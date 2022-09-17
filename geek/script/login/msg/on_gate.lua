
local redisopt = require "redisopt"
local channel = require "channel"
local onlineguid = require "netguidopt"
local skynet = require "skynetproto"
local log = require "log"
local player_data = require "game.lobby.player_data"
local enum = require "pb_enums"
local util = require "util"
local player_money = require "game.lobby.player_money"
require "functions"
require "login.msg.runtime"
local runtime_conf = require "game.runtime_conf"
local g_common = require "common"
local game_util = require "game.util"
local mutex = require "mutex"
local verify = require "login.verify.verify"
local imei_error_count = require "login.verify.imei_error_count"
local reddb = redisopt.default

local function gen_uuid(basestr)
    local entirestr = basestr..tostring(skynet.time())..tostring(math.random(10000))
    return util.sha1(entirestr)
end

local function is_player_vip(info)
    return info.vip and info.vip ~= 0
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
            channel.publish("game."..tostring(gameid),"msg","S_Logout",guid)
        end
    end

    reddb:hdel("player:online:guid:"..tostring(guid),"gate")

    onlineguid[guid] = nil

    return true
end

local function random_guid()
    local guid
    local exists
    for _ = 1,10000 do
        guid = math.random(100000,999999)
        exists = reddb:sismember("player:all",guid)
        if not exists then
            return guid
        end
    end
end

local function reg_account(msg)
    local guid = reddb:get("player:account:"..tostring(msg.open_id))
    if guid then
        guid = tonumber(guid)
        local p = player_data[guid]
        if p and p.status == 0 then
            return enum.ERROR_PLAYER_IS_LOCKED
        end

        log.warning("reg_account repeated.open_id:%s,guid:%s",msg.open_id,guid)
        local reginfo = {
            nickname = msg.nickname or ("guest_"..tostring(guid)),
            icon = msg.icon or default_open_id_icon,
            version = msg.version,
            login_ip = msg.ip,
            login_time = os.time(),
            package_name = msg.package_name,
            phone_type = msg.phone_type,
            union_id = msg.union_id,
        }
        
        reddb:hmset("player:info:"..tostring(guid),reginfo)

        if g_common.is_in_maintain() and not p:is_vip() then
            return enum.LOGIN_RESULT_MAINTAIN
        end

        local info = {
            guid = guid,
            account = p.open_id,
            nickname = p.nickname,
            open_id = p.open_id,
            sex = p.sex,
            icon = p.icon,
            version = p.version,
            login_ip = p.ip,
            level = 0,
            imei = "",
            is_guest = true,
            login_time = os.time(),
            package_name = p.package_name,
            phone_type = p.phone_type,
            role = 0,
            ip = p.ip,
            promoter = p.promoter,
            channel_id = p.channel_id,
            union_id = msg.union_id,
            vip = p.vip,
        }
        
        return enum.LOGIN_RESULT_RESET_ACCOUNT_DUP_ACC,info
    end

    local channel_id = (msg.channel_id and msg.channel_id ~= "") and msg.channel_id or nil
    local promoter = (msg.promoter and msg.promoter ~= 0) and msg.promoter or nil
    repeat
        local param = util.request_share_params(msg.sid)
        log.dump(param)
        if not param then break end

        channel_id = param.channel_id or channel_id
        promoter = tonumber(param.promoter) or promoter
    until true

    local result,ok
    ok,result,guid = mutex("guid:spinlock",function()
        local id = tonumber(random_guid())
        if not id then
            log.error("random guid faild,maybe number isn't enough.")
            return enum.ERROR_INTERNAL_UNKOWN
        end

        reddb:sadd("player:all",id)
        return enum.ERROR_NONE,id
    end)

    if result ~= enum.ERROR_NONE then
        return result
    end

    local info = {
        guid = guid,
        account = msg.open_id,
        nickname = msg.nickname or ("guest_"..tostring(guid)),
        open_id = msg.open_id,
        sex = msg.sex or 1,
        icon = msg.icon or default_open_id_icon,
        version = msg.version,
        login_ip = msg.ip,
        level = 0,
        imei = msg.imei,
        is_guest = true,
        login_time = os.time(),
        package_name = msg.package_name,
        phone_type = msg.phone_type,
        role = 0,
        ip = msg.ip,
        union_id = msg.union_id,
        promoter = promoter,
        channel_id = channel_id,
    }

    local phone = msg.phone
    local phonelen = string.len(phone or "")
    if 	not phone or
        not string.match(phone,"^%d+$") or 
        phonelen < 7 or 
        phonelen > 18 then
        info.phone = phone
    end
    log.dump(info,"reg_account:"..tostring(guid))
    reddb:hmset("player:info:"..tostring(guid),info)
    reddb:set("player:account:"..tostring(msg.open_id),guid)
    
    channel.publish("db.?","msg","LD_RegAccount",info)

    -- -- 注册时加默认房卡
    local register_money = global_conf.register_money
    if register_money and register_money > 0  then
        local player = player_data[guid]
        player:incr_money({
            money_id = 0,
            money = register_money,
        },enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)
        game_util.log_statistics_money(0,register_money,enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)
    end

    player_money[guid] = nil
    local authMsg = {
        limit = verify.limit,
        curcount = verify.curcount,
    }
    return enum.LOGIN_RESULT_SUCCESS,info,authMsg
