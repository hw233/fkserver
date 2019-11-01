local obj = require "game.fishing.logic.object"

local speed = {}

function speed.create(type_id,param,life,owner)
    local buf = {
        owner = owner,
        type_id = type_id,
        param = param,
        life = life,
    }

    return setmetatable(buf,speed)
end

function speed:on_event(e)

end

function speed:update(delta)

end

local double_cannon = {}

function double_cannon.create(type_id,param,life,owner)
    local buf = {
        owner = owner,
        type_id = type_id,
        param = param,
        life = life,
    }

    return setmetatable(buf,double_cannon)
end

function double_cannon:on_event(e)

end

function double_cannon:update(delta)

end

local ion_cannon = {}

function ion_cannon.create(type_id,param,life,owner)
    local buf = {
        owner = owner,
        type_id = type_id,
        param = param,
        life = life,
    }

    return setmetatable(buf,ion_cannon)
end

function ion_cannon:on_event(e)

end

function ion_cannon:update(delta)

end


local add_mul_by_hit = {}

function add_mul_by_hit.create(type_id,param,life,owner)
    local buf = {
        owner = owner,
        type_id = type_id,
        param = param,
        life = life,
    }

    return setmetatable(buf,add_mul_by_hit)
end

function add_mul_by_hit:on_event(e)

end

function add_mul_by_hit:update(delta)

end

local buffer = {
    speed = speed,
    double_cannon = double_cannon,
    ion_cannon = ion_cannon,
    add_mul_by_hit = add_mul_by_hit,
	[obj.EBT_CHANGESPEED] = speed,		--改变速度
	[obj.EBT_DOUBLE_CANNON] = double_cannon,		--双倍炮
	[obj.EBT_ION_CANNON] = ion_cannon,		--离子炮
	[obj.EBT_ADDMUL_BYHIT] = add_mul_by_hit,		--被击吃子弹
}

return buffer