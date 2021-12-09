
local redisopt = require "redisopt"

local reddb = redisopt.default

local log = require "log"

local groups = setmetatable({},{
    __index = function(_,club_id)
        local gs = reddb:smembers(string.format("club:block:groups:%s",club_id))
        return gs
    end,
})

return groups