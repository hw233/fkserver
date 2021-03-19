-- 牛牛房间


local base_room = require "game.lobby.base_room"
local ox_table = require "game.ox.table"

local ox_room = setmetatable({},{__index = base_room})

function ox_room:create_table()
	return ox_table:new()
end

function ox_room:get_private_fee(rule)
	local chair_opt = rule.room.player_count_option
	local round_opt = rule.round.option
	return self.conf.private_conf.fee[(chair_opt or 0) + 1][(round_opt or 0) + 1]
end

return ox_room