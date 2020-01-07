local skynet = require "skynet"

local timer = {}

function timer.add_timer(delay, func)
	skynet.timeout(delay * 100,func)
end

return timer