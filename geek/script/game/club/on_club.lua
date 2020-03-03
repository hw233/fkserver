local log = require "log"
local base_club = require "game.club.base_club"
local pb = require "pb_files"
local redisopt = require "redisopt"
local base_players = require "game.lobby.base_players"
local base_clubs = require "game.club.base_clubs"
local club_member = require "game.club.club_member"
local player_club = require "game.lobby.player_club"
local channel = require "channel"
local serviceconf = require "serviceconf"
local onlineguid = require "netguidopt"
local club_table = require "game.club.club_table"
local club_template = require "game.club.club_template"
local player_request = require "game.club.player_request"
local base_request = require "game.club.base_request"
local club_game_type = require "game.club.club_game_type"
local base_private_table = require "game.lobby.base_private_table"
local club_role = require "game.club.club_role"
local table_template = require "game.lobby.table_template"
local base_mails = require "game.mail.base_mails"
local club_request = require "game.club.club_request"
local club_team = require "game.club.club_team"
local club_money_type = require "game.club.club_money_type"
local club_money = require "game.club.club_money"
local player_money = require "game.lobby.player_money"
local club_utils = require "game.club.club_utils"
local club_commission = require "game.club.club_commission"
local club_template_conf = require "game.club.club_template_conf"
local club_team_template_conf = require "game.club.club_team_template_conf"
local util = require "util"
local enum = require "pb_enums"
local json = require "cjson"
require "functions"

local g_room = g_room

local reddb = redisopt.default

local club_op = {
    ADD_ADMIN    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","ADD_ADMIN"),
    REMOVE_ADMIN    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_ADMIN"),
    OP_JOIN_AGREED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_JOIN_AGREED"),
    OP_JOIN_REJECTED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_JOIN_REJECTED"),
    OP_EXIT_AGREED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_EXIT_AGREED"),
    OP_APPLY_EXIT    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_APPLY_EXIT"),
    ADD_PARTNER = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","ADD_PARTNER"),
    REMOVE_PARTNER = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_PARTNER"),
    CANCEL_FORBID = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","CANCEL_FORBID"),
    FORBID_GAME = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","FORBID_GAME"),
    BLOCK_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","BLOCK_CLUB"),
    UNBLOCK_CLUB    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","UNBLOCK_CLUB"),
    CLOSE_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","CLOSE_CLUB"),
}

function on_cs_club_create(msg,guid)
    local club_info = msg.info
    -- if club_info.type == 1 or club_info.parent and club_info.parent ~= 0 then
    --     local p_club = base_clubs[msg.parent]
    --     if not p_club then
    --         log.error("on_cs_club_create no parent club,%s.",msg.parent)
    --         onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
    --             result = enum.ERROR_CLUB_NOT_FOUND,
    --         })
    --         return
    --     end
    -- end

    local player = base_players[guid]
    if not player then
        log.error("internal error,recv msg but no player.")
        onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
        })

        return
    end

    dump(player)

    -- if not player:has_club_rights() then
	-- 	return {
    --         result = CLUB_OP_RESULT_NO_RIGHTS,
    --     }
    -- end

    local id = math.random(1000000,9999999)
    for _ = 1,1000 do
        if not base_clubs[id] then break end
        id = math.random(1000000,9999999)
    end

    base_club:create(id,club_info.name,club_info.icon,player,club_info.type,club_info.parent)

    -- 初始送分 金币
    base_clubs[id]:incr_money({
        money_id = club_money_type[id],
        money = math.floor(global_cfg.union_init_money),
    },enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)

    onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
        result = enum.CLUB_OP_RESULT_SUCCESS,
        id = id,
    })
end

