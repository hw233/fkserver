local skynet = require "skynetproto"
local log = require "log"
local timer = require "timer"

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 1000)

LOG_NAME = "redis_cached"

local redisd = ".redisd"

local table = table
local tinsert = table.insert
local tremove = table.remove

local cache = {}
local cachequeue = {}

local default_elapsed_time = 5

local function cache_push(key,value)
	cache[key] = value
	tinsert(cachequeue,key)
end

local function elapsed_cache_key()
	local time = os.time()
	local key
	local c
	for _ = 1,10000 do
		key = cachequeue[1]
		if not key then break end

		c = cache[key]
		if c then
			if time - c.time < default_elapsed_time then 
				break 
			end
			
			-- log.info("del cache key %s",key)
			cache[key] = nil
		end

		tremove(cachequeue,1)
	end

	timer.timeout(default_elapsed_time,elapsed_cache_key)
end

local function do_redis_command(...)
	return skynet.call(redisd,"lua","command",...)
end

local function new_commander(cmd,fn)
	return function(db,...)
		return fn(db,cmd,...)
	end
end

local function fold(list,tb)
	tb = tb or {}
	for i = 1,#list,2 do
		tb[list[i]] = list[i + 1]
	end
	return tb
end

local function expand(tb)
	local list = {}
	for k,v in pairs(tb) do
		tinsert(list,k)
		tinsert(list,v)
	end

	return list
end


local function hash_set(db,cmd,key,...)
	local c = cache[key]
	if c then
		fold({...},c.value)
	end

	return do_redis_command(db,cmd,key,...)
end

local function hash_get(db,cmd,key,...)
	local c = cache[key]
	if c then
		assert(type(c) == "table")
		local cvalue = c.value
		assert(type(cvalue) == "table")

		return expand(cvalue)
	end
	
	local data = do_redis_command(db,cmd,key,...)
	cache_push(key,{ value = fold(data),time = os.time()})

	return data
end

local function hash_get_set(db,cmd,key,field,...)
	local val = do_redis_command(db,cmd,key,field,...)

	local c = cache[key]
	if c then
		local cvalue = c.value
		cvalue[tostring(field)] = val
	end

	return val
end

local function hash_batch_get(db,cmd,key,...)
	local fields = {...}
	local c = cache[key]
	if c then
		assert(type(c) == "table")
		local cvalue = c.value
		assert(type(cvalue) == "table")

		local uncache_fields = table.series(fields,function(f)
			if not cvalue[f] then return f end
		end)

		if #uncache_fields > 0 then
			local uncache_values = do_redis_command(db,"hmget",key,table.unpack(uncache_fields))
			for i,f in pairs(uncache_fields) do
				cvalue[f] = uncache_values[i]
			end
		end
		
		local values = table.series(fields,function(f) return cvalue[f] end)
		return values
	end
	
	local data = do_redis_command(db,cmd,key,...)
	local c = cache[key]
	if c then
		local cvalue = c.value
		for i,f in pairs(fields) do
			cvalue[f] = data[i]
		end
	end

	return data
end

local function hash_del(db,cmd,key,...)
	local c = cache[key]
	if c then
		local cvalue = c.value
		for _,f in pairs({...}) do
			cvalue[tostring(f)] = nil
		end
	end

	return do_redis_command(db,cmd,key,...)
end

local function string_get(db,cmd,...)
	local keys = {...}

	local uncache_keys = table.series(keys,function(k)
		if not cache[k] then return k end
	end)

	if #uncache_keys > 0 then
		local uncache_values = do_redis_command(db,"mget",table.unpack(uncache_keys))
		for i,key in pairs(uncache_keys) do
			cache_push(key,{
				value = uncache_values[i],
				time = os.time(),
			})
		end
	end
	
	local values = table.series(keys,function(key) return cache[key].value end)
	return table.unpack(values)
end

local function string_set(db,cmd,...)
	local kvs = {...}
	for i = 1,#kvs,2 do
		cache[tostring(kvs[i])] = nil
	end
	return do_redis_command(db,cmd,...)
end

local function string_get_set(db,cmd,key,...)
	local val = do_redis_command(db,cmd,key,...)
	cache[key] = nil
	return val
end

local function set_add(db,cmd,key,...)
	local c = cache[key]
	if c then
		local cvalue = c.value
		for _,f in pairs({...}) do
			cvalue[tostring(f)] = true
		end
	end
	
	return do_redis_command(db,cmd,key,...)
end

local function set_get(db,cmd,key,...)
	local c = cache[key]
	if c then
		return table.keys(c.value)
	end

	local val = do_redis_command(db,cmd,key,...)
	cache_push(key,{
		time = os.time(),
		value = table.map(val,function(v) return v,true end),
	})
	return val
