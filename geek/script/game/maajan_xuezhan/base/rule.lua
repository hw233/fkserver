local def = require "game.maajan_xuezhan.base.define"
local log = require "log"
require "functions"

local ACTION = def.ACTION

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

function rule.tile_value(v)
	return v % 10
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
	[SECTION_TYPE.FOUR] = section_tiles_gang,
	[SECTION_TYPE.AN_GANG] = section_tiles_gang,
	[SECTION_TYPE.MING_GANG] = section_tiles_gang,
	[SECTION_TYPE.BA_GANG] = section_tiles_gang,
	[SECTION_TYPE.DUIZI] = section_tiles_dui,
	[SECTION_TYPE.THREE] = section_tiles_peng,
	[SECTION_TYPE.PENG] = section_tiles_peng,
	[SECTION_TYPE.CHI] = section_tiles_left_chi,
	[SECTION_TYPE.LEFT_CHI] = section_tiles_left_chi,
	[SECTION_TYPE.MID_CHI] = section_tiles_mid_chi,
	[SECTION_TYPE.RIGHT_CHI] = section_tiles_right_chi,
}

local function hu(state)
	local counts = state.counts
	local sections = state.sections
	local tiles = counts_2_tiles(counts)
	if #tiles == 0 then
		table.insert(state.hu,clone(sections))
		return
	end

	local section_index = #sections + 1
	local first_tile = tiles[1]
	if counts[first_tile] >= 3 then
		table.decr(counts,first_tile,3)
		sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.THREE,tile = first_tile,}
		hu(state)
		table.incr(counts,first_tile,3)
		sections[section_index] = nil
	end

	if not state.jiang and counts[first_tile] >= 2 then
		state.jiang = first_tile
		table.decr(counts,first_tile,2)
		sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.DUIZI,tile = first_tile,}
		hu(state)
		table.incr(counts,first_tile,2)
		sections[section_index] = nil
		state.jiang = nil
	end

	for tile,c in pairs(counts) do
		if  c > 0 and rule.tile_value(tile) > 0 and rule.tile_value(tile) <= 7 and 
			rule.tile_men(tile) < 3	and counts[tile + 1] > 0 and counts[tile + 2] > 0 then
			table.decr(counts,tile)
			table.decr(counts,tile + 1)
			table.decr(counts,tile + 2)
			sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.CHI,tile = tile,}
			hu(state)
			table.incr(counts,tile)
			table.incr(counts,tile + 1)
			table.incr(counts,tile + 2)
			sections[section_index] = nil
		end
	end
end

local function feed_hu_tile(tiles)
	local feed_tiles = {}
	if #tiles < 1 or #tiles > 2 then
		return feed_tiles
	end

	if #tiles == 1 then
		feed_tiles[tiles[1]] = true
	elseif #tiles == 2 then
		local tile1,tile2 = tiles[1],tiles[2]
		if tile1 == tile2 then
			feed_tiles[tile1] = true
		else
			if rule.tile_men(tile1) ~= rule.tile_men(tile2) then 
				return feed_tiles
			end

			local min,max
			if tile1 > tile2 then min,max = tile2,tile1
			else min,max = tile1,tile2
			end
			local sub = math.abs(tile1 - tile2)
			if sub == 1 then
				if rule.tile_value(min) > 1 then feed_tiles[min - 1] = true end
				if rule.tile_value(max) < 9 then feed_tiles[max + 1] = true end
			elseif sub == 2 then
				feed_tiles[min + 1] = true
			end
		end
	end

	return feed_tiles
end


