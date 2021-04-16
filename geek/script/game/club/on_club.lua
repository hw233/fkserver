local log = require "log"
local base_club = require "game.club.base_club"
local pb = require "pb_files"
local redisopt = require "redisopt"
local base_players = require "game.lobby.base_players"
local base_clubs = require "game.club.base_clubs"
local club_member = require "game.club.club_member"
local player_club = require "game.lobby.player_club"
local channel = require "channel"
local onlineguid = require "netguidopt"
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
local util = require "util"
local enum = require "pb_enums"
local json = require "json"
local club_fast_template = require "game.club.club_fast_template"
local crypt = require "skynet.crypt"
local url = require "url"
local club_partner = require "game.club.club_partner"
local club_member_partner = require "game.club.club_member_partner"
local club_partners = require "game.club.club_partners"
local club_partner_member = require "game.club.club_partner_member"
local club_partner_commission = require "game.club.club_partner_commission"
local club_block_groups = require "game.club.block.groups"
local club_block_group_players = require "game.club.block.group_players"
local club_block_player_groups = require "game.club.block.player_groups"
local club_conf = require "game.club.club_conf"
local club_team_player_count = require "game.club.club_team_player_count"
local club_team_money = require "game.club.club_team_money"
local club_partner_conf = require "game.club.club_partner_conf"
local club_gaming_blacklist = require "game.club.club_gaming_blacklist"
local game_util = require "game.util"

local gutil = require "util"

local queue = require "skynet.queue"

local money_locks = setmetatable({},{
    __index = function(t,money_id)
        local l = queue()
        t[money_id] = l
        return l
    end,
})

require "functions"

local invite_join_room_cd = 10

local g_room = g_room

local reddb = redisopt.default

local string = string
local table = table

local CLUB_OP = {
    ADD_ADMIN    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","ADD_ADMIN"),
    REMOVE_ADMIN    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_ADMIN"),
    JOIN_AGREED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","JOIN_AGREED"),
    JOIN_REJECTED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","JOIN_REJECTED"),
    EXIT_AGREED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","EXIT_AGREED"),
    APPLY_EXIT    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","APPLY_EXIT"),
    ADD_PARTNER = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","ADD_PARTNER"),
    REMOVE_PARTNER = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_PARTNER"),
    CANCEL_FORBID = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","CANCEL_FORBID"),
    FORBID_GAME = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","FORBID_GAME"),
    BLOCK_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","BLOCK_CLUB"),
    UNBLOCK_CLUB    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","UNBLOCK_CLUB"),
    CLOSE_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","CLOSE_CLUB"),
    OPEN_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OPEN_CLUB"),
    DISMISS_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","DISMISS_CLUB"),
}

function on_bs_club_create(owner,name,type,creator)
    local guid = owner

    log.dump(creator)
    local player = base_players[guid]
    if not player then
        log.error("internal error,recv msg but no player.")
        return
    end

    if player.role ~= 1 then
        return enum.ERROR_PLAYER_NO_RIGHT
    end

    local id
    if type == 1 then
        id = club_utils.rand_union_club_id()
        local club = base_club:create(id,name or "","",player,enum.CT_UNION,nil,creator)
        club:incr_member_money(guid,math.floor(global_conf.union_init_money),enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)
        game_util.log_statistics_money(club_money_type[club.id],global_conf.union_init_money,enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)
    else
        id = club_utils.rand_group_club_id()
        base_club:create(id,name or "","",player,enum.CT_DEFAULT,nil,creator)
    end

    return enum.ERROR_NONE,id
end


