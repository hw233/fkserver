local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_conf = {}

setmetatable(club_conf,{
    __index = function(t,club_id)
        local conf = reddb:hgetall(string.format("club:conf:%d",club_id))

        return conf
    end,
})

return club_conf