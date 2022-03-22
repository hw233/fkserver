-- 跑得快消息处理

local log = require "log"
local player_context = require "game.lobby.player_context"
local room = require "game.land.land_room"

-- 出牌
function on_cs_land_do_action(msg,guid)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_land_do_action player not found.")
		return
	end

	local tb = room:find_table_by_player(player)
	if tb then
		tb:do_action(player, msg)
	else
		log.error(string.format("on_cs_land_do_action guid[%d] not in table.", guid))
	end
end

function  on_cs_land_trustee(msg, guid)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_land_trustee player not found.")
		return
	end

	local tb = room:find_table_by_player(player)
	if tb then
		tb:set_trusteeship(player,false)
	else
		log.error(string.format("guid[%d] LandTrusteeship", player.guid))
	end
end

function on_cs_land_compete_landlord(msg,guid)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_land_compete_landlord player not found.")
		return
	end

	local tb = room:find_table_by_player(player)
	if tb then
		tb:do_compete_landlord(player, msg)
	else
		log.error(string.format("on_cs_land_compete_landlord guid[%d] not in table.", guid))
	end
end