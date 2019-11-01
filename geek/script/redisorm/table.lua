
local table = {}

function table:new(meta)
    local o = {
        meta = meta,
    }

    setmetatable(o,{
        __index = table,
    })

    return o
end

function table:query(id)
    
end

return table