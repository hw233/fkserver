
local queue = require "skynet.queue"


return setmetatable({},{
	__index = function(t,club_id)
		local club = setmetatable({},{
			__index = function(t,guid)
				local lock = queue()
				t[guid] = lock
				return lock
			end,
		})

		t[club_id] = club
		return club
	end
})