function on_cs_club_create_club_with_mail(msg,guid)
    dump(msg)
    local mail = base_mails[msg.mail_id]
    if not mail or mail.status ~= 0 then
        log.error("on_cs_club_create_club_with_req no request,%s.",msg.mail_id)
        onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
            result = enum.ERROR_CLUB_OP_EXPIRE,
        })
        return
    end

    local content = mail.content

    local inviter_club_id = content.club_id
    local inviter_club = base_clubs[inviter_club_id]
    if not inviter_club then
        log.error("on_cs_club_create_club_with_req no parent club,%s.",inviter_club_id)
        onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local player = base_players[guid]
    if not player then
        log.error("internal error,recv msg but no player.")
        onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
        })

        return
    end

    local role = club_role[inviter_club_id][guid]
    if role == enum.CRT_BOSS then
        return
    end

    local id = math.random(1000000,9999999)
    for _ = 1,1000 do
        if not base_clubs[id] then break end
        id = math.random(1000000,9999999)
    end

    local club_info = msg.club_info

    base_club:create(id,club_info.name,club_info.icon,player,enum.CT_UNION,inviter_club.id)
	if not id then
		return {
            result = enum.CLUB_OP_RESULT_FAILED,
        }
    end

    local _ = base_clubs[id]

    club_team[inviter_club.id] = nil

    reddb:hset("mail:"..msg.mail_id,"status",1)
    base_mails[msg.mail_id] = nil

    onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
        result = enum.CLUB_OP_RESULT_SUCCESS,
        id = id,
    })
end

function on_cs_club_invite_join_club(msg,guid)
    local invite_type = msg.invite_type
    local invitee = msg.invitee
    local club_id = msg.inviter_club
    local club = base_clubs[club_id]
    if not club then
        log.warning("unknown club:%s",club_id)
        onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    if club_member[club_id][invitee] then
        log.warning("club member:%s join self club:%s",guid,club_id)
        onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
            result = enum.ERROR_CLUB_OP_JOIN_CHECKED,
        })
        return
    end

    if not base_players[guid] then
        log.warning("invite join club but inviter is not exists,guid:%s",guid)
        onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
            result = enum.ERROR_CLUB_OP_JOIN_CHECKED,
        })
        return
    end

    -- for req_id,_ in pairs(player_request[club.owner]) do
    --     local req = base_request[req_id]
    --     if req.who == guid and req.type == invite_type then
    --         onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
    --             result = enum.ERROR_CLUB_OP_JOIN_REPEATED,
    --         })
    --         return
    --     end
    -- end

    club:invite_join(invitee,guid,club,invite_type)
    onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
        result = enum.ERROR_NONE,
    })

    player_request[club.owner] = nil
end

function on_cs_club_dismiss(msg,guid)
    local club_id = msg.club_id
    local player = base_players[guid]
    if not player then
        log.error("internal error,recv msg but guid not online.")
        return {
            club_id = club_id,
            result = enum.CLUB_OP_RESULT_INTERNAL_ERROR,
        }
    end

    if not player:has_club_rights() then
        return {
            club_id = club_id,
            result = enum.CLUB_OP_RESULT_NO_RIGHTS,
        }
    end

    local club = base_clubs[club_id]
    if not club then
        return {
            club_id = club_id,
            result = enum.CLUB_OP_RESULT_NO_CLUB,
        }
    end

    club:dismiss()
    club_member[club_id] = nil
    base_clubs[club_id] = nil

    return {
        club_id = club_id,
        result = enum.CLUB_OP_RESULT_SUCCESS,
    }
end

local function get_club_tables(club)
    if not club then return end

    local tables = {}
    for tid,_ in pairs(club_table[club.id] or {}) do
        local priv_tb = base_private_table[tid]
        local tableinfo = channel.call("game."..priv_tb.room_id,"msg","GetTableStatusInfo",priv_tb.real_table_id)
        table.insert(tables,tableinfo)
    end

    return tables
end

local function deep_get_club_tables(club)
    local tables = get_club_tables(club) or {}
    for teamid,_ in pairs(club_team[club.id]) do
        local team = base_clubs[teamid]
        if team then
            table.unionto(tables,deep_get_club_tables(team) or {})
        end
    end

    return tables
end


local function get_club_template_team_conf(club,template)
    club = base_clubs[club.parent]
    if not club then return end
    local conf = club_team_template_conf[club.id][template.template_id]
    if not conf then return end

    return conf
end

local function get_club_templates(club)
    if not club then return end

    local templates = {}
    for tid,_ in pairs(club_template[club.id]) do
        local temp = table_template[tid]
        local conf = get_club_template_team_conf(club,temp)
        if temp and (not conf or conf.visual) then
            table.insert(templates,{
                template = {
                    template_id = temp.template_id,
                    game_id = temp.game_id,
                    description = temp.description,
                    rule = json.encode(temp.rule),
                },
                club_id = temp.club_id,
            })
        end
    end

    table.unionto(templates,get_club_templates(base_clubs[club.parent]) or {})

    return templates
