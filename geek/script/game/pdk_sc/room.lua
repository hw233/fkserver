-- 跑得快房间

local base_room = require "game.lobby.base_room"
local pdk_table = require "game.pdk_sc.table"
require "functions"

local pdk_room = setmetatable({},{__index = base_room})

function pdk_room:create_table()
	return pdk_table:new()
end

return pdk_room