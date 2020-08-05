local redisopt = require "redisopt"
require "functions"
local log = require "log"

local reddb = redisopt.default

local club_member = {}

setmetatable(club_member,{
    __index = function(t,club_id)
        local members = reddb:smembers("club:member:"..tostring(club_id))
        return members
    end,
})

return club_member