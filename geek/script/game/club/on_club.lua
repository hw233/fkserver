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
local club_team_template_conf = require "game.club.club_team_template_conf"
local util = require "util"
local enum = require "pb_enums"
local json = require "cjson"
local club_fast_template = require "game.club.club_fast_template"
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
    OPEN_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OPEN_CLUB"),
}

local function rand_union_club_id()
    local id_begin = (math.random(10) > 5 and 6 or 8) * 10000000
    local id_end = id_begin + 9999999
    local id = math.random(id_begin,id_end)
    for _ = 1,1000 do
        if not base_clubs[id] then break end
        id = math.random(id_begin,id_end)
    end

    return id
end

local function rand_group_club_id()
    local id_begin = (math.random(10) > 5 and 6 or 8) * 100000
    local id_end = id_begin + 99999
    local id = math.random(id_begin,id_end)
    for _ = 1,1000 do
        if not base_clubs[id] then break end
        id = math.random(id_begin,id_end)
    end

    return id
end

local function recusive_is_in_club(club,guid)
    if not club or not guid then return end
    return table.logic_or(club_member[club.id] or {},function(_,pid) return guid == pid end)
        or table.logic_or(club_team[club] or {},function(_,teamid)
            return recusive_is_in_club(base_clubs[teamid],guid)
        end)
end

local function import_union_player_from_group(from,to)
    local root = club_utils.root(to)
    local members = club_member[from.id]
    local guids = table.series(members or {},function(_,guid)
        if not recusive_is_in_club(root,guid) then
            return guid
        end
    end)

    if table.nums(guids) == 0 then
        return
    end

    to:batch_join(guids)
    return true
end

function on_bs_club_create(owner,name)
    local guid = owner
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
        return
    end

    if player.role ~= 1 then
        return enum.ERROR_PLAYER_NO_RIGHT
    end

    local id = rand_union_club_id()

    base_club:create(id,name or "","",player,enum.CT_UNION)

    -- 初始送分 金币
    base_clubs[id]:incr_money({
        money_id = club_money_type[id],
        money = math.floor(global_cfg.union_init_money),
    },enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)

    return enum.ERROR_NONE,id
end


function on_bs_club_create_with_group(group_id,name)
    local group = base_clubs[group_id]
    if not group then
        return enum.ERROR_CLUB_NOT_FOUND
    end

    if group.type ~= enum.CT_DEFAULT then
        return enum.ERORR_PARAMETER_ERROR
    end

    local player = base_players[group.owner]
    if not player then
        return enum.ERROR_PLAYER_NOT_EXIST
    end

    local id = rand_union_club_id()
    base_club:create(id,name or "","",player,enum.CT_UNION)

    base_clubs[id]:incr_money({
        money_id = club_money_type[id],
        money = math.floor(global_cfg.union_init_money),
    },enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)

    local son_club_id = rand_union_club_id()
    base_club:create(son_club_id,group.name,"",player,enum.CT_UNION,id)
    local son_club = base_clubs[son_club_id]

    import_union_player_from_group(son_club,group)

    return enum.ERROR_NONE,id
end

function on_cs_club_create(msg,guid)
    local club_info = msg.info
    local player = base_players[guid]
    if not player then
        log.error("internal error,recv msg but no player.")
        onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
        })

        return
    end

    log.dump(player)

    local id = rand_group_club_id()

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

