
local redisopt = require "redisopt"

local reddb = redisopt.default



local base_mail = setmetatable({},{
    __index = function(t,mid)
        local mail = reddb:hgetall("mail:"..mid)
        if not mail or table.nums(mail) == 0 then
            return nil
        end

        t[mid] = mail
        return mail
    end,
})


return base_mail