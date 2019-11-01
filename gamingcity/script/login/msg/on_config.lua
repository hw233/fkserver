local log = require "log"
local netopt = require "netopt"
local redis_db = require "redisopt"
require "functions"
require "login.msg.runtime"
local channel = require "channel"

local reddb = redis_db[0]


function on_S_ReplyServerConfig(fd,msg)  
    local logincfg = msg.login_config
    log.info("load config complete ltype=%d id=%d\n", msg.type, msg.server_id);
end

function on_S_NotifyDBServerStart(fd,msg)
    sendpb(fd,"S_RequestUpdateDBServerConfigByLogin",{
        db_id = msg.db_id,
    })
end

function on_S_ReplyUpdateDBServerConfigByLogin(fd,msg)  
    log.info("load config on_S_ReplyUpdateDBServerConfigByLogin\n");
end

function on_S_Maintain_switch(fd,msg)  
	log.info("on_S_Maintain_switch  id = [%d],value=[%d]\n", msg.maintaintype, msg.switchopen)
	local open_switch = msg.switchopen
	if msg.maintaintype == 3 then
        channel.publish(SessionDB,"LD_QueryMaintain",{
            maintaintype = msg.maintaintype,
            switchopen = msg.switchopen,
        })
    end

    maintain_switch = open_switch
end

function on_S_ReviceWarnningAddr(fd,msg)
    warnning_addr = msg
    local pt_addr = msg.notice_potato_addr
    local tg_addr = msg.notice_telegram_addr
    if pt_addr or tg_addr then
        log.info("***************notice_warnning warnning ip = [%s] ,warnning port = [%u], pt_url = [%s], tg_url = [%s]*********", 
            ip_, port_, pt_addr, tg_addr)

        local warningdata = string.format("通知: 登录服---->配置服 连接成功 ip[%s:%d]",ip_,port_)
    end
end

function on_S_ReplayReplayPlatformTotal(fd,msg)  
	-- 请求全局开关
	local globalkey = {}
	for _,platform_id in pairs(msg.platform_id) do
		-- 充值
        channel.publish("config.*","S_RequestPlatformRechargeSwitchIndex",{
            platform_id = platform_id,
            update_flag = 0,
        })

		-- 1:支付宝兑换 2:银行转账（未用）3:代理支付宝转账 4:银行卡转账【线下】 5:未用 6:银联卡兑换开关【线上】        
        channel.publish("config.*","S_RequestPlatformAllCashSwitchIndex",{
            platform_id = platform_id,
            update_flag = 0,
        })

        -- 破产基础值
        table.insert(globalkey,string.format("collapse_value_platform_id_ %d",platform_id))
    end
    channel.publish("config.*","S_RequestGlobleIntCfg",{
        globlekey = globalkey,
    })
end

function on_S_ReplyPlatformRechargeSwitch(fd,msg)  
    log.info("msg.platform_id = [%d], msg.recharge_switch_str = [%s] msg.update_flag = [%d]", 
        msg.platform_id, msg.recharge_switch_str,msg.update_flag)

	reddb.set(string.format("platform_recharge_%d",msg.platform_id),msg.recharge_switch_str)

	-- update_flag == 1表示热更新需要广播游戏服通知客户端更新充值维护配置
	local broast_gameserver_flag = msg.update_flag
	if broast_gameserver_flag == 1 then
		log.info("recharge:recharage:broast_gameserver_flag = [%d] update platform_id  = [%d]", broast_gameserver_flag, msg.platform_id)
		-- 广播游戏服
        channel.publish("game.*","LS_UpdatePlatformSwitch",{
            platform_id = msg.platform_id,
        })
    end
end

function on_S_ReplyPlatformCashSwitch(fd,msg)  
    log.info("cash:msg->platform_id = [%d], msg->cash_switch_str = [%s] msg->update_flag = [%d]", 
        msg.platform_id, msg.cash_switch_str, msg.update_flag)
    
    reddb.hset("platform_cash_"..tostring(msg.platform_id),"cash_switch "..msg.cash_switch_str)

	-- update_flag == 1表示热更新需要广播游戏服通知客户端更新充值维护配置
	local broast_gameserver_flag = msg.update_flag
	if broast_gameserver_flag == 1 then
		log.info("cash:broast_gameserver_flag = [%d] update platform_id  = [%d]", broast_gameserver_flag, msg.platform_id)
		-- 广播游戏服
        channel.publish("game.*","LS_UpdatePlatformCashSwitch",{
            platform_id = msg.platform_id,
        })
    end
end

