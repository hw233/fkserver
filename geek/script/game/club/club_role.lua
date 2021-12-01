local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"

local reddb = redisopt.default

return wrap(function (t_club,club_id)
    local mt = setmetatable({},{
        __index = function(t,guid)
            if not guid then
                local rs = reddb:hgetall("club:role:"..tostring(club_id))
                return rs
            end
            local role = reddb:hget(string.format("club:role:%s",club_id),guid)
            t[guid] = tonumber(role)
            return tonumber(role)
        end
    })

    t_club[club_id] = mt
    return mt
end, 3)