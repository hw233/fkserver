local redisopt = require "redisopt"
local base_request = require "game.club.base_request"

local reddb = redisopt.default

local player_request = {}

setmetatable(player_request,{
    __index = function(t,guid)
        local reqids = reddb:smembers(string.format("player:request:%s",guid))
        if not reqids then
            return nil
        end

        local reqs = {}
        for _,id in pairs(reqids) do
            id = tonumber(id)
            reqs[id] = base_request[id]
        end

        t[guid] = reqs
        return reqs
    end,
})

return player_request