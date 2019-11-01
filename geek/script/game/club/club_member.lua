local base_players = require "game.lobby.base_players"
local redisopt = require "redisopt"

local reddb = redisopt.default

local club_member = setmetatable({},{
    __index = function(t,club_id)
        local member = reddb:smembers("club:member:"..tostring(club_id))
        local ms = {}
        for _,guid in pairs(member) do
            guid = tonumber(guid)
            ms[guid] = base_players[guid]
        end

        t[club_id] = ms
        return ms
    end,
})

return club_member