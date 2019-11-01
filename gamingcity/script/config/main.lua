local skynet = require "skynet"
local msgopt = require "msgopt"

skynet.start(function() 
    require "config.register"
    skynet.dispatch("lua",function(_, address, cmd, ...) 
        skynet.retpack(msgopt.on_msg(address,cmd,...))
    end)
end)