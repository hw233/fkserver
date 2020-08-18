local redisopt = require "redisopt"
local reddb  = redisopt.default
local redismetadata = require "redismetadata"

local club_conf = {}

setmetatable(club_conf,{
    __index = function(t,club_id)
        local conf = reddb:hgetall(string.format("club:conf:%d",club_id))

        conf = redismetadata.club.conf:decode(conf)

        return conf
    end,
})

return club_conf