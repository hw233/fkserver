local define = {}

--输入事件
define.FSM_event = {
    UPDATE          = 0,	--time update
	TRUSTEE			= 1,	--托管
	CHI				= 2,	--吃
	PENG  			= 3,	--碰  
	GANG  			= 4,	--杠
	HU	  			= 5,	--胡
	PASS  			= 6,	--过
	CHU_PAI			= 7,	--出牌
	JIA_BEI			= 8,	--加倍
}

define.ACTION = {
	TRUSTEE = 0x1,
	PENG = 0x2,
	AN_GANG = 0x4,
	MING_GANG = 0x8,
	BA_GANG = 0x10,
	HU = 0x20,
	PASS = 0x40,
	LEFT_CHI = 0x80,
	MID_CHI = 0x100,
	RIGHT_CHI = 0x200,
	JIA_BEI = 0x800,
}

function define.is_action_gang(action)
	return action & (0x4 | 0x8 | 0x10) ~= 0
end

function define.is_action_chi(action)
	return action & (0x80 | 0x100 | 0x200) ~= 0
end

--状态机  状态
define.FSM_state = {
    PER_BEGIN       		= 0,	--预开始
    XI_PAI		    		= 1,    --洗牌 
	BU_HUA_BIG				= 2,	--补花
	WAIT_MO_PAI  			= 4,	--等待 摸牌
	WAIT_CHU_PAI  			= 5,	--等待 出牌
	WAIT_PENG_GANG_HU_CHI	= 6,	--等待 碰 杠 胡, 用户出牌的时候
	WAIT_BA_GANG_HU  		= 7,	--等待 胡, 用户巴杠的时候，抢胡

	GAME_BALANCE			= 15,	--结算
	GAME_CLOSE				= 16,	--关闭游戏
	GAME_ERR				= 17,	--发生错误

	GAME_IDLE_HEAD			= 0x1000, --用于客户端播放动画延迟				
}

local HU_TYPE = {
	WEI_HU					= 0,				--未胡
	------------------------------叠加-------------------------------------------------
	TIAN_HU					= 1,				--天胡
	DI_HU					= 2,				--地胡
	REN_HU					= 3,				--人胡
	TIAN_TING				= 4,			--天听
	QING_YI_SE				= 5,			--清一色
	QUAN_HUA				= 6,				--全花
	ZI_YI_SE				= 7,				--字一色
	MIAO_SHOU_HUI_CHUN		= 8,	--妙手回春
	HAI_DI_LAO_YUE			= 9,		--海底捞月
	GANG_SHANG_HUA			= 10,		--杠上开花
	QUAN_QIU_REN			= 11,			--全求人
	SHUANG_AN_GANG			= 12,		--双暗杠
	SHUANG_JIAN_KE			= 13,		--双箭刻
	HUN_YI_SE				= 14,				--混一色
	BU_QIU_REN				= 15,			--不求人
	SHUANG_MING_GANG		= 16,		--双明杠
	HU_JUE_ZHANG			= 17,			--胡绝张
	JIAN_KE					= 18,				--箭刻
	MEN_QING				= 19,				--门前清
	ZI_AN_GANG				= 20,			--自暗杠
	DUAN_YAO				= 21,				--断幺
	SI_GUI_YI				= 22,				--四归一
	PING_HU					= 23,				--平胡
	SHUANG_AN_KE			= 24,			--双暗刻
	SAN_AN_KE				= 25,			--三暗刻
	SI_AN_KE				= 26,				--四暗刻
	BAO_TING				= 27,				--报听
	MEN_FENG_KE				= 28,			--门风刻
	QUAN_FENG_KE			= 29,			--圈风刻
	ZI_MO					= 30,					--自摸
	DAN_DIAO_JIANG			= 31,		--单钓将
	YI_BAN_GAO	 			= 32,			--一般高
	LAO_SHAO_FU	 			= 33,			--老少副
	LIAN_LIU	 			= 34,				--连六
	YAO_JIU_KE	 			= 35,			--幺九刻
	MING_GANG	 			= 36,				--明杠
	DA_SAN_FENG				= 37,			--大三风
	XIAO_SAN_FENG			= 38,		--小三风
	PENG_PENG_HU			= 39,			--碰碰胡
	SAN_GANG				= 40,				--三杠
	QUAN_DAI_YAO			= 41,			--全带幺
	QIANG_GANG_HU			= 42,			--抢杠胡
	HUA_PAI					= 43,				--花牌
	-----------------------------------------------------------------------------------
	DA_QI_XIN				= 44,			--大七星
	LIAN_QI_DUI 			= 45,			--连七对
	SAN_YUAN_QI_DUI			= 46,		--三元七对子
	SI_XI_QI_DUI			= 47,			--四喜七对子
	NORMAL_QI_DUI 			= 48,		--普通七对
	---------------------
	DA_YU_WU 				= 49,				--大于五
	XIAO_YU_WU 				= 50,			--小于五
	DA_SI_XI				= 51,				--大四喜
	XIAO_SI_XI				= 52,			--小四喜
	DA_SAN_YUAN				= 53,			--大三元
	XIAO_SAN_YUAN			= 54,		--小三元
	JIU_LIAN_BAO_DENG		= 55,	--九莲宝灯
	LUO_HAN_18				= 56,			--18罗汉
	SHUANG_LONG_HUI			= 57,		--一色双龙会
	YI_SE_SI_TONG_SHUN		= 58,	--一色四同顺
	YI_SE_SI_JIE_GAO		= 59,		--一色四节高
	YI_SE_SI_BU_GAO			= 60,		--一色四步高
	HUN_YAO_JIU				= 61,			--混幺九
	YI_SE_SAN_JIE_GAO		= 62,	--一色三节高
	YI_SE_SAN_TONG_SHUN		= 63,	--一色三同顺
	SI_ZI_KE				= 64,				--四字刻
	QING_LONG				= 65,			--清龙
	YI_SE_SAN_BU_GAO		= 66,		--一色三步高
}

