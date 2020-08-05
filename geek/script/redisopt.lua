local skynet = require "skynet"
local log = require "log"
local meta_tree = require "redismetadata"
local meta_matcher = require "redisorm.meta_matcher"

require "table_func"
require "functions"

local redisd = ".redisd"


local function expand(tb)
	if not tb then return nil end
	local list = {}
	for k,v in pairs(tb) do
		table.insert(list,k)
		table.insert(list,v)
	end
	return list
end

local function fold(tb)
	if not tb then return nil end

	local t = {}
	for i = 1,#tb,2 do
		t[tostring(tb[i])] = tb[i + 1]
	end

	return t
end

local function meta_decode(v,key,node)
	local n = node and node[key] or meta_matcher[key]
	local meta = rawget(n,"meta")
	if meta then
		v = meta.decode(v,n)
	end

	return v
end

local function meta_encode(v,key,node)
	local n = node and node[key] or meta_matcher[key]
	local meta = rawget(n,"meta")
	if meta then
		v = meta.encode(v,n)
	end

	return v
end

local function raw_arg_formater(args)
	return table.unpack(args)
end

local function dict_arg_formater(args)
	if type(args[1]) == "table" then
		return table.unpack(expand(args[1]))
	end

	return table.unpack(expand(args))
end

local function list_arg_formater(args)
	if type(args[1]) == "table" then
		return table.unpack(args[1])
	end

	return table.unpack(args)
end

local batch_set_arg_formater = dict_arg_formater
local batch_get_arg_formater = list_arg_formater

local function raw_ret_formater(v)
	return v
end

local function dict_ret_formater(v)
	return fold(v)
end

local list_ret_formater = raw_ret_formater
local batch_get_ret_formater = list_ret_formater

local function nil_encoder(v,key,n)
	return v
end

local function raw_encoder(v,key,n)
	v = type(v[1]) == "table" and v[1] or v
	return meta_encode(v,key,n)
end

local function dict_encoder(tb,key,n)
	tb = type(tb[1]) == "table" and tb[1] or tb
	return meta_encode(tb,key,n)
end

local function batch_encoder(tb,keys,n)
	for i,key in pairs(keys) do
		tb[i] = meta_encode(tb[i],key,n)
	end
	return tb
end

local function nil_decoder(v,key,n)
	return v
end

local function raw_decoder(v,key,n)
	return meta_decode(v,key,n)
end

local function dict_decoder(tb,key,n)
	return meta_decode(tb,key,n)
end

local function batch_decoder(tb,keys,n)
	for i,key in pairs(keys) do
		tb[i] = meta_decode(tb[i],key,n)
	end
	return tb
end

local function key_args(self,...)
	local args = {...}
	local key = rawget(self,"__key")
	if not key then
		key = args[1]
		args = {select(2,...)}
	end

	return key,args
end

local function batch_field_commander(cmd,ret_formater,arg_formater,encoder,decoder)
	ret_formater = ret_formater or raw_ret_formater
	arg_formater = arg_formater or list_arg_formater
	encoder = encoder or nil_encoder
	decoder = decoder or nil_encoder
	return function(self,...)
		local key,args = key_args(self,...)
		
		local db = rawget(self,"__db")

		args = encoder(args,key)
		
		local vals = skynet.call(redisd,"lua","command",db,cmd,key,arg_formater(args))

		vals = ret_formater(vals)

		vals = decoder(vals,args,meta_matcher[key])

		return vals
	end
end

local function batch_key_commander(cmd,ret_formater,arg_formater,encoder,decoder)
	ret_formater = ret_formater or raw_ret_formater
	arg_formater = arg_formater or list_arg_formater
	encoder = encoder or nil_encoder
	decoder = decoder or batch_decoder
	return function(self,...)
		local args = {...}

		local db = rawget(self,"__db")

		local vals = skynet.call(redisd,"lua","command",db,cmd,arg_formater(args))
		vals = decoder(ret_formater(vals),args)

		return vals
	end
end

local function field_commander(cmd,ret_formater,arg_formater,encoder,decoder)
	ret_formater = ret_formater or raw_ret_formater
	arg_formater = arg_formater or raw_arg_formater
	encoder = encoder or nil_encoder
	decoder = decoder or nil_decoder
	return function(self,...)
		local key,args = key_args(self,...)

		local field = args[1]
		
		local db = rawget(self,"__db")

		local vals = skynet.call(redisd,"lua","command",db,cmd,key,arg_formater(encoder(args,key)))

		vals = ret_formater(vals)

		vals = decoder(vals,field,meta_matcher[key])

		return vals
	end