function on_bs_club_create_with_group(group_id,name)
    local group = base_clubs[group_id]
    if not group then
        return enum.ERROR_CLUB_NOT_FOUND
    end

    if group.type ~= enum.CT_DEFAULT then
        return enum.ERROR_PARAMETER_ERROR
    end

    local player = base_players[group.owner]
    if not player then
        return enum.ERROR_PLAYER_NOT_EXIST
    end

    local id = club_utils.rand_union_club_id()
    local club = base_club:create(id,name or "","",player,enum.CT_UNION)

    club:incr_member_money(player.guid,math.floor(global_conf.union_init_money),enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)

    local son_club_id = club_utils.rand_union_club_id()
    base_club:create(son_club_id,group.name,"",player,enum.CT_UNION,id)
    local son_club = base_clubs[son_club_id]

    club_utils.import_union_player_from_group(son_club,group)

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

    local id = club_utils.rand_group_club_id()

    local club = base_club:create(id,club_info.name,club_info.icon,player,club_info.type,club_info.parent)

    -- 初始送分 金币
    club:incr_member_money(guid,math.floor(global_conf.union_init_money),enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)
    game_util.log_statistics_money(club_money_type[club.id],math.floor(global_conf.union_init_money),enum.LOG_MONEY_OPT_TYPE_INIT_GIFT)

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
            result = enum.ERROR_PARAMETER_ERROR
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

    club_utils.import_union_player_from_group(from,to)
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

    local id = club_utils.rand_union_club_id()

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

        local inviter_role = club_role[club_id][guid]
        if not inviter_role or inviter_role == enum.CRT_PLAYER then
            onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
                result = enum.ERROR_PLAYER_NO_RIGHT
            })
            return
        end

        if player_club[invitee][enum.CT_UNION][invitee] then
            onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
                result = enum.ERROR_AREADY_MEMBER
            })
            return
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

    local result = club:invite_join(invitee,guid,club,invite_type)
    onlineguid.send(guid,"S2C_INVITE_JOIN_CLUB",{
        result = result,
    })

    player_request[club.owner] = nil
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

    local real_games =  club_utils.get_game_list(guid,club_id)
    local root = club_utils.root(club)
    local tables = club_utils.get_club_tables(root)

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

    local role = club_role[club_id][guid] or enum.CRT_PLAYER

    local templates = club_utils.get_visiable_club_templates(club,role)
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
        commission = (role == enum.CRT_BOSS or role == enum.CRT_PARTNER) and club_partner_commission[club_id][guid] or 0,
    }

    local function get_fast_templates(cid)
        if not cid then return {} end
        local fast_templates = club_fast_template[cid]
        if table.nums(fast_templates) > 0 then return fast_templates end
        local c = base_clubs[cid]
        if not c or not c.parent or c.parent == 0 then return fast_templates end
        return table.union(fast_templates,get_fast_templates(c.parent))
    end

    local keygames = table.map(real_games,function(g) return g,true end)
    templates = table.select(templates,function(t) return keygames[t.game_id] end)
    
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

    if club_utils.is_recursive_in_club(club_utils.root(club),guid) then
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
    local partner = msg.partner
    local owner = partner or guid
    local req_role = msg.role
    local page_num = msg.page_num
    local page_size = msg.page_size

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_PLAYER_LIST_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            club_id = club_id,
        })
        return
    end

    local self_role = club_role[club_id][guid]
    if not self_role or self_role == enum.CRT_PLAYER then
        onlineguid.send(guid,"S2C_CLUB_PLAYER_LIST_RES",{
            result = enum.ERROR_PLAYER_NO_RIGHT,
            club_id = club_id,
        })
        return
    end

    local owner_role = club_role[club_id][owner]
    if not owner_role or owner_role == enum.CRT_PLAYER then
        onlineguid.send(guid,"S2C_CLUB_PLAYER_LIST_RES",{
            result = enum.ERROR_PARAMETER_ERROR,
            club_id = club_id,
        })
        return
    end

    if self_role == enum.CRT_ADMIN and partner == guid then
        partner = club.owner
    end

    local money_id = club_money_type[club_id]
    local key = (partner and partner ~= 0) and 
        string.format("club:partner:zmember:%s:%s",club_id,partner) or 
        string.format("club:zmember:%s",club_id)

    local page_index = page_num and page_num - 1 or 0
    page_size = page_size or 30
    page_size = page_size > 100 and 100 or page_size

    local score_min = (req_role and req_role ~= 0) and req_role or enum.CRT_PLAYER
    local score_max = (req_role and req_role ~= 0) and req_role or enum.CRT_BOSS

    local total_size = reddb:zcount(key,score_min,score_max)
    local mems = page_size > 0 and 
        reddb:zrevrangebyscore(key,score_max,score_min,"limit",page_index * page_size,page_size) or
        reddb:zrevrangebyscore(key,score_max,score_min)
    
    if partner and partner ~= 0 then
        table.insert(mems,1,partner)
    end

    local yesterday = gutil.timestamp_date(os.time() - util.day_seconds())
    local logs = channel.call("db.?","msg","SD_QueryPlayerStatistics",mems,club_id,partner,yesterday)

    logs = table.group(logs,function(c) return c.guid end)

    local ms = table.series(mems,function(m)
        local p = base_players[tonumber(m)]
        if not p then return end

        local role = club_role[club_id][p.guid] or enum.CRT_PLAYER
        if not req_role or req_role == 0 or req_role == role then
            return {
                info = {
                    guid = p.guid,
                    icon = p.icon,
                    nickname = p.nickname,
                    sex = p.sex,
                },
                role = role,
                money = {
                    money_id = money_id,
                    count = player_money[p.guid][money_id] or 0,
                },
                team_money = {
                    money_id = money_id,
                    count = club_team_money[club_id][p.guid] or 0,
                },
                commission = club_partner_commission[club_id][p.guid] or 0,
                extra_data = json.encode({
                    info = {
                        guid = p.guid,
                        player_count = (club_team_player_count[club_id][p.guid] or 0) + 1,
                        money = (club_team_money[club_id][p.guid] or 0) + (player_money[p.guid][money_id] or 0)
                    },
                    logs = logs[p.guid] and table.values(logs[p.guid]) or nil,
                    conf = {
                        credit = club_partner_conf[club_id][p.guid].credit or 0,
                    },
                }),
                parent = club_member_partner[club_id][p.guid],
                block_gaming = club_gaming_blacklist[club_id][p.guid],
            }
        end
    end)

    onlineguid.send(guid,"S2C_CLUB_PLAYER_LIST_RES",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        player_list = ms,
        role = req_role,
        total_page = page_size > 0 and math.ceil(total_size / page_size) or 1,
        page_num = page_num, 
    })
end


function on_cs_club_exit_req(msg,guid)

end

function on_cs_club_request_list_req(msg,guid)
    local club_id = msg.club_id
    local reqs = table.series(club_request[club_id],function(_,rid) 
        local req = base_request[rid]
        if not req then return end

        local player = base_players[req.who]
        return {
            req_id = req.id,
            type = req.type,
            who = {
                guid = player.guid,
                nickname = player.nickname,
                icon = player.icon,
            },
        }
    end)

    onlineguid.send(guid,"S2C_CLUB_REQUEST_LIST_RES",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        reqs = reqs,
    })
end

local function on_cs_club_blacklist(msg,guid)
    local target_guid = msg.target_id
    local club_id = msg.club_id
    local op = msg.op
    local res = {
        club_id = club_id,
        target_id = target_guid,
        op = op,
        result = enum.ERROR_NONE,
    }

    local club = base_clubs[club_id]
    if not club then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    local self_role = club_role[club_id][guid]
    if not self_role or self_role == enum.CRT_PLAYER  then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    local target_role = club_role[club_id][target_guid]
    if target_role == enum.CRT_BOSS   then
        res.result = enum.ERROR_OPERATION_INVALID
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if not base_players[target_guid] then
        res.result = enum.ERROR_PLAYER_NOT_EXIST
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    local team_id = self_role == enum.CRT_ADMIN and club.owner or guid
    if not club_utils.is_recursive_in_team(club,team_id,target_guid) then
        res.result = enum.ERROR_NOT_MEMBER
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if op == CLUB_OP.FORBID_GAME then
        reddb:sadd("club:blacklist:gaming:"..tostring(club_id),target_guid)
        club_gaming_blacklist[club_id] = nil
        channel.publish("db.?","msg","SD_AddIntoClubGamingBlacklist",{
            club_id = club_id,
            guid  = target_guid,
        })
    elseif op == CLUB_OP.CANCEL_FORBID then
        reddb:srem("club:blacklist:gaming:"..tostring(club_id),target_guid)
        club_gaming_blacklist[club_id] = nil
        channel.publish("db.?","msg","SD_RemoveFromClubGamingBlacklist",{
            club_id = club_id,
            guid  = target_guid,
        })
    end

    onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
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


    if msg.op == CLUB_OP.ADD_ADMIN then
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
        reddb:zincrby(string.format("club:zmember:%s",club_id),enum.CRT_ADMIN - enum.CRT_PLAYER,target_guid)

        channel.publish("db.?","msg","SD_SetClubRole",{
            guid = target_guid,
            club_id = club_id,
            role = enum.CRT_ADMIN
        })
        res.result = enum.ERROR_NONE
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == CLUB_OP.REMOVE_ADMIN then
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
        reddb:zincrby(string.format("club:zmember:%s",club_id),enum.CRT_PLAYER - enum.CRT_ADMIN,target_guid)

        channel.publish("db.?","msg","SD_SetClubRole",{
            guid = target_guid,
            club_id = club_id,
        })

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
    
    if msg.op == CLUB_OP.REMOVE_PLAYER then
        base_clubs[msg.club_id].kickout(msg.guid)
    end
