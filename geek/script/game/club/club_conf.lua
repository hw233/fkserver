local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_conf = {}

local function metafn(t,club_id)
    local conf = reddb:hgetall(string.format("club:conf:%d",club_id))
    t[club_id] = conf
    return conf
end 

setmetatable(club_conf,{
    __index = metafn
})

local timer_task = require "timer_task"

local function guard()
    club_conf = setmetatable({},{
        __index = metafn,
    })
    
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return club_conf[club_id]
    end
})

return m