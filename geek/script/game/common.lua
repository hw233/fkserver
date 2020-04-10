local serviceconf = require "serviceconf"
local channel = require "channel"

local function get_room_player_count(room_id)
	return channel.call("game."..tostring(room_id),"lua","get_player_count")
end

function find_best_room(first_game_type,second_game_type)
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