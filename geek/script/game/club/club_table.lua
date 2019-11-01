local redisopt = require "redisopt"
local private_table = require "game.lobby.base_private_table"

local reddb = redisopt.default

local club_table = {}

setmetatable(club_table,{
    __index = function(t,club_id)
        local tids = reddb:smembers(string.format("club:table:%s",club_id))
        local tbs = {}
        for _,tid in pairs(tids) do
            tid = tonumber(tid)
            tbs[tid] = private_table[tid]
        end
        
        return tbs
    end,
})


return club_table