local redisopt = require "redisopt"
local reddb  = redisopt.default

local club_partner_template_default_commission_rate = {}

setmetatable(club_partner_template_default_commission_rate,{
    __index = function(club,club_id)
        local t_comissions = setmetatable({},{
            __index = function(template,template_id)
                local m = setmetatable({},{
                    __index = function(_,partner_id)
                        if not partner_id then
                            local commissions = reddb:hgetall(string.format("club:template:commission:default:%s:%s",club_id,template_id))
                            if not commissions or table.nums(commissions) == 0 then
                                return {}
                            end

                            return commissions
                        end
        
                        local commission = reddb:hget(string.format("club:template:commission:default:%s:%s",club_id,template_id),partner_id)
                        return commission and tonumber(commission) or nil
                    end
                })

                template[template_id] = m
                return m
            end
        })
        club[club_id] = t_comissions

        return t_comissions
    end,
})

return club_partner_template_default_commission_rate