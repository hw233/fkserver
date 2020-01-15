local redisopt = require "redisopt"
local base_clubs = require "game.club.base_clubs"

local reddb = redisopt.default

local base_player_club = {}

setmetatable(base_player_club,{
	__index = function(t,guid)
		local cids = reddb:smembers("player:club:"..tostring(guid))
		local cs = {}
		for _,cid in pairs(cids) do
			cs[tonumber(cid)] = true
		end

		t[guid] = cs

		return cs
	end,
})

return base_player_club