end

local function commander(cmd,ret_formater,arg_formater,encoder,decoder)
	ret_formater = ret_formater or raw_ret_formater
	arg_formater = arg_formater or raw_arg_formater
	encoder = encoder or nil_encoder
	decoder = decoder or nil_decoder
	return function(self,...)
		local key,args = key_args(self,...)
		
		local db = rawget(self,"__db")

		local vals = skynet.call(redisd,"lua","command",db,cmd,key,arg_formater(encoder(args,key)))

		vals = ret_formater(vals)

		vals = decoder(vals,key)

		return vals
	end
end

local command = {
	hmset = batch_field_commander("hmset",raw_ret_formater,dict_arg_formater,raw_encoder,nil_decoder),
	hmget = batch_field_commander("hmget",list_ret_formater,nil,nil,batch_decoder),
	hgetall = commander("hgetall",dict_ret_formater,nil,nil,dict_decoder),
	hget = field_commander("hget",nil,nil,nil,raw_decoder),
	hset = field_commander("hset"),
	mset = batch_key_commander("mset",nil,dict_arg_formater,nil,nil),
	mget = batch_key_commander("mget",list_arg_formater,nil,nil,batch_decoder),
	get = commander("get"),
	incr = commander("incr"),
	incrby = commander("incrby"),
	incrbyfloat = commander("incrbyfloat"),
	decr = commander("decr"),
	decrby = commander("decrby"),
	hincrby = field_commander("hincrby"),
	hincrbyfloat = field_commander("hincrbyfloat"),
	smembers = commander("smembers",nil,nil,nil,raw_decoder),
	sdiff = commander("sdiff",nil,nil,nil,raw_decoder),
}

setmetatable(command, {
	__index = function(t,cmd)
		local f = function(t,key,...)
			local v = skynet.call(redisd,"lua","command",t.__db,cmd,key,...)
			return v
		end
		t[cmd] = f
		return f
	end
})

local key_command = {
	hmset = batch_field_commander("hmset",dict_ret_formater,dict_arg_formater,raw_encoder,nil_decoder),
	hmget = batch_field_commander("hmget",list_ret_formater,nil,nil,batch_decoder),
	hgetall = commander("hgetall",dict_ret_formater,nil,nil,dict_decoder),
	hget = field_commander("hget",nil,nil,nil,raw_decoder),
	hset = field_commander("hset"),
	mset = batch_key_commander("mset",nil,dict_arg_formater,nil,nil),
	mget = batch_key_commander("mget",list_arg_formater,nil,nil,batch_decoder),
	get = commander("get"),
	incr = commander("incr"),
	incrby = commander("incrby"),
	incrbyfloat = commander("incrbyfloat"),
	decr = commander("decr"),
	decrby = commander("decrby"),
	hincrby = field_commander("hincrby"),
	hincrbyfloat = field_commander("hincrbyfloat"),
	smembers = commander("smembers",nil,nil,nil,raw_decoder),
	sdiff = commander("sdiff",nil,nil,nil,raw_decoder),
}

setmetatable(key_command, {
	__index = function(t,cmd)
		local f = function(t,...)
			local v = skynet.call(redisd,"lua","command",t.__db,cmd,t.__key,...)
			return v
		end
		t[cmd] = f
		return f
	end
})

local function create_key(db,fmt,...)
	return setmetatable({
		__db = db,
		__key = string.format(fmt,...),
	},{
		__index = key_command
	})
end

local redis_db = {}

function redis_db.key(self,fmt,...)
	return create_key(self.__db,fmt,...)
end

setmetatable(redis_db,{__index = command,})

local redis = setmetatable({},{
	__index = function(t,name)
		local db = setmetatable({__db = name},{__index = redis_db})
		t[name] = db
		return db
	end
})

function redis.connect(conf)
	return skynet.call(redisd,"lua","connect",conf)
end

function redis.close(db)
	return skynet.call(redisd,"lua","close",db)
end

redis.default = redis[1]

skynet.init(function()
	redisd = skynet.uniqueservice("service.redisd")
end)

return redis