end

local function on_cs_club_exit(msg,guid)
    local operator = base_players[guid]
    local club_id = msg.club_id
    local role = club_role[club_id][guid]
    local exit_guid = msg.target_id
    local exit_role = club_role[club_id][exit_guid]
    if not operator or not role or role == enum.CRT_PLAYER 
        or exit_role == enum.CRT_BOSS or exit_role == enum.CRT_ADMIN then
        return enum.ERROR_PLAYER_NO_RIGHT
    end

    if exit_role == enum.CRT_PARTNER then
        return enum.ERROR_OPERATION_INVALID
    end
    
    if base_players[exit_guid] then
        local club = base_clubs[club_id]
        if not club then
            return enum.ERROR_CLUB_NOT_FOUND
        end

        club:full_exit(exit_guid,guid)
    end
    
    return enum.ERROR_NONE
end

local function on_cs_club_agree_join_club_with_share_id(msg,guid)
    local param = util.request_share_params(msg.sid)
    if not param or param.type ~= "joinclub" or not param.club or not param.guid then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_OPERATION_INVALID,
            op = msg.op,
        })
        return
    end

    local club = base_clubs[tonumber(param.club)]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            op = msg.op,
        })
        return
    end

    if club_utils.is_recursive_in_club(club_utils.root(club),guid) then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_AREADY_MEMBER,
            op = msg.op,
        })
        return
    end

    if not club.type or club.type == enum.CT_DEFAULT then
        club:request_join(guid)
    else
        local inviter = param.guid
        club:invite_join(guid,inviter,nil,"invite_join")
    end

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        op = msg.op,
    })
end

local function on_cs_club_agree_request(msg,guid)
    local player = base_players[guid]
    if not player then
        log.error("unknown player when agree request id:%s",msg.request_id)
        
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
            op = msg.op,
        })
        return
    end

    if not msg.request_id and (not msg.sid or msg.sid == "") then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PARAMETER_ERROR,
            op = msg.op,
        })
        return
    end

    if msg.sid and msg.sid ~= "" then
        on_cs_club_agree_join_club_with_share_id(msg,guid)
        return
    end

    local request = base_request[msg.request_id]
    if not request then
        log.error("unknown player when agree request id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_OPERATION_INVALID,
            op = msg.op,
        })
        return
    end

    local err = request:agree()
    if err ~= enum.ERROR_NONE then
        log.error("agree request failed,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = err,
            op = msg.op,
        })

        return
    end

    reddb:srem(string.format("player:request:%s",request.whoee),request.id)
    -- 更新数据
    base_request[request.id] = nil
    club_request[request.club_id][msg.request_id] = nil
    player_request[request.whoee][request.id] = nil
    club_member[request.club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        op = msg.op,
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

    local result = request:reject()
    if result ~= enum.ERROR_NONE then
        log.error("reject request failed,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = result,
            request_id = msg.request_id,
            op = msg.op,
        })

        return
    end

    reddb:srem(string.format("player:request:%s",request.whoee),request.id)
    player_request[request.whoee][request.id] = nil
    base_request[request.id] = nil
    club_member[request.club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        request_id = msg.request_id,
        op = msg.op,
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

    local club = base_clubs[club_id]
    if not club then
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
    if not role or role == enum.CRT_PLAYER then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == CLUB_OP.ADD_PARTNER then
        local target_role = club_role[club_id][target_guid]
        if target_role == enum.CRT_BOSS or target_role == enum.CRT_PARTNER or target_role == enum.CRT_ADMIN  then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        local parent = guid
        if role == enum.CRT_BOSS or role == enum.CRT_ADMIN then
            parent = club.owner
        end

        local result = club_partner:create(club_id,target_guid,parent)
        res.result = result
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == CLUB_OP.REMOVE_PARTNER then
        local target_role = club_role[club_id][target_guid]
        if target_role ~= enum.CRT_PARTNER then
            res.result = enum.ERROR_OPERATION_INVALID
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        if target_role == enum.CRT_BOSS or target_role == enum.CRT_ADMIN  then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        if role == enum.CRT_PARTNER then
            local parent = club_member_partner[club_id][target_guid]
            while parent do
                if parent == guid then
                    break
                end

                parent = club_member_partner[club_id][parent]
            end

            if not parent then
                res.result = enum.ERROR_PLAYER_NO_RIGHT
                onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
                return
            end
        end

        local function recursive_sum_member_all_money(c,partner_id)
            local sum = club_partner_commission[c.id][partner_id] or 0
            local money_id = club_money_type[c.id]
            for mem_id,_ in pairs(club_partner_member[c.id][partner_id] or {}) do
                local mrole = club_role[c.id][mem_id]
                if mrole == enum.CRT_PARTNER then
                    sum = sum + recursive_sum_member_all_money(c,mem_id)
                end

                sum = sum + player_money[mem_id][money_id]
            end

            return sum
        end

        local function recursive_dismiss_partner(c,partner_id)
            local partner = club_partners[club_id][target_guid]
            for mem_id,_ in pairs(club_partner_member[c.id][partner_id]) do
                local mrole = club_role[c.id][mem_id]
                if mrole == enum.CRT_PARTNER then
                    local result = recursive_dismiss_partner(c,mem_id)
                    if result ~= enum.ERROR_NONE then
                        return result
                    end
                end
                c:exit(mem_id)
            end

            return partner:dismiss()
        end

        if recursive_sum_member_all_money(club,target_guid) > 0 then
            res.result = enum.ERROR_MORE_MAX_LIMIT
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        local result = recursive_dismiss_partner(club,target_guid)
        res.result = result
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end
end

local function dismiss_club(club)
    log.dump(club)

    if club_utils.deep_is_member_in_gaming(club) then
        return enum.ERROR_PLAYER_IN_GAME
    end

    local money_id = club_money_type[club.id]
    local member_money = club_utils.deep_member_money_sum(club,money_id)
    if member_money > 0 then
        return enum.ERROR_MORE_MAX_LIMIT
    end

    club_utils.deep_dismiss_club(club,money_id)
    return enum.ERROR_NONE
end

function on_cs_club_dismiss(msg,guid)
    local club_id = msg.target_id
    local club = base_clubs[club_id]
    if not club then 
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            op = CLUB_OP.EXIT_AGREED,
            target_id = club_id,
        })
        return
    end

    local result = dismiss_club(club)
    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = result,
        op = CLUB_OP.EXIT_AGREED,
        target_id = club_id,
    })
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
            op = CLUB_OP.EXIT_AGREED,
            target_id = boss_guid,
        })
        return
    end

    log.dump(club)

    local result = dismiss_club(club)
    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = result,
        op = CLUB_OP.EXIT_AGREED,
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
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local target_role = club_role[club_id][target_guid]
    if target_role == enum.CRT_ADMIN or target_role == enum.CRT_BOSS or target_role == enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_OPERATION_INVALID
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

    local os = onlineguid[target_guid]
    if os and os.table then
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = enum.ERROR_PLAYER_IN_GAME
        })
        return
    end

    if club.type == enum.CT_UNION then
        local money_id = club_money_type[club_id]
        if player_money[target_guid][money_id] > 0 then
            onlineguid.send(guid,"S2C_CLUB_OP_RES",{
                result = enum.ERROR_MORE_MAX_LIMIT
            })
            return
        end
    end

    local result = club:full_exit(target_guid,guid)
    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = result,
        op = CLUB_OP.EXIT_AGREED,
        target_id = target_guid,
    })
