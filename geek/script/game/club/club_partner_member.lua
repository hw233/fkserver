local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"
require "functions"

local reddb = redisopt.default

return wrap(function (t,club_id)
    local m =  setmetatable({},{
        __index = function(c,guid)
            local partner_ids = reddb:smembers(string.format("club:partner:member:%s:%s",club_id,guid))
            if not partner_ids or table.nums(partner_ids) == 0 then
                return {}
            end
            c[guid] = partner_ids
            return partner_ids
        end
    })

    t[club_id] = m 
    return m 
end, 3)