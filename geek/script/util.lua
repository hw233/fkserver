local json = require "cjson"

local util = {}

local function object2net(obj)
    local _,v = pcall(json.encode,obj)
    return v
end

function util.format_sync_info(type,id,obj)
    id.type = type
    return {
        id = object2net(id),
        data = object2net(obj),
    }
end

return util