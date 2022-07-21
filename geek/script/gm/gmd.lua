
local channel = require "channel"
local player_data = require "game.lobby.player_data"
local onlineguid = require "netguidopt"
local redisopt = require "redisopt"
local error = require "gm.errorcode"
local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local club_money_type = require "game.club.club_money_type"
local log = require "log"
local player_money = require "game.lobby.player_money"
local club_money = require "game.club.club_money"
local club_notice = require "game.notice.club_notice"
local base_notices = require "game.notice.base_notices"
local g_common = require "common"
local verify = require "login.verify.verify"
local json = require "json"
require "functions"

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 1000)


local reddb = redisopt.default

local gmd = {}

local function recharge_team(team_id,coin_type,count)
    -- local team = base_clubs[team_id]
    -- if not team then
    --     return {
    --         errcode = error.DATA_ERROR,
    --         errstr = string.format("team [%d] not exists.",team_id),
    --     }
    -- end

    -- if coin_type ~= 0 then
    --     local money_id = club_money_type[team_id]
    --     if money_id ~= coin_type then
    --         return {
    --             errcode = error.DATA_ERROR,
    --             errstr = string.format("coin type is wrong."),
    --         }
    --     end
    -- end

    -- if count == 0 then
    --     return {
    --         errcode = error.SUCCESS,
    --     }
    -- end

    -- team:incr_money({
    --     money_id = coin_type,
    --     money = count
    -- },enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)

    return {
        errcode = error.SUCCESS,
    }
end

local function recharge_player(guid,money_id,amount,money,comment,operator)
    local player = player_data[guid]
    if not player then
        log.error("recharge_player player [%d] not exists.",guid)
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("player [%d] not exists.",guid)
        }
    end

    amount = math.floor(tonumber(amount))
    if amount == 0 then
        return {
            errcode = error.SUCCESS,
        }
    end

    local result
    local os = onlineguid[guid]
    if os and os.server then
        result = channel.call("game."..os.server,"msg","BS_Recharge",{
            money_id = money_id,
            guid = guid,
            amount = amount,
            money = money,
            comment = comment,
            operator = operator,
        })
    else
        local server = g_common.find_lightest_weight_game_server(1)
        if not server then
            return {
                errcode = error.SERVER_ERROR,
            }
        end

        result = channel.call("game."..server,"msg","BS_Recharge",{
            money_id = money_id,
            guid = guid,
            amount = amount,
            money = money,
            comment = comment,
            operator = operator,
        })
    end

    local errcode = result == enum.ERROR_NONE and error.SUCCESS or error.SERVER_ERROR
    return {
        errcode = errcode,
    }
end

function gmd.recharge(data)
    local guid = tonumber(data.guid)
    if not guid then
        return {
            errcode = error.DATA_ERROR,
            errstr = "target id can not be nil."
        }
    end

    guid = math.floor(guid)

    local money_id = tonumber(data.money_id)
    if not money_id then
        return {
            errcode = error.DATA_ERROR,
            errstr = "money_id is nil.",
        }
    end

    money_id = math.floor(money_id)

    local amount = tonumber(data.amount)
    if not amount or amount == 0 then
        return {
            errcode = error.DATA_ERROR,
            errstr = "amount is nil.",
        }
    end

    local operator = tonumber(data.operator)
    if not operator or operator == 0 then
        return {
            errcode = error.DATA_ERROR,
            errstr = "operator is invalid.",
        }
    end

    local money = tonumber(data.money)
    local comment = data.comment

    local is_team = data.is_team
    if is_team then
        return recharge_team(guid,money_id,amount,money,comment,operator)
    else
        return recharge_player(guid,money_id,amount,money,comment,operator)
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

    local creator = tonumber(data.creator)
    log.dump(data)

    owner_id = math.floor(owner_id)

    local type = tonumber(data.type or 0)

    log.dump(type)

    local player = player_data[owner_id]
    if not player then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("owner [%d] not exists.",owner_id)
        }
    end

    local name = data.club_name
    local code,club_id = channel.call("game.?","msg","B2S_CLUB_CREATE",owner_id,name,type,creator)
    return {
        errcode = code ~= enum.ERROR_PLAYER_NO_RIGHT and error.SUCCESS or error.PARAMETER_ERROR,
        club_id = club_id,
    }
