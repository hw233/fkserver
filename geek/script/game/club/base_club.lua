local redisopt = require "redisopt"
local log = require "log"
require "functions"
local pb = require "pb_files"
local base_players = require "game.lobby.base_players"
local club_member = require "game.club.club_member"
local private_table = require "game.lobby.base_private_table"
local reddb = redisopt.default

local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

local ERROR_JOIN_ROOM_NO = pb.enum("ERROR_CODE", "ERROR_JOIN_ROOM_NO")

local ERROR_NOT_IS_CLUB_MEMBER = pb.enum("ERROR_CODE", "ERROR_NOT_IS_CLUB_MEMBER")

local base_club = {}

function base_club:create(name,icon,notice,owner)
    local id = reddb:incr("club:global:id")
    id = tonumber(id)
    local owner_guid = type(owner) == "number" and owner or owner.guid
    local c = {
        name = name,
        icon = icon,
        id = id,
        notice = notice,
        owner = owner_guid,
    }

    reddb:sadd("club:all",id)
    local r = reddb:hmset("club:info:"..tostring(id),c)
    reddb:sadd("club:member:"..tostring(id),owner_guid)
    c.tables = {}
    setmetatable(c,base_club)
    if r then
        base_club[id] = c
        return id
    end
end

function base_club:dismiss()
    reddb:del("club:info:"..tostring(self.id))
    reddb:del("club:memeber:"..tostring(self.id))
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
    reddb:sadd(string.format("player:request:%s",self.owner),req_id)

    return req_id
end

function base_club:invite_join(invitee,inviter)
	local req_id = reddb:incr("request:global:id")
	req_id = tonumber(req_id)
	local request = {
		id = req_id,
		type = "invite",
		club_id = self.id,
        whoee = invitee,
        who = inviter,
	}

    reddb:hmset("request:"..tostring(req_id),request)
    reddb:sadd(string.format("player:request:%s",invitee),req_id)
    return req_id
end

function base_club:agree_request(request)
    local who = request.who
    local whoee = request.whoee

	local player = base_players[whoee]
	if not player then
		log.error("agree club request,who is unkown,guid:%s",whoee)
		return
    end
    
    dump(request)

    if request.type == "join" then
        self:join(who)
        reddb:spop(string.format("player:request:%s",whoee),request.id)
    elseif request.type == "exit" then
        self:exit(who)
        reddb:spop(string.format("player:request:%s",whoee),request.id)
    elseif request.type == "invite" then
        self:join(whoee)
        reddb:spop(string.format("player:request:%s",who),request.id)
    end

    club_member[self.id] = nil
    reddb:del("club:request:"..tostring(request.id))
    return true
end

function base_club:reject_request(request)
    local who = request.who
    local whoee = request.whoee
	local player = base_players[whoee]
	if not player then
		log.error("agree club request,who is unkown,guid:%s",whoee)
		return
    end
 
    if request.type == "invite" then
        reddb:spop(string.format("player:request:%s",who),request.id)
    else
        reddb:spop(string.format("player:request:%s",whoee),request.id)
    end
    
    reddb:del("request:"..tostring(request.id))
    return true
end

function base_club:join(guid)
	reddb:sadd(string.format("club:member:%s",self.id),guid)
	reddb:sadd(string.format("player:club:%s",guid),self.id)
end

function base_club:exit(guid)
	reddb:spop(string.format("club:member:%s",self.id),guid)
	reddb:spop(string.format("player:club:%s",guid),self.id)
end

function base_club:create_table(player,chair_count,round,conf)
    local member = club_member[self.id][player.guid]
    if not member then
        log.error("create club table,but guid [%s] not exists",player.guid)
        return ERROR_NOT_IS_CLUB_MEMBER
    end

    local result,global_tid,tb = g_room:create_private_table(member,chair_count,round,conf)
    if result == GAME_SERVER_RESULT_SUCCESS then
        reddb:hset(string.format("table:info:%s",global_tid),"club_id",self.id)
        reddb:sadd(string.format("club:table:%s",self.id),global_tid)
    end
    
    return result,global_tid,tb
end

function base_club:join_table(player,private_table,chair_count)
    return g_room:join_private_table(player,private_table,chair_count)
end

return base_club