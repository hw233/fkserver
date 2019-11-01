local skynet = require "skynet"
local service = require "nameservice"

require "functions"

local redisd

local command = {}
setmetatable(command, { __index = function(t,k)
	local cmd = string.upper(k)
	local f = function(t, ...)
		return skynet.call(redisd,"lua","command",t.db,cmd,...)
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

function redis.connect(cfg)
	if redis[cfg.id] then return end
	
	return skynet.call(redisd,"lua","connect",cfg)
end

function redis.close(db)
	return skynet.call(redisd,"lua","close",db)
end

skynet.init(function()
	require "skynet.manager"
	redisd= skynet.uniqueservice("service/redisd")
end)


return redis