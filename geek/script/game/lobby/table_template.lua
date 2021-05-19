
local redisopt = require "redisopt"

local reddb = redisopt.default

local table_template = {}

setmetatable(table_template,{
    __index = function(t,ttid)
        local temp = reddb:hgetall("template:"..tostring(ttid))
        if not temp or table.nums(temp) == 0 then
            return nil
        end

        -- t[ttid] = temp

        return temp
    end,
})

return table_template