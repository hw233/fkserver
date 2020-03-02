
local redisopt = require "redisopt"
local msgopt = require "msgopt"
local skynet = require "skynetproto"
local channel = require "channel"
local onlineguid = require "netguidopt"
local log = require "log"
local json = require "cjson"
local serviceconf = require "serviceconf"
local base_players = require "game.lobby.base_players"
local md5 = require "md5.core"
local enum = require "pb_enums"
local dbopt = require "dbopt"
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

    return true
end

local function reg_account(msg)
    local guid = reddb:get("player:account:"..tostring(msg.open_id))
    if guid then
        log.warning("reg_account repeated.open_id:%s,guid:%s",msg.open_id,guid)
        return enum.LOGIN_RESULT_RESET_ACCOUNT_DUP_ACC,base_players[tonumber(guid)]
    end

    guid = reddb:incr("player:global:guid")
    guid = tonumber(guid)
    local info = {
        guid = guid,
        account = msg.open_id,
        nickname = msg.nickname or ("guest_"..tostring(guid)),
        open_id = msg.open_id,
        sex = msg.sex or false,
        icon = msg.icon or default_open_id_icon,
        version = msg.version,
        login_ip = msg.ip,
        phone = msg.phone or "",
        status = 0,
        user_type = 1,
        tickets = 0,
        level = 0,
        bank = 0,
        imei = "",
        is_guest = true,
        login_time = os.time(),
        package_name = msg.package_name,
        phone_type = msg.phone_type,
    }

    reddb:hmset("player:info:"..tostring(guid),info)
    reddb:set("player:account:"..tostring(msg.open_id),guid)
    -- 测试注册时加默认房卡
    
    channel.call("db.?","msg","LD_RegAccount",info)

    local player = base_players[guid]
    player:incr_money({
        money_id = 0,
        money = 1000000,
    },enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)

    player_money[guid] = nil

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function open_id_login(msg,gate)
    dump(msg)
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

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function wx_auth(msg)
    dump(msg)
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

    dump(userinfo)

    return nil,userinfo
end

local function cn_auth(msg)

end

local function xl_auth(msg)

end

function on_cl_auth(msg)
    local auth_platforms = {
        wx = wx_auth,
        cn = cn_auth,
        xl = xl_auth,
    }

    local do_auth = auth_platforms[msg.auth_platform]
    if not do_auth then
        return enum.LOGIN_RESULT_AUTH_CHECK_ERROR
    end

    local errcode,auth = do_auth(msg)
    if errcode then
        return enum.LOGIN_RESULT_AUTH_CHECK_ERROR,auth
    end

    return reg_account({
        ip = msg.ip,
        open_id = auth.openid,
        nickname = auth.nickname,
        icon = auth.headimgurl,
        sex = auth.sex,
        package_name = msg.package_name,
        phone_type = msg.phone_type,
        version = msg.version,
    })
end


local function sms_reg_account(msg)
    if not msg.invite_code then
        return enum.LOGIN_RESULT_NEED_INVITE_CODE
    end

    local is_block_ip = reddb:hgetall("player:block:ip:"..tostring(msg.ip))
    if tonumber(is_block_ip) ~= 0 then
        return enum.LOGIN_RESULT_FAILED
    end

    local ip_register = reddb:hgetall("player:register:ip:"..tostring(msg.ip))
    if ip_register.disable then
        return enum.LOGIN_RESULT_IP_CREATE_ACCOUNT_LIMIT
    end

    local is_validatebox_block = ip_register.disable and tonumber(ip_register.disable) > 0 or false
    if ip_register.count > 20 then
        return enum.LOGIN_RESULT_CREATE_MAX
    end

    local password = md5(msg.account)
    
    local guid = reddb:incr("player:global:guid")
    local info = {}
    info.guid = guid
    info.is_guest =  false
    info.phone =  msg.phone
    info.phone_type =  msg.phone_type
    info.version =  msg.version
    info.channel_id =  msg.channel_id
    info.package_name =  msg.package_name
    info.imei =  msg.imei
    info.ip =  msg.ip
    info.ip_area =  msg.ip_area
    info.deprecated_imei =  msg.deprecated_imei
    info.platform_id =  msg.platform_id
    info.password = password
    info.account = msg.account
    info.nickname = msg.nickname
    info.register_time = os.time()
    
    reddb:hmset("player:info:"..tostring(guid),info)
    reddb:set("player:account:"..tostring(msg.phone),guid)

    info.using_login_validatebox = is_validatebox_block and 1 or 0

    reddb:hmset("player:proxy:relationship",{
        guid = guid,
        inviter_guid = msg.inviter_guid,
        inviter_account = msg.inviter_account,
    })

    return enum.REG_ACCOUNT_RESULT_SUCCESS,info
