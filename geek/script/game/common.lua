local serviceconf = require "serviceconf"
local channel = require "channel"
local onlineguid = require "netguidopt"
local redisopt = require "redisopt"
local base_players = require "game.lobby.base_players"

local reddb  = redisopt.default

local common = {}

local function get_room_player_count(room_id)
	return channel.call("game."..tostring(room_id),"lua","get_player_count")
end

function common.find_best_room(first_game_type,second_game_type)
	local room_id 
	local cur_player_count
	for id,_ in pairs(channel.query()) do
		id = tonumber(id:match("game%.(%d+)"))
		if id then
			local gameconf = serviceconf[id].conf
			if 	gameconf.first_game_type == first_game_type
				and (not second_game_type or second_game_type == gameconf.second_game_type) then
				local player_count = get_room_player_count(id)
				if player_count < gameconf.player_limit and (not cur_player_count or player_count < gameconf.player_limit)   then
					room_id = id
					cur_player_count = player_count
				end
			end
		end
	end

	return room_id
end

function common.switch_room(guid,room_id)
	if room_id == def_game_id then return end

	log.info("%s switch room from %s to %s",guid,def_game_id,room_id)
	channel.call("game."..tostring(room_id),"msg","SS_ChangeGame",guid)
	reddb:decr(string.format("player:online:count:%s:%d:%d",def_game_name,def_first_game_type,def_second_game_type))
	reddb:decr(string.format("player:online:count:%s:%d:%d:%d",def_game_name,def_first_game_type,def_second_game_type,def_game_id))
	onlineguid[guid] = nil
	base_players[guid] = nil
end

return common