local player_data = require "game.lobby.player_data"
local sessions = require "game.sessions"

return setmetatable({},{
	__index = function(_,guid)
		local d = player_data[guid]
		if not d then 
			return
		end


		local s = sessions.get(guid)
		if not s then 
			return
		end

		setmetatable(s,{ __index = d })
		return s
	end,
	__newindex = function(_,guid,v)
		if v == nil then
			sessions.del(guid)
		end
	end
})