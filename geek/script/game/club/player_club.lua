local redisopt = require "redisopt"
local base_clubs = require "game.club.base_clubs"

local reddb = redisopt.default

local base_player_club = setmetatable({},{
	__index = function(t,guid)
		local cids = reddb:smembers("player:club:"..tostring(guid))
		if not cids then
			return nil
		end

		local clubs = {}
		for _,cid in pairs(cids) do
			cid = tonumber(cid)
			clubs[cid] = base_clubs[cid]
		end
		t[guid] = clubs
		return clubs
	end,
})

return base_player_club