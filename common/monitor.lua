
local skynet = require "skynet.manager"

local monitord = ".monitord"

local monitor = {}

function monitor.start(servicename,...)

end

function monitor.kill(servicename)

end

function monitor.restart(servicename)

end

function monitor.watch(servicename)
	
end

skynet.init(function()
	monitord = skynet.monitor("monitord")
end)

return monitor