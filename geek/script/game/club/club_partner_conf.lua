local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"

local reddb  = redisopt.default

return wrap(function (t,club_id)
    local m = setmetatable({},{
        __index = function(c,partner_id)
            local conf = setmetatable({},{
                __index = function(f,field)
                    if not field then
                        local allcnf = reddb:hgetall(string.format("club:partner:conf:%s:%s",club_id,partner_id))
                        return allcnf
                    end
    
                    local cnf = reddb:hget(string.format("club:partner:conf:%s:%s",club_id,partner_id),field)
                    f[field] = cnf
                    return cnf
                end
            })
            
            c[partner_id] = conf

            return conf
        end
    })

    t[club_id] = m
    return m
end, 3)