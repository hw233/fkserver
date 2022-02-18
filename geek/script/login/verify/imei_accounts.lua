--验证登录相关
local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local imei_accounts = {}

setmetatable(imei_accounts,{
    __index = function(t,imei)
        local accounts = reddb:smembers("verify:imei_accounts:"..imei)
        --t[imei] = accounts
        return accounts
    end
})

return  imei_accounts
