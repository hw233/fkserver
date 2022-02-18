--验证登录相关
local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default


local account_lock_imei = {}

setmetatable(account_lock_imei,{
    __index = function(t,account)
        local lock_imeis = reddb:smembers("verify:account_lock_imei:"..account)
        --t[account] = locktime
        return lock_imeis
    end, 
})
return account_lock_imei
