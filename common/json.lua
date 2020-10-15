
local cjson = require "cjson"

function cjson.loadfile(filename)
    local f = assert(io.open(filename , "rb"))
	local buffer = f:read "*a"
	local tb = cjson.decode(buffer)
	f:close()
	return tb
end

return cjson