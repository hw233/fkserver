
local redisdb = require "redisopt"
local netopt = require "netopt"
local json = require "cjson"
local onlineguid = require "netguidopt"
local log = require "log"
local channel = require "channel"
local pb = require "pb"

require "login.msg.runtime"

local reddb = redisdb[0]


function on_dl_verify_account_result(fd,msg) 
    local verify_result = msg.verify_account_result
    if verify_result.ret == LOGIN_RESULT_SUCCESS then
		-- 2017-04-18 by rocky add 登录维护开关	
		local status = msg.maintain_switch
		if status == 1 and verify_result.vip ~= 100 then --vip不等于100的玩家在游戏维护时不能进入
			log.warning("=======maintain login==============status = [%d]", status)
            channel.publish("gate."..tostring(msg.gateid),"LC_Login",{
                result = LOGIN_RESULT_MAINTAIN,
            })
			return
        end
        
        local account_ = msg.account
        local account_key = get_account_key(account_,msg.platform_id)
        local password = msg.password
        local gate_id = msg.gate_id
        local guid = msg.guid
        local session_id = msg.session_id

        --  在线信息
        reddb.set(string.format("playerPhoneType_%d",verify_result.guid),verify_result.phonetype)
        local account_info = reddb.hget("player:login:info",account_key)
        if not account_info then
            log.error("player[%s] not find", account_key)
            return
        end
        local info = json.decode(account_info)

        -- 设置gateid 解决串号问题， 上面 为什么去屏蔽 原因不得而知
        info.session_id = gate_id
        info.guid = verify_result.guid
        info.nickname = verify_result.nickname
        info.vip = verify_result.vip
        info.login_time = verify_result.login_time
        info.logout_time = verify_result.logout_time
        info.alipay_account = verify_result.alipay_account
        info.change_alipay_num = verify_result.change_alipay_num
        if verify_result.no_bank_password == 0 then
            info.h_bank_password = true
        end

        if verify_result.is_guest then
            info.is_guest = verify_result.is_guest
        end

        info.risk = verify_result.risk
        info.create_channel_id = verify_result.channel_id
        info.enable_transfer = verify_result.enable_transfer
        info.inviter_guid = verify_result.inviter_guid
        info.invite_code = verify_result.invite_code
        info.bank_password = verify_result.bank_password
        info.using_login_validatebox = verify_result.using_login_validatebox
        info.bank_card_name = verify_result.bank_card_name
        info.bank_card_num = verify_result.bank_card_num
        info.change_bankcard_num = verify_result.change_bankcard_num
        info.bank_name = verify_result.bank_name
        info.bank_province = verify_result.bank_province
        info.bank_city = verify_result.bank_city
        info.bank_branch = verify_result.bank_branch
        -- 重连判断
        local game_id = reddb.hget("player_online_gameid",info.guid)
        if game_id then
            log.info("player[%d] reconnect game_id:%d ,session_id = %d ,gate_id = %d", info.guid, game_id, info.session_id, info.gate_id)
            local game_server_info = netopt.byid(SessionGate,game_id)
            if game_server_info then
                local player_login_info = deepcopy(info)
                player_login_info.is_reconnect = true
                channel.publish("game."..tostring(game_id),"LS_LoginNotify",player_login_info)
                log.info("login step reconnect login->LS_LoginNotify,account=%s,gameid=%d,session_id = %d,gate_id = %d", 
                    account_, game_id, info.session_id, info.gate_id)
                return
            end
        end

        -- 找一个默认大厅服务器
        game_id = find_a_default_lobby()
        if not game_id then
            channel.publish("gate."..tostring(gate_id),"LC_Login",{
                result = LOGIN_RESULT_NO_DEFAULT_LOBBY,
            })
            
            reddb.hdel("player:login:info",account_key)
            reddb.hdel("player:login:info:guid guid",info.guid)
            log.warning("no default lobby")
            return
        end

        -- 存入redis
        reddb.hset("player_online_gameid",guid,game_id)
        reddb.hset("player_session_gate",string.format("%d@%d",session_id,gate_id),account)
        local redis_player_info = json.encode(info)
        reddb.hset("player:login:info",account_key,redis_player_info)
        reddb.hset("player:login:info:guid",guid,redis_player_info)

        channel.publish("game."..tostring(game_id),"LS_LoginNotify",{
            player_login_info = info,
            password = password,
        })

        log.info("login step login->LS_LoginNotify,account=%s,gameid=%d", account_, game_id)
    else
        log.error("login step login->verify_account error:%d", verify_result.ret)
        
        local account = msg.account
        local account_key = get_account_key(account,msg.platform_id)
        local gate_id = msg.gate_id
        local guid = msg.guid
        local session_id = msg.session_id
        local ret = verify_result.ret

        -- 登陆请求状态判断
        local red_res = reddb.hget("player:login:info",account_key)
        if red_res then 
            local other = json.decode(red_res)
            local other_account_key = get_account_key(other.account,other.platform_id)
            reddb.hdel("player:login:info",other_account_key)
            reddb.hdel("player:login:info:guid",other.guid)
        end

        channel.publish("gate."..tostring(gate_id),"LC_Login",{
            result = ret,
        })

        log.info("login step login->LC_Login,account=%s", account)
	end
