local redisopt = require "redisopt"
local reddb = redisopt.default

local log = require "log"

local player_club = {}

setmetatable(player_club,{
    __index = function(t,guid)
        local tps = setmetatable({},{
            __index = function(tb,tp)
                local clubs = reddb:smembers(string.format("player:club:%d:%d",guid,tp))
                log.dump(clubs)
                return clubs
            end
        })
        t[guid] = tps
        return tps
    end
})

return player_club