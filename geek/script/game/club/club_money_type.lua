local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_money_type = {}

setmetatable(club_money_type,{
    __index = function(c,club_id)
        local money_id = reddb:get(string.format("club:money_type:%d",club_id))
        money_id = tonumber(money_id)

        c[club_id] = money_id

        return money_id
    end,
})

return club_money_type