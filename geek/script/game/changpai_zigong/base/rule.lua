local def = require "game.changpai_zigong.base.define"
local log = require "log"
require "functions"

local ACTION = def.ACTION
local all_tiles ={
	[1]={value=2,hong=2,hei=0,index=1},
	[2]={value=3,hong=1,hei=2,index=2},
	[3]={value=4,hong=1,hei=3,index=3},
	[4]={value=4,hong=0,hei=4,index=4},
	[5]={value=5,hong=5,hei=0,index=5},
	[6]={value=5,hong=0,hei=5,index=6},
	[7]={value=6,hong=0,hei=6,index=7},
	[8]={value=6,hong=1,hei=5,index=8},
	[9]={value=6,hong=4,hei=2,index=9},
	[10]={value=7,hong=0,hei=7,index=10},
	[11]={value=7,hong=1,hei=6,index=11},
	[12]={value=7,hong=4,hei=3,index=12},
	[13]={value=8,hong=0,hei=8,index=13},
	[14]={value=8,hong=0,hei=8,index=14},
	[15]={value=8,hong=8,hei=0,index=15},
	[16]={value=9,hong=0,hei=9,index=16},
	[17]={value=9,hong=4,hei=5,index=17},
	[18]={value=10,hong=0,hei=10,index=18},
	[19]={value=10,hong=4,hei=6,index=19},
	[20]={value=11,hong=0,hei=11,index=20},
	[21]={value=12,hong=6,hei=6,index=21}
}
local function counts_2_tiles(counts)
	local tiles = {}
	for tile,c in pairs(counts) do
		if c > 0 then
			for _ = 1,c do
				table.insert(tiles,tile)
			end
		end
	end

	return tiles
end

local rule 			= {}

function rule.tile_heicounts(v)
	return v and all_tiles[v].hei or 0
end
function rule.tile_hongcounts(v)
	return v and all_tiles[v].hong or 0 
end
function rule.tile_value(v)
	return v and all_tiles[v].value or 0
end

function rule.tile_men(v)
	return math.floor(v / 10)
end


local TILE_AREA = def.TILE_AREA
local SECTION_TYPE = def.SECTION_TYPE

local function section_tiles_gang(s)
	return table.fill(nil,s.tile,1,4)
end

local function section_tiles_peng(s)
	return table.fill(nil,s.tile,1,3)
end

local function section_tiles_dui(s)
	return table.fill(nil,s.tile,1,2)
end

local function section_tiles_left_chi(s)
	return {s.tile - 2,s.tile - 1,s.tile}
end

local function section_tiles_mid_chi(s)
	return {s.tile - 1,s.tile,s.tile + 1}
end

local function section_tiles_right_chi(s)
	return {s.tile,s.tile + 1,s.tile + 2}
end

local SECTION_TILES = {
	[SECTION_TYPE.BA_GANG] = section_tiles_gang,
	[SECTION_TYPE.PENG] = section_tiles_peng,
	[SECTION_TYPE.CHI] = section_tiles_left_chi,	
}

local function hu(state)
	local counts = state.counts
	local sections = state.sections
	local tuo = state.tuos
	local tiles = counts_2_tiles(counts)
	log.dump(counts)
	log.dump(sections)
	if #tiles == 0  then     
		table.insert(state.hu,clone(sections))
		return
	end
	--这里的 first_tile 是牌得index 值
	local section_index = #sections + 1
	local first_tile = tiles[1]

	for tile,c in pairs(counts) do
		if tile>=1 and tile<=21 and first_tile>=1 and first_tile<=21 and counts[first_tile]>0 and c > 0 and rule.tile_value(first_tile)+rule.tile_value(tile) == 14 then		
			table.decr(counts,first_tile)
			table.decr(counts,tile)	
			sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.CHI,tile = tile,othertile =first_tile  }
			hu(state)
			table.incr(counts,first_tile)
			table.incr(counts,tile)
			sections[section_index] = nil
		end
	end
end

local function feed_hu_tile(tiles)
	local feed_tiles = {}
	if #tiles ~= 1  then
		return feed_tiles
	end

	if #tiles == 1 then
		for k, v in pairs(all_tiles) do
			if tiles[1]+v.value == 14 then
				feed_tiles[v.index] = true 
			end
		end

	end
	return feed_tiles
end


local function ting(state)
	local counts = state.counts
	local tiles = counts_2_tiles(counts)
	local tile_count = #tiles
	
	if tile_count == 1 then
		table.mergeto(state.feed_tiles,feed_hu_tile(tiles))
		return
	end
	local feed_tiles = {}
	local first_tile = tiles[1]
	table.decr(counts,first_tile)
	for tile,c in pairs(counts) do
		if  c > 0 and rule.tile_value(first_tile)+rule.tile_value(tile) == 14 then
			table.decr(counts,first_tile)
			table.decr(counts,tile)
			ting(state)
			table.incr(counts,first_tile)
			table.incr(counts,tile )
		end
	end
	table.incr(counts,first_tile)