function on_cs_club_import_player_from_group(msg,guid)
    local to_id = msg.club_id
    local from_id = msg.group_id
    local from = base_clubs[from_id]
    local to = base_clubs[to_id]

    if not from or not to then
        onlineguid.send(guid,"S2C_IMPORT_PLAYER_FROM_GROUP",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    log.dump(from)
    log.dump(to)

    if from.type ~= enum.CT_DEFAULT or to.type ~= enum.CT_UNION then
        onlineguid.send(guid,"S2C_IMPORT_PLAYER_FROM_GROUP",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local to_role = club_role[to_id][guid]
    local from_role = club_role[from_id][guid]

    if to.owner ~= guid or from.owner ~= guid or from_role ~= to_role then
        onlineguid.send(guid,"S2C_IMPORT_PLAYER_FROM_GROUP",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    import_union_player_from_group(from,to)
    onlineguid.send(guid,"S2C_IMPORT_PLAYER_FROM_GROUP",{
        result = enum.ERROR_NONE
    })
end


function on_cs_club_create_club_with_mail(msg,guid)
    log.dump(msg)
    local mail = base_mails[msg.mail_id]
    if not mail or mail.status ~= 0 then
        log.error("on_cs_club_create_club_with_req no request,%s.",msg.mail_id)
        onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
            result = enum.ERROR_OPERATION_EXPIRE,
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
            result = enum.ERROR_OPERATION_INVALID,
        })

        return
    end

    if player.role ~= 1 then
        onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
            result = enum.CLUB_OP_RESULT_SUCCESS,
        })
        return
    end

    local root = club_utils.root(inviter_club)
    for cid,_ in pairs(player_club[guid][enum.CT_UNION]) do
        local c = base_clubs[cid]
        if c and club_utils.root(c) == root then
            onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
                result = enum.ERROR_AREADY_MEMBER
            })
            return
        end
    end

    local role = club_role[inviter_club_id][guid]
    if role == enum.CRT_BOSS then
        return
    end

    local id = rand_union_club_id()

    local club_info = msg.club_info

    base_club:create(id,club_info.name,club_info.icon,player,enum.CT_UNION,inviter_club.id)
	if not id then
        onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
            result = enum.CLUB_OP_RESULT_FAILED,
            id = id,
        })
        return
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
            result = enum.ERROR_AREADY_MEMBER,
        })
        return
    end

    if not base_players[guid] then
        log.warning("invite join club but inviter is not exists,guid:%s",guid)
        onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
            result = enum.ERROR_OPERATION_INVALID,
        })
        return
    end

    if invite_type == "invite_join" then
        if not base_players[invitee] then
            onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
                    result = enum.ERROR_PLAYER_NOT_EXIST
                })
            return
        end

        local root = club_utils.root(club)
        for cid,_ in pairs(player_club[invitee][enum.CT_UNION]) do
            local c = base_clubs[cid]
            if c and club_utils.root(c) == root then
                onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
                    result = enum.ERROR_AREADY_MEMBER
                })
                return
            end
        end
    elseif invite_type == "invite_create" then
        local p = base_players[invitee]
        if not p then
            onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
                result = enum.ERROR_PLAYER_NOT_EXIST,
            })
            return
        end

        if p.role ~= 1 then
            onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
                result = enum.ERROR_PLAYER_NO_RIGHT,
            })
            return
        end

        local root = club_utils.root(club)
        for cid,_ in pairs(player_club[invitee][enum.CT_UNION]) do
            local c = base_clubs[cid]
            if c and club_utils.root(c) == root then
                onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
                    result = enum.ERROR_AREADY_MEMBER
                })
                return
            end
        end
    end

    local code = club:invite_join(invitee,guid,club,invite_type)
    onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
        result = code,
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
    if not club then return {} end
    local ct = club_table[club.id] or {}
    local tables = table.series(ct,function(_,tid)
        local priv_tb = base_private_table[tid]
        local tableinfo = channel.call("game."..priv_tb.room_id,"msg","GetTableStatusInfo",priv_tb.real_table_id)
        return tableinfo
    end)

    return tables
end

local function deep_get_club_tables(club,getter_role)
    local tables = get_club_tables(club,getter_role)
    for teamid,_ in pairs(club_team[club.id]) do
        local team = base_clubs[teamid]
        if team then
            table.unionto(tables,deep_get_club_tables(team,getter_role))
        end
    end

    return tables
end

local function is_template_visiable(club,template)
    local conf = club_team_template_conf[club.id][template.template_id]
    local visiable = (not conf or conf.visual == nil) and true or conf.visual
    if visiable and club.parent and club.parent ~= 0 then
        local parent = base_clubs[club.parent]
        visiable = visiable and is_template_visiable(parent,template)
    end
    return visiable
