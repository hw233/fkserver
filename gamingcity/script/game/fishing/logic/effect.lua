local obj = require "game.fishing.logic.object"


local kill = {}

function kill.create(type_id,param,owner)
    local e = {
        type = type_id,
        param = param,
    }

    return setmetatable(e,{__index = kill,})
end

function kill:execute(selfobj,target,objs,pretreating)
    
end

local add_money = {}

function add_money.create(type_id,param,owner)
    local e = {
        type = type_id,
        param = param,
        lsco = 0,
    }

    return setmetatable(e,{__index = add_money,})
end

function add_money:execute(selfobj,target,objs,pretreating)
	if not selfobj then return 0 end

	local score = 0
	local mul = 1

	--鱼的倍数
	if self.lsco == 0 then
		self.lsco =  param[3] > param[2] and math.random(param[2], param[3]) or param[2]
    end

	if self.param[1] == 0 then
		mul = 1
    end

	local n = -1
	local se = {
        param = {0,n}
    }
	se.SetID(EME_QUERY_ADDMUL);
	se.SetParam1(0);
	se.SetParam2(&n);
	selfobj.ProcessCCEvent(&se);

	if(n != -1)
	{
		lSco = CGameConfig::GetInstance()->nAddMulBegin;

		if(n + lSco > GetParam(2))
			n = GetParam(2) - lSco;

		if(!bPretreating)
			CGameConfig::GetInstance()->nAddMulCur = 0;
	}
	else
		n = 0;

	lScore = (lSco + n) * mul;

	if(pTarget->GetObjType() == EOT_BULLET && ((CBullet*)pTarget)->bDouble())
		lScore *= 2;

	return lScore;
end

local add_buffer = {}

function add_buffer.create(type_id,param,owner)
    local e = {
        type = type_id,
        param = param,
    }

    return setmetatable(e,{__index = add_buffer,})
end

function add_buffer:execute(selfobj,target,objs,pretreating)

end

local produce = {}

function produce.create(type_id,param,owner)
    local e = {
        type = type_id,
        param = param,
    }

    return setmetatable(e,{__index = produce,})
end

function produce:execute(selfobj,target,objs,pretreating)

end

local black_water = {}

function black_water.create(type_id,param,owner)
    local e = {
        type = type_id,
        param = param,
    }

    return setmetatable(e,{__index = black_water,})
end

function black_water:execute(selfobj,target,objs,pretreating)

end

local award = {}

function award.create(type_id,param,owner)
    local e = {
        type = type_id,
        param = param,
    }

    return setmetatable(e,{__index = award,})
end

function award:execute(selfobj,target,objs,pretreating)

end

local effect = {
    kill = kill_effect,
    add_money = add_money,
    award = award,
    black_water = black_water,
    produce = produce,
    add_buffer = add_buffer,
    [obj.ETP_ADDMONEY] = add_money,			--增加金币
	[obj.ETP_KILL] = kill,					--杀死其它鱼
	[obj.ETP_ADDBUFFER] = add_buffer,				--增加BUFFER
	[obj.ETP_PRODUCE] = produce,				--生成其它鱼
	[obj.ETP_BLACKWATER] = black_water,				--乌贼喷墨汁效果
	[obj.ETP_AWARD] = award,					--抽奖
}

return effect