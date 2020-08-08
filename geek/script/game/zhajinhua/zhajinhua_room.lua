-- 诈金花房间
local base_room = require "game.lobby.base_room"
local zhajinhua_table = require "game.zhajinhua.zhajinhua_table"

local zhajinhua_room = base_room:new()
function zhajinhua_room:create_table()
	return zhajinhua_table:new()
end

return zhajinhua_room