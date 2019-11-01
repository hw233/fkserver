local obj = require "game.fishing.logic.object"
local pathmanager = require "game.fishing.logic.pathmanager"
local buffer = require "game.fishing.logic.buffer"
local effect = require "game.fishing.logic.effect"

local  move_by_path = {}

function move_by_path.create(owner,pos,delay,speed,path_id,troop)
    local c = {
        id = obj.EMCT_PATH,
        owner = owner,
        offset = pos,
        delay = delay,
        path = troop and pathmanager.troop[path_id] or pathmanager.normalpath[path_id],
        speed = speed,
        end_path = false,
        begin_move = false,
        target_id = 0,
        troop = troop,
        elaspe = 0,
        pause = false,
    }

    return setmetatable(c,{__index = move_by_path})
end


function move_by_path.update(self,delta)

end

local  move_by_direction = {}

function  move_by_direction.create(owner,pos,dir,delay,speed,path_id)
    local c = {
        id = obj.EMCT_DIRECTION,
        owner = owner,
        pos = pos,
        dir = dir,
        delay = delay,
        rebound = path_id == -1,
        speed = speed,
        angle = dir,
        pause = false,
        dx = math.cos(dir - math.pi / 2),
        dy = math.sin(dir - math.pi / 2),
        end_path = false,
    }
    return setmetatable(c,{__index = move_by_direction})
end

function  move_by_direction.update(self,delta)

end

local   buffer_manager = {}

function buffer_manager.create(owner)
    local c = {
        id = obj.EBCT_BUFFERMGR,
        owner = owner,
        buffers = {}
    }

    return setmetatable(c,{__index = buffer_manager})
end

function buffer_manager.update(self,delta)

end

function buffer_manager.add(self,type,param,life)
    table.insert(self.buffers,buffer[type].create(type,param,life,self.owner))
end


local  effect_manager = {}

function effect_manager.create(owner)
        local c = {
            id = obj.EECT_MGR,
            owner = owner,
            effects = {}
        }
        return setmetatable(c,{__index = effect_manager})
end

function effect_manager.add(self,e)
    table.insert(self.effects,e)
end

function effect_manager.update(self,delta)

end

local component = {
    effect_manager = effect_manager,
    buffer_manager = buffer_manager,
    move_by_direction = move_by_direction,
    move_by_path = move_by_path,
    [obj.EMCT_PATH] = move_by_path,
    [obj.EMCT_DIRECTION] = move_by_direction,
    [obj.EBCT_BUFFERMGR] = buffer_manager,
    [obj.EECT_MGR] = effect_manager,
}

return component