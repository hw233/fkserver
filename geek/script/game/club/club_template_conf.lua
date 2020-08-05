local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_template_conf = {}

setmetatable(club_template_conf,{
    __index = function(club,club_id)
        local confs = setmetatable({},{
            __index = function(t,template_id)
                local conf = reddb:hgetall(string.format("conf:%d:%d",club_id,template_id))
                if not conf or table.nums(conf) == 0 then
                    return nil
                end

                t[template_id] = conf
                return conf
            end
        })
        club[club_id] = confs

        return confs
    end,
})

return club_template_conf