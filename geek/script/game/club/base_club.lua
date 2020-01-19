local redisopt = require "redisopt"
local log = require "log"
require "functions"
local base_players = require "game.lobby.base_players"
local club_member = require "game.club.club_member"
local base_private_table = require "game.lobby.base_private_table"
local table_template = require "game.lobby.table_template"
local club_table_template = require "game.club.club_table_template"
local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local json = require "cjson"
local channel = require "channel"
local base_mail = require "game.mail.base_mail"

local reddb = redisopt.default

local table_expire_seconds = 60 * 60 * 5

local base_club = {}

function base_club:create(id,name,icon,owner,tp,parent)
    id = tonumber(id)
    local owner_guid = type(owner) == "number" and owner or owner.guid
    local c = {
        name = name,
        icon = icon,
        id = id,
        owner = owner_guid,
        type = tp,
        parent = parent,
    }

    dump(c)

    if not channel.call("db.?","msg","SD_CreateClub",c) then
        return
    end

    reddb:sadd("club:all",id)
    reddb:hmset("club:info:"..tostring(id),c)
    reddb:sadd("club:member:"..tostring(id),owner_guid)
    reddb:hset("club:role:"..tostring(id),tostring(owner_guid),enum.CRT_BOSS)
    c.tables = {}
    setmetatable(c,base_club)
    base_club[id] = c

    return id
end

function base_club:dismiss()
    reddb:del("club:info:"..tostring(self.id))
    reddb:del("club:memeber:"..tostring(self.id))
    channel.call("db.?","msg","SD_DismissClub",self.id)
end

function base_club:request_join(guid)
	local req_id = reddb:incr("request:global:id")
	req_id = tonumber(req_id)
	local request = {
		id = req_id,
		type = "join",
		club_id = self.id,
        who = guid,
        whoee = self.owner,
    }

    reddb:hmset("request:"..tostring(req_id),request)
    reddb:sadd(string.format("club:request:%s",self.id),req_id)

    return req_id
end

function base_club:invite_join(invitee,inviter_club,type)
    if string.lower(type) == "invite_join" then
        self:join(invitee)
        club_member[self.id] = nil
        return true
    end

    if string.lower(type) == "invite_create" then
        local mail_info = base_mail.create_mail(inviter_club.owner,invitee,"联盟邀请...",{
            type = type,
            club_id = self.id,
            whoee = invitee,
            who = inviter_club.owner,
        })

        base_mail.send_mail(mail_info)
        return mail_info.id
    end
end

function base_club:agree_request(request)
    dump(request)
    local who = request.who
    local whoee = request.whoee

	local player = base_players[whoee]
	if not player then
		log.error("agree club request,who is unkown,guid:%s",whoee)
		return
    end

    if request.type == "join" then
        self:join(who)
        reddb:srem(string.format("club:request:%s",request.club_id),request.id)
    elseif request.type == "exit" then
        self:exit(who)
        reddb:srem(string.format("club:request:%s",request.club_id),request.id)
    elseif request.type == "invite" then
        self:join(whoee)
        reddb:srem(string.format("club:request:%s",request.club_id),request.id)
    end

    club_member[self.id] = nil
    reddb:del(string.format("request:%s",request.id))
    return true
end

function base_club:reject_request(request)
    local whoee = request.whoee
	local player = base_players[whoee]
	if not player then
		log.error("agree club request,who is unkown,guid:%s",whoee)
		return
    end

    reddb:srem(string.format("player:request:%s",whoee),request.id)

    reddb:del(string.format("request:%s",request.id))
    return true
end

function base_club:join(guid)
    local is_join = channel.call("db.?","msg","SD_JoinClub",{club_id = self.id,guid = guid})
    if not is_join then
        return
    end

	reddb:sadd(string.format("club:member:%s",self.id),guid)
    reddb:sadd(string.format("player:club:%s",guid),self.id)
end

function base_club:exit(guid)
    local is_join = channel.call("db.?","msg","SD_ExitClub",{club_id = self.id,guid = guid})
    if not is_join then
        return
    end

	reddb:srem(string.format("club:member:%s",self.id),guid)
	reddb:srem(string.format("player:club:%s",guid),self.id)
end

