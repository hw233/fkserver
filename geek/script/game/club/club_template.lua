local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_template = {}

setmetatable(club_template,{
    __index = function(t,club_id)
        local ttids = reddb:smembers(string.format("club:template:%d",club_id))

        return ttids
    end
})


return club_template