end

function on_cs_club_detail_info_req(msg,guid)
    local club_id = msg.club_id
    if not club_id then
        onlineguid.send(guid,"S2C_CLUB_INFO_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })

        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_INFO_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    -- local role = club_role[club_id][guid]
    -- if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
    --     onlineguid.send(guid,"S2C_CLUB_INFO_RES",{
    --         result = enum.ERROR_NOT_IS_CLUB_BOSS,
    --     })
    --     return
    -- end

    local games = {}
    local info = channel.query()
    for sid,_ in pairs(info) do
        local id = sid:match("service%.(%d+)")
        if id then
            local conf = serviceconf[tonumber(id)]
            if conf.name == "game" then
                local sconf = conf.conf
                games[sconf.first_game_type] = sconf
            end
        end
    end

    local real_games = {}
    local club_games = club_game_type[club_id]
    if table.nums(club_games) ~= 0 then
        for _,game in pairs(club_games or {}) do
            if games[game] then
                table.insert(real_games,game)
            end
        end
    else
        real_games = table.keys(games)
    end

    local root = club_utils.root(club)
    local tables = deep_get_club_tables(root)

    local online_count = 0
    local total_count = 0

    for mem,_ in pairs(club_member[club_id]) do
        local p = base_players[mem]
        if p  then
            total_count = total_count + 1
            if p.online then
                online_count = online_count + 1
            end
        end
    end

    local club_status = {
        status = 0,
        player_count = total_count,
        online_player_count = online_count,
    }

    local role = club_role[club_id][guid]
    if not role then
        local my_unions = player_club[guid][enum.CT_UNION]
        if table.nums(my_unions) > 0 then
            for union_id,_ in pairs(my_unions) do
                local union = base_clubs[union_id]
                if union.owner == guid and union.parent == club_id and club.parent and club.parent ~= 0 then
                    role = enum.CRT_PARTNER
                    break
                end
            end
        end

        role = role or enum.CRT_PLAYER
    end

    local templates = get_club_templates(club)
    local money_id = club_money_type[club_id]
    local boss = base_players[club.owner]
    local myself = base_players[guid]
    local my_team_info = {
        info = {
            guid = myself.guid,
            icon = myself.icon,
            nickname = myself.nickname,
            sex = myself.sex,
        },
        role = role,
        money = {
            money_id = money_id,
            count = player_money[guid][money_id]
        }
    }

    local team_info = {
        base = {
            id = club_id,
            name = club.name,
            icon = club.icon,
            type = club.type,
        },
        boss = {
            guid = boss.guid,
            icon = boss.icon,
            nickname = boss.nickname,
            sex = boss.sex,
        },
        money = {{
            money_id = money_id,
            count = club_money[club_id][money_id] or 0
        }},
        money_id = money_id,
        commission = (role == enum.CRT_BOSS or role == enum.CRT_ADMIN) and club_commission[club_id] or 0,
    }

    local club_info = {
        root = club_utils.root(club).id,
        result = enum.ERROR_NONE,
        self_info = team_info,
        my_team_info = my_team_info,
        status = club_status,
        table_list = tables,
        gamelist = real_games,
        table_templates = templates,
    }

    onlineguid.send(guid,"S2C_CLUB_INFO_RES",club_info)
end

function on_cs_club_list(msg,guid)
    log.info("on_cs_club_list,guid:%s",guid)
    local clubs = {}
    for club,_ in pairs(player_club[guid][msg.type or enum.CT_DEFAULT]) do
        table.insert(clubs,base_clubs[club])
    end

    onlineguid.send(guid,"S2C_CLUBLIST_RES",{
        result = 0,
        clubs = clubs,
    }) 
end

function on_cs_club_edit_game_type(msg,guid)
    local club_id = msg.club_id
    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_EDIT_CLUB_GAME_TYPE_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    if club.owner ~= guid then
        onlineguid.send(guid,"S2C_EDIT_CLUB_GAME_TYPE_RES",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS,
        })
        return
    end

    
    reddb:sadd("club:game:"..tostring(club_id),table.unpack(msg.game_types))
    club_game_type[club_id] = nil

    onlineguid.send(guid,"S2C_EDIT_CLUB_GAME_TYPE_RES",{
        result = enum.ERROR_NONE,
    })
