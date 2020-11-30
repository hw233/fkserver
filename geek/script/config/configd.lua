local skynet = require "skynetproto"
local dbopt = require "dbopt"
local msgopt = require "msgopt"
local channel = require "channel"
local bootconf = require "conf.boot"
local log = require "log"
local json = require "cjson"
require "functions"
local redisopt = require "redisopt"
local enum = require "pb_enums"
local util = require "util"

local reddb = redisopt.default

LOG_NAME = "config"

local globalconf = {}

local services = {}
local clusters = {}
local dbs = {}
local redises = {}

local online_service = {}

local function load_service_cfg()
    local confs = dbopt.config:query("SELECT * FROM t_service_cfg WHERE is_launch != 0;")
    for _,conf in pairs(confs) do
        if conf.conf and type(conf.conf) == "string" and conf.conf ~= "" then
            conf.conf = json.decode(conf.conf)
        end
        if not conf.conf then
            conf.conf = {}
        end
    end

    return confs
end

local function load_cluster_cfg()
    local confs = dbopt.config:query("SELECT * FROM t_cluster_cfg WHERE is_launch != 0;")
    for _,conf in pairs(confs) do
        conf.conf = conf.conf and conf.conf ~= "" and json.decode(conf.conf) or nil
    end

    return confs
end

local function load_redis_cfg()
    local r = dbopt.config:query("SELECT * FROM t_redis_cfg;")
    return r
end

local function load_db_cfg()
    local r = dbopt.config:query("SELECT * FROM t_db_cfg;")
    return r
end

local function load_global()
    local globalcfg = dbopt.config:query("SELECT * FROM t_global_cfg;")
    if #globalcfg == 0 then
        return
    end
    
    globalconf = json.decode(globalcfg[1].value)
end

local MSG = {}

function MSG.global_conf()
    return globalconf
end

function MSG.query_php_sign()
    return globalconf.php_sign_key
end

function MSG.query_service_conf(id)
    if not id then return services end

    return services[id]
end

function MSG.query_cluster_conf(id)
    if not id then return clusters end

    return clusters[id]
end

function MSG.cluster_launch(id)
    if not id then return end

    dbopt.config:query("UPDATE t_server_cfg SET launched = 1 WHERE id = %d;",id)
    channel.publish("*.*","lua","cluster_launch",id)
end

function MSG.cluster_exit(id)
    if not id then return end

    dbopt.config:query("UPDATE t_server_cfg SET launched = 0 WHERE id = %d;",id)
    channel.publish("*.*","lua","cluster_exit",id)
end

function MSG.service_launch(id)
    if not id then return end

    dbopt.config:query("UPDATE t_service_cfg SET launched = 1 WHERE id = %d;",id)
    online_service[id] = true
    channel.publish("*.*","lua","service_launch",id)
end

function MSG.service_exit(id)
    if not id then return end

    dbopt.config:query("UPDATE t_service_cfg SET launched = 0 WHERE id = %d;",id)
    online_service[id] = nil
    channel.publish("*.*","lua","service_exit",id)
end

function MSG.query_database_conf(id)
    log.info("MSG.query_database_conf %s",id)
    if not id then return dbs end

    return dbs[id]
end

function MSG.query_redis_conf(id)
    if not id then return redises end

    return redises[id]
end

function MSG.query_online_game_conf(game_type,room_type)
    local games = {}
    for id,conf in pairs(online_service) do
        if (game_type == nil or  game_type == conf.conf.game_type)
            and (room_type == nil or room_type == conf.conf.room_type) then
            table.insert(games,conf)
        end
    end

    return games
end

function MSG.WF_UpdateDbCfg(msg)
    local db_froms = netopt.byid(SessionDB)
    for _,v in pairs(db_froms) do
        get_db_config(v.v.server_id)
    end

    return {
        result = 1
    }
end

