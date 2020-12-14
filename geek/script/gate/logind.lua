local skynet = require "skynetproto"
local redisopt = require "redisopt"
local channel = require "channel"
local netmsgopt = require "netmsgopt"
local gbk = require "gbk"
local httpc = require "http.httpc"
local crypt = require "skynet.crypt"
local util = require "gate.util"
local enum = require "pb_enums"
local serviceconf = require "serviceconf"

require "functions"
local log = require "log"
local datacenter = require "skynet.datacenter"

LOG_NAME = "gate.logind"

local gateservice,gateid,protocol = ...
log.info("gate.logind protocol %s",protocol)
netmsgopt.protocol(protocol)
gateid = tonumber(gateid)
gateservice = tonumber(gateservice)

local rsa_public_key
local logining = {}
local sms = {}
local sms_time_limit
local is_maintain

local function check_login_session(fd)
    return logining[fd]
end

local CMD = {}

function CMD.afk(fd)
    if not fd then return end
    
    logining[fd] = nil
end

function CMD.maintain(switch)
    is_maintain = switch
end

local MSG = {}

function MSG.C_RequestPublicKey(msg,session)
    if not rsa_public_key then
        rsa_public_key = skynet.call(".utild","lua","get_rsa_public_key")
    end
    netmsgopt.send(session.fd,"C_PublicKey",{
        public_key = crypt.hexencode(rsa_public_key)
    })
end

function MSG.CS_RequestSmsVerifyCode(msg,session)
    local result,timeout = channel.call("login.?","msg","CS_RequestSmsVerifyCode",msg,session.fd)
    netmsgopt.send(session.fd,"SC_RequestSmsVerifyCode",{
        result = result,
        phone_number = msg.phone_number,
        timeout = timeout,
    })
end

function MSG.CL_RegAccount(msg,session) 
    if not msg.pb_regaccount then
        log.error( "no reg info~!" )
        return false
    end

    if not msg.pb_regaccount.phone then
        log.error( "no phone, CL_RegAccount")
        return false
    end

    if not msg.pb_regaccount.invite_code then
        log.error( "no invite_code,CL_RegAccount" )
        return false
    end

    if not msg.pb_regaccount.invite_type then
        log.error( "no promote_type, CL_RegAccount")
        return false
    end

    if msg.pb_regaccount.platform_id and msg.pb_regaccount.platform_id ~= "" then
        platform_id = msg.pb_regaccount.platform_id
    else
        platform_id = "0"
        msg.pb_regaccount.platform_id = "0"
    end

    msg.pb_regaccount.ip_area = util.geo_lookup(session.ip)
    msg.pb_regaccount.ip =  session.ip
    log.info("set_ip = %s", msg.pb_regaccount.ip)
    log.info("set_ip_area = %s", msg.pb_regaccount.ip_area)
    local info,gameid = channel.call("login.?","msg","CL_RegAccount",msg)
    info.game_id = gameid
    log.info("login step MSG.CL_RegAccount,account=%s, session_id=%s", info.account, session.fd)
    if info.ret == enum.LOGIN_RESULT_SUCCESS then
        skynet.call(gateservice,"lua","login",session.fd,info.guid,gameid,info)
    end

    log.dump(info)

    netmsgopt.send(session.fd,"LC_Login",info)
end


local function login_by_sms(msg,session)
    if not msg.phone or not msg.sms_verify_no then
        return {
            result = enum.ERROR_PLAYER_NOT_EXIST
        }
    end

    msg.ip = session.ip
    local ok,info,server = channel.pcall("login.?","msg","CL_Login",msg,gateid,session.fd)
    local guid = info.guid
    if ok and info.result == enum.LOGIN_RESULT_SUCCESS then
        if not check_login_session(session.fd) then --已断开连接
            channel.publish("service."..tostring(server),"lua","afk",guid)
            return
        end

        skynet.call(gateservice,"lua","login",session.fd,info.guid,server,info)
    end

    log.dump(info)

    return ok,info
end

