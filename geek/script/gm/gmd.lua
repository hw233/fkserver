
local skynet = require "skynet"
local channel = require "channel"
local pb = require "pb_files"
require "table_func"
local md5 = require "md5"


local GMmessageRetCode_GmParamMiss = pb.enum("GMmessageRetCode","GMmessageRetCode_GmParamMiss")

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

function gmd.recharge(data)
    dump(data)
    return
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

return gmd