end


local function on_cs_club_block(msg,guid,status)
    local club_id = msg.club_id
    local target_club_id = msg.target_id
    local op = (status == 0 and CLUB_OP.UNBLOCK_CLUB or CLUB_OP.BLOCK_CLUB)

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
            result = enum.ERROR_PARAMETER_ERROR,
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
    local oper = (status == 0 and CLUB_OP.OPEN_CLUB or CLUB_OP.CLOSE_CLUB)

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
            result = enum.ERROR_PARAMETER_ERROR,
            op = oper,
        })
        return
    end

    reddb:hmset(string.format("club:info:%d",club_id),{
        status = status
    })

    channel.publish("db.?","msg","SD_EditClubInfo",{status = status},club_id)

    base_clubs[club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = enum.ERROR_NONE,
        op = oper,
        club_id = club_id,
    })
end

local operator = {
    [CLUB_OP.ADD_ADMIN] = on_cs_club_administrator,
    [CLUB_OP.REMOVE_ADMIN] = on_cs_club_administrator,
    [CLUB_OP.JOIN_AGREED] = on_cs_club_agree_request,
    [CLUB_OP.JOIN_REJECTED] = on_cs_club_reject_request,
    [CLUB_OP.EXIT_AGREED] = on_cs_club_kickout,
    [CLUB_OP.APPLY_EXIT] = on_cs_club_exit,
    [CLUB_OP.ADD_PARTNER] = on_cs_club_partner,
    [CLUB_OP.REMOVE_PARTNER] = on_cs_club_partner,
    [CLUB_OP.BLOCK_CLUB] = function(msg,guid) on_cs_club_block(msg,guid,enum.CLUB_STATUS_BLOCK) end,
    [CLUB_OP.UNBLOCK_CLUB] = function(msg,guid) on_cs_club_block(msg,guid,enum.CLUB_STATUS_NORMAL) end,
    [CLUB_OP.CLOSE_CLUB] = function(msg,guid) on_cs_club_close(msg,guid,enum.CLUB_STATUS_CLOSE) end,
    [CLUB_OP.OPEN_CLUB] = function(msg,guid) on_cs_club_close(msg,guid,enum.CLUB_STATUS_NORMAL) end,
    [CLUB_OP.DISMISS_CLUB] = on_cs_club_dismiss,
    [CLUB_OP.CANCEL_FORBID] = on_cs_club_blacklist;
    [CLUB_OP.FORBID_GAME] = on_cs_club_blacklist;
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

local function can_transfer(club_id,partner_id)
    if not base_clubs[club_id] then
        return enum.ERROR_CLUB_NOT_FOUND
    end

    if not club_member[club_id][partner_id] then
        return enum.ERROR_MEMBERS_NOT_FOUND
    end

    local role = club_role[club_id][partner_id]
    if role ~= enum.CRT_PARTNER and role ~= enum.CRT_BOSS then
        return enum.ERROR_PLAYER_NO_RIGHT
    end

    local function is_credit_less(cid,pid)
        local money_id = club_money_type[cid]
        local credit = club_partner_conf[cid][pid].credit or 0
        local team_money = (club_team_money[cid][pid] or 0) + player_money[pid][money_id]
        if team_money < credit then
            return true
        end
    end

    local is_block_switch_on = club_conf[club_id].credit_block_score
    if is_block_switch_on then
        while partner_id and partner_id ~= 0 do
            if is_credit_less(club_id,partner_id) then
                return enum.ERROR_CLUB_TEAM_IS_LOCKED
            end

            partner_id = club_member_partner[club_id][partner_id]
        end
    end

    return enum.ERROR_NONE
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
        res.result = enum.ERROR_PARAMETER_ERROR
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local recharge_id = channel.call("db.?","msg","SD_LogRecharge",{
        source_id = source_guid,
        target_id = target_club_id,
        type = 2,
        operator = guid,
    })

    local errno,_,new_db_club_money,_,new_db_player_money  = 
        channel.call("db.?","msg","SD_TransferMoney",{
            from = source_guid,
            to = target_club_id,
            type = 2,
            amount = money,
            money_id = money_id,
            why = enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,
            why_ext = recharge_id,
        })

    if errno ~= enum.ERROR_NONE then
        res.result = errno
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local new_player_money = p:incr_redis_money(money_id,-money)
    if new_player_money ~= new_db_player_money then
        log.warning("transfer_money_club2player player %s db money ~= redis money,%s,%s",p.guid,new_db_player_money,new_player_money)
    end

    local new_club_money = club:incr_redis_money(money_id,money)
    if new_club_money ~= new_db_club_money then
        log.warning("transfer_money_club2player club %s db money ~= redis money,%s,%s",club.id,new_db_club_money,new_club_money)
    end

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
        res.result = enum.ERROR_PARAMETER_ERROR
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local recharge_id = channel.call("db.?","msg","SD_LogRecharge",{
        source_id = source_club_id,
        target_id = target_club_id,
        type = 3,
        operator = guid,
    })

    
    local errno,_,new_db_source_club_money,_,new_db_target_club_money  = 
        channel.call("db.?","msg","SD_TransferMoney",{
            from = source_club_id,
            to = target_club_id,
            type = 3,
            amount = money,
            money_id = money_id,
            why = why,
            why_ext = recharge_id,
        })

    if errno ~= enum.ERROR_NONE then
        res.result = errno
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local new_source_club_money = sourceclub:incr_redis_money(money_id,-money)
    if new_db_source_club_money ~= new_source_club_money then
        log.warning("transfer_money_club2club club %s db money ~= redis money,%s,%s",sourceclub.id,new_db_source_club_money,new_source_club_money)
    end

    local new_target_club_money = targetclub:incr_redis_money(money_id,money)
    if new_db_target_club_money ~= new_target_club_money then
        log.warning("transfer_money_club2club club %s db money ~= redis money,%s,%s",sourceclub.id,new_db_target_club_money,new_target_club_money)
    end

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
        res.result = enum.ERROR_PARAMETER_ERROR
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local recharge_id = channel.call("db.?","msg","SD_LogRecharge",{
        source_id = source_club_id,
        target_id = target_guid,
        type = 1,
        operator = guid,
    })

    local errno,_,new_db_club_money,_,new_db_player_money  = 
        channel.call("db.?","msg","SD_TransferMoney",{
            from = source_club_id,
            to = target_guid,
            type = 1,
            amount = money,
            money_id = money_id,
            why = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,
            why_ext = recharge_id,
        })

    if errno ~= enum.ERROR_NONE then
        res.result = errno
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local new_club_money = club:incr_redis_money(money_id,-money)
    if new_club_money ~= new_db_club_money then
        log.warning("transfer_money_club2player club %s db money ~= redis money,%s,%s",club.id,new_db_club_money,new_club_money)
    end

    local new_player_money = p:incr_redis_money(money_id,money)
    if new_player_money ~= new_db_player_money then
        log.warning("transfer_money_club2player player %s db money ~= redis money,%s,%s",p.guid,new_db_player_money,new_player_money)
    end

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

local function transfer_money_player2player(from_guid,to_guid,club_id,money,guid)
    local res = {
        result = enum.ERROR_NONE,
        source_type = 0,
        target_type = 0,
        source_id = from_guid,
        target_id = to_guid,
        ext_data = club_id,
    }

    local club = base_clubs[club_id]
    if not club then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if not club_member[club_id][from_guid] or not club_member[club_id][to_guid] then
        res.result = enum.ERROR_NOT_MEMBER
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local from_role = club_role[club_id][from_guid] or enum.CRT_PLAYER
    local to_role = club_role[club_id][to_guid] or enum.CRT_PLAYER

    local from = base_players[from_guid]
    local to = base_players[to_guid]
    if not from or not to then
        res.result = enum.ERROR_PLAYER_NOT_EXIST
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    local whies = {
        [enum.CRT_BOSS] = {
            [enum.CRT_PARTNER] = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,
            [enum.CRT_PLAYER] = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,
            [enum.CRT_ADMIN] = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,
            [enum.CRT_BOSS] = nil,
        },
        [enum.CRT_PARTNER] = {
            [enum.CRT_PARTNER] = nil,
            [enum.CRT_PLAYER] = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,
            [enum.CRT_ADMIN] = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,
            [enum.CRT_BOSS] = enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,
        },
        [enum.CRT_PLAYER] = {
            [enum.CRT_PARTNER] = enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,
            [enum.CRT_BOSS] = enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,
            [enum.CRT_PLAYER] = nil,
            [enum.CRT_ADMIN] = enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,
        },
        [enum.CRT_ADMIN] = {
            [enum.CRT_PARTNER] = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,
            [enum.CRT_BOSS] = enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB,
            [enum.CRT_PLAYER] = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB,
            [enum.CRT_ADMIN] = nil,
        }
    }

    local function recursive_search_partner(cid,pguid,guid)
        local partner = club_member_partner[club_id][guid]
        while partner and partner ~= pguid do
            partner = club_member_partner[club_id][partner]
        end

        return partner
    end

    local why = whies[from_role][to_role]
    if from_role == enum.CRT_PARTNER and to_role == enum.CRT_PLAYER then
        if not recursive_search_partner(club_id,from_guid,to_guid) then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
            return
        end

        local can = can_transfer(club_id,from_guid)
        if can ~= enum.ERROR_NONE then
            res.result = can
            onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
            return
        end
    elseif to_role == enum.CRT_PARTNER and from_role == enum.CRT_PLAYER then
        local can = can_transfer(club_id,to_guid)
        if can ~= enum.ERROR_NONE then
            res.result = can
            onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
            return
        end

        if not recursive_search_partner(club_id,to_guid,from_guid) then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
            return
        end
    elseif from_role == enum.CRT_PARTNER and to_role == enum.CRT_PARTNER then
        local can = can_transfer(club_id,from_guid)
        if can ~= enum.ERROR_NONE then
            res.result = can
            onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
            return
        end

        if recursive_search_partner(club_id,from_guid,to_guid) then
            why = enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB
        elseif recursive_search_partner(club_id,to_guid,from_guid) then
            why = enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB
        else
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
            return
        end
    end

    local money_id = club_money_type[club_id]

    local lock = money_locks[money_id]
    lock(function()
        local orgin_money = player_money[from_guid][money_id]
        if orgin_money < money then
            res.result = enum.ERROR_PARAMETER_ERROR
            onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
            return
        end

        local old_from_money = player_money[from_guid][money_id]
        local new_from_money = club:incr_member_redis_money(from_guid,-money)
        local old_to_money = player_money[to_guid][money_id]
        local new_to_money = club:incr_member_redis_money(to_guid,money)

        local recharge_id = channel.call("db.?","msg","SD_LogRecharge",{
            source_id = from_guid,
            target_id = to_guid,
            type = 4,
            operator = guid,
        })

        local errno  =
            channel.call("db.?","msg","SD_TransferMoney",{
                from = {
                    guid = from_guid,
                    old_money = old_from_money,
                    new_money = new_from_money,
                },
                to = {
                    guid = to_guid,
                    old_money = old_to_money,
                    new_money = new_to_money,
                },
                type = 4,
                money_id = money_id,
                why = why,
                why_ext = recharge_id,
            })

        if errno ~= enum.ERROR_NONE then
            res.result = errno
            onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
            return
        end
    end)

    onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
end



function on_cs_transfer_money(msg,guid)
    local source_type = msg.source_type
    local target_type = msg.target_type
    local money = msg.money
    local ext_data = msg.ext_data
    local source_id = msg.source_id
    local target_id = msg.target_id

    local res = {
        result = enum.ERROR_OPERATION_INVALID,
        source_type = source_type,
        target_type = target_type,
        money = money,
        source_id = source_id,
        target_id = target_id,
    }

    if money <= 0 then
        onlineguid.send(guid,"S2C_CLUB_TRANSFER_MONEY_RES",res)
        return
    end

    if source_type == 0 then
        if target_type == 0 then
            transfer_money_player2player(source_id,target_id,ext_data,money,guid)
            return
        end

        if target_type == 1 then
            transfer_money_player2club(source_id,target_id,money,guid)
            return
        end
    end

    if source_type == 1 then
        if target_type == 0 then
            transfer_money_club2player(source_id,target_id,money,guid)
            return
        end

        if target_type == 1 then
            transfer_money_club2club(source_id,target_id,money,guid)
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
            result = enum.ERROR_PARAMETER_ERROR,
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
    if role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
            result = enum.ERROR_PLAYER_NO_RIGHT,
        })
        return
    end

    local commission = club_partner_commission[club_id][guid]
    if count < 0 then
        count = commission
    end

    local result = club:exchange_team_commission(guid,count)
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
            result = enum.ERROR_PARAMETER_ERROR
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
            result = enum.ERROR_PARAMETER_ERROR
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

