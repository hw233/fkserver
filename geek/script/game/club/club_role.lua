
local redisopt = require "redisopt"
require "functions"
local reddb = redisopt.default

local club_role = {}

setmetatable(club_role,{
    __index = function(t_club,club_id)
        local m = setmetatable({club_id = club_id},{
            __index = function(t,guid)
                if not guid then
                    local rs = reddb:hgetall("club:role:"..tostring(t.club_id))
                    local roles = table.map(rs,function(srole,sguid) return tonumber(sguid),tonumber(srole) end)
                    return roles
                end

                local role = reddb:hget(string.format("club:role:%s",t.club_id),guid)
                return tonumber(role)
            end
        })

        t_club[club_id] = m
        return m
    end
})

return club_role