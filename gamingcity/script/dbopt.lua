require "table_func"
require "functions"
local log = require "log"
local service = require "nameservice"

local skynet = require "skynet"

local mysqld 

local db = {}

function db:query(sql,...)
	return skynet.call(mysqld,"lua","query",self.name,sql,...)
end

function db:execute(sql,pb)
	return skynet.call(mysqld,"lua","execute_pb",self.name,sql,pb)
end

local mysql = {}

setmetatable(mysql,{
	__index = function(t,k)
		local thisdb  = setmetatable({name = k,},{__index = db,})
		t[k] = thisdb
		return thisdb
	end,
})

skynet.init(function()
	require "skynet.manager"
	mysqld = skynet.uniqueservice("service/mysqld")
end)

return mysql