function on_cs_force_dismiss_table(msg,guid)
    local club_id = msg.club_id
    local table_id = msg.table_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_FORCE_DISMISS_TABLE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    club = club_utils.root(club)
    if not club then
        onlineguid.send(guid,"S2C_CLUB_FORCE_DISMISS_TABLE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CLUB_FORCE_DISMISS_TABLE",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local tb = base_private_table[table_id]
    if not tb then
        onlineguid.send(guid,"S2C_CLUB_FORCE_DISMISS_TABLE",{
            result = enum.ERROR_TABLE_NOT_EXISTS
        })
        return
    end

    if tb.room_id ~= def_game_id then
        channel.publish("game."..tostring(tb.room_id),"msg","C2S_CLUB_FORCE_DISMISS_TABLE",msg,guid)
        return
    end

    local succ = g_room:force_dismiss_table(tb.real_table_id,enum.STANDUP_REASON_ADMIN_DISMISS_FORCE)
    onlineguid.send(guid,"S2C_CLUB_FORCE_DISMISS_TABLE",{
        result = succ
    })
end

function on_cs_pull_block_groups(msg,guid)
    local club_id = msg.club_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_PULL_GROUPS",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    local role = club_role[club_id][guid]
    if not role or role == enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_PULL_GROUPS",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local groups = table.series(club_block_groups[club_id],function(_,gid)
        return {
            group_id = gid, 
            players = table.series(club_block_group_players[club_id][gid],function(_,gpid)
                local p = base_players[gpid]
                return {
                    guid = p.guid,
                    nickname = p.nickname,
                    icon = p.icon,
                    sex = p.sex,
                }
            end)
        }
    end)

    onlineguid.send(guid,"S2C_CLUB_BLOCK_PULL_GROUPS",{
        result = enum.ERROR_NONE,
        groups = groups,
    })
