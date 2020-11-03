
local channel = require "channel"
local md5 = require "md5"
local base_players = require "game.lobby.base_players"
local onlineguid = require "netguidopt"
local redisopt = require "redisopt"
local error = require "gm.errorcode"
local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local club_money_type = require "game.club.club_money_type"
local log = require "log"
local player_money = require "game.lobby.player_money"
local club_money = require "game.club.club_money"
require "functions"


local reddb = redisopt.default

local gmd = {}

local global_sign = global_sign

local function recharge_team(team_id,coin_type,count)
    local team = base_clubs[team_id]
    if not team then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("team [%d] not exists.",team_id),
        }
    end

    if coin_type ~= 0 then
        local money_id = club_money_type[team_id]
        if money_id ~= coin_type then
            return {
                errcode = error.DATA_ERROR,
                errstr = string.format("coin type is wrong."),
            }
        end
    end

    if count == 0 then
        return {
            errcode = error.SUCCESS,
        }
    end

    team:incr_money({
        money_id = coin_type,
        money = count
    },enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)

    return {
        errcode = error.SUCCESS,
    }
end

local function recharge_player(guid,coin_type,count)
    -- if coin_type ~= 2 then
    --     return {
    --         errcode = error.DATA_ERROR,
    --         errstr = "coin type can not be 1(gold).",
    --     }
    -- end

    local player = base_players[guid]
    if not player then
        log.error("recharge_player player [%d] not exists.",guid)
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("player [%d] not exists.",guid)
        }
    end

    count = math.floor(tonumber(count))
    if count == 0 then
        return {
            errcode = error.SUCCESS,
        }
    end

    player:incr_money({
        money_id = coin_type,
        money = count,
    },enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.recharge(data)
    local target_id = tonumber(data.target_id)
    if not target_id then
        return {
            errcode = error.DATA_ERROR,
            errstr = "target id can not be nil."
        }
    end

    target_id = math.floor(target_id)

    local coin_type = tonumber(data.coin_type)
    if not coin_type then
        return {
            errcode = error.DATA_ERROR,
            errstr = "coin_type is nil.",
        }
    end

    coin_type = math.floor(coin_type)

    local count = tonumber(data.count)
    if not count or count == 0 then
        return {
            errcode = error.DATA_ERROR,
            errstr = "count is nil.",
        }
    end

    local is_team = data.is_team
    if is_team then
        return recharge_team(target_id,coin_type,count)
    else
        return recharge_player(target_id,coin_type,count)
    end
end

function gmd.create_club(data)
    local owner_id = data.owner_id
    if not owner_id or owner_id == 0 then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("owner id is illigal.")
        }
    end

    owner_id = math.floor(owner_id)

    local type = tonumber(data.type or 0)

    log.dump(type)

    local player = base_players[owner_id]
    if not player then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("owner [%d] not exists.",owner_id)
        }
    end

    local name = data.club_name
    local code,club_id = channel.call("game.?","msg","B2S_CLUB_CREATE",owner_id,name,type)
    return {
        errcode = code ~= enum.ERROR_PLAYER_NO_RIGHT and error.SUCCESS or error.PARAMETER_ERROR,
        club_id = club_id,
    }
end

function gmd.create_club_with_gourp(data)
    local group_id = data.group_id
    if not group_id or group_id == 0 then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("group id is illigal.")
        }
    end

    local group = base_clubs[group_id]
    if not group or group.type ~= enum.CT_DEFAULT then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("group id is illigal.")
        }
    end

    local name = data.club_name
    local code,union_id = channel.call("game.?","msg","B2S_CLUB_CREATE_WITH_GROUP",group_id,name)
    return {
        errcode = code == enum.ERROR_NONE and error.SUCCESS or error.PARAMETER_ERROR,
        union_id = union_id,
    }
end

function gmd.force_dismiss_club(data)

end

function gmd.block_club(data)
    return {
        errcode = error.SUCCESS
    }
end

function gmd.block_player(data)
    local guid = tonumber(data.uid)
    if not guid then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("uid [%s] illegal.",data.uid),
        }
    end

    guid = math.floor(guid)

    local player = base_players[guid]
    if  not player then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("player [%d] not exists.",data.uid),
        }
    end

    local status = data.status
    if not status or (status ~= 0 and status ~= 1) then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("parameter illigle for [%d].",guid),
        }
    end

    reddb:hset(string.format("player:info:%d",guid),"status",status)
    return {
        errcode = error.SUCCESS
    }
