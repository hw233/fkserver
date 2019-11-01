-- 13水消息处理

local pb = require "pb"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room


-- 用户设定牌型
function on_cs_player_set_cards(player, msg)
	print ("test .................. on_cs_player_set_cards")
	local tb = room:find_table_by_player(player)
	if tb then
		tb:set_player_cards(player, msg)
	else
		log.error(string.format("guid[%d] set_cards error", player.guid))
	end
end