end

function on_cs_new_block_group(msg,guid)
    local club_id = msg.club_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_NEW_GROUP",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    local role = club_role[club_id][guid]
    if not role or role == enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_NEW_GROUP",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local group_id = tonumber(reddb:incr(string.format("club:block:group:id")))
    reddb:sadd(string.format("club:block:groups:%s",club_id),group_id)
    onlineguid.send(guid,"S2C_CLUB_BLOCK_NEW_GROUP",{
        result = enum.ERROR_NONE,
        group_id = group_id,
        club_id = club_id,
    })
end

function on_cs_del_block_group(msg,guid)
    local club_id = msg.club_id
    local group_id = msg.group_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_DEL_GROUP",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    local role = club_role[club_id][guid]
    if not role or role == enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_DEL_GROUP",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local gguids = club_block_group_players[club_id][group_id]
    for gguid,_ in pairs(gguids) do
        reddb:srem(string.format("club:block:player:group:%s:%s",club_id,gguid),group_id)
    end
    reddb:del(string.format("club:block:group:player:%s:%s",club_id,group_id))
    reddb:srem(string.format("club:block:groups:%s",club_id),group_id)

    onlineguid.send(guid,"S2C_CLUB_BLOCK_DEL_GROUP",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        group_id = group_id,
    })
end

function on_cs_add_player_to_block_group(msg,guid)
    local club_id = msg.club_id
    local group_id = msg.group_id
    local group_guid = msg.guid

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_ADD_PLAYER_TO_GROUP",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    local role = club_role[club_id][guid]
    if not role or role == enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_ADD_PLAYER_TO_GROUP",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local p = base_players[group_guid]
    if not p then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_ADD_PLAYER_TO_GROUP",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    if not club_member[club_id][group_guid] then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_ADD_PLAYER_TO_GROUP",{
            result = enum.ERROR_NOT_MEMBER
        })
        return
    end

    if not club_block_groups[club_id][group_id] then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_ADD_PLAYER_TO_GROUP",{
            result = enum.ERROR_PARAMETER_ERROR
        })
        return
    end

    reddb:sadd(string.format("club:block:group:player:%s:%s",club_id,group_id),group_guid)
    reddb:sadd(string.format("club:block:player:group:%s:%s",club_id,group_guid),group_id)
    onlineguid.send(guid,"S2C_CLUB_BLOCK_ADD_PLAYER_TO_GROUP",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        group_id = group_id,
        guid = group_guid,
    })
