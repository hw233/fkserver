local base_player = require "game.lobby.base_player"
local log = require "log"
local base_club = require "game.club.base_club"
local pb = require "pb_files"
local redisopt = require "redisopt"
local base_players = require "game.lobby.base_players"
local base_clubs = require "game.club.base_clubs"
local club_memeber = require "game.club.club_member"
local player_club = require "game.club.player_club"
local channel = require "channel"
local serviceconf = require "serviceconf"
local private_table = require "game.lobby.base_private_table"
local onlineguid = require "netguidopt"
local club_table = require "game.club.club_table"
local club_request = require "game.club.club_request"
local player_request = require "game.club.player_request"
local base_request = require "game.club.base_request"
local club_game_type = require "game.club.club_game_type"
local json = require "cjson"
require "functions"

local g_room = g_room

local reddb = redisopt.default

local club_op = {
    ADD_TO_BLACK = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","ADD_TO_BLACK"),
    REMOVE_TO_BLACK    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_TO_BLACK"),
    ADD_ADMIN    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","ADD_ADMIN"),
    REMOVE_ADMIN    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_ADMIN"),
    REMOVE_PLAYER    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_PLAYER"),
    OP_JOIN_AGREED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_JOIN_AGREED"),
    OP_JOIN_REJECTED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_JOIN_REJECTED"),
    OP_EXIT_AGREED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_EXIT_AGREED"),
    OP_EXIT_REJECTED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_EXIT_REJECTED"),
    OP_APPLY_EXIT    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OP_APPLY_EXIT"),
}

local CLUB_OP_RESULT_SUCCESS = pb.enum("CLUB_OP_RESULT","CLUB_OP_RESULT_SUCCESS")
local CLUB_OP_RESULT_FAILED = pb.enum("CLUB_OP_RESULT", "CLUB_OP_RESULT_FAILED")
local CLUB_OP_RESULT_NO_RIGHTS = pb.enum("CLUB_OP_RESULT","CLUB_OP_RESULT_NO_RIGHTS")
local CLUB_OP_RESULT_INTERNAL_ERROR = pb.enum("CLUB_OP_RESULT","CLUB_OP_RESULT_INTERNAL_ERROR")
local CLUB_OP_RESULT_NO_CLUB = pb.enum("CLUB_OP_RESULT","CLUB_OP_RESULT_NO_CLUB")

local ERROR_CLUB_UNKONW = pb.enum("ERROR_CODE","ERROR_CLUB_UNKONW")
local ERROR_NONE = pb.enum("ERROR_CODE", "ERROR_NONE")
local ERROR_CLUB_NOT_FOUND = pb.enum("ERROR_CODE", "ERROR_CLUB_NOT_FOUND")
local ERROR_NOT_IS_CLUB_MEMBER = pb.enum("ERROR_CODE","ERROR_NOT_IS_CLUB_MEMBER")
local ERROR_JOIN_ROOM_NO = pb.enum("ERROR_CODE","ERROR_JOIN_ROOM_NO")
local ERROR_PLAYER_NOT_EXIST = pb.enum("ERROR_CODE", "ERROR_PLAYER_NOT_EXIST")
local ERROR_CLUB_OP_EXPIRE = pb.enum("ERROR_CODE", "ERROR_CLUB_OP_EXPIRE")
local ERROR_CLUB_OP_JOIN_CHECKED = pb.enum("ERROR_CODE", "ERROR_CLUB_OP_JOIN_CHECKED")
local ERROR_NOT_IS_CLUB_BOSS = pb.enum("ERROR_CODE", "ERROR_NOT_IS_CLUB_BOSS")
local ERROR_NOT_IS_CLUB_ADMIN = pb.enum("ERROR_CODE", "ERROR_NOT_IS_CLUB_ADMIN") 

local CRT_BOSS = pb.enum("CLUB_ROLE_TYPE","CRT_BOSS")
local CRT_PLAYER = pb.enum("CLUB_ROLE_TYPE","CRT_PLAYER")
local CRT_ADMIN = pb.enum("CLUB_ROLE_TYPE","CRT_ADMIN")


