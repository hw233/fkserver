local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local redisopt = require "redisopt"
local channel = require "channel"
local onlineguid = require "netguidopt"
local skynet = require "skynetproto"
local log = require "log"
local base_players = require "game.lobby.base_players"
local enum = require "pb_enums"
local util = require "util"
local player_money = require "game.lobby.player_money"
local runtime_conf = require "game.runtime_conf"
local g_common = require "common"
local game_util = require "game.util"
local spinlock = require "spinlock"

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
        local p = base_players[guid]
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

    local result
    result,guid = spinlock("guid:spinlock",function()
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
        imei = "",
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

    reddb:hmset("player:info:"..tostring(guid),info)
    reddb:set("player:account:"..tostring(msg.open_id),guid)
    
    channel.publish("db.?","msg","LD_RegAccount",info)

    -- -- 注册时加默认房卡
    local register_money = global_conf.register_money
    if register_money and register_money > 0  then
        local player = base_players[guid]
        player:incr_money({
            money_id = 0,
            money = register_money,
        },enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)
        game_util.log_statistics_money(0,register_money,enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)
    end

    player_money[guid] = nil

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function open_id_login(msg)
    log.dump(msg)
    default_open_id_icon = default_open_id_icon or global_conf.default_openid_icon

    local guid = reddb:get("player:account:"..tostring(msg.open_id))
    guid = tonumber(guid)
    if not guid then
        return enum.LOGIN_RESULT_ACCOUNT_NOT_EXISTS
    end

    local player = base_players[guid]
    if player and player.status == 0 then
        return enum.ERROR_PLAYER_IS_LOCKED
    end

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

    base_players[guid] = nil

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
    })
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
        local player = base_players[guid]
        if player and player.status == 0 then
            return enum.ERROR_PLAYER_IS_LOCKED
        end

        local ip = msg.ip 
        if ip then
            reddb:hset(string.format("player:info:%s",guid),"login_ip",ip)
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

        base_players[guid] = nil
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
            sex = msg.sex or false,
            promoter = msg.promoter,
            channel_id = msg.channel_id,
        })
    end

    guid = tonumber(guid)

    local player = base_players[guid]

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

    base_players[guid] = nil

    log.dump(player)

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function account_login(msg)
    local guid
    local has = reddb:exists("player:info:"..tostring(msg.account))
    if has then
        guid = tonumber(msg.account)
    else
        local open_id = reddb:get(string.format("player:phone_uuid:%s",msg.account))
        if not open_id or open_id == "" then
            return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
        end
        local uuid = reddb:get(string.format("player:account:%s",open_id))
        if not uuid or uuid == "" then
            return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
        end
        guid = tonumber(uuid)
    end

    local player = base_players[guid]
    if player and player.status == 0 then
        return enum.ERROR_PLAYER_IS_LOCKED
    end

    local password = msg.password
    local rdpassword = reddb:get(string.format("player:password:%d",guid))
    if not rdpassword or rdpassword == "" then
        if not global_conf.use_default_password then
            return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
        end
        
        local strguid = tostring(math.floor(guid))
        rdpassword = string.sub(strguid,-6)
    end

    if password ~= rdpassword then
        return enum.LOGIN_RESULT_ACCOUNT_PASSWORD_ERR
    end

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

    base_players[guid] = nil

    return enum.LOGIN_RESULT_SUCCESS,info
end

local function is_valid_str(v)
    return v and type(v) == "string" and v ~= ""
end

local function on_cl_login(msg,gate)
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
        }
    end

    info = clone(info)

    local guid = info.guid

    -- 重连判断
    --清空online信息，重接最新数据
    onlineguid[guid] = nil
    
    local onlineinfo = onlineguid[guid]

    local old_gate = onlineinfo and onlineinfo.gate
    if old_gate and old_gate ~= gate then
        channel.call("gate."..tostring(old_gate),"lua","kickout",guid)
    end

    local game_id = tonumber(onlineinfo.server)
    local first_game_type = tonumber(onlineinfo.first_game_type)
    if game_id  and tonumber(first_game_type) ~= 1 then
        log.info("player[%s] reconnect game_id:%s,gate_id = %s", guid, game_id, gate)
        info.result = enum.LOGIN_RESULT_SUCCESS
        
        reddb:hset("player:online:guid:"..tostring(guid),"gate",gate)

        local _,reconnect = channel.pcall("queue.?","lua","C",guid,"game."..tostring(game_id),"msg","LS_LoginNotify",guid,true,gate)
        if reconnect then
            info.reconnect = 1
            log.dump(info)

            log.info("on_cl_login reconnect,guid=%s,account=%s,gameid=%s,gate_id = %s",
                guid,account, game_id, gate)
            return info,game_id
        end
    end

    if g_common.is_in_maintain() and not is_player_vip(info) then
        return {
            result = enum.LOGIN_RESULT_MAINTAIN
        }
    end

    -- 找一个默认大厅服务器
    game_id = g_common.lobby_id(guid)
    if not game_id then
        log.warning("no default lobby")
        return {
            result = enum.LOGIN_RESULT_NO_DEFAULT_LOBBY,
        }
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
    -- 存入redis
    reddb:hset("player:online:guid:"..tostring(guid),"gate",gate)

    reddb:sadd("player:online:all",guid)

    channel.pcall("queue.?","lua","C",guid,"game."..tostring(game_id),"msg","LS_LoginNotify",guid,false,gate)

    log.info("on_cl_login,guid=%s,account=%s,gameid=%d", guid,account, game_id)

    info.result = enum.LOGIN_RESULT_SUCCESS

    onlineguid[guid] = nil
 
    return info,game_id
end

local msgopt = require "msgopt"

msgopt.CL_Login = on_cl_login