
local redisopt = require "redisopt"
local channel = require "channel"
local onlineguid = require "netguidopt"
local skynet = require "skynetproto"
local log = require "log"
local json = require "cjson"
local serviceconf = require "serviceconf"
local base_players = require "game.lobby.base_players"
local md5 = require "md5.core"
local crypt = require "skynet.crypt"
local enum = require "pb_enums"
local httpc = require "http.httpc"
local player_money = require "game.lobby.player_money"
require "functions"
require "login.msg.runtime"

local reddb = redisopt.default

local function http_get(url)
    local host,url = string.match(url,"(https?://[^/]+)(.+)")
    log.info("http.get %s%s",host,url)
    return httpc.get(host,url)
end

local function sha1(text)
	local c = crypt.sha1(text)
	return crypt.hexencode(c)
end

local function hmac_sha1(key, text)
	local c = crypt.hmac_sha1(key, text)
	return crypt.hexencode(c)
end

local function gen_uuid(basestr)
    local entirestr = basestr..tostring(skynet.time())..tostring(math.random(10000))
    return sha1(entirestr)
end

function on_s_logout(msg)
	local account = msg.account
	local guid = msg.guid
    local platform_id = msg.platform_id
    
    if not guid then
        return true
    end

    if not account then
        account = reddb.hget("player:info:"..tostring(guid),"account")
        if not account then 
            return true
        end
    end

    local onlineinfo = onlineguid[guid]
    if onlineinfo then
        local gameid = onlineinfo.server
        if gameid then
            channel.publish("game."..tostring(gameid),"msg","S_Logout",{
                account = account,
                guid = guid,
                platform_id = platform_id,
            })
        end
    end

    reddb:hdel("player:online:guid:"..tostring(guid),"gate")

    onlineguid[guid] = nil

    return true
end

local function reg_account(msg)
    local guid = reddb:get("player:account:"..tostring(msg.open_id))
    if guid then
        log.warning("reg_account repeated.open_id:%s,guid:%s",msg.open_id,guid)
        reddb:hmset("player:info:"..tostring(guid),{
            nickname = msg.nickname or ("guest_"..tostring(guid)),
            icon = msg.icon or default_open_id_icon,
            version = msg.version,
            login_ip = msg.ip,
            phone = msg.phone or "",
            login_time = os.time(),
            package_name = msg.package_name,
            phone_type = msg.phone_type,
        })
        
        return enum.LOGIN_RESULT_RESET_ACCOUNT_DUP_ACC,base_players[tonumber(guid)]
    end

    guid = reddb:incr("player:global:guid")
    guid = tonumber(guid)
    local info = {
        guid = guid,
        account = msg.open_id,
        nickname = msg.nickname or ("guest_"..tostring(guid)),
        open_id = msg.open_id,
        sex = msg.sex or 1,
        icon = msg.icon or default_open_id_icon,
        version = msg.version,
        login_ip = msg.ip,
        phone = msg.phone or "",
        level = 0,
        imei = "",
        is_guest = true,
        login_time = os.time(),
        package_name = msg.package_name,
        phone_type = msg.phone_type,
        role = 0,
    }

    reddb:hmset("player:info:"..tostring(guid),info)
    reddb:set("player:account:"..tostring(msg.open_id),guid)
    
    channel.call("db.?","msg","LD_RegAccount",info)

    -- -- 注册时加默认房卡
    local register_money = global_conf.register_money
    if register_money and register_money > 0  then
        local player = base_players[guid]
        player:incr_money({
            money_id = 0,
            money = register_money,
        },enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)
    end

    player_money[guid] = nil

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function open_id_login(msg,gate)
    log.dump(msg)
    local ip = msg.ip
    default_open_id_icon = default_open_id_icon or global_conf.default_openid_icon

    local guid = reddb:get("player:account:"..tostring(msg.open_id))
    guid = tonumber(guid)
    if not guid then
        return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
    end

    local info = base_players[guid]
    if ip then
        reddb:hset("player:info:"..tostring(guid),"last_login_ip",ip)
    end

    log.dump(info)
    if info.status == 0 then
        return enum.ERROR_PLAYER_IS_LOCKED,info
    end

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function wx_auth(msg)
    log.dump(msg)
    local conf = global_conf.auth.wx
    local _,authjson = http_get(string.format(conf.auth_url.."?appid=%s&secret=%s&code=%s&grant_type=authorization_code",
            conf.appid,conf.secret,msg.code))
    local auth = json.decode(authjson)
    if auth.errcode then
        log.warning("wx_auth get access token failed,errcode:%s,errmsg:%s",auth.errcode,auth.errmsg)
        return tonumber(auth.errcode),auth.errmsg
    end

    local _,userinfojson = http_get(string.format(conf.userinfo_url.."?access_token=%s&openid=%s",auth.access_token,auth.openid))
    local userinfo = json.decode(userinfojson)
    if userinfo.errcode then
        log.warning("wx_auth get user info failed,errcode:%s,errmsg:%s",userinfo.errcode,userinfo.errmsg)
        return tonumber(auth.errcode),auth.errmsg
    end

    log.dump(userinfo)

    return nil,userinfo
