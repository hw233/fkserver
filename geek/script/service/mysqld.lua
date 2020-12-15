-- db操作相关
require "functions"
local log = require "log"
local skynet = require "skynetproto"
local mysql = require "skynet.db.mysql"

LOG_NAME = "mysqld"

function new_connection(cfg)
	local conn = mysql.connect({
		host=cfg.host or "127.0.0.1",
		port=cfg.port or 3306,
		database=cfg.database,
		user=cfg.user or "root",
		password=cfg.password,
		max_packet_size = 1024 * 1024,
		on_connect = function(db)
			db:query("set charset utf8;");
		end,
	})
	if not conn then
		log.error("mysql failed to connect")
		return
	end

	return conn
end

local connection = {}

function connection.close(conn)
	if not conn then return end
	conn:disconnect()
end

function connection.query(conn,sql)
	if not conn then 
		log.errro("connection.query conn is nil.")
		return
	end
	return conn:query(sql)
end

function new_connection_pool(conf)
	assert(conf)
	return setmetatable({
		__connections = {},
		__conf = conf,
		__max= conf.pool_size or 8,
		__free = {},
		__occupied = {},
	},{__index = function(pool,id) 
		if not id then return nil end
		return pool.__connections[id]
	end})
end

local connection_pool = {}

function connection_pool.close(pool)
	for id,conn in pairs(pool.__connections) do
		connection.close(conn)
		pool.__connections[id] = nil
	end
end

function connection_pool.occupy(pool)
	for cid,conn in pairs(pool.__free) do
		pool.__free[cid] = nil
		pool.__occupied[cid] = conn
		return cid,conn
	end

	local conn = new_connection(pool.__conf)
	local cid = #pool.__connections + 1
	pool.__connections[cid] = conn
	pool.__free[cid] = conn
	return cid,conn
end

function connection_pool.release(pool,cid)
	local conn = pool.__connections[cid]
	if not conn then
		log.warning("connection_pool.release got invalid id:%s.",cid)
		return
	end

	if table.nums(pool.__free) >= pool.__max then
		pool.__connections[cid] = nil
		conn.close()
	else
		pool.__free[cid] = conn
		pool.__occupied[cid] = nil
	end
end

function connection_pool.query(pool,fmtsql,...)
	local cid,conn = connection_pool.occupy(pool)
	local res = connection.query(conn,fmtsql,...)
	connection_pool.release(pool,cid)
	return res
end

function connection_pool.do_transaction(pool,transid,fmtsql,...)
	local conn
	if not transid then
		transid,conn = connection_pool.occupy(pool)
	else
		conn = pool[transid]
	end
	
	local res = connection.query(conn,fmtsql,...)
	return transid,res
end

function connection_pool.finish_transaction(pool,transid)
	connection_pool.release(pool,transid)
end

local dbconfs= {}
local dbpools = {}

local function opendb(conf)
	local name = conf.name
	dbconfs[name] = dbconfs[name] or  conf
	return dbconfs[name]
end

local function closedb(name)
	dbconfs[name] = nil
	connection_pool.close(dbpools[name])
	dbpools[name] = nil
end

setmetatable(dbpools,{__index = function(t,name)
	local pool = new_connection_pool(dbconfs[name])
	t[name] = pool
	return pool
end})

local CMD = {}

function CMD.query(dbname,fmtsql,...)
	local pool = dbpools[dbname]
	if not pool then 
		log.error("mysqld CMD.query got nil pool,db:%s",dbname)
		return 
	end

	local res = connection_pool.query(pool,fmtsql,...)
	return res
end

function CMD.begin_transaction(dbname)
	local pool = dbpools[dbname]
	if not pool then 
		log.error("mysqld CMD.do_transaction got nil pool,db:%s",dbname)
		return 
	end

	local transid,res = connection_pool.do_transaction(pool,nil,[[SET AUTOCOMMIT = 0;BEGIN;]])
	return transid,res
end

function CMD.do_transaction(dbname,transid,fmtsql,...)
	local pool = dbpools[dbname]
	if not pool then 
		log.error("mysqld CMD.do_transaction got nil pool,db:%s",dbname)
		return 
	end

	local res
	transid,res = connection_pool.do_transaction(pool,transid,fmtsql,...)
	return transid,res
end

function CMD.rollback_transaction(dbname,transid)
	local pool = dbpools[dbname]
	if not pool then 
		log.error("mysqld CMD.do_transaction got nil pool,db:%s",dbname)
		return 
	end

	local res = connection_pool.do_transaction(pool,transid,[[ROLLBACK;SET AUTOCOMMIT = 1;]])
	connection_pool.finish_transaction(pool,transid)
	return res
end

function CMD.commit_transaction(dbname,transid)
	local pool = dbpools[dbname]
	if not pool then 
		log.error("mysqld CMD.do_transaction got nil pool,db:%s",dbname)
		return 
	end

	local res = connection_pool.do_transaction(pool,transid,[[COMMIT;SET AUTOCOMMIT = 1;]])
	connection_pool.finish_transaction(pool,transid)
	return res
end

function CMD.open(cfg)
	opendb(cfg)
end

function CMD.close(dbname)
	closedb(dbname)
end

skynet.start(function()
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else
			log.error("unknown cmd:"..cmd)
			skynet.retpack(nil)
		end
	end)

	require "skynet.manager"
	local handle = skynet.localname ".mysqld"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".mysqld"
end)