function on_S_ReplyPlatformPlayerToAgentCashSwitch(fd,msg)  
    log.info("PlayerToAgentcash:msg->platform_id = [%d], msg->playertoagent_switch_str = [%s] msg->update_flag = [%d]",
        msg.platform_id, msg.playertoagent_switch_str, msg.update_flag)

    reddb.hset("platform_PlayerToAgent_cash_"..tostring(msg.platform_id),"agent_cash_switch",msg.playertoagent_switch_str)

	-- update_flag == 1表示热更新需要广播游戏服通知客户端更新维护配置
	local broast_gameserver_flag = msg.update_flag
	if broast_gameserver_flag == 1 then
		log.info("PlayerToAgentcash:broast_gameserver_flag = [%d] update platform_id  = [%d]", broast_gameserver_flag, msg.platform_id)
		-- 广播游戏服        
        channel.publish("game.*","LS_UpdatePlatformPlayerToAgentCashSwitch",{
            platform_id = msg.platform_id,
        })
    end
end

function on_S_ReplyPlatformBankerTransferSwitch(fd,msg)  
    log.info("PlayerToAgentcash:msg->platform_id = [%d], msg->transfer_switch_str = [%s] msg->update_flag = [%d]", 
        msg.platform_id, msg.transfer_switch_str, msg.update_flag);
    
    reddb.hset("platform_bankerTransfer_"..tostring(msg.platform_id),"banker_transfer_switch",msg.transfer_switch_str)

    -- update_flag == 1表示热更新需要广播游戏服通知客户端更新维护配置
    local broast_gameserver_flag = msg.update_flag
	if broast_gameserver_flag == 1 then
		log.info("banker_transfer_switch:broast_gameserver_flag = [%d] update platform_id  = [%d]", broast_gameserver_flag, msg.platform_id)
		-- 广播游戏服        
        channel.publish("game.*","LS_UpdatePlatformBankerTransferSwitch",{
            platform_id = msg.platform_id,
        })
    end
end

function on_S_ReplyGlobleIntCfg(fd,msg)  
    for i,v in pairs(msg.pb_globlekeyvalue) do
        log.info("globlekeyvalue[%d] --------->globlekey[%s] globlevalue[%s]",i, 
            v.globlekey, v.globlevalue)
        reddb.set(v.globlekey,v.globlevalue)
    end
end

function on_S_ReplyPlatformAllSwitchInfo(fd,msg)
    log.info(":msg->platform_id = [%d], msg->switch_type = [%d] msg->switch_key = [%s] msg->switch_value = [%s] msg->update_flag = [%d]", 
        msg.platform_id, msg.switch_type, msg.switch_key, msg.switch_value, msg.update_flag)
	local switch_type = msg.switch_type
	if switch_type < 0 or switch_type > 4 then
		log.error("error unknown type[%d],return", switch_type)
		return
    end

    local keyvaluemap = {
        [1] = "cash",
        [2] = "bankerTransfer",--银行转账开关
        [3] = "PlayerToAgent_cash",--代理兑换开关
        [4] = "bankcardswitch",--银行卡兑换开关
    }

    local keyvalue = keyvaluemap[switch_type]
    reddb.hset(string.format("platform_%s_%d",keyvalue,msg.platform_id),msg.switch_key,msg.switch_value)

	local broast_gameserver_flag = msg.update_flag
	if broast_gameserver_flag == 1 then
		local redis_key = string.format("platform_%s_%d",keyvalue,msg.platform_id)
        log.info("cash:broast_gameserver_flag = [%d] update platform_id  = [%d] switch_key = [%s] redis_key = [%s]",
            broast_gameserver_flag,msg.platform_id,msg.switch_key,redis_key)
        
		--广播游戏服
        channel.publish("game.*","LS_UpdatePlatformAllSwitchInfo",{
            platform_id = msg.platform_id,
            redis_key = redis_key,
            switch_key = msg.switch_key
        })
    end
end

function on_S_UpdateGameCfg(fd,msg)
    local game_id = msg.game_id
    local platform_ids = string.split(msg.platform_ids,",")
end

function on_S_ReplyPlatformAllCashSwitch(fd,msg)  
    log.info("msg.platform_id = [%d], msg.cash_switch_str = [%s] msg.update_flag = [%d]",
        msg.platform_id, msg.all_cash_switch_str, msg.update_flag)

    reddb.set(string.format("platform_all_cash_%d",msg.platform_id),msg.all_cash_switch_str)

	--update_flag == 1表示热更新需要广播游戏服通知客户端更新充值维护配置
	local broast_gameserver_flag = msg.update_flag
	if broast_gameserver_flag == 1 then
		log.info("cash:broast_gameserver_flag = [%d] update platform_id  = [%d]", broast_gameserver_flag, msg.platform_id)
		--广播游戏服        
        channel.publish("game.*","LS_UpdatePlatformAllCashSwitch",{
            platform_id = msg.platform_id,
        })
    end
end