end

function on_cl_auth(msg)
    local do_auth = wx_auth
    if not do_auth then
        return enum.LOGIN_RESULT_AUTH_CHECK_ERROR
    end

    local errcode,auth = do_auth(msg)
    if errcode then
        return enum.LOGIN_RESULT_AUTH_CHECK_ERROR,auth
    end

    local uuid = reddb:get(string.format("player:auth_id:%s",auth.unionid))
    if not uuid or uuid == "" then
        uuid = gen_uuid(auth.unionid)
        reddb:set(string.format("player:auth_id:%s",auth.unionid),uuid)
    end

    return reg_account({
        ip = msg.ip,
        open_id = uuid,
        nickname = auth.nickname,
        icon = auth.headimgurl,
        sex = auth.sex,
        package_name = msg.package_name,
        phone_type = msg.phone_type,
        version = msg.version,
    })
end


local function sms_reg_account(msg)
    local password = md5(msg.account)
    local guid = reddb:incr("player:global:guid")
    local info = {
        guid = guid,
        is_guest =  false,
        phone =  msg.phone,
        phone_type =  msg.phone_type,
        version =  msg.version,
        channel_id =  msg.channel_id,
        package_name =  msg.package_name,
        imei =  msg.imei,
        ip =  msg.ip,
        ip_area =  msg.ip_area,
        deprecated_imei =  msg.deprecated_imei,
        platform_id =  msg.platform_id,
        password = password,
        account = msg.account,
        nickname = msg.nickname,
        register_time = os.time(),
    }

    reddb:hmset("player:info:"..tostring(guid),info)
    reddb:set("player:account:"..tostring(msg.phone),guid)

    return enum.REG_ACCOUNT_RESULT_SUCCESS,info
end


local function sms_login(msg,_,session_id)
    if not session_id then
        return enum.LOGIN_RESULT_SMS_FAILED
    end

    local verify_code = reddb:get(string.format("sms:verify_code:session:%s",session_id))
    if not verify_code or verify_code == "" then
        return enum.LOGIN_RESULT_SMS_CLOSED
    end

    reddb:del(string.format("sms:verify_code:session:%s",session_id))

    if string.lower(verify_code) ~= string.lower(msg.sms_verify_no) then
        return enum.LOGIN_RESULT_SMS_FAILED
    end

    local phone = msg.phone
    if not phone then
        return enum.LOGIN_RESULT_TEL_ERR
    end

    local ret,info
    local uuid = reddb:get(string.format("player:phone_uuid:%s",msg.phone))
    if not uuid or uuid == "" then
        uuid = gen_uuid(phone)
        reddb:set(string.format("player:phone_uuid:%s",phone),uuid)
        ret,info =  reg_account({
            ip = msg.ip,
            open_id = uuid,
            nickname = string.sub(phone,1,3) .. "****" .. string.sub(phone,8),
            icon = math.random(1,1000),
            sex = math.random(1,2),
            package_name = msg.package_name,
            phone = msg.phone,
            phone_type = msg.phone_type,
            version = msg.version,
        })
        if ret ~= enum.ERROR_NONE then
            return ret
        end
    else
        local guid = reddb:get("player:account:"..tostring(uuid))
        guid = tonumber(guid)
        info = base_players[guid]
    end

	return enum.LOGIN_RESULT_SUCCESS,info
