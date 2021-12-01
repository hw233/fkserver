local redisopt = require "redisopt"

require "functions"

local reddb = redisopt.default

local club_partner_member = setmetatable({},{
    __index = function(tc,club_id)
        local m = setmetatable({},{
            __index = function(t,guid)
                local partner_ids = reddb:smembers(string.format("club:partner:member:%s:%s",club_id,guid))
                if not partner_ids or table.nums(partner_ids) == 0 then
                    return {}
                end

                return partner_ids
            end
        })

        tc[club_id] = m
        
        return m 
    end
})

return club_partner_member