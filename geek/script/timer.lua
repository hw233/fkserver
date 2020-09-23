local skynet = require "skynet"

local timer = {}

function timer.add_timer(delay, func)
	skynet.timeout(delay * 100,func)
end

timer.timeout = timer.add_timer

function timer.ms_time()
	return math.floor(skynet.time() * 1000)
end

return timer