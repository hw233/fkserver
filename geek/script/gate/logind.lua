local skynet = require "skynetproto"
local channel = require "channel"
local protocolnetmsg = require "gate.netmsgopt"
local crypt = require "skynet.crypt"
local util = require "gate.util"
local enum = require "pb_enums"
local serviceconf = require "serviceconf"
local queue = require "skynet.queue"

require "functions"
local log = require "log"

LOG_NAME = "gate.logind"

local gateservice,gateid,protocol = ...
log.info("gate.logind protocol %s",protocol)
local netmsgopt = protocolnetmsg[protocol]
gateid = tonumber(gateid)
gateservice = tonumber(gateservice)

local string = string

local send2client = netmsgopt.send

local MSG = {}

function MSG.CS_RequestSmsVerifyCode(msg,session)
    local result,timeout = channel.call("login.?","msg","CS_RequestSmsVerifyCode",msg,session.fd)
    send2client(session.fd,"SC_RequestSmsVerifyCode",{
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

    if msg.pb_regaccount.platform_id and msg.pb_regaccount.platform_id ~= "" then
        platform_id = msg.pb_regaccount.platform_id
    else
        platform_id = "0"
        msg.pb_regaccount.platform_id = "0"
    end

    -- msg.pb_regaccount.ip_area = util.geo_lookup(session.ip)
    -- msg.pb_regaccount.ip =  session.ip
    log.info("set_ip = %s", msg.pb_regaccount.ip)
    log.info("set_ip_area = %s", msg.pb_regaccount.ip_area)
    local info,gameid = channel.call("login.?","msg","CL_RegAccount",msg)
    info.game_id = gameid
    log.info("login step MSG.CL_RegAccount,account=%s, session_id=%s", info.account, session.fd)
    if info.ret == enum.LOGIN_RESULT_SUCCESS then
        skynet.call(gateservice,"lua","login",session.fd,info.guid,info)
    end

    log.dump(info)

    send2client(session.fd,"LC_Login",info)
end


local function login_by_sms(msg,session)
    if not msg.phone or not msg.sms_verify_no then
        return {
            result = enum.ERROR_PLAYER_NOT_EXIST
        }
    end

    msg.ip = session.ip

    local ok,info = channel.pcall("login.?","msg","CL_Login",msg,gateid)

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

    local ok,info = channel.pcall("login.?","msg","CL_Login",msg,gateid)

    log.dump(info)

    return ok,info
end

local function login_by_account(msg,session)
    log.dump(msg)
    local fd = session.fd
    local ip = session.ip
    if not msg.account and type(msg.account) ~= "string" or msg.account == "" then
        return {
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        }
    end

    if not msg.password  or type(msg.password) ~= "string" or msg.password == "" then
        log.error( "no password, CL_Login")
        return {
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        }
    end

    log.info( "================= CryptoManager::rsa_decrypt ==================1 %s", msg.account )
    local password = msg.password
    -- local password = util.rsa_decrypt(crypt.hexdecode(msg.password))
    log.info( "================= CryptoManager::rsa_decrypt ==================2 %s", msg.account )
    if not password or password == "" then
        log.error("password error %s", msg.password)
        return {
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        }
    end

    msg.password = password
    msg.platform_id = (type(msg.platform_id) ~= "string" or msg.platform_id == "") and "0" or msg.platform_id
    msg.ip =  ip
    log.info( "ip = %s", msg.ip )

    local ok,info = channel.pcall("login.?","msg","CL_Login",msg,gateid)

    log.info( "login step gateservice.CL_Login,account=%s, session_id=%d", msg.account, fd )
    return ok,info
end

local function is_valid_str(v)
    return v and type(v) == "string" and v ~= ""
end

local function do_cl_login(msg,session)
    log.dump(msg)
    local fd = session.fd

    if not is_valid_str(msg.account) and  not is_valid_str(msg.open_id) and not is_valid_str(msg.phone) then
        send2client(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        })
        return
    end

    local ok,info
    if msg.account and msg.account ~= "" and msg.password and msg.password ~= "" then
        ok,info = login_by_account(msg,session)
    elseif msg.open_id and msg.open_id ~= "" then
        ok,info = login_by_openid(msg,session)
    elseif msg.phone and msg.phone ~= "" and msg.sms_verify_no and msg.sms_verify_no ~= "" then
        ok,info = login_by_sms(msg,session)
    else
        log.error("CL_Login invalid parameter")
        return
    end

    log.dump(info)

    if ok then
        if info.result == enum.LOGIN_RESULT_SUCCESS then
            local guid = info.guid
            skynet.call(gateservice,"lua","login",fd,guid,info)
        end

        send2client(fd,"LC_Login",info)
    else
        send2client(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_MAINTAIN
        })
    end
end

function MSG.CL_Auth(msg,session)
    local fd = session.fd
    if  (not msg.code or msg.code == "") or
        (not msg.auth_platform or msg.auth_platform == "") then
        send2client(fd,"LC_Auth",{
            result = enum.LOGIN_RESULT_AUTH_CHECK_ERROR,
        })
        return
    end
    -- 微信授权登录，必须要有注册的IP，不然会没入库
    msg.ip = session.ip 
    local ok,result,userinfo,authMsg = channel.pcall("login.?","msg","CL_Auth",msg)
    log.dump(result)
    log.dump(userinfo)
    if not ok then
        send2client(fd,"LC_Auth",{
            result = enum.LOGIN_RESULT_MAINTAIN,
        })
        return
    end

    if  ok and
        result ~= enum.LOGIN_RESULT_SUCCESS and 
        result ~= enum.LOGIN_RESULT_RESET_ACCOUNT_DUP_ACC then
        send2client(fd,"LC_Auth",{
            result = result,
            errmsg = userinfo,
        })
        return
    end

    if msg.ip and authMsg then
        local checkmsg = {
            ip = msg.ip,
            limit = authMsg.limit,
            curcount = authMsg.curcount,
        }
        log.dump(checkmsg,msg.ip)
        channel.publish("login.*","msg","S_AuthCheck",checkmsg)
    end

    log.dump(userinfo)

    local do_login_msg = {
        ip = msg.ip,
        open_id = userinfo.open_id,
        package_name = msg.package_name,
        phone_type = msg.phone_type,
        version = msg.version,
        imei = msg.imei
    }

    do_cl_login(do_login_msg,session)
end

function MSG.CL_Login(msg,session)
    do_cl_login(msg,session)
end

function MSG.CS_HeartBeat(_,session)
    send2client(session.fd,"SC_HeartBeat",{
        severTime = os.time(),
    })
end

function MSG.CG_GameServerCfg(msg,session)
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

	send2client(session.fd,"GC_GameServerCfg",{
        pb_cfg = pbconf,
    })

	return true
end

skynet.start(function()
    skynet.dispatch("lua",function(_,_,cmd,...)
        log.error("unkown cmd:%s",cmd)
        skynet.retpack(nil)
    end)

    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,
        pack = skynet.pack,
        unpack = skynet.unpack,
        dispatch = function(session,source,msgname,...)
            local f = MSG[msgname]
            if f then
                skynet.retpack(f(...))
            else
                log.error("unkown msg:%s",msgname)
                skynet.retpack(nil)
            end
        end,
    }
end)