local function ting(state)
	local counts = state.counts
	local tiles = counts_2_tiles(counts)
	local tile_count = #tiles
	
	if tile_count == 1 and not state.jiang then
		table.mergeto(state.feed_tiles,feed_hu_tile(tiles))
		return
	end

	if tile_count == 2 and state.jiang then
		table.mergeto(state.feed_tiles,feed_hu_tile(tiles))
		return
	end

	local feed_tiles = {}
	for _,tile in pairs(tiles) do
		if counts[tile] >= 3 then
			table.decr(counts,tile,3)
			ting(state)
			table.incr(counts,tile,3)
		end
	end

	for _,tile in pairs(tiles) do
		if not state.jiang and counts[tile] >= 2 then
			state.jiang = tile
			table.decr(counts,tile,2)
			ting(state)
			table.incr(counts,tile,2)
			state.jiang = nil
		end
	end

	for tile,c in pairs(counts) do
		if c > 0 and rule.tile_value(tile) <= 7 and rule.tile_value(tile) > 0 and 
			rule.tile_men(tile) < 3 and counts[tile + 1] > 0 and counts[tile + 2] > 0 then
			table.decr(counts,tile)
			table.decr(counts,tile + 1)
			table.decr(counts,tile + 2)
			ting(state)
			table.incr(counts,tile)
			table.incr(counts,tile + 1)
			table.incr(counts,tile + 2)
		end
	end
end

