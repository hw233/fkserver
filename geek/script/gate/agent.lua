local skynet = require "skynetproto"
local channel = require "channel"
local gbk = require "gbk"
local util = require "gate.util"
local crypt = require "skynet.crypt"
local httpc = require "http.httpc"
local datacenter = require "skynet.datacenter"
local netmsgopt = require "netmsgopt"
local cluster = require "cluster"
local serviceconf = require "serviceconf"
local json = require "cjson"
local enum = require "pb_enums"
require "table_func"
require "functions"
local log = require "log"

local gate,protocol,inserverid = ...
gate = tonumber(gate)
inserverid = tonumber(inserverid)
log.info("gate.agent protocol %s",protocol)
netmsgopt.protocol(protocol)

local fd
local addr
local guid
local conf
local rsa_public_key


local CMD = {}

function CMD.login(source, u)
	log.info("%s is login", u.guid)
	gate = source
    guid = u.guid
    fd = u.fd
    addr = u.addr
    conf = u.conf
    channel.subscribe("guid."..tostring(guid),skynet.self())
end

local function logout(...)
	if gate then
		skynet.call(gate, "lua", "logout", guid)
	end
	skynet.exit()
end

local function afk(...)
    log.warning("afk,guid:%s",guid)
    if not inserverid then
        logout()
        return
    end

    channel.call("service."..tostring(inserverid),"lua","afk",guid,true)
    logout()
end

function CMD.logout(...)
	log.warning("%s is logout", guid)
	logout()
end

function CMD.afk(...)
    afk()
end

function CMD.kickout()
    skynet.exit()
end

function CMD.goserver(_,id)
	inserverid = id
end

local MSG = {}

function MSG.C_RequestPublicKey(msg)
    if not rsa_public_key then
        rsa_public_key = skynet.public_key()
    end

    netmsgopt.send(fd,guid,"C_PublicKey",{
        public_key = rsa_public_key,
    })
end

