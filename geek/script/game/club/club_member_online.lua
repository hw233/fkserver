
local redisopt = require "redisopt"

local reddb = redisopt.default

local string = string

local strfmt = string.format

local _M = setmetatable({},{
	__index = function(t,club_id)
		local guids = reddb:smembers(strfmt("club:member:online:guid:%s",club_id))
		return guids
	end
})

return _M