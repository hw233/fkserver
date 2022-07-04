--验证登录相关
local redisopt = require "redisopt"
require "functions"
local log = require "log"
local reddb = redisopt.default


local ip_auth_accounts = {}

setmetatable(ip_auth_accounts,{
    __index = function(t,ip)
        local tb = reddb:hgetall("verify:ip_auth_accounts:"..tostring(ip))
        t[ip] = tb
        return tb
    end,
})

return ip_auth_accounts