function MSG.WF_ChangeGameCfg(msg)
    local game_id = msg.id
    local info = dbopt.config:query("CALL get_game_config(%d);", game_id)
    log.info( "get_game_config[%d] ok", game_id );
    local room_list_str = string.format(
        "do return {{table_count=%d, money_limit=%d, cell_money=%d, tax_open=%d, tax_show=%d, tax=%d, game_switch_is_open=%d,platform_id=\"%s\",title=\"%s\" }} end",
        info.table_count , info.money_limit , info.cell_money , info.tax_open , info.tax_show , info.tax , info.game_switch_is_open , info.platform_id , info.title
    )

    channel.publish("gate.*"..tostring(game_id),"msg","FChangeGameCfg",{
        room_lua_cfg = info.lua_cfg,
        room_list = room_list_str,
    })

    channel.publish("login.*","msg","UpdateGameCfg",{
        game_id = game_id,
        platform_ids = info.platform_id,
    })
end

function MSG.WF_GetCfg(msg)
    return {
        php_sign = php_sign,
    }
end

function MSG.SF_ChangeGameCfg(msg)
    sendpb2id(SessionWeb,msg.webid,"FW_ChangeGameCfg",{
        result = msg.result,
    })

    channel.publish("gate.*","msg","FG_GameServerCfg",{
        pb_cfg = msg.pb_cfg,
    })
end

function MSG.WMaintainUpdate(msg)
    local id = msg.id_index
    local str = ""
    if id == 1 then 
        str = "cash_switch"
    elseif id == 2 then
        str = "game_switch"
    elseif id == 3 then
        str = "login_switch"
    else
        return {result = 2,}
    end

    local res = dbopt.config:query("select value from t_globle_int_cfg where `d` = '%s' ;", str)
    local queryinfo = {
        maintaintype = id,
        switchopen = res[1],
    }

    if id == 3 then
        channel.publish("gate.*","msg","CQueryMaintain",queryinfo)
    else
        channel.publish("login.*","msg","CQueryMaintain",queryinfo)
    end

    return {result = 1,}
end

function MSG.WF_Recharge(msg)
    log.info("MSG.WF_Recharge......order_id[%d]  web[%d]",msg.order_id, from)
    return channel.call("db.?","msg","FD_ChangMoney",{
        order_id = msg.order_id,
        type_id = enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY,
    })
end

function MSG.DF_Reply(msg)
	log.info("MSG.DF_Reply...... web[%d] reply[%d]", msg.web_id, msg.result)
    return {
        result = msg.reuslt,
    }
end

function MSG.DF_ChangMoney(msg)
    local gate_id = guid_session(msg.info.guid).gate_id
	log.info("MSG.DF_ChangMoney  web[%d] guid[%d] order_id[%d] type[%d]",msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id )
	if not gate_id then
		log.info( "MSG.DF_ChangMoney  %d no online", msg.info.guid)
        channel.publish("gate.*","msg","FD_ChangMoneyDeal",{
            info = msg.info,
            web_id = msg.web_id,
        })
	else
		log.info( "MSG.DF_ChangMoney  %d  online", msg.info.guid );
        channel.publish("gate.*"..tostring(gate_id),"msg","FChangMoneyDeal",{
            web_id = msg.web_id,
            info = msg.info,
        })
    end
end

function MSG.FChangMoneyDeal(msg)
    log.info( "MSG.FChangMoneyDeal  web[%d] guid[%d] order_id[%d] type[%d]", msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id)    
    return channel.call("db.?","msg","FD_ChangMoneyDeal",{
        info = msg.info,
        web_id = msg.web_id,
    })
end

function MSG.RequestPlatformNum(msg)
    local res = dbopt.config:query("SELECT DISTINCT platform_id FROM t_recharge_and_cash_switch;")
    return {
        platform_id = res
    }
end

