--验证登录相关
local redisopt = require "redisopt"
require "functions"
local log = require "log"
local reddb = redisopt.default

local password_error_counts = {}

setmetatable(password_error_counts,{
    __index = function(t,account)
        local error_counts = reddb:hgetall("verify:password_error_counts:"..account)
        if not error_counts or table.nums(error_counts) == 0 then
            error_counts =  {}
        end
        --t[date] = error_counts
        return error_counts
    end
})

return password_error_counts
