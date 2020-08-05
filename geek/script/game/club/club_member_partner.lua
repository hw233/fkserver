local redisopt = require "redisopt"

require "functions"

local reddb = redisopt.default

local club_member_partner = setmetatable({},{
    __index = function(_,club_id)
        local partner_ids = reddb:hgetall(string.format("club:member:partner:%s",club_id))
        if not partner_ids or table.nums(partner_ids) == 0 then
            return {}
        end

        return partner_ids
    end
})

return club_member_partner