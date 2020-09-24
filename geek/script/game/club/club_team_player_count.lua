local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_team_player_count = {}

setmetatable(club_team_player_count,{
    __index = function(t,club_id)
        local tc = setmetatable({},{
            __index = function(_,partner_id)
                local count = reddb:hget(string.format("club:team_player_count:%s",club_id),partner_id)
                return count and tonumber(count) or 0
            end
        })

        t[club_id] = tc
        return tc
    end,
})

return club_team_player_count