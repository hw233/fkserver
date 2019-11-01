local skynet = require "skynetproto"
local redisopt = require "redisopt"
local channel = require "channel"
local netmsgopt = require "netmsgopt"
local gbk = require "gbk"
local httpc = require "http.httpc"
local crypt = require "skynet.crypt"
local util = require "gate.util"
local enum = require "pb_enums"

require "table_func"
require "functions"
local log = require "log"
local datacenter = require "skynet.datacenter"


local gateid,protocol = ...
log.info("gate.logind protocol %s",protocol)
netmsgopt.protocol(protocol)
gateid = tonumber(gateid)

local rsa_public_key
local logining = {}
local sms = {}
local sms_time_limit
local gate
local serviceid


local function check_login_session(fd)
    return logining[fd]
end

local CMD = {}

function CMD.logout(fd)
    logining[fd] = nil
end

function CMD.register_gate(g)
    assert(g)
    gate = g
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

function MSG.CS_RequestSms(msg,session)
    local fd = session.fd
    local sms_session = sms[fd]
    sms_time_limit = sms_time_limit or datacenter.query("sms_limit_time")
    if sms_session and sms_session.last then
        if os.time() - sms_session.last >= sms_time_limit then
            log.info( "RequestSms in time [%d] session [%d]", os.time() - sms_session.last, fd )
            netmsgopt.send(fd,"SC_RequestSms",{
                result = enum.LOGIN_RESULT_SMS_REPEATED,
            })
            return
        end
    end

    log.info( "RequestSms session [%d] =================", fd )
    if not msg.tel then
        log.error( "RequestSms session [%d] =================tel not find", fd)
        netmsgopt.send(fd,"SC_RequestSms",{
            result = enum.LOGIN_RESULT_SMS_FAILED,
        })
        return true
    end

    local tel = msg.tel

    log.info( "RequestSms guid [%d] =================tel[%s] platform_id[%s]",  msg.tel, msg.platform_id)
    local tellen = string.len(tel)
    if tellen < 7 or tellen > 18 then
        netmsgopt.send(fd,"SC_RequestSms",{
            result = enum.LOGIN_RESULT_TEL_LEN_ERR,
        })
        return true
    end

    local tel_head = string.sub(tel,0, 3)

    --170 171的不准绑定
    if tel_head == "170" or tel_head == "171" then
        netmsgopt.send(fd,"SC_RequestSms",{
            result = enum.LOGIN_RESULT_TEL_ERR,
        } )
        return true
    end

    if tel_head == "999" then
        local sms_no =  string.sub(tel,tellen - 6)
        sms[fd] = {
            tel = tel,
            sms_no = sms_no,
            last = os.time(),
        }
        return true
    end


    if not string.match(tel,"^%d+&") then
        netmsgopt.send(fd,"SC_RequestSms",{
            result = enum.LOGIN_RESULT_TEL_ERR,
        })
        return true
    end

    -- if msg.intention == 2 then
    --     auto session = GateSessionManager::instance().get_login_session()
    --     if session then
    --         msg.gate_session_id =  get_id
    --         msg.guid =  guid
    --         msg.gate_id( static_cast<GateServer*>(BaseServer::instance()).get_gate_id() )
    --         log.info( "gateid[%d] guid[%d] sessiong[%d]", static_cast<GateServer*>(BaseServer::instance()).get_gate_id(), get_guid(), get_id() )
    --         session.send_pb( &msg )
    --     else
    --         log.warning( "login server disconnect" )
    --     end
    -- else
        -- do_get_sms_http( msg.tel, msg.platform_id )
    -- end

	return true
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

    if msg.pb_regaccount.password then
        local password = util.rsa_decrypt(crypt.hexdecode(tostring(msg.pb_regaccount.password)))
        if type(password) ~= "string" or password == "" then
            log.error( "password error %s", msg.pb_regaccount.password )
            return false
        end

        msg.pb_regaccount.password = password 
    end

    local password_
    local account_
    local imei_
    local deprecated_imei_
    local platform_id

    -- 保存账号
    if msg.pb_regaccount.account then
        if type(msg.pb_regaccount.account) ~= "string" or msg.pb_regaccount.account == "" then
            log.error( "no account, CL_RegAccount")
            return false
        end
        account_ = msg.pb_regaccount.account
    end

    --保存imei
    if msg.pb_regaccount.imei then
        if type(msg.pb_regaccount.imei) ~= "string" or msg.pb_regaccount.imei == "" then
            log.error( "no imei, CL_RegAccount")
            return false
        end
        imei_ = msg.pb_regaccount.imei
    else
        log.error( "no imei, CL_RegAccount" )
        return false
    end

    if msg.pb_regaccount.deprecated_imei then
        if type(msg.pb_regaccount.deprecated_imei) ~= "string" or msg.pb_regaccount.deprecated_imei == "" then
            log.error( "no deprecated_imei, CL_RegAccount")
            return false
        end
        deprecated_imei_ = msg.pb_regaccount.deprecated_imei
    else
        deprecated_imei_ = ""
        msg.pb_regaccount.deprecated_imei = ""
    end

    if msg.pb_regaccount.platform_id and msg.pb_regaccount.platform_id ~= "" then
        platform_id = msg.pb_regaccount.platform_id
    else
        platform_id = "0"
        msg.pb_regaccount.platform_id = "0"
    end

    msg.pb_regaccount.ip_area = util.geo_lookup(session.ip)
    msg.pb_regaccount.ip =  session.ip
    log.info( "set_ip = %s", msg.pb_regaccount.ip )
    log.info( "set_ip_area = %s", msg.pb_regaccount.ip_area )
    local scmsg = channel.call("login.?","msg","CL_RegAccount",msg)
    log.info( "login step MSG.CL_RegAccount,account=%s, session_id=%d", account_, session.fd )
    if scmsg.server_id then
        skynet.call(gate,"lua","login")
    end
