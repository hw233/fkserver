local skynet = require "skynetproto"
local redis = require "skynet.db.redis"
local log = require "log"
local channel = require "channel"

collectgarbage("setpause", 100)

LOG_NAME = "redisd"

require "functions"

local function get_redis_conf(t,id)
	local conf = channel.call("config.?","msg","query_redis_conf",id)
	t[id] = conf
	return conf
end

local redisconf = setmetatable({},{__index = get_redis_conf,})

local function get_redis_db(t,id)
	local conf = redisconf[id]
	if not conf or (conf.cluster and conf.cluster ~= 1) then
		return nil
	end

	local db = redis.connect({
        host = conf.host or "127.0.0.1",
		port = conf.port or 6379,
		auth = conf.auth or "foobared",
		db = conf.db or 0,
		overload = conf.overload,
	})

	t[id] = db
	if conf.name then t[conf.name] = db end
	return db
end

local redisdb = setmetatable({},{__index = get_redis_db})

local CMD = {}

function CMD.command(db,cmd,...)
	local rdb = redisdb[db]
	if not rdb then
		return
	end

	local r = rdb[cmd](rdb,...)
    return r
end

function CMD.close(db)
    if not rawget(redisdb,db) then return end

    redisdb[db]:disconnect()
    redisdb[db] = nil
end

skynet.start(function()
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else
			log.error("unknown cmd:"..cmd)
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