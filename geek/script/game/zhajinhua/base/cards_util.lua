
local log = require "log"

local def = require "game.zhajinhua.base.define"

local CARDS_TYPE = def.CARDS_TYPE

local utils = {}

local function card_value(card)
    return card % 20
end

local function card_color(card)
    return math.floor(card / 20 + 0.00000001)
end

utils.value = card_value
utils.color = card_color

-- 得到牌类型
function utils.get_cards_type(cards)
	assert(#cards == 3,"utils.get_cards_type got wrong number cards [%s].",table.concat(cards or {},","))

	local valuegroup = table.group(cards,card_value)
	local valuecards = table.map(valuegroup,function(g,v) return v,table.series(g) end)
	local valuecolors = table.map(valuecards,function(cs,v) return v,table.series(cs,card_color) end)
	local countvalues = table.map(
		table.group(valuegroup,function(g) return table.nums(g) end),
		function(g,c) return c,table.keys(g) end
	)

	local colorgroup = table.group(cards,function(c) return card_color(c) end)
	local colorcards = table.map(colorgroup,function(g,v) return v,table.series(g) end)

	-- 豹子
	if countvalues[3] and #countvalues[3] > 0 then
		return {
			type = CARDS_TYPE.BAO_ZI,
			vals = {
				[3] = countvalues[3],
			},
			colors = valuecolors,
		}
	end

	-- 对子
	if countvalues[2] and #countvalues[2] > 0 then
		table.sort(valuecolors[countvalues[2][1]],function(l,r) return l < r end)
		return {
			type = CARDS_TYPE.DOUBLE,
			vals = {
				[2] = countvalues[2],
				[1] = countvalues[1],
			},
			colors = valuecolors,
		}
	end

	local is_shun_zi
	if countvalues[1] and #countvalues[1] == 3 then
		local vals = countvalues[1]
		table.sort(vals)
		if (vals[1] + 1 == vals[2] and vals[2] + 1 == vals[3]) or 
			(vals[1] == 2 and vals[2] == 3 and vals[3] == 14) then
			is_shun_zi = true
		end
	end

	local is_same_color = table.logic_or(colorcards,function(cs) return #cs == 3 end)

	if is_same_color then
		return is_shun_zi and { -- 顺金
			type = CARDS_TYPE.SHUN_JIN,
			vals = {
				[1] = countvalues[1]
			},
			colors = valuecolors,
		} or { -- 金花
			type = CARDS_TYPE.JIN_HUA,
			vals = {
				[1] = countvalues[1],
			},
			colors = valuecolors,
		}
	end

	if is_shun_zi then
		return {
			type = CARDS_TYPE.SHUN_ZI,
			vals = {
				[1] = countvalues[1],
			},
			colors = valuecolors,
		}
	end

	if 	countvalues[1][1] == 2 and 
		countvalues[1][2] == 3 and 
		countvalues[1][3] == 5 then
		return {
			type = CARDS_TYPE.CT235,
			vals = {
				[1] = countvalues[1],
			},
			colors = valuecolors,
		}
	end

	return {
		type = CARDS_TYPE.SINGLE,
		vals = {
			[1] = countvalues[1],
		},
		colors = valuecolors,
	}
end

local function single_full_compare_vals(lvals,rvals)
	if lvals[1][3] > rvals[1][3] then 
		return 1 
	elseif lvals[1][3] < rvals[1][3] then
		return -1
	end

	if lvals[1][2] > lvals[1][2] then 
		return 1 
	elseif lvals[1][2] < lvals[1][2] then
		return -1
	end

	if lvals[1][1] > rvals[1][1] then
		return 1
	elseif lvals[1][1] < rvals[1][1] then
		return -1
	end
	
	return -1
end

function utils.compare(left,right,with_color)
	local lt,rt = left.type,right.type
	if lt ~= rt then
		return lt > rt
	end

	local lvals,rvals = left.vals,right.vals
	local lcolors,rcolors = left.colors,right.colors

	if lt == CARDS_TYPE.BAO_ZI then
		return lvals[3][1] > rvals[3][1]
	end

	local comp

	if lt == CARDS_TYPE.SHUN_ZI or lt == CARDS_TYPE.SHUN_JIN  then
		if lvals[1][3] > rvals[1][3] then
			comp = 1
		elseif lvals[1][3] < rvals[1][3] then
			comp = -1
		elseif lvals[1][2] > rvals[1][2] then
			comp = 1
		elseif lvals[1][2] < rvals[1][2] then
			comp = -1
		elseif lvals[1][1] > rvals[1][1] then
			comp = 1
		elseif lvals[1][1] < rvals[1][1] then
			comp = -1
		else
			comp = 0
		end
	end

	if lt == CARDS_TYPE.JIN_HUA  then
		comp = single_full_compare_vals(lvals,rvals)
	end

	if comp == 0 then
		if with_color then return lcolors[lvals[1][3]][1] < rcolors[rvals[1][3]][1] end
		return false
	end

	if lt == CARDS_TYPE.DOUBLE then
		comp = -1
		if lvals[2][1] > rvals[2][1] then comp = 1 end
		if lvals[2][1] == rvals[2][1] then
			if lvals[1][1] > rvals[1][1] then comp = 1 end
			if lvals[1][1] < rvals[1][1] then comp = -1 end
			comp = 0
		end
		if comp == 0 then
			if with_color then 
				return lcolors[lvals[2][1]][1] < rcolors[rvals[2][1]][1] 
			end
			return false
		end
	end

	if lt == CARDS_TYPE.SINGLE then
		comp = single_full_compare_vals(lvals,rvals)
		if comp == 0 then
			if with_color then return lcolors[lvals[1][3]][1] < rcolors[rvals[1][3]][1] end
			return false
		end
	end

	return comp > 0
end

-- local lt = utils.get_cards_type({7,22,6})
-- log.dump(lt)

-- local rt = utils.get_cards_type({14,5,42})
-- log.dump(rt)

-- local comp = utils.compare(lt,rt,true)
-- log.dump(comp)

return utils