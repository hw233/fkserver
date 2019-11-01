-- classics房间

local pb = require "pb"

local base_room = require "game.lobby.base_room"
require "game.classics_ox.classics_table"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")
local GAME_SERVER_RESULT_IN_GAME = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
classics_room = base_room

-- 初始化房间
function classics_room:init(tb, chair_count, ready_mode, room_lua_cfg)
	base_room.init(self, tb, chair_count,ready_mode,room_lua_cfg)
end

-- 创建桌子
function classics_room:create_table()
	return classics_table:new()
end

-- 坐下处理
function classics_room:on_sit_down(player)
	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
			chat_content = player.account .. " sit down!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end
end

-- 快速坐下
function classics_room:auto_sit_down(player)
	print "classics ox auto sit down ....................."

	local result_, table_id_, chair_id_ = base_room.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 坐下
function classics_room:sit_down(player, table_id_, chair_id_)
	print "classics sit down ....................."

	local result_, table_id_, chair_id_ = base_room.sit_down(self, player, table_id_, chair_id_)
	
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起并离开房间
function classics_room:stand_up_and_exit_room(player)
	print("classics_room:stand_up_and_exit_room=============================")
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	
	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	if tb:is_play() and tb:in_classics(player) then
		return GAME_SERVER_RESULT_IN_GAME
	end
	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end

	local tableid = player.table_id
	local chairid = player.chair_id
	tb:player_stand_up(player, false)

	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)
	
	tb:check_start(true)

	local roomid = player.room_id
	room:player_exit_room(player)
	print("=============================12")
	return GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
end
