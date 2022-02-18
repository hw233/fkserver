--验证登录相关
local redisopt = require "redisopt"
require "functions"
local log = require "log"
local reddb = redisopt.default


local ip_accounts = {}

setmetatable(ip_accounts,{
    __index = function (t,ip)
        local accounts = reddb:smembers("verify:ip_accounts:"..ip)
        --t[ip] = accounts
        return accounts
    end 
})

return ip_accounts