end


-- function finish(fd,msg) 
-- 	local str = data.m_readbuf.str()
-- 	-- 	str = "{\"success\":true,\"code\":1,\"message\":\"ok\",\"data\":{\"open_id\":\"12562a189dcd3841cea5adcae10e930e\",\"username\":\"jibudao123\",\"phone\":\"9750673\",\"country_code\":\"354\",\"photo_url\":\"\"}}"
-- 	-- 	is_send_login_ = true
-- 	log.info( "%s", str )
-- 	rapidjson::Document document
-- 	document.Parse( str )
-- 	if (document.HasParseError()) {
-- 		log.error( boost::str( boost::format( "json 格式错误 error: (%1%:%2%)%3%" ) % document.GetParseError() % document.GetErrorOffset() % rapidjson::GetParseErrorFunc( document.GetParseError() ) ) )
-- 		is_send_login_ = false
-- 	} else if (checkJsonMember( document, "success", "bool", "code", "int", "message", "string" )) {
-- 		is_send_login_ = false
-- 	}
-- 	bool t = document["success"].GetBool()
-- 	int code = document["code"].GetInt()
-- 	if (is_send_login_ and document["success"].GetBool()) {
-- 		-- 验证成功开始登录 
-- 		if (document.HasMember( "data" ) and document["data"].IsObject() and document["data"].HasMember( "phone" ) and document["data"]["phone"].IsString()) {
-- 			string unique_id = document["data"]["open_id"].GetString()
-- 			string phone = document["data"]["phone"].GetString()

-- 			log.info( "unique_id[%s] phone[%s] potato_login_phone [%s] potato_login_phone_type [%s] potato_login_version[%s] potato_login_channel_id[%s] potato_login_package_name[%s] potato_login_imei[%s] potato_login_platform_id[%s]",
-- 					  unique_id, phone, potato_login_phone, potato_login_phone_type, potato_login_version, potato_login_channel_id, potato_login_package_name, potato_login_imei, potato_login_platform_id )
-- 			CL_LoginBySms msg
-- 			msg.set_account( phone )
-- 			msg.set_phone( potato_login_phone )
-- 			msg.set_phone_type( potato_login_phone_type )
-- 			msg.set_version( potato_login_version )
-- 			msg.set_channel_id( potato_login_channel_id )
-- 			msg.set_package_name( potato_login_package_name )
-- 			msg.set_imei( potato_login_imei )
-- 			msg.set_unique_id( unique_id )

-- 			std::string ip
-- 			if (m_haprox_ip_from_.empty()) {
-- 				get_remote_ip_port( ip )
-- 			} else {
-- 				ip = m_haprox_ip_from_
-- 			}
-- 			-- 保存账号
-- 			account_ = msg.account()
-- 			imei_ = msg.imei()
-- 			msg.set_ip_area( IpAreaManager::instance().get_ip_area_str( ip ) )
-- 			msg.set_ip( ip )
-- 			log.info( "set_ip = %s", msg.ip() )
-- 			log.info( "set_ip_area = %s", IpAreaManager::instance().U2G( msg.ip_area() ) )

-- 			msg.set_deprecated_imei( potato_login_deprecated_imei )
-- 			msg.set_platform_id( potato_login_platform_id )
-- 			msg.set_shared_id( potato_login_shared_id )

-- 			GateSessionManager::instance().add_CL_LoginBySms( get_id(), msg )
-- 		}
-- 	} else {
-- 		-- 验证失败
-- 		is_send_login_ = false
-- 		if (document.HasMember( "code" ) and document["code"].IsInt()) {
-- 			log.error( "potato login is error : code[%d] message[%s]", document["code"].GetInt(), document["message"].GetString() )
-- 		} else {
-- 			log.error( "potato login is error : code[%d] ", LOGIN_RESULT_POTATO_CHECK_ERROR )
-- 		}
-- 	}
-- end