local function login_by_openid(msg,session)
    if not msg.open_id then
        return {
            result = enum.ERROR_PLAYER_NOT_EXIST
        }
    end

    msg.ip = session.ip
    local ok,info,server = channel.pcall("login.?","msg","CL_Login",msg,gateid)
    if ok and info.result == enum.LOGIN_RESULT_SUCCESS then
        local guid = info.guid
        if not check_login_session(session.fd) then --已断开连接
            channel.publish("service."..tostring(server),"lua","afk",guid)
            return
        end

        skynet.call(gateservice,"lua","login",session.fd,info.guid,server,info)
    end

    log.dump(info)

    return ok,info
end

local function login_by_account(msg,session)
    log.dump(msg)
    local fd = session.fd
    local ip = session.ip
    if not msg.account and type(msg.account) ~= "string" then
        return {
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        }
    end

    if not msg.password  or type(msg.password) ~= "string"then
        log.error( "no password, CL_Login")
        netmsgopt.send(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        })
        return false
    end

    log.info( "================= CryptoManager::rsa_decrypt ==================1 %s", msg.account )
    local password = util.rsa_decrypt(crypt.hexdecode(msg.password))
    log.info( "================= CryptoManager::rsa_decrypt ==================2 %s", msg.account )
    if not password then
        log.error("password error %s", msg.password)
        netmsgopt.send(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        })
        return true
    end

    msg.password = password

    if not msg.imei or type(msg.imei) ~= "string" or msg.imei == "" then
        log.error( "not imei CL_Login" )
        return false
    end

    local deprecated_imei_ = (type(msg.deprecated_imei)== "string") and msg.deprecated_imei or ""
    if deprecated_imei_ == "" then
        log.error( "no deprecated_imei, CL_Login")
        return false
    end

    msg.platform_id = (type(msg.platform_id) ~= "string" or msg.platform_id == "") and "0" or msg.platform_id
    msg.ip_area = util.geo_lookup(ip)
    msg.ip =  ip
    log.info( "ip = %s", msg.ip )

    local info,server = channel.call("login.?","msg","CL_Login",msg)
    local guid = info.guid
    if info.ret == enum.LOGIN_RESULT_SUCCESS then
        if not check_login_session(session.fd) then --已断开连接
            channel.publish("service."..tostring(server),"lua","afk",guid)
            return
        end
        
        skynet.call(gateservice,"lua","login",session.fd,info.guid,info.game_id,info)
    end

    log.info( "login step gateservice.CL_Login,account=%s, session_id=%d", msg.account, fd )
    return info
end

function MSG.CL_Auth(msg,session)
    local fd = session.fd
    if logining[fd] then
        netmsgopt.send(fd,"LC_Auth",{
            result = enum.LOGIN_RESULT_LOGIN_QUQUE,
        })
        return true
    end

    if  (not msg.code or msg.code == "") or
        (not msg.auth_platform or msg.auth_platform == "") then
        netmsgopt.send(fd,"LC_Auth",{
            result = enum.LOGIN_RESULT_AUTH_CHECK_ERROR,
        })
        return
    end

    logining[fd] = true

    msg.ip = session.ip
    local ok,result,userinfo = channel.pcall("login.?","msg","CL_Auth",msg)
    log.dump(result)
    log.dump(userinfo)
    if not ok then
        netmsgopt.send(fd,"LC_Auth",{
            result = enum.LOGIN_RESULT_MAINTAIN,
        })
        logining[fd] = nil
        return
    end

    if  ok and
        result ~= enum.LOGIN_RESULT_SUCCESS and 
        result ~= enum.LOGIN_RESULT_RESET_ACCOUNT_DUP_ACC then
        netmsgopt.send(fd,"LC_Auth",{
            result = result,
            errmsg = userinfo,
        })
        logining[fd] = nil
        return
    end
    
    logining[fd] = nil

    log.dump(userinfo)

    MSG.CL_Login({
        ip = msg.ip,
        open_id = userinfo.open_id,
        package_name = msg.package_name,
        phone_type = msg.phone_type,
        version = msg.version,
    },session)
end

