local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_partner_commission = {}

setmetatable(club_partner_commission,{
    __index = function(t,club_id)
        local m = setmetatable({},{
            __index = function(_,partner_id)
                if not partner_id then
                    local commissions = reddb:hgetall(string.format("club:partner:commission:%s",club_id))

                    local cms = table.map(commissions,function(scm,sp)
                        return tonumber(sp),tonumber(scm)
                    end)

                    return cms
                end

                local commission = reddb:hget(string.format("club:partner:commission:%s",club_id),partner_id)
                return tonumber(commission)
            end
        })

        t[club_id] = m
        return m
    end,
})

return club_partner_commission