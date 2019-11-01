-- 梭哈房间

local pb = require "pb"

local base_room = require "game.lobby.base_room"
require "game.showhand.showhand_table"

local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

showhand_room = base_room

-- 初始化房间
function showhand_room:init(tb, chair_count, ready_mode,room_lua_cfg)
	base_room.init(self, tb, chair_count, ready_mode,room_lua_cfg)
end

-- 创建桌子
function showhand_room:create_table()
	return showhand_table:new()
end

-- 坐下处理
function showhand_room:on_sit_down(player)
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
function showhand_room:auto_sit_down(player)
	print "test showhand auto sit down ....................."
	local result_, table_id_, chair_id_ = base_room.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end

-- 坐下
function showhand_room:sit_down(player, table_id_, chair_id_)
	print "test showhand sit down ....................."
	local result_, table_id_, chair_id_ = base_room.sit_down(self, player, table_id_, chair_id_)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end

-- 站起
function showhand_room:stand_up(player)
	print "test showhand stand up ....................."

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
function showhand_room:player_offline(player)

	local ret,is_offline_ = base_room.player_offline(self,player)

	if is_offline_ then
		local tb = self:find_table_by_player(player)
		if tb then
			tb:player_offline(player)
		end
	end

	return ret,is_offline_
end

