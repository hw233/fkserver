-- 日志消息处理

local pb = require "pb_files"
local log = require "log"
local json = require "cjson"
local dbopt = require "dbopt"
local enum = require "pb_enums"

-- 钱日志
function on_sd_log_money(msg)
	dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", msg)
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
            INSERT INTO `log`.`t_log_game_money` (`guid`, `type`, `gameid`, `game_name`,`money_id`, `old_money`, `new_money`, `change_money`, `round_id`, `platform_id')
            VALUES (%d, %d, %d, '%s',%d, %d, %d, %d, '%s', '%d')]],
            msg.guid,msg.type,msg.gameid,msg.game_name,msg.money_id,msg.old_money,msg.new_money,msg.change_money,msg.id,msg.platform_id or 0)
    elseif msg.guid < 0 then --机器人日志记录到另一张同样的表里
        sql = string.format([[
            INSERT INTO `log`.`t_log_game_money` (`guid`, `type`, `gameid`, `game_name`,`money_id`, `old_money`, `new_money`, `change_money`, `round_id`, `platform_id')
            VALUES (%d, %d, %d, '%s',%d, %d, %d, %d, '%s', '%d')]],
            msg.guid,msg.type,msg.gameid,msg.game_name,msg.money_id,msg.old_money,msg.new_money,msg.change_money,msg.round_id,msg.platform_id or 0)
    end

    log.info("sql [%s]" , sql)
    dbopt.log:query(sql)
end

function on_sd_log_ext_game_round_start(msg)
    local guids = msg.guids
    local round = msg.ext_round
    local table_id = msg.table_id
    local club = msg.club
    local template = msg.template
    local game_id = msg.game_id
    local game_name = msg.game_name

    local ret = dbopt.log:query([[
            INSERT INTO t_log_round(round,table_id,club,template,game_id,game_name,log,start_time,end_time,create_time) 
            VALUES('%s',%s,%s,%s,%s,'%s','',unix_timestamp(),unix_timestamp(),unix_timestamp());
        ]],round,table_id,club or 'NULL',template or "NULL",game_id or 'NULL',game_name or "")
    if ret.errno then
        log.error("INSERT INTO t_log_round error:%s:%s",ret.errno,ret.err)
        return
    end

    local values_sql = table.concat(
        table.series(guids,function(guid)
            return string.format("(%s,'%s',unix_timestamp())",guid,round)
        end),",")
    ret = dbopt.log:query("INSERT INTO t_log_player_round(guid,round,create_time) VALUES" .. values_sql .. ";")
    if ret.errno then
        log.error("INSERT INTO t_log_player_round error:%s:%s",ret.errno,ret.err)
        return
    end
end

function on_sd_log_ext_game_round_end(msg)
    local guids = msg.guids
    local round = msg.ext_round
    local table_id = msg.table_id
    local club = msg.club
    local log = msg.log

    json.encode_sparse_array(true)  
    local ret = dbopt.log:query([[
        UPDATE t_log_round SET end_time = unix_timestamp(),log = '%s' WHERE round = '%s';
    ]],log and json.encode(log) or "",round)
    if ret.errno then
        log.error("UPDATE t_log_round error:%s:%s",ret.errno,ret.err)
        return
    end
end

function on_sd_log_ext_game_round_player_join(msg)
    local guid = msg.guid
    local round = msg.ext_round
    local table_id = msg.table_id
    local club = msg.club
    local ret = dbopt.log:query([[
            INSERT INTO t_log_player_round(guid,round,create_time) VALUES(%s,'%s',unix_timestamp())
        ]],guid,round)
    if ret.errno then
        log.error("INSERT INTO t_log_player_round error:%s:%s",ret.errno,ret.err)
        return
    end
end

function on_sl_log_game(msg)
    log.info("...................... on_sl_log_game")
    json.encode_sparse_array(true)  
    local sql = string.format([[
        INSERT INTO `log`.`t_log_game` (`round_id`, `game_id`,`game_name`, `log`, `ext_round_id`, `start_time`,`end_time`,`created_time`)
        VALUES ('%s',%d, '%s', '%s','%s', %d, %d, %d);
        ]],
        msg.round_id,msg.game_id,msg.game_name,json.encode(msg.log),msg.ext_round_id,msg.starttime,msg.endtime,os.time())
    local ret = dbopt.log:query(sql)
    if ret.errno then
        log.error(ret.err)
    end
end

function on_sl_robot_log_money(msg)
	log.info("...................... on_sl_robot_log_money")
    dbopt.log:query([[
        INSERT INTO `log`.`t_log_game_money_robot` (`guid`, `is_banker`, `winorlose`,`gameid`, `game_name`,`old_money`, `new_money`,`money_change`, `round_id`)
        VALUES (%d, %d, %d, %d, '%s', %d, %d, %d, '%s')]],
        msg.guid,msg.isbanker,msg.winorlose,msg.gameid,msg.game_name,msg.old_money,msg.new_money,msg.money_change,msg.round_id)
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

function on_sd_log_logout(msg)

end

