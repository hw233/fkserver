local def = require "game.maajan_customized.base.define"
local log = require "log"
require "functions"

local ACTION = def.ACTION

local function table_count_value(array,map,map)
    local counts = {}
    
    local k1,v1
    table.foreach(array,function(k,v)
		k1,v1 = map(k,v)
		counts[k1] = counts[k1] or {}
		table.insert(counts[k1] ,v1)
    end)

    return counts
end

local function table_counts(array,max)
	local counts = {}
	if max then table.fill(counts,1,max,0) end
    table.mergeto(counts,array,function(l,_) return (l or 0) + 1 end)

    return counts
end

local rule 			= {}

function rule.tile_value(v)
	return v % 10
end

function rule.tile_men(v)
	return math.floor(v / 10)
end


local GANG_TYPE = def.GANG_TYPE

local TILE_TYPE = {
	WAN = 0,
	TONG = 1,
	TIAO = 2,
	ZI = 3,
	ZHONG_FA_BAI = 4,
	JIAN_KE = 5, --中发白
	FENG = 6,
}

local SECTION_TYPE = {
	FOUR = 0,
	ANGANG = 1,
	MINGGANG = 2,
	BAGANG = 3,
	DUIZI = 4,
	THREE = 5,
	PENG = 6,
	CHI = 6,
	ZUOCHI = 7,
	ZHONGCHI = 8,
	YOUCHI = 9,
}

local TILE_AREA = {
	SHOU_TILE = 0,
	MING_TILE = 1,
}

local function Hu(state)
	local counts = state.counts
	local sections = state.sections
	if table.sum(counts) == 0 then
		table.insert(state.hu,{
			jiang = state.jiang,
			sections = sections,
		})
		return
	end

	local index = 0
	for i,v in ipairs(counts) do
		if(v ~= 0) then
			index = i
			break
		end
	end

	local section_index = #sections + 1
	if counts[index] == 4 then
		counts[index] = 0
		sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.FOUR,tile = index,}
		Hu(state)
		counts[index] = 4
		sections[section_index] = nil
	end

	if counts[index] >= 3 then
		table.decr(counts,index,3)
		sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.THREE,tile = index,}
		Hu(state)
		table.incr(counts,index,3)
		sections[section_index] = nil
	end

	if not state.jiang and counts[index] >= 2 then
		state.jiang = index
		table.decr(counts,index,2)
		sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.DUIZI,tile = index,}
		Hu(state)
		table.incr(counts,index,2)
		sections[section_index] = nil
		state.jiang = nil
	end

	if rule.tile_value(index) <= 7 and rule.tile_men(index) < 3
		and counts[index + 1] > 0 and counts[index + 2] > 0 then
		table.decr(counts,index)
		table.decr(counts,index + 1)
		table.decr(counts,index + 2)
		sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.CHI,tile = index,}
		Hu(state)
		table.incr(counts,index)
		table.incr(counts,index + 1)
		table.incr(counts,index + 2)
		sections[section_index] = nil
	end
end

local function is_hu(state)
	local counts = state.counts
	if table.sum(counts) == 0 then
		return true
	end

	local index = 0
	for i,v in ipairs(counts) do
		if(v ~= 0) then
			index = i
			break
		end
	end

	if counts[index] == 4 then
		counts[index] = 0
		if is_hu(state) then return true end
		counts[index] = 4
	end

	if counts[index] >= 3 then
		table.decr(counts,index,3)
		if is_hu(state) then return true end
		table.incr(counts,index,3)
	end

	if not state.jiang and counts[index] >= 2 then
		state.jiang = index
		table.decr(counts,index,2)
		if is_hu(state) then return true end
		table.incr(counts,index,2)
		state.jiang = nil
	end

	if rule.tile_value(index) <= 7 and rule.tile_men(index) < 3
		and counts[index + 1] > 0 and counts[index + 2] > 0 then
		table.decr(counts,index)
		table.decr(counts,index + 1)
		table.decr(counts,index + 2)
		if is_hu(state) then return true end
		table.incr(counts,index)
		table.incr(counts,index + 1)
		table.incr(counts,index + 2)
	end

	return false
end

local HU_TYPE = def.HU_TYPE
local HU_INFO = def.CARD_HU_TYPE_INFO
local FAN_UNIQUE_MAP = def.FAN_UNIQUE_MAP


