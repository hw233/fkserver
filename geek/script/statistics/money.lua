
local dbopt = require "dbopt"
local timermgr = require "timermgr"
local log = require "log"
local skynet = require "skynet"
local logdb = dbopt.log
local string = string

local offset = 15
local loopinterval = 5 * 60

local function coin_hour_change()
	local now_timestamp = os.time() - offset
    local hour = math.floor(now_timestamp / 3600) * 3600 * 1000
    local next_hour = (math.floor(now_timestamp / 3600) + 1) * 3600 * 1000
    local sql = string.format([[
        INSERT INTO t_log_coin_hour_change(money_id,reason,amount,time)
        SELECT money_id,reason,SUM(delta_money) amount,time FROM 
        (
            SELECT money_id,reason,new_money - old_money delta_money,created_time DIV (3600 * 1000) * 3600 time 
            FROM t_log_money
            WHERE created_time >= %s AND created_time < %s 
        ) d
        GROUP BY money_id,reason,time
        ON DUPLICATE KEY UPDATE amount = VALUES(amount);
    ]],hour,next_hour)
	local res = logdb:query(sql)
    if res.errno then
        log.error("%s",res.err)
    end
end

local function club_room_card_hour_cost()
	local now_timestamp = os.time() - offset
    local hour = math.floor(now_timestamp / 3600) * 3600 * 1000
    local next_hour = (math.floor(now_timestamp / 3600) + 1) * 3600 * 1000
    local sql = string.format([[
        INSERT INTO t_log_club_coin_hour_change(money_id,reason,club,game_id,amount,time)
        SELECT * FROM 
        (
            SELECT money_id,reason,ifnull(club,0),ifnull(game_id,0),SUM(delta_money) amount,time FROM 
            (
                SELECT money_id,reason,club,new_money - old_money delta_money,game_id,m.created_time DIV (3600 * 1000) * 3600 time 
                FROM 
                    t_log_money m
                LEFT JOIN
                    (SELECT game_id,round,club FROM t_log_round) r
                ON r.round = m.reason_ext
                WHERE m.money_id = 0 AND
                m.created_time >= %s AND m.created_time < %s
            ) d
            GROUP BY money_id,reason,club,game_id,time
        ) d1
        WHERE amount IS NOT NULL AND amount != 0
        ON DUPLICATE KEY UPDATE amount = VALUES(amount);
    ]],hour,next_hour)
	local res = logdb:query(sql)
    if res.errno then
        log.error("%s",res.err)
    end
end

local function task()
    coin_hour_change()
    club_room_card_hour_cost()
    timermgr:calllater(loopinterval,task)
end

skynet.start(function()
    task()
end)
