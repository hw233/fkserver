local pb = require "pb_files"

require "functions"
local log = require "log"

local dbopt = require "dbopt"

require "db.msg.on_log"

-- local old_on_sl_log_money = on_sd_log_game_money
function on_sd_log_game_money_in_bonus(game_id, msg)
	old_on_sl_log_money(game_id,msg)

	if not msg.guid or msg.guid <= 0 then return end

	local db = dbopt.game

	local data = db:query([[SELECT first_game_type FROM config.t_game_server_cfg WHERE game_id = %d;]],msg.gameid)
	if data.errno or #data == 0 then return end

	local first_game_type = data[1].first_game_type
	if first_game_type == 0 then  return end

	local data1 = db:query([[SELECT * FROM game.t_bonus_activity WHERE start_time <= NOW() AND end_time > NOW() AND platform_id = %d;]],msg.platform_id)
	if not data1 or #data1 == 0 then return end
	
	table.walk(data1,function(activity) 
		local data2 = db:query([[SELECT * FROM game.t_bonus_game_statistics WHERE guid = %d AND bonus_activity_id = %d 
			AND first_game_type = %d AND platform_id = %d;]],msg.guid,activity.id,first_game_type,msg.platform_id)
		if data2.errno or #data2 == 0 then
			db:query([[INSERT INTO game.t_bonus_game_statistics VALUES(%d,%d,%d,%d,1,%d);]],
					msg.guid,activity.id,msg.platform_id,msg.change_money,first_game_type)
		else
			db:query([[UPDATE game.t_bonus_game_statistics SET  money = money + %d,times = times + 1 
				WHERE guid = %d AND bonus_activity_id = %d AND first_game_type = %d AND platform_id = %d;]],
							msg.change_money,msg.guid,activity.id,first_game_type,msg.platform_id)
		end
	end)
end

function on_sd_query_player_bonus_game_statistics(game_id, msg)
	local db = dbopt.game
	local sql = string.format("SELECT guid,bonus_activity_id,sum(money) money,sum(times) times,platform_id FROM game.t_bonus_game_statistics WHERE guid = %d",msg.guid)
	if  msg.pb_game_types and #msg.pb_game_types ~= 0 then
		sql = sql..string.format('  AND first_game_type in (%s)',table.concat(msg.pb_game_types,','))
	end

	if msg.bonus_activity_id and msg.bonus_activity_id >= 0 then
		sql = sql .. string.format('  AND bonus_activity_id = %d',msg.bonus_activity_id)
	end

	if msg.platform_id and msg.platform_id >= 0 then
		sql = sql .. string.format('  AND platform_id = %d',msg.platform_id)
	end

	sql = sql.." GROUP BY bonus_activity_id,guid,platform_id;"

	dump(sql)

	local data = db:query(sql)
	if data.errno or #data == 0 then 
		return {pb_statistics = {}}
	end

	local reply = {}
	table.walk(data,function(statistics)
		table.push_back(reply,{
			guid = tonumber(statistics.guid),
			bonus_activity_id = tonumber(statistics.bonus_activity_id),
			times = tonumber(statistics.times),
			money = tonumber(statistics.money),
			platform_id = tonumber(statistics.platform_id)
		})
	end)
	return {pb_statistics = reply}
end

function on_sd_create_bonus_hongbao(game_id, msg)
	local db = dbopt.game
	for _,bonus in pairs(msg.pb_bonuses) do
		dump(bonus)
		local sql = string.format([[INSERT INTO game.t_player_bonus(guid,bonus_activity_id,bonus_index,money,get_in_game_id,valid_time_until) 
		VALUES(%d,%d,%d,%d,%d,FROM_UNIXTIME(%d));]],
			bonus.guid,bonus.bonus_activity_id,bonus.bonus_index,bonus.money,bonus.get_in_game_id,bonus.valid_time_until)
		db:query(sql)
		
		return {guid = bonus.guid,pb_bonuses = {}}
	end
end

function on_sd_pick_bonus_hongbao(game_id,msg)
	local db = dbopt.game
	local data = db:query("UPDATE game.t_player_bonus SET is_pick = 1 WHERE guid = %d AND bonus_activity_id = %d AND bonus_index = %d;",
		msg.guid,msg.bonus_activity_id,msg.bonus_index)

	return {
		guid = msg.guid,
		bonus_activity_id = msg.bonus_activity_id,
		bonus_index = msg.bonus_index,
		success = data == 0 and false or  true
	}