end

function on_cs_club_join_req(msg,guid)
    dump(msg)
    local club_id = msg.club_id
    local club = base_clubs[club_id]
    if not club then
        log.warning("unknown club:%s",club_id)
        onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    if club_member[club_id][guid] then
        log.warning("club member:%s join self club:%s",guid,club_id)
        onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
            result = enum.ERROR_CLUB_OP_JOIN_CHECKED,
        })
        return
    end

    for req_id,_ in pairs(club_request[club_id]) do
        local req = base_request[req_id]
        if req and req.who == guid and req.type == "join" then
            onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
                result = enum.ERROR_CLUB_OP_JOIN_REPEATED,
            })
            return
        end
    end

    club:request_join(guid)
    onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
        result = enum.ERROR_NONE,
    })

    player_request[guid] = nil
    club_request[club_id] = nil
end

function on_club_create_table(club,player,chair_count,round,rule,template)
    local result,global_table_id,tb = club:create_table(player,chair_count,round,rule,template)
    if result == enum.GAME_SERVER_RESULT_SUCCESS then
        local tableinfo = channel.call("game."..def_game_id,"msg","GetTableStatusInfo",tb.table_id_)
        local root  = club_utils.root(club)
        root:recusive_broadcast("S2C_SYNC_TABLES_RES",{
            root_club = root.id,
            club_id = club.id,
            room_info = tableinfo,
            sync_table_id = global_table_id,
            sync_type = enum.SYNC_ADD
        })
    end

    return result,global_table_id,tb
end

function on_cs_club_query_memeber(msg,guid)
    local club_id = msg.club_id

    if not base_clubs[club_id] then
        onlineguid.send(guid,"S2C_CLUB_PLAYER_LIST_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            club_id = club_id,
        })
        return
    end

    local role = club_role[club_id][guid]
    if not role or role == enum.CRT_PLAYER then
        onlineguid.send(guid,"S2C_CLUB_PLAYER_LIST_RES",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS,
            club_id = club_id,
        })
        return
    end

    local money_id = club_money_type[club_id]
    local ms = {}
    for mem,_ in pairs(club_member[club_id]) do
        local p = base_players[mem]
        if p then
            table.insert(ms,{
                info = {
                    guid = p.guid,
                    icon = p.icon,
                    nickname = p.nickname,
                    sex = p.sex,
                },
                role = club_role[club_id][p.guid] or enum.CRT_PLAYER,
                money = {
                    money_id = money_id,
                    count = player_money[p.guid][money_id] or 0,
                }
            })
        end
    end

    onlineguid.send(guid,"S2C_CLUB_PLAYER_LIST_RES",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        player_list = ms,
    })
end


function on_cs_club_exit_req(msg,guid)

end

function on_cs_club_request_list_req(msg,guid)
    local club_id = msg.club_id
    local reqs = {}
    for rid,_ in pairs(club_request[club_id]) do
        local req = base_request[rid]
        local player = base_players[req.who]
        table.insert(reqs,{
            req_id = req.id,
            type = req.type,
            who = {
                guid = player.guid,
                nickname = player.nickname,
                icon = player.icon,
            },
        })
    end

    onlineguid.send(guid,"S2C_CLUB_REQUEST_LIST_RES",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        reqs = reqs,
    })
end

local function on_cs_club_blacklist(msg,guid)
    if msg.op == club_op.ADD_TO_BALACK then
        
    elseif msg.op == club_op.REMOVE_TO_BLACK then

    end
end

local function on_cs_club_administrator(msg,guid)
    local target_guid = msg.target_id
    local club_id = msg.club_id

    local res = {
        club_id = club_id,
        target_id = target_guid,
        op = msg.op,
        result = enum.ERROR_NONE,
    }

    if not base_clubs[club_id] then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    local self_role = club_role[club_id][guid]
    if self_role ~= enum.CRT_BOSS then
        res.result = enum.ERROR_NOT_IS_CLUB_BOSS
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == club_op.ADD_ADMIN then
        local role = club_role[club_id][target_guid]
        if role == enum.CRT_BOSS or role == enum.CRT_PARTNER or role == enum.CRT_ADMIN then
            res.result = enum.ERROR_NOT_SET_ADMIN
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        reddb:hset(string.format("club:role:%d",club_id),target_guid,enum.CRT_ADMIN)
        res.result = enum.ERROR_NONE
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == club_op.REMOVE_ADMIN then
        local role = club_role[club_id][target_guid]
        if role ~= enum.CRT_ADMIN then
            res.result = enum.ERROR_NOT_SET_ADMIN
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        reddb:hdel(string.format("club:role:%d",club_id),target_guid)
        res.result = enum.ERROR_NONE
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end
end

