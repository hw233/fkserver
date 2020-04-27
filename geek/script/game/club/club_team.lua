local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_team = {}

setmetatable(club_team,{
    __index = function(t,club_id)
        local teams = reddb:smembers("club:team:"..tostring(club_id))
        local ms = table.map(teams,function(tid) return tonumber(tid),true end)

        -- t[club_id] = ms --多游服情况下，不缓存
        return ms
    end,
})

return club_team