end

function gmd.agency_create(data)
    local guid = tonumber(data.uid)
    local role = tonumber(data.role)
    if not guid or not role then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("uid [%s] illegal.",data.uid),
        }
    end

    guid = math.floor(guid + 0.0000001)
    role = math.floor(role + 0.0000001)

    local player = base_players[guid]
    if  not player then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("player [%d] not exists.",data.uid),
        }
    end

    reddb:hset(string.format("player:info:%d",guid),"role",role)
    return {
        errcode = error.SUCCESS
    }
end

function gmd.agency_remove(data)
    local guid = tonumber(data.uid)
    if not guid then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("uid [%s] illegal.",data.uid),
        }
    end

    guid = math.floor(guid)

    local player = base_players[guid]
    if  not player then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("player [%d] not exists.",data.uid),
        }
    end

    reddb:hset(string.format("player:info:%d",guid),"role",0)
    return {
        errcode = error.SUCCESS
    }
end

function gmd.online_player(_)
    local count = reddb:get("player:online:count")
    return {
        errcode = error.SUCCESS,
        count = tonumber(count) or 0,
    }
end

local function transfer_money_player2club(guid,club_id,coin_type,amount)
    local player = base_players[guid]
    if not player then
        return {
            result = error.DATA_ERROR,
            errstr = string.format("player [%d] not exists.",guid),
        }
    end

    local club = base_clubs[club_id]
    if not club then
        return {
            result = error.DATA_ERROR,
            errstr = string.format("club [%d] not exists.",club_id),
        }
    end

    if guid ~= club.owner then
        return {
            result = error.DATA_ERROR,
            errstr = string.format("player [%d] is not club [%d] boss.",guid,club_id),
        }
    end

    if coin_type ~= 0 then
        local money_id = club_money_type[club_id]
        if money_id ~= coin_type then
            return {
                errcode = error.DATA_ERROR,
                errstr = string.format("coin type is fault."),
            }
        end
    end

    if amount == 0 then
        return {
            errcode = error.SUCCESS,
        }
    end

    local money_amount = player_money[guid][coin_type]
    if money_amount < amount then
        return {
                errcode = error.DATA_ERROR,
                errstr = string.format("money is not enough."),
            }
    end

    player:incr_money({
        money_id = 0,
        money = - amount,
    },enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,club_id)

    club:incr_money({
        money_id = 0,
        money = amount,
    },enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,guid)

    return {
        errcode = error.SUCCESS,
    }
end

local function transfer_money_club2player(club_id,guid,coin_type,amount)
    local player = base_players[guid]
    if not player then
        return {
            result = error.DATA_ERROR,
            errstr = string.format("player [%d] not exists.",guid),
        }
    end

    local club = base_clubs[club_id]
    if not club then
        return {
            result = error.DATA_ERROR,
            errstr = string.format("club [%d] not exists.",club_id),
        }
    end

    if guid ~= club.owner then
        return {
            result = error.DATA_ERROR,
            errstr = string.format("player [%d] is not club [%d] boss.",guid,club_id),
        }
    end

    if coin_type ~= 0 then
        local money_id = club_money_type[club_id]
        if money_id ~= coin_type then
            return {
                errcode = error.DATA_ERROR,
                errstr = string.format("coin type is fault."),
            }
        end
    end

    if amount == 0 then
        return {
            errcode = error.SUCCESS,
        }
    end

    local money_amount = club_money[club_id][coin_type]
    if money_amount < amount then
        return {
                errcode = error.DATA_ERROR,
                errstr = string.format("money is not enough."),
            }
    end

    club:incr_money({
        money_id = 0,
        money = - amount,
    },enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,guid)

    player:incr_money({
        money_id = 0,
        money = amount,
    },enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,club_id)

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.transfer_money(data)
    local to = tonumber(data.to)
    if not to then
        return {
            errcode = error.DATA_ERROR,
            errstr = "target id can not be nil."
        }
    end

    to = math.floor(to)

    local from = tonumber(data.from)
    if not from then
        return {
            errcode = error.DATA_ERROR,
            errstr = "from id can not be nil."
        }
    end

    from = math.floor(from)

    local coin_type = tonumber(data.coin_type)
    if not coin_type then
        return {
            errcode = error.DATA_ERROR,
            errstr = "coin_type is nil.",
        }
    end

    coin_type = math.floor(coin_type)

    local amount = tonumber(data.amount)
    if not amount or amount == 0 then
        return {
            errcode = error.DATA_ERROR,
            errstr = "amount is nil.",
        }
    end

    local transfer_type = data.transfer_type
    if transfer_type == 1 then
        return transfer_money_player2club(from,to,coin_type,amount)
    end

    if transfer_type == 2 then
        return transfer_money_club2player(from,to,coin_type,amount)
    end

    return {
            errcode = error.DATA_ERROR,
            errstr = "transfer_type is not support!",
        }
