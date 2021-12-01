local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"
require "functions"

local reddb = redisopt.default

return wrap(function (t,club_id)
    local m = setmetatable({},{
        __index = function(tb,guid)
            local ttids = reddb:smembers(string.format("club:team:template:%s:%s",club_id,guid))
            if not ttids or table.nums(ttids) == 0 then
                return {}
            end

            tb[guid] = ttids

            return ttids
        end
    })

    t[club_id] = m

    return m
end, 3)