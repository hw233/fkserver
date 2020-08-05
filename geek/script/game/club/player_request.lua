local redisopt = require "redisopt"
require "functions"


local reddb = redisopt.default

local player_request = {}

setmetatable(player_request,{
    __index = function(t,guid)
        local reqids = reddb:smembers(string.format("player:request:%s",guid))
        t[guid] = reqids

        return reqs
    end,
})

return player_request