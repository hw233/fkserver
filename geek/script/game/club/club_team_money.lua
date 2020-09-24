local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_team_money = {}

setmetatable(club_team_money,{
    __index = function(t,club_id)
        local tm = setmetatable({},{
            __index = function(_,partner_id)
                local money = reddb:hget(string.format("club:team_money:%s",club_id),partner_id)
                return money and tonumber(money) or 0
            end
        })

        t[club_id] = tm
        return tm
    end,
})

return club_team_money