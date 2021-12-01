local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"

local reddb = redisopt.default

return wrap(function (t,club_id)
    local mems = reddb:smembers("club:member:"..tostring(club_id))
    t[club_id] = mems
    return mems
end, 3)