function MSG.CS_RequestSms(msg)
	if not util.request_sms(guid) then
		log.info( "RequestSms guid [%d]",guid)
		netmsgopt.send(fd,"SC_RequestSms",{
            result = enum.LOGIN_RESULT_SMS_REPEATED,
        })
	else
        log.info( "RequestSms guid [%d] =================", guid )
        if not msg.tel then
            log.error( "RequestSms guid [%d] =================tel not find", get_guid() )
            netmsgopt.send(fd,0,"SC_RequestSms",{
                result = enum.LOGIN_RESULT_SMS_FAILED,
            } )
            return true
        end

        local tel = msg.tel

        log.info( "RequestSms guid [%d] =================tel[%s] platform_id[%s]",  msg.tel, msg.platform_id)
        local tellen = string.len(tel)
        if tellen < 7 or tellen > 18 then
            netmsgopt.send(fd,0,"SC_RequestSms",{
                result = enum.LOGIN_RESULT_TEL_LEN_ERR,
            })
            return true
        end

        local tel_head = string.sub(tel,0, 3)

        --170 171的不准绑定
        if tel_head == "170" or tel_head == "171" then
            netmsgopt.send(fd,0,"SC_RequestSms",{
                result = enum.LOGIN_RESULT_TEL_ERR,
            } )
            return true
        end

        if tel_head == "999" then
            tel_head =  string.sub(tel,tellen - 6)
            -- sms_status.tel = tel
            -- sms_status.sms_no = tel_head
            -- sms_status.last_sms_time = os.time()
            return true
        end

        if not string.gmatch(tel,"^\\d+&")() then
            netmsgopt.send(fd,0,"SC_RequestSms",{
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
        --         session.netmsgopt.send(fd, &msg )
        --     else
        --         log.warning( "login server disconnect" )
        --     end
        -- else
        --     do_get_sms_http( msg.tel, msg.platform_id )
        -- end
    end

	return true
end

function MSG.CS_GameServerCfg(msg)
    local pb_cfg = {}
    for item,_ in pairs(channel.query()) do
        local id = string.match(item,"game.(%d+)")
        if id then
            id = tonumber(id)
            local sconf = serviceconf[id]
            if sconf.conf.private_conf then
                local gconf = sconf.conf
                log.info("GameName[%s] GameID[%d] first_game_type [%d].", gconf.gamename, id,gconf.first_game_type)
                table.insert(pb_cfg,gconf.first_game_type)
            end
        end
	end

    netmsgopt.send(fd,"SC_GameServerCfg",{
        game_sever_info  = pb_cfg,
    })

	return true
end

function MSG.CG_GameServerCfg(msg)
    if not msg.platform_id then
        log.warning( "platform_id empty, CG_GameServerCfg, set platform = [0]")
        msg.platform_id = "0"
    end

    local pb_cfg = {}
    for item,_ in pairs(channel.query()) do
        local type,id = string.match("([^.]+).(%d+)")
        if type == "game" then
            local sconf = serviceconf[tonumber(id)]
            if sconf.conf.private_conf then
                log.info("GameName[%s] GameID[%d] platform[%s] error.", item.game_name, item.game_id, item.platform_id)
            end
        end
	end

	for _,p in pairs(pb_cfg) do
		log.info( "GC_GameServerCfg[%s] ==> %s", p.game_name, p.title )
    end

    netmsgopt.send(fd,"S2C_GameServerCfg",{
        pb_cfg = pb_cfg,
    })

	return true
end

function MSG.CL_GetInviterInfo(msg) 
    if not msg.invite_code then
        log.error( "no invite_code, guid=%d", guid)
        return false
    end

    msg.guid = guid
    local scmsg = channel.call("login.?","msg","CL_GetInviterInfo",{
        guid = guid,
    })

    netmsgopt.send(fd,"LC_GetInviterInfo",scmsg)
end

function MSG.CS_SetNickname(msg) 
    if not msg.nickname then
        netmsgopt.send(fd,"SC_SetNickname",{
            result = enum.LOGIN_RESULT_NICKNAME_EMPTY,
        })
        return true
    end

    local reply = {
        nickname = msg.nickname,
    }
    local gbknickname = gbk.fromutf8(msg.nickname)
    local nicknamelen = gbk.len(gbknickname)
    if nicknamelen < 4 or nicknamelen > 14 then
        netmsgopt.send(fd,"SC_SetNickname",{
            result = enum.LOGIN_RESULT_NICKNAME_LIMIT,
        })
        return true
    end

    local scmsg = channel.call(":.game.?","msg","CS_SetNickname",msg)
    netmsgopt.send(fd,"SC_SetNickname",scmsg)

	return true
end


function MSG.CS_ResetAccount(msg) 
	if not inserverid then
		log.warning( "game_id == 0" )
		return false
    end

    local reset_account_reply = {
        nickname = msg.nickname,
    }

    if not msg.nickname then
        reset_account_reply.result = enum.LOGIN_RESULT_NICKNAME_EMPTY
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        return true
    end

    if not msg.password then
        reset_account_reply.result = enum.LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        log.error( "password empty" )
        return true
    end

    local gbk_nickname = gbk.fromutf8(msg.nickname)
    local nickname_len = gbk.len(gbk_nickname)
    if nickname_len < 4 or nickname_len > 14 then
        reset_account_reply.result = enum.LOGIN_RESULT_NICKNAME_LIMIT
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        return true
    end

    local password = util.rsa_decrypt(crypt.hexdecode(msg.password))
    if type(password) ~= "string" then
        reset_account_reply.result = enum.LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        log.error( "password error %s", msg.password() )
        return true
    end

    if not msg.account then
        reset_account_reply.result = enum.LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        log.error( "CE_ResetAccount account empty" )
        return true
    end

    if msg.type == 2 then
        local potato_key = util.rsa_decode(crypt.hexdecode(msg.account))
        local potato_reset_nickname = msg.nickname
        local potato_reset_password = password
        local potato_login_access_token = msg.key

        local potatoconf = datacenter.query("potato.config")
        local postparam = {
            access_token = potato_login_access_token,
            client_secret = potato_key,
        }

        local host,url = string.match(potatoconf.url,"https?://([^/]+)/?([^\\?]*)")
        local jsonrep = httpc.post(host,url,postparam)
        if not jsonrep then
            return true
        end

        local rep = json.decode(jsonrep)
        local success = rep.success
        local code = rep.code
        if success then
            local data = rep.data
            if not data or type(data) ~= "table" then
                return
            end

            local phone = data.phone
            if not phone or type(phone) ~= "string" then
                return
            end

            local scmsg = channel.call("game."..tostring(inserverid),"msg","CS_ResetAccount",{
                account = phone,
                password = potato_reset_password,
                nickname = potato_reset_nickname,
            })

            netmsgopt.send(fd,"SC_ResetAccount",scmsg)
        else
            if code then
                log.error( "potato login is error : code[%d] message[%s]", code, rep.message )
            else
                log.error( "potato login is error : code[%d] ", enum.LOGIN_RESULT_POTATO_CHECK_ERROR )
            end
        end

        reset_account_reply.result = code and tonumber(code) or enum.LOGIN_RESULT_POTATO_CHECK_ERROR
        netmsgopt.send(fd,"SC_ResetAccount", reset_account_reply)
        return
    end

    if not msg.account or type(msg.account) ~= "string" then
        reset_account_reply.result = enum.LOGIN_RESULT_SET_ACCOUNT_OR_PASSWORD_EMPTY
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        log.error( "CE_ResetAccount account empty" )
        return true
    end

    reset_account_reply.account = msg.account

    if string.len(msg.account) > 18 or string.len(msg.account < 7) then
        reset_account_reply.result = enum.LOGIN_RESULT_ACCOUNT_SIZE_LIMIT
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        return true
    end

    if string.find(msg.account,"$[^\\d]+^") then
        reset_account_reply.result = enum.LOGIN_RESULT_ACCOUNT_CHAR_LIMIT
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        return true
    end

    if not util.verify_sms(guid,msg.account,msg.key) then
        reset_account_reply.result = enum.LOGIN_RESULT_SMS_FAILED
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        return true
    end

    if not msg.key or not string.find(msg.key,"$[^\\d]+^") or string.len(msg.key) ~= 6 then
        reset_account_reply.result = enum.LOGIN_RESULT_SMS_ERR
        netmsgopt.send(fd,"SC_ResetAccount",reset_account_reply)
        return true
    end

    msg.password = password
    msg.guid = guid
    local scmsg = channel.call("game."..tostring(inserverid),"msg","CS_ResetAccount",msg)
    netmsgopt.send(fd,"SC_ResetAccount",scmsg)

	return true
end


function MSG.CS_SetPassword(msg)
	if inserverid == 0 then
		log.warning( "game_id == 0" )
		return false
    end

    if not msg.old_password or not msg.password then
        log.error( "password or old password empty" )
        return
    end

    if not msg.old_password or not msg.password then
        log.error( "old new password error %s,%s", msg.old_password, msg.password )
        return false
    end

    local old_password = util.rsa_decrypt(crypt.hexdecode(msg.old_password))
    local password = util.rsa_decrypt(crypt.hexdecode(msg.password))
    if not old_password or not password then
        log.error( "old new password error %s,%s", msg.old_password, msg.password )
        return false
    end

    if old_password == password then
        netmsgopt.send(fd,"SC_SetPassword",{
            result = enum.LOGIN_RESULT_SAME_PASSWORD,
        } )
        return true
    end

    msg.old_password =  old_password
    msg.password = password
    msg.guid = guid
    
    local scmsg = channel.call("game."..tostring(inserverid),"msg","CS_SetPassword",msg)
    netmsgopt.send(fd,"SC_SetPassword",scmsg)

	return true
end

function MSG.CS_SetPasswordBySms(msg)
    if not inserverid then
		log.warning( "game_id == 0" )
		return false
    end
    if not msg.password then
        log.error( "password empty" )
        return
    end

    msg.guid = guid

    if not util.verify_sms(guid,msg.tel,msg.sms_no) then
        netmsgopt.send(fd,"SC_SetPassword",{
            result = enum.LOGIN_RESULT_SMS_FAILED,
        })
        return true
    end

    msg.password = util.rsa_decrypt(crypt.hexdecode(msg.password))
    local scmsg = channel.call("game."..tostring(inserverid),"msg","CS_SetPasswordBySms",msg)
    netmsgopt.send(fd,"SC_SetPasswordBySms",scmsg)

	return true
end

function MSG.CS_BankSetPassword(msg) 
	if inserverid == 0 then
		log.warning( "game_id == 0" )
		return false
    end

    if msg.password then
        msg.guid = guid
        msg.password = util.rsa_decrypt(crypt.hexdecode(msg.password))
        local scmsg = channel.call("game."..tostring(inserverid),"msg","CS_BankSetPassword",msg)
        netmsgopt.send(fd,"SC_BankSetPassword",scmsg)
    else
        log.error( "CS_BankSetPassword password empty" )
    end

	return true
end

function MSG.CS_BankChangePassword(msg)
	if inserverid == 0 then
		log.warning( "game_id == 0" )
		return false
    end
    
    if msg.old_password and msg.password then
        msg.guid = guid
        msg.old_password = util.rsa_decrypt(crypt.hexdecode(msg.old_password))
        msg.password = util.rsa_decrypt(crypt.hexdecode(msg.password))
        local scmsg = channel.call("game."..tostring(inserverid),"msg","CS_BankChangePassword",msg)
        netmsgopt.send(fd,"SC_BankChangePassword",scmsg)
    else
        log.error( "CS_BankChangePassword password or old password empty" )
    end

	return true
end

-- function MSG.CS_BankReSetPassWD(guid,msg)
-- 	if inserverid == 0 then
-- 		log.warning( "game_id == 0" )
-- 		return false
--     end

--     if not util.verify_sms(guid,msg.tel,msg.bank_pw_sms) then
--         netmsgopt.send(fd,"SC_ResetBankPW",{
--             guid = msg.guid,
--             result = LOGIN_RESULT_SMS_FAILED,
--         } )
--     else
--         msg.bank_password_new = util.rsa_decrypt(crypt.hexdecode(msg.bank_password_new))
--         msg.guid = guid
--         local scmsg = channel.call("game."..tostring(inserverid),"CS_BankReSetPassWD",msg)
--         netmsgopt.send(fd,"SC_BankChangePassword",scmsg)
--     end

-- 	return true
-- end

function MSG.CS_BankDraw(msg)
	if inserverid == 0 then
		log.warning( "game_id == 0" )
		return false
    end

    msg.guid = guid
    if msg.bank_password then
        msg.bank_password = util.rsa_decrypt(crypt.hexdecode(msg.bank_password))
    end

    local scmsg = channel.call("game."..tostring(inserverid),"msg","CS_BankDraw",msg)
    netmsgopt.send(fd,"SC_BankDraw",scmsg)

	return true
end

function MSG.CS_BankLogin(msg) 
	if inserverid == 0 then
		log.warning( "game_id == 0" )
		return false
    end

    if msg.password then
        msg.password = util.rsa_decrypt(crypt.hexdecode(msg.password))
        local scmsg = channel.call("game."..tostring(inserverid),"msg","CS_BankLogin",msg)
        netmsgopt.send(fd,"SC_BankDraw",scmsg)
    else
        log.error( "CS_BankLogin password empty" )
    end

	return true
end

function MSG.CS_HeartBeat()
    netmsgopt.send(fd,"SC_HeartBeat",{
        severTime = os.time(),
    })
end

local function dispatch_client(buf)
    local msgid,msgstr = netmsgopt.unpack(buf)
    local msgname = netmsgopt.msgname(msgid)
    if not msgname then
        log.error("dispatch unkown buf")
        return
    end

    local msg = netmsgopt.decode(msgid,msgstr)
    if msgname ~= "CS_HeartBeat" then
        log.info("agent.dispatch %s,%s,%s",msgname,msgid,#msgstr)
        dump(msg)
    end

    local f = netmsgopt.dispatcher(msgid)
    if f then
        return f(msg)
    end

	if inserverid then
		channel.publish("service."..tostring(inserverid),"msg",msgname,msg,guid)
	else
		log.error("player %d isn't in server,but recv msg data.",guid)
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_, source, cmd, ...)
		local f = assert(CMD[cmd])
		skynet.retpack(f(source,...))
    end)

    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,
        unpack = skynet.unpack,
        pack = skynet.pack,
    }

    netmsgopt.register_handle(MSG)
	skynet.dispatch("client", function(_,_,...)
	    skynet.retpack(dispatch_client(...))
    end)

    skynet.dispatch("proxy",function (_,_,msgname,msg)
        log.info("agent toclient msgname:%s,%s",guid,msgname)
        dump(msg)
        netmsgopt.send(fd,msgname,msg)
    end)
end)