end

function on_dl_reg_account(msg)
    if msg.ret ~= LOGIN_RESULT_SUCCESS then
        return {
            result = msg.ret,
            account = msg.account,
            is_guest = msg.is_guest,
        }
    end

    local info = {}
    info.account = msg.account
    info.guid = msg.guid
    info.nickname = msg.nickname
    info.deprecated_imei = msg.deprecated_imei
    info.platform_id = msg.platform_id
    if msg.is_guest then
        info.is_guest = true
    end
    info.phone = msg.phone
    info.phone_type = msg.phone_type
    info.version = msg.version
    info.channel_id = msg.channel_id
    info.package_name = msg.package_name
    info.imei = msg.imei
    info.ip = msg.ip
    info.ip_area = msg.ip_area
    info.using_login_validatebox = msg.using_login_validatebox
    
    log.info("[%s] reg account, guid = %d ,platform_id = %s", info.account, info.guid,info.platform_id)

    -- 找一个默认大厅服务器
    local gameid = find_a_default_lobby()
    if not gameid then
        reddb.hdel("player:login:info",account_key)
        reddb.hdel("player:login:info:guid",info.guid)
        log.warning("no default lobby")
        return {
            result = LOGIN_RESULT_NO_DEFAULT_LOBBY
        }
    end

    -- 存入redis
    reddb.hset("player:online:"..tostsring(info.guid),gameid)
    reddb.hset("player_session_gate",string.format("%d@%d",info.session_id,info.gate_id),info.account)
    reddb.hset("player:login:info",account_key,json.encode(info))
    reddb.hset("player:login:info:guid",info.guid,json.encode(info))

    return channel.call("game."..tostring(gameid),"msg","LS_LoginNotify",{
        player_login_info = info,
        password = msg.password,
    })
end

