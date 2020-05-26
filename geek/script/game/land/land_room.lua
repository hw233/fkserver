-- 斗地主房间

local base_room = require "game.lobby.base_room"
local land_table = require "game.land.land_table"
require "functions"
local log = require "log"

local land_room = base_room.new()

-- 初始化房间
function land_room:init(tb, chair_count, ready_mode, room_lua_cfg)
	base_room.init(self, tb, chair_count, ready_mode, room_lua_cfg)
end

-- 创建桌子
function land_room:create_table()
	return land_table:new()
end

function land_room:get_table_players_status( player )
	base_room:get_table_players_status( player )
	if not player.room_id then
		log.info("player room_id is nil")
		return nil
	end
	local room = self.room_list_[player.room_id]
	if not room then
		if player.room_id then
			log.info("room not find room_id:%s",player.room_id)
		else
			log.info("room not find room_id")
		end
		return nil
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		if player.table_id then
			log.info("tablelist not find table_id:%s",player.table_id)
		else
			log.info("tablelist not find table_id")
		end
		return nil
	end
	log.info(string.format("table cunt is [%d] room_id is [%d] table_id is [%d] chair_id is [%d]",#tb:get_player_list(),player.room_id,player.table_id,player.chair_id))
	tb:foreach_except(player.chair_id,function(p) 
		if tb.ready_list_[p.chair_id] then
			log.info("player is  ready charid:%s",p.chair_id)
			local notify = {
				ready_chair_id = p.chair_id,
				is_ready = true,
				}
			send2client_pb(player, "SC_Ready", notify)
		end
	end)
end


return land_room