end

local function open_id_login(msg)
    log.dump(msg)
    default_open_id_icon = default_open_id_icon or global_conf.default_openid_icon

    local guid = reddb:get("player:account:"..tostring(msg.open_id))
    guid = tonumber(guid)
    if not guid then
        return enum.LOGIN_RESULT_ACCOUNT_NOT_EXISTS
    end

    local player = player_data[guid]
    if player and player.status == 0 then
        return enum.ERROR_PLAYER_IS_LOCKED
    end

    local ip = msg.ip 
    if ip then
        reddb:hset(string.format("player:info:%s",guid),"login_ip",ip)
        if not verify.check_ip(ip,guid) then
            return enum.LOGIN_RESULT_ACCOUNT_IP_LIMIT
        end
    end

    local imei = msg.imei
    if not verify.check_imei(imei,guid) then
        return enum.LOGIN_RESULT_ACCOUNT_IMEI_LIMIT 
    end
    
    reddb:hset(string.format("player:info:%s",guid),"version",msg.version)

    local info = {
        guid = player.guid,
        account = player.open_id,
        nickname = player.nickname or ("guest_"..tostring(guid)),
        open_id = player.open_id,
        sex = player.sex or 1,
        icon = player.icon or default_open_id_icon,
        version = player.version,
        login_ip = ip or player.login_ip,
        phone = player.phone or "",
        level = player.level,
        imei = player.imei or "",
        is_guest = true,
        login_time = os.time(),
        package_name = player.package_name,
        phone_type = player.phone_type,
        role = player.role,
        ip = ip or player.login_ip,
        promoter = player.promoter,
        channel_id = player.channel_id,
        vip = player.vip,
    }

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function wx_auth(msg)
    log.dump(msg)
    local code = msg.code
    local package = msg.package_name
    return channel.call("broker.?","msg","SB_PackageWxAuth",code,package)
end

function on_cl_auth(msg)
    local do_auth = wx_auth
    if not do_auth then
        return enum.LOGIN_RESULT_AUTH_CHECK_ERROR
    end
    log.dump(msg,"on_cl_auth")
    local ip = msg.ip 
    if ip then
        local guid = reddb:get("player:account:"..tostring(msg.open_id))
        if not guid then
            if not verify.check_have_same_ip(ip) then
                if not verify.check_ip_auth(ip) then
                    return enum.LOGIN_RESULT_IP_CREATE_ACCOUNT_LIMIT,ip
                end
            end
        end
    end

    local errcode,auth = do_auth(msg)
    if errcode then
        return enum.LOGIN_RESULT_AUTH_CHECK_ERROR,auth
    end

    log.dump(auth)

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
        promoter = msg.promoter,
        channel_id = msg.channel_id,
        union_id = auth.unionid,
        sid = msg.sid,
        imei = msg.imei
    })
end
 
function on_s_auth_check(msg)
    log.dump(msg,"on_s_auth_check")
    if not msg or not msg.ip or msg.ip =="" or not msg.curcount then
        return 
    end
    local ip = msg.ip
    local rdip 
    if ip and type(ip)=="string" then
        local i1,i2,i3,i4 = ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)" )
        rdip =  i1.."_"..i2.."_"..i3.."_"..i4
    end

    reddb:hmset(string.format("verify:ip_auth_accounts:%s",rdip),{
            limit =  msg.limit,
            curcount = msg.curcount,
            limitstart = os.time(),
        })