function on_cs_club_create(msg,guid)
    local player = base_players[guid]
    if not player then
        log.error("internal error,recv msg but guid not online.")
        return {
            result = CLUB_OP_RESULT_INTERNAL_ERROR,
        }
    end

    dump(msg)

    -- if not player:has_club_rights() then
	-- 	return {
    --         result = CLUB_OP_RESULT_NO_RIGHTS,
    --     }
	-- end

    local id = base_club:create(msg.name,msg.icon,msg.notice,player)
	if not id then
		return {
            result = CLUB_OP_RESULT_FAILED,
        }
    end
    
    local update = base_clubs[id]

    onlineguid.send(guid,"S2C_CREATE_CLUB_RES",{
        result = CLUB_OP_RESULT_SUCCESS,
        id = id,
    })
end

function on_cs_club_dismiss(msg,guid)
    local club_id = msg.club_id
    local player = base_players[guid]
    if not player then
        log.error("internal error,recv msg but guid not online.")
        return {
            club_id = club_id,
            result = CLUB_OP_RESULT_INTERNAL_ERROR,
        }
    end

    if not player:has_club_rights() then
        return {
            club_id = club_id,
            result = CLUB_OP_RESULT_NO_RIGHTS,
        }
    end

    local club = base_clubs[club_id]
    if not club then
        return {
            club_id = club_id,
            result = CLUB_OP_RESULT_NO_CLUB,
        }
    end

    club:dismiss()
    for mem,p in pairs(club_memeber[club_id]) do
        player_club[mem][club_id] = nil
    end
    club_memeber[club_id] = nil
    base_clubs[club_id] = nil

    return {
        club_id = club_id,
        result = CLUB_OP_RESULT_SUCCESS,
    }
end

function on_cs_club_query(msg,guid)
    local club = base_clubs[msg.club_id]
    return {
        id = club.id,
        name = club.name,
        icon = club.icon,
    }
end

function on_cs_club_detail_info_req(msg,guid)
    local club_id = msg.club_id
    if not club_id then
        onlineguid.send(guid,"S2C_CLUB_INFO_RES",{
            result = ERROR_CLUB_NOT_FOUND,
        })

        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CLUB_INFO_RES",{
            result = ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    -- dump(club)

    local games = {}
    local info = channel.query()
    -- dump(info)
    for id,_ in pairs(info) do
        local id = id:match("service%.(%d+)")
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

    local tables = {}
    for gid,tb in pairs(club_table[club_id]) do
        table.insert(tables,{
            table_id = gid,
            owner = tb.owner,
            table_status = 3,
            rule = json.encode(tb.rule),
            game_type = tb.game_type,
        })
    end

    local members = club_memeber[club_id]
    local online_count = 0
    local total_count = 0

    for _,p in pairs(members) do
        if p  then
            total_count = total_count + 1
            if p.online then
                online_count = online_count + 1
            end
        end
    end

    local info = {
        result = ERROR_NONE,
        club_id = club_id,
        club_name = club.name,
        note = club.note,
        closed = false,
        player_count = total_count,
        player_num_online = online_count,
        club_diamond = club_memeber[club_id][club.owner].diamond,
        table_list = tables,
        role_type = (guid == club.owner) and CRT_BOSS or CRT_PLAYER,
        gamelist = real_games,
    }

    -- dump(info)

    onlineguid.send(guid,"S2C_CLUB_INFO_RES",info)
end

function on_cs_club_list(msg,guid)
    log.info("on_cs_club_list,guid:%s",guid)
    local clubs = {}
    for _,club in pairs(base_clubs.list()) do
        if club_memeber[club.id][guid] then
            table.insert(clubs,{
                id = club.id,
                name = club.name,
                icon = club.icon,
                level = club.level,
                status = club.status,
                player_num_online = club.online_count,
                boss_guid = club.owner,
                player_num = table.nums(club_memeber[club.id]),
            })
        end
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
            result = ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    if club.owner ~= guid then
        onlineguid.send(guid,"S2C_EDIT_CLUB_GAME_TYPE_RES",{
            result = ERROR_NOT_IS_CLUB_BOSS,
        })
        return
    end

    
    reddb:sadd("club:"..tostring(club_id)..":game",table.unpack(msg.game_types))
    club_game_type[club_id] = nil

    onlineguid.send(guid,"S2C_EDIT_CLUB_GAME_TYPE_RES",{
        result = ERROR_NONE,
    })
