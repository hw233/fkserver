-- 红黑消息处理

local pb = require "pb_files"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room

--下注
function on_CS_RedblackBet(player,msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:add_score(player,msg)
	end
end

--初始化
function on_CS_RedblackInit(player,msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:player_enter(player)
	end
end

