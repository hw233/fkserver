local redisopt = require "redisopt"
require "functions"
local redismetadata = require "redismetadata"

local reddb = redisopt.default

local base_moneies = {}

setmetatable(base_moneies,{
    __index = function(t,money_id)
        local money_info = reddb:hgetall(string.format("money:info:%s",money_id))
        money_info = redismetadata.money:decode(money_info)
        t[money_id] = money_info
        return money_info
    end,
})

return base_moneies