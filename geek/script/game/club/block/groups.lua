
local redisopt = require "redisopt"

local reddb = redisopt.default

local groups = setmetatable({},{
    __index = function(_,club_id)
        local gs = reddb:smembers(string.format("club:block:groups:%s",club_id))
        return table.map(gs,function(v) return tonumber(v),true end)
    end,
    __newindex = function(_,club_id,group_id)
        reddb:sadd(string.format("club:block:groups:%s",club_id),group_id)
    end,
})

return groups