function base_club:broadcast(msgname,msg,except)
    if except then
        except = type(except) == "number" and except or except.guid
    end
    for guid,_ in pairs(club_member[self.id]) do
        if not except or except ~= guid then
            onlineguid.send(guid,msgname,msg)
        end
    end
end

function base_club:create_table(player,chair_count,round,conf)
    local member = club_member[self.id][player.guid]
    if not member then
        log.warning("create club table,but guid [%s] not exists",player.guid)
        return enum.ERROR_NOT_IS_CLUB_MEMBER
    end

    local result,global_tid,tb = g_room:create_private_table(player,chair_count,round,conf)
    if result == enum.GAME_SERVER_RESULT_SUCCESS then
        reddb:hset("table:info:"..global_tid,"club_id",self.id)
        reddb:sadd("club:table:"..self.id,global_tid)
        reddb:expire("club:table:"..self.id,table_expire_seconds)
        base_private_table[global_tid].club_id = self.id
    end

    return result,global_tid,tb
end

function base_club:join_table(player,private_table,chair_count)
    return g_room:join_private_table(player,private_table,chair_count)
end

function base_club:create_table_template(game_id,desc,rule,advanced_rule)
    local ok,ruletb = pcall(json.decode,rule) 
    if not ok or not ruletb then
        return enum.ERORR_PARAMETER_ERROR
    end
    local id = tonumber(reddb:incr("template:global:id"))

    local info = {
        template_id = id,
        club_id = self.id,
        game_id = game_id,
        description = desc,
        rule = type(rule) == "string" and rule or json.encode(rule),
        advanced_rule = type(advanced_rule) == "string" and advanced_rule or json.encode(advanced_rule),
    }

    reddb:hmset(string.format("template:%d",id),info)
    reddb:sadd(string.format("club:template:%d",self.id),id)

    club_table_template[self.id] = nil
    local _ = table_template[id]

    self:broadcast("S2C_NOTIFY_TABLE_TEMPLATE",{
        sync = enum.SYNC_ADD,
        template = {
            template = info,
            club_id = self.id,
            visual = true,
            conf = json.encode({})
        }
    })

    return enum.ERROR_NONE,info
end

function base_club:remove_table_template(template_id)
    if not template_id then
        return enum.ERORR_PARAMETER_ERROR
    end

    template_id = tonumber(template_id)
    reddb:del(string.format("template:%d",template_id))
    reddb:srem(string.format("club:template:%d",self.id),template_id)
    table_template[template_id] = nil
    club_table_template[self.id][template_id] = nil

    self:broadcast("S2C_NOTIFY_TABLE_TEMPLATE",{
        sync = enum.SYNC_DEL,
        template = {
            template = {
                template_id = template_id,
            },
            club_id = self.id,
        }
    })

    return enum.ERROR_NONE
end

function base_club:modify_table_template(template_id,game_id,desc,rule,advanced_rule)
    if not template_id then
        log.error("modify_table_template template_id is nil.")
        return enum.ERORR_PARAMETER_ERROR
    end

    template_id = tonumber(template_id)

    local ok,ruletb = pcall(json.decode,rule)
    if not ok or not ruletb then
        log.error("modify_table_template rule is illegel.")
        return enum.ERORR_PARAMETER_ERROR
    end

    local template = table_template[template_id]
    if not template then
        log.error("modify_table_template template not exists.")
        return enum.ERORR_PARAMETER_ERROR
    end

    local info = {
        template_id = template_id,
        club_id = self.id,
        game_id = (game_id and game_id ~= 0) and game_id or template.game_id,
        description = (desc and desc ~= "") and desc or template.description,
        rule = (rule and rule ~= "") and rule or template.rule,
        advanced_rule = (advanced_rule and advanced_rule ~= "") and advanced_rule or template.advanced_rule
    }

    dump(info)

    reddb:hmset(string.format("template:%d",template_id),info)

    table_template[template_id] = nil
    club_table_template[self.id][template_id] = nil 

    self:broadcast("S2C_NOTIFY_TABLE_TEMPLATE",{
        sync = enum.SYNC_UPDATE,
        template = {
            template = info,
            club_id = self.id,
            visual = true,
            conf = json.encode({}),
        },
    })

    return enum.ERROR_NONE,info
end



return base_club