
local redisopt = require "redisopt"

local reddb = redisopt.default
local redismetadata = require "redismetadata"

local base_money = {}


setmetatable(base_money,{
    __index = function(t,mid)
        local tb = reddb:hgetall("money:info:"..tostring(mid))

        tb = redismetadata.money:decode(tb)

        t[mid] = tb
        return tb
    end,
})


return base_money