end

local function account_login(msg,gate)
    log.info( "login step login[offline]->LD_VerifyAccount ok,account=%s", msg.account)
    local account = msg.verify_account.account
	local platform_id = msg.platform_id
	local ip = msg.ip
	local phone = msg.phone
	local phone_type = msg.phone_type
	local version = msg.version
	local channel_id = msg.channel_id
	local package_name = msg.package_name
    local imei = msg.imei

    local using_login_validatebox = reddb:hget("player:login:validatebox",tostring(channel_id))
    local register_status = reddb:hgetall("player:register:ip:"..ip)
    local register_count = tonumber(register_status.count)
    if register_count > 3 and using_login_validatebox == 0 then
        using_login_validatebox = 1
    end

    local guid = reddb:get("player:account:"..tostring(account))
    guid = tonumber(guid)

    local player = base_players[guid]
    if not player or player.password ~= msg.password then
        log.error( "verify account[%s] failed,account or password invalid", account )
        return enum.LOGIN_RESULT_DB_ERR
    end

    if not player.shared_id then
        reddb:hset("player:account:"..tostring(account),"shared_id",msg.shared_id)
    end

    if not player.guid then
        log.error( "verify account[%s] failed", account )
        return enum.LOGIN_RESULT_ACCOUNT_EMPTY
    end

    if player.enable_transfer then
        log.error( "verify account[%s] failed", account )
        return enum.LOGIN_RESULT_AGENT_CANNOT_IN_GAME
    end

    if player.disable then
        log.error( "verify account[%s] failed", account )
        return enum.LOGIN_RESULT_ACCOUNT_DISABLED
    end

    local is_disable_ip = reddb:sismember("player:login:disable_ip",ip)
    if is_disable_ip  then
        log.error( "verify account[%s] failed", account )
        return enum.LOGIN_RESULT_IP_CONTROL
    end

    reddb:hincrby("player:info:"..tostring(guid),"login_count",1)
    reddb:hmset("player:info:"..tostring(guid),{
        last_login_phone = phone,
        last_login_phone_type = phone_type,
        last_login_version = version,
        last_login_channel_id = channel_id,
        last_login_imei = imei,
        last_login_ip = player.login_ip,
        login_ip = ip,
        login_time = os.now(),
    })

    channel.publish("db.?","msg","LD_LogLogin",{
        guid = player.guid,
        phone = phone,
        phone_type = phone_type,
        version = version,
        channel_id = channel_id,
        login_channel_id = msg.channel_id,
        imei = imei,
        ip = ip,
        is_guest = player.is_guest,
        create_time = player.create_time,
        register_time = player.register_time,
        deprecated_imei = player.deprecated_imei,
        platform_id = player.platform_id,
        sensiorpromoter = player.sensiorpromoter,
        package_name = package_name,
    })

	player.account = account
    player.platform_id = platform_id

    local status = msg.maintain_switch
    if status == 1 and player.vip ~= 100 then --vip不等于100的玩家在游戏维护时不能进入
        log.warning("=======maintain login==============status = [%d]", status)
        return {
            result = enum.LOGIN_RESULT_MAINTAIN,
        }
    end

    return enum.LOGIN_RESULT_SUCCESS,player
end

