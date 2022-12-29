local base_room = require "game.lobby.base_room"
local maajan_table = require "game.maajan_zigong.table"

local maajan_room = base_room:new()

-- 创建桌子
function maajan_room:create_table()
	return maajan_table:new()
end

return maajan_room