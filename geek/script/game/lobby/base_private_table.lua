
local redisopt = require "redisopt"

local reddb = redisopt.default
local redismetadata = require "redismetadata"

local private_table = {}


setmetatable(private_table,{
    __index = function(t,tid)
        local tb = reddb:hgetall("table:info:"..tostring(tid))
        
        tb = redismetadata.privatetable.info:decode(tb)

        t[tid] = table.nums(tb) > 0 and tb or nil
        return tb
    end,
})


return private_table