end



local function is_hu(state)
	local counts = state.counts
	local tuos = state.tuos
	local tiles = counts_2_tiles(counts)
	if #tiles == 0 then
		return true
	end

	--这里的 first_tile 是牌得index 值
	local first_tile = tiles[1]
	for tile,c in pairs(counts) do
		if  tile>=1 and tile<=21 and counts[first_tile]>0 and c > 0 and rule.tile_value(first_tile)+rule.tile_value(tile) == 14 then		
			table.decr(counts,first_tile)
			table.decr(counts,tile)		
			if is_hu(state) then return true end
			table.incr(counts,first_tile)
			table.incr(counts,tile)
		end
	end

	return false
end


local HU_TYPE = def.CP_HU_TYPE
local UNIQUE_HU_TYPE = def.UNIQUE_HU_TYPE

local function get_hu_types(pai,cache,in_pai)
	local base_types = {}
	base_types[HU_TYPE.TUOTUO_HONG] = 1
	base_types[HU_TYPE.BABA_HEI] = 1
	base_types[HU_TYPE.HEI_LONG] = 1
	
	--在这里判断玩家的特殊牌型是妥妥红，还是把把黑，还是黑龙，还是平胡
	log.dump(pai.ming_pai)
	log.dump(cache)
	local counthonghei = 0
	for _,s in pairs(pai.ming_pai) do
		if  s.type == SECTION_TYPE.CHI then	
			log.dump(s)
			if ( rule.tile_hongcounts(s.tile)<=0) or ( rule.tile_hongcounts(s.othertile)<=0) then
				base_types[HU_TYPE.TUOTUO_HONG] = nil
			end
			if  rule.tile_hongcounts(s.tile)>0 or rule.tile_hongcounts(s.othertile)>0 then
				base_types[HU_TYPE.BABA_HEI] = nil
				if rule.tile_hongcounts(s.tile)>0 then
					counthonghei = counthonghei+1
				end
				if rule.tile_hongcounts(s.othertile)>0 then
					counthonghei = counthonghei+1
				end
				
			end
		else
			if   rule.tile_hongcounts(s.tile)<=0 then
				base_types[HU_TYPE.TUOTUO_HONG] = nil
			end
			if  rule.tile_hongcounts(s.tile)>0 then
				base_types[HU_TYPE.BABA_HEI] = nil
			end
			if s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU then
				if  rule.tile_hongcounts(s.tile)>0 then
					counthonghei = counthonghei+3
				end
			end
			if s.type == SECTION_TYPE.BA_GANG  then
				if  rule.tile_hongcounts(s.tile)>0 then
					counthonghei = counthonghei+4
				end
			end
		end
	end
	for tile,count in pairs(cache) do
		if count>0  and rule.tile_hongcounts(tile)<=0  then
			base_types[HU_TYPE.TUOTUO_HONG] = nil
		end
		if count>0 and rule.tile_hongcounts(tile)>0  then
			base_types[HU_TYPE.BABA_HEI] = nil
		end
		if count>0 and rule.tile_hongcounts(tile)>0 then
			counthonghei = counthonghei+count
		end
	end
	-- if in_pai then
	-- 	if(rule.tile_hongcounts(in_pai)<=0) then
	-- 		base_types[HU_TYPE.TUOTUO_HONG] = nil
	-- 	end
	-- 	if(rule.tile_hongcounts(in_pai)>0) then
	-- 		base_types[HU_TYPE.BABA_HEI] = nil
	-- 		counthonghei= counthonghei+1
	-- 	end
	-- end


	if counthonghei>4 then base_types[HU_TYPE.HEI_LONG] = nil end
	
	if not base_types[HU_TYPE.TUOTUO_HONG] and not base_types[HU_TYPE.BABA_HEI] and not base_types[HU_TYPE.HEI_LONG] then 
		base_types[HU_TYPE.PING_HU] = 1
	end
	log.dump(base_types)
	return base_types