end


local function sms_login(msg,gate)
    local account = msg.account
    local phone = msg.phone
    local phone_type = msg.phone_type
    local version = msg.version
    local channel_id = msg.channel_id
    local imei = msg.imei
    local ip = msg.ip
    local package_name = msg.package_name

    local guid = reddb:get("player:account:"..tostring(account))
    guid = tonumber(guid)
    local player = base_players[guid]
    if not player then
        local ret,info = sms_reg_account(msg)
        if ret == enum.REG_ACCOUNT_RESULT_SUCCESS then
            return enum.LOGIN_RESULT_SUCCESS,info
        end

        return enum.LOGIN_RESULT_FAILED
    end

    if player.imei ~= msg.imei or player.platform_id ~= msg.platform_id then
        return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
    end

    if not player.guid then
        return enum.LOGIN_RESULT_DB_ERR
    end

    if not player.is_guest then
        reddb:hset("player:account:"..account,"is_guest",0)
    end

    if not player.share_id then
        reddb:hset("player:account:"..account,"shared_id",msg.shared_id)
    end

    if player.enable_transfer then
        return enum.LOGIN_RESULT_AGENT_CANNOT_IN_GAME
    end

    if player.disable then
        return enum.LOGIN_RESULT_ACCOUNT_DISABLED
    end

    local disable_ip = reddb:hget("player:login:disable_ip",ip)
    if disable_ip  then
        log.error( "sms_login[%s] failed", account )
        return enum.LOGIN_RESULT_IP_CONTROL
    end

    reddb:hincrby("player:info:"..tostring(guid),"login_count",1)

    reddb:hmset("player:info:"..tostring(guid),{
        last_login_phone = phone,
        last_login_phone_type = phone_type,
        last_login_version = version,
        last_login_channel_id = channel_id,
        last_login_imei = imei,
        last_login_ip = ip,
        login_time = os.time(),
    })

	return enum.LOGIN_RESULT_SUCCESS,player
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
        last_login_ip = ip,
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

    return enum.LOGIN_RESULT_SUCCESS,info
end

function on_cl_login(msg,gate)
    local account = (msg.account and msg.account ~= "") and msg.account or msg.open_id

    local ret,info
    if msg.phone_type == "H5" then
        ret,info = h5_login(msg,gate)
    elseif msg.open_id and msg.open_id ~= "" then
        ret,info = open_id_login(msg,gate)
    elseif msg.sms_no and msg.sms_no ~= "" then
        ret,info = sms_login(msg,gate)
    else
        ret,info = account_login(msg,gate)
    end

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

        dump(info)

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


function on_SL_ChangeGameResult(msg)
    channel("game."..tostring(msg.game_id),msg.change_msg)
end

function on_cs_request_sms(msg)
    
end

function on_sd_bank_transfer(msg)  
	local self_game_id = server_id_

    local info = get_player_login_info(msg.target)

    if info then
        local game_id = get_gameid_by_guid(info.guid)
        if game_id then
            if has_game_server_info( game_id ) then
                channel.publish("game."..tostring(self_game_id),"msg","LS_BankTransferSelf",{
                    guid = msg.guid,
                    time = msg.time,
                    target = msg.target,
                    money = msg.money,
                    bank_balance = msg.bank_balance,
                })

                channel.publish("game."..tostring(game_id),"msg","LS_BankTransferTarget",{
                    selfname = msg.selfname,
                    time = msg.time,
                    target = msg.target,
                    money = msg.money,
                })
                
                return
            end
        end
    end

    channel.publish("db.?","msg","SD_BankTransfer",msg)
end

