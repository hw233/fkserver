local define = {}

local pb = require "pb_files"

local TIME_TYPE = {
	MAIN_FAN_PAI = 2,
	MAIN_XI_PAI = 2,
}
define.TIME_TYPE= TIME_TYPE
local ACTION = {
	TRUSTEE = pb.enum("CP_ACTION","ACTION_TRUSTEE"),
	PENG = pb.enum("CP_ACTION","ACTION_PENG"),
	TOU = pb.enum("CP_ACTION","ACTION_TOU"),
	BA_GANG = pb.enum("CP_ACTION","ACTION_BA_GANG"),
	HU = pb.enum("CP_ACTION","ACTION_HU"),
	PASS = pb.enum("CP_ACTION","ACTION_PASS"),
	CHI = pb.enum("CP_ACTION","ACTION_CHI"),
	TING = pb.enum("CP_ACTION","ACTION_TING"),
	JIA_BEI = pb.enum("CP_ACTION","ACTION_JIA_BEI"),
	CHU_PAI = pb.enum("CP_ACTION","ACTION_CHU_PAI"),
	ZI_MO = pb.enum("CP_ACTION","ACTION_ZI_MO"),
	MO_PAI = pb.enum("CP_ACTION","ACTION_MO_PAI"),
	QIANG_GANG_HU = pb.enum("CP_ACTION","ACTION_QIANG_GANG_HU"),
	CLOSE = -1,
	RECONNECT = -2,
	VOTE = -4,
}

define.ACTION = ACTION

local TILE_TYPE = {
	WAN = 0,
	TONG = 1,
	TIAO = 2,
	ZI = 3,
	ZHONG_FA_BAI = 4,
	JIAN_KE = 5, --中发白
	FENG = 6,
}

define.TILE_TYPE = TILE_TYPE

local CP_SECTION_TYPE = {
	BA_GANG = pb.enum("CP_SECTION_TYPE","Gang"),
	PENG = pb.enum("CP_SECTION_TYPE","Peng"),
	TOU = pb.enum("CP_SECTION_TYPE","Tou"),
	CHI = pb.enum("CP_SECTION_TYPE","Chi"),	
	CHI_3 = pb.enum("CP_SECTION_TYPE","Chi3"),	
	SI_ZHANG = pb.enum("CP_SECTION_TYPE","Sizhang"),	
	TUO24 = pb.enum("CP_SECTION_TYPE","Tuo24"),	
}

define.SECTION_TYPE = CP_SECTION_TYPE

local TILE_AREA = {
	SHOU_TILE = 0,
	MING_TILE = 1,
}

define.TILE_AREA = TILE_AREA

function define.is_action_gang(action)
	return action &  ACTION.BA_GANG ~= 0
end

function define.is_action_chi(action)
	return action & (ACTION.LEFT_CHI | ACTION.MID_CHI | ACTION.RIGHT_CHI) ~= 0
end

function define.is_section_gang(st)
	return st == CP_SECTION_TYPE.AN_GANG or st == CP_SECTION_TYPE.MING_GANG or st == CP_SECTION_TYPE.BA_GANG
end

--状态机  状态
define.FSM_state = {
    PER_BEGIN       			= pb.enum("CP_FSM_STATE","PER_BEGIN"),	--预开始
	XI_PAI		    			= pb.enum("CP_FSM_STATE","XI_PAI"),    --洗牌 
	WAIT_MO_PAI  				= pb.enum("CP_FSM_STATE","WAIT_MO_PAI"),	--等待 摸牌
	WAIT_CHU_PAI  				= pb.enum("CP_FSM_STATE","WAIT_CHU_PAI"),	--等待 出牌
	WAIT_ACTION_AFTER_CHU_PAI	= pb.enum("CP_FSM_STATE","WAIT_ACTION_AFTER_CHU_PAI"),	--等待 碰 杠 胡, 用户出牌的时候
	WAIT_ACTION_AFTER_FIRSTFIRST_TOU_PAI  	= pb.enum("CP_FSM_STATE","WAIT_ACTION_AFTER_FIRSTFIRST_TOU_PAI"),	--等待偷牌
	WAIT_ACTION_AFTER_TIAN_HU = pb.enum("CP_FSM_STATE","WAIT_ACTION_AFTER_TIAN_HU"),	--等待天胡
	WAIT_ACTION_AFTER_JIN_PAI  	= pb.enum("CP_FSM_STATE","WAIT_ACTION_AFTER_JIN_PAI"),	--等待进牌
	WAIT_ACTION_AFTER_FAN_PAI  	= pb.enum("CP_FSM_STATE","WAIT_ACTION_AFTER_FAN_PAI"),	--等待 胡, 用户巴杠的时候，抢胡
	WAIT_QIANG_GANG_HU			= pb.enum("CP_FSM_STATE","WAIT_QIANG_GANG_HU"), --等待抢杠胡
	GAME_BALANCE				= pb.enum("CP_FSM_STATE","GAME_BALANCE"),	--结算
	GAME_CLOSE					= pb.enum("CP_FSM_STATE","GAME_CLOSE"),	--关闭游戏
	HUAN_PAI 					= pb.enum("CP_FSM_STATE","HUAN_PAI"),	--换牌
	TOU_PAI						= pb.enum("CP_FSM_STATE","TOU_PAI"),	--偷牌
	FAN_PAI						= pb.enum("CP_FSM_STATE","FAN_PAI"),	--翻牌
	DING_QUE 					= pb.enum("CP_FSM_STATE","DING_QUE"),	--定缺
	GAME_IDLE_HEAD				= pb.enum("CP_FSM_STATE","GAME_IDLE_HEAD"), --用于客户端播放动画延迟				
	FAST_START_VOTE 			= pb.enum("CP_FSM_STATE","FAST_START_VOTE"), --快速开始投票
	FINAL_END					= pb.enum("CP_FSM_STATE","FINAL_END")
}