define.HU_TYPE = HU_TYPE

local HU_TYPE_INFO = {
	[HU_TYPE.WEI_HU]				= {name = "WEI_HU",fan = 0},				--未胡
	------------------------------叠加-------------------------------------------------
	[HU_TYPE.TIAN_HU]				= {name = "TIAN_HU",fan = 88},				--天胡
	[HU_TYPE.DI_HU]					= {name = "DI_HU",fan = 88},				--地胡
	[HU_TYPE.REN_HU]				= {name = "REN_HU",fan = 64},				--人胡
	[HU_TYPE.TIAN_TING]				= {name = "TIAN_TING",fan = 32},			--天听
	[HU_TYPE.QING_YI_SE]			= {name = "QING_YI_SE",fan = 16},			--清一色
	[HU_TYPE.QUAN_HUA]				= {name = "QUAN_HUA",fan = 16},				--全花
	[HU_TYPE.ZI_YI_SE]				= {name = "ZI_YI_SE",fan = 64},				--字一色
	[HU_TYPE.MIAO_SHOU_HUI_CHUN]	= {name = "MIAO_SHOU_HUI_CHUN",fan = 8},	--妙手回春
	[HU_TYPE.HAI_DI_LAO_YUE]		= {name = "HAI_DI_LAO_YUE",fan = 8},		--海底捞月
	[HU_TYPE.GANG_SHANG_HUA]		= {name = "GANG_SHANG_HUA",fan = 8},		--杠上开花
	[HU_TYPE.QUAN_QIU_REN]			= {name = "QUAN_QIU_REN",fan = 8},			--全求人
	[HU_TYPE.SHUANG_AN_GANG]		= {name = "SHUANG_AN_GANG",fan = 6},		--双暗杠
	[HU_TYPE.SHUANG_JIAN_KE]		= {name = "SHUANG_JIAN_KE",fan = 6},		--双箭刻
	[HU_TYPE.HUN_YI_SE]				= {name = "HUN_YI_SE",fan = 6},				--混一色
	[HU_TYPE.BU_QIU_REN]			= {name = "BU_QIU_REN",fan = 4},			--不求人
	[HU_TYPE.SHUANG_MING_GANG]		= {name = "SHUANG_MING_GANG",fan = 4},		--双明杠
	[HU_TYPE.HU_JUE_ZHANG]			= {name = "HU_JUE_ZHANG",fan = 4},			--胡绝张
	[HU_TYPE.JIAN_KE]				= {name = "JIAN_KE",fan = 2},				--箭刻
	[HU_TYPE.MEN_QING]				= {name = "MEN_QING",fan = 2},				--门前清
	[HU_TYPE.ZI_AN_GANG]			= {name = "ZI_AN_GANG",fan = 2},			--自暗杠
	[HU_TYPE.DUAN_YAO]				= {name = "DUAN_YAO",fan = 2},				--断幺
	[HU_TYPE.SI_GUI_YI]				= {name = "SI_GUI_YI",fan = 2},				--四归一
	[HU_TYPE.PING_HU]				= {name = "PING_HU",fan = 2},				--平胡
	[HU_TYPE.SHUANG_AN_KE]			= {name = "SHUANG_AN_KE",fan = 2},			--双暗刻
	[HU_TYPE.SAN_AN_KE]				= {name = "SAN_AN_KE",fan = 16},			--三暗刻
	[HU_TYPE.SI_AN_KE]				= {name = "SI_AN_KE",fan = 64},				--四暗刻
	[HU_TYPE.BAO_TING]				= {name = "BAO_TING",fan = 2},				--报听
	[HU_TYPE.MEN_FENG_KE]			= {name = "MEN_FENG_KE",fan = 2},			--门风刻
	[HU_TYPE.QUAN_FENG_KE]			= {name = "QUAN_FENG_KE",fan = 2},			--圈风刻
	[HU_TYPE.ZI_MO]					= {name = "ZI_MO",fan = 1},					--自摸
	[HU_TYPE.DAN_DIAO_JIANG]		= {name = "DAN_DIAO_JIANG",fan = 1},		--单钓将
	[HU_TYPE.YI_BAN_GAO]	 		= {name = "YI_BAN_GAO",fan = 1},			--一般高
	[HU_TYPE.LAO_SHAO_FU]	 		= {name = "LAO_SHAO_FU",fan = 1},			--老少副
	[HU_TYPE.LIAN_LIU]	 			= {name = "LIAN_LIU",fan = 1},				--连六
	[HU_TYPE.YAO_JIU_KE]	 		= {name = "YAO_JIU_KE",fan = 1},			--幺九刻
	[HU_TYPE.MING_GANG]	 			= {name = "MING_GANG",fan = 1},				--明杠
	[HU_TYPE.DA_SAN_FENG]			= {name = "DA_SAN_FENG",fan = 24},			--大三风
	[HU_TYPE.XIAO_SAN_FENG]			= {name = "XIAO_SAN_FENG",fan = 24},		--小三风
	[HU_TYPE.PENG_PENG_HU]			= {name = "PENG_PENG_HU",fan = 6},			--碰碰胡
	[HU_TYPE.SAN_GANG]				= {name = "SAN_GANG",fan = 32},				--三杠
	[HU_TYPE.QUAN_DAI_YAO]			= {name = "QUAN_DAI_YAO",fan = 4},			--全带幺
	[HU_TYPE.QIANG_GANG_HU]			= {name = "QIANG_GANG_HU",fan = 8},			--抢杠胡
	[HU_TYPE.HUA_PAI]				= {name = "HUA_PAI",fan = 1},				--花牌
	-----------------------------------------------------------------------------------
	[HU_TYPE.DA_QI_XIN]				= {name = "DA_QI_XIN",fan = 88},			--大七星
	[HU_TYPE.LIAN_QI_DUI] 			= {name = "LIAN_QI_DUI",fan = 88},			--连七对
	[HU_TYPE.SAN_YUAN_QI_DUI]		= {name = "SAN_YUAN_QI_DUI",fan = 48},		--三元七对子
	[HU_TYPE.SI_XI_QI_DUI]			= {name = "SI_XI_QI_DUI",fan = 48},			--四喜七对子
	[HU_TYPE.NORMAL_QI_DUI] 		= {name = "NORMAL_QI_DUI",fan = 24},		--普通七对
	---------------------
	[HU_TYPE.DA_YU_WU] 				= {name = "DA_YU_WU",fan = 88},				--大于五
	[HU_TYPE.XIAO_YU_WU] 			= {name = "XIAO_YU_WU",fan = 88},			--小于五
	[HU_TYPE.DA_SI_XI]				= {name = "DA_SI_XI",fan = 88},				--大四喜
	[HU_TYPE.XIAO_SI_XI]			= {name = "XIAO_SI_XI",fan = 64},			--小四喜
	[HU_TYPE.DA_SAN_YUAN]			= {name = "DA_SAN_YUAN",fan = 88},			--大三元
	[HU_TYPE.XIAO_SAN_YUAN]			= {name = "XIAO_SAN_YUAN",fan = 64},		--小三元
	[HU_TYPE.JIU_LIAN_BAO_DENG]		= {name = "JIU_LIAN_BAO_DENG",fan = 88},	--九莲宝灯
	[HU_TYPE.LUO_HAN_18]			= {name = "LUO_HAN_18",fan = 88},			--18罗汉
	[HU_TYPE.SHUANG_LONG_HUI]		= {name = "SHUANG_LONG_HUI",fan = 64},		--一色双龙会
	[HU_TYPE.YI_SE_SI_TONG_SHUN]	= {name = "YI_SE_SI_TONG_SHUN",fan = 48},	--一色四同顺
	[HU_TYPE.YI_SE_SI_JIE_GAO]		= {name = "YI_SE_SI_JIE_GAO",fan = 48},		--一色四节高
	[HU_TYPE.YI_SE_SI_BU_GAO]		= {name = "YI_SE_SI_BU_GAO",fan = 32},		--一色四步高
	[HU_TYPE.HUN_YAO_JIU]			= {name = "HUN_YAO_JIU",fan = 32},			--混幺九
	[HU_TYPE.YI_SE_SAN_JIE_GAO]		= {name = "YI_SE_SAN_JIE_GAO",fan = 24},	--一色三节高
	[HU_TYPE.YI_SE_SAN_TONG_SHUN]	= {name = "YI_SE_SAN_TONG_SHUN",fan = 24},	--一色三同顺
	[HU_TYPE.SI_ZI_KE]				= {name = "SI_ZI_KE",fan = 24},				--四字刻
	[HU_TYPE.QING_LONG]				= {name = "QING_LONG",fan = 16},			--清龙
	[HU_TYPE.YI_SE_SAN_BU_GAO]		= {name = "YI_SE_SAN_BU_GAO",fan = 16},		--一色三步高
}

