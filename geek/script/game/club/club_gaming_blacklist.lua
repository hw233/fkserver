
local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local gaming_blacklist = {}

local log = require "log"

setmetatable(gaming_blacklist,{
    __index = function(_,club_id)
        local blacklist = reddb:smembers("club:blacklist:gaming:"..tostring(club_id))
        return blacklist
    end,
})

return gaming_blacklist