local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_money = {}

setmetatable(club_money,{
    __index = function(c,club_id)
        local moneies = setmetatable({},{
            __index = function(t,money_id)
                local money = reddb:hget(string.format("club:money:%d",club_id),money_id)
                money = tonumber(money) or 0
                t[money_id] = money
                return money
            end
        })
        c[club_id] = moneies

        return moneies
    end,
})

return club_money