end

function gmd.del_club(data)
    log.dump(data)
    local club_id = tonumber(data.club_id)
    if not club_id or club_id == 0 then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("club id is illigal.")
        }
    end

    club_id = math.floor(club_id)

    local code = channel.call("game.?","msg","B2S_CLUB_DEL",club_id)
    return {
        errcode = code ~= enum.ERROR_PLAYER_NO_RIGHT and error.SUCCESS or error.PARAMETER_ERROR,
    }
end

function gmd.dismiss_club(data)
    local club_id = tonumber(data.club_id)
    if not club_id or club_id == 0 then
        return {
            errcode = error.DATA_ERROR,
            errstr = string.format("club id is illigal.")
        }
    end

    club_id = math.floor(club_id)

    local code = channel.call("game.?","msg","B2S_CLUB_DISMISS",club_id)
    return {
        errcode = code ~= enum.ERROR_PLAYER_NO_RIGHT and error.SUCCESS or error.PARAMETER_ERROR,
    }
end


function gmd.edit_club(data)
    local club_id = tonumber(data.club_id) or nil
    local club = base_clubs[club_id]
    if not club then
        return {
            errcode = enum.PARAMETER_ERROR,
        }
    end

    reddb:hmset(string.format("club:info:%s",club_id),{
        name = data.name or ""
    })

    channel.publish("db.?","msg","SD_EditClubInfo",{
        name = data.name or "",
    },club_id)
    
    return {
        errcode = error.SUCCESS,
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

    local player = player_data[guid]
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

    local player = player_data[guid]
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

    local player = player_data[guid]
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
    local player = player_data[guid]
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
    local player = player_data[guid]
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
    if not guid or not player_data[guid] then
        return {
            errcode = error.DATA_ERROR,
            errstr = "player not exists!",
        }
    end

    data.guid = nil
    local update = data

    reddb:hmset("player:info:"..tostring(guid),update)

    log.dump(data)
    
    local phone = data.phone
    if phone and phone ~= "" then
        channel.call("game.?","msg","BS_BindPhone",{
            guid = guid,
            phone = phone,
        })
    end
    local ok = channel.pcall("db.?","msg","SD_UpdatePlayerInfo",update,guid)
    return {
        errcode = ok and error.SUCCESS or error.SERVER_ERROR,
        errstr = not ok and "unkown server error",
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
        reddb:del(key)
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
        reddb:del(key)
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
    if not promoter or not player_data[promoter] then
        return {
            errcode = error.DATA_ERROR,
            errstr = "promoter not exists!",
        }
    end

    local gameids = data.gameids

    local key = string.format("runtime_conf:promoter_game:%s",promoter)
    if gameids then
        gameids = string.split(gameids,"[^,]+")
        reddb:del(key)
        reddb:sadd(key,table.unpack(gameids))
    else
        gameids = table.keys(reddb:smembers(key))
    end

    return {
        errcode = error.SUCCESS,
        gameids = gameids,
    }
end

function gmd.publish_notice(data)
    local type = tonumber(data.type) or enum.NT_NIL
    local where = tonumber(data.where) or enum.NW_GLOBAL
    local content = data.content
    local club_id = tonumber(data.club_id)
    local ttl = tonumber(data.ttl)
    local start_time = tonumber(data.start_time)
    local end_time = tonumber(data.end_time)
    local expireat = tonumber(data.expireat)
    local title = data.title

    if where == enum.NW_CLUB then
        if not club_id or club_id == 0 then
            return {
                errcode = error.PARAMETER_ERROR,
                errstr = "invalid club_id.",
            }
        end

        if not base_clubs[club_id] then
            return {
                errcode = error.PARAMETER_ERROR,
                errstr = "club not exists.",
            }
        end
    end

    if not content or content == "" then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "invalid content.",
        }
    end

    if expireat and expireat <= os.time() then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "invalid expireat.",
        }
    end

    local id = channel.call("game.?","msg","BS_PublishNotice",{
        content = content,
        club_id = club_id,
        ttl = ttl,
        where = where,
        type = type,
        expireat = expireat,
        start_time = start_time,
        end_time = end_time,
        title = title,
        create_time = os.time(),
        update_time = os.time(),
    })

    return {
        errcode = error.SUCCESS,
        id = id,
    }
