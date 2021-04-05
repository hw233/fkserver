
local runtime_conf = require "game.runtime_conf"
local channel = require "channel"

local util = {}

function util.is_private_fee_free(club)
    return (not runtime_conf.private_fee_switch[0]) or
        (club and not runtime_conf.private_fee_agency_switch[club.owner]) or
        (club and not runtime_conf.private_fee_club_switch[club.id])
end

function util.is_global_in_maintain()
    return runtime_conf.is_in_maintain()
end

function util.is_game_in_maintain()
    return runtime_conf.is_in_maintain(def_first_game_type)
end

function util.is_in_maintain()
    return runtime_conf.is_in_maintain() or runtime_conf.is_in_maintain(def_first_game_type)
end

function util.log_statistics_money(money_id,money,reason,club)
    channel.publish("statistics.?","msg","SS_LogMoney",{
        money_id = money_id,
        money = money,
        reason = reason,
        club = club,
        game_id = def_first_game_type,
        time = os.time(),
    })
end

return util