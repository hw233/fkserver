
local redisopt = require "redisopt"
local redismetadata = require "redismetadata"

local reddb = redisopt.default

local table_template = {}

setmetatable(table_template,{
    __index = function(t,ttid)
        local temp = reddb:hgetall("club:tabletemplate:"..tostring(ttid))
        if not temp then
            return nil
        end

        temp = redismetadata.privatetable.template:decode(temp)
        t[ttid] = temp
        return temp
    end,
})

return table_template