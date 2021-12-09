local redisopt = require "redisopt"
local reddb = redisopt.default
local wrap = require "fast_cache_wrap"

return wrap(function (t,club_id)
    local gs = setmetatable({},{
        __index = function(g,team_id)
            local groups = reddb:smembers(string.format("club:block:team:group:%s:%s",club_id,team_id))
            g[team_id] = groups
            return groups
        end
    })
    t[club_id] = gs
    return gs
end, 3)