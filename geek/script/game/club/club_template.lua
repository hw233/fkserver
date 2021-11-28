local redisopt = require "redisopt"

local reddb = redisopt.default

local club_template = {}
local function metafn(t,club_id)
    local ttids = reddb:smembers(string.format("club:template:%d",club_id))
    t[club_id] = ttids
    return ttids
end 

setmetatable(club_template,{
    __index = metafn
})

local timer_task = require "timer_task"

local function guard()
    club_template = setmetatable({},{
        __index = metafn,
    })
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return club_template[club_id]
    end
})

return m