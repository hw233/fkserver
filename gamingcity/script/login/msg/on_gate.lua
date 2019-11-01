
local redisopt = require "redisopt"
local netopt = require "netopt"
local pb = require "pb"
local json = require "cjson"
local skynet = require "skynet"
local channel = require "channel"

local reddb = redisopt.default

require "functions"

require "login.msg.runtime"


function on_s_logout(msg,guid)
	local account = msg.account
    local platform_id = msg.platform_id

    reddb.del("player:online:info:"..account)
    reddb.del("player:online:info:"..tostring(guid))

    local onlineinfo = reddb:hgetall("player:online:info:"..tostring(guid))
    local gameid = onlineinfo.server
    if gameid then
        channel.publish("game."..tostring(game_id),"S_Logout",{
            account = account,
            guid = guid,
            platform_id = platform_id,
        })
    end

    return true
end

function on_cl_login(msg)  
	local password = msg.password
	local info = {}
	info.session_id = session_id
	info.gate_id = server_id_
	info.account = msg.account
	info.phone = msg.phone
	info.phone_type = msg.phone_type
	info.version = msg.version
	info.channel_id = msg.channel_id
	info.package_name = msg.package_name
	info.imei = msg.imei
	info.ip = msg.ip
	info.ip_area = msg.ip_area
	info.password = password
	info.deprecated_imei = msg.deprecated_imei
	info.platform_id = msg.platform_id
	info.shared_id = msg.shared_id

    local account_key = get_account_key(info.account,info.platform_id)
    local succ = reddb.hsetnx("player:login:info",account_key,json.encode(info))
    if succ == 1 then
        if info.guid then
            reddb.hset("player:login:info:guid",info.guid,json.encode(info))
        end

        channel.call("db.?","msg","LD_VerifyAccount",{
            verify_account = {
                account = info.account,
                password = password,
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
            shared_id = info.shared_id,
        })

        log.info( "login step login[offline]->LD_VerifyAccount ok,account=%s", info.account)
    else
        local other = get_player_login_info(account_key)
        if not other then
            log.error( "login step login get_player_login_info false[%s]", account_key)
            return {
                result = LOGIN_RESULT_REDIS_ERROR,
            }
        end

        if info.session_id == other.session_id and info.gate_id == other.gate_id then
            channel.publish("db.?","LD_VerifyAccount",{
                verify_account = {
                    account = info.account,
                    password = password,
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
                shared_id = info.shared_id,
            })
    
            log.info( "login step login[offline]->LD_VerifyAccount ok,account=%s", info.account)
            return
        end

        local gate_id = netopt.byid(SessionGate,gate_id)
        if not gate_id then
            reddb.hdel("player_online_gameid",other.guid)
            reddb.hdel("player_session_gate",other.session_id,other.gate_id)
            reddb.hset("player:login:info",account_key,json.encode(info))
            if info.guid then
                reddb.hset("player:login:info:guid",info.guid,json.encode(info))
            end

            channel.publish("db.?","LD_VerifyAccount",{
                verify_account = {
                    account = info.account,
                    password = password,
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
                shared_id = info.shared_id,
            })

            log.info( "login step login[online]->LD_VerifyAccount,account=%s", info.account)

            return
        end

        channel.publish("gate."..tostring(other.gate_id),"LG_KickClient",{
            session_id = other.session_id,
            reply_account = info.account,
            user_data = 2,
            platform_id = info.platform_id,
        })

        reddb.hset("player:login:info:temp",account_key,json.encode(info))
        log.info( "login step login[online]->LG_KickClient,account=%s, session_id=%d,other_session_id=%d", account_key, info.session_id, other.session_id)
    end
end

function on_cl_reg_account(msg)  
    local msg = channel.call("db.?","msg","LD_RegAccount",{
        pb_regaccount =msg.pb_regaccount,
    })

    return on_dl_reg_account(msg)
end

function on_cl_login_by_sms(msg) 
    local info = {}
	info.session_id = session_id
	info.gate_id = server_id_
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

	local request = {}
	request.account = info.account
	request.session_id = info.session_id
	request.gate_id = info.gate_id
	request.phone = msg.phone
	request.phone_type = msg.phone_type
	request.version = msg.version
	request.channel_id = msg.channel_id
	request.package_name = msg.package_name
	request.imei = msg.imei
	request.ip = msg.ip
	request.ip_area = msg.ip_area
	request.deprecated_imei = msg.deprecated_imei
	request.platform_id = msg.platform_id
	request.shared_id = info.shared_id
	request.unique_id = msg.unique_id
	request.invite_code = msg.invite_code
	request.invite_type = msg.invite_type

	log.info( "account [%s] phone [%s] phone_type[%s] version[%s]",info.account, info.phone, info.phone_type, info.version )

    local succ = reddb.hmset("player:login:info:"..account,info)
    if succ == 1 then
        channel.publish("db.?","LD_SmsLogin",request)
    else
        local other = get_player_login_info(account_key)
        if not other then
            log.error( "player[%s] not find", account_key)
            return
        end

        if info.session_id == other.session_id and info.gate_id == other.gate_id then
            channel.publish("db.?","LD_SmsLogin",request)
            return
        end

        local gate_id = netopt.byid(SessionGate,other.gate_id)
        if not gate_id then
            reddb.hdel("player_online_gameid",other.guid)
            reddb.hdel("player_session_gate",other.session_id,other.gate_id)
            reddb.hset("player:login:info",account_key,json.encode(info))
            reddb.hset("player:login:info:guid",info.guid,json.encode(info))
        else
            channel.publish("gate."..tosring(other.gate_id),"LG_KickClient",{
                session_id = other.session_id,
                reply_account = info.account,
                user_data = 3,
                platform_id = info.platform_id,
            })
            reddb.hset("player:login:info:temp",account_key,json.encode(info))
            log.info( "login step loginsms[online]->LG_KickClient,account=%s", account_key)
        end
    end
end

function on_L_KickClient(msg)  
	local account_ = msg.reply_account
	local platform_id = msg.platform_id
	local account_key = get_account_key( account_, platform_id )
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
                    result = LOGIN_RESULT_NO_DEFAULT_LOBBY,
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
            channel.publish("db.?","LD_VerifyAccount",{
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

            channel.publish("db.?","LD_SmsLogin",{
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

function on_ss_change_game(msg)  
	local gameid = find_a_game_id( msg.first_game_type, msg.second_game_type )
	if not gameid then        
        sendpb2guids(msg.guid,msg.gate_id,"SC_EnterRoomAndSitDown",{
            game_id = msg.game_id,
            first_game_type = msg.first_game_type,
            second_game_type = msg.second_game_type,
            result = GAME_SERVER_RESULT_NO_GAME_SERVER,
        })

        sendpb("LS_ChangeGameResult",{
            guid = msg.guid,
        })

		log.error( "gameid=0, (%d,%d)", msg.first_game_type, msg.second_game_type )
		return
    end

	send_pb("LS_ChangeGameResult",{
        change_msg = msg,
        guid = msg.guid,
        success = true,
        game_id = gameid,
    })
end

function on_SL_ChangeGameResult(msg)
    channel("game."..tostring(msg.game_id),msg.change_msg)
end

function on_cs_request_sms(msg)
    channel.publish("db.?","LD_PhoneQuery",{
        phone = msg.tel,
        gate_session_id = msg.gate_session_id,
        gate_id = msg.gate_id,
        guid = msg.guid,
        platform_id = msg.platform_id,
    })
end

function on_sd_bank_transfer(msg)  
	local self_game_id = server_id_

    local info = get_player_login_info(msg.target)

    if info then
        local game_id = get_gameid_by_guid(info.guid)
        if game_id then
            if has_game_server_info( game_id ) then
                channel("game."..tostring(self_game_id),"LS_BankTransferSelf",{
                    guid = msg.guid,
                    time = msg.time,
                    target = msg.target,
                    money = msg.money,
                    bank_balance = msg.bank_balance,
                })

                channel.publish("game."..tostring(game_id),"LS_BankTransferTarget",{
                    selfname = msg.selfname,
                    time = msg.time,
                    target = msg.target,
                    money = msg.money,
                })
                
                return
            end
        end
    end

    channel.publish("db.?","SD_BankTransfer",msg)
end

function on_sd_bank_transfer_by_guid(msg)  
    
    msg.game_id = server_id_

    local game_id = get_gameid_by_guid( msg.target_guid )
    if game_id then
        if has_game_server_info( game_id ) then
            channel.publish("game."..tostring(msg.game_id),"LS_BankTransferByGuid",{
                guid = msg.guid,
                money = -msg.money,
            })

            channel.publish("game."..tostring(game_id),"LS_BankTransferByGuid",{
                guid = msg.target_guid,
                money = msg.money,
            })

            return
        end
    end

    channel.publish("db.?","S_BankTransferByGuid",msg)
end

function on_cs_chat_world(msg)  
    channel.publish("gate.*","CS_ChatWorld",msg)
end

function on_sc_chat_private(msg)
    local info = get_player_login_info(msg.private_name)
    if info then
        local game_id = get_gameid_by_guid( info.guid )
        if game_id then
            channel.publish("game."..tostring(game_id),"SC_ChatPrivate",msg)
        end
    end
end

function on_wl_request_game_server_info(msg) 

end

function on_sl_web_game_server_info(msg)  
    
end


function on_wf_recharge(msg)  
	local order_id = msg.order_id
	local guid = msg.guid
	local money = msg.money
	local asyncid = msg.asyncid
	log.info( "on_wf_recharge asyncid[%s] start guid[%d] orderid[%d] money[%d]", asyncid, guid, order_id, money )

    channel.publish("db.?","",{
        guid = guid,
        retid = 0,
        asyncid = asyncid,
        loginid = netopt.byfd(fd).server_id,
    })
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

        channel.publish("gm."..tostring(msg.web_id),"LW_CashFalse",{
            result = msg.result,
        })
    else
        channel.publish("gm."..tostring(msg.web_id),"LW_CashFalse",{
            result = msg.result,
        })
    end
end

function on_wl_request_change_tax(msg)  
    local gameid = netopt.byid(SessionGate,msg.id).server_id
    if gameid then
        channel.publish("game."..tostring(msg.id),"LS_ChangeTax",{
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
    channel.publish("gm."..tostring(msg.webid),"LW_ChangeTax",{
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
    local webid = netopt.byfd(fd).server_id
    local gateid,_ = player_is_online(guid)

    if not gateid then
        channel.publish("db.?","LD_OfflineChangeMoney",{
            guid = guid,
            gmcommand = msg.gmcommand,
        })

        sendpb2id(SessionWeb,"LW_ChangePlayersMoney",{
            result = 1,
        })
        return
    end


    local gameid = reddb.hget("player_online_gameid",guid)
    if gameid then
        channel.publish("gate."..tostring(gameid),"LS_ChangeMoney",{
            webid = webid,
            guid = guid,
            gmcommand = gmcommand,
        })

        channel.publish("gm."..tostring(webid),"LW_ChangePlayersMoney",{
            result = 1,
        })
        return
    end

    channel.publish("db.?","LD_OfflineChangeMoney",{
        guid = guid,
        gmcommand = gmcommand,
    })

    channel.publish("gm.?","LD_OfflineChangeMoney",{
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

    channel.publish("db.?","LD_ReturnAgentMoney",{
        web_id = webid,
        login_id = login_id,
        guid = guid,
        bank_money = bank_money,
        type_id = banker_type,
        order_id = order_id,
    })
end

function on_SL_LuaCmdPlayerResult(msg)
    channel.publish("gm."..tostring(msg.web_id),"LW_LuaCmdPlayerResult",{
        result = msg.result,
        guid = msg.guid,
        order_id = msg.order_id,
        cost_money = msg.cost_money,
        acturl_cost_money = msg.acturl_cost_money,
    })
end


function on_WL_GmCommandToServer(msg)  
    local webid = netopt.byfd(fd).server_id

	printf( "\n" )
	printf( msg.cmd_content )
	printf( "\n" )
    
    local doc = json.decode(msg.cmd_content)
	if not doc then
		printf( "on_WL_GmCommandToServer parse json error..." )
		channel.publish("gm."..tostring(webid),"LW_GmCommandToServerResult",{
            result = 2,
        })
		return
    end

    if not json_has_member(doc,{
        command= "number",
    }) then
        printf( "on_WL_GmCommandToServer command not found..." )
		channel.publish("gm."..tostring(webid),"LW_GmCommandToServerResult",{
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

        channel.publish("gate.*","LS_UpdateBonusHongbao",m)
    else
		log.warning( "on_WL_GmCommandToServer unknown Command code [%d]", doc.command )
	end

	channel.publish("gm."..tostring(webid),"LW_GmCommandToServerResult",{
        result = 1,
    })
end


function on_SL_GameNotice(msg)  
    local platform_ids = {}
    if msg.platform_id then
        table.insert(platform_ids,msg.platform_id)
    else
    end

    channel.publish("gate.*","LS_GameNotice",{
        pb_game_notice = msg.pb_game_notice,
        platform_ids = platform_ids,
    })
end

function on_SL_RequestProxyInfo(msg)
    channel.publish("config.?","S_RequestProxyInfo",{
        platform_id = msg.platform_id,
    })
end

function on_gl_get_server_cfg(msg)  
    channel.publish("db.?","LD_GetServerCfg",{
        gid = netopt.byfd(fd).server_id,
    })
end

function on_cl_get_server_cfg(msg)  
    channel.publish("db.?","CL_GetInviterInfo",{
        gate_session_id = 0,
        gate_id = netopt.byfd(fd).server_id,
    })
end

function on_dl_recharge(msg)  
	log.info( "LoginDBSession::on_dl_recharge guid[%d] orderid[%d] retcode[%d]", msg.guid, msg.orderid, msg.retcode )
    channel.publish("gm."..tostring(msg.retid),"FW_Result",{
        result = msg.retcode,
        asyncid = msg.asyncid,
    })
end

function on_wl_broadcast_gameserver_cmd(msg)  
    local webid = netopt.byfd(fd).server_id
    local gameinfos = netopt.byid(SessionGate)
    if #gameinfos == 0 then
        channel.publish("gm."..tostring(webid),{
            result = 2,
        })
        return
    end

    channel.publish("gate.*",msg)
    channel.publish("gm."..tostring(webid),{
        result = 1,
    })
end

function on_WF_CashFalse(msg)  
    local web_id = netopt.byfd(fd).server_id
	log.info( "on_WF_CashFalse......order_id[%d]  web[%d]", msg.order_id, web_id )
    
    channel.publish("db.?","FD_ChangMoney",{
        web_id = web_id,
        order_id = msg.order_id,
        type_id = LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE,
        other_oper = msg.del,
    })
end

function on_FS_ChangMoneyDeal(msg)  
    log.info( "on_FS_ChangMoneyDeal  web[%d] gudi[%d] order_id[%d] type[%d]", 
        msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id )

    channel.publish("db.?","FD_ChangMoneyDeal",{
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