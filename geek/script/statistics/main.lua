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
local strfmt = string.format
local tconcat = table.concat

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
    LOG_NAME = string.format("statistics.%d",conf.id)
end


local MSG = {}

function MSG.SS_GameRoundEnd(msg)
    log.dump(msg)
    local game_id = msg.game_id
    local balance = msg.log.balance
    local club = msg.club
    local start_time = msg.start_time

    local maxguid,maxmoney = table.max(balance)
    local logdb = dbopt.log

    local date = timestamp_date(tonumber(start_time))

    if maxmoney and maxmoney > 0 then
        local res = logdb:query(
            [[
            INSERT INTO t_log_player_daily_big_win_count(guid,club,game_id,count,date)
            VALUES(%s,%s,%s,1,%s)
            ON DUPLICATE KEY UPDATE count = count + 1
            ]],
            maxguid,club or 0,game_id,date
        )
        if res.errno then
            log.error("%s",res.err)
        end
    end
    
    local winlosevalues = table.series(balance,function(money,guid)
        return strfmt("(%s,%s,%s,%s,%s)",guid,club or 0,game_id,money,date)
    end)

    local guidcount = table.nums(balance or {})
    local validcount = 1 / guidcount

    local countvalues = table.series(balance,function(money,guid)
        return strfmt("(%s,%s,%s,1,%s,%s)",guid,club or 0,game_id,validcount,date)
    end)

    local ret = logdb:query([[
            INSERT INTO t_log_player_daily_play_count(guid,club,game_id,count,valid_count,date)
            VALUES %s
            ON DUPLICATE KEY UPDATE 
            count = count + 1,
            valid_count = valid_count + VALUES(valid_count);

            INSERT INTO t_log_player_daily_win_lose(guid,club,game_id,money,date)
            VALUES %s
            ON DUPLICATE KEY UPDATE money = money + VALUES(money);
        ]],
        tconcat(countvalues,","),
        tconcat(winlosevalues,",")
    )
    if ret.errno then
        log.error('%s',ret.err)
    end

    if not club or club == 0 then
        return
    end

    local playcount_values = {}
    local winlose_values = {}
    for guid,winlose in pairs(balance or {}) do
        local partner = guid
        repeat
            tinsert(winlose_values,strfmt('(%s,%s,%d,%s,%s)',partner,club,game_id,winlose,date))
            tinsert(playcount_values,strfmt("(%s,%s,%d,1,%s,%s)",partner,club,game_id,validcount,date))
            partner = club_member_partner[club][partner]
        until not partner or partner == 0
    end

    ret = logdb:query([[
            INSERT INTO t_log_team_daily_play_count(guid,club,game_id,count,valid_count,date)
            VALUES %s
            ON DUPLICATE KEY UPDATE
            count = count + 1,
            valid_count = valid_count + VALUES(valid_count);

            INSERT INTO t_log_team_daily_win_lose(guid,club,game_id,money,date)
            VALUES %s
            ON DUPLICATE KEY UPDATE
            money = money + VALUES(money);
        ]],
        tconcat(playcount_values,","),
        tconcat(winlose_values,",")
    )
    if ret.errno then
        log.error('%s',ret.err)
    end

    if not maxmoney or maxmoney <= 0 then
        log.error('no max money')
        return
    end

    local bigwin_count_values = {}
    local partner = maxguid
    repeat 
        tinsert(bigwin_count_values,strfmt('(%s,%s,%d,1,%s)',partner,club,game_id,date))
        partner = club_member_partner[club][partner]
    until not partner or partner == 0

    ret = logdb:query(
        [[
            INSERT INTO t_log_team_daily_big_win_count(guid,club,game_id,count,date)
            VALUES %s
            ON DUPLICATE KEY UPDATE count = count + 1
        ]],
        tconcat(bigwin_count_values,",")
    )
    if ret.errno then
        log.error("%s",ret.err)
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

    local values = table.series(contributions,function(s)
        return strfmt("(%s,%s,%s,%s,%s,%s)",s.parent,s.son,s.commission or 0,template or 0,club,date)
    end)
    
    local res = dbopt.log:query([[
            INSERT INTO t_log_player_daily_commission_contribute(parent,son,commission,template,club,date)
            VALUES %s
            ON DUPLICATE KEY UPDATE commission = commission + VALUES(commission);
        ]],tconcat(values,",")
    )
    if res.errno then
        log.error("SS_PlayerCommissionContributes INSERT INTO t_log_player_daily_commission_contribute errno:%d,errstr:%s.",res.errno,res.err)
    end
end

function MSG.SS_LogMoney(msg)
    local date = timestamp_date(tonumber(msg.time))
    local res = dbopt.log:query([[
            INSERT INTO t_log_coin_hour_change(money_id,reason,amount,time) VALUES(%s,%s,%s,%s)
            ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount);
        ]],
        msg.money_id,msg.reason,msg.money or 0,date
    )
    if res.errno then
        log.error("%s",res.err)
    end

    res = dbopt.log:query([[
            INSERT INTO t_log_club_coin_hour_change(money_id,reason,amount,club,game_id,time) VALUES(%s,%s,%s,%s,%s,%s)
            ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount);
        ]],
        msg.money_id,msg.reason,msg.money or 0,msg.club or 0,msg.game_id or 0,date
    )
    if res.errno then
        log.error("%s",res.err)
    end
end
function MSG.SS_LogAntiCheat(info)
    log.dump(info)
    for _, msg in pairs(info) do
        for type, num in pairs(msg.type_list) do
            local res = dbopt.log:query([[
                    INSERT INTO t_log_anti_cheat(guid,guid_other,club,game_id,type,nums) VALUES(%s,%s,%s,%s,%s,%s)
                    ON DUPLICATE KEY UPDATE nums = nums + VALUES(nums);
                ]],
                msg.guid,msg.guid_other,msg.club, msg.game_id,type,num
            )
            if res.errno then
                log.error("%s",res.err)
            end
        end 
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
