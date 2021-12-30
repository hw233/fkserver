local skynet = require "skynetproto"
local log = require "log"
local timer = require "timer"
local lock = require "lock"
local redism = require "redism"
require "functions"

LOG_NAME = "redis_cached"

local cached = ...

assert(cached)

cached = tonumber(cached)

local string = string
local table = table
local tinsert = table.insert
local tremove = table.remove
local fold_into = table.fold_into
local expand = table.expand

local METATYPE = {
	MT_NIL = 0,
	MT_HASH = 1,
	MT_STRING = 2,
	MT_SET = 3,
	MT_SSET = 4,
	MT_LIST = 5,
}

local CMD_MT = {
	hset = METATYPE.MT_HASH,
	hmset = METATYPE.MT_HASH,
	hget = METATYPE.MT_HASH,
	hmget = METATYPE.MT_HASH,
	hdel = METATYPE.MT_HASH,
	hexists = METATYPE.MT_HASH,
	hgetall = METATYPE.MT_HASH,
	hincrby = METATYPE.MT_HASH,
	hincrbyfloat = METATYPE.MT_HASH,
	hkeys = METATYPE.MT_HASH,
	hlen = METATYPE.MT_HASH,
	hsetnx = METATYPE.MT_HASH,
	hvals = METATYPE.MT_HASH,
	hscan = METATYPE.MT_HASH,

	append = METATYPE.MT_STRING,
	bitcount = METATYPE.MT_STRING,
	bitop = METATYPE.MT_STRING,
	decr = METATYPE.MT_STRING,
	decrby = METATYPE.MT_STRING,
	get = METATYPE.MT_STRING,
	getbit = METATYPE.MT_STRING,
	getrange = METATYPE.MT_STRING,
	getset = METATYPE.MT_STRING,
	incr = METATYPE.MT_STRING,
	incrby = METATYPE.MT_STRING,
	incrbyfloat = METATYPE.MT_STRING,
	set = METATYPE.MT_STRING,
	setbit = METATYPE.MT_STRING,
	setex = METATYPE.MT_STRING,
	setnx = METATYPE.MT_STRING,
	setrange = METATYPE.MT_STRING,
	strlen = METATYPE.MT_STRING,

	blpop = METATYPE.MT_LIST,
	brpop = METATYPE.MT_LIST,
	brpoplpush = METATYPE.MT_LIST,
	lindex = METATYPE.MT_LIST,
	linsert = METATYPE.MT_LIST,
	llen = METATYPE.MT_LIST,
	lpop = METATYPE.MT_LIST,
	lpush = METATYPE.MT_LIST,
	lpushx = METATYPE.MT_LIST,
	lrange = METATYPE.MT_LIST,
	lrem = METATYPE.MT_LIST,
	lset = METATYPE.MT_LIST,
	ltrim = METATYPE.MT_LIST,
	rpop = METATYPE.MT_LIST,
	rpoplpush = METATYPE.MT_LIST,
	rpush = METATYPE.MT_LIST,
	rpushx = METATYPE.MT_LIST,

	sadd = METATYPE.MT_SET,
	scard = METATYPE.MT_SET,
	sismember = METATYPE.MT_SET,
	smembers = METATYPE.MT_SET,
	smove = METATYPE.MT_SET,
	spop = METATYPE.MT_SET,
	srandmember = METATYPE.MT_SET,
	srem = METATYPE.MT_SET,
	sscan = METATYPE.MT_SET,

	zadd = METATYPE.MT_SSET,
	zcard = METATYPE.MT_SSET,
	zcount = METATYPE.MT_SSET,
	zincrby = METATYPE.MT_SSET,
	zrange = METATYPE.MT_SSET,
	zrangebyscore = METATYPE.MT_SSET,
	zrank = METATYPE.MT_SSET,
	zrem = METATYPE.MT_SSET,
	zremrangebyrank = METATYPE.MT_SSET,
	zremrangebyscore = METATYPE.MT_SSET,
	zrevrange = METATYPE.MT_SSET,
	zrevrangebyscore = METATYPE.MT_SSET,
	zrevrank = METATYPE.MT_SSET,
	zscore = METATYPE.MT_SSET,
	zscan = METATYPE.MT_SSET,
}

setmetatable(CMD_MT,{
	__index = function()
		return METATYPE.MT_NIL
	end
})

local cache = {}
local cachequeue = {}
local keylock = setmetatable({},{
	__index = function(t,k)
		local l = lock()
		t[k] = l
		return l
	end
})

local function batch_lock(...)
	local ls = {}
	local l
	for _,k in pairs({...}) do
		l = keylock[k]
		l:lock()
		tinsert(ls,l)
	end
	return ls
end

local function batch_unlock(ls)
	for _,l in pairs(ls or {}) do
		l:unlock()
	end
end

local function batch_lock_ret(ls,...)
	batch_unlock(ls)
	return ...
end

local default_elapsed_time = 10

local function set_cache(key,value,mt)
	cache[key] = {
		value = value,
		time = os.time(),
		mt = mt,
	}
	-- tinsert(cachequeue,key)
end

local function check_clean_cache(key)
	local c = cache[key]
	if c then
		if os.time() - c.time < default_elapsed_time then 
			return
		end
		
		log.info("del cache key %s",key)
		cache[key] = nil
	end
	return true
end

local function elapsed_cache_key()
	local key
	for _ = 1,1000 do
		key = tremove(cachequeue,1)
		if not key then break end
		
		local l = keylock[key]
		if not l(check_clean_cache,key) then
			tinsert(cachequeue,key)
		end
	end

	timer.timeout(default_elapsed_time,elapsed_cache_key)
end

local function do_redis_command(...)
	return redism.command(...)
end