local hu = {
	WEI_HU					= 0,				--未胡
	------------------------------叠加-------------------------------------------------
	-- TIAN_HU					= 1,				--天胡
	-- DI_HU					= 2,				--地胡
	-- REN_HU					= 3,				--人胡
	-- TIAN_TING				= 4,			--天听
	QING_YI_SE				= function(counts,tile_sections)--清一色
		
	end,
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

function rule.is_hu(pai,inPai)
	local cache = {}
	for i=1,50 do
		cache[i] = pai.shou_pai[i] or 0
	end
	if inPai then table.incr(cache,inPai) end
	
	--一万到九万，一筒到九筒，一条到九条， 东-南-西-北  -中-发-白-   春-夏-秋-冬-梅-兰-竹-菊--
	--1-9		  11-19  	21-29 		 	31-34		35-37		41-48

	-- 一万到九万， 东-南-西-北  -中-发-白-   春-夏-秋-冬-梅-兰-竹-菊--
	-- 1-9		    10-13		14-16		20-27
	
	local state = {
		hu = {},
		sections = {},
		counts = clone(cache),
		jiang = nil,
	}

	Hu(state)

	if table.nums(state.hu) == 0 then
		return {}
	end

	local ming_counts = table_counts(pai.ming_counts,function(v,_) return v,1 end,50)
	local counts = table.merge(cache,ming_counts,function(l,r) return l + r end)

	local ming_men_counts = table_counts(cache,function(c,tile) return c,rule.tile_men(tile) end,4)

	local agg_state = {
		shou_counts = cache,
		ming_counts = ming_counts,
		counts = counts,
		ming_men_counts = ming_men_counts,
		sections = state.sections,
		jiang = state.jiang,
	}

	local qing_yi_se = true
	local zi_yi_se = true
	local shuang_jian_ke = false  --双箭刻  两个由中、发、白组成的刻子
	local hun_yi_se = false  --牌型中有万、字、风三种牌
	local jian_ke = false --箭刻
	local men_qing = false --门前清
	local ping_hu = false --平胡
	local lao_shao_fu = false --老少副
	local si_an_ke = false --4暗刻
	local san_an_ke = false --3暗刻
	local shuang_an_ke = false --2暗刻
	local lian_liu = false	--连六
	local yao_jiu_ke = 0 --幺九刻
	local ming_gang = 0 --明杠
	local da_san_feng = false	--大三风
	local xiao_san_feng = false	--小三风
	local san_gang = false --三杠
	local quan_dai_yao = true --全带幺

	for _,v in ipairs(pai.ming_pai) do
		table.insert(g_split_list,clone(v))
	end

	local four_tong_list = {}
	local three_tong_list = {}
	local shun_zi_list = {}
	for _,v in ipairs(g_split_list) do
		if #v > 3 then
			table.insert(four_tong_list,v)
		elseif v[1] == v[2] and v[1] == v[3] then
			table.insert(three_tong_list,v)
		elseif #v > 2 then
			table.insert(shun_zi_list,v)
		end

		for k1,v1 in ipairs(v) do
			if v1 > 9 then qing_yi_se = false end
			if v1 < 10 and k1 > 13 then zi_yi_se = false end
		end
	end

	if g_jiang_tile > 9 then qing_yi_se = false end
	if g_jiang_tile < 10 and g_jiang_tile > 13 then zi_yi_se = false end

	local jian_ke_count = 0
	for _,v in ipairs(three_tong_list) do
		if v[1] >= 14 and v[1] <= 16 then
			jian_ke_count = jian_ke_count + 1
		end
	end

	if jian_ke_count == 2 then shuang_jian_ke = true end
	if jian_ke_count > 0 then jian_ke = true end

	local has_wan = false--混一色 牌型中有万、字、风三种牌
	local has_zi = false
	local has_feng = false
	for k,v in ipairs(pai.ming_pai) do
		if v[1] <= 9 then
			has_wan = true
		elseif v[1] <= 13 then
			has_zi = true
		elseif v[1] <= 16 then
			has_zi = true
		end
	end

	for k,v in ipairs(pai.shou_pai) do
		if v <= 9 then
			has_wan = true
		elseif v <= 13 then
			has_zi = true
		elseif v <= 16 then
			has_zi = true
		end
	end

	if has_wan and has_zi and has_feng then
		hun_yi_se = true
	end

	if #pai.ming_pai == 0 then
		men_qing = true
	end

	if #shun_zi_list == 4 and #four_tong_list == 0 and #three_tong_list == 0 and g_jiang_tile <= 9 then
		ping_hu = true
	end

	local shao_fu = 0
	local lao_fu = 0
	for _,v in ipairs(shun_zi_list) do
		if v[1] == 1 and v[2] == 2 and v[3] == 3 then
			shao_fu = shao_fu + 1
		end
		if v[1] == 7 and v[2] == 8 and v[3] == 9 then
			lao_fu = lao_fu + 1
		end
	end

	if shao_fu >= 1 and lao_fu >= 1 then
		lao_shao_fu = true
	end

	-- 暗刻 --
	local cache_an_ke = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
	local four_or_three_count = 0
	for _,v in ipairs(pai.shou_pai) do
		cache_an_ke[v] = cache_an_ke[v] + 1
	end

	for _,v in ipairs(cache_an_ke) do
		if v >= 3 then
			four_or_three_count = four_or_three_count + 1
		end

		if four_or_three_count >= 4 then
			si_an_ke = true --4暗刻
		elseif four_or_three_count >= 3 then
			san_an_ke = true --3暗刻
		elseif four_or_three_count >= 2 then
			shuang_an_ke = true --2暗刻
		end
	end

	-- 暗刻 --
	local cache_all_tile = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
	for _,v in ipairs(pai.shou_pai) do
		cache_all_tile[v] = 1
	end

	for k,v in ipairs(pai.ming_pai) do
		for k1,v1 in ipairs(v) do
			if k < 5 then
				cache_all_tile[v1] = 1
			end
		end
	end

	cache_all_tile[g_jiang_tile] = 1
	if 	(cache_all_tile[1] + cache_all_tile[2] + cache_all_tile[3] + cache_all_tile[4] + cache_all_tile[5] + cache_all_tile[6] == 6) or
		(cache_all_tile[2] + cache_all_tile[3] + cache_all_tile[4] + cache_all_tile[5] + cache_all_tile[6] + cache_all_tile[7] == 6) or
		(cache_all_tile[3] + cache_all_tile[4] + cache_all_tile[5] + cache_all_tile[6] + cache_all_tile[7] + cache_all_tile[8] == 6) or
		(cache_all_tile[4] + cache_all_tile[5] + cache_all_tile[6] + cache_all_tile[7] + cache_all_tile[8] + cache_all_tile[9] == 6) 
	then
		lian_liu = true	--连六
	end

	for _,v in pairs(three_tong_list) do
		if v[1] == 1 and v[1] == 9 and (v[1] <= 16 and v[1] >= 14) then
			yao_jiu_ke = yao_jiu_ke + 1
		end
	end

	for _,v in pairs(four_tong_list) do
		if v[1] == 1 and v[1] == 9 and (v[1] <= 16 and v[1] >= 14) then
			yao_jiu_ke = yao_jiu_ke + 1
		end
		if v[5] == GANG_TYPE.MING_GANG and v[5] == GANG_TYPE.BA_GANG then
			ming_gang = ming_gang + 1
		end
	end

	-- 大三风 --
	local da_feng_ke_count = 0
	for _,v in ipairs(three_tong_list) do
		if v[1] >= 10 and v[1] <= 13 then
			da_feng_ke_count = da_feng_ke_count + 1
		end
	end

	for _,v in ipairs(four_tong_list) do
		if v[1] >= 10 and v[1] <= 13 then
			da_feng_ke_count = da_feng_ke_count + 1
		end
	end

	if da_feng_ke_count >= 3 then
		da_san_feng = true	--大三风
	end
	-- 大三风 --
	-- 小三风 --
	local xiao_feng_ke_count = 0
	for _,v in ipairs(three_tong_list) do
		if v[1] >= 10 and v[1] <= 13 then
			xiao_feng_ke_count = xiao_feng_ke_count + 1
		end
	end

	for _,v in ipairs(four_tong_list) do
		if v[1] >= 10 and v[1] <= 13 then
			xiao_feng_ke_count = xiao_feng_ke_count + 1
		end
	end

	if g_jiang_tile >= 10 and g_jiang_tile <= 13 then
		xiao_feng_ke_count = xiao_feng_ke_count + 1
	end

	if xiao_feng_ke_count >= 3 and not da_san_feng then
		xiao_san_feng = true	--小三风
	end

	-- 小三风 --
	-- 三杠 -- 
	if #four_tong_list == 3 then
		san_gang = true
	end

	-- 三杠 --
	-- 全带幺 -- 
	if g_jiang_tile ~= 1 and g_jiang_tile ~= 9 then
		quan_dai_yao = false
	end

	for k,v in ipairs(three_tong_list) do
		if v[1] ~= 1 and v[1] ~= 9 then
			quan_dai_yao = false
		end
	end

	for k,v in ipairs(four_tong_list) do
		if v[1] ~= 1 and v[1] ~= 9 then
			quan_dai_yao = false
		end
	end

	for k,v in ipairs(shun_zi_list) do
		if (v[1] ~= 1 and v[1] ~= 9) and (v[2] ~= 1 and v[2] ~= 9) and (v[3] ~= 1 and v[3] ~= 9) then
			quan_dai_yao = false
		end
	end
	-- 全带幺 --

	local base_fan_table = {}
	if qing_yi_se then table.insert( base_fan_table,HU_INFO.QING_YI_SE) end
	if zi_yi_se then table.insert( base_fan_table,HU_INFO.ZI_YI_SE) end
	if shuang_jian_ke then table.insert( base_fan_table,HU_INFO.SHUANG_JIAN_KE) end
	if hun_yi_se then table.insert( base_fan_table,HU_INFO.HUN_YI_SE) end
	if jian_ke then table.insert( base_fan_table,HU_INFO.JIAN_KE) end
	if men_qing then table.insert( base_fan_table,HU_INFO.MEN_QING) end
	if ping_hu then table.insert( base_fan_table,HU_INFO.PING_HU) end
	if lao_shao_fu then table.insert( base_fan_table,HU_INFO.LAO_SHAO_FU) end
	if si_an_ke then table.insert( base_fan_table,HU_INFO.SI_AN_KE) end
	if san_an_ke then table.insert( base_fan_table,HU_INFO.SAN_AN_KE) end
	if shuang_an_ke then table.insert( base_fan_table,HU_INFO.SHUANG_AN_KE) end
	if lian_liu then table.insert( base_fan_table,HU_INFO.LIAN_LIU) end
	if da_san_feng then table.insert( base_fan_table,HU_INFO.DA_SAN_FENG) end
	if xiao_san_feng then table.insert( base_fan_table,HU_INFO.xiao_san_feng) end
	if san_gang then table.insert( base_fan_table,HU_INFO.SAN_GANG) end
	if quan_dai_yao then table.insert( base_fan_table,HU_INFO.QUAN_DAI_YAO) end
	if ping_hu then table.insert( base_fan_table,HU_INFO.PING_HU) end

	for _=1,yao_jiu_ke do
		table.insert(base_fan_table,HU_INFO.YAO_JIU_KE)
	end

	for _=1,ming_gang do
		table.insert(base_fan_table,HU_INFO.MING_GANG)
	end

	----------特殊牌型---------
	if cache[10] == 2 and cache[11] == 2 and cache[12] == 2 and cache[13] == 2 and cache[14] == 2 
		and cache[15] == 2 and cache[16] == 2
	then
		table.insert(base_fan_table,HU_INFO.DA_QI_XIN)
		return base_fan_table-- 大七星 --
	end

	local normarl_7_dui = true
	local dui_count = 0
	for k,v in ipairs(cache) do
		if v ~= 0 and k < 4
			and cache[k+0] == 2 and cache[k+1] == 2 and cache[k+2] == 2 and cache[k+3] == 2
			and cache[k+4] == 2 and cache[k+5] == 2 and cache[k+6] == 2
		then
			table.insert(base_fan_table,HU_INFO.LIAN_QI_DUI)
			return base_fan_table 
		end
		
		if v % 2 == 0 then
			dui_count = dui_count + v/2 
		end
		if v ~= 0 and v ~= 2 then
			normarl_7_dui = false
		end
	end
	
	if normarl_7_dui and dui_count == 7 then
		if cache[14] == 2 and cache[15] == 2 and cache[16] == 2 then
			table.insert(base_fan_table,HU_INFO.SAN_YUAN_QI_DUI)
			return base_fan_table-- 三元七对子 --
		end
		if cache[10] == 2 and cache[11] == 2 and cache[12] == 2 and cache[13] == 2 then
			table.insert(base_fan_table,HU_INFO.SI_XI_QI_DUI)
			return base_fan_table-- 四喜七对子 --
		end
		table.insert(base_fan_table,HU_INFO.NORMAL_QI_DUI)
		return base_fan_table-- 七对 --
	end
	---------------------------

---------------------------------------------------------------------------------------
	-- 大小于五 --
	local da_yu_wu = true 
	local xiao_yu_wu = true 
	for k,v in pairs(cache_all_tile) do
		if v > 0 and k > 4 then
			xiao_yu_wu = false
		end
		if v > 0 and (k < 6 or k > 9) then
			da_yu_wu = false
		end
	end

	if da_yu_wu then
		table.insert(base_fan_table,HU_INFO.DA_YU_WU)
		return base_fan_table
	end

	if xiao_yu_wu then
		table.insert(base_fan_table,HU_INFO.XIAO_YU_WU)
		return base_fan_table
	end

	-- 大小于五 --
	-- 九莲宝灯 --
	if qing_yi_se then
		local cache_bao_deng = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
		for k,v in ipairs(g_split_list) do
			for k1,v1 in ipairs(v) do
				cache_bao_deng[v1] = cache_bao_deng[v1] + 1
			end
		end

		if (cache_bao_deng[1] == 3 or cache_bao_deng[1] == 4) and cache_bao_deng[2] == 1 and cache_bao_deng[3] == 1
		and cache_bao_deng[4] == 1 and cache_bao_deng[5] == 1 and cache_bao_deng[6] == 1 and cache_bao_deng[7] == 1
		and cache_bao_deng[8] == 1 and (cache_bao_deng[9] == 3 or cache_bao_deng[9] == 4) then
			table.insert(base_fan_table,HU_INFO.JIU_LIAN_BAO_DENG)
			return base_fan_table-- 九莲宝灯 --
		end
	end

	-- 九莲宝灯 --
	-- 18罗汉 --
	if #four_tong_list == 4 then
		table.insert(base_fan_table,HU_INFO.LUO_HAN_18)
		return base_fan_table-- 18罗汉 --
	end

	-- 18罗汉 --
	-- 一色双龙会 --
	if qing_yi_se and g_jiang_tile == 5 then
		local shao_fu = 0
		local lao_fu = 0
		for k,v in ipairs(shun_zi_list) do
			if v[1] == 1 and v[2] == 2 and v[3] == 3 then
				shao_fu = shao_fu + 1
			end
			if v[1] == 7 and v[2] == 8 and v[3] == 9 then
				lao_fu = lao_fu + 1
			end
		end
		if shao_fu == 2 and lao_fu == 2 then
			table.insert(base_fan_table,HU_INFO.SHUANG_LONG_HUI)
			return base_fan_table
		end
	end
	-- 一色双龙会 --
	-- 四喜--
	local si_xi_four_count = 0
	for k,v in ipairs(four_tong_list) do
		if v[1] >= 10 and v[1] <= 13 then
			si_xi_four_count = si_xi_four_count + 1
		end
	end

	local si_xi_three_count = 0
	for k,v in ipairs(three_tong_list) do
		if v[1] >= 10 and v[1] <= 13 then
			si_xi_three_count = si_xi_three_count + 1
		end
	end

	if (si_xi_three_count + si_xi_four_count) == 4 then
		table.insert(base_fan_table,HU_INFO.DA_SI_XI)
		return base_fan_table
	end

	if si_xi_three_count == 3 and (g_jiang_tile >= 10 and g_jiang_tile <= 13) then
		table.insert(base_fan_table,HU_INFO.XIAO_SI_XI)
		return base_fan_table
	end
	-- 四喜--
	-- 三元 --
	local san_yuan_three_count = 0
	for k,v in ipairs(three_tong_list) do
		if v[1] >= 14 and v[1] <= 16 then
			san_yuan_three_count = san_yuan_three_count + 1
		end
	end

	if san_yuan_three_count == 3 then
		table.insert(base_fan_table,HU_INFO.DA_SAN_YUAN)
		return base_fan_table
	end

	if san_yuan_three_count == 2 and (g_jiang_tile >= 14 and g_jiang_tile <= 16) then
		table.insert(base_fan_table,HU_INFO.XIAO_SAN_YUAN)
		return base_fan_table
	end
	-- 三元 --
	-- 一色四同顺 --
	if qing_yi_se and #shun_zi_list == 4 then
		local shun_zi_v1 = 0
		local yi_se_si_tong = true
		for k,v in ipairs(shun_zi_list) do
			if shun_zi_v1 == 0 then
				shun_zi_v1 = v[1]
			end
			if shun_zi_v1 ~= v[1] then
				yi_se_si_tong = false break
			end
		end
		if yi_se_si_tong then
			table.insert(base_fan_table,HU_INFO.YI_SE_SI_TONG_SHUN)
			return base_fan_table
		end
	end

	-- 一色四同顺 --
	-- 一色四节高 --
	if qing_yi_se and #three_tong_list == 4 then
		local tong_list = {}
		for k,v in ipairs(three_tong_list) do
			table.insert( tong_list, v[1])
		end
		table.sort(tong_list)
		if (tong_list[1]+1 == tong_list[2]) and (tong_list[1]+2 == tong_list[3]) and (tong_list[1]+3 == tong_list[4]) then
			table.insert(base_fan_table,HU_INFO.YI_SE_SI_JIE_GAO)
			return base_fan_table
		end
	end

	-- 一色四节高 --
	-- 一色四步高 --
	if qing_yi_se and #shun_zi_list == 4 then
		local shun_list = {}
		for k,v in ipairs(shun_zi_list) do
			table.insert( shun_list, v[1])
		end
		table.sort(shun_list)
		if (shun_list[1]+1 == shun_list[2]) and (shun_list[1]+2 == shun_list[3]) and (shun_list[1]+3 == shun_list[4]) then
			table.insert(base_fan_table,HU_INFO.YI_SE_SI_BU_GAO)
			return base_fan_table
		end
	end

	-- 一色四步高 --
	-- 混幺九 --
	if #shun_zi_list == 0 then
		local yao_count = 0
		local jiu_count = 0
		local has_other_wan = false
		if g_jiang_tile == 1 then
			yao_count = yao_count + 1 
		elseif g_jiang_tile == 9 then 
			jiu_count = jiu_count + 1
		elseif g_jiang_tile < 9 and g_jiang_tile > 1 then 
			has_other_wan = true
		end

		for k,v in ipairs(three_tong_list) do
			if v[1] == 1 then
				yao_count = yao_count + 1 
			elseif v[1] == 9 then 
				jiu_count = jiu_count + 1
			elseif v[1] < 9 and v[1] > 1 then 
				has_other_wan = true
			end
		end

		if yao_count == 1 and jiu_count == 1 and not has_other_wan then
			table.insert(base_fan_table,HU_INFO.HUN_YAO_JIU)
			return base_fan_table 
		end
	end
	-- 混幺九 --
	-- 一色三节高 --
	if qing_yi_se and #three_tong_list >= 3 then
		local tong_list = {}
		for k,v in ipairs(three_tong_list) do
			table.insert( tong_list, v[1])
		end
		table.sort(tong_list)
		if ((tong_list[1]+1 == tong_list[2]) and (tong_list[1]+2 == tong_list[3])) or 
		(#three_tong_list > 3 and (tong_list[2]+1 == tong_list[3]) and (tong_list[2]+2 == tong_list[4])) then
			table.insert(base_fan_table,HU_INFO.YI_SE_SAN_JIE_GAO)
			return base_fan_table
		end
	end

	-- 一色三节高 --
	-- 一色三同顺 --
	if qing_yi_se and #shun_zi_list >= 3 then
		local shun_zi_v1_list = {}
		local yi_se_si_tong = true
		for k,v in ipairs(shun_zi_list) do
			shun_zi_v1_list[v[1]] = shun_zi_v1_list[v[1]] or 0
			shun_zi_v1_list[v[1]] = shun_zi_v1_list[v[1]] + 1
		end
		for k,v in ipairs(shun_zi_v1_list) do
			if v == 3 then
				table.insert(base_fan_table,HU_INFO.YI_SE_SAN_TONG_SHUN)
				return base_fan_table
			end
		end
	end

	-- 一色三同顺 --
	-- 清龙 --
	if qing_yi_se then
		local cache_qing_long = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
		for k,v in ipairs(g_split_list) do
			for k1,v1 in ipairs(v) do
				cache_qing_long[v1] = cache_qing_long[v1] + 1
			end
		end
		if cache_qing_long[1] > 0 and cache_qing_long[2] > 0 and cache_qing_long[3] > 0 and cache_qing_long[4] > 0 and 
		cache_qing_long[5] > 0 and cache_qing_long[6] > 0 and cache_qing_long[7] > 0 and cache_qing_long[8] > 0 and cache_qing_long[9] > 0 then
			table.insert(base_fan_table,HU_INFO.QING_LONG)
			return base_fan_table 
		end
	end
	
	-- 清龙 --
	-- 一色三步高 --
	if qing_yi_se and #shun_zi_list >= 3 then
		local cache_san_bu_gao = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
		for k,v in ipairs(shun_zi_list) do
			cache_san_bu_gao[v[1]] = cache_san_bu_gao[v[1]] + 1
		end

		for k,v in ipairs(cache_san_bu_gao) do
			if (v > 0 and cache_san_bu_gao[k+1] > 0 and cache_san_bu_gao[k+2] > 0 ) or 
			(v > 0 and cache_san_bu_gao[k+2] > 0 and cache_san_bu_gao[k+4] > 0) then
				table.insert(base_fan_table,HU_INFO.YI_SE_SAN_BU_GAO)
				return base_fan_table 
			end
		end
	end

	-- 一色三步高 --
	-- 碰碰胡 --
	if (#three_tong_list + #four_tong_list) >= 4 and #shun_zi_list == 0 then
		table.insert(base_fan_table,HU_INFO.PENG_PENG_HU)
		return base_fan_table 
	end

	-- 碰碰胡 --
	-- 四字刻 --
	local zi_ke_count = 0
	for k,v in ipairs(three_tong_list) do
		if v[1] >= 10 and v[1] <= 16 then
			zi_ke_count = zi_ke_count + 1
		end
	end

	for k,v in ipairs(four_tong_list) do
		if v[1] >= 10 and v[1] <= 16 then
			zi_ke_count = zi_ke_count + 1
		end
	end

	if zi_ke_count >= 4 then
		table.insert(base_fan_table,HU_INFO.SI_ZI_KE)
		return base_fan_table 
	end
	-- 四字刻 --
	
	table.insert(base_fan_table,HU_INFO.PING_HU)
	return base_fan_table 
end


function rule.get_fan_table_res(base_fan_table)
	local res = {describe = "",fan = 0}
	local del_list = {}
	for _,v in ipairs(base_fan_table) do
		local tmp_map = FAN_UNIQUE_MAP[v.name]
		if tmp_map then
			for _,v1 in ipairs(tmp_map) do
				for k2,v2 in ipairs(base_fan_table) do
					if v1 == v2.name then
						table.insert(del_list,k2)
					end
				end
			end
		end
	end

	for _,v in ipairs(del_list) do
		base_fan_table[v] = nil				
	end

	local description = {}
	local fan = 0

	for _,v in ipairs(base_fan_table) do
		table.insert(v.name)
		fan = fan + v.fan
	end

	res.describe = table.concat(description,",")
	res.fan = fan

	return res
end

function rule.is_chi(pai,tile)
	local counts = pai.shou_pai
	local c = counts[tile] or 0
	if not c or c == 0 then
		return {}
	end

	if rule.tile_men(tile) > 2 then
		return {}
	end

	local s2,s1,b1,b2 = 
		counts[tile - 2] or 0,
		counts[tile - 1] or 0,
		counts[tile + 1] or 0,
		counts[tile + 2] or 0

	return {
		[ACTION.LEFT_CHI] = (s2 > 0 and s1 > 0) and {tile} or nil,
		[ACTION.MID_CHI] = (s1 > 0 and b1 > 0) and {tile} or nil ,
		[ACTION.RIGHT_CHI] = (b1 > 0 and b2 > 0) and {tile} or nil,
	}
end

return rule