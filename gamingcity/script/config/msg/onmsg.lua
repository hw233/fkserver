local pb = require "pb"
local skynet = require "skynet"

local dbopt = require "dbopt"
local log = require "log"
local guidopt = require "netguidopt"
local netopt = require "netopt"
require "functions"

local LOG_MONEY_OPT_TYPE_RECHARGE_MONEY = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_RECHARGE_MONEY")

local php_sign = ""

local function get_warning_notice_cfg(fd,server_id,server_type)
    local notice_type = {[1] = true,[2] = true,[3] = true,[4] = true}
    if not notice_type[server_type] then
        return
    end

    local info = dbopt.config:query("CALL get_notice_addr();")
    send2pb(fd,"S_ReplyWarningAddr",{
        notice_potato_addr = info.notice_potato_addr,
        notice_telegram_addr = info.notice_telegram_addr,
    })
end

local function get_gate_cfg(fd,gate_id)
    local gate_info = dbopt.config:query("CALL get_gate_config(%d);", gate_id)
    local game_cfg_info = dbopt.config:query(
        "SELECT game_id, game_name, first_game_type, second_game_type, table_count, money_limit, cell_money, tax, platform_id,title FROM t_game_server_cfg WHERE is_open = 1;"
    )

    local client_room_cfg = {}
    for _,v in pairs(game_cfg_info) do
        table.insert(client_room_cfg,{
            game_id = tonumber(v[1]),
            game_name = v[2],
            first_game_type = tonumber(v[3]),
            second_game_type = tonumber(v[4]),
            table_count = tonumber(v[5]),
            money_limit = tonumber(v[6]),
            cell_money = tonumber(v[7]),
            tax = tonumber(v[8]),
            platform_id = v[9] or "[]",
        })
    end


    get_warning_notice_cfg(fd,gate_id,SessionGate)

    return {
        type = SessionGate,
        server_id = gate_id,
        game_cfg_info = game_cfg_info,
        gate_config = gate_info,
    }
end

local function get_game_cfg(fd,game_id)
    local res = dbopt.config:query("SELECT * FROM t_game_server_cfg where game_id = %d and is_open = 1;", game_id)
    dump(res)
    broadcastpb2type(SessionGate,"S_NotifyGameServerStart",{
        game_id = game_id,
    })

    return {
        type = SessionGame,
        server_id = game_id,
        game_config = #res > 0 and res[1] or nil,
    }
end

local function get_login_cfg(fd,login_id)
    local res = dbopt.config:query("SELECT * FROM t_login_server_cfg where login_id = %d;", login_id)
    
    local notify = {login_id = login_id,}
    broadcastpb2type(SessionGate,"S_NotifyLoginServerStart",notify)
    broadcastpb2type(SessionGate,"S_NotifyLoginServerStart",notify)

    return {
        type = SessionLogin,
        server_id = login_id,
        login_config = #res > 0 and res[1] or nil,
    }
end

local function get_db_cfg(fd,db_id)
    local res = dbopt.config:query( "SELECT * from t_db_server_cfg WHERE id = %d and is_open = 1;", db_id)
    phpsign = res.php_sign_key
    
    local notify = {db_id = db_id,}
    broadcastpb2type(SessionGate,"S_NotifyDBServerStart",notify)
    broadcastpb2type(SessionLogin,"S_NotifyDBServerStart",notify)
    get_warning_notice_cfg(fd,db_id,SessionGate)

    return {
        type = SessionDB,
        server_id = db_id,
        db_config = #res > 0 and res[1] or nil,
    }
end

local function get_gm_cfg(fd,db_id)
    local res = dbopt.config:query( "SELECT * from t_db_server_cfg WHERE id = %d and is_open = 1;", db_id)
    return {
        type = SessionWeb,
        server_id = db_id,
        db_config = #res > 0 and res[1] or nil,
    }
end

local function update_gate_config(fd,gate_id,game_id)
    local res = dbopt.config:query("CALL update_gate_config(%d,%d);", gate_id, game_id)
    local game_res = dbopt.config:query(
        "SELECT game_id, game_name, first_game_type, second_game_type, table_count,money_limit,cell_money,tax,platform_id,title  FROM t_game_server_cfg WHERE is_open = 1;"
    )

    for _,v in pairs(game_res) do
        log.info( "update_gate_config[%d] ok", gate_id )
        sendpb(fd,"S_ReplyUpdateGameServerConfig",{
            server_id = gate_id,
            game_id = game_id,
            ip = res.ip,
            port = res.port,
            client_room_cfg = v,
        })
    end