define.CARD_HU_TYPE_INFO = HU_TYPE_INFO


local FAN_UNIQUE_MAP = {
	--大四喜----圈风刻,门风刻,大三风,小三风,碰碰胡
	[HU_TYPE.DA_SI_XI] 				= {HU_TYPE.QUAN_FENG_KE,HU_TYPE.MEN_FENG_KE,HU_TYPE.DA_SAN_FENG,HU_TYPE.XIAO_SAN_FENG,HU_TYPE.PENG_PENG_HU},
	--大三元----双箭刻,箭刻
	[HU_TYPE.DA_SAN_YUAN]			= {HU_TYPE.SHUANG_JIAN_KE,HU_TYPE.JIAN_KE},
	--九莲宝灯----清一色		
	[HU_TYPE.JIU_LIAN_BAO_DENG]		= {HU_TYPE.QING_YI_SE},	
	--18罗汉----三杠，双明杠，明杠，单钓将
	[HU_TYPE.LUO_HAN_18]			= {HU_TYPE.SAN_GANG,HU_TYPE.SHUANG_MING_GANG,HU_TYPE.MING_GANG,HU_TYPE.DAN_DIAO_JIANG},	
	--连7对----清一色、单钓，门前清，自摸。
	[HU_TYPE.LIAN_QI_DUI]			= {HU_TYPE.QING_YI_SE,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.MEN_QING,HU_TYPE.ZI_MO},	
	--大七星--全带幺，单钓将，门前清，自摸，字一色
	[HU_TYPE.DA_QI_XIN]				= {HU_TYPE.QUAN_DAI_YAO,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.MING_GANG,HU_TYPE.ZI_MO,HU_TYPE.ZI_YI_SE},	
	--天胡--单钓将，不求人，自摸。
	[HU_TYPE.TIAN_HU]				= {HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.BU_QIU_REN,HU_TYPE.ZI_MO},
	--小四喜 不计大三风，小三风，圈风刻，门风刻。
	[HU_TYPE.XIAO_SI_XI]			= {HU_TYPE.DA_SAN_FENG,HU_TYPE.XIAO_SAN_FENG,HU_TYPE.QUAN_FENG_KE,HU_TYPE.MEN_FENG_KE},
	--小三元	不计双箭刻，箭刻
	[HU_TYPE.XIAO_SAN_YUAN]			= {HU_TYPE.SHUANG_JIAN_KE,HU_TYPE.JIAN_KE},
	--字一色 不计碰碰和。
	[HU_TYPE.ZI_YI_SE]				= {HU_TYPE.PENG_PENG_HU},
	--四暗刻	不计三暗刻，双暗刻，门前清，碰碰和，自摸
	[HU_TYPE.SI_AN_KE] 				= {HU_TYPE.SAN_AN_KE,HU_TYPE.SHUANG_AN_KE,HU_TYPE.MING_GANG,HU_TYPE.PENG_PENG_HU,HU_TYPE.ZI_MO},
	--一色双龙会 不计平和，清一色，一般高
	[HU_TYPE.SHUANG_LONG_HUI]		= {HU_TYPE.PING_HU,HU_TYPE.QING_YI_SE,HU_TYPE.YI_BAN_GAO},
	--一色四同顺 不计一色三节高、一色三同顺，四归一，一般高
	[HU_TYPE.YI_SE_SI_TONG_SHUN]	= {HU_TYPE.YI_SE_SAN_JIE_GAO,HU_TYPE.YI_SE_SAN_TONG_SHUN,HU_TYPE.SI_GUI_YI,HU_TYPE.YI_BAN_GAO},
	--一色四节高 不计一色三同顺，一色三节高，碰碰和，一般高
	[HU_TYPE.YI_SE_SI_JIE_GAO]		= {HU_TYPE.YI_SE_SAN_TONG_SHUN,HU_TYPE.YI_SE_SAN_JIE_GAO,HU_TYPE.PENG_PENG_HU,HU_TYPE.YI_BAN_GAO},
	--三元七对子 不计门前清，单钓将，自摸。
	[HU_TYPE.SAN_YUAN_QI_DUI]		= {HU_TYPE.MEN_QING,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.ZI_MO},
	--四喜七对子 不计 门前清，单调将，自摸。
	[HU_TYPE.SI_XI_QI_DUI]			= {HU_TYPE.MEN_QING,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.ZI_MO},
	--一色四步高 不计三步高，连六，老少副
	[HU_TYPE.YI_SE_SI_BU_GAO]		= {HU_TYPE.YI_SE_SAN_BU_GAO,HU_TYPE.LIAN_LIU,HU_TYPE.LAO_SHAO_FU},
	--三杠  不计双明刚，明杠
	[HU_TYPE.SAN_GANG]				= {HU_TYPE.SHUANG_MING_GANG,HU_TYPE.MING_GANG},
	--混幺九 不计碰碰和。全带幺。
	[HU_TYPE.HUN_YAO_JIU]			= {HU_TYPE.PENG_PENG_HU,HU_TYPE.QUAN_DAI_YAO},
	--七对 不计不求人，门前清，单钓将，自摸。
	[HU_TYPE.NORMAL_QI_DUI]			= {HU_TYPE.BU_QIU_REN,HU_TYPE.MEN_QING,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.ZI_MO},
	--一色三节高 不计一色三同顺，一般高。
	[HU_TYPE.YI_SE_SAN_JIE_GAO]		= {HU_TYPE.YI_SE_SAN_TONG_SHUN,HU_TYPE.YI_BAN_GAO},
	--一色三同顺 不计一色三节高，一般高。
	[HU_TYPE.YI_SE_SAN_TONG_SHUN]	= {HU_TYPE.YI_SE_SAN_JIE_GAO,HU_TYPE.YI_BAN_GAO},
	--四字刻 	不计碰碰胡。
	[HU_TYPE.SI_ZI_KE]				= {HU_TYPE.PENG_PENG_HU},
	--大三风 	不计小三风
	[HU_TYPE.DA_SAN_FENG]			= {HU_TYPE.XIAO_SAN_FENG},
	--清龙 不计连六，老少副。
	[HU_TYPE.QING_LONG]				= {HU_TYPE.LIAN_LIU,HU_TYPE.LAO_SHAO_FU},
	--三暗刻 不计双暗刻
	[HU_TYPE.SAN_AN_KE]				= {HU_TYPE.SHUANG_AN_KE},
	--妙手回春 不计自摸
	[HU_TYPE.MIAO_SHOU_HUI_CHUN]	= {HU_TYPE.ZI_MO},
	--杠上开花 	不计自摸。
	[HU_TYPE.GANG_SHANG_HUA]		= {HU_TYPE.ZI_MO},
	--抢杠胡 不计胡绝张
	[HU_TYPE.QIANG_GANG_HU]			= {HU_TYPE.HU_JUE_ZHANG},
	--全求人 不计单钓
	[HU_TYPE.QUAN_QIU_REN]			= {HU_TYPE.DAN_DIAO_JIANG},
	--双暗杠 	不计双暗刻，暗杠。
	[HU_TYPE.SHUANG_AN_GANG]		= {HU_TYPE.SHUANG_AN_KE,HU_TYPE.AN_GANG},
	--双箭刻 	不计双暗刻，暗杠
	[HU_TYPE.SHUANG_JIAN_KE]		= {HU_TYPE.SHUANG_AN_KE,HU_TYPE.AN_GANG},
}


define.FAN_UNIQUE_MAP = FAN_UNIQUE_MAP

define.ACTION_TIME_OUT			= 15 	-- 10秒

return define