local redisopt = require "redisopt"
local private_table = require "game.lobby.base_private_table"

local reddb = redisopt.default

local club_table = {}

local cls_club_table = {}

function cls_club_table:get()
    return private_table[self.tid]
end

setmetatable(club_table,{
    __index = function(t,club_id)
        local tids = reddb:smembers(string.format("club:table:%s",club_id))
        local tbs = {}
        for _,tid in pairs(tids) do
            tid = tonumber(tid)
            tbs[tid] = setmetatable({tid = tid},{__index = cls_club_table})
        end

        return tbs
    end,
})


return club_table