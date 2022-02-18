-- 日志消息处理
local log = require "log"
local json = require "json"
local dbopt = require "dbopt"
local enum = require "pb_enums"
local gutil = require "util"

-- 钱日志
function on_sd_log_money(msg)
	dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", msg)
	log.info("...................... on_sd_log_money")
end

--下注流水日志
function on_sd_log_bet_flow(msg)
    dbopt.proxy:query("call update_bet_flow(%d,%d)",msg.guid,msg.money)
end

function on_sd_log_game_money( msg)
    if msg.guid >= 0 then
        dbopt.log:query([[
            INSERT INTO `log`.`t_log_game_money` (`guid`, `type`, `gameid`, `game_name`,`money_id`, `old_money`, `new_money`, `change_money`, `round_id`, `platform_id')
            VALUES (%d, %d, %d, '%s',%d, %d, %d, %d, '%s', '%d')]],
            msg.guid,msg.type,msg.gameid,msg.game_name,msg.money_id,msg.old_money,msg.new_money,msg.change_money,msg.id,msg.platform_id or 0)
    elseif msg.guid < 0 then --机器人日志记录到另一张同样的表里
        dbopt.log:query([[
            INSERT INTO `log`.`t_log_game_money` (`guid`, `type`, `gameid`, `game_name`,`money_id`, `old_money`, `new_money`, `change_money`, `round_id`, `platform_id')
            VALUES (%d, %d, %d, '%s',%d, %d, %d, %d, '%s', '%d')]],
            msg.guid,msg.type,msg.gameid,msg.game_name,msg.money_id,msg.old_money,msg.new_money,msg.change_money,msg.round_id,msg.platform_id or 0)
    end
end

function on_sd_log_ext_game_round_start(msg)
    local guids = msg.guids
    local round = msg.ext_round
    local table_id = msg.table_id
    local club = msg.club
    local template = msg.template
    local game_id = msg.game_id
    local game_name = msg.game_name
    local rule = msg.rule

    json.encode_sparse_array(true)
    local ret = dbopt.log:query([[
            INSERT INTO t_log_round(round,table_id,club,template,game_id,game_name,rule,start_time,end_time,create_time) 
            VALUES('%s',%s,%s,%s,%s,'%s','%s',%s,%s,%s);
        ]],round,table_id,club or 'NULL',template or "NULL",game_id or 'NULL',game_name or "",
            rule and json.encode(rule) or "",
            os.time(),os.time(),os.time()
        )
    if ret.errno then
        log.error("INSERT INTO t_log_round error:%s:%s",ret.errno,ret.err)
        return
    end

    local values_sql = table.concat(
        table.series(guids,function(guid)
            return string.format("(%s,'%s',%s)",guid,round,os.time())
        end),",")
    ret = dbopt.log:query("INSERT IGNORE INTO t_log_player_round(guid,round,create_time) VALUES" .. values_sql .. ";")
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
        UPDATE t_log_round SET end_time = %s,log = '%s' WHERE round = '%s';
    ]],os.time(),log and json.encode(log) or "",round)
    if ret.errno then
        log.error("UPDATE t_log_round error:%s:%s",ret.errno,ret.err)
        return
    end

    for guid,money in pairs(log.balance or {}) do
        local ret = dbopt.log:query([[
          INSERT INTO t_log_round_money(round,guid,money,create_time)
          VALUES('%s',%s,%s,%s)  
        ]],round,guid,money,os.time())
        if ret.errno then
            log.error('INSERT INTO t_log_round_money error:%s',ret.err)
        end
    end
end

function on_sd_log_ext_game_round(msg)
    local guids = msg.guids
    local round = msg.ext_round
    local table_id = msg.table_id
    local club = msg.club
    local template = msg.template
    local game_id = msg.game_id
    local game_name = msg.game_name
    local rule = msg.rule
    local round_log = msg.log
    local balance = round_log.balance
    local start_time = msg.start_time
    local end_time = msg.end_time

    log.dump(msg)
    
    local now = os.time()
    local ret = dbopt.log:query([[
            INSERT INTO t_log_round(round,table_id,club,template,game_id,game_name,rule,log,start_time,end_time,create_time) 
            VALUES('%s',%s,%s,%s,%s,'%s','%s','%s',%s,%s,UNIX_TIMESTAMP());
            ]],
            round,
            table_id,
            club or 'NULL',
            template or "NULL",
            game_id or 'NULL',
            game_name or "",
            rule and json.encode(rule) or "",
            round_log and json.encode(round_log) or "",
            start_time,end_time
        )
    if ret.errno then
        log.error("INSERT INTO t_log_round error:%s:%s",ret.errno,ret.err)
        return
    end

    local player_round_sqls = table.series(guids or {},function(guid)
        return {
            "INSERT IGNORE INTO t_log_player_round(guid,round,create_time) VALUES(%s,'%s',%s);",
            guid,round,start_time
        }
    end)

    ret = dbopt.log:batchquery(player_round_sqls)
    if ret.errno then
        log.error("INSERT INTO t_log_player_round error:%s:%s",ret.errno,ret.err)
        return
    end

    local round_money_sqls = table.series(balance or {},function(money,guid)
        return {
            "INSERT INTO t_log_round_money(round,guid,money,create_time) VALUES('%s',%s,%s,%s);",
            round,guid,money,now
        }
    end)

    local ret = dbopt.log:batchquery(round_money_sqls)
    if ret.errno then
        log.error('INSERT INTO t_log_round_money error:%s',ret.err)
    end
end