local function h5_login(msg,gate)
    local guid = reddb:get("player:account:"..tostring(msg.open_id))
    if not guid then
        return reg_account({
            open_id = msg.open_id,
            version = msg.version,
            phone_type = msg.phone_type,
            package_name = msg.package_name,
            ip = msg.ip,
            sex = msg.sex or false,
        })
    end

    local info = base_players[tonumber(guid)]
    log.dump(info)
    if info.status == 0 then
        return enum.ERROR_PLAYER_IS_LOCKED,info
    end

    return enum.LOGIN_RESULT_SUCCESS,info
end

function on_cl_login(msg,gate,session_id)
    local account = (msg.account and msg.account ~= "") and msg.account or msg.open_id
    log.dump(msg)
    local ret,info

    if msg.open_id and msg.open_id ~= "" then
        if msg.phone_type == "H5" then
            ret,info = h5_login(msg,gate)
        else
            ret,info = open_id_login(msg,gate)
        end
    elseif msg.phone ~= "" and msg.sms_verify_no ~= "" then
        ret,info = sms_login(msg,gate,session_id)
    end

    log.dump(info)

    if ret ~= enum.LOGIN_RESULT_SUCCESS then
        return {
            result = ret,
        }
    end

    info = clone(info)

    -- 重连判断
    local game_id = reddb:hget("player:online:guid:"..tostring(info.guid),"server")
    if game_id then
        log.info("player[%s] reconnect game_id:%s ,session_id = %s ,gate_id = %s", info.guid, game_id, info.session_id, info.gate_id)
        info.result = enum.LOGIN_RESULT_SUCCESS
        local reconnect = 1
        info.reconnect = reconnect
        reddb:hset("player:online:guid:"..tostring(info.guid),"gate",gate)
        reddb:set("player:online:account:"..account,info.guid)

        channel.publish("game."..tostring(game_id),"msg","LS_LoginNotify",info.guid,reconnect)

        log.dump(info)

        log.info("login step reconnect login->LS_LoginNotify,account=%s,gameid=%s,session_id = %s,gate_id = %s",
            account, game_id, info.session_id, info.gate_id)
        return info,game_id
    end

    -- 找一个默认大厅服务器
    game_id = find_a_default_lobby()
    if not game_id then
        log.warning("no default lobby")
        return {
            result = enum.LOGIN_RESULT_NO_DEFAULT_LOBBY,
        }
    end

    channel.publish("db.?","msg","LD_LogLogin",{
        guid = info.guid,
        phone = msg.phone,
        phone_type = msg.phone_type,
        version = msg.version,
        channel_id = msg.channel_id,
        login_channel_id = msg.channel_id,
        imei = msg.imei,
        ip = msg.ip,
        is_guest = info.is_guest,
        create_time = info.create_time,
        register_time = info.register_time,
        deprecated_imei = info.deprecated_imei,
        platform_id = info.platform_id,
        sensiorpromoter = info.sensiorpromoter,
        package_name = msg.package_name,
    })
    
    -- 存入redis
    reddb:hmset("player:online:guid:"..tostring(info.guid),{
        gate = gate,
        login = def_game_id,
    })
    reddb:set("player:online:account:"..account,info.guid)

    channel.publish("game."..tostring(game_id),"msg","LS_LoginNotify",info.guid)

    log.info("login step login->LS_LoginNotify,account=%s,gameid=%d", account, game_id)

    info.result = enum.LOGIN_RESULT_SUCCESS

    onlineguid[info.guid] = nil
 
    return info,game_id
end

