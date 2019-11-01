local obj = require "game.fishing.logic.object"
local mathaide = require "game.fishing.logic.mathaide"
local component = require "game.fishing.logic.component"
require "game.fishing.config"

local bullet = {}

function bullet.create(conf,pos,dir,cannon_type,cannon_mul,forward)
    local b = {
        id = obj.gen_id(),
        type = obj.EOT_BULLET,
        type_id = cannon_mul,
        max_catch = conf.max_catch,
        catch_radio = conf.catch_radio,
        cannon_type = cannon_type,
        score = conf.mulriple,
        guid = nil,
        size = conf.bullet_size,
        double = false,
        probolitiy = conf.probolitiy,
        component = {},
        events = {},
    }

    local bufmgr = component.buffer_manager.create(b)
    b.component[bufmgr.id] = bufmgr

    local move = component.move_by_direction.create(b,pos,dir,speed)
    if forward then
        move.update( 100 * 1000 / conf.speed * system_set.scale.h)
    end

    return setmetatable(b,{__index = bullet,})
end

function bullet:hit_test(fish)
    if not fish or fish.state >= obj.EOS_DEAD then
        return false
    end
    
    local pos = {x = 0,y = 0}
    local move = self.component[obj.ECF_MOVE]
    if move then
        if move.target_id ~= 0 and fish.id ~= move.target_id then 
            return false 
        end

        pos= move.pos
    end

    local fpos = fish.pos
    local dir = fish.direction
    local bdx = fish.boundbox_id
    if bound_box[bdx] then
        for _,bb in ipairs(bound_box[bdx].BB) do
            local bps = mathaide.rotate_by_offset(fpos,bb.offset,dir)
            if mathaide.distance(bps,pos) < bb.radio + self.size then
                return true
            end
        end
    end

	return false
end

function bullet.net_cast(b,fish)
    
end

function bullet:update(delta)
    
end


return bullet