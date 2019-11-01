
local redisopt = require "redisopt"
local netopt = require "netopt"
local json = require "cjson"
local skynet = require "skynet"
local pb = require "pb"
local channel = require "channel"

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

local reddb = redisopt.default

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
        login_id = netopt.byfd(fd).server_id,
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
    local online_info = reddb.hget("player_guid_online",guid)
    local account = ""
    if online_info then
        local gateid,account = string.split(online_info,":")
        return gateid,account
    end

    return nil,nil
end

function get_gameid_by_guid(guid)
    local gameid = reddb.hget("player:online:info:"..tostring(guid),"game")
    if not gameid then
        return nil
    end

    return tonumber(gameid)
end

function find_a_game_id(first_game_type,second_game_type )
    local games = netopt.byid(SessionGame)
    if not games then return nil end
    for _,c in pairs(games) do
        if c.first_game_type == first_game_type and c.second_game_type == second_game_type then
            return c.server_id
        end
    end

    return nil
end

function has_game_server_info(game_id)
    return netopt.byid(SessionGate,game_id)
end


function json_has_member(doc,fields)
    for k,f in pairs(fields) do
        if not doc[k] then return false end
        if type(doc[k]) ~= f then return false end
    end

    return true
end