local function on_cs_club_player(msg,guid)
    local player = base_players[guid]
    if not player then
        log.error("unknown player when kickout player out club:%s",msg.club_id)
        return
    end
    
    if msg.op == club_op.REMOVE_PLAYER then
        base_clubs[msg.club_id].kickout(msg.guid)
    end
end

local function on_cs_club_exit(msg,guid)
    local who = base_players[guid]

    local club_id = msg.club_id
    if base_players[msg.guid] then
        base_clubs[club_id]:exit(msg.guid)
        club_member[club_id][msg.guid] = nil
    end
    
    return enum.CLUB_OP_RESULT_SUCCESS
end

local function on_cs_club_agree_request(msg,guid)
    local player = base_players[guid]
    if not player then
        log.error("unknown player when agree request id:%s",msg.request_id)
        
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
            op_type = msg.op,
        })
        return
    end

    local request = base_request[msg.request_id]
    if not request then
        log.error("unknown player when agree request id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_OP_EXPIRE,
            op_type = msg.op,
        })
        return
    end

    if not request:agree() then
        log.error("agree request failed,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_OP_EXPIRE,
            op_type = msg.op,
        })

        return
    end

    -- 更新数据
    base_request[request.id] = nil
    club_request[request.club_id][msg.request_id] = nil
    club_member[request.club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        op_type = msg.op,
    })
end

local function on_cs_club_reject_request(msg,guid)
    dump(msg)
    local player = base_players[guid]
    if not player then
        log.error("unknown player when reject request request_id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
            op = msg.op,
        })
        return
    end

    local request = base_request[tonumber(msg.request_id)]
    if not request then
        log.error("unknown request when reject request request_id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_OP_EXPIRE,
            op = msg.op,
        })
        return
    end

    local club = base_clubs[request.club_id]
    if not club then
        log.error("unkonw club_id when reject request,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            request_id = msg.request_id,
        })
        return
    end

    if not club:reject_request(request) then
        log.error("reject request failed,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_OP_EXPIRE,
            request_id = msg.request_id,
        })

        return
    end

    player_request[request.whoee][request.id] = nil
    base_request[request.id] = nil
    club_member[request.club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        request_id = msg.request_id,
    })
end

local function on_cs_club_partner(msg,guid)
    local club_id = msg.club_id
    local target_guid = msg.target_id
    local res = {
        club_id = club_id,
        target_id = target_guid,
        op = msg.op,
        result = enum.ERROR_NONE,
    }

    if not base_clubs[club_id] then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if not club_member[club_id][target_guid] then
        res.result = enum.ERROR_NOT_IS_CLUB_MEMBER
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    local role = club_role[club_id][guid]
    if not role or (role ~= enum.CRT_BOSS and role ~= enum.CRT_ADMIN) then
        res.result = enum.ERROR_NOT_IS_CLUB_BOSS
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == club_op.ADD_PARTNER then
        local target_role = club_role[club_id][target_guid]
        if target_role == enum.CRT_BOSS or target_role == enum.CRT_PARTNER or target_role == enum.CRT_ADMIN  then
            res.result = enum.ERROR_NOT_IS_CLUB_BOSS
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        local id = math.random(1000000,9999999)
        for _ = 1,1000 do
            if not base_clubs[id] then break end
            id = math.random(1000000,9999999)
        end
    
        base_club:create(id,"","",target_guid,enum.CT_UNION,club_id)

        reddb:hset(string.format("club:role:%d",club_id),target_guid,enum.CRT_PARTNER)
        club_role[club_id][target_guid] = nil

        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == club_op.REMOVE_PARTNER then
        local target_role = club_role[club_id][target_guid]
        if target_role == enum.CRT_BOSS or target_role == enum.CRT_PARTNER or target_role == enum.CRT_ADMIN  then
            res.result = enum.ERROR_NOT_IS_CLUB_BOSS
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        reddb:hdel(string.format("club:role:%d",club_id),target_guid)
        club_role[club_id][target_guid] = nil
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end
end

