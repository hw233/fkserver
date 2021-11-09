local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local club_team_template = {}

setmetatable(club_team_template,{
    __index = function(_,club_id)
        return setmetatable({club_id = club_id},{
            __index = function(t,guid)
                local ttids = reddb:smembers(string.format("club:team:template:%s:%s",t.club_id,guid))
                if not ttids or table.nums(ttids) == 0 then
                    return {}
                end

                return ttids
            end
        })
    end
})


return club_team_template