end

function on_sd_query_active_bonus_hongbao_activity(game_id,msg)
	local sql = string.format([[SELECT id,UNIX_TIMESTAMP(start_time) start_time,UNIX_TIMESTAMP(end_time) end_time,platform_id,cfg FROM game.t_bonus_activity
										 WHERE 1 = 1]])
	if msg and msg.id and msg.id >= 0 then
		sql = sql..string.format(" AND id = %d",msg.id)
	end 

	if msg and msg.platform_id and msg.platform_id >= 0 then
		sql = sql..string.format(" AND platform_id = %d",msg.platform_id)
	end

	sql = sql.." ORDER BY start_time DESC,end_time DESC;"

	-- log.info(sql)

	local data = dbopt.game:query(sql)
	if data.errno or #data == 0 then 
		return 
	end

	dump(data)

	local activities = {}
	table.walk(data,function(activity)
		table.push_back(activities,{id = activity.id,start_time = activity.start_time,end_time = activity.end_time,cfg = activity.cfg,platform_id = activity.platform_id})
	end)

	return {pb_activities = activities}
end

function on_sd_query_bonus_hongbao(game_id,msg)
	local sql = string.format([[SELECT guid,bonus_activity_id,bonus_index,money,get_in_game_id,UNIX_TIMESTAMP(get_time) get_time,
										UNIX_TIMESTAMP(valid_time_until) valid_time_until,is_pick FROM game.t_player_bonus WHERE guid = %d AND valid_time_until > NOW()]],
										msg.guid)
	if msg.bonus_activity_id and msg.bonus_activity_id ~= 0 then
		sql = sql..string.format(" AND bonus_activity_id = %d",msg.bonus_activity_id)
	end 

	if  msg.is_pick then
		sql = sql..string.format(" AND is_pick = %d",msg.is_pick and 1 or 0)
	end

	sql = sql..";"

	local data = dbopt.game:query(sql)
	if data.errno or #data == 0 then 
		return {guid = msg.guid,pb_bonuses = {}}
	end

	local bonuses = {}
	table.walk(data,function(bonus)
		table.push_back(bonuses,{guid = bonus.guid,bonus_activity_id = bonus.bonus_activity_id,bonus_index = bonus.bonus_index,
						money = bonus.money,get_in_game_id = bonus.get_in_game_id,valid_time_until = bonus.valid_time_until,is_pick = (tonumber(bonus.is_pick) ~= 0)})
	end)
	
	return {guid = msg.guid,pb_bonuses = bonuses}
end


function on_sd_query_bonus_activity_limit_info(game_id,msg)
	local sql = string.format([[SELECT * FROM game.t_player_bonus_activity_limit WHERE guid = %d AND activity_id = %d;]],
										msg.guid,msg.activity_id)
	dump(sql)
	local data = dbopt.game:query(sql)
	if data.errno or #data == 0 then 
		return {guid = msg.guid,activity_id = msg.activity_id,bonus_index = 1}
	end
	
	return {
		guid = msg.guid,
		activity_id = msg.activity_id,
		bonus_index = data[1].bonus_index,
		play_count_min = data[1].play_count_min,
		play_count_max = data[1].play_count_max,
		money = data[1].money
	}
end


function on_sd_update_bonus_activity_limit_info(game_id,msg)
	local db = dbopt.game
	local data = db:query([[SELECT * FROM game.t_player_bonus_activity_limit WHERE guid = %d AND activity_id = %d;]],
							msg.guid,msg.activity_id)
	dump(data)
	if data.errno or #data == 0 then 
		db:query("INSERT INTO game.t_player_bonus_activity_limit VALUES(%d,%d,%d,%d,%d,%d);",
			msg.guid,msg.activity_id,msg.bonus_index,msg.play_count_min,msg.play_count_max,msg.money
		)
	else
		db:query(
			"UPDATE game.t_player_bonus_activity_limit SET bonus_index = %d,play_count_min = %d,play_count_max = %d,money = %d WHERE guid = %d AND activity_id = %d;",
			msg.bonus_index,msg.play_count_min,msg.play_count_max,msg.money,msg.guid,msg.activity_id
		)
	end
end



