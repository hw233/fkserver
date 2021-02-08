local skynet = require "skynetproto"
local dbopt = require "dbopt"
local log = require "log"
require "functions"
local club_member_partner = require "game.club.club_member_partner"
local club_role = require "game.club.club_role"
local enum = require "pb_enums"

local table = table
local string = string
local tinsert = table.insert

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

LOG_NAME = "statistics"

local function timestamp_date(time)
    local now = os.date("*t",time or os.time())
    return os.time({
        year = now.year,
        month = now.month,
        day = now.day,
        hour = 0,
        min = 0,
        sec = 0,
    })
end

local function checkdbconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.name)
    assert(conf.type)
end

local CMD = {}

function CMD.start(conf)
    checkdbconf(conf)
    LOG_NAME = "statistics_" .. conf.id
end


local MSG = {}

function MSG.SS_GameRoundEnd(msg)
    local game_id = msg.game_id
    local balance = msg.log.balance
    local club = msg.club
    local round = msg.ext_round

    local maxguid,maxmoney = table.max(balance)
    local logdb = dbopt.log

    local res = logdb:query("SELECT * FROM t_log_round WHERE round = '%s';",round)
    if res.errno then
        log.error("%s",res.err)
        return
    end

    local start_time = res.start_time

    local date = timestamp_date(tonumber(start_time))

    if maxmoney > 0 then
        logdb:query(
            [[
            INSERT INTO t_log_player_daily_big_win_count(guid,club,game_id,count,date)
            VALUES(%s,%s,%s,1,%s)
            ON DUPLICATE KEY UPDATE count = count + 1
            ]],
            maxguid,club or 0,game_id,date
        )
    end
    
    local playerbatchsqls = {}
    for guid,money in pairs(balance or {}) do
        tinsert(playerbatchsqls,{
            [[
            INSERT INTO t_log_player_daily_win_lose(guid,club,game_id,money,date)
            VALUES(%s,%s,%s,%s,%s)  
            ON DUPLICATE KEY UPDATE money = money + VALUES(money);
            ]],
            guid,club or 0,game_id,money,date
        })
        tinsert(playerbatchsqls,{
            [[
                INSERT INTO t_log_player_daily_play_count(guid,club,game_id,count,date)
                VALUES(%s,%s,%s,1,%s)
                ON DUPLICATE KEY UPDATE count = count + 1;
            ]],
            guid,club or 0,game_id,date
        })
    end

    local ret = logdb:batchquery(playerbatchsqls)
    if ret.errno then
        log.error('%s',ret.err)
    end

    if club and club ~= 0 then
        local teambatchsqls = {}
        for guid,_ in pairs(balance or {}) do
            local role = club_role[club][guid]
            if role == enum.CRT_PARTNER or role == enum.CRT_BOSS then
                tinsert(teambatchsqls,{
                    [[
                    INSERT INTO t_log_team_daily_play_count(guid,club,count,date)
                    VALUES(%s,%s,1,%s)
                    ON DUPLICATE KEY UPDATE count = count + 1;
                    ]],
                    guid,club,date
                })
            end
            local partner = club_member_partner[club][guid]
            while partner and partner ~= 0 do
                tinsert(teambatchsqls,{
                    [[
                    INSERT INTO t_log_team_daily_play_count(guid,club,count,date)
                    VALUES(%s,%s,1,%s)
                    ON DUPLICATE KEY UPDATE count = count + 1;
                    ]],
                    partner,club,date
                })

                partner = club_member_partner[club][partner]
            end
        end

        local ret = logdb:batchquery(teambatchsqls)
        if ret.errno then
            log.error('%s',ret.err)
        end
    end
end

function MSG.SS_PlayerCommissionContributes(msg)
    local contributions = msg.contributions
    local template =  msg.template
    local club = msg.club

    if not contributions or table.nums(contributions) == 0 or not club or club == 0 then
        log.error("SS_PlayerCommissionContributes contributions is illegal.")
        return
    end

    local date = timestamp_date()

    local batchsqls = table.series(contributions,function(s)
        return {
            [[
                INSERT INTO t_log_player_daily_commission_contribute(parent,son,commission,template,club,date)
                VALUES(%s,%s,%s,%s,%s,%s)
                ON DUPLICATE KEY UPDATE commission = commission + VALUES(commission);
            ]],
            s.parent,s.son,s.commission or 0,template or 0,club,date
        }
    end)

    local res = dbopt.log:batchquery(batchsqls)
    if res.errno then
        log.error("SS_PlayerCommissionContributes INSERT INTO t_log_player_daily_commission_contribute errno:%d,errstr:%s.",res.errno,res.err)
    end
end

skynet.start(function()
    skynet.dispatch("lua",function(_,_,cmd,...) 
        local f = CMD[cmd]
        if not f then
            log.error("unkown cmd:%s",cmd)
            skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)

    skynet.dispatch("msg",function(_,_,cmd,...) 
        local f = MSG[cmd]
        if not f then
            log.error("unkown msg:%s",cmd)
            skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)

    local prepare = require("statistics.prepare")
    prepare()

    require "statistics.money"
end)
