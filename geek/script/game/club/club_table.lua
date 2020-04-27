local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_table = {}


setmetatable(club_table,{
    __index = function(t,club_id)
        local tids = reddb:smembers(string.format("club:table:%d",club_id))
        local tbs = table.map(tids,function(tid) return tonumber(tid),true end)
        -- t[club_id] = tbs
        return tbs
    end,
})


return club_table