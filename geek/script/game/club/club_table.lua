local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_table = {}

-- 俱乐部的所有房间号
setmetatable(club_table,{
    __index = function(t,club_id)
        local tids = reddb:smembers(string.format("club:table:%d",club_id))
        return tids
    end,
})


return club_table