function on_dl_reg_account2(fd,msg)
    local account_result = msg.guest_account_result
    if account_result.ret ~= LOGIN_RESULT_SUCCESS then
        log.error("login step login->reg_account error:%d", account_result.ret)

        sendpb2guids(msg.session_id,msg.gate_id,"LC_Login",{
            result = account_result.ret,
            account = account_result.account,
            is_guest = account_result.is_guest,
        })
        return
    end

    -- 2017-04-18 by rocky add 登录维护开关	
    local status = maintain_switch
    if status == 1 and account_result.vip ~= 100 then --vip不等于100的玩家在游戏维护时不能登录
        log.warning("=======maintain login==============status = [%d]", status)
        sendpb2guid(msg.session_id,msg.gate_id,"LC_Login",{
            result = LOGIN_RESULT_MAINTAIN,
        })
        return
    end

    local sessionid = msg.session_id
    local gateid = msg.gate_id
    local phone_ = msg.phone
    local phone_type_ = msg.phone_type
    local version_ = msg.version
    local channel_id_ = msg.channel_id
    local package_name_ = msg.package_name
    local imei_ = msg.imei
    local ip_ = msg.ip
    local ip_area_ = msg.ip_area
    local bank_password = msg.bank_password
    local platform_id = msg.platform_id

    --  在线信息
    reddb.set(string.format("playerPhoneType_%d",account_result.guid),msg.phone)
    local account_key = get_account_key(account_result.account,platform_id)
    
    -- 登陆请求状态判断
    local info = get_player_login_info(account_key)

    if not info then return end

    -- 正常注册登陆
    info.session_id = sessionid
    info.gate_id = gateid
    info.account = account_result.account
    info.guid = account_result.guid
    info.nickname = account_result.nickname
    info.vip = account_result.vip
    info.login_time = account_result.login_time
    info.logout_time = account_result.logout_time
    info.alipay_account = account_result.alipay_account
    info.alipay_name = account_result.alipay_name
    info.change_alipay_num = account_result.change_alipay_num
    if account_result.no_bank_password == 0 then
        info.h_bank_password = true
    end

    if  account_result.is_guest then
        info.is_guest = true
    end

    info.risk = account_result.risk
    info.create_channel_id = account_result.channel_id
    info.enable_transfer = account_result.enable_transfer

    info.phone = phone_
    info.phone_type = phone_type_
    info.version = version_
    info.channel_id = channel_id_
    info.package_name = package_name_
    info.imei = imei_
    info.ip = ip_
    info.ip_area = ip_area_
    info.is_first = account_result.is_first
    info.bank_password = bank_password
    info.platform_id = platform_id
    info.using_login_validatebox = account_result.using_login_validatebox
    info.bank_card_name = account_result.bank_card_name
    info.bank_card_num = account_result.bank_card_num
    info.change_bankcard_num = account_result.change_bankcard_num
    info.bank_name = account_result.bank_name
    info.bank_province = account_result.bank_province
    info.bank_city = account_result.bank_city
    info.bank_branch = account_result.bank_branch

    local password = account_result.password

    --  重连判断
    local game_id = reddb.hget("player_online_gameid",info.guid)
    if game_id then
        log.info("player[%d] reconnect game_id:%d ,session_id = %d ,gate_id = %d", info.guid, game_id, info.session_id, info.gate_id)

        local game_server_info = netopt.byid(SessionGate,game_id)
        if game_server_info then
            local account_ = account_result.account()

            -- 存入redis
            reddb.hset("player_online_gameid",info.guid,game_id)
            reddb.hset("player_session_gate",string.format("%d@%d",info.session_id,info.gate_id),account)
            reddb.hset("player:login:info",account_key,json.encode(info))
            reddb.hset("player:login:info:guid",info.guid,json.encode(info))

            local player_login_info = deepcopy(info)
            player_login_info.is_reconnect = true

            channel.publish("game."..tostring(game_id),"LS_LoginNotify",{
                player_login_info = player_login_info,
                password = password,
            })

            log.info("login step reconnect login->LS_LoginNotify,account=%s,gameid=%d,session_id = %d,gate_id = %d", 
                account_, game_id, info.session_id, info.gate_id)
            return
        end
    end

    log.info("[%s] reg account, guid = %d", info.account, info.guid)

    -- 找一个默认大厅服务器
    local gameid = find_a_default_lobby()
    if gameid == 0 then
        local session_id = info.session_id
        local gate_id = info.gate_id
        local is_first = info.is_first

        channel.publish("gate."..tostring(gate_id),"",{
            result = LOGIN_RESULT_NO_DEFAULT_LOBBY,
            is_first = is_first,
        })

        reddb.hdel("player:login:info",account_key)
        reddb.hdel("player:login:info:guid",info.guid)
        log.warning("no default lobby")
        return
    end

    -- 存入redis
    reddb.hset("player_online_gameid",info.guid,game_id)
    reddb.hset("player_session_gate",string.format("%d@%d",info.session_id,info.gate_id),info.account)
    reddb.hset("player:login:info",account_key,json.encode(info))
    reddb.hset("player:login:info:guid",info.guid,json.encode(info))

    channel.publish("game."..tostring(gameid),"LS_LoginNotify",{
        player_login_info = info,
        password = password,
    })

    channel.publish("gate."..tostring(gateid),"LC_Login",{
        result = LOGIN_RESULT_REPEAT_LOGIN,
    })
    
    -- 下面代码无法踢掉玩家，为简单起见，直接提示登录失败
    info.session_id = sessionid
    info.gate_id = gateid
    info.account = account_result.account
    info.guid = account_result.guid
    info.nickname = account_result.nickname
    info.vip = account_result.vip
    info.login_time = account_result.login_time
    info.logout_time = account_result.logout_time
    info.alipay_account = account_result.alipay_account
    info.alipay_name = account_result.alipay_name
    info.change_alipay_num = account_result.change_alipay_num
    if  account_result.no_bank_password == 0 then
        info.h_bank_password = true
    end

    if account_result.is_guest then
        info.is_guest = true
    end

    info.risk = account_result.risk
    info.phone = phone_
    info.phone_type = phone_type_
    info.version = version_
    info.channel_id = channel_id_
    info.package_name = package_name_
    info.imei = imei_
    info.ip = ip_
    info.ip_area = ip_area_
    info.is_first = account_result.is_first
    info.bank_password = bank_password
    info.platform_id = platform_id

    channel.publish("gate."..tostring(gateid),"LG_KickClient",{
        session_id = sessionid,
        reply_account = info.account,
        user_data = 1,
        platform_id = platform_id,
    })

    local c = netopt.byid(SessionGate,gateid)
    if c then
        local  password = account_result.password
        log.info("[%s] reg account, guid = %d", info.account, info.guid)

        -- 找一个默认大厅服务器
        local gameid = find_a_default_lobby()
        if not gameid then
            local session_id = info.session_id
            local gate_id = info.gate_id

            sendpb2guids(session_id,gate_id,"LC_Login",{
                result = LOGIN_RESULT_NO_DEFAULT_LOBBY,
                is_first = info.is_first,
            })
            
            reddb.hdel("player:login:info",account_key)
            reddb.hdel("player:login:info:guid",info.guid)
            log.warning("no default lobby")
            return
        end

        reddb.hset("player_online_gameid",info.guid,gameid)
        reddb.hset("player_session_gate",string.format("%d@%d",info.session_id,info.gate_id),info.account)
        reddb.hset("player:login:info",account_key,json.encode(info))
        reddb.hset("player:login:info:guid",info.guid,json.encode(info))
        channel.publish("game."..tostring(gameid),"LS_LoginNotify",{
            player_login_info = info,
            password = password,
        })
    else
        -- 先缓存数据
        reddb.hset("player:login:info:temp",account_key,json.encode(info))
    end
