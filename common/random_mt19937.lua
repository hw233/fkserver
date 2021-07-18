
local random = require "random"
local math = math

local rand = random.new(os.time())

math.randomseed = function(s)
    rand:seed(tonumber(s))
end

math.random = function(x,y)
    if not x then
        return rand(1,10000) / 10000
    end
    if not y then
        return math.floor(rand(1,x) + 0.00000001)
    end
    return math.floor(rand(x,y) + 0.00000001)
end