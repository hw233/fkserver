local redisopt = require "redisopt"
local wrap = require "fast_cache_wrap"
local queue = require "skynet.queue"

local reddb = redisopt.default

local table = table
local mfloor = math.floor
local strfmt = string.format


local infolock = setmetatable({},{
	__index = function(t,guid)
		local l = queue()
		t[guid] = l
		return l
	end,
})

local mgr = setmetatable({},{
	__index = function(t,guid)
		assert(guid)
		guid = mfloor(tonumber(guid))
		local l = infolock[guid]
		return l(function()
			-- double check
			local p = rawget(t,guid)
			if p then return p end
	
			p = reddb:hgetall(strfmt("player:info:%d",guid))
			if not p or table.nums(p) == 0 then
				return
			end
	
			t[guid] = p
			return p
		end)
	end,
	__newindex = function(t,guid,v)
		if v == nil then
			infolock[guid] = nil
			t[guid] = nil
		end
	end,
})

return wrap(mgr,2)