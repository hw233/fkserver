local redisopt = require "redisopt"
local base_clubs = require "game.club.base_clubs"

local reddb = redisopt.default

local cls_player_club = {}
function cls_player_club:get()
	return base_clubs[self.cid]
end

local base_player_club = setmetatable({},{
	__index = function(t,guid)
		local cids = reddb:smembers("player:club:"..tostring(guid))
		if not cids then
			return nil
		end

		local clubs = {}
		for _,cid in pairs(cids) do
			cid = tonumber(cid)
			clubs[cid] = setmetatable({cid = cid,},{__index = cls_player_club,})
		end
		
		t[guid] = clubs
		return clubs
	end,
})

return base_player_club