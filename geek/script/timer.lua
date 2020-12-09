local skynet = require "skynet"
local chronos = require "chronos"

local timer = {}

function timer.add_timer(delay, func)
	skynet.timeout(delay * 100,func)
end

timer.timeout = timer.add_timer

function timer.milliseconds_time()
	return math.floor(chronos.nanotime() * 1000)
end

function timer.nanotime()
	return chronos.nanotime()
end

return timer