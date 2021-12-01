local redisopt = require "redisopt"

local reddb = redisopt.default

local club_role = {}
local function metafn(t_club,club_id)
        local mt = setmetatable({club_id = club_id},{
            __index = function(t,guid)
                if not guid then
                    local rs = reddb:hgetall("club:role:"..tostring(t.club_id))
                    return rs
                end
                local role = reddb:hget(string.format("club:role:%s",t.club_id),guid)
                t[guid] = tonumber(role)
                return tonumber(role)
            end
        })

        t_club[club_id] = mt
        return mt
end 

setmetatable(club_role,{
    __index = metafn
})

local timer_task = require "timer_task"

local function guard()
    club_role = setmetatable({},{
        __index = metafn,
    })
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return club_role[club_id]
    end,
    _newindex = function(t,club_id,value)
        if value == nil then 
            club_role[club_id] = nil 
        end 
    end,
})

return m