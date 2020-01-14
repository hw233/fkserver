require "table_func"
require "functions"
local log = require "log"

local skynet = require "skynet"

local mysqld

local db = {}

function db:query(sql,...)
	return skynet.call(mysqld,"lua","query",self.name,sql,...)
end

function db:execute(sql,tb)
	return skynet.call(mysqld,"lua","execute",self.name,sql,tb)
end

function db:querywithconn(conn,sql,...)
	return skynet.call(mysqld,"lua","querywithconn",self.name,conn,sql,...)
end

function db:getconn()
	return skynet.call(mysqld,"lua","getconn",self.name)
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
