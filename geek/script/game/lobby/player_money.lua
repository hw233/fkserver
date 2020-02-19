local redisopt = require "redisopt"
local reddb  = redisopt.default

local player_money = {}

setmetatable(player_money,{
    __index = function(c,guid)
        local moneies = setmetatable({},{
            __index = function(t,money_id)
                local money = reddb:hget(string.format("player:money:%d",guid),money_id)
                money = tonumber(money) or 0
                return money
            end
        })
        c[guid] = moneies

        return moneies
    end,
})

return player_money