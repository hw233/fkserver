local redisopt = require "redisopt"

require "functions"

local reddb = redisopt.default

local function metafn(t,club_id)
    local partner_ids = reddb:hgetall(string.format("club:member:partner:%s",club_id))
    if not partner_ids or table.nums(partner_ids) == 0 then
        partner_ids =  {}
    end
    t[club_id] = partner_ids
    return partner_ids
end

local club_member_partner = setmetatable({},{
    __index = metafn
})

local timer_task = require "timer_task"

local function guard()
    club_member_partner = setmetatable({},{
        __index = metafn,
    })
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return club_member_partner[club_id]
    end
})

return m
