require "functions"
local base_room = require "game.lobby.base_room"
require "game.twenty_one.twenty_one_table"

local pb = require "pb"

local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_IN_GAME = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
local GAME_SERVER_RESULT_IN_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER")
local GAME_SERVER_RESULT_PLAYER_NO_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_NO_CHAIR")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")

twenty_one_room = class("twenty_one_room",base_room)

function twenty_one_room:ctor( ... )
    
end


function twenty_one_room:init(tb, chair_count, ready_mode,room_lua_cfg)
	base_room.init(self, tb, chair_count, ready_mode,room_lua_cfg)
    self:update_lua_cfg(room_lua_cfg)
end

function twenty_one_room:update_lua_cfg( room_lua_cfg )
    log.warning(string.format("twenty_one_room:load_lua_cfg,%s",room_lua_cfg))
    local cfg = json.decode(room_lua_cfg)

    if not cfg then return end

    if cfg.broadcast_cfg and cfg.broadcast_cfg.money then
		 broadcast_cfg = cfg.broadcast_cfg 
	end

    if cfg.bet_money_units and #cfg.bet_money_units == 5 then bet_money_units = cfg.bet_money_units end

	if cfg.kill_points_prob then
		if cfg.kill_points_prob.player_kill_prob then kill_points_prob.player_kill_prob = cfg.kill_points_prob.player_kill_prob end
		if cfg.kill_points_prob.banker_blackjack_prob then kill_points_prob.banker_blackjack_prob = cfg.kill_points_prob.banker_blackjack_prob end
		if cfg.kill_points_prob.player_blackjack_prob then kill_points_prob.player_blackjack_prob = cfg.kill_points_prob.player_blackjack_prob end
		if cfg.kill_points_prob.player_blackjack_count then kill_points_prob.player_blackjack_count = cfg.kill_points_prob.player_blackjack_count end
		if cfg.kill_points_prob.player_no_aice_double_prob then kill_points_prob.player_no_aice_double_prob = cfg.kill_points_prob.player_no_aice_double_prob end
	end

	return true
end

-- gm重新更新配置, room_lua_cfg
function twenty_one_room:gm_update_cfg(rooms, room_lua_cfg)
    log.warning(room_lua_cfg)
    self:update_lua_cfg(room_lua_cfg)

	local old_count = #self.room_list_
	for i,v in ipairs(rooms) do
		if i <= old_count then
			print("change----gm_update_cfg", v.table_count, self.chair_count_, v.money_limit, v.cell_money,v.game_switch_is_open)
			self.room_list_[i]:gm_update_cfg(self,v.table_count, self.chair_count_, v.money_limit, v.cell_money, v, room_lua_cfg)
		else
			local r = self:create_room()
			print("Init----gm_update_cfg", v.table_count, self.chair_count_, v.money_limit, v.cell_money)
			r:init(self, v.table_count, self.chair_count_, self.ready_mode_, v.money_limit, v.cell_money, v, room_lua_cfg)
			self.room_list_[i] = r
		end
	end
end

-- 创建桌子
function twenty_one_room:create_table()
	return twenty_one_table:new()
end


function twenty_one_room:player_offline(player)
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

	return GAME_SERVER_RESULT_SUCCESS, true
end
