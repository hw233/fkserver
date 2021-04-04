local pb = require "pb_files"

local define = {}

define.ACTION = {
	TRUSTEE = pb.enum("ACTION","ACTION_TRUSTEE"),
	PENG = pb.enum("ACTION","ACTION_PENG"),
	AN_GANG = pb.enum("ACTION","ACTION_AN_GANG"),
	MING_GANG = pb.enum("ACTION","ACTION_MING_GANG"),
	BA_GANG = pb.enum("ACTION","ACTION_BA_GANG"),
	HU = pb.enum("ACTION","ACTION_HU"),
	PASS = pb.enum("ACTION","ACTION_PASS"),
	LEFT_CHI = pb.enum("ACTION","ACTION_LEFT_CHI"),
	MID_CHI = pb.enum("ACTION","ACTION_MID_CHI"),
	RIGHT_CHI = pb.enum("ACTION","ACTION_RIGHT_CHI"),
	TING = pb.enum("ACTION","ACTION_TING"),
	JIA_BEI = pb.enum("ACTION","ACTION_JIA_BEI"),
	CHU_PAI = pb.enum("ACTION","ACTION_CHU_PAI"),
	MEN = pb.enum("ACTION","ACTION_MEN"),
	ZI_MO = pb.enum("ACTION","ACTION_ZI_MO"),
	MO_PAI = pb.enum("ACTION","ACTION_MO_PAI"),
	MEN_ZI_MO = pb.enum("ACTION","ACTION_MEN_ZI_MO"),
	FREE_BA_GANG = pb.enum("ACTION","ACTION_FREE_BA_GANG"),
	FREE_AN_GANG = pb.enum("ACTION","ACTION_FREE_AN_GANG"),
	DING_QUE = pb.enum("ACTION","ACTION_DING_QUE"),
	HUAN_PAI = pb.enum("ACTION","ACTION_HUAN_PAI"),
	CLOSE = -1,
	RECONNECT = -2,
	VOTE = -4,
}

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

