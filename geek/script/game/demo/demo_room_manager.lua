-- demo房间
local base_room = require "game.lobby.base_room"

local pb = require "pb_files"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")


demo_room = base_room  

-- 初始化房间
function demo_room:init(tb, chair_count, ready_mode)
	base_room.init(self, tb, chair_count, ready_mode)
end

-- 坐下处理
function demo_room:on_sit_down(player)
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
function demo_room:auto_sit_down(player)
	print "test demo auto sit down ....................."

	local result_, table_id_, chair_id_ = base_room.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 坐下
function demo_room:sit_down(player, table_id_, chair_id_)
	print "test demo sit down ....................."

	local result_, table_id_, chair_id_ = base_room.sit_down(self, player, table_id_, chair_id_)
	
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起
function demo_room:stand_up(player)
	print "test demo stand up ....................."
	
	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
		chat_content = player.account .. " stand up!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end
	return base_room.stand_up(self, player)
end


