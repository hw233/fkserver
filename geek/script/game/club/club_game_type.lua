
local redisopt = require "redisopt"

local reddb = redisopt.default

local club_game_type = {}


setmetatable(club_game_type,{
    __index = function(t,club_id)
        local ids = reddb:smembers("club:game:"..tostring(club_id))
        for i = 1,#ids do
            ids[i] = true
        end

        t[club_id] = ids
        return ids
    end,
})


return club_game_type