end

function gmd.edit_notice(data)
    local type = tonumber(data.type) or enum.NT_NIL
    local where = tonumber(data.where) or enum.NW_GLOBAL
    local content = data.content
    local club_id = tonumber(data.club_id)
    local ttl = tonumber(data.ttl)
    local start_time = tonumber(data.start_time)
    local end_time = tonumber(data.end_time)
    local expireat = tonumber(data.expireat)
    local title = data.title
    local id = data.id

    if not id or id == "" then
        return {
            errcode = error.DATA_ERROR,
            errstr = "notice id not exists."
        }
    end

    if where == enum.NW_CLUB then
        if not club_id or club_id == 0 then
            return {
                errcode = error.PARAMETER_ERROR,
                errstr = "invalid club_id.",
            }
        end

        if not base_clubs[club_id] then
            return {
                errcode = error.PARAMETER_ERROR,
                errstr = "club not exists.",
            }
        end
    end

    if not content or content == "" then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "invalid content.",
        }
    end

    if ttl and ttl == 0 then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "invalid ttl.",
        }
    end

    channel.call("game.?","msg","BS_EditNotice",{
        id = id,
        content = content,
        club_id = club_id,
        ttl = ttl,
        where = where,
        type = type,
        expireat = expireat,
        start_time = start_time,
        end_time = end_time,
        title = title,
        update_time = os.time(),
    })

    return {
        errcode = error.SUCCESS,
        id = id,
    }
end

function gmd.del_notice(data)
    local id = data.id

    log.dump(data)

    if not id or id == "" then
        return {
            errcode = error.DATA_ERROR,
            errstr = "notice id not exists."
        }
    end

    local result = channel.call("game.?","msg","BS_DelNotice",{
        id = id,
    })

    return {
        errcode = result == enum.ERROR_NONE and error.SUCCESS or error.PARAMETER_ERROR,
        id = id,
    }
end

function gmd.notices(data)
    local club_id = tonumber(data.club_id)
    if club_id and not base_clubs[club_id] then
        return {
            errcode = error.PARAMETER_ERROR,
        }
    end

    local id = data.id
    if id then
        return {
            errcode = error.SUCCESS,
            notices = {base_notices[id]},
        }
    end

    if club_id then
        local notice_ids = club_notice[club_id]
        local notices = table.series(notice_ids,function(_,nid) return base_notices[nid] end)
        return {
            errcode = error.SUCCESS,
            notices = notices,
        }
    end

    return {
        errcode = error.SUCCESS,
        notices = table.values(base_notices["*"]),
    }
end


function gmd.set_maintain_switch(data) 
    local gametype = tonumber(data.gametype)

    local switch = data.switch

    if gametype then
        if switch then
            reddb:set(string.format("runtime_conf:game_maintain_switch:%s",gametype),switch)
        else
            reddb:del(string.format("runtime_conf:game_maintain_switch:%s",gametype))
        end
    else
        if switch then
            reddb:set("runtime_conf:global:maintain_switch",switch)
        else
            reddb:del("runtime_conf:global:maintain_switch")
        end

        channel.publish("gate.*","lua","maintain",(switch and switch == "true") and true or nil)
    end

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.maintain_switch(data) 
    local gametype = tonumber(data.gametype)

    local switch
    if gametype then
        switch = reddb:get(string.format("runtime_conf:game_maintain_switch:%s",gametype))
    else
        switch = reddb:get("runtime_conf:global:maintain_switch")
    end

    return {
        errcode = error.SUCCESS,
        switch = switch,
    }
end

