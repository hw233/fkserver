--验证登录相关
require "functions"
local log = require "log"
local redisopt = require "redisopt"
local reddb = redisopt.default

local imei_accounts = require "login.verify.imei_accounts"
local ip_accounts = require "login.verify.ip_accounts"

local password_error_counts = require "login.verify.password_error_counts"
local account_lock_imei = require "login.verify.account_lock_imei"

local ip_auth_accounts = require "login.verify.ip_auth_accounts"

local not_check_ip_conf = require "data.not_check_ip_conf"


local IP_LIMIT = 5 --同IP允许登录的账号数
local IMEI_LIMIT = 2 --同设备允许登录的账号数
local PSERROR_LIMIT = 5 --同IMEI一个账号允许密码错误次数
local IP_CHECK = false 
local IMEI_CHECK = false 

local IP_AUTH_CHECK = true
local IP_AUTH_LIMIT = 2     --同IP允许注册的账号数

local function ip2rdip(ip)
    local rdip 
    if ip and type(ip)=="string" then
        local i1,i2,i3,i4 = ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)" )
        rdip =  i1.."_"..i2.."_"..i3.."_"..i4
    end
    return rdip 
end

local verify = {
    curcount = 0,
    limit = IP_AUTH_LIMIT,
}

function verify.check_ip(ip,account)
    --log.info(string.format("check_ip ip[%s] account[%s] ",ip,account))
    if not IP_CHECK then
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

function verify.check_imei(imei,account)
    --log.info(string.format("check_imei imei[%s] account[%s] ",imei,account))
    if not IMEI_CHECK then
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

function verify.check_password_error(imei,account)
    if not imei or imei == ""  or not account then
        return 0
    end 
    local error_counts = password_error_counts[account]
    local ec = (error_counts[imei] or 0) +1
    log.info(string.format("check_password_error imei[%s] account[%s] error_counts[%s]",imei,account,ec))
    if ec >= PSERROR_LIMIT then
        log.error(string.format("check_password_error imei[%s] account[%s] ec[%s]PSERROR_LIMIT",imei,account,ec))
        verify.set_account_lock_imei(imei,account)
        reddb:hset(string.format("verify:password_error_counts:%d",account),imei,0)
        return PSERROR_LIMIT - ec
    end
    reddb:hset(string.format("verify:password_error_counts:%d",account),imei,ec)
    return PSERROR_LIMIT - ec
end

function verify.set_account_lock_imei(imei,account)
    if not imei or imei == ""  or not account then
        return 
    end 
    log.info(string.format("set_account_lock_imei imei[%s] account[%s] ",imei,account))
    reddb:sadd(string.format("verify:account_lock_imei:%s",account),tostring(imei))
end

function verify.check_account_lock_imei(imei,account)
    if not imei or imei == ""  or not account then
        return 
    end 
    local lock_imeis = account_lock_imei[account]
    if not lock_imeis or table.nums(lock_imeis) == 0  then
        return
    end
    if lock_imeis[imei]  then
        log.info(string.format("check_account_lock_imei  account[%s] imei[%s]",account,imei))
        return true 
    end
    return false
end

function verify.remove_account_lock_imei(account)
    if  not account then
        return
    end
    reddb:del("verify:account_lock_imei:"..account)
end 

function verify.remove_ip_accounts(ip)
    if not ip or ip =="" then
        return
    end
    local rdip = ip2rdip(ip)
    reddb:del("verify:ip_accounts:"..rdip)
end

function verify.remove_imei_accounts(imei)
    if not imei or imei =="" then
        return
    end
    reddb:del("verify:imei_accounts:"..tostring(imei))
end

function verify.check_ip_auth(ip)
    log.info(string.format("check_ip_auth ip[%s] ",ip))
    if not IP_AUTH_CHECK then
        return true
    end
    if not ip or ip =="" then
        return  true
    end
    local rdip = ip2rdip(ip)
    if not rdip then
        return  true
    end

    local ipaccouts = reddb:hgetall("verify:ip_auth_accounts:"..tostring(rdip)) -- ip_auth_accounts[rdip]
    log.dump(ipaccouts,rdip)
    if ipaccouts.curcount and ipaccouts.limit then
        verify.limit = ipaccouts.limit
        if tonumber(ipaccouts.curcount) >= tonumber(ipaccouts.limit) then
            log.error(string.format("check_ip_auth ip[%s] IP_AUTH_LIMIT %d",ip,tonumber(ipaccouts.limit)))
            log.dump(ipaccouts)
            return false 
        end
    else         
        verify.curcount = 1
        verify.limit = IP_AUTH_LIMIT
        log.info(string.format("check_ip_auth ip[%s] 11111",rdip))
        return true
    end
    verify.curcount = ipaccouts.curcount + 1
    log.info(string.format("check_ip_auth ip[%s] 22222",rdip))
    return true
end 

function verify.remove_ip_auth_accounts(ip)
    if not ip or ip =="" then
        return
    end
    local rdip = ip2rdip(ip)
    reddb:del("verify:ip_auth_accounts:"..rdip)
end

function verify.check_have_same_ip(ip)
	local function ipsec(ip)
		local ips = {}
		for s in ip:gmatch("%d+") do
			table.insert(ips,tonumber(s))
		end
		return ips
	end

	local function same_ip_net(ip1,ip2)
		local s1 = ipsec(ip1)
		local s2 = ipsec(ip2)	
		if #s1 < 4 or #s2 < 4 then
			return false
		end
		return s1[1] == s2[1] and s1[2] == s2[2] and s1[3] == s2[3] and s1[4] == s2[4]
	end

	local auth_ip = ip
	log.dump(auth_ip,"auth_ip")
    local not_check_ip = not_check_ip_conf
    log.dump(not_check_ip,"not_check_ip")
	return table.logic_or(not_check_ip,function(confip)
		return same_ip_net(auth_ip,confip)
	end)
end

return verify