end

local function get_club_templates(club,getter_role)
    if not club then return {} end

    local ctt = club_template[club.id] or {}
    local templates = table.series(ctt,function(_,tid) return table_template[tid] end)

    table.unionto(templates,get_club_templates(base_clubs[club.parent],getter_role) or {})

    return templates
end

local function get_visiable_club_templates(club,getter_role)
    local templates = get_club_templates(club,getter_role)
    return table.series(templates,function(template)
        local visiable = is_template_visiable(club,template)
        if  visiable or
            getter_role == enum.CRT_BOSS or getter_role == enum.CRT_ADMIN then
            return template
        end
    end)
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

    local ss = channel.query()
    local games = table.agg(ss,{},function(tb,_,sid)
        local id = sid:match("service%.(%d+)")
        if not id then  return tb end

        local conf = serviceconf[tonumber(id)]
        if conf.name ~= "game" then return tb end

        local sconf = conf.conf
        tb[sconf.first_game_type] = sconf

        return tb
    end)

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

    local function recusive_parent_status(c)
        local parent = c.parent
        if not parent or parent == 0 then return 0 end
        c = base_clubs[parent]
        if not c then return 0 end

        return (not c.status or c.status == 0) and recusive_parent_status(c) or c.status
    end

    local club_status = {
        status = club.status,
        player_count = total_count,
        online_player_count = online_count,
        status_in_club = recusive_parent_status(club),
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

    local templates = get_visiable_club_templates(club,role)
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
        },{
            money_id = 0,
            count = club_money[club_id][0] or 0,
        }},
        money_id = money_id,
        commission = (role == enum.CRT_BOSS or role == enum.CRT_ADMIN) and club_commission[club_id] or 0,
    }

    local function get_fast_templates(cid)
        if not cid then return {} end
        local fast_templates = club_fast_template[cid]
        if table.nums(fast_templates) > 0 then return fast_templates end
        local c = base_clubs[cid]
        if not c or not c.parent or c.parent == 0 then return fast_templates end
        return table.union(fast_templates,get_fast_templates(c.parent))
    end

    local club_info = {
        root = root.id,
        result = enum.ERROR_NONE,
        self_info = team_info,
        my_team_info = my_team_info,
        status = club_status,
        table_list = tables,
        gamelist = real_games,
        fast_templates = get_fast_templates(club_id),
        table_templates = table.series(templates,function(template)
            return {
                club_id = template.club_id,
                template = {
                    template_id = template.template_id,
                    game_id = template.game_id,
                    description = template.description,
                    rule = json.encode(template.rule),
                }
            }
        end),
    }

    onlineguid.send(guid,"S2C_CLUB_INFO_RES",club_info)
end

