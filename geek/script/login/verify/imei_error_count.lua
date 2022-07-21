--验证登录相关
local redisopt = require "redisopt"
require "functions"
local log = require "log"
local reddb = redisopt.default

local imei_error_count = {}

setmetatable(imei_error_count,{
    __index = function(t,imei)
        local error_counts = reddb:get("verify:imei_error_count:"..imei)
        --t[imei] = error_counts
        return error_counts
    end
})

return imei_error_count
