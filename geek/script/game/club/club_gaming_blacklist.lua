local redisopt = require "redisopt"

local reddb = redisopt.default

local gaming_blacklist = {}

local function metafn(t,club_id)
    local blacklist = reddb:smembers("club:blacklist:gaming:"..tostring(club_id))
    t[club_id] = blacklist
  
    return blacklist
end

setmetatable(gaming_blacklist,{
    __index = metafn,
})

local timer_task = require "timer_task"

local function guard()
    gaming_blacklist = setmetatable({},{
        __index = metafn,
    })
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return gaming_blacklist[club_id]
    end,
    _newindex = function(t,club_id,value)
        if value == nil then 
            gaming_blacklist[club_id] = nil 
        end 
    end,
})

return m