function on_cs_club_list(msg,guid)
    log.info("on_cs_club_list,guid:%s,%s,%s",guid,msg.type,msg.owned_myself)
    local clubs = table.series(player_club[guid][msg.type or enum.CT_DEFAULT],function(_,cid)
        return base_clubs[cid]
    end)

    if msg.owned_myself then
        clubs = table.select(clubs,function(c) return c.owner == guid end)
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
            result = enum.ERROR_PLAYER_NO_RIGHT,
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
    log.dump(msg)
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
            result = enum.ERROR_AREADY_MEMBER,
        })
        return
    end

    for req_id,_ in pairs(club_request[club_id]) do
        local req = base_request[req_id]
        if req and req.who == guid and req.type == "join" then
            onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
                result = enum.ERROR_REQUEST_REPEATED,
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
            result = enum.ERROR_PLAYER_NO_RIGHT,
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
    if self_role ~= enum.CRT_BOSS or self_role == enum.CRT_ADMIN  then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end


    if msg.op == club_op.ADD_ADMIN then
        if not club_member[club_id][target_guid] then
            res.result = enum.ERROR_NOT_MEMBER
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        local role = club_role[club_id][target_guid]
        if role == enum.CRT_BOSS or role == enum.CRT_PARTNER or role == enum.CRT_ADMIN then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        reddb:hset(string.format("club:role:%d",club_id),target_guid,enum.CRT_ADMIN)
        res.result = enum.ERROR_NONE
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == club_op.REMOVE_ADMIN then
        if not club_member[club_id][target_guid] then
            res.result = enum.ERROR_NOT_MEMBER
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        local role = club_role[club_id][target_guid]
        if role ~= enum.CRT_ADMIN then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
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
            result = enum.ERROR_OPERATION_INVALID,
            op_type = msg.op,
        })
        return
    end

    local err = request:agree()
    if err ~= enum.ERROR_NONE then
        log.error("agree request failed,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = err,
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
    log.dump(msg)
    local player = base_players[guid]
    if not player then
        log.error("unknown player when reject request request_id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_OPERATION_INVALID,
            op = msg.op,
        })
        return
    end

    local request = base_request[tonumber(msg.request_id)]
    if not request then
        log.error("unknown request when reject request request_id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_OPERATION_EXPIRE,
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

    local err = club:reject_request(request)
    if err ~= enum.ERROR_NONE then
        log.error("reject request failed,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = err,
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
        res.result = enum.ERROR_NOT_MEMBER
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    local role = club_role[club_id][guid]
    if not role or (role ~= enum.CRT_BOSS and role ~= enum.CRT_ADMIN) then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == club_op.ADD_PARTNER then
        local target_role = club_role[club_id][target_guid]
        if target_role == enum.CRT_BOSS or target_role == enum.CRT_PARTNER or target_role == enum.CRT_ADMIN  then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
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
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        reddb:hdel(string.format("club:role:%d",club_id),target_guid)
        club_role[club_id][target_guid] = nil
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end
end

local function on_cs_club_kickout_club_boss(msg,guid)
    log.dump(msg)
    local club_id = msg.club_id
    local boss_guid = msg.target_id

    local club
    for cid,_ in pairs(player_club[boss_guid][enum.CT_UNION]) do
        local c = base_clubs[cid]
        if c.owner == boss_guid then
            club = c
            break
        end
    end

    if not club then 
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            op = club_op.OP_EXIT_AGREED,
            target_id = boss_guid,
        })
        return
    end

    log.dump(club)

    local function is_member_in_gaming(c)
        if not c then return false end
        return table.logic_or(club_member[c.id] or {},function(_,mid)
            local os = onlineguid[mid]
            return os and os.table
        end)
    end

    local function member_money_sum(c,money_id)
        return table.sum(club_member[c.id] or {},function(_,mid)
            return player_money[mid][money_id] or 0
        end)
    end

    local function deep_is_member_in_gaming(c,money_id)
        local gaming = is_member_in_gaming(c,money_id)
        if gaming then return true end
        local teamids = club_team[c.id]
        return table.logic_or(teamids,function(_,teamid)
            local team = base_clubs[teamid]
            return team and deep_is_member_in_gaming(team,money_id)
        end)
    end

    local function deep_member_money_sum(c,money_id)
        local sum = member_money_sum(c,money_id) + (club_money[c.id][money_id] or 0) + (club_commission[c.id] or 0)
        local teamids = club_team[c.id]
        return sum + table.sum(teamids,function(_,teamid)
            local team = base_clubs[teamid]
            return team or deep_member_money_sum(team) or 0
        end)
    end

    if deep_is_member_in_gaming(club) then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_IN_GAME,
            op = club_op.OP_EXIT_AGREED,
            target_id = boss_guid,
        })
        return
    end

    local money_id = club_money_type[club.id]
    local member_money = deep_member_money_sum(club,money_id)
    if member_money > 0 then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_MORE_MAX_LIMIT,
            op = club_op.OP_EXIT_AGREED,
            target_id = boss_guid,
        })
        return
    end

    local function deep_dismiss_club(c,money_id)
        local teamids = club_team[c.id]
        if not teamids or table.nums(teamids) == 0 then
            c:dismiss()
            if c.parent and c.parent ~= 0 then
                local role = club_role[c.parent][c.owner]
                if role == enum.CRT_PARTNER then
                    reddb:hdel(string.format("club:role:%d",c.parent),c.id)
                    club_role[c.parent][c.owner] = nil
                end
            end
        end

        return table.foreach(teamids,function(_,teamid)
            local team = base_clubs[teamid]
            return team and deep_dismiss_club(team,money_id)
        end)
    end

    deep_dismiss_club(club,money_id)

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        op = club_op.OP_EXIT_AGREED,
        target_id = boss_guid,
    })
