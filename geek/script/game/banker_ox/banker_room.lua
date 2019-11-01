-- banker房间

local pb = require "pb_files"

local base_room = require "game.lobby.base_room"
local banker_table = require "game.banker_ox.banker_table"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")
local GAME_SERVER_RESULT_IN_GAME = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")

-- 创建桌子
function base_room:create_table()
	return banker_table:new()
end

-- 坐下处理
function base_room:on_sit_down(player)
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
function base_room:auto_sit_down(player)
	print "banker ox auto sit down ....................."

	local result_, table_id_, chair_id_ = base_room.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 坐下
function base_room:sit_down(player, table_id_, chair_id_)
	print "banker sit down ....................."

	local result_, table_id_, chair_id_ = base_room.sit_down(self, player, table_id_, chair_id_)
	
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起
--function base_room:stand_up(player)
--	print "banker stand up ....................."
--
--	local tb = self:find_table_by_player(player)
--	if tb then
--		local chat = {
--		chat_content = player.account .. " stand up!",
--			chat_guid = player.guid,
--			chat_name = player.account,
--		}
--		--tb:broadcast2client("SC_ChatTable", chat)
--	end
--	return base_room.stand_up(self, player)
--end


-- 玩家掉线
--[[function base_room:player_offline(player)
	local room = self:find_room(player.room_id)
	if not room then

	print("is ready_mode off line   1")
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		print("is ready_mode off line   2")
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	
		local chair = tb:get_player(player.chair_id)
	if not chair then
	print("is ready_mode off line   3")
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
	print("is ready_mode off line   4")
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end

	local tableid, chairid = player.table_id, player.chair_id

	if tb:player_stand_up(player, true) then
		local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
		tb:foreach(function (p)
			p:on_notify_stand_up(notify)
		end)

		tb:check_start(true)

	print("is ready_mode off line   5")
		return GAME_SERVER_RESULT_SUCCESS, false
	end

	local notify = {
		table_id = tableid,
		chair_id = chairid,
		guid = player.guid,
		is_offline = true,
	}
	tb:foreach_except(chairid, function (p)
		if not tb.is_play then
			print("AAAAAAAAAA~~~~~~~~~~~!", tb.status)
			p:on_notify_stand_up(notify)
		end
	end)
	print("is ready_mode off line   0")
	return GAME_SERVER_RESULT_SUCCESS, true
end--]]

-- 站起并离开房间
function base_room:stand_up_and_exit_room(player)
	print("base_room:stand_up_and_exit_room=============================")
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
	if tb:is_play() and tb:in_Banker(player) then
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

return base_room