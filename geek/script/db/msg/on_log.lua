-- 日志消息处理

local pb = require "pb_files"
local log = require "log"

require "db.net_func"
local send2center_pb = send2center_pb
local send2game_pb = send2game_pb

local dbopt = require "dbopt"
local db_execute = db_execute
local db_execute_query = db_execute_query
local db_fmt_query = db_fmt_query

local LOG_MONEY_OPT_TYPE_RESET_ACCOUNT = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_RESET_ACCOUNT")

-- 钱日志
function on_ld_log_money(login_id,msg)
    dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", msg)
end

-- 钱日志
function on_sd_log_money( msg)
	dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", msg)
	if msg.opt_type == LOG_MONEY_OPT_TYPE_RESET_ACCOUNT then
        local sql = string.format("update t_player set bind_gold = %d , bind_time = current_timestamp where guid = %d", msg.new_money - msg.old_money ,msg.guid )
        dbopt.game:query(sql)
    end
	--print ("...................... on_sd_log_money")
end

--下注流水日志
function on_sd_log_bet_flow(msg)
    dbopt.proxy:query("call update_bet_flow(%d,%d)",msg.guid,msg.money)
end

function save_error_sql(str_sql)
    local sqlT = string.gsub(str_sql,"'","''")
    dbopt.log:query("INSERT INTO `log`.`t_erro_sql` (`sql`) VALUES ('%s')",sqlT)
end

function on_sl_channel_invite_tax( msg)
    --print("ChannelInviteTaxes step 3--------------------------------")
    dbopt.log:query([[
        INSERT INTO `log`.`t_log_channel_invite_tax` (`guid`, `guid_contribute`, `val`, `time`)
        VALUES (%d, %d, %d, NOW())]],
    msg.guid_invite,msg.guid,msg.val)
    dbopt.game:query([[
        INSERT INTO `game`.`t_channel_invite_tax` (`guid`, `val`)
        VALUES (%d, %d)]],
    msg.guid_invite,msg.val)
end

function on_sl_log_money( msg)
    --print ("...................... on_sl_log_money")
    local table_name = "t_log_money_tj"

    local sql = string.format([[
    INSERT INTO `log`.`%s` (`guid`, `type`, `gameid`, `game_name`,`phone_type`, `old_money`, `new_money`, `tax`, `get_bonus_money`, `to_bonus_money`, `change_money`, `ip`, `id`, `channel_id`, `platform_id` , `seniorpromoter`)
    VALUES (%d, %d, %d, '%s', '%s', %d, %d, %d, %d, %d, %d, '%s', '%s', '%s', '%s' , %d)]],
    table_name,msg.guid,msg.type,msg.gameid,msg.game_name,msg.phone_type,msg.old_money,msg.new_money,msg.tax,msg.get_bonus_money,msg.to_bonus_money,msg.change_money,msg.ip,msg.id,msg.channel_id,msg.platform_id,msg.seniorpromoter)

    --机器人日志记录到另一张同样的表里
    if msg.guid < 0 then
        table_name = "t_log_money_tj_robot"

        sql = string.format([[
        INSERT INTO `log`.`%s` (`guid`, `type`, `gameid`, `game_name`,`phone_type`, `old_money`, `new_money`, `tax`, `get_bonus_money`, `to_bonus_money`, `change_money`, `ip`, `id`, `channel_id`, `platform_id` )
        VALUES (%d, %d, %d, '%s', '%s', %d, %d, %d, %d, %d, %d, '%s', '%s', '%s', '%s' )]],
        table_name,msg.guid,msg.type,msg.gameid,msg.game_name,msg.phone_type,msg.old_money,msg.new_money,msg.tax,msg.get_bonus_money,msg.to_bonus_money,msg.change_money,msg.ip,msg.id,msg.channel_id,msg.platform_id)
    end

    log.info("sql [%s]" , sql)
    dbopt.log:query(sql)
end

function on_sl_log_Game(msg)
    --print ("...................... on_sl_log_Game")
    dbopt.log:query([[
        INSERT INTO `log`.`t_log_game_tj` (`id`, `type`, `log`, `start_time`,`end_time`)
        VALUES ('%s', '%s', '%s', FROM_UNIXTIME(%d), FROM_UNIXTIME(%d))]],
        msg.playid,msg.type,msg.log,msg.starttime,msg.endtime)
end

function on_sl_robot_log_money(msg)
	--print ("...................... on_sl_robot_log_money")
    dbopt.log:query([[
        INSERT INTO `log`.`t_log_robot_money_tj` (`guid`, `is_banker`, `winorlose`,`gameid`, `game_name`,`old_money`, `new_money`, `tax`, `money_change`, `id`)
        VALUES (%d, %d, %d, %d, '%s', %d, %d, %d, %d, '%s')]],
        msg.guid,msg.isbanker,msg.winorlose,msg.gameid,msg.game_name,msg.old_money,msg.new_money,msg.tax,msg.money_change,msg.id)
end

function  on_SD_SaveCollapsePlayerLog(msg)
    --print("----------------------------------------------->on_SD_SaveCollapsePlayerLog")
    --INSERT INTO `t_log_bankrupt`(`day`,`guid`,`times_bkt`,`bag_id`,`plat_id`) VALUES('2017-08-12',1,1,'124','0') ON DUPLICATE KEY UPDATE `times_bkt`=(`times_bkt`+1),`bag_id`=VALUES(`bag_id`),`plat_id`=VALUES(`plat_id`)
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
end


