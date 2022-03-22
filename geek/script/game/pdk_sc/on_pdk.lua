-- 跑得快消息处理

local log = require "log"
local player_context = require "game.lobby.player_context"

function on_cs_pdk_do_action(msg,guid)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_pdk_do_action player not found.")
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:do_action(player, msg)
	else
		log.error(string.format("on_cs_pdk_do_action guid[%d] not in table.", guid))
	end
end