
local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"
require "functions"

local reddb = redisopt.default

return wrap(function (t,ttid)
    local temp = reddb:hgetall("template:"..tostring(ttid))
    if not temp or table.nums(temp) == 0 then
        return nil
    end
    t[ttid] = temp
    return temp
end, 3) 