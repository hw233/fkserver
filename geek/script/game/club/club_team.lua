local redisopt = require "redisopt"

local reddb = redisopt.default

local club_team = {}

setmetatable(club_team,{
    __index = function(t,club_id)
        local ms = {}
        local teams = reddb:smembers("club:team:"..tostring(club_id))
        for _,tid in pairs(teams) do
            ms[tonumber(tid)] = true
        end

        -- t[club_id] = ms --多游服情况下，不缓存
        return ms
    end,
})

return club_team