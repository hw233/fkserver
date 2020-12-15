local redisopt = require "redisopt"
local log = require "log"

local reddb = redisopt.default

local function load_notice(id)
	local c = reddb:hgetall(string.format("notice:info:%s", id))
	if not c or table.nums(c) == 0 then
		return nil
	end

	return c
end

local base_notices =setmetatable({},{
	__index = function(t, id)
		if id == "*" then
			local all = reddb:smembers("notice:all")
			return table.series(all,function(_,id)
				return load_notice(id)
			end)
		end

		return load_notice(id)
	end
})

return base_notices
