local redisopt = require "redisopt"
local reddb = redisopt.default
local wrap = require "fast_cache_wrap"

return wrap(function (t,club_id)
    local gs = setmetatable({},{
         __index = function(g,guid)
            local groups = reddb:smembers(string.format("club:block:player:group:%s:%s",club_id,guid))
            g[guid] = groups
            return groups
        end
    })
    t[club_id] = gs
    return gs
end, 3)