function gmd.club_free_cost(data)
    local club_id = tonumber(data.club_id)
    if not club_id then
        return {
            errcode = error.PARAMETER_ERROR,
        }
    end

    local club = base_clubs[club_id]
    if not club then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "club not found",
        }
    end

    local expire_at = tonumber(data.expire_at)
    if not expire_at or expire_at <= os.time() then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "time can not set less than now timestamp",
        }
    end

    reddb:hset("runtime_conf:private_fee:club",club_id,expire_at)

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.agency_free_cost(data)
    local guid = tonumber(data.guid)
    if not guid then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "guid can not be nil",
        }
    end

    local player = player_data[guid]
    if not player then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "player not found",
        }
    end

    local expire_at = tonumber(data.expire_at)
    if not expire_at or expire_at <= os.time() then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "time can not set less than now timestamp",
        }
    end

    reddb:hset("runtime_conf:private_fee:agency",guid,expire_at)

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.verify_remove_lock_imei(data)
    local guid = tonumber(data.guid)
    if not guid then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "guid can not be nil",
        }
    end

    local player = player_data[guid]
    if not player then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "player not found",
        }
    end



    verify.remove_account_lock_imei(guid)

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.verify_remove_ip(data)
    local ip = tostring(data.ip)
   
    if not ip then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "ip can not be nil",
        }
    end

    verify.remove_ip_accounts(ip)

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.verify_remove_imei(data)
    local imei = tostring(data.imei)
    if not imei then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "imei can not be nil",
        }
    end

    verify.remove_imei_accounts(imei)

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.verify_lock_imei(data)
    local guid = tonumber(data.guid)
    if not guid then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "guid can not be nil",
        }
    end

    local player = player_data[guid]
    if not player then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "player not found",
        }
    end

    local imei = tostring(data.imei)
    if not imei then
        return {
            errcode = error.PARAMETER_ERROR,
            errstr = "imei can not be nil",
        }
    end


    verify.set_account_lock_imei(imei,guid)

    return {
        errcode = error.SUCCESS,
    }
end

function gmd.update_passworld(data)
    log.dump(data)
    reddb:set(string.format("player:password:%s",data.guid),data.password)
end

function gmd.verify_update_ip_auth(data)
    local ip = tostring(data.ip)
    if not ip then
        return {
            errcode = error.DATA_ERROR,
            errstr = "data.ip can not be nil",
        }
    end
    local limit = data.limit
    if not limit then
        return {
            errcode = error.DATA_ERROR,
            errstr = "data.limit can not be nil",
        }
    end

    local checkmsg = {
        ip = data.ip,
        limit = data.limit,
        curcount = 0,
    }
    log.dump(checkmsg,data.ip)
    channel.publish("login.*","msg","S_AuthCheck",checkmsg)

    return {
        errcode = error.SUCCESS,
    }
end

gmd["club/create"] = gmd.create_club
gmd["club/create/group"] = gmd.create_club_with_gourp
gmd["club/edit"] = gmd.edit_club
gmd["club/del"] = gmd.del_club
gmd["club/dismiss"] = gmd.dismiss_club
gmd['club/freecost']= gmd.club_free_cost
gmd["player/block"] = gmd.block_player
gmd["agency/create"] = gmd.agency_create
gmd["agency/remove"] = gmd.agency_remove
gmd["agency/freecost"] = gmd.agency_free_cost
gmd["online/player"] = gmd.online_player
gmd["player/update"] = gmd.update_player
gmd['notice/publish'] = gmd.publish_notice
gmd['notice/edit'] = gmd.edit_notice
gmd["notice/del"] = gmd.del_notice
gmd["verify/remove/lockimei"] = gmd.verify_remove_lock_imei
gmd["verify/remove/ip"] = gmd.verify_remove_ip
gmd["verify/remove/imei"] = gmd.verify_remove_imei
gmd["verify/lock/imei"] = gmd.verify_lock_imei
gmd["player/password"] = gmd.update_passworld
gmd["verify/update/ipauth"] = gmd.verify_update_ip_auth

return gmd