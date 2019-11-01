local skynet = require "skynet"
local redisopt = require "redisopt"
local channel = require "channel"
local netmsgopt = require "netmsgopt"
local pb = require "pb"
local gbk = require "gbk"
local httpc = require "http.httpc"
local crypt = require "skynet.crypt"
local util = require "gate.util"

require "table_func"
require "functions"
local log = require "log"

local datacenter = require "skynet.datacenter"

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
}

local LOGIN_RESULT_LOGIN_QUQUE = pb.enum("LOGIN_RESULT","LOGIN_RESULT_LOGIN_QUQUE")
local LOGIN_RESULT_ACCOUNT_PASSWORD_ERR = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_ACCOUNT_PASSWORD_ERR")
local LOGIN_RESULT_SMS_FAILED = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_SMS_FAILED")
local LOGIN_RESULT_SAME_PASSWORD = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_SAME_PASSWORD")
local LOGIN_RESULT_SMS_ERR = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_SMS_ERR")
local LOGIN_RESULT_ACCOUNT_CHAR_LIMIT = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_ACCOUNT_CHAR_LIMIT")
local LOGIN_RESULT_ACCOUNT_SIZE_LIMIT = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_ACCOUNT_SIZE_LIMIT")
local LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY")
local LOGIN_RESULT_NICKNAME_LIMIT = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_NICKNAME_LIMIT")
local LOGIN_RESULT_NICKNAME_EMPTY = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_NICKNAME_EMPTY")
local LOGIN_RESULT_POTATO_CHECK_ERROR = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_POTATO_CHECK_ERROR")
local LOGIN_RESULT_TEL_ERR = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_TEL_ERR")
local LOGIN_RESULT_TEL_LEN_ERR = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_TEL_LEN_ERR")
local LOGIN_RESULT_SMS_REPEATED = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_SMS_REPEATED")

local potato_login_access_token = ""
local potato_key = ""
local potato_url = "https:--oauth.potato.im:8443/oauth2/api/userinfo"
local rsa_public_key
local logining = {}

local gate

local CMD = {}

function CMD.login()

end

function CMD.logout()

end

function CMD.register_gate(g)
    assert(g)
    gate = g
end

local MSG = {}

function MSG.C_RequestPublicKey(fd,ip,msg)
    if not rsa_public_key then
        rsa_public_key = skynet.call(".utild","lua","get_rsa_public_key")
    end
    netmsgopt.write(fd,0,"C_PublicKey",{
        public_key = crypt.hexencode(rsa_public_key)
    })
end

function MSG.CL_RegAccount(fd,ip,msg) 
    local password_ = ""
    local platform_id = ""
    local imei_ = ""
    local deprecated_imei_ = ""
    local account_ = ""
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

    local password_ = ""
    local account_ = ""
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

    msg.pb_regaccount.ip_area = util.geo_lookup(ip)
    msg.pb_regaccount.ip =  ip
    log.info( "set_ip = %s", msg.pb_regaccount.ip )
    log.info( "set_ip_area = %s", msg.pb_regaccount.ip_area )
    local scmsg = channel.call("login.?","msg","CL_RegAccount",msg)
    log.info( "login step MSG.CL_RegAccount,account=%s, session_id=%d", account_, fd )
    if scmsg.server_id then
        skynet.call(gate,"lua","login")
    end
end