end

function on_cs_club_join_req(msg,guid)
    dump(msg)
    local club_id = msg.club_id
    local club = base_clubs[club_id]
    if not club then
        log.error("unknown club:%s",club_id)
        onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
            result = ERROR_CLUB_NOT_FOUND,
        })
        return 
    end

    if club_memeber[club_id] and club_memeber[club_id][guid] then
        log.error("club member:%s join self club:%s",guid,club_id)
        onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
            result = ERROR_CLUB_OP_JOIN_CHECKED,
        })
        return
    end

    dump(club)

    club:request_join(guid)
    onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
        result = ERROR_NONE,
    })

    player_request[club.owner] = nil

    dump(player_request)
end

function on_cs_club_invite_join_req(msg,guid)
    local club_id = msg.club_id
    local player = base_players[guid]
    if not player then
        log.error("internal error,recv msg but guid not online.")
        onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
            result = ERROR_PLAYER_NOT_EXIST,
        })
        return
    end

    if not player:has_club_rights() then
        onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
            result = ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_JOIN_CLUB_RES",{
            result = ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    club.invite_join(msg.guid,guid)
    player_request[msg.guid] = nil
end


function on_cs_create_table(msg,guid)
    dump(msg)
    local game_type = msg.game_type
    local club_id = msg.club_id
    local rule = msg.rule

    if not club_id then
        onlineguid.send(guid,"S2C_ROOM_CREATE_RES",{
            result = ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_ROOM_CREATE_RES",{
            result = ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local result,table_id = club:create_table(guid,json.decode(rule or "{}"))
    onlineguid.send(guid,"S2C_ROOM_CREATE_RES",{
        result = result,
        game_type = game_type,
        club_id = club_id,
        table_id = table_id,
        rule = rule,
    })
end

function on_cs_join_table_req(msg,guid)
    local player = base_players[guid]
    if not player then
        return ERROR_NOT_IS_CLUB_MEMBER
    end

    local tb = private_table[msg.table_id]
    if not tb then
        return ERROR_JOIN_ROOM_NO
    end

    if not msg.club_id then
        return g_room:join_table(guid,tonumber(tb.table_id))
    end

    local club = player_club[guid][msg.club_id]
    if not club then
        return ERROR_NOT_IS_CLUB_MEMBER
    end

    return g_room:join_table(player,msg.table_id)
end

function on_cs_club_query_memeber(msg,guid)
    dump(msg)
    local members = club_memeber[msg.club_id]
    local ms = {}

    for _,p in pairs(members) do
        table.insert(ms,{
            guid = p.guid,
            icon = p.open_id_icon,
            nickname = p.nickname,
            time = p.online and 0 or -1,
            role_type = CRT_BOSS,
        })
    end

    dump(ms)

    onlineguid.send(guid,"S2C_CLUB_PLAYER_LIST_RES",{
        player_list = ms,
    })
end

function on_cs_club_publish_notice(msg,guid)

end 

function on_cs_club_create_table_template(msg,guid)
    local club_id = msg.club_id
    local id = reddb:incr("tabletemplate:global:id")
    reddb:hmset("tabletemplate:"..tostring(id),{
        game_type = msg.game_type,
        rule = msg.rule,
        club_id = club_id,
    })

    reddb:sadd(string.format("club:template:%s",club_id),id)

    return {
        result = ERROR_NONE,
        template_id = id,
    }
end

function on_cs_club_remove_table_tempalte(msg,guid)
    local club_id = msg.club_id
    if not msg.template_id then
        onlineguid.send(guid,"S2C_TABLE_TEMPLATE_EDIT_RES",{
            result = ERROR_CLUB_NOT_FOUND
        })
    end
end

function on_cs_club_edit_table_template(msg,guid)

end

function on_cs_club_history_record(msg,guid)

end

function on_cs_club_exit_req(msg,guid)
    
end

function on_cs_club_request_list_req(msg,guid)
    local club_id = msg.club_id
    local reqs = {}
    for _,req in pairs(player_request[guid]) do
        local player = base_players[req.who]
        table.insert(reqs,{
            req_id = req.id,
            type = req.type,
            who = {
                guid = player.guid,
                nickname = player.nickname,
                icon = player.open_id_icon,
                time = 0,
            },
        })
    end

    dump(reqs)

    onlineguid.send(guid,"S2C_CLUB_REQUEST_LIST_RES",{
        result = ERROR_NONE,
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
    if msg.op == club_op.ADD_ADMIN then
        
    elseif msg.op == club_op.REMOVE_ADMIN then

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
	if not who:has_club_rights() then
		return CLUB_OP_RESULT_NO_RIGHTS
	end

    local club_id = msg.club_id
    if base_players[msg.guid] then
        base_clubs[club_id].exit(msg.guid)
        club_memeber[club_id][msg.guid] = nil
        player_club[msg.guid][club_id] = nil
    end
    
    return CLUB_OP_RESULT_SUCCESS
end

local function on_cs_club_agree_request(msg,guid)
    dump(msg)
    local player = base_players[guid]
    if not player then
        log.error("unknown player when agree request id:%s",msg.request_id)
        
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = ERROR_PLAYER_NOT_EXIST,
            op_type = msg.op,
        })
        return
    end

    local request = base_request[msg.request_id]
    if not request then
        log.error("unknown player when agree request id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = ERROR_CLUB_OP_EXPIRE,
            op_type = msg.op,
        })
        return
    end

    if not request:agree() then
        log.error("agree request failed,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = ERROR_CLUB_OP_EXPIRE,
            op_type = msg.op,
        })

        return
    end

    -- 更新数据
    player_request[request.whoee] = nil
    base_request[request.id] = nil
    club_memeber[request.club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = ERROR_NONE,
        op_type = msg.op,
    })
