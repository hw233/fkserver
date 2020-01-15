local redisopt = require "redisopt"
local reddb = redisopt.default

local club_table = {}


setmetatable(club_table,{
    __index = function(t,club_id)
        local tids = reddb:smembers(string.format("club:table:%d",club_id))
        local tbs = {}
        for _,id in pairs(tids) do
            tbs[tonumber(id)] = true
        end

        t[club_id] = tbs

        return tbs
    end,
})


return club_table