end

function on_dl_NewNotice(fd,msg) 
    local asyncid = msg.asyncid
	if msg.ret == 100 then --成功
        if msg.type == 1 then --消息
            local gateid,account = player_is_online(msg.guid)
            if gateid == -1 then
                -- 玩家不在线
                if not asyncid then
                    channel.publish("gm."..tostring(msg.retid),"LW_GMMessage",{
                        result = GMmessageRetCode_MsgPlayerOffline,
                        asyncid = asyncid,
                    })
                end
                return
            end

            channel.publish("gate."..tostring(gateid),"LG_NewNotice",{
                id = msg.id,
                gateid = gateid,
                start_time = msg.start_time,
                end_time = end_time,
                msg_type = msg.type,
                is_read = 1,
                content = msg.content,
                retid = msg.retid,
                guid = msg.guid,
                asyncid = asyncid,
            })
		elseif msg.type == 2 then --公告
            channel.publish("gate.*","LS_NewNotice",{
                id = msg.id,
                start_time = msg.start_time,
                end_time = end_time,
                msg_type = msg.type,
                is_read = 1,
                content = msg.content,
                retid = msg.retid,
                asyncid = asyncid,
                platforms = msg.platforms,
            })

            write_gm_msg(msg.retid,GMmessageRetCode_Success,asyncid)
		elseif msg.type == 3 then  --跑马灯
            channel.publish("gate.*","LS_NewNotice",{
                id = msg.id,
                start_time = msg.start_time,
                end_time = end_time,
                msg_type = msg.type,
                number = msg.number,
                interval_time = msg.interval_time,
                content = msg.content,
                retid = msg.retid,
                asyncid = asyncid,
                platforms = msg.platforms,
            })

            write_gm_msg(msg.retid,GMmessageRetCode_Success,asyncid)
        end
	else --失败
        log.info("on_dl_NewNotice faild")
        write_gm_msg(msg.retid,GMmessageRetCode_MsgDBFaild,asyncid)
    end
