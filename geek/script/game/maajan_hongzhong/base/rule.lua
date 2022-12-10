local def = require "game.maajan_hongzhong.base.define"
require "functions"
local log = require "log"

local TY_VALUE = 35
local maajian_is_hu = require "game.maajan_hongzhong.base.maajian_is_hu"
local is_hu = maajian_is_hu.is_hu
local rule 			= {}

function rule.tile_value(v)
	return v % 10
end

function rule.tile_men(v)
	return v == TY_VALUE and 4 or math.floor(v / 10)
end


local SECTION_TYPE = def.SECTION_TYPE

local function ting(state)
	for k = 1,29 do 
		if k ~= 10 and k ~= 20  then
			table.incr(state.counts,k)
			if is_hu(state) then 
				state.feed_tiles[k] =true
			end
			table.decr(state.counts,k)
		end 
	end
	-- 红中
	table.incr(state.counts,35)
	if is_hu(state) then 
		state.feed_tiles[35] =true
	end
	table.decr(state.counts,35)
end

local function ting_qi_dui(counts)
	local qi_dui_tiles = {}
	if table.sum(counts) ~= 13 then 
		return qi_dui_tiles 
	end 
	local curcounts = clone(counts)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	count_tiles[1] = count_tiles[1] or {}
	count_tiles[2] = count_tiles[2] or {}
	if count_tiles[3]  and #count_tiles[3]>0 then 
		for _, value in ipairs(count_tiles[3] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[1],value)
		end
		count_tiles[3] = nil
	end 
	if count_tiles[4]  and #count_tiles[4]>0 then 
		for _, value in ipairs(count_tiles[4] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[2],value)
		end
		count_tiles[4] =nil
	end 
	local two_count = count_tiles[2] and #count_tiles[2] or 0
	local one_count = count_tiles[1] and #count_tiles[1] or 0
	local need_count = 7 - two_count 
	local for_num =    ty_num >one_count and  one_count or ty_num
	if one_count >0 and ty_num >0 then 
		for i = 1, for_num, 1 do
			one_count = one_count -1
			need_count = need_count - 1
		end
	end 
	if (ty_num - for_num) == 0  and need_count == one_count  and need_count ==1 then 
		for _, value in pairs(count_tiles[1]) do
			table.insert(qi_dui_tiles,value)
		end
		table.insert(qi_dui_tiles,TY_VALUE)
	end 
	if one_count == 0  and (ty_num - for_num)+1   == need_count*2  then 
		for i = 1, 29, 1 do
			if i ~= 10  and i~=20 then 
				table.insert(qi_dui_tiles,i)
			end 
		end
		table.insert(qi_dui_tiles,35)
	end 
	return qi_dui_tiles
end

local function ting_si_dui(counts)
	local si_dui_tiles = {}
	if table.sum(counts) ~= 7 then 
		return false 
	end
	local curcounts = clone(counts)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	count_tiles[1] = count_tiles[1] or {}
	count_tiles[2] = count_tiles[2] or {}
	if count_tiles[3]  and #count_tiles[3]>0 then 
		for _, value in ipairs(count_tiles[3] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[1],value)
		end
		count_tiles[3] = nil
	end 
	if count_tiles[4]  and #count_tiles[4]>0 then 
		for _, value in ipairs(count_tiles[4] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[2],value)
		end
		count_tiles[4] =nil
	end 
	local two_count = count_tiles[2] and #count_tiles[2] or 0
	local one_count = count_tiles[1] and #count_tiles[1] or 0
	local need_count = 4 - two_count 
	local for_num =    ty_num >one_count and  one_count or ty_num
	if one_count >0 and ty_num >0 then 
		for i = 1, for_num, 1 do
			one_count = one_count -1
			need_count = need_count - 1
		end
	end 
	if (ty_num - for_num) == 0  and need_count == one_count  and need_count ==1 then 
		for _, value in pairs(count_tiles[1]) do
			table.insert(si_dui_tiles,value)
		end
		table.insert(si_dui_tiles,TY_VALUE)
	end 
	if one_count == 0  and (ty_num - for_num)+1   == need_count*2  then 
		for i = 1, 29, 1 do
			if i ~= 10  and i~=20 then 
				table.insert(si_dui_tiles,i)
			end 
		end
	end 
	return si_dui_tiles
end

