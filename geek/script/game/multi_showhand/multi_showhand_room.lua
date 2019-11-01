-- 梭哈房间

local pb = require "pb_files"

local base_room = require "game.lobby.base_room"
require "game.multi_showhand.multi_showhand_table"

local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

local multi_showhand_room = base_room


-- 创建桌子
function multi_showhand_room:create_table()
	return multi_showhand_table:new()
end

-- 坐下处理
function multi_showhand_room:on_sit_down(player)
	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
			chat_content = player.account .. " sit down!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		--tb:broadcast2client("SC_ChatTable", chat)
	end
end

-- 快速坐下
function multi_showhand_room:auto_sit_down(player)
	print "test multi_showhand auto sit down ....................."
	local result_, table_id_, chair_id_ = base_room.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end

-- 坐下
function multi_showhand_room:sit_down(player, table_id_, chair_id_)
	print "test multi_showhand sit down ....................."
	local result_, table_id_, chair_id_ = base_room.sit_down(self, player, table_id_, chair_id_)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end

-- 站起
function multi_showhand_room:stand_up(player)
	print "test multi_showhand stand up ....................."

	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
		chat_content = player.account .. " stand up!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		--tb:broadcast2client("SC_ChatTable", chat)
	end
	return base_room.stand_up(self, player)
end

-- 玩家掉线
function multi_showhand_room:player_offline(player)

	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
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

		return GAME_SERVER_RESULT_SUCCESS, false
	end

	local notify = {
		table_id = tableid,
		chair_id = chairid,
		guid = player.guid,
		is_offline = true,
	}
	tb:foreach_except(chairid, function (p)
		if not tb:is_play(player) then
			log.info("multi_showhand player_offline guid[%d]" ,player.guid)
			p:on_notify_stand_up(notify)
		end
	end)
	local tb = self:find_table_by_player(player)
	if tb then
		tb:player_offline(player)
	end

	return GAME_SERVER_RESULT_SUCCESS, true


	--[[local ret,is_offline_ = base_room.player_offline(self,player)
	if is_offline_ then
		local tb = self:find_table_by_player(player)
		if tb then
			tb:player_offline(player)
		end
	end

	return ret,is_offline_--]]
end

return multi_showhand_room