local redisopt = require "redisopt"
local reddb  = redisopt.default
local redismetadata = require "redismetadata"

local club_team_template_conf = {}

setmetatable(club_team_template_conf,{
    __index = function(team,club_id)
        local confs = setmetatable({},{
            __index = function(t,template_id)
                local conf = reddb:hgetall(string.format("team_conf:%d:%d",club_id,template_id))
                if not conf or table.nums(conf) == 0 then
                    return nil
                end

                conf = redismetadata.conf:decode(conf)
                t[template_id] = conf
                return conf
            end
        })
        team[club_id] = confs

        return confs
    end,
})

return club_team_template_conf