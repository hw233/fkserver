local define = {}

local pb = require "pb_files"

local ACTION = {
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
	QIANG_GANG_HU = pb.enum("ACTION","ACTION_QIANG_GANG_HU"),
	GANG_HUAN_PAI = pb.enum("ACTION","ACTION_GANG_HUAN_PAI"),
	RUAN_AN_GANG = pb.enum("ACTION","ACTION_RUAN_AN_GANG"),
	RUAN_MING_GANG = pb.enum("ACTION","ACTION_RUAN_MING_GANG"),
	RUAN_BA_GANG = pb.enum("ACTION","ACTION_RUAN_BA_GANG"),
	RUAN_PENG = pb.enum("ACTION","ACTION_RUAN_PENG"),
	PIAO_FEN = pb.enum("ACTION","ACTION_PIAO_FEN"),
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

local SECTION_TYPE = {
	FOUR = pb.enum("SECTION_TYPE","Four"),
	AN_GANG = pb.enum("SECTION_TYPE","AnGang"),
	MING_GANG = pb.enum("SECTION_TYPE","MingGang"),
	BA_GANG = pb.enum("SECTION_TYPE","BaGang"),
	DUIZI = pb.enum("SECTION_TYPE","DuiZi"),
	THREE = pb.enum("SECTION_TYPE","Three"),
	PENG = pb.enum("SECTION_TYPE","Peng"),
	CHI = pb.enum("SECTION_TYPE","Chi"),
	LEFT_CHI = pb.enum("SECTION_TYPE","LeftChi"),
	MID_CHI = pb.enum("SECTION_TYPE","MidChi"),
	RIGHT_CHI = pb.enum("SECTION_TYPE","RightChi"),
	RUAN_AN_GANG = pb.enum("SECTION_TYPE","RuanAnGang"),
	RUAN_MING_GANG = pb.enum("SECTION_TYPE","RuanMingGang"),
	RUAN_BA_GANG = pb.enum("SECTION_TYPE","RuanBaGang"),
	RUAN_PENG = pb.enum("SECTION_TYPE","RuanPeng"),


}

define.SECTION_TYPE = SECTION_TYPE

local TILE_AREA = {
	SHOU_TILE = 0,
	MING_TILE = 1,
}

define.TILE_AREA = TILE_AREA

function define.is_action_gang(action)
	return action & (ACTION.AN_GANG | ACTION.MING_GANG | ACTION.BA_GANG | ACTION.FREE_BA_GANG | ACTION.FREE_AN_GANG | ACTION.RUAN_MING_GANG |ACTION.RUAN_BA_GANG |ACTION.RUAN_AN_GANG ) ~= 0
end

function define.is_action_chi(action)
	return action & (ACTION.LEFT_CHI | ACTION.MID_CHI | ACTION.RIGHT_CHI) ~= 0
end

function define.is_section_gang(st)
	return st == SECTION_TYPE.AN_GANG or st == SECTION_TYPE.MING_GANG or st == SECTION_TYPE.BA_GANG
end

--状态机  状态
define.FSM_state = {
    PER_BEGIN       			= pb.enum("FSM_STATE","PER_BEGIN"),	--预开始
	XI_PAI		    			= pb.enum("FSM_STATE","XI_PAI"),    --洗牌 
	CHECK_TING 					= pb.enum("FSM_STATE","CHECK_TING"),	--天听
	WAIT_MO_PAI  				= pb.enum("FSM_STATE","WAIT_MO_PAI"),	--等待 摸牌
	WAIT_CHU_PAI  				= pb.enum("FSM_STATE","WAIT_CHU_PAI"),	--等待 出牌
	WAIT_ACTION_AFTER_CHU_PAI	= pb.enum("FSM_STATE","WAIT_ACTION_AFTER_CHU_PAI"),	--等待 碰 杠 胡, 用户出牌的时候
	WAIT_ACTION_AFTER_MO_PAI  	= pb.enum("FSM_STATE","WAIT_ACTION_AFTER_MO_PAI"),	--等待 胡, 用户巴杠的时候，抢胡
	WAIT_QIANG_GANG_HU			= pb.enum("FSM_STATE","WAIT_QIANG_GANG_HU"), --等待抢杠胡
	GAME_BALANCE				= pb.enum("FSM_STATE","GAME_BALANCE"),	--结算
	GAME_CLOSE					= pb.enum("FSM_STATE","GAME_CLOSE"),	--关闭游戏
	PIAO_FEN 					= pb.enum("FSM_STATE","PIAO_FEN"),	--飘分
	GAME_IDLE_HEAD				= pb.enum("FSM_STATE","GAME_IDLE_HEAD"), --用于客户端播放动画延迟				
	FAST_START_VOTE 			= pb.enum("FSM_STATE","FAST_START_VOTE"), --快速开始投票
	FINAL_END					= pb.enum("FSM_STATE","FINAL_END")
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
	KA_ER_TIAO					= pb.enum("HU_TYPE","KA_ER_TIAO"), --卡二条
	SI_DUI 						= pb.enum("HU_TYPE","SI_DUI"), --7张牌四对(当作12张七对)
	LONG_SI_DUI 				= pb.enum("HU_TYPE","LONG_SI_DUI"),	--龙四对
	QING_SI_DUI 				= pb.enum("HU_TYPE","QING_SI_DUI"), --清四对
	QING_LONG_SI_DUI 			= pb.enum("HU_TYPE","QING_LONG_SI_DUI"), --清龙四对
	WU_JI 						= pb.enum("HU_TYPE","WU_JI"), --无鸡
	SI_JI 						= pb.enum("HU_TYPE","SI_JI"), --四鸡
	RUAN_AN_GANG 			    = pb.enum("HU_TYPE","RUAN_AN_GANG"), --软暗杠
	RUAN_MING_GANG 				= pb.enum("HU_TYPE","RUAN_MING_GANG"), --软明杠
	RUAN_BA_GANG 				= pb.enum("HU_TYPE","RUAN_BA_GANG"), --软巴杠

}

define.HU_TYPE = HU_TYPE

local HU_TYPE_INFO = {
	[HU_TYPE.WEI_HU]				= {name = "WEI_HU",score = 0,fan = 0},				--未胡
	[HU_TYPE.TIAN_HU]				= {name = "TIAN_HU",score = 0,fan = 1},				--天胡
	[HU_TYPE.DI_HU]					= {name = "DI_HU",score = 0,fan = 0},				--地胡
	[HU_TYPE.REN_HU]				= {name = "REN_HU",score = 0,fan = 0},				--人胡
	[HU_TYPE.TIAN_TING]				= {name = "TIAN_TING",score = 0,fan = 0},			--天听
	[HU_TYPE.QING_YI_SE]			= {name = "QING_YI_SE",score = 0,fan = 1},			--清一色
	[HU_TYPE.QUAN_HUA]				= {name = "QUAN_HUA",score = 0,fan = 0},				--全花
	[HU_TYPE.ZI_YI_SE]				= {name = "ZI_YI_SE",score = 0,fan = 0},				--字一色
	[HU_TYPE.MIAO_SHOU_HUI_CHUN]	= {name = "MIAO_SHOU_HUI_CHUN",score = 0,fan = 0},	--妙手回春
	[HU_TYPE.HAI_DI_LAO_YUE]		= {name = "HAI_DI_LAO_YUE",score = 0,fan = 0},		--海底捞月
	[HU_TYPE.GANG_SHANG_HUA]		= {name = "GANG_SHANG_HUA",score = 0,fan = 0},		--杠上开花
	[HU_TYPE.QUAN_QIU_REN]			= {name = "QUAN_QIU_REN",score = 0,fan = 0},			--全求人
	[HU_TYPE.SHUANG_AN_GANG]		= {name = "SHUANG_AN_GANG",score = 0,fan = 0},		--双暗杠
	[HU_TYPE.SHUANG_JIAN_KE]		= {name = "SHUANG_JIAN_KE",score = 0,fan = 0},		--双箭刻
	[HU_TYPE.HUN_YI_SE]				= {name = "HUN_YI_SE",score = 0,fan = 0},				--混一色
	[HU_TYPE.BU_QIU_REN]			= {name = "BU_QIU_REN",score = 0,fan = 0},			--不求人
	[HU_TYPE.SHUANG_MING_GANG]		= {name = "SHUANG_MING_GANG",score = 0,fan = 0},		--双明杠
	[HU_TYPE.HU_JUE_ZHANG]			= {name = "HU_JUE_ZHANG",score = 0,fan = 0},			--胡绝张
	[HU_TYPE.JIAN_KE]				= {name = "JIAN_KE",score = 0,fan = 0},				--箭刻
	[HU_TYPE.MEN_QING]				= {name = "MEN_QING",score = 0,fan = 0},				--门前清
	[HU_TYPE.AN_GANG]				= {name = "AN_GANG",score = 2,fan = 1},				--暗杠
	[HU_TYPE.DUAN_YAO]				= {name = "DUAN_YAO",score = 0,fan = 0},				--断幺
	[HU_TYPE.SI_GUI_YI]				= {name = "SI_GUI_YI",score = 0,fan = 0},				--四归一
	[HU_TYPE.PING_HU]				= {name = "PING_HU",score = 0,fan = 2},				--平胡
	[HU_TYPE.SHUANG_AN_KE]			= {name = "SHUANG_AN_KE",score = 0,fan = 0},			--双暗刻
	[HU_TYPE.SAN_AN_KE]				= {name = "SAN_AN_KE",score = 0,fan = 0},			--三暗刻
	[HU_TYPE.SI_AN_KE]				= {name = "SI_AN_KE",score = 0,fan = 0},				--四暗刻
	[HU_TYPE.BAO_TING]				= {name = "BAO_TING",score = 0,fan = 0},				--报听
	[HU_TYPE.MEN_FENG_KE]			= {name = "MEN_FENG_KE",score = 0,fan = 0},			--门风刻
	[HU_TYPE.QUAN_FENG_KE]			= {name = "QUAN_FENG_KE",score = 0,fan = 0},			--圈风刻
	[HU_TYPE.ZI_MO]					= {name = "ZI_MO",score = 0,fan = 1},				--自摸
	[HU_TYPE.DAN_DIAO_JIANG]		= {name = "DAN_DIAO_JIANG",score = 0,fan = 0},		--单钓将
	[HU_TYPE.YI_BAN_GAO]	 		= {name = "YI_BAN_GAO",score = 0,fan = 0},			--一般高
	[HU_TYPE.LAO_SHAO_FU]	 		= {name = "LAO_SHAO_FU",score = 0,fan = 0},			--老少副
	[HU_TYPE.LIAN_LIU]	 			= {name = "LIAN_LIU",score = 0,fan = 0},				--连六
	[HU_TYPE.YAO_JIU_KE]	 		= {name = "YAO_JIU_KE",score = 0,fan = 0},			--幺九刻
	[HU_TYPE.MING_GANG]	 			= {name = "MING_GANG",score = 1,fan = 1},				--明杠
	[HU_TYPE.DA_SAN_FENG]			= {name = "DA_SAN_FENG",score = 0,fan = 0},			--大三风
	[HU_TYPE.XIAO_SAN_FENG]			= {name = "XIAO_SAN_FENG",score = 0,fan = 0},		--小三风
	[HU_TYPE.PENG_PENG_HU]			= {name = "PENG_PENG_HU",score = 0,fan = 1},			--碰碰胡
	[HU_TYPE.SAN_GANG]				= {name = "SAN_GANG",score = 0,fan = 0},				--三杠
	[HU_TYPE.QUAN_DAI_YAO]			= {name = "QUAN_DAI_YAO",score = 0,fan = 0},			--全带幺
	[HU_TYPE.QIANG_GANG_HU]			= {name = "QIANG_GANG_HU",score = 0,fan = 1},			--抢杠胡
	[HU_TYPE.HUA_PAI]				= {name = "HUA_PAI",score = 0,fan = 0},				--花牌
	[HU_TYPE.DA_QI_XIN]				= {name = "DA_QI_XIN",score = 0,fan = 0},			--大七星
	[HU_TYPE.LIAN_QI_DUI] 			= {name = "LIAN_QI_DUI",score = 0,fan = 0},			--连七对
	[HU_TYPE.SAN_YUAN_QI_DUI]		= {name = "SAN_YUAN_QI_DUI",score = 0,fan = 0},		--三元七对子
	[HU_TYPE.SI_XI_QI_DUI]			= {name = "SI_XI_QI_DUI",score = 0,fan = 0},			--四喜七对子
	[HU_TYPE.QI_DUI] 				= {name = "QI_DUI",score = 0,fan = 1},				--普通七对
	[HU_TYPE.DA_YU_WU] 				= {name = "DA_YU_WU",score = 0,fan = 0},				--大于五
	[HU_TYPE.XIAO_YU_WU] 			= {name = "XIAO_YU_WU",score = 0,fan = 0},			--小于五
	[HU_TYPE.DA_SI_XI]				= {name = "DA_SI_XI",score = 0,fan = 0},				--大四喜
	[HU_TYPE.XIAO_SI_XI]			= {name = "XIAO_SI_XI",score = 0,fan = 0},			--小四喜
	[HU_TYPE.DA_SAN_YUAN]			= {name = "DA_SAN_YUAN",score = 0,fan = 0},			--大三元
	[HU_TYPE.XIAO_SAN_YUAN]			= {name = "XIAO_SAN_YUAN",score = 0,fan = 0},		--小三元
	[HU_TYPE.JIU_LIAN_BAO_DENG]		= {name = "JIU_LIAN_BAO_DENG",score = 0,fan = 0},	--九莲宝灯
	[HU_TYPE.LUO_HAN_18]			= {name = "LUO_HAN_18",score = 0,fan = 0},			--18罗汉
	[HU_TYPE.SHUANG_LONG_HUI]		= {name = "SHUANG_LONG_HUI",score = 0,fan = 0},		--一色双龙会
	[HU_TYPE.YI_SE_SI_TONG_SHUN]	= {name = "YI_SE_SI_TONG_SHUN",score = 0,fan = 0},	--一色四同顺
	[HU_TYPE.YI_SE_SI_JIE_GAO]		= {name = "YI_SE_SI_JIE_GAO",score = 0,fan = 0},		--一色四节高
	[HU_TYPE.YI_SE_SI_BU_GAO]		= {name = "YI_SE_SI_BU_GAO",score = 0,fan = 0},		--一色四步高
	[HU_TYPE.HUN_YAO_JIU]			= {name = "HUN_YAO_JIU",score = 0,fan = 0},			--混幺九
	[HU_TYPE.YI_SE_SAN_JIE_GAO]		= {name = "YI_SE_SAN_JIE_GAO",score = 0,fan = 0},	--一色三节高
	[HU_TYPE.YI_SE_SAN_TONG_SHUN]	= {name = "YI_SE_SAN_TONG_SHUN",score = 0,fan = 0},	--一色三同顺
	[HU_TYPE.SI_ZI_KE]				= {name = "SI_ZI_KE",score = 0,fan = 0},				--四字刻
	[HU_TYPE.QING_LONG]				= {name = "QING_LONG",score = 0,fan = 0},			--清龙
	[HU_TYPE.YI_SE_SAN_BU_GAO]		= {name = "YI_SE_SAN_BU_GAO",score = 0,fan = 0},		--一色三步高
	[HU_TYPE.DA_DUI_ZI]  			= {name = "DA_DUI_ZI",score = 0,fan = 1},				--大对子
	[HU_TYPE.LONG_QI_DUI] 			= {name = "LONG_QI_DUI",score = 0,fan = 0},			--龙七对
	[HU_TYPE.QING_QI_DUI] 			= {name = "QING_QI_DUI",score = 0,fan = 0},			--清七对
	[HU_TYPE.QING_LONG_BEI] 		= {name = "QING_LONG_BEI",score = 0,fan = 0},		--清龙背
	[HU_TYPE.QING_DA_DUI] 			= {name = "QING_DA_DUI",score = 0,fan = 0},			--清大对
	[HU_TYPE.QING_DAN_DIAO]			= {name = "QING_DAN_DIAO",score = 0,fan = 0},		--清单吊
	[HU_TYPE.BA_GANG]				= {name = "BA_GANG",score = 1,fan = 0},				--把杠(补杠)

	[HU_TYPE.NORMAL_JI]				= {name = "NORMAL_JI",score = 0,fan = 0},				--鸡牌
	[HU_TYPE.WU_GU_JI]				= {name = "WU_GU_JI",score = 0,fan = 0},				--乌骨鸡
	[HU_TYPE.FAN_PAI_JI]			= {name = "FAN_PAI_JI",score = 0,fan = 0},				--翻牌鸡
	[HU_TYPE.CHUI_FENG_JI]			= {name = "CHUI_FENG_JI",score = 0,fan = 0},			--吹风鸡
	[HU_TYPE.ZHE_REN_JI]			= {name = "ZHE_REN_JI",score = 0,fan = 0},				--责任鸡
	[HU_TYPE.CHONG_FENG_JI]			= {name = "CHONG_FENG_JI",score = 0,fan = 0},				--冲锋鸡
	[HU_TYPE.XING_QI_JI]			= {name = "XING_QI_JI",score = 0,fan = 0},				--星期鸡
	[HU_TYPE.DIAN_PAO]				= {name = "DIAN_PAO",score = 0,fan = 1},				--点炮
	[HU_TYPE.WEI_JIAO]				= {name = "WEI_JIAO",score = 0,fan = 0},				--未叫牌
	[HU_TYPE.JIAO_PAI]				= {name = "JIAO_PAI",score = 0,fan = 0},				--叫牌
	[HU_TYPE.MEN]					= {name = "MEN",score = 0,fan = 0},						--闷
	[HU_TYPE.MEN_ZI_MO]				= {name = "MEN_ZI_MO",score = 0,fan = 0},				--自摸闷
	[HU_TYPE.LIAN_ZHUANG]			= {name = "LIAN_ZHUANG",score = 0,fan = 0},				--连庄
	[HU_TYPE.ZHUANG]				= {name = "ZHUANG",score = 0,fan = 0},				--庄家
	[HU_TYPE.YING_BAO]				= {name = "YING_BAO",score = 0,fan = 0},		--硬报
	[HU_TYPE.RUAN_BAO]				= {name = "RUAN_BAO",score = 0,fan = 0},		--软报
	[HU_TYPE.HONG_ZHONG]			= {name = "HONG_ZHONG",score = 0,fan = 0},		--红中
	[HU_TYPE.CHONG_FENG_WU_GU]		= {name = "CHONG_FENG_WU_GU",score = 0,fan = 0}, --冲锋乌骨鸡
	[HU_TYPE.ZHE_REN_WU_GU]			= {name = "ZHE_REN_WU_GU",score = 0,fan = 0}, --责任乌骨鸡
	[HU_TYPE.JING_JI]				= {name = "JING_JI",score = 0,fan = 0}, --金鸡
	[HU_TYPE.JING_WU_GU_JI]			= {name = "JING_WU_GU_JI",score = 0,fan = 0},	--金乌骨鸡
	[HU_TYPE.CHONG_FENG_JING_JI]	= {name = "CHONG_FENG_JING_JI",score = 0,fan = 0}, -- 冲锋金鸡
	[HU_TYPE.CHONG_FENG_JING_WU_GU]	= {name = "CHONG_FENG_JING_WU_GU",score = 0,fan = 0}, -- 冲锋金乌骨鸡
	[HU_TYPE.ZHE_REN_JING_JI]		= {name = "ZHE_REN_JING_JI",score = 0,fan = 0},	--责任金鸡
	[HU_TYPE.ZHE_REN_JING_WU_GU]	= {name = "ZHE_REN_JING_WU_GU",score = 0,fan = 0}, --责任金乌骨
	[HU_TYPE.GANG_SHANG_PAO]		= {name = "GANG_SHANG_PAO",score = 0,fan = 0}, --杠上炮
	[HU_TYPE.JIANG_DUI]				= {name = "JIANG_DUI",score = 0,fan = 0},	--将对
	[HU_TYPE.JIANG_QI_DUI]			= {name = "JIANG_QI_DUI",score = 0,fan = 0},	--将七对
	[HU_TYPE.QUAN_YAO_JIU]			= {name = "QUAN_YAO_JIU",score = 0,fan = 0},	--全幺九
	[HU_TYPE.DAI_GOU]				= {name = "DAI_GOU",score = 0,fan = 0},	--带根
	[HU_TYPE.KA_WU_XING]			= {name = "KA_WU_XING",score = 0,fan = 0}, --卡五星
	[HU_TYPE.KA_ER_TIAO]			= {name = "KA_ER_TIAO",score = 0,fan = 0}, --卡二条

	[HU_TYPE.SI_DUI]				= {name = "SI_DUI",score = 0,fan = 0}, --四对
	[HU_TYPE.QING_SI_DUI]			= {name = "QING_SI_DUI",score = 0,fan = 0}, --清四对
	[HU_TYPE.LONG_SI_DUI]			= {name = "LONG_SI_DUI",score = 0,fan = 0}, --龙四对
	[HU_TYPE.QING_LONG_SI_DUI]		= {name = "QING_LONG_SI_DUI",score = 0,fan = 0}, --龙四对

	[HU_TYPE.RUAN_AN_GANG]			= {name = "RUAN_AN_GANG",score = 0,fan = 0}, --软暗杠
	[HU_TYPE.RUAN_MING_GANG]		= {name = "RUAN_MING_GANG",score = 0,fan = 0}, --软明杠
	[HU_TYPE.RUAN_BA_GANG]			= {name = "RUAN_BA_GANG",score = 0,fan = 0}, --软吧杠
	[HU_TYPE.WU_JI]					= {name = "WU_JI",score = 0,fan = 2}, --无鸡(无红中)
	[HU_TYPE.SI_JI]					= {name = "SI_JI",score = 0,fan = 0}, --四鸡顶翻
}

define.HU_TYPE_INFO = HU_TYPE_INFO


local UNIQUE_HU_TYPE = {
	-- --大四喜----圈风刻,门风刻,大三风,小三风,碰碰胡
	-- [HU_TYPE.DA_SI_XI] 				= {[HU_TYPE.QUAN_FENG_KE] = true,[HU_TYPE.MEN_FENG_KE] = true,[HU_TYPE.DA_SAN_FENG] = true,[HU_TYPE.XIAO_SAN_FENG] = true,[HU_TYPE.PENG_PENG_HU] = true},
	-- --大三元----双箭刻,箭刻
	-- [HU_TYPE.DA_SAN_YUAN]			= {[HU_TYPE.SHUANG_JIAN_KE] = true,[HU_TYPE.JIAN_KE] = true},
	-- --九莲宝灯----清一色		
	-- [HU_TYPE.JIU_LIAN_BAO_DENG]		= {[HU_TYPE.QING_YI_SE] = true,},	
	-- --18罗汉----三杠，双明杠，明杠，单钓将
	-- [HU_TYPE.LUO_HAN_18]			= {[HU_TYPE.SAN_GANG] = true,[HU_TYPE.SHUANG_MING_GANG] = true,[HU_TYPE.MING_GANG] = true,[HU_TYPE.DAN_DIAO_JIANG] = true},	
	-- --连7对----清一色、单钓，门前清，自摸。
	-- [HU_TYPE.LIAN_QI_DUI]			= {[HU_TYPE.QING_YI_SE] = true,[HU_TYPE.DAN_DIAO_JIANG] = true,[HU_TYPE.MEN_QING] = true,[HU_TYPE.ZI_MO] = true},	
	-- --大七星--全带幺，单钓将，门前清，自摸，字一色
	-- [HU_TYPE.DA_QI_XIN]				= {[HU_TYPE.QUAN_DAI_YAO] = true,[HU_TYPE.DAN_DIAO_JIANG] = true,[HU_TYPE.MING_GANG] = true,[HU_TYPE.ZI_MO] = true,[HU_TYPE.ZI_YI_SE] = true},	
	-- --天胡--单钓将，不求人，自摸。
	-- [HU_TYPE.TIAN_HU]				= {[HU_TYPE.DAN_DIAO_JIANG] = true,[HU_TYPE.BU_QIU_REN] = true,[HU_TYPE.ZI_MO] = true},
	-- --小四喜 不计大三风，小三风，圈风刻，门风刻。
	-- [HU_TYPE.XIAO_SI_XI]			= {[HU_TYPE.DA_SAN_FENG] = true,[HU_TYPE.XIAO_SAN_FENG] = true,[HU_TYPE.QUAN_FENG_KE] = true,[HU_TYPE.MEN_FENG_KE] = true},
	-- --小三元	不计双箭刻，箭刻
	-- [HU_TYPE.XIAO_SAN_YUAN]			= {[HU_TYPE.SHUANG_JIAN_KE] = true,[HU_TYPE.JIAN_KE] = true},
	-- --字一色 不计碰碰和。
	-- [HU_TYPE.ZI_YI_SE]				= {[HU_TYPE.PENG_PENG_HU] = true},
	-- --四暗刻	不计三暗刻，双暗刻，门前清，碰碰和，自摸
	-- [HU_TYPE.SI_AN_KE] 				= {[HU_TYPE.SAN_AN_KE] = true,[HU_TYPE.SHUANG_AN_KE]=true,[HU_TYPE.MING_GANG] = true,[HU_TYPE.PENG_PENG_HU] = true,[HU_TYPE.ZI_MO] = true},
	-- --一色双龙会 不计平和，清一色，一般高
	-- [HU_TYPE.SHUANG_LONG_HUI]		= {[HU_TYPE.PING_HU] = true,[HU_TYPE.QING_YI_SE] = true,[HU_TYPE.YI_BAN_GAO] = true},
	-- --一色四同顺 不计一色三节高、一色三同顺，四归一，一般高
	-- [HU_TYPE.YI_SE_SI_TONG_SHUN]	= {[HU_TYPE.YI_SE_SAN_JIE_GAO] = true,[HU_TYPE.YI_SE_SAN_TONG_SHUN] = true,[HU_TYPE.SI_GUI_YI] = true,[HU_TYPE.YI_BAN_GAO] = true},
	-- --一色四节高 不计一色三同顺，一色三节高，碰碰和，一般高
	-- [HU_TYPE.YI_SE_SI_JIE_GAO]		= {[HU_TYPE.YI_SE_SAN_TONG_SHUN] = true,[HU_TYPE.YI_SE_SAN_JIE_GAO] = true,[HU_TYPE.PENG_PENG_HU] = true,[HU_TYPE.YI_BAN_GAO] = true},
	-- --三元七对子 不计门前清，单钓将，自摸。
	-- [HU_TYPE.SAN_YUAN_QI_DUI]		= {[HU_TYPE.MEN_QING] = true,[HU_TYPE.DAN_DIAO_JIANG] = true,[HU_TYPE.ZI_MO] = true},
	-- --四喜七对子 不计 门前清，单调将，自摸。
	-- [HU_TYPE.SI_XI_QI_DUI]			= {[HU_TYPE.MEN_QING] = true,[HU_TYPE.DAN_DIAO_JIANG] = true,[HU_TYPE.ZI_MO] = true},
	-- --一色四步高 不计三步高，连六，老少副
	-- [HU_TYPE.YI_SE_SI_BU_GAO]		= {[HU_TYPE.YI_SE_SAN_BU_GAO] = true,[HU_TYPE.LIAN_LIU] = true,[HU_TYPE.LAO_SHAO_FU] = true},
	-- --三杠  不计双明刚，明杠
	-- [HU_TYPE.SAN_GANG]				= {[HU_TYPE.SHUANG_MING_GANG] = true,[HU_TYPE.MING_GANG] = true},
	-- --混幺九 不计碰碰和。全带幺。
	-- [HU_TYPE.HUN_YAO_JIU]			= {[HU_TYPE.PENG_PENG_HU] = true,[HU_TYPE.QUAN_DAI_YAO] = true},
	-- --七对 不计不求人，门前清，单钓将，自摸。
	-- [HU_TYPE.QI_DUI]				= {[HU_TYPE.BU_QIU_REN] = true,[HU_TYPE.MEN_QING] = true,[HU_TYPE.DAN_DIAO_JIANG] = true,[HU_TYPE.ZI_MO] = true},
	-- --一色三节高 不计一色三同顺，一般高。
	-- [HU_TYPE.YI_SE_SAN_JIE_GAO]		= {[HU_TYPE.YI_SE_SAN_TONG_SHUN] = true,[HU_TYPE.YI_BAN_GAO] = true},
	-- --一色三同顺 不计一色三节高，一般高。
	-- [HU_TYPE.YI_SE_SAN_TONG_SHUN]	= {[HU_TYPE.YI_SE_SAN_JIE_GAO] = true,[HU_TYPE.YI_BAN_GAO] = true},
	-- --四字刻 	不计碰碰胡。
	-- [HU_TYPE.SI_ZI_KE]				= {[HU_TYPE.PENG_PENG_HU] = true},
	-- --大三风 	不计小三风
	-- [HU_TYPE.DA_SAN_FENG]			= {[HU_TYPE.XIAO_SAN_FENG] = true},
	-- --清龙 不计连六，老少副。
	-- [HU_TYPE.QING_LONG]				= {[HU_TYPE.LIAN_LIU] = true,[HU_TYPE.LAO_SHAO_FU] = true},
	-- --三暗刻 不计双暗刻
	-- [HU_TYPE.SAN_AN_KE]				= {[HU_TYPE.SHUANG_AN_KE] = true},
	-- --妙手回春 不计自摸
	-- [HU_TYPE.MIAO_SHOU_HUI_CHUN]	= {[HU_TYPE.ZI_MO] = true},
	-- --杠上开花 	不计自摸。
	-- [HU_TYPE.GANG_SHANG_HUA]		= {[HU_TYPE.ZI_MO] = true},
	-- --抢杠胡 不计胡绝张
	-- [HU_TYPE.QIANG_GANG_HU]			= {[HU_TYPE.HU_JUE_ZHANG] = true},
	-- --全求人 不计单钓
	-- [HU_TYPE.QUAN_QIU_REN]			= {[HU_TYPE.DAN_DIAO_JIANG] = true},
	-- --双暗杠 	不计双暗刻，暗杠。
	-- [HU_TYPE.SHUANG_AN_GANG]		= {[HU_TYPE.SHUANG_AN_KE] = true},
	-- --双箭刻 	不计双暗刻，暗杠
	-- [HU_TYPE.SHUANG_JIAN_KE]		= {[HU_TYPE.SHUANG_AN_KE] = true},

	[HU_TYPE.QING_QI_DUI]			= {[HU_TYPE.QI_DUI] = true,[HU_TYPE.QING_YI_SE]=true},
	[HU_TYPE.QING_LONG_BEI] 		= {[HU_TYPE.LONG_QI_DUI] = true,[HU_TYPE.QING_YI_SE] = true},
	[HU_TYPE.QING_DA_DUI]			= {[HU_TYPE.DA_DUI_ZI] = true,[HU_TYPE.QING_YI_SE]=true},
	[HU_TYPE.QING_SI_DUI]			= {[HU_TYPE.SI_DUI] = true,[HU_TYPE.QING_YI_SE]=true},
	[HU_TYPE.QING_LONG_SI_DUI] 		= {[HU_TYPE.LONG_SI_DUI] = true,[HU_TYPE.QING_YI_SE] = true},
}


define.UNIQUE_HU_TYPE = UNIQUE_HU_TYPE

define.ACTION_TIME_OUT			= 15 	-- 10秒

return define