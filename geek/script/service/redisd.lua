local skynet = require "skynetproto"
local redis = require "skynet.db.redis"
local log = require "log"
local channel = require "channel"
local rediscluster = require "skynet.db.redis.cluster"

LOG_NAME = "redisd"

local mgrd = tonumber(...)

require "functions"

local function get_redis_conf(t,id)
	local conf = channel.call("config.?","msg","query_redis_conf",id)
	if id then
		t[id] = conf
	end
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

local function setupcluster()
	local confs = table.series(redisconf[nil],function(c)
		return (c.cluster and c.cluster ~= 0) and c or nil
	end)
	assert(#confs > 0)
	return rediscluster.new(
		confs,
		{read_slave=true,auth=confs[1].auth,db=0,}
	)
end

local clusterdb
local function get_redis_cluster_db(t)
	clusterdb = clusterdb or setupcluster()
	return clusterdb
end

local redisdb = setmetatable({},{__index = get_redis_cluster_db})

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
	if not db or not rawget(redisdb,db) then 
		return 
	end

	local rdb = redisdb[db]
	if rdb == clusterdb then
		rdb:close_all_connection()
		clusterdb = nil
	else
		rdb:disconnect()
    	redisdb[db] = nil
	end
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
end)