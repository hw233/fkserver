local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_commission = {}

setmetatable(club_commission,{
    __index = function(t,club_id)
        local commission = reddb:get(string.format("club:commission:%d",club_id))
        return commission
    end,
})

return club_commission