local function is_qi_dui(counts)
	if table.sum(counts) ~= 14 then 
		return false 
	end 
	local curcounts = clone(counts)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	count_tiles[1] = count_tiles[1] or {}
	count_tiles[2] = count_tiles[2] or {}
	if count_tiles[3]  and #count_tiles[3]>0 then 
		for _, value in ipairs(count_tiles[3] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[1],value)
		end
		count_tiles[3] = nil
	end 
	if count_tiles[4]  and #count_tiles[4]>0 then 
		for _, value in ipairs(count_tiles[4] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[2],value)
		end
		count_tiles[4] =nil
	end 
	local two_count = count_tiles[2] and #count_tiles[2] or 0
	local one_count = count_tiles[1] and #count_tiles[1] or 0
	local need_count = 7 - two_count 
	local for_num =    ty_num >one_count and  one_count or ty_num
	if one_count >0 and ty_num >0 then 
		for i = 1, for_num, 1 do
			one_count = one_count -1
			need_count = need_count - 1
		end
	end 
	if need_count == 0 or  need_count == (ty_num -for_num)/2 then 
		return true
	end 

	return  false 
end

local function is_si_dui(counts)
	if table.sum(counts) ~= 8 then 
		return false 
	end 
	local curcounts = clone(counts)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	count_tiles[1] = count_tiles[1] or {}
	count_tiles[2] = count_tiles[2] or {}
	if count_tiles[3]  and #count_tiles[3]>0 then 
		for _, value in ipairs(count_tiles[3] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[1],value)
		end
		count_tiles[3] = nil
	end 
	if count_tiles[4]  and #count_tiles[4]>0 then 
		for _, value in ipairs(count_tiles[4] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[2],value)
		end
		count_tiles[4] =nil
	end 
	local two_count = count_tiles[2] and #count_tiles[2] or 0
	local one_count = count_tiles[1] and #count_tiles[1] or 0
	local need_count = 4 - two_count 
	local for_num =    ty_num >one_count and  one_count or ty_num
	if one_count >0 and ty_num >0 then 
		for i = 1, for_num, 1 do
			one_count = one_count -1
			need_count = need_count - 1
		end
	end 
	if need_count == 0 or  need_count == (ty_num -for_num)/2 then 
		return true
	end 

	return  false 
end




local HU_TYPE = def.HU_TYPE
local UNIQUE_HU_TYPE = def.UNIQUE_HU_TYPE


function rule.is_hu(pai,in_pai,with_si_dui,ke_qi_dui)
	local cache = {}
	for i=1,35 do
		cache[i] = pai.shou_pai[i] or 0
	end
	if in_pai then table.incr(cache,in_pai) end
	local state = {counts = cache}
	local can_hu = is_hu(state)
	local qi_dui = ke_qi_dui and is_qi_dui(cache) or false
	local si_dui = with_si_dui and is_si_dui(cache)

	return can_hu or qi_dui or si_dui
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
		return c == 0 or (num == 2 or num == 5 or num == 8) or tile == TY_VALUE 
	end)
	local is_ming_258 = table.logic_and(pai.ming_pai,function(s)
		local num = rule.tile_value(s.tile)
		return num == 2 or num == 5 or num == 8
	end)

	return is_shou_258 and is_ming_258
end



local function is_duan_yao(pai,in_pai)
	local is_19 = table.logic_or(pai.shou_pai,function(c,tile)
		local num = rule.tile_value(tile)
		return c > 0 and (num == 1 or num == 9) and tile~= TY_VALUE
	end) or (table.nums(pai.ming_pai) > 0 and table.logic_or(pai.ming_pai,function(s)
		local num = rule.tile_value(s.tile)
		return num == 1 or num == 9
	end)) or (in_pai and   in_pai~= TY_VALUE and 
		(rule.tile_value(in_pai) == 1 or rule.tile_value(in_pai) == 9)
	)

	return not is_19
end

local function gou_count_wutiyong(pai,cache)
	local shou_gou  ,ming_gou = 0,0
	shou_gou = table.sum(cache,function(c) return c == 4 and 1 or 0 end)
	ming_gou = table.sum(pai.ming_pai,function(s) return ((s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.RUANPENG) and cache[s.tile] == 1) and 1 or 0 end)
	return shou_gou + ming_gou