local operator = {
    [club_op.ADD_ADMIN] = on_cs_club_administrator,
    [club_op.REMOVE_ADMIN] = on_cs_club_administrator,
    [club_op.OP_JOIN_AGREED] = on_cs_club_agree_request,
    [club_op.OP_JOIN_REJECTED] = on_cs_club_reject_request,
    [club_op.OP_EXIT_AGREED] = on_cs_club_agree_request,
    [club_op.OP_APPLY_EXIT] = on_cs_club_exit,
    [club_op.ADD_PARTNER] = on_cs_club_partner,
    [club_op.REMOVE_PARTNER] = on_cs_club_partner,
}

function on_cs_club_operation(msg,guid)
    local f = operator[msg.op]
    if f then
        f(msg,guid)
    end
end


function on_cs_club_kickout(msg,guid)

end

function on_cs_club_dismiss_table(msg,guid)

end


function on_cs_club_team_list(msg,guid)
    local club_id = msg.club_id

    if not base_clubs[club_id] then
        onlineguid.send(guid,"S2C_CLUB_TEAM_LIST_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CLUB_TEAM_LIST_RES",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS,
        })
        return
    end

    local teams = {}
    local team_ids = club_team[club_id]
    for team_id,_ in pairs(team_ids) do
        local team_club = base_clubs[team_id]
        local team_money_id = club_money_type[team_id]
        local boss = base_players[team_club.owner]
        local moneies = {{
            money_id = team_money_id,
            count = club_money[team_id][team_money_id]
        }}
        table.insert(teams,{
            base = team_club,
            boss = {
                guid = boss.guid,
                icon = boss.icon,
                nickname = boss.nickname,
                sex = boss.sex,
            },
            money = moneies,
            money_id = team_money_id,
            commission = 0,
        })
    end

    onlineguid.send(guid,"S2C_CLUB_TEAM_LIST_RES",{
        result = enum.ERROR_NONE,
        teams = teams,
    })
end

