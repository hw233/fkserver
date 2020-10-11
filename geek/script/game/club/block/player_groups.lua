local redisopt = require "redisopt"
local reddb = redisopt.default

local player_groups = setmetatable({},{
    __index = function(t,club_id)
        local gs = setmetatable({},{
            __index = function(_,guid)
                local groups = reddb:smembers(string.format("club:block:player:group:%s:%s",club_id,guid))
                return groups
            end
        })
        t[club_id] = gs
        return gs
    end
})

return player_groups