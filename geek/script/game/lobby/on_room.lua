-- 房间操作消息处理

local pb = require "pb_files"
local log = require "log"
require "game.net_func"
local enum = require "pb_enums"
local send2client_pb = send2client_pb

local base_players = require "game.lobby.base_players"

-- 进入房间并坐下
function on_cs_enter_room_and_sit_down(msg,guid)
	local player = base_players[guid]
	local result_, room_id_, table_id_, chair_id_, tb = g_room:enter_room_and_sit_down(player)
	player:on_enter_room_and_sit_down(room_id_, table_id_, chair_id_, result_, tb)
	g_room:get_table_players_status(player)
	log.info ("test .................. on_cs_enter_room_and_sit_down")
	log.info(string.format("result [%d]",result_))
end

-- 站起并离开房间
function on_cs_stand_up_and_exit_room(msg,guid)	
	local player = base_players[guid]
	log.info ("test .................. on_cs_stand_up_and_exit_room~1")
	local result_, room_id_, table_id_, chair_id_ = g_room:stand_up_and_exit_room(player,enum.STANDUP_REASON_NORMAL)
	player:on_stand_up_and_exit_room(room_id_, table_id_, chair_id_, result_)
	log.info ("test .................. on_cs_stand_up_and_exit_room~2")
	log.info(string.format("result [%d]",result_))
end

-- 切换座位
function on_cs_change_chair(msg,guid)
	local player = base_players[guid]
	local result_, table_id_, chair_id_, tb = g_room:change_chair(player)
	player:on_change_chair(table_id_, chair_id_, result_, tb)
	
	log.info ("test .................. on_cs_change_chair")
end

-- 进入房间
function on_cs_enter_room(msg,guid)
	local player = base_players[guid]
	local result_ = g_room:enter_room(player, msg.room_id)
	log.info("on_cs_enter_g_room:~~~~~~~~~~~~~~~~~~~~~~result_ = ",result_)
	if result_ == 14 then --game maintain
		log.warning(string.format("on_cs_enter_g_room: game_id =[%d], will maintain,exit",def_game_id))	
	end
	player:on_enter_room(msg.room_id, result_)
	
	log.info ("test .................. on_cs_enter_room")
end

-- 离开房间
function on_cs_exit_room(msg,guid)
	local player = base_players[guid]
	local result_, room_id_ = g_room:exit_room(player)
	player:on_exit_room(room_id_, result_)
	
	log.info ("test .................. on_cs_exit_room")
end

-- 快速进入房间
function on_cs_auto_enter_room(msg,guid)
	local player = base_players[guid]
	local result_, room_id_ = g_room:auto_enter_room(player)
	log.info("on_cs_auto_enter_g_room:~~~~~~~~~~~~~~~~~~~~~~result_ = ",result_)
	if result_ == 14 then --game maintain
		log.warning(string.format("on_cs_auto_enter_g_room: game_id =[%d], will maintain,exit",def_game_id))	
	end
	player:on_enter_room(room_id_, result_)

	log.info ("test .................. on_cs_auto_enter_room")
end

-- 快速坐下
function on_cs_auto_sit_down(msg,guid)
	local player = base_players[guid]
	local result_, table_id_, chair_id_ = g_room:auto_sit_down(player)
	player:on_sit_down(table_id_, chair_id_, result_)
	g_room:get_table_players_status(player)
	log.info ("test .................. on_cs_auto_sit_down")
end

-- 坐下
function on_cs_sit_down(msg,guid)
	local player = base_players[guid]
	local result_, table_id_, chair_id_  = g_room:sit_down(player, msg.table_id, msg.chair_id)
	player:on_sit_down(table_id_, chair_id_, result_)
	g_room:get_table_players_status(player)
	log.info ("test .................. on_cs_sit_down")
end

-- 站起
function on_cs_stand_up(msg,guid)
	local player = base_players[guid]
	local result_, table_id_, chair_id_  = g_room:stand_up(player)
	player:on_stand_up(table_id_, chair_id_, result_)
	
	log.info ("test .................. on_cs_stand_up")
end

-- 准备开始
function on_cs_ready(msg,guid)
	local player = base_players[guid]
	if not player then
		log.error("on_cs_ready not found player,guid:%s",guid)
		return
	end
	if player.disable == 1 then
		log.info("player is Freeaz forced_exit")
		-- 强行T下线
		player:forced_exit()
		return
	end

	if not player.table_id then
		log.warning("on_cs_ready table_id is:%s",player.table_id)
	end

	if player.chair_id then
		log.info("on_cs_ready chair_id is:%s",player.chair_id)
	end

	local tb = g_room:find_table_by_player(player)
	if not tb then
		log.warning("on_cs_ready not find table,guid:%s",player.guid)
		return
	end

	tb:ready(player)

	log.info("test .................. on_cs_ready")
end

function on_cs_change_table(msg,guid)
	log.info ("test .................. on_cs_change_table")
	local player = base_players[guid]
	g_room:change_table_new(player)
end

function on_cs_exit(msg,guid)
	log.info ("test .................. on_cs_exit")
	local player = base_players[guid]
	g_room:exit_server(player,true)
end

function on_cs_trusteeship(msg,guid)
	log.info ("test .................. on_cs_Trusteeship")
	local player = base_players[guid]
	g_room:cs_trusteeship(player)
end

-- 加载玩家数据
function on_cs_read_game_info(msg,guid)
	local player = base_players[guid]
	if player.is_offline then
		log.info("-------------------------1")
	end
	
	if g_room:is_play(player) then
		log.info("-------------------------2")
	end

	if player.is_offline and g_room:is_play(player) then
		log.info("=====================================send SC_ReadGameInfo")
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
		g_room:player_online(player)
		return
	end
	log.info("--------on_cs_read_game_info========")
	send2client_pb(player,  "SC_ReadGameInfo", nil)
end

--请求玩家数据
function on_cs_reconnection_play_msg( msg,guid )
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_reconnect(player)
	else
		send2client_pb(player,  "SC_ReconnectionPlay", {find_table = false})
		log.error("guid[%d] stand up", player.guid)
	end
end

--解散房间
function on_cs_dismiss_table_req(msg,guid)
	local player = base_players[guid]
	if not player or not player.online then
		send2client_pb(guid,"SC_DismissTableReq",{
			result = enum.ERROR_PLAYER_NOT_EXIST,
		})
		return
	end

	local result = g_room:request_dismiss_private_table(player)
	if result ~= enum.ERROR_NONE then
		send2client_pb(guid,"SC_DismissTableReq",{
			result = result
		})
	end
end

function on_cs_dismiss_table_commit(msg,guid)
	local player = base_players[guid]
	if not player or not player.online then
		send2client_pb(guid,"SC_DismissTableCommit",{
			result = enum.ERROR_PLAYER_NOT_IN_ROOM,
		})
		return
	end

	local result = g_room:commit_dismiss_private_table(player,msg.agree)
	if result ~= enum.ERROR_NONE then
		send2client_pb(guid,"SC_DismissTableCommit",{
			result = result,
		})
	end
end

function on_s_get_table_status_info(table_id)
	local tb = g_room:find_table(table_id)
	if not tb then
		log.warning("can not find table,%s",table_id)
		return
	end

	return tb:global_status_info()
end