local function new_commander(cmd,fn)
	assert(cmd)
	assert(not fn or type(fn) == "function")
	fn = fn or do_redis_command
	cmd = string.lower(cmd)
	return function(db,...)
		return fn(db,cmd,...)
	end
end

local function new_lock_commander(cmd,fn)
	assert(cmd)
	assert(not fn or type(fn) == "function")
	fn = fn or do_redis_command
	cmd = string.lower(cmd)
	return function(db,key,...)
		local l = keylock[key]
		return l(fn,db,cmd,key,...)
	end
end

local function hash_set(db,cmd,key,...)
	local c = cache[key]
	if c then
		fold_into({...},c.value)
	end

	return do_redis_command(db,cmd,key,...)
end

local function hash_get(db,cmd,key,...)
	local c = cache[key]
	if c then
		return expand(c.value)
	end
	
	local data = do_redis_command(db,cmd,key,...)
	
	set_cache(key,fold_into(data))

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
		local cvalue = c.value

		local uncache_fields = table.series(fields,function(f)
			if not cvalue[f] then return f end
		end)

		if #uncache_fields > 0 then
			local fvalues = do_redis_command(db,"hmget",key,table.unpack(fields))
			for i,f in pairs(fields) do
				cvalue[f] = fvalues[i]
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

local function string_get(db,cmd,key)
	local c = cache[key]
	if c then
		return c.value
	end

	local v = do_redis_command(db,"get",key)
	set_cache(key,v)
	return v
end

local function string_mget(db,cmd,...)
	local ls = batch_lock(...)
	return batch_lock_ret(ls,do_redis_command(db,cmd,...))
end

local function string_set(db,cmd,key,val)
	local c = cache[key]
	if c then
		c.value = val
	end
	return do_redis_command(db,cmd,key,val)
end

local function string_setex(db,cmd,key,sec,val)
	local c = cache[key]
	if c then
		c.value = val
	end
	return do_redis_command(db,cmd,key,val)
end

local function string_mset(db,cmd,...)
	local ls = batch_lock(...)
	local kvs = {...}
	for i = 1,#kvs,2 do
		cache[tostring(kvs[i])] = nil
	end
	return batch_lock_ret(ls,do_redis_command(db,cmd,...))
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
	set_cache(key,table.map(val,function(v) return v,true end))
	return val
end

local function set_move(db,cmd,src,target,member,...)
	local ls = batch_lock(src,target)
	local src_c = cache[src]
	if src_c then
		src_c.value[tostring(member)] = nil
	end

	local target_c = cache[target]
	if target_c then
		target_c.value[tostring(member)] = true
	end
	
	return batch_lock_ret(ls,do_redis_command(db,cmd,src,target,member,...))
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

local function set_store(db,cmd,dest,...)
	cache[dest] = nil
	return do_redis_command(db,cmd,dest,...)
end

local function key_del(db,cmd,key,...)
	cache[key] = nil
	return do_redis_command(db,cmd,key,...)
end

local function key_rename(db,cmd,key1,key2,...)
	local ls = batch_lock(key1,key2)
	cache[key1] = nil
	cache[key2] = nil
	batch_lock_ret(ls,do_redis_command(db,cmd,key1,key2,...))
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

local command = {
	hset = new_lock_commander("hset",hash_set),
	hsetnx = new_lock_commander("hsetnx",hash_set),
	hmset = new_lock_commander("hmset",hash_set),
	hmget = new_lock_commander("hmget",hash_batch_get),
	hgetall = new_lock_commander("hgetall",hash_get),
	hdel = new_lock_commander("hdel",hash_del),
	hincrby = new_lock_commander("hincrby",hash_get_set),
	hincrbyfloat = new_lock_commander("hincrbyfloat",hash_get_set),

	get = new_lock_commander("get",string_get),
	mget = new_commander("mget",string_mget),
	set = new_lock_commander("set",string_set),
	setnx = new_lock_commander("setnx",string_set),
	setex = new_lock_commander("setex",string_setex),
	mset = new_commander("mset",string_mset),
	msetnx = new_commander("msetnx",string_mset),
	incr = new_lock_commander("incr",string_get_set),
	incrby = new_lock_commander("incrby",string_get_set),
	incrbyfloat = new_lock_commander("incrbyfloat",string_get_set),
	decr = new_lock_commander("decr",string_get_set),
	decrby = new_lock_commander("decrby",string_get_set),
	append = new_lock_commander("append",string_get_set),

	sadd = new_lock_commander("sadd",set_add),
	smembers = new_lock_commander("smembers",set_get),
	smove = new_commander("smove",set_move),
	spop = new_lock_commander("spop",set_pop),
	srem = new_lock_commander("srem",set_del),
	sdiffstore = new_lock_commander("sdiffstore",set_store),
	sinterstore = new_lock_commander("sinterstore",set_store),
	sunionstore = new_lock_commander("sunionstore",set_store),
	srandmember = new_lock_commander("srandmember"),

	del = new_lock_commander("del",key_del),
	rename = new_commander("rename",key_rename),
	expire = new_lock_commander("expire",key_expire),
	expireat = new_lock_commander("expireat",key_expire_at),
	pexpire = new_lock_commander("pexpire",key_pexpire),
	pexpireat = new_lock_commander("pexpireat",key_pexpire),
}

setmetatable(command,{
	__index = function(c,cmd)
		local fn = function(db,...)
			return do_redis_command(db,string.lower(cmd),...)
		end
		c[cmd] = fn
		return fn
	end
})

skynet.start(function()	
	skynet.dispatch("lua", function (_, _,db,cmd,...)
		local f = command[cmd]
		skynet.retpack(f(db,...))
	end)

	-- elapsed_cache_key()
end)