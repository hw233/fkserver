local redisopt = require "redisopt"
local base_request = require "game.club.base_request"

local reddb = redisopt.default

local player_request = {}

local cls_player_request = {}

function cls_player_request:get()
    return base_request[self.id]
end

setmetatable(player_request,{
    __index = function(t,guid)
        local reqids = reddb:smembers(string.format("player:request:%s",guid))
        if not reqids then
            return nil
        end

        local reqs = {}
        for _,id in pairs(reqids) do
            id = tonumber(id)
            reqs[id] = setmetatable({id = id,},{__index = cls_player_request})
        end

        t[guid] = reqs
        return reqs
    end,
})

return player_request