local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"
require "functions"
local log = require "log"
local redisopt = require "redisopt"
local reddb = redisopt.default

local imei_accounts = require "login.verify.imei_accounts"
local verify = require "login.verify.verify"
local IMEI_LIMIT = 2 --同IP允许登录的账号数

function verify.check_imei(imei,account)
    log.info(string.format("fix_check_imei imei[%s] account[%s] ",imei,account))
    if imei then
        return true
    end
    if not imei or imei == ""  or not account then
        return true
    end 
    local  imeiaccouts = imei_accounts[imei]

    if  table.logic_or(imeiaccouts,function (a)
        return tonumber(a) == account
    end) then
        return true 
    end

    if table.nums(imeiaccouts) >= IMEI_LIMIT then
        log.error(string.format("check_imei imei[%s] account[%s] IMEI_LIMIT",imei,account))
        log.dump(imeiaccouts)
        return false 
    end

    reddb:sadd(string.format("verify:imei_accounts:%s",tostring(imei)),account)
    return true
end