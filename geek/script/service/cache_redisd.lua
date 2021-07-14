local skynet = require "skynetproto"
local log = require "log"
local timer = require "timer"
local queue = require "skynet.queue"
require "functions"

require "functions"

LOG_NAME = "redis_cached"

local cached = ...

assert(cached)

cached = tonumber(cached)

local redisd

local table = table
local tinsert = table.insert
local tremove = table.remove
local fold_into = table.fold_into
local expand = table.expand

local cache = {}
local cachequeue = {}
local queuelock = setmetatable({},{
	__index = function(t,k)
		local q = queue()
		t[k] = q
		return q
	end,
	__call = function(t,key,fn,...)
		local l = t[key]
		return l(fn,...)
	end,
})

local default_elapsed_time = 10

local function cache_push(key,value)
	cache[key] = {
		value = value,
		time = os.time(),
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
		queuelock[key] = nil
	end
	return true
end

local function elapsed_cache_key()
	local key
	for _ = 1,1000 do
		key = tremove(cachequeue,1)
		if not key then break end
		
		if not queuelock(key,check_clean_cache,key) then
			tinsert(cachequeue,key)
		end
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

local function hash_set(db,cmd,key,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			fold_into({...},c.value)
		end

		return do_redis_command(db,cmd,key,...)
	end,...)
end

local function hash_get(db,cmd,key,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			local cvalue = c.value

			return expand(cvalue)
		end
		
		local data = do_redis_command(db,cmd,key,...)
		
		cache_push(key,fold_into(data))

		return data
	end,...)
end

local function hash_get_set(db,cmd,key,field,...)
	return queuelock(key,function(...)
		local val = do_redis_command(db,cmd,key,field,...)

		local c = cache[key]
		if c then
			local cvalue = c.value
			cvalue[tostring(field)] = val
		end

		return val
	end,...)
end

local function hash_batch_get(db,cmd,key,...)
	return queuelock(key,function(...)
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
	end,...)
end

local function hash_del(db,cmd,key,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			local cvalue = c.value
			for _,f in pairs({...}) do
				cvalue[tostring(f)] = nil
			end
		end

		return do_redis_command(db,cmd,key,...)
	end,...)
end

local function string_get(db,cmd,key)
	return queuelock(key,function() 
		local c = cache[key]
		if c then
			return c.value
		end

		local v = do_redis_command(db,"get",key)
		cache_push(key,v)
		return v
	end)
end

local function string_mget(db,cmd,...)
	return do_redis_command(db,cmd,...)
end

local function string_set(db,cmd,key,val)
	return queuelock(key,function()
		local c = cache[key]
		if c then
			c.value = val
		end
		return do_redis_command(db,cmd,key,val)
	end)
end

local function string_mset(db,cmd,...)
	local kvs = {...}
	for i = 1,#kvs,2 do
		cache[tostring(kvs[i])] = nil
	end
	return do_redis_command(db,cmd,...)
end

local function string_get_set(db,cmd,key,...)
	return queuelock(key,function(...)
		local val = do_redis_command(db,cmd,key,...)
		cache[key] = nil
		return val
	end,...)
end

local function set_add(db,cmd,key,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			local cvalue = c.value
			for _,f in pairs({...}) do
				cvalue[tostring(f)] = true
			end
		end
		
		return do_redis_command(db,cmd,key,...)
	end,...)
end

local function set_get(db,cmd,key,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			return table.keys(c.value)
		end

		local val = do_redis_command(db,cmd,key,...)
		cache_push(key,table.map(val,function(v) return v,true end))
		return val
	end,...)
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
	return queuelock(key,function(...)
		local vals = do_redis_command(db,cmd,key,...)
		local c = cache[key]
		if c and vals then
			local cvalue = c.value
			for _,v in pairs(vals) do
				cvalue[tostring(v)] = nil
			end
		end

		return vals
	end,...)
end

local function set_del(db,cmd,key,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			local cvalue = c.value
			for _,f in pairs({...}) do
				cvalue[tostring(f)] = nil
			end
		end

		return do_redis_command(db,cmd,key,...)
	end,...)
end

local function key_del(db,cmd,key,...)
	return queuelock(key,function(...)
		cache[key] = nil
		queuelock[key] = nil
		return do_redis_command(db,cmd,key,...)
	end,...)
end

local function key_rename(db,cmd,key1,key2,...)
	cache[key1] = nil
	cache[key2] = nil
	return do_redis_command(db,cmd,key1,key2,...)
end

local function key_expire(db,cmd,key,seconds,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			c.time = os.time() + (seconds - default_elapsed_time + 1)
		end

		return do_redis_command(db,cmd,key,seconds,...)
	end,...)
end

local function key_expire_at(db,cmd,key,timestamp,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			c.time = timestamp - (default_elapsed_time + 1)
		end

		return do_redis_command(db,cmd,key,timestamp,...)
	end,...)
end

local function key_pexpire(db,cmd,key,milliseconds,...)
	return queuelock(key,function(...)
		local c = cache[key]
		if c then
			c.time = os.time() + (math.ceil(milliseconds / 1000) - default_elapsed_time)
		end

		return do_redis_command(db,cmd,key,milliseconds,...)
	end,...)
end

local command = {
	hset = new_commander("hset",hash_set),
	hmset = new_commander("hmset",hash_set),
	hmget = new_commander("hmget",hash_batch_get),
	hgetall = new_commander("hgetall",hash_get),
	hdel = new_commander("hdel",hash_del),
	hincrby = new_commander("hincrby",hash_get_set),
	hincrbyfloat = new_commander("hincrbyfloat",hash_get_set),

	get = new_commander("get",string_get),
	mget = new_commander("mget",string_mget),
	set = new_commander("set",string_set),
	mset = new_commander("mset",string_mset),
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

skynet.start(function()	
	redisd = skynet.call(cached,"lua","REDIS")
	skynet.dispatch("lua", function (_, _,db,cmd,...)
		local f = command[cmd]
		skynet.retpack(f(cmd,...))
	end)

	-- elapsed_cache_key()
end)