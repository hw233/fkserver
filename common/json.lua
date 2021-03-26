
local cjson = require "cjson"

function cjson.loadfile(filename)
    local f = assert(io.open(filename , "rb"))
	local buffer = f:read "*a"
	local tb = cjson.decode(buffer)
	f:close()
	return tb
end

cjson.encode_sparse_array(true)
cjson.decode_json_null_value(false)

return cjson