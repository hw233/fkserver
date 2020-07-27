local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_partner_commission = {}

setmetatable(club_partner_commission,{
    __index = function(_,club_id)
        local commissions = reddb:hgetall(string.format("club:partner:commission:%s",club_id))

        local cms = table.map(commissions,function(scm,sp)
            return tonumber(sp),tonumber(scm)
        end)

        return cms
    end,
})

return club_partner_commission