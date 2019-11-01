
local redisdb = require "redisopt"
local json = require "cjson"
local skynet = require "skynet"
local pb = require "pb_files"
local channel = require "channel"
local nameservice = require "nameservice"
local serviceconf = require "serviceconf"

GMmessageRetCode_FBParamMiss = pb.enum("GMmessageRetCode","GMmessageRetCode_FBParamMiss")
GMmessageRetCode_MsgTypeError = pb.enum("GMmessageRetCode","GMmessageRetCode_MsgTypeError")
GMmessageRetCode_MsgParamMiss = pb.enum("GMmessageRetCode","GMmessageRetCode_MsgParamMiss")
GMmessageRetCode_Success = pb.enum("GMmessageRetCode","GMmessageRetCode_Success")
GMmessageRetCode_ATMoneyParamError = pb.enum("GMmessageRetCode","GMmessageRetCode_ATMoneyParamError")
GMmessageRetCode_ATtypeError = pb.enum("GMmessageRetCode","GMmessageRetCode_ATtypeError")
GMmessageRetCode_AT_PL_onePlayer = pb.enum("GMmessageRetCode","GMmessageRetCode_AT_PL_onePlayer")
GMmessageRetCode_DBRquestError = pb.enum("GMmessageRetCode","GMmessageRetCode_DBRquestError")
GMmessageRetCode_PLnofindUser = pb.enum("GMmessageRetCode","GMmessageRetCode_PLnofindUser")
GMmessageRetCode_ATnofindUser = pb.enum("GMmessageRetCode","GMmessageRetCode_ATnofindUser")
GMmessageRetCode_ATCantTransfer = pb.enum("GMmessageRetCode","GMmessageRetCode_ATCantTransfer")
GMmessageRetCode_PLCantTransfer= pb.enum("GMmessageRetCode","GMmessageRetCode_PLCantTransfer")
GMmessageRetCode_FreezeAccountOnLineFaild = pb.enum("GMmessageRetCode","GMmessageRetCode_FreezeAccountOnLineFaild")
GMmessageRetCode_GmParamMiss = pb.enum("GMmessageRetCode","GMmessageRetCode_GmParamMiss")
GMmessageRetCode_GmCommandError = pb.enum("GMmessageRetCode","GMmessageRetCode_GmCommandError")
GMmessageRetCode_MsgDBFaild = pb.enum("GMmessageRetCode","GMmessageRetCode_MsgDBFaild")
GMmessageRetCode_MsgPlayerOffline = pb.enum("GMmessageRetCode","GMmessageRetCode_MsgPlayerOffline")
GMmessageRetCode_DelMsgDBError = pb.enum("GMmessageRetCode","GMmessageRetCode_DelMsgDBError")
GMmessageRetCode_EditAliPayFail = pb.enum("GMmessageRetCode","GMmessageRetCode_EditAliPayFail")
GMmessageRetCode_FreezeAccountGameFaild = pb.enum("GMmessageRetCode","GMmessageRetCode_FreezeAccountGameFaild")


LOGIN_RESULT_SUCCESS = pb.enum("LOGIN_RESULT","LOGIN_RESULT_SUCCESS")
LOGIN_RESULT_NO_DEFAULT_LOBBY = pb.enum("LOGIN_RESULT","LOGIN_RESULT_NO_DEFAULT_LOBBY")
LOGIN_RESULT_MAINTAIN = pb.enum("LOGIN_RESULT","LOGIN_RESULT_MAINTAIN")
LOGIN_RESULT_REPEAT_LOGIN = pb.enum("LOGIN_RESULT","LOGIN_RESULT_REPEAT_LOGIN")

LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE")
LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY")
LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY")
LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY")
LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY")

ChangMoney_Success = pb.enum("ChangeMoneyRecode","ChangMoney_Success")

maintain_switch = maintain_switch or false
warnning_addr = warnning_addr or {}

local cost_bank_func = {}
local to_do_sql = {}

local server_player_count = {}

local guid_gate_id = {}

local reddb = redisdb[0]

function add_player_bank_money(stData, proxy_oldmoney, proxy_newmoney)
    return nil
end

function cost_agent_bank_money(fd,keyid, guid, player_guid, money, transfer_type, transfer_id, strData, func )
    if cost_bank_func[keyid] then
        keyid = tostring(tonumber(keyid) + 1)
    end

	cost_bank_func[keyid] = {
        data = strData,
        func = func,
    }

    channel.call("db.?","msg","LD_CC_ChangeMoney",{
        proxy_guid = guid,
        player_guid = player_guid,
        transfer_money = money,
        transfer_tyep = transfer_type,
        transfere_id = transfer_id,
        keyid = keyid,
        retid = fd,
    })
end

function create_do_Sql(fd,msg)

end

function on_do_sql_request(msg)

end

function new_gm_msg(gm_id,ret_code,asyncid)
    return {
        result = ret_code,
        asyncid = asyncid,
    }
end

function player_is_online(guid)
    local onlineinfo = reddb.hgetall("player:online:guid:"..tostring(guid))
    if onlineinfo and type(onlineinfo) == "table" then
        return onlineinfo.gate,onlineinfo.server
    end

    return nil,nil
end

function get_gameid_by_guid(guid)
    local gameid = reddb.hget("player:online:guid:"..tostring(guid),"server")
    if not gameid then
        return nil
    end

    return tonumber(gameid)
end

function find_a_default_lobby()
    local services = channel.list()
    for sid,_ in pairs(services) do
        local id = sid:match("service%.(%d+)")
        if id then
            id = tonumber(id)
            local conf = serviceconf[id]
            if conf and (conf.name == nameservice.TNGAME or conf.type == nameservice.TIDGAME) then
                local gameconf = conf.conf
                if gameconf and gameconf.first_game_type and gameconf.first_game_type == 1 then
                    return tonumber(sid:match("service%.(%d+)"))
                end
            end
        end
    end
end


function find_a_game_id(first_game_type,second_game_type )
    local services = channel.list()
    for sid,_ in pairs(services) do
        local id = sid:match("service%.(%d+)")
        if id then
            id = tonumber(id)
            local conf = serviceconf[id]
            if conf and (conf.name == nameservice.TNGAME or conf.type == nameservice.TIDGAME) then
                local gameconf = conf.conf
                if gameconf.first_game_type == first_game_type and gameconf.second_game_type == second_game_type then
                    return tonumber(sid:match("service%.(%d+)"))
                end
            end
        end
    end
end

function has_game_server_info(game_id)
    return channel.query("game."..tostring(game_id)) ~= nil
end

function json_has_member(doc,fields)
    for k,f in pairs(fields) do
        if not doc[k] then return false end
        if type(doc[k]) ~= f then return false end
    end

    return true
end