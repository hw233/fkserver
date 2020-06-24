local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_notice = {}

setmetatable(club_notice,{
        __index = function(t,club_id)
                local nids = reddb:smembers("club:notice:"..tostring(club_id))
                local ms = table.map(nids,function(nid) return tonumber(nid),true end)

                -- t[club_id] = ms
                return ms
        end,
})

return club_notice