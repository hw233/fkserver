local redisopt = require "redisopt"
local reddb = redisopt.default

local group_teams = setmetatable({},{
    __index = function(t,club_id)
        local ps = setmetatable({},{
            __index = function(_,group_id)
                local teams = reddb:smembers(string.format("club:block:group:team:%s:%s",club_id,group_id))
                return teams
            end
        })
        t[club_id] = ps
        return ps
    end
})

return group_teams