end

local function sms_reg_account(msg)
    local password = util.md5(msg.account)
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


local function sms_login(msg)
    log.dump(msg)
    local phone = msg.phone
    if not phone then
        return enum.LOGIN_RESULT_TEL_ERR
    end

    local verify_code = reddb:get(string.format("sms:verify_code:phone:%s",phone))
    if not verify_code or verify_code == "" then
        return enum.LOGIN_RESULT_SMS_CLOSED
    end

    reddb:del(string.format("sms:verify_code:phone:%s",phone))

    if string.lower(verify_code) ~= string.lower(msg.sms_verify_no) then
        return enum.LOGIN_RESULT_SMS_FAILED
    end

    local ret,info
    local uuid = reddb:get(string.format("player:phone_uuid:%s",msg.phone))
    if not uuid or uuid == "" then
        return enum.ERROR_LOGIN_NO_BINDING
        -- uuid = gen_uuid(phone)
        -- reddb:set(string.format("player:phone_uuid:%s",phone),uuid)
        -- ret,info =  reg_account({
        --     ip = msg.ip,
        --     open_id = uuid,
        --     nickname = "guest_"..tostring(math.random(20003,999999)),
        --     icon = math.random(1,1000),
        --     sex = math.random(1,2),
        --     package_name = msg.package_name,
        --     phone = msg.phone,
        --     phone_type = msg.phone_type,
        --     version = msg.version,
        --     promoter = (msg.promoter and msg.promoter ~= 0) and msg.promoter or nil,
        -- })
        -- if ret ~= enum.ERROR_NONE then
        --     return ret
        -- end
    else
        local guid = reddb:get("player:account:"..tostring(uuid))
        guid = tonumber(guid)
        local player = player_data[guid]
        if player and player.status == 0 then
            return enum.ERROR_PLAYER_IS_LOCKED
        end

        local ip = msg.ip 
        if ip then
            reddb:hset(string.format("player:info:%s",guid),"login_ip",ip)
            if not verify.check_ip(ip,guid) then
                return enum.LOGIN_RESULT_ACCOUNT_IP_LIMIT
            end
        end

        local imei = msg.imei
        if not verify.check_imei(imei,guid) then
            return enum.LOGIN_RESULT_ACCOUNT_IMEI_LIMIT 
        end
      
        reddb:hset(string.format("player:info:%s",guid),"version",msg.version)
        
        info = {
            guid = player.guid,
            account = player.open_id,
            nickname = player.nickname or ("guest_"..tostring(guid)),
            open_id = player.open_id,
            sex = player.sex or 1,
            icon = player.icon or default_open_id_icon,
            version = player.version,
            login_ip = ip or player.login_ip,
            phone = player.phone or "",
            level = player.level,
            imei = player.imei or "",
            is_guest = true,
            login_time = os.time(),
            package_name = player.package_name,
            phone_type = player.phone_type,
            role = player.role,
            ip = ip or player.login_ip,
            promoter = player.promoter,
            channel_id = player.channel_id,
            vip = player.vip,
        }
    end

	return enum.LOGIN_RESULT_SUCCESS,info
end

