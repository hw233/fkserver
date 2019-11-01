-- 房间操作消息处理

local pb = require "pb"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


--local base_room = require "game.lobby.base_room"
local room = g_room

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type

-- 进入房间并坐下
function on_cs_enter_room_and_sit_down(player, msg)
	local result_, room_id_, table_id_, chair_id_, tb = room:enter_room_and_sit_down(player)
	player:on_enter_room_and_sit_down(room_id_, table_id_, chair_id_, result_, tb)
	room:get_table_players_status(player)
	print ("test .................. on_cs_enter_room_and_sit_down")
	print(string.format("result [%d]",result_))
end

-- 站起并离开房间
function on_cs_stand_up_and_exit_room(player, msg)	
	print ("test .................. on_cs_stand_up_and_exit_room~1")
	local result_, room_id_, table_id_, chair_id_ = room:stand_up_and_exit_room(player)
	print (result_)
	player:on_stand_up_and_exit_room(room_id_, table_id_, chair_id_, result_)
	print ("test .................. on_cs_stand_up_and_exit_room~2")
	print (result_)
	print(string.format("result [%d]",result_))
end

-- 切换座位
function on_cs_change_chair(player, msg)
	local result_, table_id_, chair_id_, tb = room:change_chair(player)
	player:on_change_chair(table_id_, chair_id_, result_, tb)
	
	print ("test .................. on_cs_change_chair")
end

-- 进入房间
function on_cs_enter_room(player, msg)
	local result_ = room:enter_room(player, msg.room_id)
	print("on_cs_enter_room:~~~~~~~~~~~~~~~~~~~~~~result_ = ",result_)
	if result_ == 14 then --game maintain
		log.warning(string.format("on_cs_enter_room: game_id =[%d], will maintain,exit",def_game_id))	
	end
	player:on_enter_room(msg.room_id, result_)
	
	print ("test .................. on_cs_enter_room")
end

-- 离开房间
function on_cs_exit_room(player, msg)
	local result_, room_id_ = room:exit_room(player)
	player:on_exit_room(room_id_, result_)
	
	print ("test .................. on_cs_exit_room")
end

-- 快速进入房间
function on_cs_auto_enter_room(player, msg)
	local result_, room_id_ = room:auto_enter_room(player)
	print("on_cs_auto_enter_room:~~~~~~~~~~~~~~~~~~~~~~result_ = ",result_)
	if result_ == 14 then --game maintain
		log.warning(string.format("on_cs_auto_enter_room: game_id =[%d], will maintain,exit",def_game_id))	
	end
	player:on_enter_room(room_id_, result_)

	print ("test .................. on_cs_auto_enter_room")
end

-- 快速坐下
function on_cs_auto_sit_down(player, msg)
	local result_, table_id_, chair_id_ = room:auto_sit_down(player)
	player:on_sit_down(table_id_, chair_id_, result_)
	room:get_table_players_status(player)
	print ("test .................. on_cs_auto_sit_down")
end

-- 坐下
function on_cs_sit_down(player, msg)
	local result_, table_id_, chair_id_  = room:sit_down(player, msg.table_id, msg.chair_id)
	player:on_sit_down(table_id_, chair_id_, result_)
	room:get_table_players_status(player)
	print ("test .................. on_cs_sit_down")
end

-- 站起
function on_cs_stand_up(player, msg)
	local result_, table_id_, chair_id_  = room:stand_up(player)
	player:on_stand_up(table_id_, chair_id_, result_)
	
	print ("test .................. on_cs_stand_up")
end

-- 准备开始
function on_cs_ready(player, msg)
	if player.disable == 1 then
		print("player is Freeaz forced_exit")
		-- 强行T下线
		player:forced_exit();
		return
	end
	if player.chair_id then
		print("on_cs_ready chair_id is :"..player.chair_id)
	end
	local tb = room:find_table_by_player(player)
	if tb then
		tb:ready(player)
	end

	print ("test .................. on_cs_ready")
end

function on_cs_change_table(player,msg)
	print ("test .................. on_cs_change_table")
	-- body
	--room:change_table(player)
	room:change_table_new(player)
end

function on_cs_exit(player,msg)
	print ("test .................. on_cs_exit")
	-- body
	room:exit_server(player,true)
end

function on_cs_Trusteeship(player,msg)
	print ("test .................. on_cs_Trusteeship")
	-- body
	room:cs_trusteeship(player)
end

-- 加载玩家数据
function on_cs_read_game_info(player)
	if player.is_offline then
		print("-------------------------1")
	end
	if room:is_play(player) then
		print("-------------------------2")
	end
	if player.is_offline and room:is_play(player) then
		print("=====================================send SC_ReadGameInfo")
		local notify = {
			pb_gmMessage = {
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				room_id = player.room_id,
				table_id = player.table_id,
				chair_id = player.chair_id,
			}
		}
		send2client_pb(player,  "SC_ReadGameInfo", notify)
		room:player_online(player)
		return
	end
	print("--------on_cs_read_game_info========")
	send2client_pb(player,  "SC_ReadGameInfo", nil)	
end

--请求玩家数据
function on_cs_reconnection_play_msg( player, msg )
	-- body
	local tb = room:find_table_by_player(player)
	if tb then
		tb:reconnection_play_msg(player)
	else
		send2client_pb(player,  "SC_ReconnectionPlay", {find_table = false})	
		log.error(string.format("guid[%d] stand up", player.guid))
	end
end