end
local function get_ty_can_gou_list(pai,cache,tynum)
	local ty_can_shougou_list = {}
	local ty_can_minggou_list = {}
	for tile, c in pairs(cache) do
		if c== 4-tynum then
			table.insert(ty_can_shougou_list,tile)
		end
	end
	if  tynum==1 then 
		for _, s in pairs(pai.ming_pai) do
			if (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.RUANPENG) and  (not cache[s.tile] or  cache[s.tile]==0 )  then 
				table.insert(ty_can_minggou_list,s.tile)
			end 
		end
	end 
	return table.merge_back(ty_can_shougou_list,ty_can_minggou_list)
end 
local function gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
	local gou_num = 0 
	local curlen = #ty_can_gou_list
	if ty_num == 2 then 
		if gou_num == 0 and curlen >=1  then  --1刻 加1TY 
			table.incr(state.counts,TY_VALUE)
			for i = 1, #ty_can_gou_list, 1 do
				table.incr(state.counts,ty_can_gou_list[i])
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num 
				else
					table.decr(state.counts,ty_can_gou_list[i])
				end
			end
			table.decr(state.counts,TY_VALUE)
		end
		if gou_num == 0 then  --1对 加2TY 
			local ty_can_gou_list_dui =  get_ty_can_gou_list(pai,state.counts,2)
			for i = 1, #ty_can_gou_list_dui, 1 do
				table.incr(state.counts,ty_can_gou_list_dui[i],2)
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num
				else
					table.decr(state.counts,ty_can_gou_list_dui[i],2)
				end
			end
		end
	elseif ty_num == 3 then
		if curlen >=2 then   --2刻 加2TY 
			table.incr(state.counts,TY_VALUE)
			for i = 1, #ty_can_gou_list-1, 1 do
				for j = i+1, #ty_can_gou_list, 1 do
					table.incr(state.counts,ty_can_gou_list[i])
					table.incr(state.counts,ty_can_gou_list[j])
					if is_hu(state) then 
						gou_num = gou_count_wutiyong(pai,state.counts)
						return  gou_num
					else
						table.decr(state.counts,ty_can_gou_list[i])
						table.decr(state.counts,ty_can_gou_list[j])
					end
				end
			end
			table.decr(state.counts,TY_VALUE)
		end
		local ty_can_gou_list_dui =  get_ty_can_gou_list(pai,state.counts,2)
		if gou_num == 0 and curlen >=1 and #ty_can_gou_list_dui >0 then  --1刻1TY  1队2ty
			for i = 1, #ty_can_gou_list, 1 do
				for j = 1, #ty_can_gou_list_dui, 1 do
					table.incr(state.counts,ty_can_gou_list[i])
					table.incr(state.counts,ty_can_gou_list_dui[j],2)
					if is_hu(state) then 
						gou_num = gou_count_wutiyong(pai,state.counts)
						return  gou_num
					else
						table.decr(state.counts,ty_can_gou_list[i])
						table.decr(state.counts,ty_can_gou_list_dui[j],2)
					end
				end
			end
		end
		if gou_num == 0 and curlen >=1  then   --1刻1TY 
			table.incr(state.counts,TY_VALUE,2)
			for i = 1, #ty_can_gou_list, 1 do
				table.incr(state.counts,ty_can_gou_list[i])
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num 
				else
					table.decr(state.counts,ty_can_gou_list[i])
				end
			end
			table.decr(state.counts,TY_VALUE,2)
		end
		if gou_num == 0 and #ty_can_gou_list_dui >0 then  --1对2TY 
			table.incr(state.counts,TY_VALUE)
			for i = 1, #ty_can_gou_list_dui, 1 do
				table.incr(state.counts,ty_can_gou_list_dui[i],2)
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num 
				else
					table.decr(state.counts,ty_can_gou_list_dui[i],2)
				end
			end
			table.decr(state.counts,TY_VALUE)
		end
		if gou_num == 0 then  --1张 3TY
			local ty_can_gou_list_dan =  get_ty_can_gou_list(pai,state.counts,3)
			for i = 1, #ty_can_gou_list_dan, 1 do
				table.incr(state.counts,ty_can_gou_list_dan[i],3)
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num 
				else
					table.decr(state.counts,ty_can_gou_list_dan[i],3)
				end
			end
		end
	end 
	return gou_num
