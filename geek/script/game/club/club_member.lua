local redisopt = require "redisopt"

local reddb = redisopt.default

local club_member = {}

local function metafn(t,club_id)
    local mems = reddb:smembers("club:member:"..tostring(club_id))
    t[club_id] = mems
    return mems
end

setmetatable(club_member,{
    __index = metafn,
})

local timer_task = require "timer_task"

local function guard()
    club_member = setmetatable({},{
        __index = metafn,
    })
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return club_member[club_id]
    end,
    _newindex = function(t,club_id,value)
        if value == nil then 
            club_member[club_id] = nil 
        end 
    end,
})

return m