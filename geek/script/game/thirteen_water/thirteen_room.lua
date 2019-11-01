-- 13水房间管理器

local pb = require "pb_files"

local base_room = require "game.lobby.base_room"
local thirteen_table = require "game.thirteen_water.thirteen_table"

local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

local thirteen_room = base_room:new()


-- 创建桌子
function thirteen_room:create_table()
	return thirteen_table:new()
end

-- 坐下处理
function thirteen_room:on_sit_down(player)
end

-- 快速坐下
function thirteen_room:auto_sit_down(player)
	print "test thirteen auto sit down ....................."
	local result_, table_id_, chair_id_ = base_room.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end

-- 坐下
function thirteen_room:sit_down(player, table_id_, chair_id_)
	print "test thirteen sit down ....................."
	local result_, table_id_, chair_id_ = base_room.sit_down(self, player, table_id_, chair_id_)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	return result_
end

-- 站起
function thirteen_room:stand_up(player)
	return base_room.stand_up(self, player)
end

-- 玩家掉线
function thirteen_room:player_offline(player)

	local ret,is_offline_ = base_room.player_offline(self,player)

	if is_offline_ then
		local tb = self:find_table_by_player(player)
		if tb then
			tb:player_offline(player)
		end
	end

	return ret,is_offline_
end

return thirteen_room