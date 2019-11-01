local skynet = require "skynet"
local channel = require "channel"

local CMD = {}

function CMD.handshake(source,msg)
    for id,conf in pairs(msg) do
        channel.subscribe(id,conf.addr,true)
    end
    return true
end


skynet.start(function() 
    skynet.dispatch("lua",function(source,cmd,...) 
        local f = CMD[cmd]
        if f then
            return f(source,...)
        else
            skynet.error(string.format("unknow cmd:%s",tostring(cmd)))
            return nil
        end
    end)

    require "skynet.manager"
	local handle = skynet.localname ".handshaked"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".handshaked"
end)