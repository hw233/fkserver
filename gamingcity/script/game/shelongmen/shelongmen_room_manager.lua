require "functions"
local base_room = require "game.lobby.base_room"
require "game.shelongmen.shelongmen_table"

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

shelongmen_room = class("shelongmen_room",base_room)

function shelongmen_room:ctor( ... )
    
end


function shelongmen_room:init(tb, chair_count, ready_mode,room_lua_cfg)
	base_room.init(self, tb, chair_count, ready_mode,room_lua_cfg)
    self:update_lua_cfg(room_lua_cfg)
end

function shelongmen_room:update_lua_cfg( room_lua_cfg )
	log.warning(string.format("shelongmen_room:load_lua_cfg,%s",room_lua_cfg))
	if not room_lua_cfg or room_lua_cfg == "" then
		return
	end
   
    local cfg = json.decode(room_lua_cfg)

    if not cfg then return end

    if cfg.broadcast and cfg.broadcast.money then
		 broadcast = cfg.broadcast 
	end

    if cfg.bet_chips and #cfg.bet_chips == 6 then bet_chips = cfg.bet_chips end

	if cfg.type_prob and #cfg.type_prob == 5 then type_prob = cfg.type_prob end

	if cfg.table_bet_limit then table_bet_limit = cfg.table_bet_limit end

	if cfg.always_kill_prob then always_kill_prob = cfg.always_kill_prob end

	return true
end

-- gm???????????, room_lua_cfg
function shelongmen_room:gm_update_cfg(rooms, room_lua_cfg)
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

-- ????????
function shelongmen_room:create_table()
	return shelongmen_table:new()
end


function shelongmen_room:player_offline(player)
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
