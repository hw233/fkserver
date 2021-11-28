local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default


local meta_func = function(_,club_id)
    local m = setmetatable({club_id = club_id},{
        __index = function(t,guid)
            local ttids = reddb:smembers(string.format("club:team:template:%s:%s",t.club_id,guid))
            if not ttids or table.nums(ttids) == 0 then
                return {}
            end

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
    club_member_partner = setmetatable({},{
        __index = meta_func
    })
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return club_team_template[club_id]
    end
})

return m