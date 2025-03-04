local skynet = require "skynetproto"
require "functions"
local log = require "log"
local cluster = require "cluster"

local table = table
local string = string

local tremove = table.remove
local tinsert = table.insert
local strgmatch = string.gmatch
local strfmt = string.format
local strmatch = string.match

LOG_NAME = "channeld"

local nodemetaindex = {}

local function createnode(p)
    local n = setmetatable({},{
        __index = nodemetaindex,
    })
    
    return n
end

function nodemetaindex.call(self,proto,...)
    if self.global then
        local node,addr = self.addr:match("([^%@]+)(@.+)")
        return cluster.call(node,addr,proto,...)
    else
        return skynet.call(self.addr,proto,...)
    end
end

function nodemetaindex.rawcall(self,proto,msg,sz)
    if self.global then
        local node,addr = self.addr:match("([^%@]+)(@.+)")
        return cluster.rawcall(node,addr,proto,msg,sz)
    else
        return skynet.rawcall(self.addr,proto,msg,sz)
    end
end

function nodemetaindex.send(self,proto,...)
    if self.global then
        local node,addr = self.addr:match("([^%@]+)(@.+)")
        return cluster.send(node,addr,proto,...)
    else
        return skynet.send(self.addr,proto,...)
    end
end

function nodemetaindex.rawsend(self,proto,msg,sz)
    if self.global then
        local node,addr = self.addr:match("([^%@]+)(@.+)")
        return cluster.rawsend(node,addr,proto,msg,sz)
    else
        return skynet.rawsend(self.addr,proto,msg,sz)
    end
end

function nodemetaindex.broadcast(self,proto,...)
    if self.addr or self.global then
        self:send(proto,...)
    end

    if self.__son and type(self.__son) == "table" then
        for _,n in pairs(self.__son) do
            n:broadcast(proto,...)
        end
    end
end

function nodemetaindex.rawbroadcast(self,proto,msg,sz)
    if self.addr or self.global then
        self:rawsend(proto,msg,sz)
    end

    if self.__son and type(self.__son) == "table" then
        for _,n in pairs(self.__son) do
            n:rawbroadcast(proto,msg,sz)
        end
    end
end

function nodemetaindex.son(self,s)
    if not self.__son then
        local n = createnode(self)
        self.__son = {
            [s] = n
        }
        return n
    end

    self.__son[s] = self.__son[s] or createnode(self)
    return self.__son[s]
end

function nodemetaindex.del(self,model)
    local son = self.__son
    if son[model] then
        son[model] = nil
        return
    end

    if model == "*" then
        self.__son = nil
        return
    end
end

local batchmatchmetaindex = {}

local function createbatchmatch(nodes)
    return setmetatable({__nodes = nodes},{__index = batchmatchmetaindex})
end

function batchmatchmetaindex.match(self,model)
    local ns = table.series(self.__nodes,function(n) 
        return n:match(model) 
    end)

    if #ns == 0 then
        return
    end

    return #ns > 1 and createbatchmatch(ns) or ns[1]
end

function batchmatchmetaindex.send(self,proto,...)
    for _,n in pairs(self.__nodes) do
        n:broadcast(proto,...)
    end
end

function batchmatchmetaindex.rawsend(self,proto,msg,sz)
    for _,n in pairs(self.__nodes) do
        n:rawbroadcast(proto,msg,sz)
    end
end

function batchmatchmetaindex.del(self,model)
    for _,n in pairs(self.__nodes) do
        n:del(model)
    end
end

local modelmatcher = {
    ["*"] = function(n)
        return createbatchmatch(n.__son)
    end,
    ["?"] = function(n)
        local _,n = table.choice(n.__son or {})
        return n
    end,
}

local function match_son(node,model)
    local son = node.__son
    if not son then return end
    local n = son[model]
    if n then return n end 
    local mfn = modelmatcher[model]
    if mfn then
        return mfn(node)
    end
end

function nodemetaindex.match(self,id)
    local n = self
    for model in strgmatch(id,"[^%:|%.]+") do
        n = match_son(n,model)
        if not n then 
            return
        end
    end
    return n
end

local buildermetatable
buildermetatable = {
    __index = function(self,s)
        local n = self.__node:son(s)
        local bn = setmetatable({__node = n},buildermetatable)
        return bn
    end,
    __newindex = function(self,s,v)
        self.__node[s] = v
    end
}

local function createbuilder(root)
    return setmetatable({__node = root,},buildermetatable)
end

local function creatematcher(root)
    return setmetatable({},{
        __index = function(t,id)
            return root:match(id)
        end
    })
