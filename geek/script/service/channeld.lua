local skynet = require "skynetproto"
require "table_func"
require "functions"
local log = require "log"
local cluster = require "cluster"

local delimter = "."

local match = {
    MULTI = 1,
    SINGLE = 2,
}

match["*"] = function(tree)
    assert(type(tree) == "table")
    return match.MULTI,tree
end

match["?"] = function(tree)
    assert(type(tree) == "table")
    local _,r = table.choice(tree)
    return match.SINGLE,r
end

setmetatable(match,{
__index = function(t,k)
    local f = function(tree) 
        assert(type(tree) == "table")
        return match.SINGLE,tree[k]
    end

    t[k] = f
    return f
end})


local treenode = {}

function treenode:call(proto,...)
    if self.global then
        local node,addr = self.addr:match("([^%@]+)(@.+)")
        -- log.warning("channeld treenode:call,addr:%s,node:%s,addr:%s",self.addr,node,addr)
        return cluster.call(node,addr,proto,...)
    else
        return skynet.call(self.addr,proto,...)
    end
end

function treenode:send(proto,...)
    if self.global then
        local node,addr = self.addr:match("([^%@]+)(@.+)")
        return cluster.send(node,addr,proto,...)
    else
        return skynet.send(self.addr,proto,...)
    end
end


function treenode:deepin(ss,cb,i)
    i = i or 1
    local s = ss[i]

    local c,nodes = match[s](self.son)
    if c == match.SINGLE and i == #ss then
        cb(nodes)
        return
    end

    if c == match.MULTI and nodes then
        for _,n in pairs(nodes) do
            n:deepin(ss,cb, i + 1)
        end
    elseif c == match.SINGLE and nodes then
        nodes:deepin(ss,cb, i + 1)
    end
end


local treenodecreator = {}

setmetatable(treenodecreator,{
    __index = function(t,k)
        local n = setmetatable({
            s = k,
            son = setmetatable({},getmetatable(treenodecreator))
        },{__index = treenode})
        t[k] = n
        return n
    end,
})

local root = treenodecreator["root"]

local function search(id,cb)
    local ss 
    if type(id) == "string" then
        ss = string.split(id,"[^\\"..delimter.."]+")
    else
        ss = id
    end

    if #ss == 0 then
        log.error("search, invalid id")
        return
    end

    root:deepin(ss,cb)
end

local function put(id,addr,global)
    local ss = string.split(id,"[^\\"..delimter.."]+")
    if not ss then
        log.error("invalid id:%s",id)
        return
    end

    local node = root
    for _,s in ipairs(ss) do
        node = node.son[s]
    end
    node.addr = addr
    node.global = global
end

local function pop(id)
    local ss = string.split(id,"[^\\"..delimter.."]+")
    if not ss then
        log.error("invalid id:%s",id)
        return
    end

    local node = root
end

local CMD = {}
local waiting = {}
local address = {}
local selfprovider

local function wait(id)
    local waitco = waiting[id] or {}

    waitco[#waitco + 1] = coroutine.running()
    waiting[id] = waitco
    skynet.wait()
end

local function wakeup()
    for _,w in pairs(waiting) do
        for _,co in pairs(w) do
            skynet.wakeup(co)
        end
    end
end

function CMD.query(source,id)
    if not id then
        return address
    end
    
    return address[id]
end

function CMD.localprovider(source,name)
    selfprovider = name
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

function CMD.unsubscribe(source,service,provider)
    log.info("channeld.unsubscribe %s,%d",service)

    if not provider then
        address[service] = nil
        return
    end

    cluster.send(provider,"@channel","lua","unsubscribe",service)
    cluster.register(service,nil)
end

function CMD.call(source,id,proto,...)
    if id:match("%*") then
        log.error("senderd.call id include '*' to call multi target,id:%s",id)
        return nil
    end

    local function dosearch(id)
        local node
        search(id,function(n)
            if not n then
                log.error("search got nil,%s",id)
                return
            end
            node = n
        end)
        return node
    end

    local node
    repeat
        node = dosearch(id)
        if node then break end

        log.warning("senderd.call %s,got nil node,waiting...",id)
        wait(id)
    until node ~= nil

    log.info("channel.call id:%s",id)
    return node:call(proto,...)
end

function CMD.publish(source,id,proto,...)
    local function dosearch(id)
        local nodes = {}
        search(id,function(n)
            if not n then
                log.error("senderd:search got nil,%s",id)
                return
            end
            table.insert(nodes,n)
        end)
        return nodes
    end

    local nodes
    repeat 
        nodes = dosearch(id)
        if #nodes > 0 then break end
 
        log.warning("senderd.call %s,got nil node,waiting...",id)
        wait(id)
    until #nodes > 0

    for _,n in pairs(nodes) do
        n:send(proto,...)
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

    cluster.register("channel",skynet.self())

    require "skynet.manager"
    local handle = skynet.localname ".channeld"
    
	if handle then
		skynet.exit()
		return
	end

	skynet.register ".channeld"
end)