end

function gmd.runtime_conf()
    local roomcard_switch = reddb:get("runtime_conf:private_fee:0")
    local diamond_switch = reddb:get("runtime_conf:private_fee:-1")
    local h5_login_switch = reddb:get("runtime_conf:global:h5_login")
    return {
        errcode = error.SUCCESS,
        data = {
            private_fee = {
                roomcard = roomcard_switch and tonumber(roomcard_switch) or 1,
                diamond = diamond_switch and tonumber(diamond_switch) or 1,
            },
            global = {
                h5_login = h5_login_switch and tonumber(h5_login_switch) or 0,
            }
        }
    }
end

function gmd.turn_diamond_switch(data)
    reddb:set("runtime_conf:private_fee:-1",(data and data.open and data.open ~= 0) and 1 or 0)
    return {
        errcode = error.SUCCESS,
    }
end

function gmd.turn_roomcard_switch(data)
    reddb:set("runtime_conf:private_fee:0",(data and data.open and data.open ~= 0) and 1 or 0)
    return {
        errcode = error.SUCCESS,
    }
end

function gmd.turn_h5_login_switch(data)
    reddb:set("runtime_conf:global:h5_login",(data and data.open and data.open ~= 0) and 1 or 0)
    return {
        errcode = error.SUCCESS,
    }
end

function gmd.update_player(data)
    local guid = tonumber(data.guid) or nil
    if not guid or not base_players[guid] then
        return {
            errcode = error.DATA_ERROR,
            errstr = "player not exists!",
        }
    end

    local update = {
        channel_id = data.channel_id,
        promoter = data.promoter,
        platform_id = data.platform_id,
    }

    reddb:hmset("player:info:"..tostring(guid),update)

    return {
        errcode = error.SUCCESS
    }
end

function gmd.club_game(data)
    local club_id = tonumber(data.club_id) or nil
    if not club_id or not base_clubs[club_id] then
        return {
            errcode = error.DATA_ERROR,
            errstr = "club not exists!",
        }
    end

    local gameids = data.gameids

    local key = string.format("runtime_conf:club_game:%s",club_id)
    if gameids then
        gameids = string.split(gameids,"[^,]+")
        reddb:sadd(key,table.unpack(gameids))
    else
        gameids = table.keys(reddb:smembers(key))
    end

    return {
        errcode = error.SUCCESS,
        gameids = gameids,
    }
end

function gmd.channel_game(data)
    local channel = data.channel
    if not channel or channel == "" then
        return {
            errcode = error.DATA_ERROR,
            errstr = "channel not exists!",
        }
    end

    local gameids = data.gameids

    local key = string.format("runtime_conf:channel_game:%s",channel)
    if gameids then
        gameids = string.split(gameids,"[^,]+")
        reddb:sadd(key,table.unpack(gameids))
    else
        gameids = table.keys(reddb:smembers(key))
    end

    return {
        errcode = error.SUCCESS,
        gameids = gameids,
    }
end

function gmd.promoter_game(data)
    local promoter = tonumber(data.promoter) or nil
    if not promoter or not base_players[promoter] then
        return {
            errcode = error.DATA_ERROR,
            errstr = "promoter not exists!",
        }
    end

    local gameids = data.gameids

    local key = string.format("runtime_conf:promoter_game:%s",promoter)
    if gameids then
        gameids = string.split(gameids,"[^,]+")
        reddb:sadd(key,table.unpack(gameids))
    else
        gameids = table.keys(reddb:smembers(key))
    end

    return {
        errcode = error.SUCCESS,
        gameids = gameids,
    }
end

gmd["club/create"] = gmd.create_club
gmd["club/create/group"] = gmd.create_club_with_gourp
gmd["player/block"] = gmd.block_player
gmd["agency/create"] = gmd.agency_create
gmd["agency/remove"] = gmd.agency_remove
gmd["online/player"] = gmd.online_player
gmd["player/update"] = gmd.update_player

return gmd