end
function rule.is_hu(pai,in_pai,is_zhuang)
	local cache = {}
	local shoupai = {}
	for i=1,50 do
		cache[i] = pai.shou_pai[i] or 0
		shoupai[i] = pai.shou_pai[i] or 0
	end
	if in_pai then
		 table.incr(cache,in_pai) 
		 table.incr(shoupai,in_pai) 
	end
	local state = {
		hu = {},
		sections = {},
		counts = cache,
		tuos = 0
	}
	local can_hu = is_hu(state)
	
	local en_tuo = false 

	local hutype =  get_hu_types(pai,shoupai,in_pai)
	log.dump(hutype) 
	log.dump(can_hu) 
	log.dump(is_zhuang) 
	log.dump(rule.tuos(pai,in_pai,nil,is_zhuang)) 

	if is_zhuang then 
		if rule.tuos(pai,in_pai,nil,is_zhuang)>=14 or hutype[HU_TYPE.HEI_LONG] then en_tuo = true end
	else
		if rule.tuos(pai,in_pai,nil,false)>=12 or hutype[HU_TYPE.HEI_LONG] then en_tuo = true end
	end

	return can_hu and en_tuo 
end



function rule.tuos(pai,in_pai,mo_pai,is_zhuang)
	local tuos = 0
	local counts =pai and pai.shou_pai or {}
		for index, s in pairs(pai.ming_pai) do
			if (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU) and rule.tile_hongcounts(s.tile)>0 then
				tuos =tuos + 6
			end
			if (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU) and rule.tile_hongcounts(s.tile) == 0 then
				tuos =tuos + 3
			end
			if (s.type == SECTION_TYPE.BA_GANG) and rule.tile_hongcounts(s.tile) > 0 then
				tuos =tuos + 8
			end
			if (s.type == SECTION_TYPE.BA_GANG) and rule.tile_hongcounts(s.tile) == 0 then
				tuos =tuos + 4
			end
			if  s.type == SECTION_TYPE.CHI then
				if rule.tile_hongcounts(s.tile) > 0 then
					tuos =tuos + 1
				end
				if rule.tile_hongcounts(s.othertile) > 0 then
					tuos =tuos + 1
				end
			end
		end
		log.dump(counts)
		for i, c in pairs(counts) do
			if i>0 and c >0 then
				if  rule.tile_hongcounts(i) >0 then
					tuos =tuos + c
				end
			end
		end
		if in_pai and rule.tile_hongcounts(in_pai) >0 then
			tuos = tuos + 1
		end
	return tuos
end
function rule.hu(pai,in_pai,mo_pai,is_zhuang)
	local cache = {}
	local cards = {}
	for i = 1,50 do 
		cache[i] = pai.shou_pai[i] or 0 
		cards[i] = pai.shou_pai[i] or 0 
	end
	if in_pai then
		 if  rule.tile_value(in_pai)==7 then --翻牌或者别人出的牌是 7 时不可以胡牌
			return {{[HU_TYPE.WEI_HU] = 1}}
		 end
		 table.incr(cache,in_pai)
		 table.incr(cards,in_pai)
		 
	 end
	local state = { hu = {}, sections = {}, counts = clone(cache) ,tuos = 0}
	hu(state)
	
	log.dump(state)
	local alltypes = {}
	if table.nums(state.hu) == 0  then
		return {{[HU_TYPE.WEI_HU] = 1}}
	
	end
	
	local types = get_hu_types(pai,cards,in_pai)

	if types and types[HU_TYPE.PING_HU] then
		--坨数小于规定庄家14坨，闲家12坨的时候不能胡
		if is_zhuang and rule.tuos(pai,in_pai,mo_pai,is_zhuang)<14 or not is_zhuang and rule.tuos(pai,in_pai,mo_pai,is_zhuang)<12 then 
			return {{[HU_TYPE.WEI_HU] = 1}}
		end
	end
	table.insert(alltypes,types)

	
	log.dump(alltypes)
	return alltypes
end

function rule.ting_tiles(pai)
	local cache = {}
	for i = 1,50 do cache[i] = pai.shou_pai[i] or 0 end
	local state = { feed_tiles = {}, counts = cache }
	ting(state)
	local tiles = state.feed_tiles
	
	return tiles
end

--未摸牌判听
function rule.ting(pai,si_dui)
	return rule.ting_tiles(pai)
end

--打牌的时候打那张听的牌是啥
function rule.ting_full(pai)
	local all_pai = clone(pai)
	local discard_then_ting_tiles = table.map(all_pai.shou_pai,function(c,tile)
		if c <= 0 then return end
		table.decr(all_pai.shou_pai,tile)
		local tiles = rule.ting_tiles(all_pai)
		table.incr(all_pai.shou_pai,tile)
		if table.nums(tiles) > 0 then return tile,tiles end
	end)

	return discard_then_ting_tiles
end

function rule.get_fan_table_res(base_fan_table)
	local res = {describe = "",fan = 0}
	local del_list = {}
	for _,v in ipairs(base_fan_table) do
		local tmp_map = UNIQUE_HU_TYPE[v.name]
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


	return {
		[ACTION.CHI] = false,
	}
end


return rule