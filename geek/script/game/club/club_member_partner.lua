local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"
require "functions"

local reddb = redisopt.default

return wrap(function (t,club_id)
    local partner_ids = reddb:hgetall(string.format("club:member:partner:%s",club_id))
    if not partner_ids or table.nums(partner_ids) == 0 then
        partner_ids =  {}
    end
    t[club_id] = partner_ids
    return partner_ids
end, 3)
