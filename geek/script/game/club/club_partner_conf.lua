local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_partner_conf = {}

local function metafn(t,club_id)
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
end

setmetatable(club_partner_conf,{
    __index = metafn,
})

local timer_task = require "timer_task"

local function guard()
    club_partner_conf = setmetatable({},{
        __index = metafn,
    })
end 

timer_task.exec(3,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return club_partner_conf[club_id]
    end
})

return m