local redisopt = require "redisopt"
local reddb  = redisopt.default
local strfmt = string.format

local club_partner_template_default_commission_rate = {}

setmetatable(club_partner_template_default_commission_rate,{
    __index = function(t1,club_id)
        local club = setmetatable({},{
            __index = function(t2,template_id)
                local template = setmetatable({},{
                    __index = function(_,self_id)
                        return reddb:hget(strfmt("club:commission:template:default:%s:%s",club_id,template_id),self_id)
                    end
                })

                t2[template_id] = template
                return template
            end
        })
        t1[club_id] = club

        return club
    end,
})

return club_partner_template_default_commission_rate