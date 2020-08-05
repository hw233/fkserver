
local root = require "redisorm.meta"

local matcher = {}

setmetatable(matcher,{
    __index = function(t,key)
        local n = root
        for s in string.gmatch(key,"[^%:|%.]+") do
            n = n[s]
        end
        return n
    end,
    __newindex = function(t,key,type)
        local model
        local n = root
        for s in string.gmatch(key,"[^%:|%.]+") do
            model = s
            n = n[model]
        end

        n.__parent[model] = type
    end
})

return matcher