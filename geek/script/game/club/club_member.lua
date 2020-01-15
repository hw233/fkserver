local redisopt = require "redisopt"

local reddb = redisopt.default

local club_member = {}

setmetatable(club_member,{
    __index = function(t,club_id)
        local ms = {}
        local members = reddb:smembers("club:member:"..tostring(club_id))
        for _,guid in pairs(members) do
            ms[tonumber(guid)] = true
        end

        t[club_id] = ms
        return ms
    end,
})

return club_member