local function login_by_sms(msg,session)

end

local function login_by_openid(msg,session)
    if not msg.open_id then
        return {
            result = enum.ERROR_PLAYER_NOT_EXIST
        }
    end

    msg.ip = session.ip
    local info,server = channel.call("login.?","msg","CL_Login",msg,gateid)
    if not check_login_session(session.fd) then --已断开连接
        return
    end

    if info.result == enum.LOGIN_RESULT_SUCCESS then
        skynet.call(gate,"lua","login",session.fd,info.guid,server,info)
    end

    return info
end

local function login_by_account(msg,session)
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

    local res = channel.call("login.?","msg","CL_Login",msg,serviceid)

    if not check_login_session(session.fd) then --已断开连接
        return
    end

    if res.ret == enum.LOGIN_RESULT_SUCCESS then
        skynet.call(gate,"lua","login",session.fd,res.guid,res.game_id,res)
    end

    log.info( "login step gate.CL_Login,account=%s, session_id=%d", msg.account, fd )
    return res
end


function MSG.CL_Login(msg,session)
    local fd = session.fd
    dump(msg)
    if logining[fd] then
        netmsgopt.send(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_LOGIN_QUQUE,
        })
        return true
    end

    local function check_key_field(field)
        return field and type(field) == "string" and field ~= ""
    end

    if not check_key_field(msg.account) and  not check_key_field(msg.open_id) then
        netmsgopt.send(fd,"LC_Login",{
            result = enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        })
        return false
    end

    logining[fd] = true

    local res
    if msg.account ~= "" then
        res = login_by_account(msg,session)
    end

    if msg.open_id ~= "" then
        res = login_by_openid(msg,session)
    end

    logining[fd] = nil

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
--         skynet.call(gate,"lua","login",session.fd,res.guid,res.game_id,res)
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

function MSG.C2S_LOGIN_REQ(msg,session)
    local s = logining[session.fd]
    if s then
        log.error("login repeated! fd:%d",session.fd)
        return
    end

    logining[session.fd] = coroutine.running()

    msg.loginIp = session.ip
    local inserverid,info = channel.call("login.?","msg","C2S_LOGIN_REQ",msg,gateid)

    if not check_login_session(session.fd) then --已断开连接
        return
    end

    if info then
        skynet.call(gate,"lua","login",session.fd,info.player_id,inserverid,info)
    end

    info.roomCard = info.room_card

    dump(info)

    netmsgopt.send(session.fd,"S2C_LOGIN_RES",info)

    logining[session.fd] = nil
end

function MSG.C2S_HEARTBEAT_REQ(_,session)
    netmsgopt.send(session.fd,"S2C_HEARTBEAT_RES",{
        dateTime = os.time(),
    })
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

    skynet.dispatch("client",function(_,_,msgstr,...)
        skynet.retpack(netmsgopt.on_msg(msgstr,...))
    end)
end)