
local string = string
local tolower = string.lower

local netmsgopt = setmetatable({},{
    __index = function(t,protocol)
        local netmsg
        if tolower(protocol) == "ws" then
            netmsg =  require "gate.netmsgwsopt"
            t[protocol] = netmsg
        else
            netmsg = require "gate.netmsgrawopt"
        end

        return netmsg
    end
})

return netmsgopt