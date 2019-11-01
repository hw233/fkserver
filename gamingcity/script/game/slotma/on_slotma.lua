-- 老虎机消息处理

local pb = require "pb"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room


--玩家进入游戏
function on_cs_slotma_PlayerConnectionMsg( player, msg )
	-- body
	print("test ..................on_cs_slotma_PlayerConnectionMsg")
	local tb = room:find_table_by_player(player)
	if tb then
		tb:PlayerConnectionSlotmaGame(player)
	else
		log.error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 玩家离开游戏
function on_cs_slotma_PlayerLeaveGame(player,msg)
	print("test ..................on_cs_slotma_PlayerLeaveGame"..player.guid)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:playerLeaveSlotmaGame(player)
	else
		log.error(string.format("guid[%d] leave slotma game error.", player.guid))
	end
end

-- 用户叫分
function on_cs_slotma_start(player, msg)
	print ("test .................. on_cs_slotma_start")
	
	local tb = room:find_table_by_player(player)
	if tb then
		tb:slotma_start(player, msg)
	else
		log.error(string.format("guid[%d] player not find in the room", player.guid))
	end
end
-- 用户查询奖池
function on_cs_slotma_bonus(player, msg)
	print ("test .................. on_cs_slotma_bonus")
	
	local tb = room:find_table_by_player(player)
	if tb then
		tb:slotma_bonus(player)
	else
		log.error(string.format("guid[%d] player not find in the room", player.guid))
	end
end
