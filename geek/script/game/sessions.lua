
local log = require "log"

local sessions = {}

local function getset(guid)
	local s = sessions[guid]
	if not s then 
		s = {}
		sessions[guid] = s
	end

	return s
end

local M_ = {
	new = function(guid)
		local s = sessions[guid]
		if s then
			log.error("sessions.new [%s] already exists",guid)
			return s 
		end
	
		s = {}
	
		sessions[guid] = s
	
		return s
	end,
	del = function(guid)
		sessions[guid] = nil
	end,
	rawget = function(guid)
		return sessions[guid]
	end,
	get = getset,
}

setmetatable(M_,{
	__index = function(_,guid)
		return getset(guid)
	end
})

return M_