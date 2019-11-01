local skynet = require "skynet"

function add_timer(delay, func)
	skynet.timeout(delay * 100,func)
end