function on_sd_bank_transfer_by_guid(msg)  
    msg.game_id = server_id_

    local game_id = get_gameid_by_guid( msg.target_guid )
    if game_id then
        if has_game_server_info( game_id ) then
            channel.publish("game."..tostring(msg.game_id),"msg","LS_BankTransferByGuid",{
                guid = msg.guid,
                money = -msg.money,
            })

            channel.publish("game."..tostring(game_id),"msg","LS_BankTransferByGuid",{
                guid = msg.target_guid,
                money = msg.money,
            })

            return
        end
    end

    channel.publish("db.?","msg","S_BankTransferByGuid",msg)
end

function on_cs_chat_world(msg)  
    channel.publish("gate.*","msg","CS_ChatWorld",msg)
end

function on_sc_chat_private(msg)
    local info = get_player_login_info(msg.private_name)
    if info then
        local game_id = get_gameid_by_guid( info.guid )
        if game_id then
            channel.publish("game."..tostring(game_id),"msg","SC_ChatPrivate",msg)
        end
    end
end

function on_wf_recharge(msg)  
	local order_id = msg.order_id
	local guid = msg.guid
	local money = msg.money
	local asyncid = msg.asyncid
	log.info( "on_wf_recharge asyncid[%s] start guid[%d] orderid[%d] money[%d]", asyncid, guid, order_id, money )

    local info = channel.call("db.?","LD_Recharge",{
        guid = guid,
        retid = 0,
        asyncid = asyncid,
        money = money,
        order_id = order_id
    })

    log.info("LoginDBSession::on_dl_recharge guid[%d] retcode[%d]", info.guid, info.retcode)
    local ret = {
        result = info.retcode,
        asyncid = info.asyncid,
    }

	local changemoney = info.changemoney
	local newbankmoney = info.bank
    local guid = info.guid
    local onlineinfo = onlineguid[guid]

    if not onlineinfo or not onlineinfo.gate then
        -- 玩家不在线
        log.info("LoginDBSession::on_dl_recharge guid[%d] not online", guid)
        return ret
    end

    if changemoney == 0 then
        -- 金钱无变化  不需要通知
        log.info("LoginDBSession::on_dl_recharge guid[%d] changemoney == 0", guid)
        return ret
    end

    onlineguid.send(guid,"",{
        guid = guid,
        bankmoney = newbankmoney,
        changemoney = changemoney,
    })

    return ret
end

function on_gl_NewNotice(msg)  
    write_gm_msg( msg.retid,msg.asyncid, msg.result )
end

function on_sl_cash_false_reply(msg)  
    if msg.result ~= 5 then       
        channel.call("db.?","msg","LD_CashReply",{
            web_id = msg.web_id,
            result = msg.result,
            order_id = msg.order_id,
        })

        channel.publish("gm."..tostring(msg.web_id),"msg","LW_CashFalse",{
            result = msg.result,
        })
    else
        channel.publish("gm."..tostring(msg.web_id),"msg","LW_CashFalse",{
            result = msg.result,
        })
    end
end

function on_wl_request_change_tax(msg)  
    local gameid = netopt.byid(SessionGate,msg.id).server_id
    if gameid then
        channel.publish("game."..tostring(msg.id),"msg","LS_ChangeTax",{
            webid = netopt.byfd(fd).server_id,
            tax = msg.tax,
            is_show = msg.is_show,
            is_enable = msg.is_enable,
        })
    else
        sendpb("LW_ChangeTax",{
            result = 2,
        })
    end
end

function on_sl_change_tax_reply(msg)  
    channel.publish("gm."..tostring(msg.webid),"msg","LW_ChangeTax",{
        result = msg.result,
    })
end

function on_wl_request_gm_change_money(msg)  
	local guid = msg.guid
	local bank_money = msg.bank_money
	local login_id = 

    sendpb("LD_GMChangMoney",{
        web_id = netopt.byfd(fd).server_id,
        login_id = login_id,
        guid = guid,
        bank_money = bank_money,
        type_id = LOG_MONEY_OPT_TYPE_GM,
    })
end

