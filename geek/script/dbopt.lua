require "functions"
local log = require "log"
local skynet = require "skynet"
local json = require "json"

local table = table
local string = string

local mysqld = ".mysqld"

local escape_map = {
	['\0'] = "\\0",
	['\b'] = "\\b",
	['\n'] = "\\n",
	['\r'] = "\\r",
	['\t'] = "\\t",
	['\26'] = "\\Z",
	['\\'] = "\\\\",
	["'"] = "\\'",
	['"'] = '\\"',
}

local function escape(str)
	if type(str) ~= "string" then
		return str
	end

	return string.gsub(str, "[\0\b\n\r\t\26\\\'\"]", escape_map)
end

local function uniform_sql_quota(sql)
	sql = string.trim(sql)
	local lastchar = string.sub(sql,#sql)
	return lastchar == ";" and sql or sql .. ";"
end

local function uniform_sql_field_name(name)
	return string.format("`%s`",name)
end

local function table2sql(fields)
	local strtb = table.series(fields,function(v,k)
		assert(type(k) == "string")
		local t = type(v)
		k = uniform_sql_field_name(k)
		if t == "string" then
			return string.format("`%s`='%s'",k,escape(v))
		end
		if t == "table" then
			return string.format("`%s`='%s'",k,json.encode(v))
		end
		return string.format("`%s`=%s",k,v)
	end)

	return table.concat(strtb,",")
end

local db = {}

function db:query(sql,...)
	local args = table.series({...},escape)
	sql = string.format(sql,table.unpack(args))
	sql = uniform_sql_quota(sql)
	return skynet.call(mysqld,"lua","query",self.name,sql)
end

local function fomrat_batch_sql(s)
	if type(s) == "table" then
		if not s[2] then
			return uniform_sql_quota(s[1])
		end

		local vargs = {}
		for i = 2,#s do 
			vargs[i - 1] = escape(s[i]) or 'NULL'
		end

		local sql = string.format(s[1],table.unpack(vargs))
		sql = uniform_sql_quota(sql)
		return sql
	end

	local s = uniform_sql_quota(s)
	return s
end

function db:batchquery(sqls,...)
	if type(sqls) == "table" then
		sqls = table.series(sqls,fomrat_batch_sql)
		local sql = table.concat(sqls,"")
		return skynet.call(mysqld,"lua","query",self.name,sql)
	end

	return self:query(sqls,...)
end

function db:execute(sql,tb)
	sql = string.gsub(sql,"%$FIELD%$",table2sql(tb))
	return skynet.call(mysqld,"lua","query",self.name,sql)
end

local trans = {}

function trans:exec(sql,...)
	local args = table.series({...},escape)
	sql = string.format(sql,table.unpack(args))
	sql = uniform_sql_quota(sql)
	return skynet.call(mysqld,"lua","do_transaction",self.name,self.id,sql)
end

function trans:batchexec(sqls,...)
	if type(sqls) == "table" then
		sqls = table.series(sqls,fomrat_batch_sql)
		local sql = table.concat(sqls,"")
		return skynet.call(mysqld,"lua","do_transaction",self.name,self.id,sql)
	end
	return self:do_trans(self.id,sqls,...)
end

function db:transaction(fn)
	local conn_id = skynet.call(mysqld,"lua","begin_transaction",self.name)
	local t = setmetatable({
		id = conn_id
	},{
		__index = trans
	})

	local ok,succ = pcall(fn,t)

	if not ok or not succ then
		skynet.call(mysqld,"lua","rollback_transaction",self.name,conn_id)
	else
		skynet.call(mysqld,"lua","commit_transaction",self.name,conn_id)
	end
end

function db:begin_trans()
	return skynet.call(mysqld,"lua","begin_transaction",self.name)
end

function db:do_trans(transid,sql,...)
	local args = table.series({...},escape)
	sql = string.format(sql,table.unpack(args))
	sql = uniform_sql_quota(sql)
	return skynet.call(mysqld,"lua","do_transaction",self.name,transid,sql)
end

function db:do_batchtrans(transid,sqls,...)
	if type(sqls) == "table" then
		sqls = table.series(sqls,fomrat_batch_sql)
		local sql = table.concat(sqls,"")
		return skynet.call(mysqld,"lua","do_transaction",self.name,transid,sql)
	end
	return self:do_trans(transid,sqls,...)
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

mysql.escapefield = escape
mysql.escapefieldname = function(s)
	return string.format('`%s`',s)
end

skynet.init(function()
	mysqld = skynet.uniqueservice("service.mysqld")
end)

return mysql