end

function on_cc_ChangMoney(fd,msg) 
    on_db_requesst(msg)
end

function on_dl_doSql(fd,msg) 
    to_do_sql(msg)
end

function on_dl_DelMessage(fd,msg) 
    local asyncid = msg.asyncid
	if msg.ret == 100 then --成功
		log.info("on_dl_DelMessage success")
        if msg.msg_type == 1 then --消息
            local gateid,_ = player_is_online(msg.guid)
            if gateid == -1 then
                -- 玩家不在线
                write_gm_msg(msg.retid,GMmessageRetCode_Success,asyncid)
                return
            end

            channel.publish("gate."..tostring(gateid),"LG_DelNotice",{
                guid = msg.guid,
                msg_type = msg.msg_type,
                msg_id = msg.msg_id,
                retid = msg.retid,
                asyncid = asyncid,
            })
		elseif msg.msg_type == 2 or msg.msg_type == 3 then   --公告
            channel.publish("gate.*","LS_DelMessage",{
                msg_type = msg.msg_type,
                msg_id = msg.msg_id,
            })
            write_gm_msg(msg.retid,GMmessageRetCode_Success,asyncid)
        end
	else --失败
        log.info("on_dl_DelMessage faild")
        write_gm_msg(msg.retid,GMmessageRetCode_DelMsgDBError,asyncid)
    end
end

function on_dl_AlipayEdit(fd,msg) 
    if msg.editnum > 0 then
        write_gm_msg(msg.retid,GMmessageRetCode_Success,asyncid)
    else
        log.info("on_dl_DelMessage faild")
        write_gm_msg(msg.retid,GMmessageRetCode_EditAliPayFail,asyncid)
    end
end


function on_wl_request_GMMessage(fd,msg) 
	if msg.gmcommand == "MSG" then --公告 消息 //反馈更新
        log.info(msg.data)
        local doc = json.decode(msg.data)
        if not doc then
            return
        end
        
        if not json_has_member(doc,{
            type = "number",
            content = "string",
            start_time = "string",
            end_time = "string",
        }) then
            return
        end

        local check_msg_type = {
            [1] = function(doc) return not doc.number or not doc.interval_time end,
            [2] = function(doc) return not doc.name or not doc.author or not doc.guid end,
            [3] = function(doc) return not doc.name or not doc.author end,
        }

        local type = doc.type
        local check_f = check_msg_type[type]
        if not check_f then
            log.error("on_wl_request_GMMessage  type not find : %d", type)
            return
        end
        
        if not check_f(doc) then return end

        local request = {}
        if type == 1 then
            request.guid = msg.guid
        elseif type == 2 then
            request.number = doc.number
            request.interval_time = doc.interval_time
        elseif type == 3 then
            request.name = doc.name
            request.author = doc.author
        end

		request.type = doc.type
		request.content = doc.content
		request.start_time = doc.start_time
		request.end_time = doc.end_time
        request.retid = get_id
        channel.publish("db.?","LD_NewNotice",request)
	end
end

function on_dl_recharge(fd,msg) 
	log.info("LoginDBSession::on_dl_recharge guid[%d] retcode[%d]", msg.guid, msg.retcode)
    sendpb2id(SessionWeb,msg.retid,"FW_Result",{
        result = msg.retcode,
        asyncid = msg.asyncid,
    })

	local changemoney = msg.changemoney
	local newbankmoney = msg.bank
    local guid = msg.guid
    local gateid,_ = player_is_online(msg.guid)

    if gateid == -1 then
        -- 玩家不在线
        log.info("LoginDBSession::on_dl_recharge guid[%d] not online", guid)
        return
    end

    if changemoney == 0 then
        -- 金钱无变化  不需要通知
        log.info("LoginDBSession::on_dl_recharge guid[%d] changemoney == 0", guid)
        return
    end

    channel.publish("gate."..tostring(gateid),"",{
        guid = guid,
        bankmoney = newbankmoney,
        changemoney = changemoney,
    })
end

