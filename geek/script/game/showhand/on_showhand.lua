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
		tb:add_score(player, msg)
	else
		log.error("guid[%d] add_score error", player.guid)
	end
end

-- 弃牌
function on_cs_showhand_give_up(player, msg)
	print ("test .................. on_cs_showhand_give_up")
	local tb = room:find_table_by_player(player)
	if tb then
		tb:give_up(player,msg)
	else
		log.error("guid[%d] give_up error", player.guid)
	end
end
-- 让牌
function on_cs_showhand_pass(player, msg)
	print ("test .................. on_cs_showhand_pass")
	local tb = room:find_table_by_player(player)
	if tb then
		tb:pass(player,msg)
	else
		log.error("guid[%d] pass error", player.guid)
	end
end

function on_cs_showhand_give_up_eixt(player, msg)
	print ("test .................. on_cs_showhand_give_up_eixt")
	local tb = room:find_table_by_player(player)
	if tb then
		tb:give_up_eixt(player,msg)
	else
		log.error("guid[%d] give_up_eixt error", player.guid)
	end
end