function MSG.CL_Login_By_Potato(fd,ip,msg)    
    if not msg.access_token or type(msg.access_token) ~= "string" then
        log.error( "no client_id, CL_Login_By_Potato")
        return false
    else
        potato_login_access_token = msg.access_token				-- 客户端的token
    end

    if not msg.potatokey then
        log.error( "no PotatoSdkSecretKey~!" )
        return false
    end

    local potato_key = util.rsa_decrypt(crypt.hexdecode(msg.potatokey))
    local potato_login_phone = type(msg.phone) == "string" and msg.phone or "" -- 手机
    local potato_login_phone_type = type(msg.phone_type) == "string" and msg.phone_type or "" -- 手机类型
    local potato_login_version = type(msg.version) == "string" and msg.version or "" -- 版本号
    local potato_login_channel_id = type(msg.channel_id) == "string" and msg.channel_id or "" -- 渠道号
    local potato_login_package_name = type(msg.channpackage_nameel_id) == "string" and msg.package_name or "" -- 安装包名字
    local potato_login_imei = type(msg.imei) == "string" and msg.imei or "" -- 安装包名字
    local potato_login_ip = type(msg.ip) == "string" and msg.ip or "" -- 客户端ip
    local potato_login_ip_area = type(msg.ip_area) == "string" and msg.ip_area or "" -- 客户端ip地区
    local potato_login_deprecated_imei = type(msg.deprecated_imei) == "string" and msg.deprecated_imei or "" -- 客户端ip地区
    local potato_login_platform_id = type(msg.platform_id) == "string" and msg.platform_id or "0" -- 客户端 平台id
    local potato_login_shared_id = type(msg.shared_id) == "string" and msg.shared_id or "" -- 共享设备ID

    if msg.platform_id then
        log.info( "platform_id [%s]", msg.platform_id)
    end

    if potato_https_curl then
        local resultmsg = {}
        local deprecated_imei_ = potato_login_deprecated_imei
        local platform_id = potato_login_platform_id
        local host,url = string.match(potato_url,"https?://([^/]+)/?([^&]*)")
        local jsonstr = httpc.post(host,url.. "/" .. table.concat(potato_auth,"&"))
        log.info( 
            "potato_login_phone [%s] potato_login_phone_type [%s] potato_login_version[%s] potato_login_channel_id[%s] potato_login_package_name[%s] potato_login_imei[%s] potato_login_platform_id[%s]",
            potato_login_phone, potato_login_phone_type, potato_login_version, potato_login_channel_id, 
            potato_login_package_name, potato_login_imei, potato_login_platform_id )

        local jsonrep = json.decode(jsonstr)
        if jsonrep.success then
            

            -- if (document.HasMember( "data" ) and document["data"].IsObject() and document["data"].HasMember( "phone" ) and document["data"]["phone"].IsString()) {
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
        else
            if type(jsonrep.code) == "number" then
                resultmsg.result = jsonrep.code
    			log.error("potato login is error : code[%d] message[%s]", jsonrep.code, jsonrep.message)
            else
                resultmsg.result = LOGIN_RESULT_POTATO_CHECK_ERROR
    			log.error("potato login is error : code[%d] ", LOGIN_RESULT_POTATO_CHECK_ERROR )
            end
        end

        netmsgopt.write(fd,"LC_Login",resultmsg)
    end

    -- local login_result = channel.call("login.?","CL_Login_By_Potato",msg)

    logining[fd] = nil
	return true
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


function MSG.CL_Login(fd,ip,msg) 
	if is_send_login_ then
		log.warning( "send login repeated" )
		return true
    end

    local password_ = ""
    local platform_id = ""
    local imei_ = ""
    local deprecated_imei_ = ""
    local account_ = ""

    if not msg.account or type(msg.account) ~= "string" then
        log.error( "no account, id=%d")
        return false
    end

    if logining[fd] then
        netmsgopt.write(fd,0,"LC_Login",{
            result = LOGIN_RESULT_LOGIN_QUQUE,
        } )
        return true
    end

    logining[fd] = true

    if not msg.password  or type(msg.password) ~= "string"then
        log.error( "no password, CL_Login")
        netmsgopt.write(fd,0,"LC_Login",{
            result = LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        })
        return false
    end


    log.info( "================= CryptoManager::rsa_decrypt ==================1 %s", msg.account )
    local password = util.rsa_decrypt(crypt.hexdecode(msg.password))
    log.info( "================= CryptoManager::rsa_decrypt ==================2 %s", msg.account )
    if not password then
        log.error("password error %s", msg.password)
        netmsgopt.write(fd,0,"LC_Login",{
            result = LOGIN_RESULT_ACCOUNT_PASSWORD_ERR,
        })
        return true
    end

    msg.password = password 
    password_ = password

    --保存imei
    if not msg.imei or type(msg.imei) ~= "string" or msg.imei == "" then
        log.error( "not imei CL_Login" )
        return false
    end

    imei_ = msg.imei

    deprecated_imei_ = (type(msg.deprecated_imei)== "string") and msg.deprecated_imei or ""
    if deprecated_imei_ == "" then
        log.error( "no deprecated_imei, CL_Login")
        return false
    end

    platform_id = (type(msg.platform_id) ~= "string" or msg.platform_id == "") and "0" or msg.platform_id
    msg.platform_id = platform_id

    -- 保存账号
    account_ = msg.account
    msg.ip_area = util.geo_lookup(ip)
    msg.ip =  ip
    log.info( "ip = %s", msg.ip )
    -- log.info( "ip_area = %s", IpAreaManager::instance().U2G( msg.ip_area() ) )
    -- 登录时，没有guid，做过特殊处理
    local login_result = channel.call("login.?","msg","CL_Login",msg)
    log.info( "login step gate.CL_Login,account=%s, session_id=%d", account_, fd )

    logining[fd] = nil
	return true
end

function MSG.CL_LoginBySms(fd,ip,msg)     
    local password_ = ""
    local platform_id = ""
    local imei_ = ""
    local deprecated_imei_ = ""
    local account_ = ""

    if not msg.account or type(msg.account ~= "string") then
        log.error( "no account, LoginBySms")
        return false
    end
    
    if logining[fd] then
        netmsgopt.write(fd,0,"LC_Login",{
            result = LOGIN_RESULT_LOGIN_QUQUE,
        } )
        return true
    end

    logining[fd] = true

    if msg.account ~= tel_ or not sms_no_  or not msg.sms_no ~= sms_no_ then
        netmsgopt.write(fd,0,"LC_Login",{
            result = LOGIN_RESULT_SMS_FAILED,
        } )
        logining[fd] = nil
        return
    end

    -- 保存账号
    account_ = msg.account
    imei_ = msg.imei
    msg.ip_area =  util.geo_lookup(ip)
    msg.ip =  ip
    log.info( "ip = %s", msg.ip )
    log.info( "ip_area = %s", msg.ip_area )
    local login_result = channel.call("login.?","msg","CL_LoginBySms",msg)

    --保存imei
    imei_ = msg.imei
    if not imei_ or type(imei_) ~= "string" then
        log.error( "not has imei" )
        return false
    end

    deprecated_imei_ = msg.deprecated_imei
    if not deprecated_imei_ or type(deprecated_imei_) ~= "string" then
        log.error( "no deprecated_imei, id=%d")
        return false
    end

    platform_id = msg.platform_id
    if not platform_id or type(platform_id) ~= "string" then
        platform_id = "0"
        msg.platform_id = "0"
    end
    password_ = ""

    logining[fd] = nil

	return true
end

-- function do_get_sms_http(fd,msg) 
-- 	sms_task.m_msg.append( "----------------------------675526169953038878040223\r\n" )
-- 		.append( "Content-Disposition: form-data name=\"phone\"" )
-- 		.append( "\r\n\r\n" )
-- 		.append( sms_task.m_tel )
-- 		.append( "\r\n" )
-- 		.append( "----------------------------675526169953038878040223\r\n" )
-- 		.append( "Content-Disposition: form-data name=\"code\"" )
-- 		.append( "\r\n\r\n" )
-- 		.append( sms_task.m_sms_no )
-- 		.append( "\r\n" )
-- 		.append( "----------------------------675526169953038878040223\r\n" )
-- 		.append( "Content-Disposition: form-data name=\"sign\"" )
-- 		.append( "\r\n\r\n" )
-- 		.append( sing )
-- 		.append( "\r\n" )
-- 		.append( "----------------------------675526169953038878040223\r\n" )
-- 		.append( "Content-Disposition: form-data name=\"platform_id\"" )
-- 		.append( "\r\n\r\n" )
-- 		.append( platform_id )
-- 		.append( "\r\n" )
-- 		.append( "----------------------------675526169953038878040223--\r\n" )

-- 	AsynTaskMgr::instance().addTask( sms_task )
-- end


skynet.start(function()
    skynet.dispatch("lua",function(_,_,cmd,...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            skynet.error(string.format("unkown cmd:%s",cmd))
        end
    end)

    skynet.dispatch("client",function(_,_,fd,ip,cmd,...) 
        local f = MSG[cmd]
        if f then
            return f(fd,ip,...)
        else
            skynet.error(string.format("got unkown client msg:%s",cmd))
        end
    end)
end)