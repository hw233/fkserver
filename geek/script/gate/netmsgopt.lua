
local string = string
local tolower = string.lower

local netmsgopt = setmetatable({},{
    __index = function(t,protocol)
        local netmsg
        if tolower(protocol) == "ws" then
            netmsg =  require "gate.netmsgwsopt"
        else
            netmsg = require "gate.netmsgrawopt"
        end

        t[protocol] = netmsg

        return netmsg
    end
})

return netmsgopt