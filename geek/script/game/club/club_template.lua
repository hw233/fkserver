local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"

local reddb = redisopt.default

return wrap(function (t,club_id)
    local ttids = reddb:smembers(string.format("club:template:%d",club_id))
    t[club_id] = ttids
    return ttids
end, 3)