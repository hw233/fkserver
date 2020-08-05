
local obj = require "redisorm.object"


local db = {}

setmetatable(db,{
    __index = function(t,name)
        t[name] = obj
        return obj
    end
})

return db