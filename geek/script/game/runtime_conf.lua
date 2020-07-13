
local redopt = require "redisopt"

local reddb = redopt.default

local private_fee_switch = setmetatable({},{
    __index = function(_,money_id)
        local v = reddb:get(string.format("runtime_conf:private_fee:%s",money_id))
        return (not v or tonumber(v) ~= 0) and true or false
    end,
})

return {
    private_fee_switch = private_fee_switch,
}