define.GANG_TYPE = {
	AN_GANG = 1,
	MING_GANG = 2,
	BA_GANG = 3
}

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
	WEI_HU						= pb.enum("HU_TYPE","WEI_HU"),	 --未胡
	------------------------------叠加-------------------------------------------------
	TIAN_HU						= pb.enum("HU_TYPE","TIAN_HU"),	--天胡
	DI_HU						= pb.enum("HU_TYPE","DI_HU"),	--地胡
	REN_HU						= pb.enum("HU_TYPE","REN_HU"),	--人胡
	TIAN_TING					= pb.enum("HU_TYPE","TIAN_TING"),	--天听
	QING_YI_SE					= pb.enum("HU_TYPE","QING_YI_SE"),	--清一色
	QUAN_HUA					= pb.enum("HU_TYPE","QUAN_HUA"),	--全花
	ZI_YI_SE					= pb.enum("HU_TYPE","ZI_YI_SE"),	--字一色
	MIAO_SHOU_HUI_CHUN			= pb.enum("HU_TYPE","MIAO_SHOU_HUI_CHUN"),	--妙手回春
	HAI_DI_LAO_YUE				= pb.enum("HU_TYPE","HAI_DI_LAO_YUE"),	--海底捞月
	GANG_SHANG_HUA				= pb.enum("HU_TYPE","GANG_SHANG_HUA"),	--杠上开花
	QUAN_QIU_REN				= pb.enum("HU_TYPE","QUAN_QIU_REN"),	--全求人
	SHUANG_AN_GANG				= pb.enum("HU_TYPE","SHUANG_AN_GANG"),	--双暗杠
	SHUANG_JIAN_KE				= pb.enum("HU_TYPE","SHUANG_JIAN_KE"),	--双箭刻
	HUN_YI_SE					= pb.enum("HU_TYPE","HUN_YI_SE"),	--混一色
	BU_QIU_REN					= pb.enum("HU_TYPE","BU_QIU_REN"),	--不求人
	SHUANG_MING_GANG			= pb.enum("HU_TYPE","SHUANG_MING_GANG"),	--双明杠
	HU_JUE_ZHANG				= pb.enum("HU_TYPE","HU_JUE_ZHANG"),	--胡绝张
	JIAN_KE						= pb.enum("HU_TYPE","JIAN_KE"),	--箭刻
	MEN_QING					= pb.enum("HU_TYPE","MEN_QING"),	--门前清
	AN_GANG						= pb.enum("HU_TYPE","AN_GANG"),	--暗杠
	DUAN_YAO					= pb.enum("HU_TYPE","DUAN_YAO"),	--断幺
	SI_GUI_YI					= pb.enum("HU_TYPE","SI_GUI_YI"),	--四归一
	PING_HU						= pb.enum("HU_TYPE","PING_HU"),	--平胡
	SHUANG_AN_KE				= pb.enum("HU_TYPE","SHUANG_AN_KE"),	--双暗刻
	SAN_AN_KE					= pb.enum("HU_TYPE","SAN_AN_KE"),	--三暗刻
	SI_AN_KE					= pb.enum("HU_TYPE","SI_AN_KE"),	--四暗刻
	BAO_TING					= pb.enum("HU_TYPE","BAO_TING"),	--报听
	MEN_FENG_KE					= pb.enum("HU_TYPE","MEN_FENG_KE"),	--门风刻
	QUAN_FENG_KE				= pb.enum("HU_TYPE","QUAN_FENG_KE"),	--圈风刻
	ZI_MO						= pb.enum("HU_TYPE","ZI_MO"),	--自摸
	DAN_DIAO_JIANG				= pb.enum("HU_TYPE","DAN_DIAO_JIANG"),	--单钓将
	YI_BAN_GAO					= pb.enum("HU_TYPE","YI_BAN_GAO"),	--一般高
	LAO_SHAO_FU					= pb.enum("HU_TYPE","LAO_SHAO_FU"),	--老少副
	LIAN_LIU					= pb.enum("HU_TYPE","LIAN_LIU"),	--连六
	YAO_JIU_KE					= pb.enum("HU_TYPE","YAO_JIU_KE"),	--幺九刻
	MING_GANG					= pb.enum("HU_TYPE","MING_GANG"),	--明杠
	DA_SAN_FENG					= pb.enum("HU_TYPE","DA_SAN_FENG"),	--大三风
	XIAO_SAN_FENG				= pb.enum("HU_TYPE","XIAO_SAN_FENG"),	--小三风
	PENG_PENG_HU				= pb.enum("HU_TYPE","PENG_PENG_HU"),	--碰碰胡
	SAN_GANG					= pb.enum("HU_TYPE","SAN_GANG"),	--三杠
	QUAN_DAI_YAO				= pb.enum("HU_TYPE","QUAN_DAI_YAO"),	--全带幺
	QIANG_GANG_HU				= pb.enum("HU_TYPE","QIANG_GANG_HU"),	--抢杠胡
	HUA_PAI						= pb.enum("HU_TYPE","HUA_PAI"),	--花牌
	DA_QI_XIN					= pb.enum("HU_TYPE","DA_QI_XIN"),	--大七星
	LIAN_QI_DUI					= pb.enum("HU_TYPE","LIAN_QI_DUI"),	--连七对
	SAN_YUAN_QI_DUI				= pb.enum("HU_TYPE","SAN_YUAN_QI_DUI"),	--三元七对子
	SI_XI_QI_DUI				= pb.enum("HU_TYPE","SI_XI_QI_DUI"),	--四喜七对子
	QI_DUI						= pb.enum("HU_TYPE","QI_DUI"),	--普通七对
	DA_YU_WU					= pb.enum("HU_TYPE","DA_YU_WU"),	--大于五
	XIAO_YU_WU					= pb.enum("HU_TYPE","XIAO_YU_WU"),	--小于五
	DA_SI_XI					= pb.enum("HU_TYPE","DA_SI_XI"),	--大四喜
	XIAO_SI_XI					= pb.enum("HU_TYPE","XIAO_SI_XI"),	--小四喜
	DA_SAN_YUAN					= pb.enum("HU_TYPE","DA_SAN_YUAN"),	--大三元
	XIAO_SAN_YUAN				= pb.enum("HU_TYPE","XIAO_SAN_YUAN"),	--小三元
	JIU_LIAN_BAO_DENG			= pb.enum("HU_TYPE","JIU_LIAN_BAO_DENG"),	--九莲宝灯
	LUO_HAN_18					= pb.enum("HU_TYPE","LUO_HAN_18"),	--18罗汉
	SHUANG_LONG_HUI				= pb.enum("HU_TYPE","SHUANG_LONG_HUI"),	--一色双龙会
	YI_SE_SI_TONG_SHUN			= pb.enum("HU_TYPE","YI_SE_SI_TONG_SHUN"),	--一色四同顺
	YI_SE_SI_JIE_GAO			= pb.enum("HU_TYPE","YI_SE_SI_JIE_GAO"),	--一色四节高
	YI_SE_SI_BU_GAO				= pb.enum("HU_TYPE","YI_SE_SI_BU_GAO"),	--一色四步高
	HUN_YAO_JIU					= pb.enum("HU_TYPE","HUN_YAO_JIU"),	--混幺九
	YI_SE_SAN_JIE_GAO			= pb.enum("HU_TYPE","YI_SE_SAN_JIE_GAO"),	--一色三节高
	YI_SE_SAN_TONG_SHUN			= pb.enum("HU_TYPE","YI_SE_SAN_TONG_SHUN"),	--一色三同顺
	SI_ZI_KE					= pb.enum("HU_TYPE","SI_ZI_KE"),	--四字刻
	QING_LONG					= pb.enum("HU_TYPE","QING_LONG"),	--清龙
	YI_SE_SAN_BU_GAO			= pb.enum("HU_TYPE","YI_SE_SAN_BU_GAO"),	--一色三步高
	DA_DUI_ZI					= pb.enum("HU_TYPE","DA_DUI_ZI"),	--大对子
	LONG_QI_DUI					= pb.enum("HU_TYPE","LONG_QI_DUI"),	--龙七对
	QING_QI_DUI					= pb.enum("HU_TYPE","QING_QI_DUI"),	--清七对
	QING_LONG_BEI				= pb.enum("HU_TYPE","QING_LONG_BEI"),	--清龙背
	QING_DA_DUI					= pb.enum("HU_TYPE","QING_DA_DUI"),	--清大对
	QING_DAN_DIAO				= pb.enum("HU_TYPE","QING_DAN_DIAO"),	--清单吊
	BA_GANG 					= pb.enum("HU_TYPE","BA_GANG"),	--把杠
	NORMAL_JI 					= pb.enum("HU_TYPE","NORMAL_JI"),	--鸡牌
	FAN_PAI_JI 					= pb.enum("HU_TYPE","FAN_PAI_JI"),	--翻牌鸡
	CHONG_FENG_JI 				= pb.enum("HU_TYPE","CHONG_FENG_JI"),	--冲锋鸡
	ZHE_REN_JI 					= pb.enum("HU_TYPE","ZHE_REN_JI"),	--责任鸡
	WU_GU_JI 					= pb.enum("HU_TYPE","WU_GU_JI"),	--乌骨鸡
	YAO_BAI_JI 					= pb.enum("HU_TYPE","YAO_BAI_JI"),	--摇摆鸡
	BEN_JI 						= pb.enum("HU_TYPE","BEN_JI"),	--本鸡
	XING_QI_JI 					= pb.enum("HU_TYPE","XING_QI_JI"),	--星期鸡
	CHUI_FENG_JI 				= pb.enum("HU_TYPE","CHUI_FENG_JI"),	--吹风鸡
	JIAO_PAI 					= pb.enum("HU_TYPE","JIAO_PAI"),	--叫牌
	WEI_JIAO 					= pb.enum("HU_TYPE","WEI_JIAO"),	--查叫
	MEN							= pb.enum("HU_TYPE","MEN"), 	--闷
	MEN_ZI_MO					= pb.enum("HU_TYPE","MEN_ZI_MO"), --自摸闷
	DIAN_PAO 					= pb.enum("HU_TYPE","DIAN_PAO"), --点炮
	LIAN_ZHUANG					= pb.enum("HU_TYPE","LIAN_ZHUANG"), --连庄
	ZHUANG						= pb.enum("HU_TYPE","ZHUANG"), --庄
	YING_BAO					= pb.enum("HU_TYPE","YING_BAO"), --硬报
	RUAN_BAO					= pb.enum("HU_TYPE","RUAN_BAO"), --软报
	SHA_BAO						= pb.enum("HU_TYPE","SHA_BAO"),	--杀报
	HONG_ZHONG					= pb.enum("HU_TYPE","HONG_ZHONG"), --红中
	CHONG_FENG_WU_GU 			= pb.enum("HU_TYPE","CHONG_FENG_WU_GU"), --冲锋乌骨鸡
	ZHE_REN_WU_GU 				= pb.enum("HU_TYPE","ZHE_REN_WU_GU"), --责任乌骨鸡
	JING_JI						= pb.enum("HU_TYPE","JING_JI"),	--金鸡
	JING_WU_GU_JI				= pb.enum("HU_TYPE","JING_WU_GU_JI"),--金乌骨鸡
	CHONG_FENG_JING_JI			= pb.enum("HU_TYPE","CHONG_FENG_JING_JI"), --冲锋金鸡
	CHONG_FENG_JING_WU_GU		= pb.enum("HU_TYPE","CHONG_FENG_JING_WU_GU"),--冲锋金乌骨
	ZHE_REN_JING_JI				= pb.enum("HU_TYPE","ZHE_REN_JING_JI"), --责任金鸡
	ZHE_REN_JING_WU_GU			= pb.enum("HU_TYPE","ZHE_REN_JING_WU_GU"),--责任金乌骨鸡
	GANG_SHANG_PAO				= pb.enum("HU_TYPE","GANG_SHANG_PAO"),--杠上炮
	JIANG_DUI 					= pb.enum("HU_TYPE","JIANG_DUI"),--将对
	JIANG_QI_DUI				= pb.enum("HU_TYPE","JIANG_QI_DUI"),--将七对
	QUAN_YAO_JIU				= pb.enum("HU_TYPE","QUAN_YAO_JIU"),--全幺九
	DAI_GOU						= pb.enum("HU_TYPE","DAI_GOU"),	--带勾
	KA_WU_XING					= pb.enum("HU_TYPE","KA_WU_XING"), --卡五星
	ZHONG_ZHANG					= pb.enum("HU_TYPE","ZHONG_ZHANG"), --中张
	KA_ER_TIAO					= pb.enum("HU_TYPE","KA_ER_TIAO"), --卡二条
	SI_DUI 						= pb.enum("HU_TYPE","SI_DUI"), --7张牌四对(当作12张七对)
	LONG_SI_DUI 				= pb.enum("HU_TYPE","LONG_SI_DUI"),	--龙四对
	QING_SI_DUI 				= pb.enum("HU_TYPE","QING_SI_DUI"), --清四对
	QING_LONG_SI_DUI 			= pb.enum("HU_TYPE","QING_LONG_SI_DUI"), --清龙四对
}

