
local math = require "math"

local mathaide = {}

-- 阶乘
function mathaide.factorial(n)
	if n == 0 or n == 1 then return 1 end

	local function cn2(n)
		local x = (0x1 << n) + 0x1
		local mask = (0x1 << n) - 0x1
		return ((x^n) >> ((n >> 0x1) * n)) & mask
	end

	if n & 0x1 == 1 then
		return n * mathaide.factorial(n - 1)
	end

	return cn2(n) * mathaide.factorial(n >> 1)^2
end

-- 组合
function mathaide.combination(count, r)
	return mathaide.factorial(count) / (mathaide.factorial(r) * mathaide.factorial(count - r))
end

function mathaide.bernstein(n,i,t)
	-- Bernstein basis
	return mathaide.combination(n, i) * t^i * (1 - t)^(n - i)
end

-- 计算距离
function mathaide.distance(p1,p2)
	return math.sqrt((p1.x - p2.x)^2 + (p1.y - p2.y)^2)
end

-- 计算角度
function mathaide.angle(p1,p2)
	local distance = mathaide.distance(p1,p2)
	if distance == 0 then return 0 end
	local angle = math.acos((p1.x - p2.x) / distance)
	if p1.y < p2.y then
        angle = 2 * math.pi - angle
    end
	angle = angle + math.pi
	return angle
end

-- 创建线
function mathaide.linear(points, interval)
	if #points < 2 then return end

    if interval <= 0 then return end

    local lastpoint = points[#points]
    local firstpoint = points[1]

	local totaldist = mathaide.distance(lastpoint,firstpoint)
	if totaldist <= 0 then return end

	local cos = math.abs(lastpoint.y - firstpoint.y) / totaldist
	local angle = math.acos(cos)

    local linepoints = {}
    table.insert(linepoints,firstpoint)

    local pdistance = 0
    local offset = 0
	local point = {}
	
	while pdistance < totaldist do
		offset = #linepoints
		if lastpoint.x < firstpoint.x then
			point.x = firstpoint.x - math.sin(angle) * (interval * offset)
		else 
			point.x = firstpoint.x + math.sin(angle) * (interval * offset)
		end

		if lastpoint.y < firstpoint.y then
			point.y = firstpoint.y - math.cos(angle) * (interval * offset)
		else 
			point.y = firstpoint.y + math.cos(angle) * (interval * offset)
		end
		table.insert(linepoints,point)
		pdistance = mathaide.distance(point, firstpoint)
	end

    linepoints[#linepoints] = lastpoint
	return linepoints
end

function mathaide.bezier(points, cpts)
	if not points or #points < 3 then 
		return nil
	end

	local path = {}
	local step = 1.0 / (cpts - 1)
	local t = 0
	local c = #points
	local last

	for _ = 1,cpts do
		if ((1.0 - t) < 5e-6) then
			t = 1.0
		end

		local point = {x = 0,y = 0,dir = 1.0}
		for i = 0,c - 1 do
			local basis = mathaide.bernstein(c - 1, i, t)
			point.x = point.x + basis * points[i + 1].x
			point.y = point.y + basis * points[i + 1].y
		end

		point.dir = last and (mathaide.angle(point, last) - math.pi / 2) or 1.0
		last = point

		table.insert(path,point)
		t = t + step
	end

	return path
end

function mathaide.circle(center, radius,count)
    if count <= 0 or radius == 0 then return end

	local cellradian = 2 * math.pi / count
    local circlepoints = {}
    for i = 0,count - 1 do
        local p = {
            x = center.x + radius * math.cos(i * cellradian),
            y = center.y + radius * math.sin(i * cellradian),
            dir = cellradian,
        }
		table.insert(circlepoints,p)
    end

    return circlepoints
end

-- 创建循环路径
function mathaide.circle_path(center, radius, begin, angle, step, add)
	if angle == 0 or radius == 0 then return end
	if not step or step < 1 then step = 1 end
	if not add then add = 0 end

	local cir = 2 * math.pi * radius / step
	local count = cir * math.abs(angle) / (2 * math.pi)
	local cellradian =  2 * math.pi / cir * angle / math.abs(angle)

    local points = {}
    local last = {x = 0,y = 0,dir = 0}
    local p = {}
	for i = 0,count - 1 do
		p.x = center.x + radius * math.cos(begin + i * cellradian)
		p.y = center.y + radius * math.sin(begin + i * cellradian)
		p.dir = i == 0 and (begin + i * cellradian + math.pi / 2) or (mathaide.angle(last, p) + math.pi / 2)
		last = p
		radius = radius + add
		
		table.insert(points,p)
    end

    return points
end

-- 通过便宜获得旋转
function mathaide.rotate_by_offest(pos, offset, dir, scale)
    local p = {}

	local r = math.sqrt(offset.x ^ 2  + offset.y ^ 2)
	local fd = mathaide.angle({x = 0,y = 0}, offset) - math.pi / 2 + dir

	p.x = (pos.x - r * math.cos(fd)) * (scale and scale.h or 1)
	p.y = (pos.y - r * math.sin(fd)) * (scale and scale.v or 1)

	return p
end

print("mathaide.factorial(5)",mathaide.factorial(5) == 1*2*3*4*5)

return mathaide
