local redisopt = require "redisopt"

local xpcall = xpcall
local traceback = debug.traceback

local reddb = redisopt.defaut

local function unlock(id,ok,...)
	reddb:del(id)
	return ...
end

local function spinlock(id)
	local exist
	repeat
		exist = reddb:exists(id)
	until not exist
	reddb:set(id,1)
end

return function(id,fn,...)
	spinlock(id)
	return unlock(id,xpcall(fn,traceback,...))
end