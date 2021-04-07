
local redisopt = require "redisopt"

local reddb = redisopt.default

local log = require "log"

local allonlineguid = setmetatable({},{
	__index = function(t,guid)
		if not guid or guid == "*" then
			local guids = table.map(reddb:smembers("player:online:all"),function(v,k) 
				return tonumber(k),v
			end)
			return guids
		end

		local is = reddb:sismember("player:online:all",guid)
		return is
	end,
})

return allonlineguid