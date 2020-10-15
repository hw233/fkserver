require "functions"

function eval(str)
	return assert(load(str))()
end

local cjson = require "cjson"
function json_decode_file(filename)
	local f = assert(io.open(filename , "rb"))
	local buffer = f:read "*a"
	local tb = cjson.decode(buffer)
	f:close()
	return tb
end