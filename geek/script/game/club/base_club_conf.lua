
local redismetadata = require "redismetadata"
local redisopt = require "redisopt"

local reddb = redisopt.default

local base_club_conf = {}


setmetatable(base_club_conf,{
    __index = function(t,club_id)
        local conf = reddb:smembers("club:conf:"..tostring(club_id))

        conf = redismetadata.club.conf:decode(conf)
    
        t[club_id] = conf
        return conf
    end,
})

return base_club_conf