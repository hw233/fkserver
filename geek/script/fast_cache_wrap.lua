local timer_task = require "timer_task"

return function(indexmeta,time)
	local mod = setmetatable({},{
		__index = indexmeta
	})

	timer_task.exec(time,function()
		mod = setmetatable({},{
			__index = indexmeta
		})
	end)

	return setmetatable({},{
		__index = function(t,k)
			return mod[k]
		end,
		__newindex = function(_,k,v)
			if v == nil then
				mod[k] = v
			end
		end,
	})
end