local function h5_login(msg)
    if not runtime_conf.global.h5_login then
        return enum.LOGIN_RESULT_ACCOUNT_DISABLED
    end

    local guid = reddb:get("player:account:"..tostring(msg.open_id))
    if not guid then
        return reg_account({
            open_id = msg.open_id,
            version = msg.version,
            phone_type = msg.phone_type,
            package_name = msg.package_name,
            ip = msg.ip,
            imei = msg.imei,
            sex = msg.sex or false,
            promoter = msg.promoter,
            channel_id = msg.channel_id,
        })
    end

    guid = tonumber(guid)

    local player = player_data[guid]

    local ip = msg.ip
    if ip then
        reddb:hset(string.format("player:info:%s",guid),"login_ip",ip)
    end

    reddb:hset(string.format("player:info:%s",guid),"version",msg.version)
    
    local info = {
        guid = player.guid,
        account = player.open_id,
        nickname = player.nickname or ("guest_"..tostring(guid)),
        open_id = player.open_id,
        sex = player.sex or 1,
        icon = player.icon or default_open_id_icon,
        version = player.version,
        login_ip = msg.ip or player.login_ip,
        phone = player.phone or "",
        level = player.level,
        imei = player.imei or "",
        is_guest = true,
        login_time = os.time(),
        package_name = player.package_name,
        phone_type = player.phone_type,
        role = player.role,
        ip = msg.ip or player.login_ip,
        promoter = player.promoter,
        channel_id = player.channel_id,
        vip = player.vip,
    }

    log.dump(player)

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function account_login(msg)
    local imei = msg.imei
    local error_counts = 0
    if imei and imei ~= "" then
        error_counts = imei_error_count[imei]
        if error_counts then 
            if tonumber(error_counts) > verify.imeierrorlimit then
                log.error("account_login imei_error_count imei:" .. tostring(imei))
                return enum.LOGIN_RESULT_ACCOUNT_IMEI_LIMIT
            end
        end
    end
    

    local guid
    local has = reddb:exists("player:info:"..tostring(msg.account))
    if has then
        guid = tonumber(msg.account)
    else
        local open_id = reddb:get(string.format("player:phone_uuid:%s",msg.account))
        if not open_id or open_id == "" then
            verify.check_imei_error(imei)
            return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
        end
        local uuid = reddb:get(string.format("player:account:%s",open_id))
        if not uuid or uuid == "" then
            verify.check_imei_error(imei)
            return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
        end
        guid = tonumber(uuid)
    end
    
    local player = player_data[guid]
    if player and player.status == 0 then
        return enum.ERROR_PLAYER_IS_LOCKED
    end

    if verify.check_account_lock_imei(imei,guid) then
        return enum.LOGIN_RESULT_ACCOUNT_PASSWOLD_ERRPR_LIMIT
    end

    local password = msg.password
    local rdpassword = reddb:get(string.format("player:password:%d",guid))
    if not rdpassword or rdpassword == "" then
        if not global_conf.use_default_password then
            verify.check_imei_error(imei)
            return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
        end
        
        local strguid = tostring(math.floor(guid))
        rdpassword = string.sub(strguid,-6)
    end
   

    if password ~= rdpassword then
        verify.check_imei_error(imei)
        local remain_error_counts =  verify.check_password_error(imei,guid)
        return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR ,{ ps_error_counts = remain_error_counts }
    end
    log.dump(msg)
    local ip = msg.ip
    if ip then
        reddb:hset(string.format("player:info:%s",guid),"login_ip",ip)
        if not verify.check_ip(ip,guid) then
            return enum.LOGIN_RESULT_ACCOUNT_IP_LIMIT
        end
    end
   
    if not verify.check_imei(imei,guid) then
        return enum.LOGIN_RESULT_ACCOUNT_IMEI_LIMIT 
    end

    if error_counts  then
        if tonumber(error_counts) > 0 then
            verify.remove_imei_error(imei)
        end        
    end
    
    reddb:hset(string.format("player:info:%s",guid),"version",msg.version)
    
    local info = {
        guid = player.guid,
        account = player.open_id,
        nickname = player.nickname or ("guest_"..tostring(guid)),
        open_id = player.open_id,
        sex = player.sex or 1,
        icon = player.icon or default_open_id_icon,
        version = player.version,
        login_ip = ip or player.login_ip,
        phone = player.phone or "",
        level = player.level,
        imei = player.imei or "",
        is_guest = true,
        login_time = os.time(),
        package_name = player.package_name,
        phone_type = player.phone_type,
        role = player.role,
        ip = ip or player.login_ip,
        promoter = player.promoter,
        channel_id = player.channel_id,
        vip = player.vip,
    }

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function is_valid_str(v)
    return v and type(v) == "string" and v ~= ""
end

