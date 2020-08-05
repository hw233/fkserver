
local redisopt = require "redisopt"

local reddb = redisopt.default

local base_money = {}

setmetatable(base_money,{
    __index = function(t,mid)
        local tb = reddb:hgetall("money:info:"..tostring(mid))
        t[mid] = tb
        return tb
    end,
})


return base_money