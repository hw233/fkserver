local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_team = {}

setmetatable(club_team,{
    __index = function(t,club_id)
        local teams = reddb:smembers("club:team:"..tostring(club_id))
        return teams
    end,
})

return club_team