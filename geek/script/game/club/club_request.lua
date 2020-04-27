local redisopt = require "redisopt"
local base_request = require "game.club.base_request"
require "functions"

local reddb = redisopt.default

local club_request = {}

setmetatable(club_request,{
    __index = function(t,club_id)
        local ids = reddb:smembers(string.format("club:request:%s",club_id))
        local reqs = table.map(ids,function(id) return tonumber(id),true end)

        -- t[club_id] = reqs
        return reqs
    end,
})

return club_request