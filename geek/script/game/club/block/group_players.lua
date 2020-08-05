local redisopt = require "redisopt"
local reddb = redisopt.default

local group_players = setmetatable({},{
    __index = function(t,club_id)
        local ps = setmetatable({},{
            __index = function(_,group_id)
                local guids = reddb:smembers(string.format("club:block:group:player:%s:%s",club_id,group_id))
                return table.map(guids,function(v) return tonumber(v),true end)
            end
        })
        t[club_id] = ps
        return ps
    end
})

return group_players