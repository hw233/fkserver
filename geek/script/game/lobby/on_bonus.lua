local base_players = require "game.lobby.base_players"
local base_bonus = require "game.lobby.base_bonus"
require "functions"
require "game.lobby.on_login_logout"



function on_ds_query_game_statistics(msg)
	if not msg or not msg.pb_statistics then return end
	
	dump(msg.pb_statistics)
	table.walk(msg.pb_statistics,function(statistic)
		local player = base_players[statistic.guid]
		if not player then return end
		player:on_ds_load_game_statistics(statistic)
	end)
end


function on_ds_query_bonus_activities(msg)
	if not msg or not msg.pb_activities then return end

	dump(msg)
	table.walk(msg.pb_activities,function(activity)
		base_bonus:new_activity(activity.id,activity.start_time,activity.end_time,activity.platform_id,activity.cfg)
	end)

	base_players:foreach(function(p)
		local activity = base_bonus:latest_activity(tonumber(p.platform_id))
		dump(activity)
		if activity then
			send2client_pb(p,"SC_BonusActivity",{pb_activities = {activity:format_client_msg()}})
		else
			send2client_pb(p,"SC_BonusActivity",{})
		end
	end)
end


function on_ds_query_player_bonuses(msg)
	if not msg or not msg.pb_bonuses then return end

	dump(msg)
	local player = base_players[msg.guid]
	if not player then return end
	table.walk(msg.pb_bonuses,function(bonus) 
		player:on_ds_load_bonus(bonus)
	end)
	
	player:send_bonuses()
end

function on_ds_pick_bonus(msg)
	if not msg or not msg.success then return end
	
	local player = base_players[msg.guid]
	if not player then return end

	player:on_ds_pick_bonus(msg.bonus_activity_id,msg.bonus_index)
end


function on_cs_pick_bonus(player,msg)
	if not msg or not player then return end

	if	player.bonus and 
		player.bonus[msg.bonus_activity_id] and 
		player.bonus[msg.bonus_activity_id].hongbao[msg.index] then
		player.bonus[msg.bonus_activity_id].hongbao[msg.index]:pick()
	else
		send2client_pb(player,"SC_PickBonusResult",{
			guid = player.guid,
			bonus_activity_id = msg.bonus_activity_id,
			index = msg.index,
			success = false
		})
	end
end

function on_cs_query_bonus_activities(msg,guid)
	local player = base_players[guid]
	player:send_unelasped_activities()
end

function on_cs_query_bonus(msg,guid)
	local player = base_players[guid]
	player:send_bonuses()
end

function on_ls_load_bonus_config(msg)
	if not msg then return end
	base_bonus.load_activity(msg.activity_id)
end

function on_ds_load_current_bonus_activity_limit_info(msg)
	if not msg or not msg.guid then return end

	dump(msg)

	local player = base_players[msg.guid]
	if not player then return end

	player:on_ds_load_current_bonus_activity_limit_info(msg)
end


local  old_on_cs_request_player_info = on_cs_request_player_info
function on_cs_request_player_info(msg,guid)
	local player = base_players[guid]
	old_on_cs_request_player_info(player,msg)
	dump(player.platform_id)
	if not player:is_android() then
		player:send_unelasped_activities()
		player:load_bonus_hongbao()
		player:load_bonus_game_statisticss()
		player:load_bonus_activity_limit_info()
	end
end

local old_on_ss_change_game = on_ss_change_game
function on_ss_change_game(msg)
	old_on_ss_change_game(msg)

	local player = base_players[msg.guid]
	if not player or player:is_android() then return end

	player:send_unelasped_activities()
	player:load_bonus_hongbao()
	player:load_bonus_game_statisticss()
	player:load_bonus_activity_limit_info()
end