end

local function set_move(db,cmd,src,target,member,...)
	local src_c = cache[src]
	if src_c then
		src_c.value[tostring(member)] = nil
	end

	local target_c = cache[target]
	if target_c then
		target_c.value[tostring(member)] = true
	end
	
	return do_redis_command(db,src,target,member,...)
end

local function set_pop(db,cmd,key,...)
	local vals = do_redis_command(db,cmd,key,...)
	local c = cache[key]
	if c and vals then
		local cvalue = c.value
		for _,v in pairs(vals) do
			cvalue[tostring(v)] = nil
		end
	end

	return vals
end

local function set_del(db,cmd,key,...)
	local c = cache[key]
	if c then
		local cvalue = c.value
		for _,f in pairs({...}) do
			cvalue[tostring(f)] = nil
		end
	end

	return do_redis_command(db,cmd,key,...)
end

local function key_del(db,cmd,key,...)
	cache[key] = nil
	return do_redis_command(db,cmd,key,...)
end

local function key_rename(db,cmd,key1,key2,...)
	cache[key1] = nil
	cache[key2] = nil
	return do_redis_command(db,cmd,key1,key2,...)
end

local function key_expire(db,cmd,key,seconds,...)
	local c = cache[key]
	if c then
		c.time = os.time() + (seconds - default_elapsed_time + 1)
	end

	return do_redis_command(db,cmd,key,seconds,...)
end

local function key_expire_at(db,cmd,key,timestamp,...)
	local c = cache[key]
	if c then
		c.time = timestamp - (default_elapsed_time + 1)
	end

	return do_redis_command(db,cmd,key,timestamp,...)
end

local function key_pexpire(db,cmd,key,milliseconds,...)
	local c = cache[key]
	if c then
		c.time = os.time() + (math.ceil(milliseconds / 1000) - default_elapsed_time)
	end

	return do_redis_command(db,cmd,key,milliseconds,...)
end

local function key_pexpire_at(db,cmd,key,milliseconds_timestamp,...)
	local c = cache[key]
	if c then
		c.time = math.floor(milliseconds_timestamp / 1000) - (default_elapsed_time + 1)
	end

	return do_redis_command(db,cmd,key,milliseconds_timestamp,...)
end


local key_commander = {
	del = new_commander("del",key_del),
	rename = new_commander("rename",key_rename),
	expire = new_commander("expire",key_expire),
	expireat = new_commander("expireat",key_expire_at),
	pexpire = new_commander("pexpire",key_pexpire),
	pexpireat = new_commander("pexpireat",key_pexpire),
}

local command = {
	hset = new_commander("hset",hash_set),
	hmset = new_commander("hmset",hash_set),
	hmget = new_commander("hmget",hash_batch_get),
	hgetall = new_commander("hgetall",hash_get),
	hdel = new_commander("hdel",hash_del),
	hincrby = new_commander("hincrby",hash_get_set),
	hincrbyfloat = new_commander("hincrbyfloat",hash_get_set),

	get = new_commander("get",string_get),
	mget = new_commander("mget",string_get),
	set = new_commander("set",string_set),
	mset = new_commander("mset",string_set),
	incr = new_commander("incr",string_get_set),
	incrby = new_commander("incrby",string_get_set),
	incrbyfloat = new_commander("incrbyfloat",string_get_set),
	decr = new_commander("decr",string_get_set),
	decrby = new_commander("decrby",string_get_set),
	append = new_commander("append",string_get_set),

	sadd = new_commander("sadd",set_add),
	smembers = new_commander("smembers",set_get),
	smove = new_commander("smove",set_move),
	spop = new_commander("spop",set_pop),
	srem = new_commander("srem",set_del),

	del = new_commander("del",key_del),
	rename = new_commander("rename",key_rename),
	expire = new_commander("expire",key_expire),
	expireat = new_commander("expireat",key_expire_at),
	pexpire = new_commander("pexpire",key_pexpire),
	pexpireat = new_commander("pexpireat",key_pexpire),
}

setmetatable(command,{
	__index = function(c,cmd)
		local fn = function(db,...)
			return do_redis_command(db,cmd,...)
		end
		c[cmd] = fn
		return fn
	end
})

local CMD = {}

function CMD.command(db,cmd,...)
	return command[cmd](db,...)
end

function CMD.close(...)
    return skynet.call(redisd,"lua",...)
end

skynet.init(function()
	redisd = skynet.uniqueservice("service.redisd")
end)

skynet.start(function()
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else
			log.error("unknown cmd:"..cmd)
		end
	end)

	require "skynet.manager"
	local handle = skynet.localname ".cache_redisd"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".cache_redisd"

	elapsed_cache_key()
end)