end 
local function gou_count_tiyong(pai,cache)
	local curcounts = clone(cache)
	local gou_num = 0 
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] =  nil 
	local ty_can_gou_list =  get_ty_can_gou_list(pai,curcounts,1)
	local ty_lenth = #ty_can_gou_list
	local state = { counts = curcounts }
	if ty_num == 1 then 
		if ty_lenth >0 then 
			for _, tile in pairs(ty_can_gou_list) do
				table.incr(state.counts,tile)
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num
				else
					table.decr(state.counts,tile)
				end
			end

		end 	
	else 
		if ty_lenth >= 0 then 
			if ty_lenth >= ty_num then 
				if ty_num == 2 then 
					for i = 1, ty_lenth-1, 1 do --2刻 加2TY 
						for j = i+1, ty_lenth, 1 do
							table.incr(state.counts,ty_can_gou_list[i])
							table.incr(state.counts,ty_can_gou_list[j])
							if is_hu(state) then 
								gou_num = gou_count_wutiyong(pai,state.counts)
								return  gou_num
							else
								table.decr(state.counts,ty_can_gou_list[i])
								table.decr(state.counts,ty_can_gou_list[j])
							end
						end
					end
					if gou_num == 0 then 
						gou_num=gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
					end
				elseif ty_num == 3 then 
					for i = 1, ty_lenth-2, 1 do  --3刻 加3TY 
						for j = i+1, ty_lenth, 1 do
							for k = i+2, ty_lenth, 1 do
								table.incr(state.counts,ty_can_gou_list[i])
								table.incr(state.counts,ty_can_gou_list[j])
								table.incr(state.counts,ty_can_gou_list[k])
								if is_hu(state) then 
									gou_num = gou_count_wutiyong(pai,state.counts)
									return  gou_num
								else
									table.decr(state.counts,ty_can_gou_list[i])
									table.decr(state.counts,ty_can_gou_list[j])
									table.decr(state.counts,ty_can_gou_list[k])
								end
							end 
						end
					end
					if gou_num == 0 then 
						gou_num=gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
					end
				end
			else 
				gou_num=gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
			end 
		else 
			gou_num=gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
		end 
	end 
	if gou_num == 0 then 
		table.incr(state.counts,TY_VALUE,ty_num)
		if is_hu(state) then 
			gou_num = gou_count_wutiyong(pai,state.counts)
			return  gou_num
		else
			table.decr(state.counts,TY_VALUE,ty_num)
		end
	end
	return gou_num
end

local function gou_count_tiyong_qidui(cache)
	local curcounts = clone(cache)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	local one_count = count_tiles[1] and #count_tiles[1] or 0
	local two_count = count_tiles[2] and #count_tiles[2] or 0
	local three_count = count_tiles[3] and #count_tiles[3] or 0
	local gen_count = count_tiles[4] and #count_tiles[4] or 0
	if one_count >0 then 
		ty_num = ty_num - one_count
	end 
	if three_count >0 then 
		ty_num = ty_num - three_count
		gen_count = gen_count+three_count
	end 
	if ty_num >0 and two_count >0 and  ty_num%2 ==0 and ty_num/2 <= two_count  then 
		gen_count = gen_count+ty_num/2
	end 
	return  gen_count 
end 
-- flags 1 qidui 2 sidui 3 daduizi
local function gou_count(pai,cache,flags,ji_num)
	local ty_num = cache[TY_VALUE] or 0
	local gou_num = 0
	if ty_num ==0 then 
		gou_num = gou_count_wutiyong(pai,cache)
	else 
		if flags  == 1 then 
			gou_num= gou_count_tiyong_qidui(cache)
		elseif  flags  == 2 then 
			gou_num = gou_count_tiyong_qidui(cache)
		elseif  flags  == 3 then 
			gou_num = 0
		else
			if ji_num == 4 then  --4鸡顶翻不用算根
				gou_num = 0
			else 
				gou_num = gou_count_tiyong(pai,cache)
			end 
		end 
	end 
	return gou_num
end
local function ji_count(pai,cache)
	local shou_ji =  cache[TY_VALUE] or 0
	local ming_ji = table.sum(pai.ming_pai,function(s) return (s.type ~= SECTION_TYPE.PENG ) and s.substitute_num or 0 end)

	return shou_ji + ming_ji
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
		table.logic_and(pai.ming_pai,function(s) return s.type == SECTION_TYPE.AN_GANG or s.type == SECTION_TYPE.RUAN_AN_GANG end)
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

