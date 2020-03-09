
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

local function json_has_member(doc,fields)
    for k,f in pairs(fields) do
        if not doc[k] then return false end
        if type(doc[k]) ~= f then return false end
    end

    return true
end

local function result_code(code)
    return json.encode({result = code,})
end

local function encode(tb)
    return json.encode(tb)
end

function gmd.RequestGameServerInfo(data)
    local msg = channel.call("logind.1","msg","WL_RequestGameServerInfo")
    if not msg or not msg.info_list then 
        return gmd.result_code(1)
    end

    
    return gmd.encode(msg.info_list)
end

function gmd.RequestGmCommand(data)
    if not json_has_member(data,{
        Command = "string",
        Data = "string",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("Command=%s&Data=%s%s",data.Command,data.Data,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WL_GMMessage",{
        gmcommand = data.Command,
        data = data.Data,
    })

    return result_code(msg.result)
end

function gmd.RequestCashFalse(data)
    if not json_has_member(data,{
        id = "number",
        del = "number",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("id=%d%s",data.order_id,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WF_CashFalse",{
        order_id = data.order_id,
        del = data.del,
    })

    return result_code(msg.result)
end

function gmd.RequestRcharge(data)
    if not json_has_member(data,{
        serial_order_no = "number",
        guid = "number",
        money = "number",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("serial_order_no=%d%s",data.serial_order_no,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WF_Recharge",{
        order_id = data.serial_order_no,
        guid = data.guid,
        money = data.money,
    })

    return result_code(msg.result)
end

function gmd.ChangeTax(data)
    if not json_has_member(data,{
        id = "number",
        tax = "number",
        is_enable = "number",
        is_show = "number",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local msg = channel.call("logind.1","msg","WL_ChangeTax",{
        id = data.id,
        tax = data.tax,
        is_enable = data.is_enable,
        is_show = data.is_show,
    })

    return result_code(msg.result)
end

function gmd.ChangeGameCfg(data)
    if not json_has_member(data,{
        id = "number",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("id=%d%s",data.id,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WF_ChangeGameCfg",{
        id = data.id,
    })

    return result_code(msg.result)
end

function gmd.GmCommandChangeMoney(data)
    if not json_has_member(data,{
        guid = "number",
        bank_money = "number",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("guid=%d&bank_money=%d%s",data.guid,data.bank_money,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WL_ChangeMoney",{
        guid = data.guid,
        bank_money = data.bank_money,
    })

    return result_code(msg.result)
end

function gmd.BroadcastClientUpdate(data)
    if not json_has_member(data,{
        GmCommand = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("guid=%d&bank_money=%d%s",data.guid,data.bank_money,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WL_BroadcastClientUpdate",{
        gmcommand = data.GmCommand,
    })

    return result_code(msg.result)
end

-- lua命令，针对玩家，返回结果
function gmd.LuaCmdPlayerResult(data)
    if not json_has_member(data,{
        guid = "number",
        banktype = "number",
        order_id = "string",
        money = "number",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("guid=%d&banktype=%d&order_id=%s&money=%d%s",
        data.guid,data.banktype,data.order_id,data.money,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WL_ChangeMoney",{
        guid = data.guid,
        bank_money = data.bank_money,
    })

    return encode(msg)
end
--lua命令,不同类型维护开关通知服务器响应
function gmd.LuaCmdQueryMaintain(data)
    if not json_has_member(data,{
        id_index = "number",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("id_index=%d%s",
        data.id_index,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WS_MaintainUpdate",{
        id_index = data.id_index,
    })

    return result_code(msg.result)
end

--lua命令,不同类型维护开关通知服务器响应
function gmd.UpdateDbConfig(data)
    if not json_has_member(data,{
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("%s",global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WF_UpdateDbCfg",{})

    return result_code(msg.result)
end

--通过lua命令修改玩家身上的钱
function gmd.ChangePlayersMoneyForLuaCmd(data)
    if not json_has_member(data,{
        guid = "number",
        GmCommand = "string",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local sign = md5.sumhdexa(string.format("guid=%d&GmCommand=%s%s",data.guid,data.GmCommand,global_sign))
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call("logind.1","msg","WL_ChangePlayersMoney",{
        guid = data.guid,
        gmcommand = data.GmCommand,
    })

    return result_code(msg.result)
end

--login服务器
function gmd.ServerCmd(data)
    if not json_has_member(data,{
        server_type = "number",
        sign = "string",
    }) then
        return result_code(GMmessageRetCode_GmParamMiss)
    end

    local servicename = ""
    if data.server_type == 1 then
        servicename = "logind.1"
    elseif data.server_type == 2 then
        servicename = "configd.1"
    else
        return result_code(0)
    end

    local function get_sign(d)
        local tb = {}
        for k,v in ipairs(d) do
            if k ~= "sign" then
                local t = type(v)
                local t = type(v)
                if t == "number" then
                    table.insert(string.format("%s=%d",k,v))
                elseif t == "string" then
                    table.insert(string.format("%s=%s",k,v))
                elseif t == "table" then
                    table.insert(string.format("%s=%s",k,get_sign(v)))
                else
                    return nil
                end
            end
        end

        return table.concat(tb,"&")
    end

    local sign = md5.sumhdexa(get_sign(data)..global_sign)
    if sign ~= data.sign then
        return result_code(0)
    end

    local msg = channel.call(servicename,"msg","WL_GmCommandToServer",{
        cmd_content = json.encode(data),
    })

    return result_code(msg.result)
end

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
    local club_id = channel.call("game.?","msg","B2S_CLUB_CREATE",owner_id,name)
    return {
        errcode = error.SUCCESS,
        club_id = club_id,
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

function gmd.online_player(data)
    local count = reddb:get("player:online:count")
    return {
        result = error.SUCCESS,
        count = tonumber(count) or 0,
    }
end

gmd["info"] = gmd.RequestGameServerInfo
gmd["GMCommand"] = gmd.RequestGmCommand
gmd["cash"] = gmd.RequestCashFalse
gmd["changetax"] = gmd.ChangeTax
gmd["update-game-cfg"] = gmd.ChangeGameCfg
gmd["lua"] = gmd.GmCommandChangeMoney
gmd["broadcast-client-update-info"] = gmd.BroadcastClientUpdate
gmd["cmd-player-result"] = gmd.LuaCmdPlayerResult
gmd["Maintain-switch"] = gmd.LuaCmdQueryMaintain
gmd["update-db-cfg"] = gmd.UpdateDbConfig
gmd["lua_change_player_money"] = gmd.ChangePlayersMoneyForLuaCmd
gmd["gm_server_cmd"] = gmd.ServerCmd
gmd["club/create"] = gmd.create_club
gmd["player/block"] = gmd.block_player
gmd["agency/create"] = gmd.agency_create
gmd["agency/remove"] = gmd.agency_remove
gmd["online/player"] = gmd.online_player

return gmd