end

function on_cs_remove_player_from_block_group(msg,guid)
    local club_id = msg.club_id
    local group_id = msg.group_id
    local group_guid = msg.guid

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_REMOVE_PLAYER_FROM_GROUP",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    local role = club_role[club_id][guid]
    if not role or role == enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_REMOVE_PLAYER_FROM_GROUP",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local p = base_players[group_guid]
    if not p then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_ADD_PLAYER_TO_GROUP",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    if not club_block_groups[club_id][group_id] then
        onlineguid.send(guid,"S2C_CLUB_BLOCK_REMOVE_PLAYER_FROM_GROUP",{
            result = enum.ERROR_PARAMETER_ERROR
        })
        return
    end

    reddb:srem(string.format("club:block:group:player:%s:%s",club_id,group_id),group_guid)
    reddb:srem(string.format("club:block:player:group:%s:%s",club_id,group_guid),group_id)
    onlineguid.send(guid,"S2C_CLUB_BLOCK_REMOVE_PLAYER_FROM_GROUP",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        group_id = group_id,
        guid = group_guid,
    })
end

function on_cs_club_edit_info(msg,guid)
    local club_id = msg.club_id
    local name = msg.name

    local operator = base_players[guid]
    if not operator then
        onlineguid.send(guid,"S2C_CLUB_EDIT_INFO",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
            club_id = club_id,
            name = name,
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_EDIT_INFO",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            club_id = club_id,
            name = name,
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CLUB_EDIT_INFO",{
            result = enum.ERROR_PLAYER_NO_RIGHT,
            club_id = club_id,
            name = name,
        })
        return
    end

    reddb:hmset(string.format("club:info:%s",club_id),{
        name = name
    })

    channel.publish("db.?","msg","SD_EditClubInfo",{
        name = name,
    },club_id)

    base_clubs[club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_EDIT_INFO",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        name = name,
    })
end

function on_cs_club_get_config(msg,guid)
    local club_id = msg.club_id
    local conf = msg.conf

    local operator = base_players[guid]
    if not operator then
        onlineguid.send(guid,"S2C_CLUB_GET_CONFIG",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
            club_id = club_id,
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_GET_CONFIG",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            club_id = club_id,
        })
        return
    end

    -- local role = club_role[club_id][guid]
    -- if role ~= enum.CRT_BOSS and role ~= enum.CRT_ADMIN then
    --     onlineguid.send(guid,"S2C_CLUB_GET_CONFIG",{
    --         result = enum.ERROR_PLAYER_NO_RIGHT,
    --         club_id = club_id,
    --     })
    --     return
    -- end

    local tconf = club_conf[club_id] or {}
    onlineguid.send(guid,"S2C_CLUB_GET_CONFIG",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        conf = json.encode(tconf),
    })
end

function on_cs_club_edit_config(msg,guid)
    local club_id = msg.club_id
    local conf = msg.conf

    local operator = base_players[guid]
    if not operator then
        onlineguid.send(guid,"S2C_CLUB_EDIT_CONFIG",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
            club_id = club_id,
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_EDIT_CONFIG",{
            result = enum.ERROR_CLUB_NOT_FOUND,
            club_id = club_id,
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CLUB_EDIT_CONFIG",{
            result = enum.ERROR_PLAYER_NO_RIGHT,
            club_id = club_id,
        })
        return
    end

    local ok,tconf = pcall(json.decode,conf)
    if not ok then
        onlineguid.send(guid,"S2C_CLUB_EDIT_CONFIG",{
            result = enum.ERROR_PARAMETER_ERROR,
            club_id = club_id,
            conf = conf,
        })
        return
    end

    tconf = table.map(tconf,function(c,k) return k,c and true or false end)

    log.dump(tconf)

    reddb:hmset(string.format("club:conf:%s",club_id),tconf)
    club_conf[club_id] = nil
    onlineguid.send(guid,"S2C_CLUB_EDIT_CONFIG",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        conf = conf,
    })
end


function on_cs_club_invite_join_room(msg,guid)
    local player = base_players[guid]
    if not player then
        onlineguid.send(guid,"S2C_CLUB_INVITE_JOIN_ROOM",{
            result = enum.ERROR_OPERATION_INVALID,
        })
        return
    end

    local club_id = msg.club_id
    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_INVITE_JOIN_ROOM",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local k = string.format("club:join_room_invite_cd:%s:%s",club_id,guid)
    local timeout = tonumber(reddb:ttl(k))
    if timeout >= 0 then
        onlineguid.send(guid,"S2C_CLUB_INVITE_JOIN_ROOM",{
            result = enum.ERROR_REQUEST_REPEATED,
            timeout = timeout
        })
        return
    end

    local tb = g_room:find_table_by_player(player)
    if not tb then
        onlineguid.send(guid,"S2C_CLUB_INVITE_JOIN_ROOM",{
            result = enum.ERROR_PLAYER_NOT_IN_GAME,
        })
        return
    end

    reddb:set(k,1)
    reddb:expire(k,invite_join_room_cd)

    onlineguid.send(guid,"S2C_CLUB_INVITE_JOIN_ROOM",{
        result = enum.ERROR_NONE,
        timeout = invite_join_room_cd,
    })

    local tbconf = tb:private_table_conf()
    local notify = {
        inviter = {
            guid = player.guid,
            nickname = player.nickname,
            icon = player.icon,
            sex = player.sex,
        },
        table = {
            game_type = tbconf.game_type,
            owner = tbconf.owner,
            club_id = tbconf.club_id,
            table_id = tbconf.table_id,
            rule = json.encode(tbconf.rule),
        },
    }

    local mems = club_member[club_id]
    table.filter(mems,function(_,mid)
        local os = onlineguid[mid]
        return table.nums(os) > 0 and not (os.table or os.chair)
    end)
    onlineguid.broadcast(table.keys(mems),"S2C_NOTIFY_INVITE_JOIN_ROOM",notify)
end

