local redisopt = require "redisopt"
local reddb = redisopt.default

local player_club = {}

setmetatable(player_club,{
    __index = function(t,guid)
        local tps = setmetatable({},{
            __index = function(tb,tp)
                local clubs = reddb:smembers(string.format("player:club:%d:%d",guid,tp))
                local cs = {}
                for _,club in pairs(clubs) do
                    cs[tonumber(club)] = true
                end
                tb[guid] = cs
                return cs
            end
        })
        t[guid] = tps
        return tps
    end
})

return player_club