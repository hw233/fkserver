-- 斗地主消息处理

local pb = require "pb_files"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room


-- 玩家下注
function on_CS_FiveStarBetting(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:fivestarBetting(player, msg)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

-- 玩家获取记录
function on_CS_FiveStarGetHistory(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:fivestarGetHistory(player)
	else
		log.error("guid[%d] call double", player.guid)
	end
end
-- 请求游戏数据
function on_CS_GetPlayInfo(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:get_playerInfo(player)
	else
		log.error("guid[%d] call double", player.guid)
	end
end

function on_CS_GetBigWinListHistory(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:fivestarGetBigWinHistory(player)
	else
		log.error("guid[%d] call double", player.guid)
	end
end
