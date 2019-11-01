-- db操作相关

require "table_func"
require "functions"
local log = require "log"
local skynet = require "skynet"
local mysql = require "skynet.db.mysql"

local function table2string(tb)
	local strtb = {}
	for k,v in pairs(tb) do
		local t = type(v)
		if t == "number" or t == "boolean" then
			table.insert(strtb,k.."="..v)
		elseif t == "string" then
			table.insert(strtb,k.."=''"..v.."''")
		elseif t == "table" then
			table.insert(strtb,k.."="..table2string(v))
		end
	end

	return table.concat(strtb,",")
end

local function pb2string(tb)
	local strtb={}
	for k, v in pairs(tb or {}) do
		local t = type(v)
		if t == "number" or t == "boolean" then
			table.insert(strtb, k.."="..v)
		elseif t == "string" then
			table.insert(strtb, k.."='"..v.."'")
        elseif t == "table" then
			table.insert(strtb, k.."='"..table2string(v).."'")
        end
    end
	return table.concat(strtb,",")
end

function pbstr2table(pbstr)
	
end


local db_conn = {}

function new_db_connection(cfg)
	local conn = {}
	conn.db = mysql.connect({
		host=cfg.host or "127.0.0.1",
		port=cfg.port or 3306,
		database=cfg.name,
		user=cfg.user or "root",
		password=cfg.password,
		max_packet_size = 1024 * 1024,
		on_connect = function(db)
			db:query("set charset utf8");
		end,
	})
	if not conn.db then
		log.info("mysql failed to connect")
	end

	return setmetatable(conn,{__index = db_conn})
end

function db_conn:close()
	if not self.db then return end

	self.db:disconnect()
	self.db = nil
end

function db_conn:execute_pb(sql, pb)
	local str = pb2string(pb)
	str = string.gsub(sql, '%$FIELD%$', str)
	self.db:query(str)
end

function db_conn:query(sqlfmt,...)
	return self.db:query(string.format(sqlfmt,...))
end

local db_conn_pool = {}

function new_db_connection_pool(cfg)
	assert(cfg)
	local pool = setmetatable({
		conns = {},
		cfg = cfg,
		max_conn = cfg.pool_size or 8,
	},{__index = db_conn_pool})
	return pool
end

function db_conn_pool:close()
	for _,conn in pairs(self.conns) do
		conn:close()
	end
	self.conns = {}
end

function db_conn_pool:choice()
	local i = math.random(#self.conns)
	return self.conns[i]
end

function db_conn_pool:get()
	if #self.conns >= self.max_conn then
		return self:choice()
	end

	local conn = new_db_connection(self.cfg)
	table.insert(self.conns,conn)
	return conn
end


function db_conn_pool:execute_pb(sql, pb)
	self:get():execute_pb(sql,pb)
end

function db_conn_pool:update(sql)
	return self:get():query(sql)
end

function db_conn_pool:query(sql)
	return self:get():query(sql)
end

function db_conn_pool:fmt_query(sqlfmt,...)
	return self:get():query(string.format(sqlfmt,...))
end

function db_conn_pool:fmt_execute(sqlfmt,...)
	return self:get():query(string.format(sqlfmt,...))
end

function db_conn_pool:fmt_execute_pb(sqlfmt,...)
	return self:get():query(string.format(sqlfmt,...))
end


local dbmanager = {all = {}}

function dbmanager:open(cfg)
	-- dump(cfg)
	if self.all[cfg.name] then
		return self.all[cfg.name]
	end

	local db = new_db_connection_pool(cfg)
	if db then
		self.all[cfg.name] = db
	end

	return db
end

function dbmanager:close(dbname)
	dump(dbname)

	if not self.all[dbname] then return end

	self.all[dbname]:close()
	self.all[dbname] = nil
end

function dbmanager:get(cfg_or_name)
	local function get_with_cfg(cfg)
		return self.all[cfg.name] or self:open(cfg)
	end

	local function get_with_name(name)
		return self.all[name]
	end

	if type(cfg_or_name) == "string" then
		return get_with_name(cfg_or_name) 
	end

	if type(cfg_or_name) == "table" then
		return get_with_cfg(cfg_or_name)
	end

	return nil
end

local CMD = {}

function CMD.query(dbname,fmtsql,...)
	local pool = dbmanager:get(dbname)
	if not pool then return end
	local res = pool:fmt_query(fmtsql,...)
	return res
end

function CMD.execute_pb(dbname,sql,pb)
	local pool = dbmanager:get(dbname)
	if not pool then return end
	return pool:execute_pb(sql,pb)
end

function CMD.open(cfg)
	dbmanager:open(cfg)
end

function CMD.close(dbname)
	dbmanager:close(dbname)
end

skynet.start(function() 
	local g_cfg = json_decode_file("gamingcity/config/database.json")
	dbmanager:open(g_cfg.account)
	dbmanager:open(g_cfg.game)
	dbmanager:open(g_cfg.log)
	dbmanager:open(g_cfg.recharge)
	dbmanager:open(g_cfg.proxy)
	dbmanager:open(g_cfg.config)

	skynet.dispatch("lua", function (_, address, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else 
			skynet.error("unknown cmd:"..cmd)
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