function on_dl_BankcardEdit(fd,msg) 
	if msg.editnum > 0 then
		log.info("on_dl_BankcardEdit ok.guid[%d],retid[%d] editnum[%d]", msg.guid, msg.retid, msg.editnum)
		write_gm_msg(msg.retid, GMmessageRetCode_Success,msg.asyncid )
	else
        log.info("on_dl_BankcardEdit faild,guid[%d]",msg.guid)
        write_gm_msg(msg.retid, GMmessageRetCode_EditAliPayFail,msg.asyncid )
    end
end

function on_dl_cashfalseinfo(fd,msg) 
    local nmsg = {
        info = msg.info,
        web_id = msg.web_id,
    }
    -- 判断是否在线
    local gateid,account = player_is_online(nmsg.info.guid)
    if gateid == -1 then
        -- 玩家不在线
        channel.publish("db.?","LD_CashDeal",{
            web_id = msg.web_id,
            info = msg.info,
        })
        return
    end
    
    -- 判断用户所在服务器ID
    -- 在线信息
    local game_id = reddb.hget("player_online_gameid",msg.info.guid) 
    if game_id then
        channel.publish("game."..tostring(game_id),"LS_CashDeal",{
            web_id = msg.web_id,
            info = msg.info,
            server_id = tonumber(game_id),
            login_id = msg.login_id,
        })
    else
        -- 玩家不在线
        channel.publish("db.?","LD_CashDeal",{
            web_id = msg.web_id,
            info = msg.info,
        })
    end
end

function on_dl_cashreply(fd,msg)
    channel.publish("gm."..tostring(msg.web_id),"LW_CashFalse",{
        result = msg.result,
    })
end

function on_dl_rechargeinfo(fd,msg) 
    channel.publish("gate."..tostring(msg.gate_id),"LG_PhoneQuery",{
        phone = msg.phone,
        ret = msg.ret,
        gate_session_id = msg.gate_session_id,
        guid = msg.guid,
        platform_id = msg.platform_id,
    })
end

function on_dl_reg_phone_query(fd,msg) 
    channel.publish("gate."..tostring(msg.gate_id),"LG_PhoneQuery",{
        phone = msg.phone,
        ret = msg.ret,
        gate_session_id = msg.gate_session_id,
        guid = msg.guid,
        platform_id = msg.platform_id
    })
end

function on_dl_server_config(fd,msg) 
    channel.publish("gate.*",msg)
end

function on_dl_server_config_mgr(fd,msg) 
    channel.publish("gate."..tostring(msg.gid),"LG_DBGameConfigMgr",{
        pb_cfg_mgr = msg.pb_cfg_mgr,
    })
end

function on_dl_get_inviter_info(fd,msg) 
    sendpb2guids(msg.guid_self,msg.gate_id,msg)
end

function on_DL_LuaCmdPlayerResult(fd,msg) 
    channel.publish("gm."..tostring(msg.web_id),"LW_LuaCmdPlayerResult",{
        result = msg.result,
    })
end

function on_DF_ChangMoney(fd,msg) 
    local gateid,account = player_is_online(msg.info.guid)
    if gateid == -1 then
        -- 玩家不在线
        channel.publish("db.?","FD_ChangMoneyDeal",{
            info = msg.info,
            web_id = msg.web_id,
            login_id = msg.login_id,
        })
    else
        channel.publish("gate."..tostring(gateid),"FS_ChangMoneyDeal",{
            info = msg.info,
            web_id = msg.web_id,
            login_id = msg.login_id,
        })
    end
end

function on_DF_Reply(fd,msg) 
	log.info("on_DF_Reply...... web[%d] reply[%d]", msg.web_id, msg.result)
    channel.publish("gm."..tostring(msg.web_id),"FW_Result",{
        result = msg.result,
    })
end

local function notify_player_bank(guid,old_bank,new_bank,opt_type)
    local gateid,account = player_is_online(guid)
    if gateid then
        -- 玩家在线
        channel.publish("gate."..tostring(gateid),"LG_UpdatePlayerBank",{
            guid = guid,
            opt_type = opt_type,
            old_bank = old_bank,
            new_bank = new_bank,
        })
    else
        channel.publish("db.?","SD_LogMoney",{
            guid = guid,
            old_money = 0,
            new_money = 0,
            old_bank = old_bank,
            new_bank = new_bank,
            opt_type = opt_type,
        })

        log.info("on_DF_ChangMoney  %d no online", guid)
    end