function on_cl_reg_account(msg,gate)  
    local validatebox_ip = reddb:get("validatebox_feng_ip")
	local is_validatebox_block = validatebox_ip and tonumber(validatebox_ip) or 0
    local account = msg.pb_regaccount.account
    local imei = msg.pb_regaccount
	if account and account ~= "" then
		log.warning("has account")
		return
    end

    if not imei and imei == "" then
        log.warning("imei has account")
        return enum.LOGIN_RESULT_FAILED
    end
    
    local guid = reddb:get("player:imei:"..tostring(msg.pb_regaccount.imei))
    if guid then
        log.warning("has account with imei")
        return enum.LOGIN_RESULT_FAILED
    end

    guid = reddb:incr("player:global:guid")
    local info = msg.pb_regaccount
    info.guid = guid
    info.account = "guest_"..tostring(guid)
    info.nickname = "guest_"..tostring(guid)
    info.login_time = os.time()
    info.is_guest = true
    info.login_ip = info.ip
    info.register_time = os.time()
    info.role = 0
    reddb:hmset("player:info:"..tostring(guid),info)
    reddb:set("player:account:"..tostring(info.account),guid)
    if info.inviter_guid then
        reddb:set("proxy:info:"..tostring(guid),info.inviter_guid)
    end

    log.info("[%s] reg account, guid = %d ,platform_id = %s", info.account, info.guid,info.platform_id)

    -- 找一个默认大厅服务器
    local gameid = find_a_default_lobby()
    if not gameid then
        log.warning("no default lobby")
        return {
            result = enum.LOGIN_RESULT_NO_DEFAULT_LOBBY
        }
    end

    -- 存入redis
    reddb:hmset("player:online:guid"..tostring(info.guid),{
        server = gameid,
        gate = gate,
    })

    reddb:set("player:online:account:"..account,info.guid)

    channel.publish("game."..tostring(gameid),"msg","LS_LoginNotify",{
        player_login_info = info,
        password = msg.password,
    })

    info.ret = enum.LOGIN_RESULT_SUCCESS

    return info,gameid
end


function on_cl_login_by_sms(msg,session)
    local info = {}
	info.account = msg.account
	info.phone = msg.phone
	info.phone_type = msg.phone_type
	info.version = msg.version
	info.channel_id = msg.channel_id
	info.package_name = msg.package_name
	info.imei = msg.imei
	info.ip = msg.ip
	info.ip_area = msg.ip_area
	info.platform_id = msg.platform_id
	info.deprecated_imei = msg.deprecated_imei
	info.shared_id = msg.shared_id
    info.unique_id = msg.unique_id
    
	log.info( "account [%s] phone [%s] phone_type[%s] version[%s]",info.account, info.phone, info.phone_type, info.version )

    return sms_login(msg)
end

function on_L_KickClient(msg)  
	local account_ = msg.reply_account
	local platform_id = msg.platform_id
	local userdata = msg.user_data
	if userdata == 1 then
        local info = get_player_login_info_temp(account_key)
        if info then
            log.info( "[%s] reg account, guid = %d", account_key, info )
            local gameid = find_a_default_lobby()
            if gameid == 0 then
                local session_id = info.session_id
                local gate_id = info.gate_id

                sendpb2guids(session_id,gate_id,"LC_Login",{
                    result = enum.LOGIN_RESULT_NO_DEFAULT_LOBBY,
                })
                
                reddb.hdel("player:login:info",account_key)
                reddb.hdel("player:login:info:guid",info.guid)

                log.warning( "no default lobby" )
                return
            end

            reddb.hdel("player:login:info:temp",account_key)

            reddb.hset("player_online_gameid",info.guid,gameid)
            reddb.hset("player_session_gate",string.format("%d@%d",info.session_id,info.gate_id),info.account)
            reddb.hset("player:login:info",account_key,json.encode(info))
            reddb.hset("player:login:info:guid",info.guid,json.encode(info))

            channel("game."..tostring(gameid),"LS_LoginNotify",{
                player_login_info = info,
            })
        end
	elseif userdata == 2 then
		local info = get_player_login_info_temp(account_key)        
        if info then
            log.info( "[%s] login account, guid = %d", account_key, info.guid )

            reddb.hdel("player:login:info:temp",account_key)

            reddb.hset("player:login:info",account_key,json.encode(info))
            reddb.hset("player:login:info:guid",info.guid,json.encode(info))
            channel.publish("db.?","msg","LD_VerifyAccount",{
                verify_account = {
                    account = info.account,
                    password = info.password,
                },
                session_id = info.session_id, 
                gate_id = info.gate_id, 
                ip = info.ip, 
                phone = info.phone, 
                phone_type = info.phone_type, 
                version = info.version, 
                channel_id = info.channel_id, 
                package_name = info.package_name, 
                imei = info.imei, 
                deprecated_imei = info.deprecated_imei, 
                platform_id = info.platform_id, 
            })
        end
	elseif userdata == 3 then
        local info = get_player_login_info_temp(account_key)
        if info then
            log.info( "[%s] loginsms account, guid = %d", account_key, info.guid)

            reddb.hdel("player:login:info:temp",account_key)

            reddb.hset("player:login:info",account_key,json.encode(info))
            reddb.hset("player:login:info:guid",info.guid,json.encode(info))

            channel.publish("db.?","msg","LD_SmsLogin",{
                account = info.account,
                session_id = info.session_id,
                gate_id = info.gate_id,
                phone = info.phone,
                phone_type = info.phone_type,
                version = info.version,
                channel_id = info.channel_id,
                package_name = info.package_name,
                imei = info.imei,
                ip = info.ip,
                ip_area = info.ip_area,
                deprecated_imei = info.deprecated_imei,
                platform_id = info.platform_id,
                shared_id = info.shared_id,
                unique_id = info.unique_id,
            })
        end
	end

	log.info( "login step login[online]->L_KickClient,account=%s,userdata=%d", account_key, userdata )
