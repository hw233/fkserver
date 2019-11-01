local obj = require "game.fishing.logic.object"
local component = require "game.fishing.logic.component"
local effect = require "game.fishing.logic.effect"

local fish = {}

function fish.create(conf,fish_category,pos,dir,delay,speed,path_id,troop)
    local f = {
        id = obj.gen_id(),
        type = obj.EOT_FISH,
        type_id = conf.type_id,
        category = fish_category,
        probability = conf.probability,
        bounding_box = conf.bounding_box,
        score = 0,
        create_tick = os.clock(),
        state = 0,
        broadcast = conf.broadcast,
        boundbox_id = 0,
        lock_level = conf.lock_level,
        name = conf.name,
        refresh_id = conf.refresh_id,
        events = {},
        component = {},
    }

	if fish_category ~= obj.ESFT_NORMAL then
		f.broadcast = true
        local special_conf = nil
		if fish_category == obj.ESFT_KINGANDQUAN or fish_category == obj.ESFT_KING then
			special_conf = fish_king
			f.name = conf.name .. "鱼王"
		elseif fish_category == obj.ESFT_SANYUAN then
			special_conf = fish_sanyuan
			f.name = "大三元"
        elseif fish_category == obj.ESFT_SIXI then
            special_conf = fish_sixi
			f.name = "大四喜"
        end

        if special_conf and special_conf[conf.type_id] then
            local kks = special_conf[conf.type_id]
            if kks then
                if fish_category == obj.ESFT_KINGANDQUAN or fish_category == obj.ESFT_KING then
                    f.probability = fish_category == obj.ESFT_KINGANDQUAN and conf.probability / 5 or kks.catch_probability
                elseif fish_category == obj.ESFT_SANYUAN then
                    f.probability = conf.probability / 3.0
                elseif fish_category == obj.ESFT_SIXI then
                    f.probability = conf.probability / 4.0
                end

                f.lock_level = kks.lock_level

                if fish_category == obj.ESFT_KINGANDQUAN or fish_category == obj.ESFT_SANYUAN or fish_category == obj.ESFT_SIXI then
                    f.bounding_box = kks.bounding_box
                end
            end
        end
    end
    
	--路径ID大于0 有移动路径
	if path_id >= 0 then
		local c = componet.move_by_path.create(f,pos,delay,speed,path_id,troop)
        f.component[c.__index] = c
	else --无指定路径，按方向移动
		local c = component.move_by_direction.create(f,pos,dir,delay,speed,path_id)
        f.component[c.id] = c
    end

    --增加BUFF管理器
    local bufmgr = component.buffer_manager.create(f)
    f.component[bufmgr.id] = bufmgr
    if conf.buffer then
        --增加所有buffer
        for _,bufconf in pairs(conf.buffer) do
            bufmgr:add(buffer[buffconf.type_id].create(bufconf,owner))
        end
    end

	--当前鱼效果集大于1
	if conf.effect then
        --增加效果管理器
        local effectmgr = component.effect_manager.create(f)
        f.component[effectmgr.id] = effectmgr
        if fish_category == obj.ESFT_KINGANDQUAN or fish_category == obj.ESFT_KING then
            --创建杀死后效果
            local e = effect[obj.ETP_KILL].create(obj.ETP_KILL,{2,conf.type_id},f)
            if fish_king[conf.type_id] then
                table.insert(e.param,fish_king[conf.type_id].max_score)
            end
            effectmgr:add(e)

            --增加金币效果
            effectmgr:add(
                effect[obj.ETP_ADDMONEY].create(obj.ETP_ADDMONEY,{1,10},f)
                )
        end

        --增加所有效果
        for _,econf in pairs(conf.effect) do
            local e = effect[econf.type_id].create(econf.type_id,econf.param,f)
            if fish_category == obj.ESFT_SANYUAN then
                e.param[2] = e.param[2] * 3
            elseif fish_category == obj.ESFT_SIXI then
                e.param[2] = e.param[2] * 4
            end

            effectmgr:add(e)
        end

        --如果等于鱼王
        if fish_category == obj.ESFT_KINGANDQUAN then
            local e = effect[obj.ETP_PRODUCE].create(conf.type_id,{3,30,1},f)
            effectmgr:add(e)
        end
	end

	return setmetatable(f,{__index = f,})
end

function fish:update(delta)
    for _,c in pairs(self.component) do
        c:update(delta)
    end
end


return fish