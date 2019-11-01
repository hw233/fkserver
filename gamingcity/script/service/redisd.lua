local skynet = require "skynet"
local redis = require "skynet.db.redis"

require "functions"

local redisdb = {}

local CMD = {}

function CMD.command(db,cmd,...)
	if not redisdb[db] then return end
	local r = redisdb[db][cmd](...)
	log.info(cmd,...,r)
    return r
end

function CMD.connect(dbconf)
	if redisdb[dbconf.id] then return true end
	
	dump(dbconf)

    redisdb[dbconf.id] = redis.connect({
        host = dbconf.host or "127.0.0.1",
		port = dbconf.port or 6379,
		auth = dbconf.auth or "foobared",
		overload = dbconf.overload,
	})

	return redisdb[dbconf.id] ~= nil
end

function CMD.close(db)
    if not redisdb[db] then return end

    redisdb[db]:disconnect()
    redisdb[db] = nil
end

skynet.start(function() 
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else 
			skynet.error("redisd,unknown cmd:"..cmd)
		end
	end)

	require "skynet.manager"
	local handle = skynet.localname ".redisd"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".redisd"
end)