local CP_HU_TYPE = {
	WEI_HU						= pb.enum("CP_HU_TYPE","WEI_HU"),	 --未胡
	PING_HU						= pb.enum("CP_HU_TYPE","PING_HU"),	 --平胡
	------------------------------叠加-------------------------------------------------
	TIAN_HU						= pb.enum("CP_HU_TYPE","TIAN_HU"),	--天胡
	DI_HU						= pb.enum("CP_HU_TYPE","DI_HU"),	--地胡
	TUOTUO_HONG					= pb.enum("CP_HU_TYPE","TUOTUO_HONG"),	--妥妥红
	BABA_HEI					= pb.enum("CP_HU_TYPE","BABA_HEI"),	--把把黑
	HEI_LONG					= pb.enum("CP_HU_TYPE","HEI_LONG"),	--黑龙
	SI_ZHANG					= pb.enum("CP_HU_TYPE","SI_ZHANG"),	--四张					
	CHONGFAN_PENG				= pb.enum("CP_HU_TYPE","CHONGFAN_PENG"),	--冲番碰
	CHONGFAN_TOU				= pb.enum("CP_HU_TYPE","CHONGFAN_TOU"),	 --冲番偷
	CHONGFAN_CHI_3				= pb.enum("CP_HU_TYPE","CHONGFAN_CHI_3"),--冲番吃三张
	TUO_24						= pb.enum("CP_HU_TYPE","TUO_24"),--达到24坨 	
}

define.CP_HU_TYPE = CP_HU_TYPE

local HU_TYPE_INFO = {
	[CP_HU_TYPE.WEI_HU]				= {name = "WEI_HU",score = 0,fan = 0},				--未胡
	[CP_HU_TYPE.PING_HU]			= {name = "PING_HU",score = 0,fan = 0},			--平胡
	[CP_HU_TYPE.TIAN_HU]			= {name = "TIAN_HU",score = 0,fan = 3},			--天胡
	[CP_HU_TYPE.DI_HU]				= {name = "DI_HU",score = 0,fan = 1},				--地胡
	[CP_HU_TYPE.TUOTUO_HONG]		= {name = "TUOTUO_HONG",score = 0,fan =3},				--妥妥红
	[CP_HU_TYPE.BABA_HEI]			= {name = "BABA_HEI",score = 0,fan = 3},			--把把黑
	[CP_HU_TYPE.HEI_LONG]			= {name = "HEI_LONG",score = 0,fan = 1},			--黑龙
	[CP_HU_TYPE.SI_ZHANG]			= {name = "SI_ZHANG",score = 0,fan = 1},			--四张
	[CP_HU_TYPE.CHONGFAN_PENG]		= {name = "CHONGFAN_PENG",score = 0,fan = 1},		--冲番牌碰
	[CP_HU_TYPE.CHONGFAN_TOU]		= {name = "CHONGFAN_TOU",score = 0,fan = 1},		--冲番牌偷
	[CP_HU_TYPE.CHONGFAN_CHI_3]		= {name = "CHONGFAN_CHI_3",score = 0,fan = 1},		--冲番牌吃三张
	[CP_HU_TYPE.TUO_24]				= {name = "TUO_24",score = 0,fan = 1},				--达到24坨
}

define.HU_TYPE_INFO = HU_TYPE_INFO


local UNIQUE_HU_TYPE = {
	
}


define.UNIQUE_HU_TYPE = UNIQUE_HU_TYPE

define.ACTION_TIME_OUT			= 15 	-- 10秒

return define