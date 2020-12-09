local redisopt = require "redisopt"
require "functions"

local reddb = redisopt.default

local player_winlose = setmetatable({},{
	__index = function(t,guid)
		local m = setmetatable({},{
			__index = function(_,money_id)
				return reddb:hget(string.format("player:winlose:%s",guid),money_id)
			end
		})
		t[guid] = m
		return m
    end,
})

function player_winlose.incr_money(player,money_id,money)
	if money == 0 then
		return money
	end

	local guid = type(player) == "number" and player or player.guid

	return reddb:hincrby(string.format("player:winlose:%s",guid),money_id,money)
end


return player_winlose