
--高倍场牛牛(1赔10)游戏逻辑

local def = require "game.oxp.define"

local log = require "log"

local CARDS_TYPE = def.CARDS_TYPE
local math = math
local mfloor = math.floor
local table = table
local tinsert = table.insert
local mabs = math.abs
local tsort = table.sort

-- 得到牌大小
local function get_value(card)
	return card % 20
end

local function get_ox_value(card)
	local v = get_value(card)
	return v >= 10 and 10 or v
end

-- 得到牌花色
local function get_color(card)
	return mfloor(card / 20)
end

local function ox_type(two_value)
	local v = two_value % 10
	return v == 0 and CARDS_TYPE.OX_10 or v + CARDS_TYPE.OX_NONE
end

local function sorted_pair_values(p)
	local cards = {}
	for _,i in pairs(p) do
		for _,c in pairs(i) do
			tinsert(cards,c)
		end
	end

	tsort(cards,function(l,r) 
		local lv,rv = get_value(l),get_value(r)
		if rv ~= lv then 
			return lv > rv 
		end
		return get_color(l) < get_color(r)
	end)
	return cards
end

local function compare(l,r)
	if l.type ~= r.type then
		return l.type > r.type
	end
	
	local lcards = sorted_pair_values(l.pair)
	local rcards = sorted_pair_values(r.pair)
	local lc1,rc1 = lcards[1],rcards[1]
	local lc5,rc5 = lcards[5],rcards[5]
	local lv,rv = get_value(lc1),get_value(rc1)
	local lv5,rv5 = get_value(lc5),get_value(rc5)

	if l.type == r.type and (l.type == CARDS_TYPE.OX_TONGHUASHUN or l.type == CARDS_TYPE.OX_SHUNZI)  then
		if lv == rv and lv ==13 then
			if lv == 13 and lv5 ==1 and rv==13  and rv5 ==1  then
				local ls,rs = get_color(lv5),get_color(rv5)
				return ls<rs
			end
			if lv == 13 and lv5 ==1 and rv==13  and rv5 ~=1  then
				
				return true
			end
			if lv == 13 and lv5 ~=1 and rv==13  and rv5 ==1  then
				
				return false
			end
			local xxs,rrs = get_color(lc1),get_color(rc1)
			return xxs < rrs
		end
		return lv>rv
	end
	if lv ~= rv then
		return lv > rv
	end

	local lc,rc = get_color(lc1),get_color(rc1)
	return lc < rc
end