local function get_hu_types(cache)
	local base_types = {}
	local curcounts = clone(cache)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	count_tiles[1] = count_tiles[1] or {}
	count_tiles[3] = count_tiles[3] or {}
	if count_tiles[4]  and #count_tiles[4]>0 then 
		for _, value in ipairs(count_tiles[4] ) do
			table.insert(count_tiles[3],value)
			table.insert(count_tiles[1],value)
		end
		count_tiles[4] =nil
	end
	-- log.dump(count_tiles,"count_tiles")
	local two_count = count_tiles[2] and #count_tiles[2] or 0
	local one_count = count_tiles[1] and #count_tiles[1] or 0	
	local ke_zi_bj =false 
	-- log.info("one_count %d,two_count %d,ty_num %d,",one_count,two_count,ty_num)
	if one_count == 0 and two_count == 0 and ty_num == 2 then
		ke_zi_bj = true 
	end
	if not ke_zi_bj and ((one_count == 0 and two_count-ty_num ==1 ) or (two_count == 0 and one_count-ty_num ==0)) then
		ke_zi_bj = true 
	end
	if  not ke_zi_bj and two_count ~= 0 and one_count ~= 0   then
		local curty_num = ty_num
		local curtwo_count = two_count
		for i = 1, two_count-1, 1 do
			curty_num = curty_num -1
			curtwo_count = curtwo_count -1
		end
		if curtwo_count == 1 and  curty_num >=0 and curty_num == one_count*2 and (curty_num + one_count)%3 == 0 then
			ke_zi_bj = true 
		end
	end
	if not ke_zi_bj and one_count == 0 and two_count == 1 and ty_num >= 3  then
		ke_zi_bj = true 
	end
	if not ke_zi_bj and (one_count == 2 and two_count == 0 and ty_num == 3) then
		ke_zi_bj = true 
	end
	if ke_zi_bj then
		--if is_2_5_8(pai,cache) then
			--base_types[HU_TYPE.JIANG_DUI] = 1
		--else
			base_types[HU_TYPE.DA_DUI_ZI] = 1
		--end
	end
	--if is_all_1_9(pai) then
	---	base_types[HU_TYPE.QUAN_YAO_JIU] = 1
	--end

	-- if table.nums(base_types) == 0 then
		base_types[HU_TYPE.PING_HU] = 1
	-- end

	return base_types
end

function rule.get_ty()
	return TY_VALUE