define.FAN_UNIQUE_MAP	 = {
	--大四喜----圈风刻,门风刻,大三风,小三风,碰碰胡
	DA_SI_XI 			= {HU_TYPE.QUAN_FENG_KE,HU_TYPE.MEN_FENG_KE,HU_TYPE.DA_SAN_FENG,HU_TYPE.XIAO_SAN_FENG,HU_TYPE.PENG_PENG_HU},
	--大三元----双箭刻,箭刻
	DA_SAN_YUAN			= {HU_TYPE.SHUANG_JIAN_KE,HU_TYPE.JIAN_KE},	
	--九莲宝灯----清一色		
	JIU_LIAN_BAO_DENG	= {HU_TYPE.QING_YI_SE},	
	--18罗汉----三杠，双明杠，明杠，单钓将
	LUO_HAN_18			= {HU_TYPE.SAN_GANG,HU_TYPE.SHUANG_MING_GANG,HU_TYPE.MING_GANG,HU_TYPE.DAN_DIAO_JIANG},	
	--连7对----清一色、单钓，门前清，自摸。
	LIAN_QI_DUI			= {HU_TYPE.QING_YI_SE,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.MEN_QING,HU_TYPE.ZI_MO},	
	--大七星--全带幺，单钓将，门前清，自摸，字一色
	DA_QI_XIN			= {HU_TYPE.QUAN_DAI_YAO,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.MING_GANG,HU_TYPE.ZI_MO,HU_TYPE.ZI_YI_SE},	
	--天胡--单钓将，不求人，自摸。
	TIAN_HU				= {HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.BU_QIU_REN,HU_TYPE.ZI_MO},
	--小四喜 不计大三风，小三风，圈风刻，门风刻。
	XIAO_SI_XI			= {HU_TYPE.DA_SAN_FENG,HU_TYPE.XIAO_SAN_FENG,HU_TYPE.QUAN_FENG_KE,HU_TYPE.MEN_FENG_KE},
	--小三元	不计双箭刻，箭刻
	XIAO_SAN_YUAN		= {HU_TYPE.SHUANG_JIAN_KE,HU_TYPE.JIAN_KE},
	--字一色 不计碰碰和。
	ZI_YI_SE			= {HU_TYPE.PENG_PENG_HU},
	--四暗刻	不计三暗刻，双暗刻，门前清，碰碰和，自摸
	SI_AN_KE 			= {HU_TYPE.SAN_AN_KE,HU_TYPE.SHUANG_AN_KE,HU_TYPE.MING_GANG,HU_TYPE.PENG_PENG_HU,HU_TYPE.ZI_MO},
	--一色双龙会 不计平和，清一色，一般高
	SHUANG_LONG_HUI		= {HU_TYPE.PING_HU,HU_TYPE.QING_YI_SE,HU_TYPE.YI_BAN_GAO},
	--一色四同顺 不计一色三节高、一色三同顺，四归一，一般高
	YI_SE_SI_TONG_SHUN	= {HU_TYPE.YI_SE_SAN_JIE_GAO,HU_TYPE.YI_SE_SAN_TONG_SHUN,HU_TYPE.SI_GUI_YI,HU_TYPE.YI_BAN_GAO},
	--一色四节高 不计一色三同顺，一色三节高，碰碰和，一般高
	YI_SE_SI_JIE_GAO	= {HU_TYPE.YI_SE_SAN_TONG_SHUN,HU_TYPE.YI_SE_SAN_JIE_GAO,HU_TYPE.PENG_PENG_HU,HU_TYPE.YI_BAN_GAO},
	--三元七对子 不计门前清，单钓将，自摸。
	SAN_YUAN_QI_DUI		= {HU_TYPE.MEN_QING,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.ZI_MO},
	--四喜七对子 不计 门前清，单调将，自摸。
	SI_XI_QI_DUI		= {HU_TYPE.MEN_QING,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.ZI_MO},
	--一色四步高 不计三步高，连六，老少副
	YI_SE_SI_BU_GAO		= {HU_TYPE.YI_SE_SAN_BU_GAO,HU_TYPE.LIAN_LIU,HU_TYPE.LAO_SHAO_FU},
	--三杠  不计双明刚，明杠
	SAN_GANG			= {HU_TYPE.SHUANG_MING_GANG,HU_TYPE.MING_GANG},
	--混幺九 不计碰碰和。全带幺。
	HUN_YAO_JIU			= {HU_TYPE.PENG_PENG_HU,HU_TYPE.QUAN_DAI_YAO},
	--七对 不计不求人，门前清，单钓将，自摸。
	NORMAL_QI_DUI		= {HU_TYPE.BU_QIU_REN,HU_TYPE.MEN_QING,HU_TYPE.DAN_DIAO_JIANG,HU_TYPE.ZI_MO},
	--一色三节高 不计一色三同顺，一般高。
	YI_SE_SAN_JIE_GAO	= {HU_TYPE.YI_SE_SAN_TONG_SHUN,HU_TYPE.YI_BAN_GAO},
	--一色三同顺 不计一色三节高，一般高。
	YI_SE_SAN_TONG_SHUN	= {HU_TYPE.YI_SE_SAN_JIE_GAO,HU_TYPE.YI_BAN_GAO},
	--四字刻 	不计碰碰胡。
	SI_ZI_KE			= {HU_TYPE.PENG_PENG_HU},
	--大三风 	不计小三风
	DA_SAN_FENG			= {HU_TYPE.XIAO_SAN_FENG},
	--清龙 不计连六，老少副。
	QING_LONG			= {HU_TYPE.LIAN_LIU,HU_TYPE.LAO_SHAO_FU},
	--三暗刻 不计双暗刻
	SAN_AN_KE			= {HU_TYPE.SHUANG_AN_KE},
	--妙手回春 不计自摸
	MIAO_SHOU_HUI_CHUN	= {HU_TYPE.ZI_MO},
	--杠上开花 	不计自摸。
	GANG_SHANG_HUA		= {HU_TYPE.ZI_MO},
	--抢杠胡 不计胡绝张
	QIANG_GANG_HU		= {HU_TYPE.HU_JUE_ZHANG},
	--全求人 不计单钓
	QUAN_QIU_REN		= {HU_TYPE.DAN_DIAO_JIANG},
	--双暗杠 	不计双暗刻，暗杠。
	SHUANG_AN_GANG		= {HU_TYPE.SHUANG_AN_KE,HU_TYPE.AN_GANG},
	--双箭刻 	不计双暗刻，暗杠
	SHUANG_JIAN_KE		= {HU_TYPE.SHUANG_AN_KE,HU_TYPE.AN_GANG},
} 
define.CARD_HU_TYPE_INFO = {
	WEI_HU					= {name = "WEI_HU",fan = 0},				--未胡
------------------------------叠加-------------------------------------------------
	TIAN_HU					= {name = "TIAN_HU",fan = 88},				--天胡
	DI_HU					= {name = "DI_HU",fan = 88},				--地胡
	REN_HU					= {name = "REN_HU",fan = 64},				--人胡
	TIAN_TING				= {name = "TIAN_TING",fan = 32},			--天听
	QING_YI_SE				= {name = "QING_YI_SE",fan = 16},			--清一色
	QUAN_HUA				= {name = "QUAN_HUA",fan = 16},				--全花
	ZI_YI_SE				= {name = "ZI_YI_SE",fan = 64},				--字一色
	MIAO_SHOU_HUI_CHUN		= {name = "MIAO_SHOU_HUI_CHUN",fan = 8},	--妙手回春
	HAI_DI_LAO_YUE			= {name = "HAI_DI_LAO_YUE",fan = 8},		--海底捞月
	GANG_SHANG_HUA			= {name = "GANG_SHANG_HUA",fan = 8},		--杠上开花
	QUAN_QIU_REN			= {name = "QUAN_QIU_REN",fan = 8},			--全求人
	SHUANG_AN_GANG			= {name = "SHUANG_AN_GANG",fan = 6},		--双暗杠
	SHUANG_JIAN_KE			= {name = "SHUANG_JIAN_KE",fan = 6},		--双箭刻
	HUN_YI_SE				= {name = "HUN_YI_SE",fan = 6},				--混一色
	BU_QIU_REN				= {name = "BU_QIU_REN",fan = 4},			--不求人
	SHUANG_MING_GANG		= {name = "SHUANG_MING_GANG",fan = 4},		--双明杠
	HU_JUE_ZHANG			= {name = "HU_JUE_ZHANG",fan = 4},			--胡绝张
	JIAN_KE					= {name = "JIAN_KE",fan = 2},				--箭刻
	MEN_QING				= {name = "MEN_QING",fan = 2},				--门前清
	ZI_AN_GANG				= {name = "ZI_AN_GANG",fan = 2},			--自暗杠
	DUAN_YAO				= {name = "DUAN_YAO",fan = 2},				--断幺
	SI_GUI_YI				= {name = "SI_GUI_YI",fan = 2},				--四归一
	PING_HU					= {name = "PING_HU",fan = 2},				--平胡
	SHUANG_AN_KE			= {name = "SHUANG_AN_KE",fan = 2},			--双暗刻
	SAN_AN_KE				= {name = "SAN_AN_KE",fan = 16},			--三暗刻
	SI_AN_KE				= {name = "SI_AN_KE",fan = 64},				--四暗刻
	BAO_TING				= {name = "BAO_TING",fan = 2},				--报听
	MEN_FENG_KE				= {name = "MEN_FENG_KE",fan = 2},			--门风刻
	QUAN_FENG_KE			= {name = "QUAN_FENG_KE",fan = 2},			--圈风刻
	ZI_MO					= {name = "ZI_MO",fan = 1},					--自摸
	DAN_DIAO_JIANG			= {name = "DAN_DIAO_JIANG",fan = 1},		--单钓将
	YI_BAN_GAO	 			= {name = "YI_BAN_GAO",fan = 1},			--一般高
	LAO_SHAO_FU	 			= {name = "LAO_SHAO_FU",fan = 1},			--老少副
	LIAN_LIU	 			= {name = "LIAN_LIU",fan = 1},				--连六
	YAO_JIU_KE	 			= {name = "YAO_JIU_KE",fan = 1},			--幺九刻
	MING_GANG	 			= {name = "MING_GANG",fan = 1},				--明杠
	DA_SAN_FENG				= {name = "DA_SAN_FENG",fan = 24},			--大三风
	XIAO_SAN_FENG			= {name = "XIAO_SAN_FENG",fan = 24},		--小三风
	PENG_PENG_HU			= {name = "PENG_PENG_HU",fan = 6},			--碰碰胡
	SAN_GANG				= {name = "SAN_GANG",fan = 32},				--三杠
	QUAN_DAI_YAO			= {name = "QUAN_DAI_YAO",fan = 4},			--全带幺
	QIANG_GANG_HU			= {name = "QIANG_GANG_HU",fan = 8},			--抢杠胡
	HUA_PAI					= {name = "HUA_PAI",fan = 1},				--花牌
-----------------------------------------------------------------------------------
	DA_QI_XIN			= {name = "DA_QI_XIN",fan = 88},			--大七星
	LIAN_QI_DUI 		= {name = "LIAN_QI_DUI",fan = 88},			--连七对
	SAN_YUAN_QI_DUI		= {name = "SAN_YUAN_QI_DUI",fan = 48},		--三元七对子
	SI_XI_QI_DUI		= {name = "SI_XI_QI_DUI",fan = 48},			--四喜七对子
	NORMAL_QI_DUI 		= {name = "NORMAL_QI_DUI",fan = 24},		--普通七对
---------------------
	DA_YU_WU 			= {name = "DA_YU_WU",fan = 88},				--大于五
	XIAO_YU_WU 			= {name = "XIAO_YU_WU",fan = 88},			--小于五
	DA_SI_XI			= {name = "DA_SI_XI",fan = 88},				--大四喜
	XIAO_SI_XI			= {name = "XIAO_SI_XI",fan = 64},			--小四喜
	DA_SAN_YUAN			= {name = "DA_SAN_YUAN",fan = 88},			--大三元
	XIAO_SAN_YUAN		= {name = "XIAO_SAN_YUAN",fan = 64},		--小三元
	JIU_LIAN_BAO_DENG	= {name = "JIU_LIAN_BAO_DENG",fan = 88},	--九莲宝灯
	LUO_HAN_18			= {name = "LUO_HAN_18",fan = 88},			--18罗汉
	SHUANG_LONG_HUI		= {name = "SHUANG_LONG_HUI",fan = 64},		--一色双龙会
	YI_SE_SI_TONG_SHUN	= {name = "YI_SE_SI_TONG_SHUN",fan = 48},	--一色四同顺
	YI_SE_SI_JIE_GAO	= {name = "YI_SE_SI_JIE_GAO",fan = 48},		--一色四节高
	YI_SE_SI_BU_GAO		= {name = "YI_SE_SI_BU_GAO",fan = 32},		--一色四步高
	HUN_YAO_JIU			= {name = "HUN_YAO_JIU",fan = 32},			--混幺九
	YI_SE_SAN_JIE_GAO	= {name = "YI_SE_SAN_JIE_GAO",fan = 24},	--一色三节高
	YI_SE_SAN_TONG_SHUN	= {name = "YI_SE_SAN_TONG_SHUN",fan = 24},	--一色三同顺
	SI_ZI_KE			= {name = "SI_ZI_KE",fan = 24},				--四字刻
	QING_LONG			= {name = "QING_LONG",fan = 16},			--清龙
	YI_SE_SAN_BU_GAO	= {name = "YI_SE_SAN_BU_GAO",fan = 16},		--一色三步高
}

define.ACTION_TIME_OUT			= 15 	-- 10秒

return define