end

function on_cs_club_kickout(msg,guid)
    local club_id = msg.club_id
    local target_guid = msg.target_id

    log.dump(msg)

    local player = base_players[guid]
    if not player then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local target_role = club_role[club_id][target_guid]
    if target_role == enum.CRT_ADMIN or target_role == enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local target = base_players[target_guid]
    if not target then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    if not club_member[club_id][target_guid] then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_NOT_MEMBER
        })
        return
    end

    local club_ids = player_club[target_guid][enum.CT_UNION]
    for cid,_ in pairs(club_ids) do
        local c = base_clubs[cid]
        if c and c.parent == club_id and c.owner == target_guid then
            on_cs_club_kickout_club_boss(msg,guid)
            return
        end
    end

    local os = onlineguid[target_guid]
    if os and os.table then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_IN_GAME
        })
        return
    end

    local money_id = club_money_type[club_id]
    if player_money[target_guid][money_id] > 0 then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_MORE_MAX_LIMIT
        })
        return
    end

    club:exit(target_guid)

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        op = club_op.OP_EXIT_AGREED,
        target_id = target_guid,
    })
end


local function on_cs_club_block(msg,guid,status)
    local club_id = msg.club_id
    local target_club_id = msg.target_id
    local op = (status == 0 and club_op.UNBLOCK_CLUB or club_op.BLOCK_CLUB)

    local player = base_players[guid]
    if not player then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
            op = op,
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            op = op,
        })
        return
    end

    if not target_club_id or target_club_id == 0  then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_OPERATION_INVALID,
            op = op,
        })
        return
    end

    local target_club = base_clubs[target_club_id]
    if not target_club then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERORR_PARAMETER_ERROR,
            op = op,
        })
        return
    end

    if club.type ~= enum.CT_UNION then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_OPERATION_INVALID,
            op = op,
        })
        return
    end

    if not club_member[club_id][guid] then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_NOT_MEMBER,
            op = op,
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NO_RIGHT,
            op = op,
        })
        return
    end

    if target_club.parent ~= club_id then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_OPERATION_INVALID,
            op = op,
        })
        return
    end

    reddb:hmset(string.format("club:info:%d",target_club_id),{
        status = status
    })

    base_clubs[target_club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        op = op,
        club_id = club_id,
    })
end

local function on_cs_club_close(msg,guid,status)
    local club_id = msg.club_id
    local oper = (status == 0 and club_op.OPEN_CLUB or club_op.CLOSE_CLUB)

    local player = base_players[guid]
    if not player then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
            op = oper,
        })
        return
    end

    local club = base_clubs[club_id] 
    if not club then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            op = oper,
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERORR_PARAMETER_ERROR,
            op = oper,
        })
        return
    end

    reddb:hmset(string.format("club:info:%d",club_id),{
        status = status
    })

    base_clubs[club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        op = oper,
        club_id = club_id,
    })
end

