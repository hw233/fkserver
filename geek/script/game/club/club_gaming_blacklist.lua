local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"

local reddb = redisopt.default

return wrap(function (t,club_id)
    local blacklist = reddb:smembers("club:blacklist:gaming:"..tostring(club_id))
    t[club_id] = blacklist
  
    return blacklist
end, 3)