
local log = require "log"

local dbopt = require "dbopt"

local log_create_table_sql = [[
    USE log;
    
    CREATE TABLE IF NOT EXISTS t_log_player_daily_play_count(
        id INT(8) NOT NULL AUTO_INCREMENT,
        guid INT(4) NOT NULL,
        club INT(8),
        game_id INT(4) NOT NULL,
        count INT(4) NOT NULL,
        date INT(8) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE(guid,club,date,game_id)
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;

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
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;

    CREATE TABLE IF NOT EXISTS t_log_team_daily_play_count(
        id INT(8) NOT NULL AUTO_INCREMENT,
        guid INT(4) NOT NULL,
        club INT(8),
        game_id INT(4) NOT NULL,
        count INT(4) NOT NULL,
        date INT(8) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE(guid,club,date,game_id)
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;

    CREATE TABLE IF NOT EXISTS t_log_player_daily_win_lose(
        id INT(8) NOT NULL AUTO_INCREMENT,
        guid INT(4) NOT NULL,
        club INT(8),
        game_id INT(4) NOT NULL,
        money INT(4) NOT NULL,
        date INT(8) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE(guid,club,date,game_id)
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;

    CREATE TABLE IF NOT EXISTS t_log_player_daily_big_win_count(
        id INT(8) NOT NULL AUTO_INCREMENT,
        guid INT(4) NOT NULL,
        club INT(8),
        game_id INT(4) NOT NULL,
        count INT(4) NOT NULL,
        date INT(8) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE(guid,club,date,game_id)
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;
    
    CREATE TABLE IF NOT EXISTS t_log_coin_hour_change(
        id INT(8) NOT NULL AUTO_INCREMENT,
        money_id INT(4),
        reason INT(4) NOT NULL,
        amount INT(4) NOT NULL,
        time INT(8) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE(money_id,time,reason)
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;

    CREATE TABLE IF NOT EXISTS t_log_club_coin_hour_change(
        id INT(8) NOT NULL AUTO_INCREMENT,
        money_id INT(4) NOT NULL,
        reason INT(4) NOT NULL,
        club INT(4),
        game_id INT(4),
        amount INT(4) NOT NULL,
        time INT(8) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE(money_id,reason,game_id,club,time)
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;
]]

local game_create_table_sql = [[
    USE game;

    CREATE TABLE IF NOT EXISTS t_team_player_count(
        id INT(8) NOT NULL AUTO_INCREMENT,
        guid INT(4) NOT NULL,
        club INT(8),
        count INT(4) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE(guid,club)
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;

    CREATE TABLE IF NOT EXISTS t_team_money(
        id INT(8) NOT NULL AUTO_INCREMENT,
        guid INT(4) NOT NULL,
        club INT(8),
        money INT(4) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE(guid,club)
    )ENGINE=MyISAM DEFAULT CHARSET=UTF8;
]]

local function create_table()
    local res = dbopt.log:query(log_create_table_sql)
    if res.errno then
        log.error("create log table error,%s",res.err)
    end

    local res = dbopt.game:query(game_create_table_sql)
    if res.errno then
        log.error("create game table error,%s",res.err)
    end
end

return create_table