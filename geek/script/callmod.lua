
local string = string
local strfmt = string.format

local function callmod(mod,...)
	local filename = package.searchpath(mod, package.path)
	if not filename then
		error(strfmt("not found module %s",mod))
		return
	end

	local fn,err = loadfile(filename)
	if not fn then
		error(err)
		return
	end

	local ok,err = pcall(fn,...)
	if not ok then
		error(err)
		return
	end

    return true
end

return callmod