function on_cl_login(msg,gate)
    local account = is_valid_str(msg.account) and msg.account or msg.open_id
    log.dump(msg)
    local ret,info

    if is_valid_str(msg.open_id)then
        if msg.phone_type == "H5" then
            ret,info = h5_login(msg)
        else
            ret,info = open_id_login(msg)
        end
    elseif is_valid_str(msg.phone) and is_valid_str(msg.sms_verify_no) then
        ret,info = sms_login(msg)
    elseif is_valid_str(msg.password) and is_valid_str(msg.account) then
        ret,info = account_login(msg)
    end

    log.dump(info)

    if ret ~= enum.LOGIN_RESULT_SUCCESS then
        return {
            result = ret,
            ps_error_counts = info and  info.ps_error_counts
        }
    end

    info = clone(info)

    local guid = info.guid

    -- 重连判断
    --清空online信息，重接最新数据
    onlineguid[guid] = nil

    local ok,result,reconnect,game_id = channel.pcall("queue.?","lua","Login",guid,gate)
    if not ok then
        return {
            result = enum.ERROR_INTERNAL_UNKOWN
        }
    end

    if result == enum.LOGIN_RESULT_MAINTAIN and not reconnect and not is_player_vip(info) then
        return {
            result = enum.LOGIN_RESULT_MAINTAIN
        }
    end

    if reconnect then
        info.result = enum.LOGIN_RESULT_SUCCESS
        info.reconnect = 1
        log.dump(info)

        log.info("on_cl_login reconnect,guid=%s,account=%s,gameid=%s,gate_id = %s",
            guid,account, game_id, gate)
        return info
    end

    channel.publish("db.?","msg","LD_LogLogin",{
        guid = guid,
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
    
    log.dump(gate)
    reddb:sadd("player:online:all",guid)

    log.info("on_cl_login,guid=%s,account=%s,gameid=%d", guid,account, game_id)

    info.result = enum.LOGIN_RESULT_SUCCESS

    onlineguid[guid] = nil
 
    return info
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

    -- 存入redis
    reddb:hset("player:online:guid"..tostring(info.guid),"gate",gate)

    local reconnect,gameid = channel.pcall("queue.?","lua","Login",guid,gate)

    info.ret = enum.LOGIN_RESULT_SUCCESS
    info.reconnect = reconnect and 1 or 0

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

function on_cs_request_sms_verify_code(msg,session_id)
    if not session_id then
        return enum.LOGIN_RESULT_SMS_FAILED
    end

    local phone_num = msg.phone_number
    log.info( "RequestSms session [%s] =================", session_id )
    if not phone_num then
        log.error( "RequestSms session [%s] =================tel not find", session_id)
        return enum.LOGIN_RESULT_TEL_ERR
    end

    local verify_code = reddb:get(string.format("sms:verify_code:phone:%s",phone_num))
    if verify_code and verify_code ~= "" then
        local ttl = reddb:ttl(string.format("sms:verify_code:phone:%s",phone_num))
        ttl = tonumber(ttl)
        return enum.LOGIN_RESULT_SMS_REPEATED,ttl
    end

    log.info( "RequestSms =================tel[%s] platform_id[%s]",  phone_num, msg.platform_id)
    local phone_num_len = string.len(phone_num)
    if phone_num_len < 7 or phone_num_len > 18 then
        return enum.LOGIN_RESULT_TEL_LEN_ERR
    end

    local prefix = string.sub(phone_num,1, 3)
    -- if prefix == "170" or prefix == "171" then
    --     return enum.LOGIN_RESULT_TEL_ERR
    -- end

    if prefix == "999" then
        local expire = math.floor(global_conf.sms_expire_time or 60)
        local code =  string.sub(phone_num,phone_num_len - 4 + 1)
        local rkey = string.format("sms:verify_code:phone:%s",phone_num)
        reddb:set(rkey,code)
        reddb:expire(rkey,expire or 60)
        return enum.LOGIN_RESULT_SUCCESS,expire
    end

    if not  string.match(phone_num,"^%d+$") then
        log.info("phone number %s is invalid.",phone_num)
        return enum.LOGIN_RESULT_TEL_ERR
    end

    local expire = math.floor(global_conf.sms_expire_time or 60)
    local code = string.format("%4d",math.random(4001,9999))
    local rkey = string.format("sms:verify_code:phone:%s",phone_num)
    reddb:set(rkey,code)
    reddb:expire(rkey,expire)
    local reqid = channel.call("broker.?","msg","SB_PostSms",phone_num,string.format("【友愉互动】您的验证码为%s, 请在%s分钟内验证完毕.",code,math.floor(expire / 60)))
    if not reqid then
        return enum.ERROR_REQUEST_SMS_FAILED
    end
    return enum.ERROR_NONE,expire
end

function on_cs_chat_world(msg)  
    channel.publish("gate.*","msg","CS_ChatWorld",msg)
end

