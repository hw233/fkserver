local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_member = {}

setmetatable(club_member,{
    __index = function(t,club_id)
        local members = reddb:smembers("club:member:"..tostring(club_id))
        local ms = table.map(members,function(guid) return tonumber(guid),true end)

        -- t[club_id] = ms --多游服情况下，不缓存
        return ms
    end,
})

return club_member