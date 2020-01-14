-- 日志消息处理

local pb = require "pb_files"
local log = require "log"
local json = require "cjson"
require "db.net_func"
local dbopt = require "dbopt"
local enum = require "pb_enums"

-- 钱日志
function on_sd_log_money(msg)
    dump(msg)
	dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", msg)
	-- if msg.opt_type == enum.LOG_MONEY_OPT_TYPE_RESET_ACCOUNT then
    --     local sql = string.format("update t_player set bind_gold = %d , bind_time = current_timestamp where guid = %d", msg.new_money - msg.old_money ,msg.guid )
    --     dbopt.game:query(sql)
    -- end
	log.info("...................... on_sd_log_money")
end

--下注流水日志
function on_sd_log_bet_flow(msg)
    dbopt.proxy:query("call update_bet_flow(%d,%d)",msg.guid,msg.money)
end

function on_sl_channel_invite_tax( msg)
    dbopt.log:query([[
        INSERT INTO `log`.`t_log_channel_invite_tax` (`guid`, `guid_contribute`, `val`, `time`)
        VALUES (%d, %d, %d, NOW())]],msg.guid_invite,msg.guid,msg.val)
    dbopt.game:query([[
        INSERT INTO `game`.`t_channel_invite_tax` (`guid`, `val`)
        VALUES (%d, %d)]],msg.guid_invite,msg.val)
end

function on_sd_log_game_money( msg)
    local sql
    if msg.guid >= 0 then
        sql = string.format([[
            INSERT INTO `log`.`t_log_money_tj` (`guid`, `type`, `gameid`, `game_name`,`phone_type`,`money_type`, `old_money`, `new_money`, `tax`, `change_money`, `ip`, `id`, `channel_id`, `platform_id` , `seniorpromoter`)
            VALUES (%d, %d, %d, '%s', '%s', %d, %d, %d, %d, %d, '%s', '%s', '%s', '%s' , %d)]],
            msg.guid,msg.type,msg.gameid,msg.game_name,msg.phone_type,msg.money_type,msg.old_money,msg.new_money,msg.tax,msg.change_money,msg.ip,msg.id,msg.channel_id,msg.platform_id,msg.seniorpromoter)
    elseif msg.guid < 0 then --机器人日志记录到另一张同样的表里
        sql = string.format([[
            INSERT INTO `log`.`t_log_money_tj_robot` (`guid`, `type`, `gameid`, `game_name`,`phone_type`, `money_type`, `old_money`, `new_money`, `tax`, `change_money`, `ip`, `id`, `channel_id`, `platform_id` )
            VALUES (%d, %d, %d, '%s', '%s', %d, %d, %d, %d, %d, %d, '%s', '%s', '%s', '%s' )]],
            msg.guid,msg.type,msg.gameid,msg.game_name,msg.phone_type,msg.money_type,msg.old_money,msg.new_money,msg.tax,msg.change_money,msg.ip,msg.id,msg.channel_id,msg.platform_id)
    end

    log.info("sql [%s]" , sql)
    dbopt.log:query(sql)
end

function on_sl_log_game(msg)
    log.info("...................... on_sl_log_game")
    local sql = string.format([[
        INSERT INTO `log`.`t_log_game_tj` (`id`, `type`, `log`, `ext_id`, `start_time`,`end_time`)
        VALUES ('%s', '%s', '%s','%s', FROM_UNIXTIME(%d), FROM_UNIXTIME(%d));
        ]],
        msg.playid,msg.type,json.encode(msg.log),msg.ext_id,msg.starttime,msg.endtime)
    local ret = dbopt.log:query(sql)
    if ret.errno then
        log.error(ret.err)
    end

    local players_sql = {}
    for _,p in pairs(msg.log.players) do
        table.insert(players_sql,string.format("('%s',%d,%d)",msg.playid,msg.log.table_id,p.guid))
    end

    ret = dbopt.log:query("INSERT INTO `t_log_round`(round,table_id,guid) VALUES"..table.concat(players_sql,",")..";")
    if ret.errno then
        log.error(ret.err)
    end
end

function on_sl_robot_log_money(msg)
	log.info("...................... on_sl_robot_log_money")
    dbopt.log:query([[
        INSERT INTO `log`.`t_log_robot_money_tj` (`guid`, `is_banker`, `winorlose`,`gameid`, `game_name`,`old_money`, `new_money`, `tax`, `money_change`, `id`)
        VALUES (%d, %d, %d, %d, '%s', %d, %d, %d, %d, '%s')]],
        msg.guid,msg.isbanker,msg.winorlose,msg.gameid,msg.game_name,msg.old_money,msg.new_money,msg.tax,msg.money_change,msg.id)
end

function  on_SD_SaveCollapsePlayerLog(msg)
    local sql = string.format([[
        INSERT INTO `t_log_bankrupt`(`day`,`guid`,`times_bkt`,`bag_id`,`plat_id`) VALUES('%s',%d,1,'%s','%s') ON DUPLICATE KEY UPDATE `times_bkt`=(`times_bkt`+1),`bag_id`=VALUES(`bag_id`),`plat_id`=VALUES(`plat_id`)]],
        os.date("%Y-%m-%d",os.time()),msg.guid,msg.channel_id,msg.platform_id)
    dbopt.log:query(sql)
    dbopt.game:query("UPDATE t_player SET is_collapse=1 WHERE guid=%d;",msg.guid)
end

function on_SD_LogProxyCostPlayerMoney(msg)
	dbopt.recharge:query("INSERT INTO \
			`t_agent_recharge_order`(`transfer_id`,`proxy_guid`,`player_guid`,`transfer_type`,`transfer_money`,`platform_id`,`channel_id`,`seniorpromoter`,`proxy_status`,`player_status`,`updated_at`) \
			VALUES('%s','%d','%d','%d','%d','%d','%d','%d','1','1',NOW())",
			msg.transfer_id,msg.proxy_guid,msg.player_guid,msg.transfer_type,msg.transfer_money,msg.platform_id,msg.channel_id,msg.promoter_id)
end

function on_ld_log_login(msg)
    log.info( "login step db.DL_VerifyAccountResult ok,guid=%d", msg.guid)
    local res = dbopt.account:query(
        "update t_account set login_time = NOW(),login_count = login_count + 1,last_login_ip = '%s' WHERE guid = %d;",
        msg.ip,msg.guid)
    if res.errno then
        log.error("on_ld_log_login update t_account info throw exception.[%d],[%s]",res.errno,res.err)
        return
    end

    res = dbopt.log:query(
        [[insert into t_log_login(guid,login_version,login_phone_type,login_ip,login_time,create_time,platform_id)
            values(%d,'%s','%s','%s',NOW(),NOW(),'%s');]],
        msg.guid,
        msg.version,
        msg.phone_type or "unkown",
        msg.ip,
        msg.platform_id or "")

    if res.errno then
        log.error("on_ld_log_login insert into t_log_login info throw exception.[%d],[%s]",res.errno,res.err)
        return
    end
end