function on_cs_search_club_player(msg,guid)
    local club_id = msg.club_id
    local partner_id = msg.partner
    local pattern = msg.guid_pattern

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"SC_SEARCH_CLUB_PLAYER",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    local self_role = club_role[club_id][guid]

    if partner_id and partner_id ~= 0 then
        if not self_role or self_role == enum.CRT_PLAYER then
            onlineguid.send(guid,"SC_SEARCH_CLUB_PLAYER",{
                result = enum.ERROR_PLAYER_NO_RIGHT
            })
            return
        end
        
        local role = club_role[club_id][partner_id]
        if not role or role == enum.CRT_PLAYER then
            onlineguid.send(guid,"SC_SEARCH_CLUB_PLAYER",{
                result = enum.ERROR_PARAMETER_ERROR
            })
            return
        end

        if self_role == enum.CRT_ADMIN and partner_id == guid then
            partner_id = club.owner
        end
    else
        if not self_role or (self_role ~= enum.CRT_ADMIN and self_role ~= enum.CRT_BOSS) then
            onlineguid.send(guid,"SC_SEARCH_CLUB_PLAYER",{
                result = enum.ERROR_PLAYER_NO_RIGHT
            })
            return
        end
    end

    local key = string.format("club:member:%s",club_id)
    local mems = {}
    local cursor = "0"
    repeat
        local scanner = reddb:sscan(key,cursor,"MATCH","*"..pattern.."*","COUNT",1000)
        if not scanner or #scanner < 2 then break end
        cursor = scanner[1]
        table.unionto(mems,scanner[2])
    until cursor == "0"

    mems = table.series(mems,function(m) return tonumber(m) end)
    local function match_partner(club,partner,guid)
        local uid = guid
        repeat 
            uid = club_member_partner[club][uid]
            if uid == partner then return true end
        until not uid
    end

    mems = table.series(mems,function(m)
        if  partner_id and 
            partner_id ~= 0 and 
            not match_partner(club_id,partner_id,m) then
            return
        end

        return m
    end)

    local money_id = club_money_type[club_id]

    local today = math.floor(os.time() / 86400) * 86400
    local logs = channel.call("db.?","msg","SD_QueryPlayerStatistics",mems,club_id,partner_id,today)

    logs = table.group(logs,function(c) return c.guid end)

    json.encode_sparse_array(true)
    local infos = table.series(mems,function(m)
        local p = base_players[tonumber(m)]
        if not p then return end

        local role = club_role[club_id][p.guid] or enum.CRT_PLAYER
        return {
            info = {
                guid = p.guid,
                icon = p.icon,
                nickname = p.nickname,
                sex = p.sex,
            },
            role = role,
            money = {
                money_id = money_id,
                count = player_money[p.guid][money_id] or 0,
            },
            team_money = {
                money_id = money_id,
                count = club_team_money[club_id][p.guid] or 0,
            },
            commission = club_partner_commission[club_id][p.guid] or 0,
            extra_data = json.encode({
                info = {
                    guid = p.guid,
                    player_count = (club_team_player_count[club_id][p.guid] or 0) + 1,
                    money = (club_team_money[club_id][p.guid] or 0) + (player_money[p.guid][money_id] or 0)
                },
                logs = logs[p.guid] and table.values(logs[p.guid]) or nil,
            }),
            parent = club_member_partner[club_id][p.guid],
            block_gaming = club_gaming_blacklist[club_id][p.guid],
        }
    end)

    onlineguid.send(guid,"SC_SEARCH_CLUB_PLAYER",{
        result = enum.ERROR_NONE,
        players = infos,
    })
end


function on_cs_club_edit_team_config(msg,guid)
    log.dump(msg)
    local club_id = msg.club_id
    local partner_id = msg.partner

    local club = base_clubs[club_id]
    if not club then 
        onlineguid.send(guid,"S2C_CLUB_EDIT_TEAM_CONFIG",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local role = club_role[club_id][guid]
    if (role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER) or
        club_member_partner[club_id][partner_id] ~= guid 
    then 
        onlineguid.send(guid,"S2C_CLUB_EDIT_TEAM_CONFIG",{
            result = enum.ERROR_PLAYER_NO_RIGHT,
        })
        return
    end

    local ok,conf = pcall(json.decode,msg.conf)
    if not ok then
        onlineguid.send(guid,"S2C_CLUB_EDIT_TEAM_CONFIG",{
            result = enum.ERROR_PARAMETER_ERROR,
        })
        return
    end

    reddb:hmset(string.format("club:partner:conf:%s:%s",club_id,partner_id),conf)

    onlineguid.send(guid,"S2C_CLUB_EDIT_TEAM_CONFIG",msg)
end

function on_cs_club_kickout_player(msg,kicker_guid)
    local club_id = msg.club_id
    local guid = msg.guid
    log.dump(msg)
    if not club_id or club_id == 0 then
        onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })

        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })

        return
    end

    if not guid or guid == 0 then
        onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
        })

        return
    end

    local player = base_players[guid]
    if not player then
        onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
            result = enum.ERROR_PLAYER_NOT_EXIST,
        })

        return
    end

    local kicker = base_players[kicker_guid]
    local kicker_table = g_room:find_table_by_player(kicker)
    local kickee_table = g_room:find_table_by_player(player)
    local result = enum.ERROR_NONE
    if kickee_table ~= kicker_table then
        local kicker_role = club_role[club_id][kicker_guid]
        if kicker_role ~= enum.CRT_ADMIN and kicker_role ~= enum.CRT_BOSS then
            onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
                result = enum.ERROR_PLAYER_NO_RIGHT,
            })
    
            return
        end

        if not club_member[club_id][guid] then
            onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
                result = enum.ERROR_OPERATION_INVALID,
            })
    
            return
        end

        if kicker_guid == guid then
            onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
                result = enum.ERROR_OPERATION_INVALID,
            })
    
            return
        end

        result = player:force_exit(enum.STANDUP_REASON_FORCE)
    else
        if not kickee_table then
            result = enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
        else
            result = kickee_table:kickout_player(player,kicker)
        end
    end

    onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
        result = result,
    })
end

function on_bs_club_del(club_id)
    local club = base_clubs[club_id]
    if not club then
        return enum.ERROR_CLUB_NOT_FOUND
    end

    return club:del()
end

function on_bs_club_dismiss(club_id)
    local club = base_clubs[club_id]
    if not club then
        return enum.ERROR_CLUB_NOT_FOUND
    end

    return club:dismiss()
end