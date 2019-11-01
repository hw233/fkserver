local redisobject = {}
local redisopt = require "redisopt"

local reddb = redisopt.default

function redisobject:new(meta,id)
    local o = {
        meta = meta,
        id = id,
    }

    setmetatable(o,{
        __index = function(t,field)
            local rv = reddb:hset(self.meta:key(self.id),field)
            return self.meta:decode(rv)
        end,
        __newindex = function(t,field,v)
            reddb:hset(self.meta:key(self.id),field,self.meta:encode(v))
        end,
    })

    return o
end

function redisobject:set(meta,id,field,v)

end

function redisobject:get(meta,id,field,v)

end

return redisobject