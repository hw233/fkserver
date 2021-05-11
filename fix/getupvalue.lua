
local function getupvalues(func)
	local vals = {}
	for i = 1,math.huge do
		local name, value = debug.getupvalue(func, i)
		if name == nil then
			return vals
		end

		vals[name] = value
	end

	return vals
end

return getupvalues