function on_sd_log_club_commission(msg)
    local parent = msg.parent
    local club = msg.club
    local commission = msg.commission
    local res = dbopt.log:query("INSERT INTO t_log_commission(club,money_id,commission,round_id) VALUES(%d,%d,%d,'%s')",
        club,msg.money_id,commission,msg.round_id)
    if res.errno then
        log.error("on_sd_log_club_commission insert into t_log_commission info throw exception.[%d],[%s]",res.errno,res.err)
        return
    end
end

function on_sd_log_recharge(msg)
    local sqls = {
        string.format("INSERT INTO t_log_recharge(source_id,target_id,type,operator,created_time) VALUES(%d,%d,%d,%d,%d);",
                msg.source_id,msg.target_id,msg.type,msg.operator,os.time()),
        string.format("SELECT LAST_INSERT_ID() AS id;")
    }

    log.dump(sqls)
    local res = dbopt.log:query(table.concat(sqls,"\n"))
    if res.errno then
        log.error("on_sd_log_recharge insert into t_log_recharge info throw exception.[%d],[%s]",res.errno,res.err)
        return
    end

    log.dump(res)

    return res[2][1].id
end

function on_sd_log_club_commission_contribution(msg)
    local parent = msg.parent
    local club = msg.club
    local commission = msg.commission
    local template =  msg.template
    if not parent or parent == 0 then
        return
    end

    local date_timestamp = math.floor(os.time() / 86400) * 86400
    local res = dbopt.log:query([[INSERT INTO t_log_club_commission_contribute(club_parent,club_son,commission,template,date)
        VALUES(%d,%d,%d,%d,%d)
        ON DUPLICATE KEY UPDATE commission = commission + %d;]],
        parent,club,commission,template,date_timestamp,commission)
    if res.errno then
        log.error("on_sd_log_club_commission INSERT INTO t_log_club_commission_contribute errno:%d,errstr:%s.",res.errno,res.err)
    end
end

function on_sd_log_player_commission(msg)
    local club = msg.club
    local guid = msg.guid
    local commission = msg.commission
    local round_id = msg.round_id
    local money_id = msg.money_id
    local res = dbopt.log:query("INSERT INTO t_log_player_commission(club,guid,money_id,commission,round_id,create_time) VALUES(%d,%d,%d,%d,'%s',%d)",
        club,guid,money_id,commission,round_id,os.time())
    if res.errno then
        log.error("on_sd_log_player_commission insert into t_log_player_commission info throw exception.[%d],[%s]",res.errno,res.err)
        return
    end

    return true
end

function on_sd_log_player_commission_contribute(msg)
    local parent = msg.parent
    local guid = msg.guid
    local commission = msg.commission
    local template =  msg.template
    local club = msg.club

    if not parent or parent == 0 then
        log.error("on_sd_log_player_commission_contribute parent is ilegal.")
        return
    end

    local res = dbopt.log:query([[
        INSERT INTO t_log_player_commission_contribute(parent,son,commission,template,club,create_time)
        VALUES(%s,%s,%s,%s,%s,%s)]],
        parent,guid,commission or 0,template or "NULL",club,os.time())
    if res.errno then
        log.error("on_sd_log_player_commission_contribute INSERT INTO t_log_player_commission_contribute errno:%d,errstr:%s.",res.errno,res.err)
    end
end

function on_sd_request_share_param(sid)
    if not sid or sid == "" then
        log.error("on_sd_request_share_param got nil sid!")
        return
    end

    local res = dbopt.log:query([[SELECT s.* FROM 
        t_log_share_code  s
        LEFT JOIN
        t_log_install_trace t
        ON t.shareId = s.sid
        WHERE s.sid = "%s" OR t.traceId = "%s";]],sid,sid)
    if res.errno then
        log.error("on_sd_request_share_param SELECT t_log_share_code errno:%d,errstr:%s.",res.errno,res.err)
        return
    end

    return res[1]
end

function on_sd_query_player_statistics(guids,club,getter,start_date,limit)
    if not guids or #guids == 0 then
        return {}
    end

    limit = limit or 2

    start_date =  start_date or (math.floor(os.time() / 86400) - 1) * 86400

    local where_sql = table.concat(guids,",")

    local logs = dbopt.log:query([[
        SELECT cou.guid,count play_count,commission,cou.date 
        FROM 
            (
                SELECT guid,club,count,date FROM t_log_team_daily_play_count
                WHERE guid in (%s) AND club = %s
            ) cou
        JOIN 
            (
                SELECT son guid,club,SUM(commission) commission,date 
                FROM t_log_player_daily_commission_contribute
                WHERE son in (%s) AND club = %s and parent = %s
                GROUP BY son,club,date
            ) com
        ON cou.guid = com.guid AND cou.club = com.club AND cou.date = com.date
        WHERE cou.date >= %s
        ORDER BY cou.date DESC
        LIMIT %s
    ]],where_sql,club,where_sql,club,getter,start_date,limit)

    return logs
end

function on_sd_log_club_action_msg(msg)
    local operator = msg.operator
    local club = msg.club
    local actionmsg = msg.msg
    local type = msg.type

    local res = dbopt.log:query([[
            INSERT INTO t_log_club_msg(club,operator,type,content,created_time)
            VALUES(%s,%s,%s,'%s',%s)
        ]],club,operator,type,actionmsg and json.encode(actionmsg) or "",os.time())

    if res.errno then
        log.error("on_sd_log_club_action_msg error:%s",res.err)
    end
end