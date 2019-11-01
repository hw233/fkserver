-- 斗地主房间

local pb = require "pb"

local base_room = require "game.lobby.base_room"
require "game.five_star.fivestar_table"

local get_second_time = get_second_time

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

-- 等待开始
local LAND_STATUS_FREE = 1


fivestar_room = base_room

-- 初始化房间
function fivestar_room:init(tb, chair_count, ready_mode, room_lua_cfg)
	base_room.init(self, tb, chair_count, ready_mode, room_lua_cfg)
end

-- 创建桌子
function fivestar_room:create_table()
	return fivestar_table:new()
end

---- 坐下处理
function fivestar_room:on_sit_down(player)
end

-- 获取当前桌子信息
function fivestar_room:get_table_players_status( player )
	-- 下发下注情况
end
-- 坐下
function fivestar_room:sit_down(player, table_id_, chair_id_)
	print "test land sit down ....................."

	local result_, table_id_, chair_id_ = base_room.sit_down(self, player, table_id_, chair_id_)

	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end

	return result_
end