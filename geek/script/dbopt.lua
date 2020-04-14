require "table_func"
require "functions"
local log = require "log"

local skynet = require "skynet"

local mysqld = ".mysqld"

local function table2sql(tb)
	local strtb = {}
	for k,v in pairs(tb) do
		local t = type(v)
		if t == "number" or t == "boolean" then
			table.insert(strtb,k.."="..v)
		elseif t == "string" then
			table.insert(strtb,k.."='"..v.."'")
		elseif t == "table" then
			table.insert(strtb,k.."="..table2sql(v))
		end
	end

	return table.concat(strtb,",")
end

local transaction = {}

function transaction:begin()
	return skynet.call(mysqld,"lua","querywithconn",self.name,self.conn,"BEGIN;")
end

function transaction:rollback()
	return skynet.call(mysqld,"lua","querywithconn",self.name,self.conn,"ROLLBACK;")
end

function transaction:execute(sql,...)
	return skynet.call(mysqld,"lua","querywithconn",self.name,self.conn,sql,...)
end

function transaction:commit()
	return skynet.call(mysqld,"lua","querywithconn",self.name,self.conn,"COMMIT;")
end

local db = {}

function db:query(sql,...)
	return skynet.call(mysqld,"lua","query",self.name,sql,...)
end

function db:execute(sql,tb)
	sql = string.gsub(sql,"%$FIELD%$",table2sql(tb))
	return skynet.call(mysqld,"lua","query",self.name,sql)
end

function db:transaction()
	local conn = skynet.call(mysqld,"lua","getconn",self.name)
	return setmetatable({name = self.name,conn = conn},{__index = transaction})
end

local mysql = {}

setmetatable(mysql,{
	__index = function(t,k)
		local thisdb  = setmetatable({name = k,},{__index = db,})
		t[k] = thisdb
		return thisdb
	end,
})

function mysql.open(conf)
	skynet.call(mysqld,"lua","open",conf)
end

function mysql.close(nameorid)
	skynet.call(mysqld,"lua","close",nameorid)
end

skynet.init(function()
	mysqld = skynet.uniqueservice("service.mysqld")
end)

return mysql