function on_wl_request_lua_change_players_money(msg)  
    local guid = msg.guid
    local gmcommand = msg.gmcommand
    local onlineinfo = onlineguid[guid]
    if not onlineinfo then
        return
    end

    local gateid = onlineinfo.gate
    if not gateid then
        channel.publish("db.?","msg","LD_OfflineChangeMoney",{
            guid = guid,
            gmcommand = msg.gmcommand,
        })

        return {
            result = 1,
        }
    end


    local gameid = reddb.hget("player:online:guid:"..tostring(guid),"server")
    if gameid then
        channel.publish("gate."..tostring(gameid),"msg","LS_ChangeMoney",{
            webid = webid,
            guid = guid,
            gmcommand = gmcommand,
        })

        channel.publish("gm."..tostring(webid),"msg","LW_ChangePlayersMoney",{
            result = 1,
        })
        return
    end

    channel.publish("db.?","msg","LD_OfflineChangeMoney",{
        guid = guid,
        gmcommand = gmcommand,
    })

    channel.publish("gm.?","msg","LD_OfflineChangeMoney",{
        result = 1,
    })
end

function on_WL_LuaCmdPlayerResult(msg)  
	local webid = netopt.byfd(fd).server_id
	local login_id = netopt.byid(SessionGate,msg.id).server_id
	local guid = msg.guid
	local bank_money = msg.money
	local banker_type = msg.banktype
	local order_id = msg.order_id

    channel.publish("db.?","msg","LD_ReturnAgentMoney",{
        web_id = webid,
        login_id = login_id,
        guid = guid,
        bank_money = bank_money,
        type_id = banker_type,
        order_id = order_id,
    })
end

function on_SL_LuaCmdPlayerResult(msg)
    channel.publish("gm."..tostring(msg.web_id),"msg","LW_LuaCmdPlayerResult",{
        result = msg.result,
        guid = msg.guid,
        order_id = msg.order_id,
        cost_money = msg.cost_money,
        acturl_cost_money = msg.acturl_cost_money,
    })
end


function on_WL_GmCommandToServer(msg)  
    local webid = netopt.byfd(fd).server_id

	printf( msg.cmd_content )
    
    local doc = json.decode(msg.cmd_content)
	if not doc then
		printf( "on_WL_GmCommandToServer parse json error..." )
		channel.publish("gm."..tostring(webid),"msg","LW_GmCommandToServerResult",{
            result = 2,
        })
		return
    end

    if not json_has_member(doc,{
        command= "number",
    }) then
        printf( "on_WL_GmCommandToServer command not found..." )
		channel.publish("gm."..tostring(webid),"msg","LW_GmCommandToServerResult",{
            result = 3,
        })
        return
    end

    if doc.command == 1 then
        local m = {}
        if doc.id and type(doc.id) == "number" then
            m.activity_id = doc.id
        end

        printf( "on_WL_GmCommandToServer LS_UpdateBonusHongbao  id [%d]", doc.id)
        printf( "\n" )

        channel.publish("gate.*","msg","LS_UpdateBonusHongbao",m)
    else
		log.warning( "on_WL_GmCommandToServer unknown Command code [%d]", doc.command )
	end

	channel.publish("gm."..tostring(webid),"msg","LW_GmCommandToServerResult",{
        result = 1,
    })
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

function on_SL_RequestProxyInfo(msg)
    channel.publish("config.?","msg","S_RequestProxyInfo",{
        platform_id = msg.platform_id,
    })
end

function on_wl_broadcast_gameserver_cmd(msg)

end

function on_WF_CashFalse(msg)
	log.info( "on_WF_CashFalse......order_id[%d]", msg.order_id )
    
    local info = channel.call("db.?","FD_ChangMoney",{
        order_id = msg.order_id,
        type_id = LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE,
        other_oper = msg.del,
    })
end

function on_FS_ChangMoneyDeal(msg)
    log.info( "on_FS_ChangMoneyDeal  web[%s] gudi[%s] order_id[%s] type[%s]", 
        msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id )

    local info = channel.call("db.?","FD_ChangMoneyDeal",{
        info = msg.info,
        web_id = msg.web_id,
        login_id = msg.login_id,
    })
end

function on_SL_AT_ChangeMoney(msg)
    log.info( "on_SL_AT_ChangeMoney  transfid[%s] guid [%d] key[%s]", msg.transfer_id, msg.guid, msg.keyid )
end

function on_sl_FreezeAccount(msg)
	if msg.ret == 0 then
		write_gm_msg(msg.retid,GMmessageRetCode_Success,msg.asyncid)
    else
        write_gm_msg(msg.retid,GMmessageRetCode_FreezeAccountGameFaild,msg.asyncid)
	end
end


function on_db_request(msg)
    
end


function on_do_SqlReQuest(msg)

end