end

local root = createnode()
local builder = createbuilder(root)
local matcher = creatematcher(root)

local function put(id,addr,global)
    local n = builder
    for model in string.gmatch(id,"[^%:|%.]+") do
        n = n[model]
    end
    n.addr = addr
    n.global = global
end

local function pop(id)
    local node = root
    for model in string.gmatch(id,"[^%:|%.]+") do
        local n = node:match(model)
        if not n then
            node:del(model)
            return
        end
        n = node
    end
end

local CMD = {}
local waiting = {}
local address = {}
local selfprovider
local selfname

local function get_node(id)
    local n = matcher[id]
    if n then
        return n
    end

    log.warning("channeld get node %s,got nil node,waiting...",id)
    waiting[id] = waiting[id] or {}
    local co = coroutine.running()
    tinsert(waiting[id],co)
    skynet.wait()

    --double check
    n = matcher[id]
    if not n then
        error(strfmt("channeld wait id %s,got nil",id))
    end

    return n
end

local function wakeup_queue(q)
    local co
    while true do
        co = tremove(q,1)
        if not co then break end
        skynet.wakeup(co)
    end
end

local function wakeup()
    for id,q in pairs(waiting) do
        local n = matcher[id]
        if n then
            wakeup_queue(q)
            waiting[id] = nil
        end
    end
end

local function get_service_without_warmdead(sid)
    local ss = {}
    for id,s in pairs(address) do
        if not s.warmdead and (not sid or sid == id or id:match(sid)) then
            ss[id] = s
        end
    end

    return ss
end

function CMD.query(_,id)
    return get_service_without_warmdead(id)
end

function CMD.localprovider(_,ctx)
    selfprovider = ctx
end

function CMD.providerservice(provider)
    local providers = {}
    for id,sconf in pairs(address) do
        if sconf.global then
            local p,_ = sconf.addr:match("([^@]+)@.+")
            if not provider or p == provider then
                providers[p] = providers[p] or {}
                tinsert(providers[p],id)
            end
        end
    end

    return providers
end

local function do_sub(sid,handle)
    local provider = type(handle) == "string" and handle:match("[^%@]+") or nil
    put(sid,handle,provider)
    address[sid] = {
        addr = handle,
        global = provider,
        provider = provider,
    }
    log.info("channeld.subscribe %s  %s",sid,handle)
end

local function do_unsub(sid)
    assert(sid and type(sid) == "string")
    pop(sid)
    local ctx = address[sid]
    if ctx and not ctx.global then
        cluster.register(sid)
    end
    address[sid] = nil
    log.info("channeld.unsubscribe %s  %s",sid,ctx and ctx.addr)
end

local function sub(sid,handle)
    local t = type(handle)
    if t == "number" then
        do_sub(sid,handle)
        cluster.register(sid,handle)
        return
    end

    if t == "string" then
        do_sub(sid,handle)
        return
    end

    if t == "table" then
        local provider = handle.provider
        assert(type(provider) == "string")
        assert(not selfprovider or provider ~= selfprovider.name)
        assert(type(handle.addr) == "string")

        do_sub(sid,provider.."@"..sid)
        return provider,handle.addr
    end
end

local function sub_many(services)
    local remotenodes = {}
    for sid,hdl in pairs(services) do
        local provider,addr = sub(sid,hdl)
        if provider and addr then
            remotenodes[provider] = addr
        end
    end

    cluster.reload(remotenodes)
end

local function sub_one(service,handle)
    local provider,addr = sub(service,handle)
    if provider and addr then
        cluster.reload({
            [provider] = addr
        })
    end
end

function CMD.load_service(_,clusters)
    for name in pairs(clusters) do
        if name ~= selfprovider.name then 
            local ok,services = pcall(cluster.call,name,"@channel","lua","reqeust_service")
            if ok then
                sub_many(services)
                wakeup()
            end
        end
    end
end 

function CMD.reqeust_service()
    local localservices = {}
    local localprovider = {
        provider = selfprovider.name,
        addr = selfprovider.addr,
    }
    for sid,c in pairs(address) do
        if not c.global then
            localservices[sid] = localprovider
        end
    end

    return localservices
end

function CMD.exchange(_,service,handle,from)
    if type(service) == "table" then
        sub_many(service)
        from = handle
    else
        sub_one(service,handle)
    end

    wakeup()

    local localservices = {}
    local localprovider = {
        provider = selfprovider.name,
        addr = selfprovider.addr,
    }
    for sid,c in pairs(address) do
        if not c.global then
            localservices[sid] = localprovider
        end
    end

    cluster.send(from,"@channel","lua","exchange_rep",localservices)