end

local function on_cs_club_reject_request(msg,guid)
    dump(msg)
    local player = base_players[guid]
    if not player then
        log.error("unknown player when reject request request_id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = ERROR_PLAYER_NOT_EXIST,
            op = msg.op,
        })
        return
    end

    local request = base_request[tonumber(msg.request_id)]
    if not request then
        log.error("unknown request when reject request request_id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = ERROR_CLUB_OP_EXPIRE,
            op = msg.op,
        })
        return
    end

    local club = base_clubs[request.club_id]
    if not club then
        log.error("unkonw club_id when reject request,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = ERROR_CLUB_NOT_FOUND,
            request_id = msg.request_id,
        })
        return
    end

    if not club:reject_request(request) then
        log.error("reject request failed,id:%s",msg.request_id)
        onlineguid.send(guid,"S2C_CLUB_OP_RES",{
            result = ERROR_CLUB_OP_EXPIRE,
            request_id = msg.request_id,
        })

        return
    end

    player_request[request.who][request.id] = nil
    base_request[request.id] = nil
    club_memeber[request.club_id] = nil

    onlineguid.send(guid,"S2C_CLUB_OP_RES",{
        result = ERROR_NONE,
        request_id = msg.request_id,
    })
end

local operator = {
    [club_op.ADD_TO_BLACK] = on_cs_club_blacklist,
    [club_op.REMOVE_TO_BLACK] = on_cs_club_blacklist,
    [club_op.ADD_ADMIN] = on_cs_club_administrator,
    [club_op.REMOVE_ADMIN] = on_cs_club_administrator,
    [club_op.REMOVE_PLAYER] = on_cs_club_player,
    [club_op.OP_JOIN_AGREED] = on_cs_club_agree_request,
    [club_op.OP_JOIN_REJECTED] = on_cs_club_reject_request,
    [club_op.OP_EXIT_AGREED] = on_cs_club_agree_request,
    [club_op.OP_EXIT_REJECTED] = on_cs_club_reject_request,
    [club_op.OP_APPLY_EXIT] = on_cs_club_exit,
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

function on_cs_club_lock_table(msg,guid)

end

function on_cs_club_unlock_table(msg,guid)

end

function on_cs_online_member_without_gaming(msg,guid)

end

function on_cs_invite_member_to_game(msg,guid)

end

function on_cs_response_invite_to_game(msg,guid)

end