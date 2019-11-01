local object = {
	EOT_NONE = 0,				    --
	EOT_PLAYER = 1,					--玩家
	EOT_BULLET = 2,					--子弹
    EOT_FISH = 3,					--鱼
    
	EOS_LIVE = 0,					--存活
	EOS_HIT = 1,					--受击
	EOS_DEAD = 2,					--死亡
	EOS_DESTORY = 3,				--摧毁
    EOS_LIGHTING = 4,				--照明
    
	EME_STATE_CHANGED = 0,		    --状态变化
	EME_QUERY_SPEED_MUL = 1,		--查询速度倍率     --速度倍率？前端加速？
    EME_QUERY_ADDMUL = 2,			--查询额外增加的倍率

    EBT_NONE = 0,
	EBT_CHANGESPEED = 1,		--改变速度
	EBT_DOUBLE_CANNON = 2,		--双倍炮
	EBT_ION_CANNON = 3,			--离子炮
    EBT_ADDMUL_BYHIT = 4,		--被击吃子弹

    ECF_NONE = 0,
	ECF_MOVE = 1,		        --移动组件
	ECF_VISUAL = 2,		        --可视化组件
	ECF_EFFECTMGR = 3,	        --死亡效果管理器
    ECF_BUFFERMGR = 4,	        --ＢＵＦＦＥＲ管理器
    
    ETP_ADDMONEY = 0,			--增加金币
	ETP_KILL = 1,				--杀死其它鱼
	ETP_ADDBUFFER = 2,			--增加BUFFER
	ETP_PRODUCE = 3,			--生成其它鱼
	ETP_BLACKWATER = 4,			--乌贼喷墨汁效果
    ETP_AWARD = 5,				--抽奖
    
    EAT_NORMAL=0,
    EAT_ROTATION = 1,
    
    ESFT_NORMAL = 0,                  --普通
	ESFT_KING = 1,                    --鱼王
	ESFT_KINGANDQUAN = 2,             --鱼后
	ESFT_SANYUAN = 3,                 --大三元
	ESFT_SIXI = 4,                    --大四喜

	ERT_NORMAL = 0,
	ERT_GROUP = 1,				--鱼群
	ERT_LINE = 2,				--鱼队
	ERT_SNAK = 3,				--大蛇
}

local unique_id = 0
function object.gen_id()
    unique_id = unique_id + 1
    return unique_id
end

function object.create(type_id)
	return setmetatable({
		components = {},
		events = {},
		type_id = id,
	},object)
end

function object.process_com_event()

end


return object