end

local function update_gate_login_config(fd,gate_id,login_id)
    local res = dbopt.config:query("CALL update_gate_login_config(%d,%d);", gate_id, login_id)
    sendpb(fd,"S_ReplyUpdateLoginServerConfigByGate",{
        server_id = gate_id,
        login_id = login_id,
        ip = res.ip,
        port = res.port,
    })

    log.info("update_gate_login_config[%d] ok", login_id )
end

local function update_game_login_config(fd,game_id,login_id)
    local res = dbopt.config:query("CALL update_game_login_config(%d,%d);", game_id, login_id)
    sendpb(fd,"S_ReplyUpdateLoginServerConfigByGame",{
        server_id = gate_id,
        login_id = login_id,
        ip = res.ip,
        port = res.port,
    })

    log.info( "update_game_login_config[%d] ok", login_id )
end

local function update_game_db_config(fd,game_id,db_id)
    local res = dbopt.config:query("CALL update_game_db_config(%d,%d);", game_id, db_id)
    sendpb(fd,"S_ReplyUpdateDBServerConfigByGame",{
        server_id = game_id,
        db_id = db_id,
        ip = res.ip,
        port = res.port,
    })

    log.info( "update_game_login_config[%d] ok", db_id )
end

local function update_login_db_config(fd,login_id,db_id)
    local res = dbopt.config:query("CALL update_login_db_config(%d,%d);", login_id, db_id)
    sendpb(fd,"S_ReplyUpdateDBServerConfigByLogin",{
        server_id = login_id,
        db_id = db_id,
        ip = res.ip,
        port = res.port,
    })

    log.info( "update_game_login_config[%d] ok", db_id )
end

local get_server_cfg = {
    [SessionGate] = get_gate_cfg,
    [SessionLogin] = get_login_cfg,
    [SessionDB] = get_db_cfg,
    [SessionGame] = get_game_cfg,
    [SessionWeb] = get_gm_cfg,
}

function on_S_RequestServerConfig(fd,msg)
    if not get_server_cfg[msg.type] then
        return
    end
    return get_server_cfg[msg.type](fd,msg.server_id)
end

function on_S_RequestUpdateGameServerConfig(fd,msg)
    update_gate_config(df,msg.server_id,msg.game_id)
end

function on_S_RequestUpdateLoginServerConfigByGate(fd,msg)
    update_gate_login_config(fd,msg.server_id,msg.login_id)
end

function on_S_RequestUpdateLoginServerConfigByGame(fd,msg)
    update_game_login_config(fd,msg.server_id,msg.login_id)
end

function on_S_RequestUpdateDBServerConfigByGame(fd,msg)
    update_game_db_config(fd,msg.server_id,msg.db_id)
end

function on_S_RequestUpdateDBServerConfigByLogin(fd,msg)
    update_login_db_config(fd,msg.server_id,msg.db_id)
end

function on_WF_UpdateDbCfg(fd,msg)
    local db_fds = netopt.byid(SessionDB)
    for _,v in pairs(db_fds) do
        get_db_config(v.fd,v.server_id)
    end
    sendpb(fd,"FW_UpdateDbCfg",{result = 1})
end

function on_WF_ChangeGameCfg(fd,msg)
    local game_id = msg.id
    local info = dbopt.config:query("CALL get_game_config(%d);", game_id)
    log.info( "get_game_config[%d] ok", game_id );
    local room_list_str = string.format(
        "do return {{table_count=%d, money_limit=%d, cell_money=%d, tax_open=%d, tax_show=%d, tax=%d, game_switch_is_open=%d,platform_id=\"%s\",title=\"%s\" }} end",
        info.table_count , info.money_limit , info.cell_money , info.tax_open , info.tax_show , info.tax , info.game_switch_is_open , info.platform_id , info.title
    )

    sendpb2id(SessionGate,game_id,"FS_ChangeGameCfg",{
        room_lua_cfg = info.lua_cfg,
        room_list = room_list_str,
    })

    broadcast2type(SessionLogin,"S_UpdateGameCfg",{
        game_id = game_id,
        platform_ids = info.platform_id,
    })
end

