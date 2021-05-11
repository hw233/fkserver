local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"
require "functions"
local log = require "log"
local redisopt = require "redisopt"
local reddb = redisopt.default

local ip_accounts = require "login.verify.ip_accounts"
local verify = require "login.verify.verify"
local IP_LIMIT = 5 --同IP允许登录的账号数

local function ip2rdip(ip)
    local rdip 
    if ip and type(ip)=="string" then
        local i1,i2,i3,i4 = ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)" )
        rdip =  i1.."_"..i2.."_"..i3.."_"..i4
    end
    return rdip 
end

function verify.check_ip(ip,account)
    log.info(string.format("fix___check_ip ip[%s] account[%s] ",ip,account))
    if ip then
        return true
    end
    if not ip or ip =="" or not account then
        return  true
    end
    local rdip = ip2rdip(ip)
    if not rdip then
        return  true
    end
    local ipaccouts = ip_accounts[rdip]

    if  table.logic_or(ipaccouts,function (a)
        return tonumber(a) == account
    end) then
        return true 
    end

    if table.nums(ipaccouts) >= IP_LIMIT then
        log.error(string.format("check_ip ip[%s] account[%s] IP_LIMIT",ip,account))
        log.dump(ipaccouts)
        return false 
    end
    reddb:sadd(string.format("verify:ip_accounts:%s",rdip),account)
    return true
end 