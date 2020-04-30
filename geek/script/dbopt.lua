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

local db = {}

function db:query(sql,...)
	return skynet.call(mysqld,"lua","query",self.name,sql,...)
end

function db:execute(sql,tb)
	sql = string.gsub(sql,"%$FIELD%$",table2sql(tb))
	return skynet.call(mysqld,"lua","query",self.name,sql)
end

function db:begin_trans()
	return skynet.call(mysqld,"lua","begin_transaction",self.name)
end

function db:do_trans(transid,sql,...)
	return skynet.call(mysqld,"lua","do_transaction",self.name,transid,sql,...)
end

function db:rollback_trans(transid)
	return skynet.call(mysqld,"lua","rollback_transaction",self.name,transid)
end

function db:commit_trans(transid)
	return skynet.call(mysqld,"lua","commit_transaction",self.name,transid)
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
