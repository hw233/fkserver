local redisopt = require "redisopt"

local reddb = redisopt.default

local base_rule = setmetatable({},{
    __index = function(t,rule_id)
        
    end,
})


return base_rule