end 
function rule.hu(pai,in_pai,mo_pai,si_dui,ke_qi_dui)
	local cache = {}
	for i = 1,35 do cache[i] = pai.shou_pai[i] or 0 end
	if in_pai then table.incr(cache,in_pai) end
	
	-- 一万到九万，一筒到九筒，一条到九条， 东-南-西-北  -中-发-白-   春-夏-秋-冬-梅-兰-竹-菊--
	-- 1-9		   11-19  	  21-29 	   31-34		 35-37		 41-48
	
	local state = {  counts = clone(cache) }
	if is_hu(state) then state.hu  = true  end 
	local alltypes = {}

	local qi_dui = ke_qi_dui and is_qi_dui(cache)
	local si_dui = is_si_dui(cache)
	if not state.hu and not qi_dui and not si_dui then
		return {{[HU_TYPE.WEI_HU] = 1}}
	end

	local qing_yi_se = is_qing_yi_se(pai,cache)
	-- local men_qing =  is_men_qing(pai)
	-- local duan_yao = is_duan_yao(pai,in_pai)
	local gou = 0 
	local ji_num  = ji_count(pai,cache)
	if qi_dui then
		local base_types = {}
		-- gou = gou_count(pai,cache,1,ji_num)
		-- if gou > 0 then
		-- 	base_types[HU_TYPE.LONG_QI_DUI] = 1
		-- else
		-- 	base_types[HU_TYPE.QI_DUI] = 1
		-- end
		base_types[HU_TYPE.QI_DUI] = 1
		base_types[HU_TYPE.PING_HU] = 1
		if qing_yi_se then base_types[HU_TYPE.QING_YI_SE] = 1 end
		-- if duan_yao then base_types[HU_TYPE.DUAN_YAO] = 1 end
		-- if men_qing then base_types[HU_TYPE.MEN_QING] = 1 end
		if ji_num ==0 then base_types[HU_TYPE.WU_JI] = 1 end
		-- if ji_num ==4 then base_types[HU_TYPE.SI_JI] = 1 end
		table.insert(alltypes,base_types)
	end

	-- if si_dui then
	-- 	local base_types = {}
	-- 	-- gou = gou_count(pai,cache,2,ji_num)
	-- 	-- if gou > 0 then
	-- 	-- 	base_types[HU_TYPE.LONG_SI_DUI] = 1
	-- 	-- else
	-- 	-- 	base_types[HU_TYPE.SI_DUI] = 1
	-- 	-- end
	-- 	base_types[HU_TYPE.SI_DUI] = 1
	-- 	if qing_yi_se then base_types[HU_TYPE.QING_YI_SE] = 1 end
	-- 	-- if duan_yao then base_types[HU_TYPE.DUAN_YAO] = 1 end
	-- 	-- if men_qing then base_types[HU_TYPE.MEN_QING] = 1 end
	-- 	if ji_num ==0 then base_types[HU_TYPE.WU_JI] = 1 end
	-- 	-- if ji_num ==4 then base_types[HU_TYPE.SI_JI] = 1 end
	-- 	table.insert(alltypes,base_types)
	-- end
	if state.hu then 
		local common_types = {}
		-- if duan_yao then common_types[HU_TYPE.DUAN_YAO] = 1 end
		-- if men_qing then common_types[HU_TYPE.MEN_QING] = 1 end
		if qing_yi_se then common_types[HU_TYPE.QING_YI_SE] = 1 end
		if ji_num ==0 then common_types[HU_TYPE.WU_JI] = 1 end
		-- if ji_num ==4 then common_types[HU_TYPE.SI_JI] = 1 end
		local types = get_hu_types(cache)
		-- gou = gou_count(pai,cache,(types[HU_TYPE.JIANG_DUI] or types[HU_TYPE.DA_DUI_ZI]) and 3 or -1,ji_num )
		-- if gou > 0 then common_types[HU_TYPE.DAI_GOU] = gou end
		-- local sum = table.sum(pai.shou_pai)
		-- local ty_num = pai.shou_pai[TY_VALUE] or 0 
		-- if (sum == 1 and  (pai.shou_pai[in_pai] == 1 or in_pai == TY_VALUE or ty_num == 1 ))or
		-- 	(sum == 2 and not in_pai and (table.logic_or(pai.shou_pai,function(c,_) return c == 2 end) or ty_num >= 1 )) then
		-- 	common_types[HU_TYPE.DAN_DIAO_JIANG] = 1
		-- end

		table.mergeto(types,common_types,function(l,r) return (l or 0) + (r or 0) end)

		table.insert(alltypes,types)
	end 
	-- log.dump(alltypes,"alltypes1111")
	-- for i = 1,#alltypes do
	-- 	alltypes[i] = unique_hu_types(alltypes[i])
	-- end
	
	alltypes = merge_same_type(alltypes)
	-- log.dump(alltypes,"alltypes2222")
	
	return alltypes
end

function rule.ting_tiles(pai,si_dui,qi_dui)
	local cache = {}
	for i = 1,35 do cache[i] = pai.shou_pai[i] or 0 end
	local state = { feed_tiles = {}, counts = cache }
	ting(state)
	local qi_dui_tiles = qi_dui and ting_qi_dui(cache)
	local tiles = state.feed_tiles
	if table.sum(qi_dui_tiles) >0 then
		for _, value in pairs(qi_dui_tiles) do
			tiles[value] = true 
		end
	end
	if si_dui then 
		local si_dui_tile = ting_si_dui(cache)
		if table.sum(si_dui_tile) >0 then
			for _, value in pairs(si_dui_tile) do
				tiles[value] = true 
			end
		end
	end
	return tiles
end

--未摸牌判听
function rule.ting(pai,si_dui,qi_dui)
	return rule.ting_tiles(pai,si_dui,qi_dui)
end

--全部牌判听
function rule.ting_full(pai,si_dui,qi_dui)
	local all_pai = clone(pai)
	local discard_then_ting_tiles = table.map(all_pai.shou_pai,function(c,tile)
		if c <= 0 or tile == TY_VALUE then return end
		table.decr(all_pai.shou_pai,tile)
		local tiles = rule.ting_tiles(all_pai,si_dui,qi_dui)
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