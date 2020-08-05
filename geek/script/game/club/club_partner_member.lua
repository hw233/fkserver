local redisopt = require "redisopt"

require "functions"

local reddb = redisopt.default

local club_partner_member = setmetatable({},{
    __index = function(_,club_id)
        return setmetatable({club_id = club_id},{
            __index = function(t,guid)
                local partner_ids = reddb:smembers(string.format("club:partner:member:%s:%s",t.club_id,guid))
                if not partner_ids or table.nums(partner_ids) == 0 then
                    return {}
                end

                return partner_ids
            end
        })
    end
})

return club_partner_member