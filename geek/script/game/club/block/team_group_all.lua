
local redisopt = require "redisopt"

local reddb = redisopt.default

local team_group_all = setmetatable({},{
    __index = function(_,club_id)
        local gs = reddb:smembers(string.format("club:block:team:group:all:%s",club_id))
        return gs
    end,
})

return team_group_all