local function ting_qi_dui(pai,counts)
	local count_tilemaps = table.group(counts,function(c,_) return c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	local even_count = (count_tiles[2] and #count_tiles[2] or 0) + (count_tiles[4] and #count_tiles[4] * 2 or 0)
	if count_tiles[1] and #count_tiles[1] == 1 and even_count == 6 then
		return count_tiles[1][1]
	end

	if count_tiles[3] and #count_tiles[3] == 1 and even_count == 5 then
		return count_tiles[3][1]
	end

	return nil
end

local function ting_si_dui(pai,counts)
	if table.nums(pai.ming_pai) > 0 then
		return nil
	end

	local count_tilemaps = table.group(counts,function(c,_) return c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	local even_count = (count_tiles[2] and #count_tiles[2] or 0) + (count_tiles[4] and #count_tiles[4] * 2 or 0)
	if count_tiles[1] and #count_tiles[1] == 1 and even_count == 3 then
		return count_tiles[1][1]
	end

	if count_tiles[3] and #count_tiles[3] == 1 and even_count == 2 then
		return count_tiles[3][1]
	end

	return nil
end

local function is_qi_dui(pai,counts)
	local dui_zi_count = table.sum(counts,function(c)
		return c == 4 and 2 or c == 2 and 1 or 0
	end)

	local total_count = table.sum(counts)

	return dui_zi_count == 7 and total_count == 14 and table.nums(pai.ming_pai) == 0
end

local function is_si_dui(pai,counts)
	local dui_zi_count = table.sum(counts,function(c)
		return c == 4 and 2 or c == 2 and 1 or 0
	end)

	local total_count = table.sum(counts)

	return dui_zi_count == 4 and total_count == 8 and table.nums(pai.ming_pai) == 0
end

local function is_hu(state)
	local counts = state.counts
	local tiles = counts_2_tiles(counts)
	if #tiles == 0 then
		return true
	end

	local index = tiles[1]
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
local UNIQUE_HU_TYPE = def.UNIQUE_HU_TYPE


function rule.is_hu(pai,in_pai,with_si_dui)
	local cache = {}
	for i=1,50 do
		cache[i] = pai.shou_pai[i] or 0
	end
	if in_pai then table.incr(cache,in_pai) end
	local state = {
		sections = {},
		counts = cache,
	}

	local can_hu = is_hu(state)
	local qi_dui = is_qi_dui(pai,cache)
	local si_dui = with_si_dui and is_si_dui(pai,cache)

	return can_hu or qi_dui or si_dui
end

local function get_qi_dui_types(pai,cache)
	local base_types = {}
	return base_types
end


local function table_entire_key(tb)
	table.sort(tb)
	return table.concat(tb,",")
end

local function merge_same_type(alltypes)
	local types = {}

	for _,ts in pairs(alltypes) do
		local key = table_entire_key(table.keys(ts))
		types[key] = ts
	end

	return table.values(types)
end


local function is_qing_yi_se(pai,cache)
	local men_counts = table.fill(nil,0,0,5)

	table.agg(cache,men_counts,function(tb,c,tile)
		table.incr(tb,rule.tile_men(tile),c)
		return tb
	end)

	table.agg(pai.ming_pai,men_counts,function(tb,s)
		table.incr(tb,rule.tile_men(s.tile))
		return tb
	end)

	local total_men_count = table.sum(men_counts,function(c,men)
		return (c > 0 and men < 3) and 1 or 0
	end)

	return total_men_count == 1
end

local function is_2_5_8(pai,cache)
	local is_shou_258 = table.logic_and(cache,function(c,tile)
		local num = rule.tile_value(tile)
		return c == 0 or (num == 2 or num == 5 or num == 8)
	end)
	local is_ming_258 = table.logic_and(pai.ming_pai,function(s)
		local num = rule.tile_value(s.tile)
		return num == 2 or num == 5 or num == 8
	end)

	return is_shou_258 and is_ming_258
end

local function is_1_9(pai,cache)
	return table.logic_and(cache,function(c,tile)
		local num = rule.tile_value(tile)
		return c == 0 or (num == 1 or num == 9)
	end) and table.logic_and(pai.ming_pai,function(s)
		local num = rule.tile_value(s.tile)
		return num == 1 or num == 9
	end)
end

local function is_duan_yao(pai,in_pai)
	local is_19 = table.logic_or(pai.shou_pai,function(c,tile)
		local num = rule.tile_value(tile)
		return c > 0 and (num == 1 or num == 9)
	end) or (table.nums(pai.ming_pai) > 0 and table.logic_or(pai.ming_pai,function(s)
		local num = rule.tile_value(s.tile)
		return num == 1 or num == 9
	end)) or (in_pai and 
		(rule.tile_value(in_pai) == 1 or rule.tile_value(in_pai) == 9)
	)

	return not is_19
end

local function gou_count(pai,cache)
	local shou_gou = table.sum(cache,function(c) return c == 4 and 1 or 0 end)
	local ming_gou = table.sum(pai.ming_pai,function(s) return (s.type == SECTION_TYPE.PENG and cache[s.tile] == 1) and 1 or 0 end)
	return shou_gou + ming_gou
end

local function is_ka_wu_tiao(pai,in_pai,mo_pai)
	local is_ka_wu_tiao = false
	if in_pai then
		if in_pai ~= 25 then
			return false
		end
	elseif mo_pai then
		if mo_pai ~= 25 then
			return false
		end
	else
		return false
	end
	
	local all_pai = clone(pai)
	if in_pai then table.incr(all_pai.shou_pai,in_pai) end
	log.dump(all_pai,"is_ka_wu_tiao")
	local shou_pai = all_pai.shou_pai
	if (not shou_pai[24] or shou_pai[24] == 0) or (not shou_pai[26] or shou_pai[26] == 0) then
		return false
	end
	table.decr(all_pai.shou_pai,24)
	table.decr(all_pai.shou_pai,25)
	table.decr(all_pai.shou_pai,26)
	local cache = {}
	for i = 1,29 do cache[i] = all_pai.shou_pai[i] or 0 end
	-- if in_pai then table.incr(cache,in_pai) end
	local state = {  counts = clone(cache) }
	if is_hu(state) then
		is_ka_wu_tiao = true
	end
	log.dump(is_ka_wu_tiao,"is_ka_wu_tiao")
	return is_ka_wu_tiao
end

local function is_yi_tiao_long(pai,in_pai,mo_pai)
	local is_yi_tiao_long = false
	
	local all_pai = clone(pai)	
	if in_pai then table.incr(all_pai.shou_pai,in_pai) end
	local total_count = table.sum(all_pai.shou_pai)
	-- log.dump(all_pai,"is_yi_tiao_long nn ".. total_count)
	if total_count < 11 then
		return false
	end

	local cache = {}
	for i = 1,29 do cache[i] = all_pai.shou_pai[i] or 0 end
	if not is_qing_yi_se(all_pai,cache) then
		return false
	end
	if table.nums(pai.ming_pai) > 1 then
		return false
	end
	local men 
	for tile, count in pairs(all_pai.shou_pai) do
		if tile and count > 0 then
			men = rule.tile_men(tile)
			log.info("========= men %d ",men)
			break
		end
	end
	
	-- log.dump(all_pai,"is_yi_tiao_long")
	local shou_pai = all_pai.shou_pai
	for i = men*10+1, men*10+9, 1 do
		if (not shou_pai[i] or shou_pai[i] == 0) then
			return false
		end
	end
	for i = men*10+1, men*10+9, 1 do
		table.decr(all_pai.shou_pai,i)
	end

	local newcache = {}
	for i = 1,29 do newcache[i] = all_pai.shou_pai[i] or 0 end

	local state = {  counts = clone(newcache) }
	if is_hu(state) then
		is_yi_tiao_long = true
	end
	log.dump(is_yi_tiao_long,"is_yi_tiao_long")
	return is_yi_tiao_long
end

local function is_all_1_9(pai,sections)
	return table.logic_and(sections,function(s)
		local val = rule.tile_value(s.tile)
		if 	s.type == SECTION_TYPE.CHI then
			return table.logic_or({val,val + 1,val + 2},function(v) 
				return v == 1 or v == 9
			end)
		end
		return val == 1 or val == 9
	end) and (table.nums(pai.ming_pai) == 0 or table.logic_and(pai.ming_pai,function(s)
		local val = rule.tile_value(s.tile)
		return val == 1 or val == 9
	end))
end

local function is_men_qing(pai)
	return table.nums(pai.ming_pai) == 0 or
		table.logic_and(pai.ming_pai,function(s) return s.type == SECTION_TYPE.AN_GANG end)
end

local function unique_hu_types(base_hu_types)
	local types = {}
	for unique_t,s in pairs(UNIQUE_HU_TYPE) do
		if table.logic_and(s,function(_,k) return base_hu_types[k] end) then
			for t,_ in pairs(s) do base_hu_types[t] = nil end
			types[unique_t] = 1
		end
	end

	return table.merge(types,base_hu_types,function(l,r) 
		local c = (l or 0) + (r or 0)
		return (c and c > 0) and c or nil
	end)
end
-- inpai,mopai 用于后面加的卡五条、一条龙判断
local function get_hu_types(pai,cache,sections,in_pai,inpai,mopai)
	local base_types = {}

	local shun_zi_list = table.select(sections,function(v)
		return v.type == SECTION_TYPE.CHI
	end)

	if table.nums(shun_zi_list) == 0 then
		if is_2_5_8(pai,cache) then
			base_types[HU_TYPE.JIANG_DUI] = 1
		else
			base_types[HU_TYPE.DA_DUI_ZI] = 1
		end
	end

	for _,s in pairs(shun_zi_list) do
		if in_pai == 22 then
			if s.type == SECTION_TYPE.CHI and s.tile + 1 == 22 then
				base_types[HU_TYPE.KA_ER_TIAO] = 1
			end
		end

		if in_pai % 10 == 5 then
			if s.type == SECTION_TYPE.CHI and (s.tile + 1) % 10 == 5 and (s.tile + 1) == in_pai then
				base_types[HU_TYPE.KA_WU_XING] = 1
			end
		end
	end

	if is_ka_wu_tiao(pai,inpai,mopai) then
		base_types[HU_TYPE.KA_WU_TIAO] = 1
	end

	if is_yi_tiao_long(pai,inpai,mopai) then
		base_types[HU_TYPE.YI_TIAO_LONG] = 1
	end

	if is_all_1_9(pai,sections) then
		base_types[HU_TYPE.QUAN_YAO_JIU] = 1
	end

	if table.nums(base_types) == 0 then
		base_types[HU_TYPE.PING_HU] = 1
	end

	return base_types
end


function rule.hu(pai,in_pai,mo_pai)
	local cache = {}
	for i = 1,50 do cache[i] = pai.shou_pai[i] or 0 end
	if in_pai then table.incr(cache,in_pai) end
	
	--一万到九万，一筒到九筒，一条到九条， 东-南-西-北  -中-发-白-   春-夏-秋-冬-梅-兰-竹-菊--
	--1-9		  11-19  	21-29 		 	31-34		35-37		41-48
	
	local state = { hu = {}, sections = {}, counts = clone(cache) }

	hu(state)

	local alltypes = {}

	local qi_dui = is_qi_dui(pai,cache)
	local si_dui = is_si_dui(pai,cache)
	if table.nums(state.hu) == 0 and not qi_dui and not si_dui then
		return {{[HU_TYPE.WEI_HU] = 1}}
	end

	local qing_yi_se = is_qing_yi_se(pai,cache)
	local men_qing =  is_men_qing(pai)
	local duan_yao = is_duan_yao(pai,in_pai)
	local gou = gou_count(pai,cache)

	if qi_dui then
		local base_types = {}
		if gou > 0 then
			base_types[HU_TYPE.LONG_QI_DUI] = 1
		else
			base_types[HU_TYPE.QI_DUI] = 1
		end

		if qing_yi_se then base_types[HU_TYPE.QING_YI_SE] = 1 end
		if duan_yao then base_types[HU_TYPE.DUAN_YAO] = 1 end
		if men_qing then base_types[HU_TYPE.MEN_QING] = 1 end

		table.insert(alltypes,base_types)
	end

	if si_dui then
		local base_types = {}
		if gou > 0 then
			base_types[HU_TYPE.LONG_SI_DUI] = 1
		else
			base_types[HU_TYPE.SI_DUI] = 1
		end

		if qing_yi_se then base_types[HU_TYPE.QING_YI_SE] = 1 end
		if duan_yao then base_types[HU_TYPE.DUAN_YAO] = 1 end
		if men_qing then base_types[HU_TYPE.MEN_QING] = 1 end

		table.insert(alltypes,base_types)
	end

	local common_types = {}
	
	if duan_yao then common_types[HU_TYPE.DUAN_YAO] = 1 end
	if men_qing then common_types[HU_TYPE.MEN_QING] = 1 end
	if qing_yi_se then common_types[HU_TYPE.QING_YI_SE] = 1 end
	if gou > 0 then common_types[HU_TYPE.DAI_GOU] = gou end

	for _,sections in pairs(state.hu) do
		local types = get_hu_types(pai,cache,sections,in_pai or mo_pai,in_pai,mo_pai)
		local sum = table.sum(pai.shou_pai)
		if (sum == 1 and pai.shou_pai[in_pai] == 1) or
			(sum == 2 and not in_pai and table.logic_or(pai.shou_pai,function(c,_) return c == 2 end)) then
			common_types[HU_TYPE.DAN_DIAO_JIANG] = 1
		end

		table.mergeto(types,common_types,function(l,r) return (l or 0) + (r or 0) end)

		table.insert(alltypes,types)
	end

	for i = 1,#alltypes do
		alltypes[i] = unique_hu_types(alltypes[i])
	end

	alltypes = merge_same_type(alltypes)

	return alltypes
end

function rule.ting_tiles(pai,si_dui)
	local cache = {}
	for i = 1,50 do cache[i] = pai.shou_pai[i] or 0 end
	local state = { feed_tiles = {}, counts = cache }
	ting(state)
	local qi_dui_tile = ting_qi_dui(pai,cache)
	local tiles = state.feed_tiles
	if qi_dui_tile then tiles[qi_dui_tile] = true end
	if si_dui then 
		local si_dui_tile = ting_si_dui(pai,cache)
		if si_dui_tile then
			tiles[si_dui_tile] = true
		end
	end
	return tiles
end

--未摸牌判听
function rule.ting(pai,si_dui)
	return rule.ting_tiles(pai,si_dui)
end

--全部牌判听
function rule.ting_full(pai,si_dui)
	local all_pai = clone(pai)
	local discard_then_ting_tiles = table.map(all_pai.shou_pai,function(c,tile)
		if c <= 0 then return end
		table.decr(all_pai.shou_pai,tile)
		local tiles = rule.ting_tiles(all_pai,si_dui)
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

-- local test_pai = {
-- 	shou_pai = {[14] = 3,[16] = 1,[17] = 1,[22] = 2,[24] = 1,[25] = 1,[26] = 1,[27] = 1,[28] = 1,[29] = 1},
-- 	ming_pai = {
-- 	},

-- }

-- local test_pai = {
-- 	shou_pai = {[5] = 2,[6] = 1,[7] = 1,[8] = 1,[25] = 1,[26] = 1,[27] = 1},
-- 	ming_pai = {
-- 		{
-- 			tile = 6,
-- 			type = SECTION_TYPE.PENG,
-- 		},
-- 		{
-- 			tile = 27,
-- 			type = SECTION_TYPE.PENG,
-- 		}
-- 	},
-- }

-- local test_hu = rule.hu(test_pai,nil,27)

-- log.dump(test_hu)

return rule