function on_WF_GetCfg(fd,msg)
    sendpb(fd,"FW_GetCfg",{
        php_sign = php_sign,
    })
end

function on_SF_ChangeGameCfg(fd,msg)
    sendpb2id(SessionWeb,msg.webid,"FW_ChangeGameCfg",{
        result = msg.result,
    })

    broadcast2type(SessionGate,"FG_GameServerCfg",{
        pb_cfg = msg.pb_cfg,
    })
end

function on_WS_MaintainUpdate(fd,msg)
    local id = msg.id_index
    local str = ""
    if id == 1 then 
        str = "cash_switch"
    elseif id == 2 then
        str = "game_switch"
    elseif id == 3 then
        str = "login_switch"
    else
        sendpb(fd,"SW_MaintainResult",{result = 2,})
        return
    end

    local res = dbopt.config:query("select value from t_globle_int_cfg where `key` = '%s' ;", str)
    local queryinfo = {
        maintaintype = id,
        switchopen = res[1],
    }

    if id == 3 then
        broadcast2type(SessionGate,"CS_QueryMaintain",queryinfo)
    else
        broadcast2type(SessionLogin,"CS_QueryMaintain",queryinfo)
    end

    sendpb(fd,"SW_MaintainResult",{result = 1,})
end

function on_GF_PlayerOut(fd,msg)
    guidopt.logout(msg.guid)
end

function on_GF_PlayerIn(fd,msg)
    guidopt.login(msg.guid,{
        gate_id = fd_session(fd).server_id,
    })
end

function on_WF_Recharge(fd,msg)
    log.info("on_WF_Recharge......order_id[%d]  web[%d]",msg.order_id, fd)
    sendpb2randomid(SessionDB,"FD_ChangMoney",{
        web_id = netopt.byfd(fd).server_id,
        order_id = msg.order_id,
        type_id = LOG_MONEY_OPT_TYPE_RECHARGE_MONEY,
    })
end

function on_DF_Reply(fd,msg)
	log.info("on_DF_Reply...... web[%d] reply[%d]", msg.web_id, msg.result)
    sendpb2id(SessionWeb,msg.web_id,"FW_Result",{
        result = msg.reuslt,
    })
end

function on_DF_ChangMoney(fd,msg)
    local gate_id = guid_session(msg.info.guid).gate_id
	log.info("on_DF_ChangMoney  web[%d] guid[%d] order_id[%d] type[%d]",msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id )
	if gate_id == -1 then
		log.info( "on_DF_ChangMoney  %d no online", msg.info.guid)
        sendpb2randomid(SessionDB,"FD_ChangMoneyDeal",{
            info = msg.info,
            web_id = msg.web_id,
        })
	else
		log.info( "on_DF_ChangMoney  %d  online", msg.info.guid );
        sendpb2id(SessionGate,gate_id,"FS_ChangMoneyDeal",{
            web_id = msg.web_id,
            info = msg.info,
        })
    end
end

function on_FS_ChangMoneyDeal(fd,msg)
    log.info( "on_FS_ChangMoneyDeal  web[%d] guid[%d] order_id[%d] type[%d]", msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id)    
    sendpb2randomid(SessionDB,"FD_ChangMoneyDeal",{
        info = msg.info,
        web_id = msg.web_id,
    })
end

function on_SS_JoinPrivateRoom(fd,msg)
    local gate_id = guid_session(msg.owner_guid).gate_id
    if not gate_id then
        senbpb(fd,msg)
        return
    end

    sendpb2id(SessionGate,gate_id,msg)
end

function on_S_RequestPlatformNum(fd,msg)
    local res = dbopt.config:query("SELECT DISTINCT platform_id FROM t_recharge_and_cash_switch;")
    sendpb(fd,"S_ReplayPlatformId",{
        platform_id = res
    })
end

