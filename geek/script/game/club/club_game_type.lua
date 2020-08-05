
local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_game_type = {}


setmetatable(club_game_type,{
    __index = function(t,club_id)
        local ids = reddb:smembers("club:game:"..tostring(club_id))
        return ids
    end,
})


return club_game_type