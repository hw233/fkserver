local skynet = require "skynet"
local log = require "log"
require "table_func"

require "functions"

local redisd

local command = {}


local function expand(tb)
	if not tb then return nil end
	local list = {}
	for k,v in pairs(tb) do
		if v then
			table.insert(list,k)
			table.insert(list,v)
		end
	end
	return list
end

local function fold(tb)
	if not tb then return nil end

	local t = {}
	for i = 1,#tb,2 do
		t[tostring(tb[i])] = tb[i + 1]
	end

	return t
end

local function checkexpandkeyvalue(args)
	if type(args[1]) == "table" then
		return expand(args[1])
	end

	return args
end

local function checkexpandsequance(args)
	if type(args[1]) == "table" then
		return args[1]
	end

	return args
end

function command:hmset(key,...)
	return skynet.call(redisd,"lua","command",self.db,"hmset",key,table.unpack(checkexpandkeyvalue({...})))
end

function command:hmget(key,...)
	local dictvalues = skynet.call(redisd,"lua","command",self.db,"hmget",key,table.unpack(checkexpandsequance({...})))
	return fold(dictvalues)
end

function command:hgetall(key)
	local dictvalues = skynet.call(redisd,"lua","command",self.db,"hgetall",key)
	return fold(dictvalues)
end


function command:mget(...)
	local values = skynet.call(redisd,"lua","command",self.db,"mget",table.unpack({...}))
	return values
end

function command:mset(...)
	return skynet.call(redisd,"lua","command",self.db,"mset",table.unpack(checkexpandkeyvalue({...})))
end

setmetatable(command, { __index = function(t,k)
	local cmd = k
	local f = function(t,...)
		local v = skynet.call(redisd,"lua","command",t.db,cmd,...)
		return v
	end
	t[k] = f
	return f
end})

local redis = setmetatable({},{
	__index = function(t,k)
		local db = setmetatable({db = k},{__index = command})
		t[k] = db
		return db
	end
})

function redis.connect(conf)
	return skynet.call(redisd,"lua","connect",conf)
end

function redis.close(db)
	return skynet.call(redisd,"lua","close",db)
end

redis.default = redis[1]

skynet.init(function()
	redisd= skynet.uniqueservice("service.redisd")
end)

return redis