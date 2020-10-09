local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_partner_conf = {}

setmetatable(club_partner_conf,{
    __index = function(t,club_id)
        local m = setmetatable({},{
            __index = function(c,partner_id)
                local conf = setmetatable({},{
                    __index = function(_,field)
                        if not field then
                            local allcnf = reddb:hgetall(string.format("club:partner:conf:%s:%s",club_id,partner_id))
                            return allcnf
                        end
        
                        local cnf = reddb:hget(string.format("club:partner:conf:%s:%s",club_id,partner_id),field)
                        return cnf
                    end
                })
                
                c[partner_id] = conf

                return conf
            end
        })

        t[club_id] = m
        return m
    end,
})

return club_partner_conf