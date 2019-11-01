local channel = require "channel"

local confs = {}

setmetatable(confs,{
    __index = function(t,k)
        local conf = channel.call("config.?","msg","query_service_conf",tonumber(k))
        if not conf then
            return nil
        end

        t[k] = conf
        return conf
    end
})

return confs