function MSG.CL_Login(msg,session)
    log.dump(msg)
    local fd = session.fd
    
    if logining[fd] then
        netmsgopt.send(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_LOGIN_QUQUE,
        })
        return true
    end

    local function check_key_field(field)
        return field and type(field) == "string" and field ~= ""
    end

    if not check_key_field(msg.account) and  not check_key_field(msg.open_id) and not check_key_field(msg.phone) then
        netmsgopt.send(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        })
        return false
    end

    logining[fd] = true

    local ok,res
    if msg.account and msg.account ~= "" then
        ok,res = login_by_account(msg,session)
    end

    if msg.open_id and msg.open_id ~= "" then
        ok,res = login_by_openid(msg,session)
    end

    if msg.phone and msg.phone ~= "" and msg.sms_verify_no and msg.sms_verify_no ~= "" then
        ok,res = login_by_sms(msg,session)
    end

    logining[fd] = nil

    log.dump(res)

    if not ok then
        netmsgopt.send(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_MAINTAIN
        })
        return
    end

	netmsgopt.send(fd,"LC_Login",res)
end

-- function MSG.CL_LoginBySms(msg,session)
--     local password_
--     local platform_id = msg.platform_id
--     local imei_
--     local deprecated_imei_ = msg.deprecated_imei
--     local fd = session.fd
--     local account_ = msg.account
--     local imei_ = msg.imei
--     local ip = session.ip

--     if not msg.account or type(msg.account ~= "string") then
--         log.error( "no account, LoginBySms")
--         return false
--     end

--     if logining[fd] then
--         netmsgopt.send(fd,"LC_Login",{
--             result = LOGIN_RESULT_LOGIN_QUQUE,
--         } )
--         return true
--     end

--     logining[fd] = true

--     if msg.account ~= tel or not sms_no_  or not msg.sms_no ~= sms_no_ then
--         netmsgopt.send(fd,"LC_Login",{
--             result = LOGIN_RESULT_SMS_FAILED,
--         } )
--         logining[fd] = nil
--         return
--     end

--     -- 保存账号
--     msg.ip_area =  util.geo_lookup(ip)
--     msg.ip =  ip
--     log.info( "ip = %s", msg.ip )
--     log.info( "ip_area = %s", msg.ip_area )
--     local res = channel.call("login.?","msg","CL_LoginBySms",msg,serviceid)

--     if not check_login_session(session.fd) then --已断开连接
--         return
--     end

--     if res.ret == LOGIN_RESULT_SUCCESS then
--         skynet.call(gateservice,"lua","login",session.fd,res.guid,res.game_id,res)
--     end

--     --保存imei
--     if not imei_ or type(imei_) ~= "string" then
--         log.error( "not has imei" )
--         return false
--     end

--     if not deprecated_imei_ or type(deprecated_imei_) ~= "string" then
--         log.error( "no deprecated_imei, id=%d")
--         return false
--     end

--     if not platform_id or type(platform_id) ~= "string" then
--         platform_id = "0"
--         msg.platform_id = "0"
--     end
--     password_ = ""

--     logining[fd] = nil

--     netmsgopt.send(session.fd,msg.guid,"LC_Login",res)
--     return true
-- end

function MSG.CS_HeartBeat(_,session)
    netmsgopt.send(session.fd,"SC_HeartBeat",{
        severTime = os.time(),
    })
end

function MSG.CG_GameServerCfg(msg,session)
    local player_platform_id = "0"
    
    if not msg.platform_id then
        log.warning( "platform_id empty, CG_GameServerCfg, set platform = [0]")
    else
        player_platform_id = msg.platform_id
    end

    local gameservices = table.map(channel.list(),function(_,sid)
        local id = string.match(sid,"service.(%d+)")
        if not id then return end
        id = tonumber(id)
        local conf = serviceconf[id]
        if conf and conf.name == "game" and conf.conf.first_game_type ~= 1 then  return id,conf.conf end
    end)

    local pbconf = table.values(gameservices)

    log.dump(pbconf)

	for _,p in pairs(pbconf) do
		log.info( "GC_GameServerCfg[%s] ==> %s", p.game_name, p.title )
    end

	netmsgopt.send(session.fd,"GC_GameServerCfg",{
        pb_cfg = pbconf,
    })

	return true
end

skynet.start(function()
    netmsgopt.register_handle(MSG)

    skynet.dispatch("lua",function(_,_,cmd,...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            log.error("unkown cmd:%s",cmd)
            return nil
        end
    end)

    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,
        pack = skynet.pack,
        unpack = skynet.unpack,
    }

    skynet.dispatch("client",function(_,_,msgname,msg,...)
        skynet.retpack(netmsgopt.dispatch(msgname,msg,...))
    end)
end)