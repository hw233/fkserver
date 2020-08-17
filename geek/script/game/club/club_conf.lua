local redisopt = require "redisopt"
local reddb  = redisopt.default
local redismetadata = require "redismetadata"

local club_conf = {}

setmetatable(club_conf,{
    __index = function(t,club_id)
        local conf = reddb:hgetall(string.format("club:conf:%d",club_id))
        if not conf or table.nums(conf) == 0 then
            return nil
        end

        conf = redismetadata.club.conf:decode(conf)

        t[club_id] = conf
        return conf
    end,
})

return club_conf