function on_S_RequestPlatformRechargeSwitchIndex(fd,msg)
	local platform_id = msg.platform_id()
	local update_flag = msg.update_flag()
    local res = dbopt.config:query("select recharge_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local recharge_maintain_cmd = res[1][1]
    log.info( "recharge:platform = [%d] recharge_maintain = [%s]", platform_id, recharge_maintain_cmd)
    sendpb(fd,"S_ReplyPlatformRechargeSwitch",{
        update_flag = update_flag,
        platform_id = platform_id,
        recharge_switch_str = recharge_maintain_cmd,
    })
end

function on_S_RequestPlatformCashSwitchIndex(fd,msg)
    local platform_id = msg.platform_id()
    local update_flag = msg.update_flag()
    local res = dbopt.config:query("select cash_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local cash_maintain_cmd = res[1][1]
    log.info("cash:platform = [%d] cash_maintain_cmd = [%s]", platform_id, cash_maintain_cmd)
    sendpb(fd,"S_ReplyPlatformCashSwitch",{
        update_flag = update_flag,
        platform_id = platform_id,
        cash_switch_str = cash_maintain_cmd,
    })
end

function on_S_RequestPlatformPlayerToAgentCashSwitchIndex(fd,msg)
    local platform_id = msg.platform_id()
    local update_flag = msg.update_flag()
    local res = dbopt.config:query("select agent_cash_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local agent_cash_maintain_cmd = res[1][1]
    log.info("PlayerToAgentcash:platform = [%d] agent_cash_maintain_cmd = [%s]", platform_id, agent_cash_maintain_cmd)
    sendpb(fd,"S_ReplyPlatformPlayerToAgentCashSwitch",{
        update_flag = update_flag,
        platform_id = platform_id,
        playertoagent_switch_str = agent_cash_maintain_cmd,
    })
end

function on_S_RequestPlatformBankerTransferSwitchIndex(fd,msg)
    local platform_id = msg.platform_id()
    local update_flag = msg.update_flag()
    local res = dbopt.config:query("select banker_transfer_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local transfer_switch_str = res[1][1]
    log.info("banker_transfer_switch:platform = [%d] transfer_switch_str = [%s]", platform_id, transfer_switch_str)
    sendpb(fd,"S_ReplyPlatformBankerTransferSwitch",{
        update_flag = update_flag,
        platform_id = platform_id,
        transfer_switch_str = transfer_switch_str,
    })
end

function on_S_RequestGlobleIntCfg(fd,msg)
    local global_keys = {}
    for _,v in pairs(msg.globalkey) do
        table.insert(global_keys,"'" .. v .. "'")
    end

    local res = dbopt.config:query("select * from t_globle_int_cfg as tb where tb.key  in (%s);", table.concat(global_keys,","))
    local globlekeyvalue = {}
    for _,v in pairs(res) do
        table.insert(pb_globlekeyvalue,{
            globlekey = v[1],
            globlevalue = v[2],
        })
    end
    sendpb(fd,"S_ReplyGlobleIntCfg",{
        pb_globlekeyvalue = globlekeyvalue,
    })
end

function on_S_RequestPlatformSwitchInfo(fd,msg)
	local platform_id = msg.platform_id
	local temp_switch_type = msg.switch_type
	local update_flag = msg.update_flag
	local key_value = "cash_switch"

	if temp_switch_type < 0 or temp_switch_type > 4 then
		log.error( "error unknown type[%d],return", temp_switch_type )
		return
    end

	if temp_switch_type == 2 then
		key_value = "banker_transfer_switch"
	elseif temp_switch_type == 3 then
		key_value = "agent_cash_switch"
	elseif temp_switch_type == 4 then
		key_value = "bank_card_cash_switch"
    end

    log.info("platform = [%d] switch_value = [%s] temp_switch_type = [%d] update_flag = [%d] key_value = [%s]", 
        platform_id, temp_value, temp_switch_type, update_flag, key_value)

    local res = dbopt.config:query("select %s from t_recharge_and_cash_switch where platform_id = %d;", key_value, platform_id)
    sendpb(fd,"S_ReplyPlatformSwitchInfo",{
        platform_id = platform_id,
        switch_type = temp_switch_type,
        switch_key = key_value,
        switch_value = temp_value,
        update_flag = update_flag,
    })
end

function on_S_RequestPlatformAllCashSwitchIndex(fd,msg)
	local platform_id = msg.platform_id
    local update_flag = msg.update_flag
    local res = dbopt.config:query("select all_cash_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local cash_maintain_cmd = res[1][1]

    log.info("all cash switch:platform = [%d] cash_maintain_cmd = [%s]", platform_id, cash_maintain_cmd)
    sendpb(fd,"S_ReplyPlatformAllCashSwitch",{
        platform_id = platform_id,
        all_cash_switch_str = cash_maintain_cmd,
        update_flag = update_flag,
    })
end

skynet.start(function() end)