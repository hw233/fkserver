local redisopt = require "redisopt"
local reddb = redisopt.default

local meta_func = function(t,guid)
    local tps = setmetatable({},{
        __index = function(tb,tp)
            local clubs = reddb:smembers(string.format("player:club:%d:%d",guid,tp))
            tb[tp] = clubs
            return clubs
        end
    })
    t[guid] = tps
    return tps
end

local player_club = setmetatable({},{
    __index = meta_func,
})

local timer_task = require "timer_task"

local function guard()
    player_club = setmetatable({},{
        __index = meta_func,
    })
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,guid)
        return player_club[guid]
    end
})

return m