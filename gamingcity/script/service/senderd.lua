local skynet = require "skynet"

require "table_func"
require "functions"
local cluster = require "skynet.cluster"

local pb = require "pb"

pb.register_file("./gamingcity/pb/verify_define.proto")
pb.register_file("./gamingcity/pb/redis_define.proto")
pb.register_file("./gamingcity/pb/common_player_define.proto")
pb.register_file("./gamingcity/pb/config_define.proto")
pb.register_file("./gamingcity/pb/common_enum_define.proto")
pb.register_file("./gamingcity/pb/common_msg_define.proto")
pb.register_file("./gamingcity/pb/msg_server.proto")

local delimter = "."
local address = {}

local matcher = {
    MULTI = 2,
    ONE = 3,
}

matcher["*"] = function(tree)
    assert(type(tree) == "table")
    return matcher.MULTI,tree
end

matcher["?"] = function(tree)
    assert(type(tree) == "table")
    local k,r = table.choice(tree)
    return matcher.ONE,r
end

setmetatable(matcher,{
__index = function(t,k)
    local f = function(tree) 
        assert(type(tree) == "table")
        return matcher.ONE,tree[k]
    end

    t[k] = f
    return f
end})


local treenode = {}

function treenode:deepin(ss,cb,i)
    if not i then i = 1 end
    local s = ss[i]

    local c,nodes = matcher[s](self.son)
    if c == matcher.ONE and i == #ss then
        cb(nodes)
        return
    end

    if c == matcher.MULTI and nodes then
        for _,n in pairs(nodes) do
            n:deepin(ss,cb, i + 1)
        end
    elseif c == matcher.ONE and nodes then
        nodes:deepin(ss,cb, i + 1)
    end
end

function treenode:call(p,...)
    if self.isremote then
        local node,addr = string.match("([^\\@]+)(\\@.+)")
        cluster.call(node,addr,p,...)
    else
        skynet.call(self.addr,p,...)
    end
end

function treenode:send(p,...)
    if self.isremote then
        local node,addr = string.match("([^\\@]+)(\\@.+)")
        cluster.send(node,addr,p,...)
    else
        skynet.send(self.addr,p,...)
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

treenode.son = setmetatable({},getmetatable(treenodecreator))

local addresstree = {
    root = treenode,
}

function addresstree:search(id,cb)
    local ss 
    if type(id) == "string" then
        ss = string.split(id,"[^\\"..delimter.."]+")
    else
        ss = id
    end

    if not ss then
        skynet.error("invalid id")
        return
    end

    self.root:deepin(ss,cb)
end

function addresstree:put(id,addr,iscluster)
    local ss = string.split(id,"[^\\"..delimter.."]+")
    if not ss then
        skynet.error(string.format("invalid id:%s",id))
        return
    end

    local node = self.root
    for _,s in ipairs(ss) do
        node = node.son[s]
    end
    node.addr = addr
    node.iscluster = iscluster
end

local CMD = {}

function CMD.query(id)
    if not id then
        return addreess
    end
    
    return address[id]
end

function CMD.register(source,id,addr,iscluster)
    addr = addr or source
    addresstree:put(id,addr,iscluster)
    address[id] = {
        addr  = addr,
        iscluster = iscluster,
    }
end

function CMD.call(source,id,...)
    local ret
    local args = {...}
    addresstree:search(id,function(node)
        if not node then
            skynet.erorr("addresstree:search got nil")
            return
        end
        ret = node:call(table.unpack(args))
    end)
    return ret
end

function CMD.send(source,id,...)
    local args = {...}
    addresstree:search(id,function(node)
        if not node then
            skynet.error("addresstree:search got nil")
            return
        end 
        
        node:send(table.unpack(args))
    end)
end

skynet.start(function()
    skynet.dispatch("lua", function (_, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(source, ...))
        else
            skynet.error(string.format("senderd unknown cmd:%s",cmd))
        end
    end)

    require "skynet.manager"
	local handle = skynet.localname ".senderd"
	if handle then
		skynet.exit()
		return
	end

	skynet.register ".senderd"
end)