function MSG.RequestPlatformRechargeSwitchIndex(msg)
	local platform_id = msg.platform_id
	local update_flag = msg.update_flag
    local res = dbopt.config:query("select recharge_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local recharge_maintain_cmd = res[1][1]
    log.info( "recharge:platform = [%d] recharge_maintain = [%s]", platform_id, recharge_maintain_cmd)
    return {
        update_flag = update_flag,
        platform_id = platform_id,
        recharge_switch_str = recharge_maintain_cmd,
    }
end

function MSG.RequestPlatformCashSwitchIndex(msg)
    local platform_id = msg.platform_id()
    local update_flag = msg.update_flag()
    local res = dbopt.config:query("select cash_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local cash_maintain_cmd = res[1][1]
    log.info("cash:platform = [%d] cash_maintain_cmd = [%s]", platform_id, cash_maintain_cmd)
    return {
        update_flag = update_flag,
        platform_id = platform_id,
        cash_switch_str = cash_maintain_cmd,
    }
end

function MSG.RequestPlatformPlayerToAgentCashSwitchIndex(msg)
    local platform_id = msg.platform_id()
    local update_flag = msg.update_flag()
    local res = dbopt.config:query("select agent_cash_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local agent_cash_maintain_cmd = res[1][1]
    log.info("PlayerToAgentcash:platform = [%d] agent_cash_maintain_cmd = [%s]", platform_id, agent_cash_maintain_cmd)
    return {
        update_flag = update_flag,
        platform_id = platform_id,
        playertoagent_switch_str = agent_cash_maintain_cmd,
    }
end

function MSG.RequestPlatformBankerTransferSwitchIndex(msg)
    local platform_id = msg.platform_id()
    local update_flag = msg.update_flag()
    local res = dbopt.config:query("select banker_transfer_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local transfer_switch_str = res[1][1]
    log.info("banker_transfer_switch:platform = [%d] transfer_switch_str = [%s]", platform_id, transfer_switch_str)
    return {
        update_flag = update_flag,
        platform_id = platform_id,
        transfer_switch_str = transfer_switch_str,
    }
end

function MSG.RequestGlobleIntCfg(msg)
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
    return {
        pb_globlekeyvalue = globlekeyvalue,
    }
end

function MSG.RequestPlatformSwitchInfo(msg)
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
    return {
        platform_id = platform_id,
        switch_type = temp_switch_type,
        switch_key = key_value,
        switch_value = temp_value,
        update_flag = update_flag,
    }
end

function MSG.RequestPlatformAllCashSwitchIndex(msg)
	local platform_id = msg.platform_id
    local update_flag = msg.update_flag
    local res = dbopt.config:query("select all_cash_switch from t_recharge_and_cash_switch where platform_id = %d;", platform_id)
    local cash_maintain_cmd = res[1][1]

    log.info("all cash switch:platform = [%d] cash_maintain_cmd = [%s]", platform_id, cash_maintain_cmd)
    return {
        platform_id = platform_id,
        all_cash_switch_str = cash_maintain_cmd,
        update_flag = update_flag,
    }
end

function MSG.maintain()
    return util.is_in_maintain()
end

local sconf

local CMD = {}

local function checkconfigdconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
end

function CMD.start(conf)
    checkconfigdconf(conf)
    sconf = conf
end

local function clean_when_start()
    local key_patterns = {"table:player:*","player:table:*","table:info:*","club:table:*","player:online:*","sms:verify_code:*"}
    for _,pattern in pairs(key_patterns) do
		local keys = reddb:keys(pattern)
        for _,key in pairs(keys) do
            log.info("redis del %s",key)
            reddb:del(key)
        end
    end
end

local function setup_default_redis_value()
    local global_conf = globalconf
    local first_guid = global_conf.first_guid or 100001
    reddb:setnx("player:global:guid",math.floor(first_guid))
end

skynet.start(function()
    
    skynet.dispatch("lua",function(_,_,cmd,...)
        local f = CMD[cmd]
        if not f then
            log.error("unknow cmd:%s",cmd)
            skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
	end)

    msgopt.register_handle(MSG)
    skynet.dispatch("msg",function(_,_,cmd,...)
        local msg,sz = skynet.pack(msgopt.on_msg(cmd,...))
        skynet.ret(msg,sz)
	end)

    dbopt.open(bootconf.service.conf.db)

    for _,s in pairs(load_service_cfg()) do
        services[s.id] = s
    end

    for _,c in pairs(load_cluster_cfg()) do
        clusters[c.id] = c
    end

    for _,d in pairs(load_db_cfg()) do
        dbs[d.name] = d
    end

    for _,r in pairs(load_redis_cfg()) do
        redises[r.id] = r
    end

    load_global()

    skynet.timeout(0,function()
        clean_when_start()
        -- setup_default_redis_value()
    end)
end)