end

function on_DL_CashFalseReply(fd,msg) 
	local guid = msg.guid
	local old_bank = msg.old_bank
    local new_bank = msg.new_bank
    
	log.info("on_DF_Reply...... web[%d] reply[%d]", msg.web_id, msg.result)
    channel.publish("gm."..tostring(msg.web_id),"FW_Result",{
        result = msg.result,
    })

	-- 成功就更新在线玩家金币
	if msg.result == 1 then
		notify_player_bank(guid, old_bank, new_bank, LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE)
    end
end

function on_DL_ResetAlipay(fd,msg) 
    local guid = msg.guid
    local gateid,_ = player_is_online(guid)
    if gateid then
        local alipay_name = msg.alipay_name
        local alipay_name_y = msg.alipay_name_y
        local alipay_account = msg.alipay_account
        local alipay_account_y = msg.alipay_account_y
        -- 玩家在线
        local gameid = reddb.hget("player_online_gameid",guid)
        if gameid then
            channel.publish("game."..tostring(gameid),"LS_AlipayEdit",{
                guid = guid,
                alipay_name = alipay_name,
                alipay_name_y = alipay_name_y,
                alipay_account = alipay_account,
                alipay_account_y = alipay_account_y,
            })
        end
    end
end

function on_DL_CreateProxyAccount(fd,msg) 
    if msg.result == 1 then 
        log.info("create proxy account success")
		write_gm_msg(msg.web_id,GMmessageRetCode_Success, msg.asyncid)
    else
        log.info("create proxy account failed")
		write_gm_msg(msg.web_id,GMmessageRetCode_GmCommandError, msg.asyncid)
    end
end

function on_S_ReplayProxyPlatformIds(fd,msg) 
    for _,id in pairs(msg.platform_id) do
        channel.publish("db.?","",{
            plaform_id = id,
            loginid = local_id,
        })
    end
end

function on_S_ReplyProxyInfo(fd,msg) 
    local rep = reddb.hset("platform_proxy_info",msg.pb_platform_proxys.platform_id,json.encode(msg.pb_platform_proxys))
    if rep == 0 or rep == 1 then
        log.info("set proxy info sucess")
    else
        log.error("set proxy info failed")
    end
end

function on_DL_AgentAddPlayerMoney(fd,msg) 
	local guid = msg.player_guid
	local transfer_type = msg.transfer_type
	local old_bank = msg.old_bank
	local new_bank = msg.new_bank

	log.info("on_DL_AgentAddPlayerMoney...... guid[%d] old_bank[%d] new_bank[%d]", msg.player_guid, old_bank, new_bank)

	-- 成功就更新在线玩家金币
	if msg.result == 1 then
		local log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
		if transfer_type == 0 then
			log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
		elseif transfer_type == 1 then
			log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY
		elseif transfer_type == 2 then
			log_money_type = LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY
		elseif transfer_type == 3 then
            log_money_type = LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY
        end
		
		notify_player_bank(guid, old_bank, new_bank, log_money_type)
    end
end

function on_DL_GMChangMoney(fd,msg) 
	local guid = msg.guid
	local old_bank = msg.old_bank
	local new_bank = msg.new_bank
	local type_id = msg.type_id

    channel.publish("gm."..tostring(msg.web_id),"LW_ChangeMoney",{
        result = msg.result,
    })

	-- 成功就更新在线玩家金币
	if msg.result == 1 then
		notify_player_bank(guid, old_bank, new_bank, type_id)
    end
end

function on_DL_ReturnAgentMoney(fd,msg)
	local guid = msg.guid
	local old_bank = msg.old_bank
	local new_bank = msg.new_bank
	local type_id = msg.type_id

    channel.publish("gm."..tostring(msg.web_id),"LW_LuaCmdPlayerResult",{
        result = msg.result,
        guid = guid,
        order_id = msg.order_id,
        cost_money = msg.cost_money,
        acturl_cost_money = msg.acturl_cost_money,
    })

	-- 成功就更新在线玩家金币
	if msg.result == 1 then
		notify_player_bank(guid, old_bank, new_bank, type_id)
    end
end