local channel = require "channel"
local onlineguid = require "netguidopt"
local redisopt = require "redisopt"
local base_players = require "game.lobby.base_players"
local log = require "log"
local util = require "util"

local reddb  = redisopt.default

local common = {}

local function get_room_player_count(room_id)
	return channel.call("game."..tostring(room_id),"lua","get_player_count")
end

function common.find_best_room(first_game_type,second_game_type)
	return util.find_lightest_weight_game_server(first_game_type,second_game_type)
end

function common.switch_room(guid,room_id)
	if room_id == def_game_id then return end

	log.info("%s switch room from %s to %s",guid,def_game_id,room_id)
	channel.call("game."..tostring(room_id),"msg","SS_ChangeGame",guid)

	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		-1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		-1,def_game_id)

	base_players[guid].online = nil
	onlineguid[guid] = nil
	base_players[guid] = nil
end

function common.switch_to_lobby(guid)
	local room_id = common.find_best_room(1)
	if not room_id then
		log.error("common.switch_to_lobby can not find lobby.")
		return
	end

	if room_id == def_game_id then return end

	log.info("%s switch_to_lobby from %s to %s",guid,def_game_id,room_id)
	channel.call("game."..tostring(room_id),"msg","SS_ChangeGame",guid)
	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		1,def_game_id)

	base_players[guid].online = nil
	onlineguid[guid] = nil
	base_players[guid] = nil
end

return common