local operator = {
    [club_op.ADD_ADMIN] = on_cs_club_administrator,
    [club_op.REMOVE_ADMIN] = on_cs_club_administrator,
    [club_op.OP_JOIN_AGREED] = on_cs_club_agree_request,
    [club_op.OP_JOIN_REJECTED] = on_cs_club_reject_request,
    [club_op.OP_EXIT_AGREED] = on_cs_club_kickout,
    [club_op.OP_APPLY_EXIT] = on_cs_club_exit,
    [club_op.ADD_PARTNER] = on_cs_club_partner,
    [club_op.REMOVE_PARTNER] = on_cs_club_partner,
    [club_op.BLOCK_CLUB] = function(msg,guid) on_cs_club_block(msg,guid,2) end,
    [club_op.UNBLOCK_CLUB] = function(msg,guid) on_cs_club_block(msg,guid,0) end,
    [club_op.CLOSE_CLUB] = function(msg,guid) on_cs_club_close(msg,guid,1) end,
    [club_op.OPEN_CLUB] = function(msg,guid) on_cs_club_close(msg,guid,0) end,
}

function on_cs_club_operation(msg,guid)
    local f = operator[msg.op]
    if f then
        f(msg,guid)
    end
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
            result = enum.ERROR_PLAYER_NO_RIGHT,
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
            status = team_club.status,
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
        res.result = enum.ERROR_NOT_MEMBER
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local role = club_role[target_club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
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

    local recharge_id = channel.call("db.?","msg","SD_LogRecharge",{
        source_id = source_guid,
        target_id = target_club_id,
        type = 2,
        operator = guid,
    })

    -- reddb:multi()

    if not p:incr_money({
        money_id = money_id,
        money = -money,
    },enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,recharge_id) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return        
    end

    if not club:incr_money({
        money_id = money_id,
        money = money,
    },enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,recharge_id) then
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
        res.result = enum.ERROR_NOT_MEMBER
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local role = club_role[parent_club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
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

    local recharge_id = channel.call("db.?","msg","SD_LogRecharge",{
        source_id = source_club_id,
        target_id = target_club_id,
        type = 3,
        operator = guid,
    })

    -- reddb:multi()

    if not sourceclub:incr_money({
        money_id = money_id,
        money = -money,
    },why,recharge_id) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if not targetclub:incr_money({
        money_id = money_id,
        money = money,
    },why,recharge_id) then
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
        res.result = enum.ERROR_NOT_MEMBER
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local role = club_role[source_club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
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

    local recharge_id = channel.call("db.?","msg","SD_LogRecharge",{
        source_id = source_club_id,
        target_id = target_guid,
        type = 1,
        operator = guid,
    })

    -- reddb:multi()

    if not p:incr_money({
        money_id = money_id,
        money = money,
    },enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,recharge_id) then
        -- reddb:discard()
        res.result = enum.ERROR_CLUB_UNKOWN
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if not club:incr_money({
        money_id = money_id,
        money = -money,
    },enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,recharge_id) then
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
            result = enum.ERROR_PLAYER_NO_RIGHT,
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
            result = enum.ERROR_PLAYER_NO_RIGHT
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

function on_cs_config_fast_game_list(msg,guid)
    log.info("on_cs_config_fast_game_list")
    local player = base_players[guid]
    if not player then
        onlineguid.send(guid,"S2C_CONFIG_FAST_GAME_LIST",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })

        return
    end

    local club_id = msg.club_id
    local template_ids = msg.template_ids
    if not club_id or not template_ids or table.nums(template_ids) == 0 then
        onlineguid.send(guid,"S2C_CONFIG_FAST_GAME_LIST",{
            result = enum.ERORR_PARAMETER_ERROR
        })

        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CONFIG_FAST_GAME_LIST",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })

        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CONFIG_FAST_GAME_LIST",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })

        return
    end

    local is = table.logic_and(template_ids,function(tid) return tid <= 0 or table_template[tid] ~= nil end)
    if not is then
        onlineguid.send(guid,"S2C_CONFIG_FAST_GAME_LIST",{
            result = enum.ERORR_PARAMETER_ERROR
        })

        return
    end

    reddb:hmset(string.format("club:fast_template:%d",club_id),template_ids)

    onlineguid.send(guid,"S2C_CONFIG_FAST_GAME_LIST",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        template_ids = template_ids,
    })
end