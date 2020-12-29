local skynet = require "skynetproto"
require "functions"
local log = require "log"
local cluster = require "cluster"

local table = table
local string = string

collectgarbage("setpause", 100)

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
    for model in string.gmatch(id,"[^%:|%.]+") do
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

local function get_node(id)
    local n = matcher[id]
    if n then
        return n
    end

    log.warning("channeld get node %s,got nil node,waiting...",id)
    waiting[id] = waiting[id] or {}
    local co = coroutine.running()
    table.insert(waiting[id],co)
    skynet.wait()

    --double check
    n = matcher[id]
    if not n then
        error(string.format("channeld wait id %s,got nil",id))
    end

    return n
end

local function wakeup()
    for id,w in pairs(waiting) do
        local n = matcher[id]
        if n then
            local co
            repeat
                co = table.remove(w,1)
                if co then
                    skynet.wakeup(co)
                end
            until not co
            waiting[id] = nil
        end
    end
end

local function get_service_without_warmdead(sid)
    local ss = {}
    for id,s in pairs(address) do
        if not s.warmdead and (not sid or sid == id) then
            ss[id] = s
        end
    end

    return ss
end

function CMD.query(_,id)
    return get_service_without_warmdead(id)
end

function CMD.localprovider(_,name)
    selfprovider = name
end

function CMD.providerservice(provider)
    local providers = {}
    for id,sconf in pairs(address) do
        if sconf.global then
            local p,_ = sconf.addr:match("([^@]+)@.+")
            if not provider or p == provider then
                providers[p] = providers[p] or {}
                table.insert(providers[p],id)
            end
        end
    end

    return providers
end

function CMD.subscribe(source,service,handle,provider)
    if not provider then
        handle = handle or source
        local global = (type(handle) == "string" and handle:match("%@"))
        put(service,handle,global)
        address[service] = {
            addr = handle,
            global = global,
        }
    else
        cluster.send(provider,"@channel","lua","subscribe",service,selfprovider.."@"..service)
    end

    log.info("channeld.subscribe provider:%s,id:%s,handle:%s",provider,service,handle)

    wakeup()
end

function CMD.unsubscribe(_,service,provider)
    log.info("channeld.unsubscribe %s,%d",service)

    if not provider or provider == selfprovider then
        pop(service)
        address[service] = nil
        return
    end

    cluster.send(provider,"@channel","lua","unsubscribe",service)
    cluster.register(service,nil)
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
                if provider ~= selfprovider then
                    table.insert(providers,provider)
                end
            end
            address[id] = nil
        end
    end
    for _,provider in pairs(providers) do
        cluster.send(provider,"@channel","lua","kill",id)
    end
end

skynet.start(function()
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

    require "skynet.manager"
    local handle = skynet.localname ".channeld"
	if handle then
		skynet.exit()
		return
	end

	skynet.register ".channeld"
end)


