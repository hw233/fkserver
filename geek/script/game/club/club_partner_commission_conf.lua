local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_partner_commission_conf = {}

setmetatable(club_partner_commission_conf,{
    __index = function(t,club_id)
        local m = setmetatable({},{
            __index = function(c,partner_id)
                local cnf = reddb:hget(string.format("club:partner:commision:conf:%s",club_id),partner_id) or {}
                return cnf    
            end
        })

        t[club_id] = m
        return m
    end,
})

return club_partner_commission_conf