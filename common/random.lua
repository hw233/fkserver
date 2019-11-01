
local random = {}

function random.integer(min, max)
    return math.random(min, max)
end

function random.float(precision)
    precision = precision or 10000
    return random.integer(0, precision) / precision
end

function random.boost_integer(min, max)
	return random.integer(min,max)
end

function random.boost_01()
	return math.random(0,10000) / 10000
end

function random.boost(min, max)
    -- body
    if min == nil then
        return
    end
    if max == nil then
        max = min
        min = 1
    end
    return random.boost_integer(min, max)
end


function random.boost_key(min, max , random_key )
    if min == nil then
        return
    end    
    if max == nil then
        return
    end
    if random_key == nil then
        random_key = max
        max = min
        min = 1
    end
    return math.random(min,max)
end

math.randomseed(tostring(os.time()):reverse():sub(1, 6))

return random
