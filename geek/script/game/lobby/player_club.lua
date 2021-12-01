local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"

local reddb = redisopt.default

return wrap(function(t,guid)
    local tps = setmetatable({},{
        __index = function(tb,tp)
            local clubs = reddb:smembers(string.format("player:club:%d:%d",guid,tp))
            tb[tp] = clubs
            return clubs
        end
    })
    t[guid] = tps
    return tps
end, 3)