local function cards_type(cards,opt)
	local list = clone(cards)

	tsort(list,function(l,r) return get_value(l) > get_value(r) end)

	local values = table.series(list,get_value)
	local value_count = table.agg1(values,function(vcount,v)
		vcount[v] = (vcount[v] or 0) + 1
		return vcount
	end)

	local count_value = table.agg1(value_count,function(cvalue,n,v) 
		cvalue[n] = cvalue[n] or {}
		tinsert(cvalue[n],v)
		return cvalue
	end)

	local jinhua_ox = table.logic_and(values,function(v) return v > 10 end)
	local yinhua_ox = table.logic_and(values,function(v) return v >= 10 end)

	local color_count = table.agg(list,{},function(colors,v)
		local c = get_color(v)
		colors[c] = (colors[c] or 0) + 1
		return colors
	end)
	
	local same_color = table.nums(color_count) == 1
	local seq
	
	for _,v in pairs(values) do
		if seq and mabs(seq - v) ~= 1 then
			seq = nil
			break
		end

		seq = v
	end
	if #values==5 and values[1]== 13 and values[2]== 12 and values[3]== 11 and values[4]== 10 and values[5]== 1 then
		seq = 1
	end
	
	if opt[CARDS_TYPE.OX_TONGHUASHUN] and same_color and seq then
		return {
			type = CARDS_TYPE.OX_TONGHUASHUN,
			pair = {list},
		}
	end


	if 	opt[CARDS_TYPE.OX_SMALL_5] and 
		table.logic_and(values,function(v) return v < 5 end) and
		table.sum(values) <= 10 then
		return {
			type = CARDS_TYPE.OX_SMALL_5,
			pair = {list},
		}
	end

	if opt[CARDS_TYPE.OX_BOMB] and count_value[4] then
		return {
			type = CARDS_TYPE.OX_BOMB,
			pair = {list},
		}
	end



	if opt[CARDS_TYPE.OX_HULU] and count_value[3] and count_value[2] then
		return {
			type = CARDS_TYPE.OX_HULU,
			pair = {list},
		}
	end


	-- 五花牛
	if opt[CARDS_TYPE.OX_JINHUA] and jinhua_ox then
		return {
			type = CARDS_TYPE.OX_JINHUA,
			pair = {list},
		}
	end

	-- 四花牛
	if opt[CARDS_TYPE.OX_YINHUA] and yinhua_ox then
		return {
			type = CARDS_TYPE.OX_YINHUA,
			pair = {list},
		}
	end

	
	if opt[CARDS_TYPE.OX_TONGHUA] and same_color then
		return {
			type = CARDS_TYPE.OX_TONGHUA,
			pair = {list},
		}
	end

	if opt[CARDS_TYPE.OX_SHUNZI] and seq then
		return {
			type = CARDS_TYPE.OX_SHUNZI,
			pair = {list},
		}
	end

	local ox_values = table.series(list,get_ox_value)
	local types = {}
	for i=1,3 do
		local vi = ox_values[i]
		for j =i+1,4 do
			local vj = ox_values[j]
			for k=j+1,5 do
				local vk = ox_values[k]
				if (vi + vj + vk) % 10 == 0 then
					local triple = {list[i],list[j],list[k]}
					local two = {}
					for l=1,5 do
						if l ~=i and l ~=j and l~=k then
							tinsert(two,list[l])
						end
					end
					tinsert(types,{
						type = ox_type(table.sum(two,get_ox_value)),
						pair = {triple,two}
					})
				end
			end
		end
	end


	if #types == 0 then
		return {
			type = CARDS_TYPE.OX_NONE,
			pair = {list}
		}
	end

	tsort(types,compare)

	local t = types[1]
	return t
end

local function pair_type(pair,opt)
	if #pair < 2 and #pair[1] == 5 then
		return cards_type(pair[1],opt)
	end

	tsort(pair,function(l,r) return #l > #r end)

	local ox_v = table.series(pair,function(cards)
		return table.sum(cards,function(v) return get_ox_value(v) end)
	end)
	if ox_v[1] % 10 ~= 0 then
		return {
			type = CARDS_TYPE.NONE,
			pair = pair,
		}
	end
	
	return {
		type = ox_type(ox_v[2]),
		pair = pair,
	}
end

-- local opt = {
-- 	[CARDS_TYPE.OX_NONE] = 1,
-- 	[CARDS_TYPE.OX_1] = 1,
-- 	[CARDS_TYPE.OX_2] = 1,
-- 	[CARDS_TYPE.OX_3] = 1,
-- 	[CARDS_TYPE.OX_4] = 1,
-- 	[CARDS_TYPE.OX_5] = 1,
-- 	[CARDS_TYPE.OX_6] = 1,
-- 	[CARDS_TYPE.OX_7] = 1,
-- 	[CARDS_TYPE.OX_8] = 1,
-- 	[CARDS_TYPE.OX_9] = 1,
-- 	[CARDS_TYPE.OX_10] = 1,
-- 	[CARDS_TYPE.OX_SHUNZI] = 1,
-- 	[CARDS_TYPE.OX_TONGHUA] = 1,
-- 	[CARDS_TYPE.OX_YINHUA] = 1,
-- 	[CARDS_TYPE.OX_JINHUA] = 1,
-- 	[CARDS_TYPE.OX_HULU] = 1,
-- 	[CARDS_TYPE.OX_BOMB] = 1,
-- 	[CARDS_TYPE.OX_SMALL_5] = 1,
-- 	[CARDS_TYPE.OX_TONGHUASHUN] = 1,
-- }

-- local ct1 = cards_type({65,47,67,23,63},opt)
-- log.dump(ct1)
-- local ct2 = cards_type({62,12,45,30,21},opt)
-- log.dump(ct2)

-- log.dump(compare(ct1,ct2))

return {
	cards_type = cards_type,
	compare = compare,
	ox_type = ox_type,
	pair_type = pair_type,
}