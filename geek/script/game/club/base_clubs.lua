local redisopt = require "redisopt"
local base_club = require "game.club.base_club"

local reddb = redisopt.default

local base_clubs = setmetatable({},{
    __index = function(t,id)
        local c = reddb:hgetall("club:info:"..tostring(id))
        if not c or table.nums(c) == 0 then
            return nil
        end
        
        setmetatable(c,{__index = base_club})
        t[id] = c
        return c
    end
})

return base_clubs