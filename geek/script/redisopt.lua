local skynet = require "skynet"
local log = require "log"
local meta_tree = require "redismetadata"
local meta_matcher = require "redisorm.meta_matcher"
local crc16 = require "crc16"

require "functions"

local cached
local cacheagent

local function get_command_key(key,...)
	return tostring(key)
end

local function get_slot(key)
	return (crc16(key) % #cacheagent) + 1
end

local function do_slot_command(slot,db,cmd,...)
	return skynet.call(cacheagent[slot],"lua",db,cmd,...)
end

local function do_command(db,cmd,...)
	local key = get_command_key(...)
	return skynet.call(cacheagent[get_slot(key)],"lua",db,cmd,...)
end

local function expand(tb)
	if not tb then return end
	return table.expand(tb)
end

local function fold(tb)
	if not tb then return end
	
	return table.fold(tb)
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
		
		local vals = do_command(db,cmd,key,arg_formater(args))

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

		local vals = do_command(db,cmd,arg_formater(args))
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

		local vals = do_command(db,cmd,key,arg_formater(encoder(args,key)))

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

		local vals = do_command(db,cmd,key,arg_formater(encoder(args,key)))

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

function command:mget(...)
	local keys = {...}
	local slotkeys = {}
	for k in pairs(keys) do
		local slot = get_slot(k)
		slotkeys[slot] = slotkeys[slot] or {}
		table.insert(slotkeys[slot],k)
	end

	local slotvalues = table.map(slotkeys,function(ks,slot)
		local values = do_slot_command(slot,self.__db,"mget",table.unpack(ks))

		local dict = {}
		for i = 1,#ks do
			dict[ks[i]] = values[i]
		end

		return dict
	end)

	local keyvalue = {}
	for slot,map in pairs(slotvalues) do
		for k,v in pairs(map) do
			keyvalue[k] = v
		end
	end

	return table.series(keys,function(k) return keyvalue[k] end)
end

function command:mset(...)
	local keys = {...}
	local slotkeyvalue = {}
	for k,v in pairs(fold(keys)) do
		local slot = get_slot(k)
		slotkeyvalue[slot] = slotkeyvalue[slot] or {}
		slotkeyvalue[slot][k] = v
	end
	
	local ret = table.And(slotkeyvalue,function(keyvalue,slot)
		return do_slot_command(slot,self.__db,"mset",table.unpack(expand(keyvalue)))
	end)

	return ret
end

setmetatable(command, {
	__index = function(t,cmd)
		local f = function(t,key,...)
			local v = do_command(t.__db,cmd,key,...)
			return v
		end
		t[cmd] = f
		return f
	end
})

local redis_db = setmetatable({},{__index = command,})

local redis = setmetatable({},{
	__index = function(t,name)
		local db = setmetatable({__db = name},{__index = redis_db})
		t[name] = db
		return db
	end
})

redis.default = redis[1]

skynet.init(function()
	cached = skynet.uniqueservice("cached")
	cacheagent = skynet.call(cached,"lua","AGENT")
end)

return redis