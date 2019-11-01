
local netmsgopt = {}


function netmsgopt.protocol(proto)
    local opt
    if proto == "ws" then
        opt = require "netmsgwsopt"
        for k,v in pairs(opt) do
            netmsgopt[k] = v            
        end
    else
        opt = require "netmsgrawopt"
        for k,v in pairs(opt) do
            netmsgopt[k] = v            
        end
    end
end

return netmsgopt