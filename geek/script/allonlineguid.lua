
local redisopt = require "redisopt"

local reddb = redisopt.default

local allonlineguid = setmetatable({},{
	__index = function(t,guid)
		if not guid or guid == "*" then
			local guids = reddb:smembers("player:online:all")
			for uid,_ in pairs(guids) do
				t[uid] = true
			end
			return guids
		end

		local is = reddb:sismember("player:online:all",guid)
		t[guid] = is
		return is
	end,
})

return allonlineguid