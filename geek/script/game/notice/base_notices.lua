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
			for _, nkey in pairs(reddb:keys("notice:info:*") or {}) do
				local nid = string.match(nkey,"notice:info:(.+)")
				t[nid] = load_notice(nid)
			end
			return t
		end

		local c = load_notice(id)
		t[id] = c
		return c
	end
})

return base_notices
