local redisopt = require "redisopt"
local reddb  = redisopt.default
local log = require "log"

local club_partner_template_commission_rate = {}

setmetatable(club_partner_template_commission_rate,{
    __index = function(club,club_id)
        local c_templates = setmetatable({},{
            __index = function(template,template_id)
                local m = setmetatable({},{
                    __index = function(_,partner)
                        if not partner then
                            local cms = reddb:hgetall(string.format("club:template:commission:%s:%s",club_id,template_id))
                            if not cms or table.nums(cms) == 0 then
                                return {}
                            end
                            return cms
                        end
                        local commission = reddb:hget(string.format("club:template:commission:%s:%s",club_id,template_id),partner)
                        return commission and tonumber(commission) or nil
                    end
                })

                template[template_id] = m
                return m
            end
        })
        club[club_id] = c_templates

        return c_templates
    end,
})

return club_partner_template_commission_rate