function on_sd_log_ext_game_round_player_join(msg)
    local guid = msg.guid
    local round = msg.ext_round
    local ret = dbopt.log:query(
        [[INSERT IGNORE INTO t_log_player_round(guid,round,create_time) VALUES(%s,'%s',%s);]],
        guid,round,os.time()
    )
    if ret.errno then
        log.error("INSERT INTO t_log_player_round error:%s:%s",ret.errno,ret.err)
        return
    end
end

function on_sl_log_game(msg)
    log.info("...................... on_sl_log_game")
    local gamelog = msg.log
    local round_id = msg.round_id
    json.encode_sparse_array(true)  
    local ret = dbopt.log:query([[
        INSERT INTO `log`.`t_log_game` (`round_id`, `game_id`,`game_name`, `log`, `ext_round_id`, `start_time`,`end_time`,`created_time`)
        VALUES ('%s',%d, '%s', '%s','%s', %d, %d, %d);
        ]],
        round_id,msg.game_id,msg.game_name,json.encode(msg.log),msg.ext_round_id,msg.starttime,msg.endtime,os.time())
    if ret.errno then
        log.error("INSERT INTO t_log_game error:%s",ret.err)
    end

    local sqls = table.series(gamelog.players or {},function(p,chair)
        return {
            [[INSERT IGNORE INTO t_log_player_game(guid,chair_id,round_id,created_time) VALUES(%s,%s,'%s',%s)]],
            p.guid,
            p.chair_id or chair,
            round_id,
            os.time()
        }
    end)

    ret = dbopt.log:batchquery(sqls)
    if ret.errno then
        log.error("INSERT INTO t_log_player_game error:%s",ret.err)
    end
end

function on_sl_robot_log_money(msg)
	log.info("...................... on_sl_robot_log_money")
    dbopt.log:query([[
        INSERT INTO `log`.`t_log_game_money_robot` (`guid`, `is_banker`, `winorlose`,`gameid`, `game_name`,`old_money`, `new_money`,`money_change`, `round_id`)
        VALUES (%d, %d, %d, %d, '%s', %d, %d, %d, '%s')]],
        msg.guid,msg.isbanker,msg.winorlose,msg.gameid,msg.game_name,msg.old_money,msg.new_money,msg.money_change,msg.round_id)
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
        [[insert into t_log_login(guid,login_version,login_phone_type,login_ip,login_time,create_time,platform_id,login_imei)
            values(%d,'%s','%s','%s',NOW(),NOW(),'%s','%s');]],
        msg.guid,
        msg.version,
        msg.phone_type or "unkown",
        msg.ip,
        msg.platform_id or "",
        msg.imei or "")

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
    local res = dbopt.log:query([[
            INSERT INTO t_log_recharge(source_id,target_id,type,operator,money,comment,created_time) VALUES(%d,%d,%d,%d,%s,'%s',%d);
        ]],
        msg.source_id,msg.target_id,msg.type,msg.operator,msg.money or "NULL",msg.comment or "",os.time()
    )
    if res.errno then
        log.error("on_sd_log_recharge insert into t_log_recharge info throw exception.[%d],[%s]",res.errno,res.err)
        return
    end

    return res.insert_id
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
        club,guid,money_id,commission,round_id or "",os.time())
    if res.errno then
        log.error("on_sd_log_player_commission insert into t_log_player_commission info throw exception.[%d],[%s]",res.errno,res.err)
        return
    end

    res = dbopt.game:query([[
        INSERT INTO t_player_commission(club,guid,money_id,commission)
        VALUES(%s,%s,%s,%s)
        ON DUPLICATE KEY UPDATE commission = commission + VALUES(commission);
        ]],club,guid,money_id,commission or 0)
    if res.errno then
        log.error("on_sd_log_player_commission update t_player_commission throw exception.[%d],[%s]",res.errno,res.err)
        return
    end

    return true
end

function on_sd_log_player_commission_contributes(msg)
    local contributions = msg.contributions
    local template =  msg.template
    local club = msg.club

    if not contributions or table.nums(contributions) == 0 or not club or club == 0 then
        log.error("on_sd_log_player_commission_contributes contributions is ilegal.")
        return
    end

    local values = table.series(contributions,function(s)
        local parent = s.parent
        local guid = s.son
        local commission = s.commission
        return string.format("(%s,%s,%s,%s,%s,%s)",parent,guid,commission or 0,template or "NULL",club,os.time())
    end)

    local res = dbopt.log:query([[
        INSERT INTO t_log_player_commission_contribute(parent,son,commission,template,club,create_time)
        VALUES
        ]] .. table.concat(values,","))
    if res.errno then
        log.error("on_sd_log_player_commission_contributes INSERT INTO t_log_player_commission_contribute errno:%d,errstr:%s.",res.errno,res.err)
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

function on_sd_query_player_statistics(guids,club,getter,start_date)
    if not guids or #guids == 0 then
        return {}
    end

    start_date =  start_date or gutil.timestamp_date(os.time() - gutil.day_seconds())

    local where_sql = table.concat(guids,",")

    local logs = dbopt.log:query([[
        SELECT cou.guid,count play_count,commission,cou.date 
        FROM    
            (
                SELECT guid,club,count,date FROM t_log_team_daily_play_count
                WHERE guid in (%s) AND club = %s
            ) cou
        LEFT JOIN 
            (
                SELECT son guid,club,SUM(commission) commission,date 
                FROM t_log_player_daily_commission_contribute
                WHERE son in (%s) AND club = %s and parent = %s
                GROUP BY son,club,date
            ) com
        ON cou.guid = com.guid AND cou.club = com.club AND cou.date = com.date
        WHERE cou.date >= %s
        ORDER BY cou.date DESC
    ]],where_sql,club,where_sql,club,getter,start_date)

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