local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local fast_template = {}

setmetatable(fast_template,{
    __index = function(_,club_id)
        local id_indexes = reddb:hgetall("club:fast_template:"..tostring(club_id))
        return id_indexes
    end,
})


return fast_template