end

function on_cs_request_sms_verify_code(msg,session_id)
    if not session_id then
        return enum.LOGIN_RESULT_SMS_FAILED
    end

    local verify_code = reddb:get(string.format("sms:verify_code:session:%s",session_id))
    if verify_code and verify_code ~= "" then
        return enum.LOGIN_RESULT_SMS_REPEATED
    end

    local phone_num = msg.phone_number
    log.info( "RequestSms session [%s] =================", session_id )
    if not phone_num then
        log.error( "RequestSms session [%s] =================tel not find", session_id)
        return enum.LOGIN_RESULT_TEL_ERR
    end

    log.info( "RequestSms =================tel[%s] platform_id[%s]",  msg.tel, msg.platform_id)
    local phone_num_len = string.len(phone_num)
    if phone_num_len < 7 or phone_num_len > 18 then
        return enum.LOGIN_RESULT_TEL_LEN_ERR
    end

    local prefix = string.sub(phone_num,1, 3)
    if prefix == "170" or prefix == "171" then
        return enum.LOGIN_RESULT_TEL_ERR
    end

    if prefix == "999" then
        local expire = math.floor(global_conf.sms_expire_time or 60)
        local code =  string.sub(phone_num,phone_num_len - 4 + 1)
        local rkey = string.format("sms:verify_code:session:%s",session_id)
        reddb:set(rkey,code)
        reddb:expire(rkey,expire or 60)
        return enum.LOGIN_RESULT_SUCCESS
    end

    if not  string.match(phone_num,"^%d+$") then
        log.info("phone number %s is invalid.",phone_num)
        return enum.LOGIN_RESULT_TEL_ERR
    end

    local expire = math.floor(global_conf.sms_expire_time or 60)
    local code = string.format("%4d",math.random(4001,9999))
    local rkey = string.format("sms:verify_code:session:%s",session_id)
    reddb:set(rkey,code)
    reddb:expire(rkey,expire)
    channel.publish("gate.?","lua","LG_PostSms",phone_num,string.format("【友愉互动】您的验证码为%s, 请在%s分钟内验证完毕.",code,math.floor(expire / 60)))
end

function on_cs_chat_world(msg)  
    channel.publish("gate.*","msg","CS_ChatWorld",msg)
end

function on_gl_NewNotice(msg)  
    write_gm_msg( msg.retid,msg.asyncid, msg.result )
end

function on_SL_GameNotice(msg)  
    local platform_ids = {}
    if msg.platform_id then
        table.insert(platform_ids,msg.platform_id)
    else
    end

    channel.publish("gate.*","msg","LS_GameNotice",{
        pb_game_notice = msg.pb_game_notice,
        platform_ids = platform_ids,
    })
end

