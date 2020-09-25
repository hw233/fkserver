
local log = require "log"

local dbopt = require "dbopt"



local day_seconds = 60 * 60 * 24

local player_statistics = {}

local log_create_table_sql = {
    [[USE log;]],
    [[
        CREATE TABLE IF NOT EXISTS t_log_player_daily_play_count(
            id INT(8) NOT NULL AUTO_INCREMENT,
            guid INT(4) NOT NULL,
            club INT(8),
            count INT(4) NOT NULL,
            date INT(8) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(guid,club,date)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS t_log_player_daily_commission_contribute(
            id INT(8) NOT NULL AUTO_INCREMENT,
            parent INT(4) NOT NULL,
            son INT(4) NOT NULL,
            club INT(8),
            template INT(4),
            commission INT(8) NOT NULL,
            date INT(8) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(parent,son,club,date)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS t_log_team_daily_play_count(
            id INT(8) NOT NULL AUTO_INCREMENT,
            guid INT(4) NOT NULL,
            club INT(8),
            count INT(4) NOT NULL,
            date INT(8) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(guid,club,date)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    ]],
}

local game_create_table_sql = {
    [[
        CREATE TABLE IF NOT EXISTS t_team_player_count(
            id INT(8) NOT NULL AUTO_INCREMENT,
            guid INT(4) NOT NULL,
            club INT(8),
            count INT(4) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(guid,club)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS t_team_money(
            id INT(8) NOT NULL AUTO_INCREMENT,
            guid INT(4) NOT NULL,
            club INT(8),
            money INT(4) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(guid,club)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    ]],
}

local function create_table()
    local res = dbopt.log:query(table.concat(log_create_table_sql,""))
    if res.errno then
        log.error("create log table error,%s",res.err)
    end

    local res = dbopt.game:query(table.concat(game_create_table_sql,""))
    if res.errno then
        log.error("create game table error,%s",res.err)
    end
end

local function player_play_count()
    local today = math.floor(os.time() / day_seconds)
    local res = dbopt.log:query([[
            USE log;
            REPLACE INTO t_log_player_daily_play_count(guid,club,count,date)
            SELECT pr.guid,r.club,COUNT(DISTINCT(r.round)) count,pr.create_time div 86400 * 86400 date FROM 
                log.t_log_player_round pr
            LEFT JOIN
                log.t_log_round r
            ON pr.round = r.round
            WHERE pr.create_time > %s AND pr.create_time <= %s
            GROUP BY r.club,pr.guid,pr.create_time div 86400 * 86400;
        ]],today * day_seconds,(today + 1) * day_seconds)
    if res.errno then
        log.error("do player statistics task player_count error,%s",res.err)
    end
end

local function get_parents(teams)
    if teams and #teams > 0 then
        local where_sql = table.concat(table.series(teams,function(m)
            return string.format("(club = %s AND guid = %s)",m.club,m.guid)
        end)," OR ")
        local sql = string.format([[
            SELECT club,partner guid FROM t_partner_member
            WHERE %s
        ]],where_sql)
        local res = dbopt.game:query(sql)
        if res.errno then
            log.error(res.err)
        end
        return res
    end

    local res = dbopt.game:query([[
        SELECT l.*
        FROM 
            t_partner_member l
        LEFT JOIN
            t_partner_member r
        ON l.club = r.club AND l.guid = r.partner
        WHERE r.club IS NULL
    ]])
    if res.errno then
        log.error(res.err)
    end

    return res
end


local function team_play_count()
    local today = math.floor(os.time() / day_seconds) * day_seconds 
    local res = dbopt.log:query([[
        DELETE FROM t_log_team_daily_play_count WHERE date >= %s
    ]],today)

    if res.errno then
        log.error("team_play_count delete today t_log_team_daily_play_count error:%s",log.err)
    end

    local function start_members()
        local res = dbopt.game:query([[
            SELECT l.* FROM 
                game.t_partner_member l
            LEFT JOIN
                game.t_partner_member r
            ON l.club = r.club AND l.guid = r.partner
            WHERE r.club IS NULL
        ]])
        if res.errno then
            log.error(res.err)
        end
        return res
    end

    local function get_parents(mems)
        if not mems or #mems == 0 then return {} end

        local where_sql = table.series(mems,function(m)
            return string.format("(club = %s AND guid = %s)",m.club,m.partner)
        end)
        local res = dbopt.game:query([[
                SELECT * FROM t_partner_member WHERE (%s)
            ]],table.concat(where_sql," OR "))
        if res.errno then
            log.error(res.err)
        end

        return res
    end

    local function get_self_counts(teams)
        if #teams == 0 then return {} end

        local where_sql = table.series(teams,function(m)
            return string.format("(club = %s AND guid = %s)",m.club,m.guid)
        end)
        local res = dbopt.log:query([[
            SELECT * FROM t_log_player_daily_play_count
            WHERE date >= %s AND (%s)
        ]],today,table.concat(where_sql," OR "))
        if res.errno then
            log.error(res.err)
        end

        return res
    end

    local function get_mems_counts(mems)
        if #mems == 0 then return {} end

        local where_sql = table.series(mems,function(m)
            return string.format("(club = %s AND guid = %s)",m.club,m.guid)
        end)
        local res =  dbopt.log:query([[
            SELECT * FROM t_log_player_daily_play_count
            WHERE date >= %s AND (%s)
        ]],today,table.concat(where_sql," OR "))
        if res.errno then
            log.error(res.err)
        end

        return res
    end

    local function update_self_count(counts)
        if #counts == 0 then return end

        local value_sql = table.series(counts,function(c)
            return string.format("(%s,%s,%s,%s)",c.club,c.guid,c.count,c.date)
        end)

        local res = dbopt.log:query([[
            INSERT INTO t_log_team_daily_play_count(club,guid,count,date)
            VALUES %s 
            ON DUPLICATE KEY UPDATE count = VALUES(count) + count
        ]],table.concat(value_sql,","))
        if res.errno then
            log.error(res.err)
        end
    end

    local function update_parent_count(counts)
        if #counts == 0 then return end

        local value_sql = table.series(counts,function(c)
            return string.format("(%s,%s,%s,%s)",c.club,c.partner,c.count,c.date)
        end)

        local res = dbopt.log:query([[
            INSERT INTO t_log_team_daily_play_count(club,guid,count,date)
            VALUES %s 
            ON DUPLICATE KEY UPDATE count = VALUES(count) + count
        ]],table.concat(value_sql,","))

        if res.errno then
            log.error(res.err)
        end
    end

    local mems = start_members()

    while #mems > 0 do
        local self_counts = get_self_counts(mems)

        update_self_count(self_counts)

        mems = table.join(mems,self_counts,function(l,r)
            return l.club == r.club and r.guid == l.guid
        end)

        update_parent_count(mems)

        mems = get_parents(mems)
    end
end

local function team_player_count()
    local res = dbopt.game:query([[
        DELETE FROM t_team_player_count
    ]])

    if res.errno then
        log.error("team_play_count delete t_team_player_count error:%s",log.err)
    end

    local function update_directly_son_counts()
        local res = dbopt.game:query([[
            INSERT INTO t_team_player_count(club,guid,count)
            SELECT club,partner guid,COUNT(guid) count FROM t_partner_member
            GROUP BY club,partner
        ]])

        if res.errno then
            log.error(res.err)
        end
    end

    local function update_parents_count(teams)
        if #teams == 0 then return end

        local where_sql = table.concat(table.series(teams,function(t)
            return string.format("(guid = %s AND club = %s)",t.guid,t.club)
        end)," OR ")

        local res = dbopt.game:query([[
            REPLACE INTO t_team_player_count(club,guid,count)
            (
                SELECT mc.club,mc.guid,mc.count + pc.count count 
                FROM 
                    t_team_player_count pc
                JOIN
                (
                    SELECT m.club,m.partner guid,count
                    FROM 
                        t_team_player_count c
                    JOIN
                    (
                        SELECT club,guid,partner FROM t_partner_member
                        WHERE %s
                    ) m
                    ON c.club = m.club AND c.guid = m.guid
                ) mc
                ON pc.club = mc.club AND pc.guid = mc.guid
            )
        ]],where_sql)

        if res.errno then
            log.error(res.err)
        end
    end

    update_directly_son_counts()
    local teams = get_parents(get_parents())
    while #teams > 0 do
        update_parents_count(teams)
        teams = get_parents(teams)
    end
end

local function team_money()
    local res = dbopt.game:query([[
        DELETE FROM t_team_money
    ]])

    if res.errno then
        log.error("team_money delete t_team_player_count error:%s",log.err)
    end

    local function update_directly_son_money()
        local res = dbopt.game:query([[
            INSERT INTO t_team_money(club,guid,money)
            SELECT p.club,p.partner guid,SUM(money) money FROM 
                t_player_money m
            LEFT JOIN
                t_club_money_type mt
            ON m.money_id = mt.money_id
            JOIN
                t_partner_member p
            ON p.guid = m.guid AND mt.club = p.club
            GROUP BY p.club,p.partner
        ]])

        if res.errno then
            log.error(res.err)
        end
    end

    local function update_parents_money(teams)
        if #teams == 0 then return end

        local where_sql = table.concat(table.series(teams,function(t)
            return string.format("(guid = %s AND club = %s)",t.guid,t.club)
        end)," OR ")

        local res = dbopt.game:query([[
            REPLACE INTO t_team_money(club,guid,money)
            (
                SELECT tm.club,tm.guid,(tm.money + pm.money) money 
                FROM 
                    t_team_money tm
                JOIN
                (
                    SELECT m.club,p.partner guid,money
                    FROM
                        t_team_money m
                    JOIN
                    (
                        SELECT club,guid,partner FROM t_partner_member
                        WHERE %s
                    ) p
                    ON m.club = p.club AND m.guid = p.guid
                ) pm
                ON pm.club = tm.club AND pm.guid = tm.guid
            )
        ]],where_sql,where_sql)

        if res.errno then
            log.error(res.err)
        end
    end

    update_directly_son_money()
    local teams = get_parents(get_parents())
    while #teams > 0 do
        update_parents_money(teams)
        teams = get_parents(teams)
    end
end

local function player_commission_contribute()
    local today = math.floor(os.time() / day_seconds)
    local res = dbopt.log:query([[
            USE log;
            REPLACE INTO log.t_log_player_daily_commission_contribute(parent,son,commission,template,club,date)
            SELECT parent,son,SUM(commission) commission,template,club,create_time div 86400 * 86400 date 
            FROM log.t_log_player_commission_contribute
            WHERE create_time > %s AND create_time <= %s
            GROUP BY parent,son,template,club,create_time div 86400 * 86400;
        ]],today * day_seconds,(today + 1) * day_seconds)

    if res.errno then
        log.error("do player statistics task player_commission_contribute error,%s",res.err)
    end
end

local function task(dbconf)
    log.info("do player statistics task ...")
    os.execute(string.format(
        "python3 ./geek/script/statistics/player.py host %s port %s user %s password %s",
        dbconf.host,
        dbconf.port,
        dbconf.user,
        dbconf.password
    ))
    log.info("do player statistics end")
end

function player_statistics.setup()
    create_table()
end

function player_statistics.task(dbconf)
    task(dbconf)
end


return player_statistics