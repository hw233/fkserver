local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_notice = {}

setmetatable(club_notice,{
    __index = function(t, club_id)
        local nids = reddb:smembers("club:notice:" .. tostring(club_id))
        t[club_id] = nids
        return nids
    end
})

return club_notice
