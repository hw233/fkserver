
local channel = require "channel"
require "table_func"
local md5 = require "md5"
local base_players = require "game.lobby.base_players"
local onlineguid = require "netguidopt"
local redisopt = require "redisopt"
local error = require "gm.errorcode"
local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local club_money_type = require "game.club.club_money_type"
local log = require "log"


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
        money_id = 0,
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

    local player = base_players[owner_id]
    if not player then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("owner [%d] not exists.",owner_id)
        }
    end

    local name = data.club_name
    local code,club_id = channel.call("game.?","msg","B2S_CLUB_CREATE",owner_id,name)
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

    reddb:hset(string.format("player:info:%d",guid),"role",1)
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
        result = error.SUCCESS,
        count = tonumber(count) or 0,
    }
end

gmd["club/create"] = gmd.create_club
gmd["club/create/group"] = gmd.create_club_with_gourp
gmd["player/block"] = gmd.block_player
gmd["agency/create"] = gmd.agency_create
gmd["agency/remove"] = gmd.agency_remove
gmd["online/player"] = gmd.online_player

return gmd