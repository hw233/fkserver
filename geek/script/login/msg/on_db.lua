
local redisdb = require "redisopt"
local json = require "cjson"
local onlineguid = require "netguidopt"
local log = require "log"
local channel = require "channel"
local pb = require "pb_files"
local serviceconf = require "serviceconf"
local json = require "cjson"
local enum = require "pb_enums"
require "login.msg.runtime"

local reddb = redisdb.default

function on_dl_reg_account2(msg)
    local account_result = msg.guest_account_result
    if account_result.ret ~= enum.LOGIN_RESULT_SUCCESS then
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
    local account = account_result.account

    local info = reddb:hgetall("player:online:guid:"..tostring(account_result.guid))
    -- 登陆请求状态判断
    if not info then
        return
    end

    -- 正常注册登陆
    info.account = account_result.account
    info.guid = account_result.guid
    info.nickname = account_result.nickname
    info.vip = account_result.vip
    info.login_time = account_result.login_time
    info.logout_time = account_result.logout_time
    info.alipay_account = account_result.alipay_account
    info.alipay_name = account_result.alipay_name
    info.change_alipay_num = account_result.change_alipay_num
    info.h_bank_password = account_result.no_bank_password and false or true
    info.is_guest = account_result.is_guest and true or false
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
    local onlineinfo = reddb.hgetall("player:online:guid:"..tostring(info.guid))
    if onlineinfo.server then
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

            channel.publish("game."..tostring(game_id),"msg","LS_LoginNotify",{
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
        local gate_id = info.gate_id
        local is_first = info.is_first

        channel.publish("gate."..tostring(gate_id),"msg","",{
            result = LOGIN_RESULT_NO_DEFAULT_LOBBY,
            is_first = is_first,
        })

        reddb.del("player:login:info:"..account_key)
        reddb.hdel("player:login:info:"..tostring(info.guid))
        log.warning("no default lobby")
        return
    end

    -- 存入redis
    reddb.hset("player:online:guid:"..tostring(info.guid),"server",gameid)
    reddb.hmset("player:login:info:"..account,info)
    reddb.hmset("player:login:info:"..tostring(info.guid),info)

    channel.publish("game."..tostring(gameid),"msg","LS_LoginNotify",{
        player_login_info = info,
        password = password,
    })

    channel.publish("gate."..tostring(gateid),"msg","LC_Login",{
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

    channel.publish("gate."..tostring(gateid),"msg","LG_KickClient",{
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
            
            reddb.del("player:login:info:"..account)
            reddb.del("player:login:info:"..tostring(info.guid))
            log.warning("no default lobby")
            return
        end

        reddb.hset("player:online:guid:"..tostring(info.guid),"server",gameid)
        reddb:hset("player:online:guid:"..tostring(info.guid),"gate",info.gate_id)
        reddb.hset("player:login:info",account_key,json.encode(info))
        reddb.hset("player:login:info:guid",info.guid,json.encode(info))
        channel.publish("game."..tostring(gameid),"msg","LS_LoginNotify",{
            player_login_info = info,
            password = password,
        })
    end
end

function on_dl_NewNotice(msg,session) 
    local asyncid = msg.asyncid
	if msg.ret == 100 then --成功
        if msg.type == 1 then --消息
            local gateid,account = player_is_online(msg.guid)
            if gateid == -1 then
                -- 玩家不在线
                if not asyncid then
                    channel.publish("gm."..tostring(msg.retid),"msg","LW_GMMessage",{
                        result = GMmessageRetCode_MsgPlayerOffline,
                        asyncid = asyncid,
                    })
                end
                return
            end

            channel.publish("gate."..tostring(gateid),"msg","LG_NewNotice",{
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
            channel.publish("gate.*","msg","LS_NewNotice",{
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
            channel.publish("gate.*","msg","LS_NewNotice",{
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

function on_cc_ChangMoney(msg,session)
    on_db_requesst(msg)
end

function on_dl_doSql(msg,session)
    to_do_sql(msg)
end

function on_dl_DelMessage(msg,session)
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

            channel.publish("gate."..tostring(gateid),"msg","LG_DelNotice",{
                guid = msg.guid,
                msg_type = msg.msg_type,
                msg_id = msg.msg_id,
                retid = msg.retid,
                asyncid = asyncid,
            })
		elseif msg.msg_type == 2 or msg.msg_type == 3 then   --公告
            channel.publish("gate.*","msg","LS_DelMessage",{
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

function on_dl_AlipayEdit(msg,session) 
    if msg.editnum > 0 then
        write_gm_msg(msg.retid,GMmessageRetCode_Success,asyncid)
    else
        log.info("on_dl_DelMessage faild")
        write_gm_msg(msg.retid,GMmessageRetCode_EditAliPayFail,asyncid)
    end
end


function on_wl_request_GMMessage(msg,session) 
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
        
        if not check_f(doc) then 
            return 
        end

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
        channel.publish("db.?","msg","LD_NewNotice",request)
	end
end

function on_dl_BankcardEdit(msg) 
	if msg.editnum > 0 then
		log.info("on_dl_BankcardEdit ok.guid[%d],retid[%d] editnum[%d]", msg.guid, msg.retid, msg.editnum)
        return {
            result = GMmessageRetCode_Success,
            asyncid = msg.asyncid,
        }
	else
        log.info("on_dl_BankcardEdit faild,guid[%d]",msg.guid)
        return {
            result = GMmessageRetCode_EditAliPayFail,
            asyncid = msg.asyncid,
        }
    end
end

function on_dl_cashfalseinfo(msg,session) 
    local nmsg = {
        info = msg.info,
        web_id = msg.web_id,
    }
    -- 判断是否在线
    local gateid,account = player_is_online(nmsg.info.guid)
    if gateid == -1 then
        -- 玩家不在线
        channel.publish("db.?","msg","LD_CashDeal",{
            web_id = msg.web_id,
            info = msg.info,
        })
        return
    end
    
    -- 判断用户所在服务器ID
    -- 在线信息
    local game_id = reddb.hget("player_online_gameid",msg.info.guid) 
    if game_id then
        channel.publish("game."..tostring(game_id),"msg","LS_CashDeal",{
            web_id = msg.web_id,
            info = msg.info,
            server_id = tonumber(game_id),
            login_id = msg.login_id,
        })
    else
        -- 玩家不在线
        channel.publish("db.?","msg","LD_CashDeal",{
            web_id = msg.web_id,
            info = msg.info,
        })
    end
end

function on_dl_rechargeinfo(msg) 
    onlineguid.send(msg.guid,"LG_PhoneQuery",{
        phone = msg.phone,
        ret = msg.ret,
        gate_session_id = msg.gate_session_id,
        guid = msg.guid,
        platform_id = msg.platform_id,
    })
end

function on_dl_reg_phone_query(msg)
    onlineguid.send(msg.guid,"LG_PhoneQuery",{
        phone = msg.phone,
        ret = msg.ret,
        gate_session_id = msg.gate_session_id,
        guid = msg.guid,
        platform_id = msg.platform_id,
    })
end

function on_dl_get_inviter_info(msg)
    onlineguid.send(msg.guid_self,msg.gate_id,msg)
end

function on_DL_LuaCmdPlayerResult(msg)
    channel.publish("gm."..tostring(msg.web_id),"msg","LW_LuaCmdPlayerResult",{
        result = msg.result,
    })
end

function on_DF_ChangMoney(msg,session)
    local gateid,account = player_is_online(msg.info.guid)
    if gateid == -1 then
        -- 玩家不在线
        channel.publish("db.?","msg","FD_ChangMoneyDeal",{
            info = msg.info,
            web_id = msg.web_id,
            login_id = msg.login_id,
        })
    else
        channel.publish("gate."..tostring(gateid),"msg","FS_ChangMoneyDeal",{
            info = msg.info,
            web_id = msg.web_id,
            login_id = msg.login_id,
        })
    end
end

function on_DF_Reply(msg,session) 
	log.info("on_DF_Reply...... web[%d] reply[%d]", msg.web_id, msg.result)
    channel.publish("gm."..tostring(msg.web_id),"msg","FW_Result",{
        result = msg.result,
    })
end

local function notify_player_bank(guid,old_bank,new_bank,opt_type)
    local gateid,account = player_is_online(guid)
    if gateid then
        -- 玩家在线
        channel.publish("gate."..tostring(gateid),"msg","LG_UpdatePlayerBank",{
            guid = guid,
            opt_type = opt_type,
            old_bank = old_bank,
            new_bank = new_bank,
        })
    else
        channel.publish("db.?","msg","SD_LogMoney",{
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

function on_DL_CashFalseReply(msg,session) 
	local guid = msg.guid
	local old_bank = msg.old_bank
    local new_bank = msg.new_bank
    
	log.info("on_DF_Reply...... web[%d] reply[%d]", msg.web_id, msg.result)
    channel.publish("gm."..tostring(msg.web_id),"msg","FW_Result",{
        result = msg.result,
    })

	-- 成功就更新在线玩家金币
	if msg.result == 1 then
		notify_player_bank(guid, old_bank, new_bank, LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE)
    end
end

function on_DL_ResetAlipay(msg,session) 
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
            channel.publish("game."..tostring(gameid),"msg","LS_AlipayEdit",{
                guid = guid,
                alipay_name = alipay_name,
                alipay_name_y = alipay_name_y,
                alipay_account = alipay_account,
                alipay_account_y = alipay_account_y,
            })
        end
    end
end

function on_DL_CreateProxyAccount(msg,session) 
    if msg.result == 1 then 
        log.info("create proxy account success")
		write_gm_msg(msg.web_id,GMmessageRetCode_Success, msg.asyncid)
    else
        log.info("create proxy account failed")
		write_gm_msg(msg.web_id,GMmessageRetCode_GmCommandError, msg.asyncid)
    end
end

function on_S_ReplayProxyPlatformIds(msg,session) 
    for _,id in pairs(msg.platform_id) do
        channel.publish("db.?","msg","",{
            plaform_id = id,
            loginid = local_id,
        })
    end
end

function on_S_ReplyProxyInfo(msg,session) 
    local rep = reddb.hset("platform_proxy_info",msg.pb_platform_proxys.platform_id,json.encode(msg.pb_platform_proxys))
    if rep == 0 or rep == 1 then
        log.info("set proxy info sucess")
    else
        log.error("set proxy info failed")
    end
end

function on_DL_AgentAddPlayerMoney(msg,session) 
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

function on_DL_GMChangMoney(msg,session)
	local guid = msg.guid
	local old_bank = msg.old_bank
	local new_bank = msg.new_bank
	local type_id = msg.type_id

    channel.publish("gm."..tostring(msg.web_id),"msg","LW_ChangeMoney",{
        result = msg.result,
    })

	-- 成功就更新在线玩家金币
	if msg.result == 1 then
		notify_player_bank(guid, old_bank, new_bank, type_id)
    end
end

function on_DL_ReturnAgentMoney(msg,session)
	local guid = msg.guid
	local old_bank = msg.old_bank
	local new_bank = msg.new_bank
	local type_id = msg.type_id

    channel.publish("gm."..tostring(msg.web_id),"msg","LW_LuaCmdPlayerResult",{
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