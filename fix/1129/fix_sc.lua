
local redisopt = require "redisopt"
require "functions"

local string = string

local reddb = redisopt.default

local meta_func = function(t,club_id)
    local m = setmetatable({},{
        __index = function(tb,guid)
            local ttids = reddb:smembers(string.format("club:team:template:%s:%s",club_id,guid))
            if not ttids or table.nums(ttids) == 0 then
                return {}
            end

            tb[guid] = ttids

            return ttids
        end
    })

    t[club_id] = m

    return m
end

local club_team_template = setmetatable({},{
    __index = meta_func
})

local timer_task = require "timer_task"

local function guard()
    club_team_template = setmetatable({},{
        __index = meta_func
    })
end 

timer_task.exec(3,guard)

local log = require "log"
local m = require "game.club.club_team_template"

local dump = require "fix.dump"

dump(print,getmetatable(m))

print(m)

local function fn(t,club_id)
    return club_team_template[club_id]
end

setmetatable(m,{
    __index = fn
})

dump(print,getmetatable(m))