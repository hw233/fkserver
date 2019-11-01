local redisopt = require "redisopt"
local base_club = require "game.club.base_club"
local redismetadata = require "redismetadata"

local reddb = redisopt.default

local base_clubs = setmetatable({},{
    __index = function(t,id)
        local c = reddb:hgetall("club:info:"..tostring(id))
        if not c or table.nums(c) == 0 then
            return nil
        end

        c = redismetadata.club.info:decode(c)
        
        setmetatable(c,{__index = base_club})
        t[id] = c
        return c
    end
})

function base_clubs:list()
    local clubs = {}
    local clubids = reddb:smembers("club:all")
    for _,id in pairs(clubids) do
        clubs[id] = base_clubs[tonumber(id)]
    end

    return clubs
end

return base_clubs