local function transfer_money_player2club(source_guid,target_club_id,money,guid)
    local res = {
        result = enum.ERROR_NONE,
        source_type = 0,
        target_type = 1,
        source_id = source_guid,
        target_id = target_club_id,
    }

    local p = base_players[source_guid]
    if not p then
        res.result = enum.ERROR_PLAYER_NOT_EXIST
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local club = base_clubs[target_club_id]
    if not club then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if not club_member[target_club_id][source_guid] then
        res.result = enum.ERROR_NOT_IS_CLUB_MEMBER
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local role = club_role[target_club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        res.result = enum.ERROR_NOT_IS_CLUB_BOSS
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local money_id = club_money_type[target_club_id]

    local orgin_money = player_money[source_guid][money_id]
    if orgin_money < money then
        res.result = enum.ERORR_PARAMETER_ERROR
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    -- reddb:multi()

    if not p:incr_money({
        money_id = money_id,
        money = -money,
    },enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return        
    end

    if not club:incr_money({
        money_id = money_id,
        money = money,
    },enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    -- reddb:exec()

    onlineguid.send(p.guid,"SYNC_OBJECT",util.format_sync_info(
        "PLAYER",{
            guid = p.guid,
            club_id = club.id,
            money_id = money_id,
        },{
            money = player_money[p.guid][money_id],
        }))

    onlineguid.send(club.owner,"SYNC_OBJECT",util.format_sync_info(
        "CLUB",{
            id = club.id,
            money_id = money_id,
        },{
            money = club_money[club.id][money_id],
        }))

    onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
end

local function transfer_money_club2club(source_club_id,target_club_id,money,guid)
    local res = {
        result = enum.ERROR_NONE,
        source_type = 1,
        target_type = 1,
        source_id = source_club_id,
        target_id = target_club_id,
    }

    local sourceclub = base_clubs[source_club_id]
    if not sourceclub then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local targetclub = base_clubs[target_club_id]
    if not targetclub then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    
    local parent_club_id = club_team[source_club_id][target_club_id] and source_club_id or
        (club_team[target_club_id][source_club_id] and target_club_id or nil)
    if not parent_club_id then
        res.result = enum.ERROR_NOT_IS_CLUB_MEMBER
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local role = club_role[parent_club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        res.result = enum.ERROR_NOT_IS_CLUB_BOSS
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local why = parent_club_id == source_club_id and enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB or enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB
    local money_id = club_money_type[target_club_id]

    local orgin_money = club_money[source_club_id][money_id]
    if orgin_money < money then
        res.result = enum.ERORR_PARAMETER_ERROR
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    -- reddb:multi()

    if not sourceclub:incr_money({
        money_id = money_id,
        money = -money,
    },why) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if not targetclub:incr_money({
        money_id = money_id,
        money = money,
    },why) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    -- reddb:exec()

    onlineguid.send(sourceclub.owner,"SYNC_OBJECT",util.format_sync_info(
        "CLUB",{
            id = sourceclub.id,
            money_id = money_id,
        },{
            money = club_money[sourceclub.id][money_id],
        }))

    onlineguid.send(targetclub.owner,"SYNC_OBJECT",util.format_sync_info(
        "CLUB",{
            id = targetclub.id,
            money_id = money_id,
        },{
            money = club_money[targetclub.id][money_id],
        }))

    onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
end

local function transfer_money_club2player(source_club_id,target_guid,money,guid)
    local res = {
        result = enum.ERROR_NONE,
        source_type = 0,
        target_type = 1,
        source_id = source_club_id,
        target_id = target_guid,
    }

    local p = base_players[target_guid]
    if not p then
        res.result = enum.ERROR_PLAYER_NOT_EXIST
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local club = base_clubs[source_club_id]
    if not club then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if not club_member[source_club_id][target_guid] then
        res.result = enum.ERROR_NOT_IS_CLUB_MEMBER
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local role = club_role[source_club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        res.result = enum.ERROR_NOT_IS_CLUB_BOSS
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local money_id = club_money_type[source_club_id]

    local orgin_money = club_money[source_club_id][money_id]
    if orgin_money < money then
        res.result = enum.ERORR_PARAMETER_ERROR
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    -- reddb:multi()

    if not p:incr_money({
        money_id = money_id,
        money = money,
    },enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if not club:incr_money({
        money_id = money_id,
        money = -money,
    },enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end
    -- reddb:exec()

    onlineguid.send(p.guid,"SYNC_OBJECT",util.format_sync_info(
        "PLAYER",{
            guid = p.guid,
            club_id = club.id,
            money_id = money_id,
        },{
            money = player_money[p.guid][money_id],
        }))

    onlineguid.send(club.owner,"SYNC_OBJECT",util.format_sync_info(
        "CLUB",{
            id = club.id,
            money_id = money_id,
        },{
            money = club_money[club.id][money_id],
        }))

    onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
end

function on_cs_transfer_money(msg,guid)
    local source_type = msg.source_type
    local target_type = msg.target_type
    local money = msg.money

    local res = {
        result = enum.ERORR_PARAMETER_ERROR,
        source_type = 0,
        target_type = 1,
        money = money,
        source_id = msg.source_id,
        target_id = msg.target_id,
    }

    if money <= 0 then
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if source_type == 0 then
        if target_type == 1 then
            transfer_money_player2club(msg.source_id,msg.target_id,money,guid)
            return
        end
    end

    if source_type == 1 then
        if target_type == 0 then
            transfer_money_club2player(msg.source_id,msg.target_id,money,guid)
            return
        end

        if target_type == 1 then
            transfer_money_club2club(msg.source_id,msg.target_id,money,guid)
            return
        end
    end

    onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
end

function on_cs_exchagne_club_commission(msg,guid)
    local club_id = msg.club_id
    local count = msg.count

    if not count or not club_id then
        onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
            result = enum.ERORR_PARAMETER_ERROR,
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS,
        })
        return
    end

    local commission = club_commission[club_id]
    if count < 0 then
        count = commission
    end

    local result = club:exchange_commission(count)
    onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
        result = result,
        club_id = club_id,
    })
end

function on_cs_club_money(msg,guid)
    local club_id = msg.club_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_MONEY_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CLUB_MONEY_RES",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS
        })
        return
    end

    local money_id = club_money_type[club_id]
    onlineguid.send(guid,"S2C_CLUB_MONEY_RES",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        money_id = money_id,
        count = club_money[club_id][money_id],
        commission = club_commission[club_id] or 0,
    })
end