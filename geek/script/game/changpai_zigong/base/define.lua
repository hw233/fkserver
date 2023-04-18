local define = {}

local pb = require "pb_files"

local TIME_TYPE = {
	MAIN_FAN_PAI = 0.5,
	MAIN_XI_PAI = 3,
}
define.TIME_TYPE= TIME_TYPE
local ACTION = {
	TRUSTEE = 0x1,
	PENG = 0x2,
	TOU = 0x4,
	BA_GANG = 0x10,
	HU = 0x20,
	PASS = 0x40,
	CHI = 0x80,
	TING = 0x400,
	TIAN_HU = 0x800,
	CHU_PAI = 0x1000,
	ZI_MO = 0x2000,
	MO_PAI = 0x8000,
	TUO = 0x20000,
	QIANG_GANG_HU = 0x200000,
	FAN_PAI = 0x600000,
	ROUND = 0x800000,
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
	WAIT_BAO_TING 				= pb.enum("CP_FSM_STATE","WAIT_BAO_TING"), 	--报听
	
	FINAL_END					= pb.enum("CP_FSM_STATE","FINAL_END")
}

local CP_HU_TYPE = {
	WEI_HU						= 0,	 --未胡
	PING_HU						= 1,	 --平胡
	------------------------------叠加-------------------------------------------------
	TIAN_HU						= 2,	--天胡
	DI_HU						= 3,	--地胡
	TUOTUO_HONG					= 4,	--妥妥红
	BABA_HEI					= 5,	--把把黑
	HEI_LONG					= 6,	--黑龙
	SI_ZHANG					= 7,	--四张					
	CHONGFAN_PENG				= 8,	--冲番碰
	CHONGFAN_TOU				= 9,	 --冲番偷
	CHONGFAN_CHI_3				= 10,--冲番吃三张
	TUO_24						= 11,--达到24坨 	
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