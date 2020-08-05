
local redisopt = require "redisopt"

local reddb = redisopt.default
local log = require "log"

local private_table = {}


setmetatable(private_table,{
    __index = function(t,tid)
        local tb = reddb:hgetall("table:info:"..tostring(tid))
        return table.nums(tb) > 0 and tb or nil
    end,
})


return private_table