-- 梭哈消息处理

local pb = require "pb_files"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room


-- 用户加注
function on_cs_showhand_add_score(player, msg)
	print ("test .................. on_cs_showhand_add_score")

	local tb = room:find_table_by_player(player)
	if tb then
		tb:add_score(player, msg.score_type, msg.score)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

-- 放弃跟注
--function on_cs_showhand_give_up(player, msg)
--	print ("test .................. on_cs_showhand_give_up")
--	local tb = room:find_table_by_player(player)
--	if tb then
--		tb:give_up(player)
--	else
--		log.error("guid[%d] stand up", player.guid)
--	end
--end
