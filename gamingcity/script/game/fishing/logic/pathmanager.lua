local mathaide = require "game.fishing.logic.mathaide"
require "game.fishing.config"
require "functions"
local math = require "math"
local skynet = require "skynet"

local pathmanager = {
    NPT_LINE = 0,
    NPT_BEZIER = 1,
    NPT_CIRCLE = 2,
}

local function swap(x,y)
    local t = x
    x = y
    y = x
end

function pathmanager.create_circle(conf,mirror,nt)
    local ps = clone(conf.point)
    if mirror and mirror.x then
        ps[1].x = 1.0 - ps[0].x
        ps[3].x = math.pi - ps[3].x
        ps[3].y = -ps[3].y
    end

    if mirror and mirror.y then
        ps[1].y = 1.0 - ps[0].y
        ps[3].x = 2 * math.pi - ps[3].y
        ps[3].y = -ps[3].y
    end

    if mirror and mirror.xy then
        local t = ps[1].x
        ps[1].x = 1.0 - ps[1].y
        ps[1].y = 1.0 - t
        ps[3].x = ps[3].x + math.pi / 2
    end

    if nt then
        ps[3].x = ps[3].x + ps[3].y
		ps[3].y = -ps[3].y
    end

    ps[1].x = ps[1].x * system_set.default_screen_set.width
    ps[1].y = ps[1].y * system_set.default_screen_set.height
    
    local points = mathaide.circle_path(ps[1],ps[2].x,ps[3].x,ps[3].y,1,ps[2].y)
    if conf.delay and points then
        local lastpoint = points[#points]
        for i = 1,conf.delay do
            table.insert(points,lastpoint)
        end
    end

    return points
end



function pathmanager.create_bezier_or_linear(conf,mirror,nt)
    local ps = clone(conf.point)
    if mirror and mirror.x then
        for _,p in ipairs(ps) do
            p.x = 1 - p.x
        end
    end

    if mirror and mirror.y then
        for _,p in ipairs(ps) do
            p.y = 1 - p.y
        end
    end

    if mirror and mirror.xy then  
        for _,p in ipairs(ps) do
            swap(p.x,p.y)
        end
    end

    if nt then
        local n = #ps
        for i = 1,n do
            swap(ps[i],ps[n-i])
        end
    end

    for _,p in ipairs(ps) do
        p.x = p.x * system_set.default_screen_set.width
        p.y = p.y * system_set.default_screen_set.height
    end

    local points = conf.type == pathmanager.NPT_LINE and mathaide.linear(ps,1) or mathaide.bezier(ps,1000)
    if conf.delay and points then
        local lastpoint = points[#points]
        for i = 1,conf.delay do
            table.insert(points,lastpoint)
        end
    end

    return points
end

function pathmanager.create_normal_path(conf,mirror,nt)
    local path = {}
    local points
    while conf do
        if conf.type == pathmanager.NPT_CIRCLE then
            points = pathmanager.create_circle(conf,mirror,nt)
        else
            points = pathmanager.create_bezier_or_linear(conf,mirror,nt)
        end

        if points then
            table.insertto(path,points)
        end

        conf = fish_path[conf.next]
    end

    return points
end

function pathmanager.create_troop_path(conf)
    local path = {}
    local points
    while conf do
        if conf.type == pathmanager.NPT_CIRCLE then
            points = pathmanager.create_circle(conf)
        else
            points = pathmanager.create_bezier_or_linear(conf)
        end

        if points then
            table.insertto(path,points)
        end

        conf = troop_path[conf.next]
    end

    return points
end

function pathmanager.create_troop(conf)
    local troop = {shape = {}}
    troop.describe_text = conf.describe_text

    for _,shape in ipairs(conf.shape or {}) do
        local path
        if shape.type == pathmanager.NPT_LINE then
            local p0,p1 = shape.pos[1],shape.pos[#shape.pos]
            path = mathaide.linear(shape.pos,mathaide.distance(p0,p1) / #shape.pos)
        elseif shape.type == pathmanager.NPT_CIRCLE then
            path = mathaide.circle(shape.center,shape.radius,shape.count)
        end
        if path then
            for _,p in ipairs(path) do
                local shapepoint = {
                    pos = p,
                    same = conf.same,
                    pice_count = conf.pice_count,
                    path = conf.path,
                    interval = conf.interval,
                    speed = conf.speed,
                    fish_type = conf.fish_type,
                    weight = conf.weight,
                }
                table.insert(troop.shape,shapepoint)
            end
        end
    end

    if conf.points then
        table.insertto(troop.shape,conf.points)
    end

    return troop
end

function pathmanager.init_troop()
    pathmanager.troops = {}
    for id,troop in pairs(troop) do
        local starttime = os.clock()
        pathmanager.troops[id] = pathmanager.create_troop(troop)
        print("troop",id,troop.type, "interval",os.clock() - starttime)
    end

    pathmanager.trooppath = {}
    for id,conf in pairs(troop_path) do
        local starttime = os.clock()
        pathmanager.trooppath[id] = pathmanager.create_troop_path(conf)
        print("troop_path",id,conf.type, "interval",os.clock() - starttime)
    end
end

function pathmanager.init_normal_path()
    pathmanager.normalpath = {}
    for id,path in ipairs(fish_path) do
        local starttime = os.clock()
        for mx = 1,2 do
            for my = 1,2 do
                for mxy = 1,2 do
                    for nt = 1,2 do
                        table.insert(pathmanager.normalpath,
                            pathmanager.create_normal_path(path,{x = mx == 1,y = my == 1,xy = mxy == 1},nt == 1)
                        )
                    end
                end
            end
        end
        print("normal_path",id,path.type, "interval",os.clock() - starttime)
    end
end

function pathmanager.init()
    pathmanager.init_normal_path()
    pathmanager.init_troop()
end

skynet.fork(function() 
    pathmanager.init()
end)

return pathmanager