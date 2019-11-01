require "functions"
local base_room = require "game.lobby.base_room"
local sanshui_table = require "game.sanshui.sanshui_table"
local define = require "game.sanshui.logic.define"

local PlayerStatus = define.PLAYER_STATUS

local pb = require "pb_files"
local log = require "log"
local json = require "cjson"

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

local sanshui_room = base_room:new()

function sanshui_room:init(conf, chair_count, ready_mode)
	base_room.init(self, conf, chair_count, ready_mode)
    self:update_lua_cfg(conf.room_cfg)
end

function sanshui_room:update_lua_cfg( room_lua_cfg )
    local cfg = json.decode(room_lua_cfg)
    
    if not cfg then return end

    if cfg.broadcast_cfg then broadcast_cfg = cfg.broadcast_cfg end

    if cfg.peipai_cfg then peipai_cfg = cfg.peipai_cfg end

	return true
end

-- gm重新更新配置, room_lua_cfg
function sanshui_room:gm_update_cfg(rooms, room_lua_cfg)
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
function sanshui_room:create_table()
	return sanshui_table:new()
end

-- 站起并离开房间
function sanshui_room:stand_up_and_exit_room(player)
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

    if player.status > PlayerStatus.READY then
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
	if not tb:player_stand_up(player, false) then 
        log.warning("sanshui_table:player_stand_up false")
        return GAME_SERVER_RESULT_IN_GAME
    end

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
	return GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
end

return sanshui_room