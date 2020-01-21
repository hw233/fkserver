local redisopt = require "redisopt"
local reddb  = redisopt.default
local redismetadata = require "redismetadata"

local club_template_conf = {}

setmetatable(club_template_conf,{
    __index = function(c,club_id)
        local temp = setmetatable({},{
            __index = function(t,template_id)
                local conf = reddb:hgetall(string.format("conf:%d:%d",club_id,template_id))
                if not conf or table.nums(conf) == 0 then
                    return nil
                end

                conf = redismetadata.conf:decode(conf)
                t[template_id] = conf
                return conf
            end
        })
        c[club_id] = temp

        return temp
    end,
})

return club_template_conf