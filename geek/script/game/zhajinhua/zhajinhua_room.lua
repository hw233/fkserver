-- 诈金花房间
local base_room = require "game.lobby.base_room"
local zhajinhua_table = require "game.zhajinhua.zhajinhua_table"

local zhajinhua_room = base_room:new()

function zhajinhua_room:create_table()
	return zhajinhua_table:new()
end

function zhajinhua_room:get_private_fee(rule)
	local chair_opt = rule.room.player_count_option
	local round_opt = rule.round.option
	return self.conf.private_conf.fee[(chair_opt or 0) + 1][(round_opt or 0) + 1]
end

return zhajinhua_room