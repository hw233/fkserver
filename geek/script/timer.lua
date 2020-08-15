local skynet = require "skynet"

local timer = {}

function timer.add_timer(delay, func)
	skynet.timeout(delay * 100,func)
end

timer.timeout = timer.add_timer

return timer