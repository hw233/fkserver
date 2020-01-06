local def = require "game.maajan_customized.base.define"
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
			sections[section_index] = {area = TILE_AREA.SHOU_TILE, type = SECTION_TYPE.LEFT_CHI,tile = tile,}
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

local function ting_qi_dui(state)
	local count_tiles = table.fill(nil,{},1,4)
	for tile,c in pairs(state.counts) do
		if c > 0 then
			table.insert(count_tiles[c],tile)
		end
	end

	local even_count = #count_tiles[2] + #count_tiles[4]
	if count_tiles[1] == 1 and even_count == 6 then
		return count_tiles[1][1]
	end

	if count_tiles[3] == 1 and even_count == 5 then
		return count_tiles[3][1]
	end
	
	return nil
end

local function is_qi_dui(state)
	local dui_zi_count = table.sum(state.counts,function(c)
		return c == 4 and 2 or c == 2 and 1 or 0
	end)

	return dui_zi_count == 7
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


function rule.is_hu(pai,in_pai)
	local cache = {}
	for i=1,50 do
		cache[i] = pai.shou_pai[i] or 0
	end
	if in_pai then table.incr(cache,in_pai) end
	local state = {
		sections = {},
		counts = cache,
	}
	return is_hu(state) or is_qi_dui(state)
end

local function unique_hu_types(base_hu_types)
	local types = {}
	for unique_t,s in pairs(UNIQUE_HU_TYPE) do
		if table.logic_and(s,function(v) return base_hu_types[v] ~= nil end) then
			types[unique_t] = true
		end
	end

	return types
end

local function calculate_hu_types(pai,cache,sections)
	local base_types = {}

	if table.sum(cache) == 2 then
		base_types[HU_TYPE.DAN_DIAO_JIANG] = true
	end

	local shou_counts = clone(cache)
	local ming_counts = table.fill(nil,0,1,50)
	local ming_men_counts = table.fill(nil,0,0,5)
	local shou_men_counts = table.fill(nil,0,0,5)

	for tile,c in pairs(cache) do
		table.incr(shou_men_counts,rule.tile_men(tile),c)
	end

	for _,s in pairs(pai.ming_pai) do
		local tiles = SECTION_TILES[s.type](s)
		for _,tile in pairs(tiles) do
			table.incr(ming_counts,tile)
			table.incr(ming_men_counts,rule.tile_men(tile))
		end
	end

	local tile_counts = table.merge(ming_counts,shou_counts,function(l,r) return l + r end)
	local men_counts = table.merge(ming_men_counts,shou_men_counts,function(l,r) return l + r end)

	local four_tong_list = {}
	local three_tong_list = {}
	local shun_zi_list = {}
	for _,v in ipairs(sections) do
		if v.type == SECTION_TYPE.AN_GANG or v.type == SECTION_TYPE.MING_GANG or v.type == SECTION_TYPE.BA_GANG then
			table.insert(four_tong_list,v)
		elseif v.type == SECTION_TYPE.PENG then
			table.insert(three_tong_list,v)
		elseif v.type == SECTION_TYPE.CHI or v.type == SECTION_TYPE.LEFT_CHI or
			v.type == SECTION_TYPE.MID_CHI or v.type == SECTION_TYPE.RIGHT_CHI then
			table.insert(shun_zi_list,v)
		end
	end

	if #shun_zi_list == 0 then
		base_types[HU_TYPE.DA_DUI_ZI] = true
	end

	local total_mens = table.sum(men_counts,function(c,men) 
		if c > 0 and men < 3 then return 1
		else return 0 end
	end)
	if total_mens == 1 then
		base_types[HU_TYPE.QING_YI_SE] = true
	end

	if table.nums(base_types) == 0 then
		base_types[HU_TYPE.PING_HU] = true
	end

	return base_types
end

local function unique_types_id(ts)
	return table.concat(table.keys(ts),",")
end

local function merge_same_type(alltypes)
	local types = {}
	for _,ts in pairs(alltypes) do
		types[unique_types_id(ts)] = ts
	end

	return table.values(types)
end

function rule.hu(pai,inPai)
	local cache = {}
	for i = 1,50 do cache[i] = pai.shou_pai[i] or 0 end
	if inPai then table.incr(cache,inPai) end
	
	--一万到九万，一筒到九筒，一条到九条， 东-南-西-北  -中-发-白-   春-夏-秋-冬-梅-兰-竹-菊--
	--1-9		  11-19  	21-29 		 	31-34		35-37		41-48
	
	local state = { hu = {}, sections = {}, counts = clone(cache) }

	hu(state)

	local alltypes = {}

	local base_types = {}
	local qi_dui = is_qi_dui(state)
	if table.nums(state.hu) == 0 and not qi_dui then
		base_types[HU_TYPE.WEI_HU] = true
		return {base_types}
	end

	if qi_dui then
		if cache[inPai] == 4 then
			base_types[HU_TYPE.LONG_QI_DUI] = true
			table.insert(alltypes,base_types)
		else
			base_types[HU_TYPE.QI_DUI] = true
			table.insert(alltypes,base_types)
		end
	end

	for _,sections in pairs(state.hu) do
		local types = calculate_hu_types(pai,cache,sections)
		table.insert(alltypes,types)
	end

	alltypes = merge_same_type(alltypes)

	return alltypes
end

function rule.ting_tiles(shou_pai)
	local cache = {}
	for i = 1,50 do cache[i] = shou_pai[i] or 0 end
	local state = { feed_tiles = {}, counts = cache }
	ting(state)
	local qi_dui_tile = ting_qi_dui(state)
	local tiles = state.feed_tiles
	if qi_dui_tile then tiles[qi_dui_tile] = true end
	return tiles
end

--未摸牌判听
function rule.ting(pai)
	return rule.ting_tiles(pai.shou_pai)
end

--全部牌判听
function rule.ting_full(pai)
	local counts = clone(pai.shou_pai)
	local discard_then_ting_tiles = {}
	for tile,c in pairs(counts) do
		if c > 0 then
			table.decr(counts,tile)
			local tiles = rule.ting_tiles(counts)
			if table.nums(tiles) > 0 then
				discard_then_ting_tiles[tile] = tiles
			end
			table.incr(counts,tile)
		end
	end

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


-- local tiles = {13,14,15,19,21,22,23,23,23,24,24,25,26,15}
-- local counts = table.fill(nil,0,1,30)
-- for _,tile in pairs(tiles) do
-- 	counts[tile] = counts[tile] + 1
-- end

-- local test = rule.ting_full({
-- 	shou_pai = counts,
-- 	ming_pai = {{
-- 		type = SECTION_TYPE.PENG,
-- 		tile = 3,
-- 	}},
-- },1)

return rule