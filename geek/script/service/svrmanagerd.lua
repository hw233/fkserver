local skynet = require "skynetproto"
local log = require "log"
local channel = require "channel"
local cluster = require "cluster"

local svrmanagerd = {}

local CMD = {}

function CMD.kill(_,id)
    
end

function CMD.warmdead(_,id)

end

function CMD.hotlaunch(_,id)

end


skynet.start(function()
    skynet.dispatch("lua", function (_, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(source,...))
        else
            log.error("channeld unknown cmd:%s",cmd)
            skynet.retpack(nil)
        end
    end)

    require "skynet.manager"
    local handle = skynet.localname ".svrmanagerd"
	if handle then
		skynet.exit()
		return
	end

	skynet.register ".svrmanagerd"
end)

return svrmanagerd