end

function CMD.exchange_rep(_,services)
    sub_many(services)
    wakeup()
end

function CMD.subscribe(_,service,handle,remote)
    if type(service) == "table" then
        remote = handle
        if remote then
            cluster.send(remote,"@channel","lua","exchange",service,selfprovider.name)
            return
        end
        sub_many(service)
    else
        assert(service and type(service) == "string")
        assert(handle)
        if remote then
            cluster.send(remote,"@channel","lua","exchange",service,handle,selfprovider.name)
            return
        end

        sub_one(service,handle)
    end
    
    wakeup()
end

function CMD.unsubscribe(_,service,remote)
    if remote then
        cluster.send(remote,"@channel","lua","unsubscribe",service)
        return
    end

    local t = type(service)
    if t == "string" then
        log.info("channeld.unsubscribe %s",service)
        do_unsub(service)
        return
    end

    assert(t == "table")
    for k,name in pairs(service) do 
        log.info("channeld.unsubscribe %s",name)
        do_unsub(name)
    end
end

function CMD.rawcall(_,id,proto,msg,sz)
    if id:match("%*") then
        log.error("channeld.rawcall id include '*' to rawcall multi target,id:%s",id)
        return nil
    end

    local n = get_node(id)
    return n:rawcall(proto,msg,sz)
end

function CMD.call(_,id,proto,...)
    if id:match("%*") then
        log.error("channeld.call id include '*' to call multi target,id:%s",id)
        return nil
    end

    local n = get_node(id)
    return n:call(proto,...)
end

function CMD.publish(_,id,proto,...)    
    local n = get_node(id)
    n:send(proto,...)
end

function CMD.warmdead(_,id)
    if not id or not address[id] then
        log.warning("channeld warmdead with wrong id:%s",id)
        return
    end

    local kidnum = id:match("[^.].(%d+)")
    for sid,conf in pairs(address) do
        local sname,idnum = sid:match("([^.]+).(%d+)")
        idnum = tonumber(idnum)
        if idnum == kidnum and not conf.global then
            conf.warmdead = true
        elseif sname == "service" then
            CMD.publish(_,sid,"lua","warmdead",id)
        end
    end

    address[id].warmdead = true
end

function CMD.kill(_,id)
    local providers = {}
    local kidnum = id:match("[^.].(%d+)")
    for sid,conf in pairs(address) do
        local _,idnum = sid:match("([^.]+).(%d+)")
        idnum = tonumber(idnum)
        if idnum == kidnum then
            if not conf.global then
                skynet.kill(conf.addr)
                cluster.register(id,nil)
            else
                local provider,_ = conf.addr:match("([^@]+)@(.+)")
                if provider ~= selfprovider.name then
                    tinsert(providers,provider)
                end
            end
            address[id] = nil
        end
    end
    for _,provider in pairs(providers) do
        cluster.send(provider,"@channel","lua","kill",id)
    end
end

function CMD.term()
    log.warning("CHANNELD TERM")
    local localservices = {}
    for sid,c in pairs(address) do
        if not c.global then
            localservices[sid] = c.addr
        end
    end

    for sid,addr in pairs(localservices) do
        if sid ~= selfname then
            local ok,err = pcall(skynet.call,addr,"lua","term")
            if not ok then
                log.error("term addr error:%s",err)
            end
        end
    end

    local localnames = {}
    local otherproviders = {}
    for sid,c in pairs(address) do
        if sid ~= selfname then
            if c.global then
                otherproviders[c.provider] = true
            else
                tinsert(localnames,sid)
            end
        end
    end
    
    for provider in pairs(otherproviders) do
        cluster.send(provider,"@channel","lua","unsubscribe",localnames)
    end
    
    log.warning("CHANNELD TERM END")
end

skynet.start(function()
    require "skynet.manager"
    local handle = skynet.localname ".channeld"
	if handle then
		skynet.exit()
		return
	end

	skynet.register ".channeld"

    skynet.dispatch("lua", function (_, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(source,...))
        else
            log.error("channeld unknown cmd:%s",cmd)
            skynet.retpack(nil)
        end
    end)

    skynet.register_protocol {
        id = skynet.PTYPE_CLIENT,
        name = "client",
        pack = skynet.pack,
        unpack = skynet.unpack,
    }
    
    cluster.register("channel",skynet.self())
    selfname = "channel." .. math.floor(skynet.time() * 1000) .. math.random(1,10000)
    sub(selfname,skynet.self())
end)


