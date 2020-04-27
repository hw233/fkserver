
local redisopt = require "redisopt"
require "functions"
local reddb = redisopt.default

local club_role = {}

setmetatable(club_role,{
    __index = function(t,club_id)
        local rs = reddb:hgetall("club:role:"..tostring(club_id))
        local roles = table.map(rs,function(role,guid) return tonumber(guid),tonumber(role) end)
        return roles
    end
})

return club_role