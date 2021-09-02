local channel = require "channel"
local onlineguid = require "netguidopt"
local redisopt = require "redisopt"
local base_players = require "game.lobby.base_players"
local log = require "log"
local g_common = require "common"
local allonlineguid = require "allonlineguid"

local reddb  = redisopt.default

local string = string
local table = table

local common = {}

function common.find_best_room(first_game_type,second_game_type)
	return g_common.find_lightest_weight_game_server(first_game_type,second_game_type)
end

function common.all_game_server(first_game_type,second_game_type)
	return g_common.all_game_server(first_game_type,second_game_type)
end

function common.lobby_id(guid)
	return g_common.lobby_id(guid)
end

function common.switch_to(guid,room_id)
	if room_id == def_game_id then return end

	log.info("%s switch_to from %s to %s",guid,def_game_id,room_id)
	channel.call("game."..tostring(room_id),"msg","SS_ChangeGame",guid)

	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		-1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		-1,def_game_id)

	local player = base_players[guid]
	player.table_id = nil
	player.chair_id = nil
	player.online = nil
	player.active = nil
	allonlineguid[guid] = nil
	onlineguid[guid] = nil
	base_players[guid] = nil
end

function common.switch_from(guid,room_id)
	if room_id == def_game_id then return end

	local player = base_players[guid]
	player.online = true
	player.active = true

	log.info("%s switch_from from %s to %s",guid,room_id,def_game_id)
	channel.call("game."..tostring(room_id),"msg","SS_ChangeTo",guid,def_game_id)
	
	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		1,def_game_id)

	onlineguid.goserver(guid,def_game_id)

	onlineguid[guid] = nil
end

function common.switch_to_lobby(guid)
	local room_id = common.lobby_id(guid)
	if not room_id then
		log.error("common.switch_to_lobby can not find lobby.")
		return
	end

	if room_id == def_game_id then return end

	log.info("%s switch_to_lobby from %s to %s",guid,def_game_id,room_id)
	channel.call("game."..tostring(room_id),"msg","SS_ChangeGame",guid)
	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		-1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		-1,def_game_id)

	local player = base_players[guid]
	player.table_id = nil
	player.chair_id = nil
	player.online = nil
	player.active = nil

	allonlineguid[guid] = nil
	onlineguid[guid] = nil
	base_players[guid] = nil

	return true
end

function common.is_in_lobby()
	return def_first_game_type == 1
end

function common.is_player_in_lobby(guid)
	local os = onlineguid[guid]
	return os and os.server and os.first_game_type == common.lobby_game_type()
end

function common.lobby_game_type()
	return 1
end

return common