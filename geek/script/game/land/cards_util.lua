local pb = require "pb_files"
local log = require "log"

local cards_util = {}

local LAND_CARD_TYPE = {
	SINGLE = pb.enum("DDZ_CARD_TYPE", "SINGLE"),
	DOUBLE = pb.enum("DDZ_CARD_TYPE", "DOUBLE"),
	THREE = pb.enum("DDZ_CARD_TYPE", "THREE"),
	THREE_WITH_ONE = pb.enum("DDZ_CARD_TYPE", "THREE_WITH_ONE"),
	THREE_WITH_TWO = pb.enum("DDZ_CARD_TYPE", "THREE_WITH_TWO"),
	FOUR_WITH_SINGLE = pb.enum("DDZ_CARD_TYPE", "FOUR_WITH_SINGLE"),
	FOUR_WITH_DOUBLE = pb.enum("DDZ_CARD_TYPE", "FOUR_WITH_DOUBLE"),
	SINGLE_LINE = pb.enum("DDZ_CARD_TYPE", "SINGLE_LINE"),
	DOUBLE_LINE = pb.enum("DDZ_CARD_TYPE", "DOUBLE_LINE"),
	PLANE = pb.enum("DDZ_CARD_TYPE", "PLANE"),
	PLANE_WITH_ONE = pb.enum("DDZ_CARD_TYPE", "PLANE_WITH_ONE"),
	PLANE_WITH_TWO = pb.enum("DDZ_CARD_TYPE", "PLANE_WITH_TWO"),
	BOMB = pb.enum("DDZ_CARD_TYPE", "BOMB"),
	FOUR_WITH_THREE = pb.enum("DDZ_CARD_TYPE", "FOUR_WITH_THREE"),
	MISSLE = pb.enum("DDZ_CARD_TYPE", "MISSLE"),
}

cards_util.LAND_CARD_TYPE = LAND_CARD_TYPE

-- 0:黑 1:红 2:梅 3:方

function cards_util.color(card)
	return math.floor(card / 20)
end

function cards_util.value(card)
	return math.floor(card % 20)
end

function cards_util.check(card)
	local color,value = cards_util.color(card),cards_util.value(card)
	return color >= 0 and color <= 5 and value > 0 and value < 16
end

-- 检查牌是否合法
function cards_util.check_cards(cards)
	return table.logic_and(cards,function(c) return cards_util.check(c) end)
end

local function full_combination(number)
	if number == 1 then return {{number}} end
	local numbers = full_combination(number - 1)
	local combos = {{number}}
	for _,nums in pairs(numbers) do
		table.insert(nums,1)
		table.insert(combos,nums)
	end
	return combos
end

local function seek_continuity_cards_count(valuecounts,begin,value_count,len)
	local sections = {}
	local function next_section(b,e)
		local n = 0
		for i = b,e do
			if not valuecounts[i] or valuecounts[i]< value_count or valuecounts[i] == 4 then
				return n
			end
			n = n + 1
			if len and n == len then return n end
		end

		return n
	end
	local i = begin
	while i <= 14 do
		local len = next_section(i,14)
		if len > 0 then
			table.insert(sections,{b = i,len = len})
		end
		i = i + len + 1
	end
	table.sort(sections,function(l,r) 
		if l.len > r.len then return true end
		if l.len == r.len then return l.b < r.b end
		return false
	end)
	if #sections > 0 then
		local top = sections[1]
		return top.len,top.b
	end

	return 0
end


local function pick_exactly(valuecards,count,val,excludes,try_includes)
	assert(count > 0 and valuecards[val] and #valuecards[val] >= count)

	local cards = {}
	local vcards = valuecards[val]
	log.dump(try_includes)
	if try_includes then
		for _,card in pairs(vcards) do
			if try_includes[card] and (not excludes or not excludes[card]) then
				table.insert(cards,card)
				if #cards == count then break  end
			end
		end
	end

	if #cards < count then  
		for _,card in pairs(vcards) do
			if (not try_includes or not try_includes[card]) and (not excludes or not excludes[card]) then
				table.insert(cards,card)
				if #cards == count then break  end
			end
		end
	end

	log.dump(cards)

	assert(cards and #cards == count)

	return cards
end


local function find_min_value_with_exactly_count(valuecards,count,excludes,try_includes)
	for i = 3,15 do
		if valuecards[i] and #valuecards[i] == count then
			repeat
				if excludes and table.nums(excludes) > 0 and 
					table.logic_or(valuecards[i],function(card) return excludes[card] end) then
					break
				end

				if try_includes and table.nums(try_includes) > 0 and 
					table.logic_and(valuecards[i],function(card) return not try_includes[card] end) then
					break
				end

				return i
			until true 
		end
	end
end

local function pick_min_combination_with_exactly_count(valuecards,combs,excludes,try_includes)
	local cards_combination = {}
	local comb_exlucdes = clone(excludes)
	for _,c in pairs(combs) do
		local val = find_min_value_with_exactly_count(valuecards,c,comb_exlucdes,try_includes)
		if not val then return end

		local cards = pick_exactly(valuecards,c,val,comb_exlucdes,try_includes)
		assert(#cards == c)
		table.mergeto(comb_exlucdes,
			table.map(cards,function(c) return c,true end),
			function(l,r) return l or r end
		)
		table.insert(cards_combination,cards)
	end

	local cards = table.union_tables(cards_combination)
	return cards
end

local function search_min_combination(valuecards,count,excludes,try_includes)
	local count_combinations = full_combination(count)
	table.sort(count_combinations,function(l,r) return #l > #r end)
	for _,comb in pairs(count_combinations) do
		local cards = pick_min_combination_with_exactly_count(valuecards,comb,excludes,try_includes)
		if cards then
			assert(#cards == count)
			return cards
		end
	end

	return nil
end


local function check_cards_repeat(cards)
	local cardsgroup = table.group(cards,function(c) return c end)
	local cardcounts = table.map(cardsgroup,function(cs,c) return c,table.nums(cs) end)
	return table.logic_or(cardcounts,function(n) return n > 1 end)
end

function cards_util.seek_great_than(kcards,ctype,cvalue,ccount,rule)
	local total_count = table.nums(kcards)
	local valuegroup = table.group(kcards,function(_,c) return cards_util.value(c) end)
	local valuecards =  table.map(valuegroup,function(cs,v)  return v,table.keys(cs) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)
	local countgroup =  table.group(valuecounts,function(c)  return c end)
	
	local pick_func = {
		[LAND_CARD_TYPE.SINGLE] = function(val) return pick_exactly(valuecards,1,val) end,
		[LAND_CARD_TYPE.DOUBLE] = function(val) return pick_exactly(valuecards,2,val) end,
		[LAND_CARD_TYPE.THREE] = function(val) return pick_exactly(valuecards,3,val) end,
		[LAND_CARD_TYPE.THREE_WITH_ONE] = function(val)
			local three = pick_exactly(valuecards,3,val)
			local one = search_min_combination(valuecards,1,table.map(valuecards[val],function(c) return c,true end))
			return table.union(three,one)
		end,
		[LAND_CARD_TYPE.THREE_WITH_TWO] = function(val)
			local three = pick_exactly(valuecards,3,val)
			local v = find_min_value_with_exactly_count(valuecards,2,table.map(valuecards[val],function(c) return c,true end))
			local two = pick_exactly(valuecards,2,v)
			return table.union(three,two)
		end,
		[LAND_CARD_TYPE.FOUR_WITH_DOUBLE] = function(val)
			local four = pick_exactly(valuecards,4,val)
			local two = search_min_combination(valuecards,2,table.map(valuecards[val],function(c) return c,true end))
			return table.union(four,two)
		end,
		[LAND_CARD_TYPE.FOUR_WITH_THREE] = function(val)
			local four = pick_exactly(valuecards,4,val)
			local three = search_min_combination(valuecards,3,table.map(valuecards[val],function(c) return c,true end))
			return table.union(four,three)
		end,
		[LAND_CARD_TYPE.PLANE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				table.insert(tbcards,pick_exactly(valuecards,3,i))
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.PLANE_WITH_ONE] = function(val,len)
			local tbcards = {}
			local excludes = {}
			for i = val,len + val - 1 do
				table.insert(tbcards,pick_exactly(valuecards,3,i))
				table.mergeto(excludes,
					table.map(valuecards[i],function(c) return c,true end),
					function(l,r) return l or r end
				)
				local combine_cards = search_min_combination(valuecards,1,excludes)
				table.mergeto(excludes,
					table.map(combine_cards,function(c) return c,true end),
					function(l,r) return l or r end
				)
				table.insert(tbcards,combine_cards)
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.PLANE_WITH_TWO] = function(val,len)
			local tbcards = {}
			local excludes = {}
			for i = val,len + val - 1 do
				local cards = pick_exactly(valuecards,3,i)
				table.insert(tbcards,cards)
				table.mergeto(excludes,table.map(cards,
					function(c) return c,true end),
					function(l,r) return l or r end)
				local v = find_min_value_with_exactly_count(valuecards,2,table.map(valuecards[i],function(c) return c,true end))
				local combine_cards = pick_exactly(valuecards,2,v)
				table.mergeto(excludes,table.map(combine_cards,
					function(c) return c,true end),
					function(l,r) return l or r end)
				table.insert(tbcards,combine_cards)
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.SINGLE_LINE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				table.insert(tbcards,pick_exactly(valuecards,1,i))
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.DOUBLE_LINE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				table.insert(tbcards,pick_exactly(valuecards,2,i))
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.BOMB] = function(val)
			return pick_exactly(valuecards,4,val)
		end,
		[LAND_CARD_TYPE.MISSLE] = function(val)
			return table.union(pick_exactly(valuecards,1,16),pick_exactly(valuecards,1,17))
		end,
	}

	local seek_func = {
		[LAND_CARD_TYPE.SINGLE] = function()
			for i = cvalue + 1,17 do
				if valuecounts[i] then return pick_func[LAND_CARD_TYPE.SINGLE](i) end
			end
		end,
		[LAND_CARD_TYPE.DOUBLE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 2 and valuecounts[i] < 4 then  
					return pick_func[LAND_CARD_TYPE.DOUBLE](i) 
				end
			end
		end,
		[LAND_CARD_TYPE.THREE] = function() 
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 3 then  
					return pick_func[LAND_CARD_TYPE.THREE](i) 
				end
			end
		end,
		[LAND_CARD_TYPE.THREE_WITH_ONE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 3 and total_count >= 4 then 
					return pick_func[LAND_CARD_TYPE.THREE_WITH_ONE](i) 
				end
			end
		end,
		[LAND_CARD_TYPE.THREE_WITH_TWO] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 3 and table.nums(countgroup[2]) > 0 then 
					return pick_func[LAND_CARD_TYPE.THREE_WITH_TWO](i) 
				end
			end
		end,
		[LAND_CARD_TYPE.FOUR_WITH_DOUBLE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 4 and total_count >= 6  then 
					return pick_func[LAND_CARD_TYPE.FOUR_WITH_DOUBLE](i)
				end
			end
		end,
		[LAND_CARD_TYPE.FOUR_WITH_THREE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 4  and total_count >= 7 then 
					return pick_func[LAND_CARD_TYPE.FOUR_WITH_THREE](i)
				end
			end
		end,
		[LAND_CARD_TYPE.PLANE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,3,ccount / 3)
			if lian_count >= ccount / 3 then
				return pick_func[LAND_CARD_TYPE.PLANE](first_value,lian_count)
			end
		end,
		[LAND_CARD_TYPE.PLANE_WITH_ONE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,3,ccount  /  4)
			if lian_count >= ccount  /  4 and table.nums(countgroup[1]) >= ccount / 4 then
				return pick_func[LAND_CARD_TYPE.PLANE_WITH_ONE](first_value,ccount  /  4)
			end
		end,
		[LAND_CARD_TYPE.PLANE_WITH_TWO] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,3,ccount / 5)
			if lian_count >= ccount / 5 and table.nums(countgroup[2]) >= ccount / 5 then
				return pick_func[LAND_CARD_TYPE.PLANE_WITH_TWO](first_value,ccount / 5)
			end
		end,
		[LAND_CARD_TYPE.SINGLE_LINE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,1,ccount)
			if lian_count >= ccount then
				return pick_func[LAND_CARD_TYPE.SINGLE_LINE](first_value,ccount)
			end
		end,
		[LAND_CARD_TYPE.DOUBLE_LINE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,2,ccount / 2)
			if lian_count >= ccount / 2 then
				return pick_func[LAND_CARD_TYPE.DOUBLE_LINE](first_value,ccount / 2)
			end
		end,
		[LAND_CARD_TYPE.BOMB] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 4  then 
					return pick_func[LAND_CARD_TYPE.BOMB](i)
				end
			end
		end,
		[LAND_CARD_TYPE.MISSLE] = function()
			if valuecounts[16] and valuecounts[16] > 0 and valuecounts[17] and valuecounts[17] > 0 then
				return pick_func[LAND_CARD_TYPE.MISSLE]()
			end
		end,
	}

	local function seek_any_bomb()
		for i = 3,14 do
			if valuecounts[i] and valuecounts[i] == 4  then 
				return pick_func[LAND_CARD_TYPE.BOMB](i)
			end
		end
	end

	if ctype == LAND_CARD_TYPE.MISSLE then
		return
	end

	local seekfns = {seek_func[ctype],seek_any_bomb,seek_func[LAND_CARD_TYPE.MISSLE]}

	local cards
	for _,fn in pairs(seekfns) do
		cards = fn()
		if cards then break end
	end

	log.dump(cards)

	assert((not cards or #cards > 0) and not check_cards_repeat(cards))

	return cards
end


function cards_util.seek_greatest(kcards,rule)
	local total_count = table.nums(kcards)
	local valuegroup = table.group(kcards,function(_,c) return cards_util.value(c) end)
	local valuecards =  table.map(valuegroup,function(cs,v)  return v,table.keys(cs) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)
	local countgroup =  table.group(valuecounts,function(c)  return c end)

	local has_triple_with_two = rule and rule.play and rule.play.san_dai_er
	local has_four_with_two = rule and rule.play and rule.play.si_dai_er
	local has_triple = rule and rule.play and rule.play.san_zhang

	local pick_func = {
		[LAND_CARD_TYPE.SINGLE] = function(val) return pick_exactly(valuecards,1,val) end,
		[LAND_CARD_TYPE.DOUBLE] = function(val) return pick_exactly(valuecards,2,val) end,
		[LAND_CARD_TYPE.THREE] = function(val) return pick_exactly(valuecards,3,val) end,
		[LAND_CARD_TYPE.THREE_WITH_ONE] = function(val)
			local three = pick_exactly(valuecards,3,val)
			local one = search_min_combination(valuecards,1,table.map(valuecards[val],function(c) return c,true end))
			return table.union(three,one)
		end,
		[LAND_CARD_TYPE.THREE_WITH_TWO] = function(val)
			local three = pick_exactly(valuecards,3,val)
			local v = find_min_value_with_exactly_count(valuecards,2,table.map(valuecards[val],function(c) return c,true end))
			local two = pick_exactly(valuecards,2,v)
			return table.union(three,two)
		end,
		[LAND_CARD_TYPE.FOUR_WITH_DOUBLE] = function(val)
			local four = pick_exactly(valuecards,4,val)
			local two = search_min_combination(valuecards,2,table.map(valuecards[val],function(c) return c,true end))
			return table.union(four,two)
		end,
		[LAND_CARD_TYPE.FOUR_WITH_THREE] = function(val)
			local four = pick_exactly(valuecards,4,val)
			local three = search_min_combination(valuecards,3,table.map(valuecards[val],function(c) return c,true end))
			return table.union(four,three)
		end,
		[LAND_CARD_TYPE.PLANE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				table.insert(tbcards,pick_exactly(valuecards,3,i))
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.PLANE_WITH_ONE] = function(val,len)
			local tbcards = {}
			local excludes = {}
			for i = val,len + val - 1 do
				table.insert(tbcards,pick_exactly(valuecards,3,i))
				table.mergeto(excludes,
					table.map(valuecards[i],function(c) return c,true end),
					function(l,r) return l or r end
				)
				local combine_cards = search_min_combination(valuecards,1,excludes)
				table.mergeto(excludes,
					table.map(combine_cards,function(c) return c,true end),
					function(l,r) return l or r end
				)
				table.insert(tbcards,combine_cards)
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.PLANE_WITH_TWO] = function(val,len)
			local tbcards = {}
			local excludes = {}
			for i = val,len + val - 1 do
				local cards = pick_exactly(valuecards,3,i)
				table.insert(tbcards,cards)
				table.mergeto(excludes,
					table.map(cards,function(c) return c,true end),
					function(l,r) return l or r end)
				log.dump(excludes)
				local v = find_min_value_with_exactly_count(valuecards,2,table.map(valuecards[i],function(c) return c,true end))
				local combine_cards = pick_exactly(valuecards,2,v)
				table.mergeto(excludes,
					table.map(combine_cards,function(c) return c,true end),
					function(l,r) return l or r end)
				log.dump(excludes)
				table.insert(tbcards,combine_cards)
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.SINGLE_LINE] = function(val,len)
			local cards = {}
			for i = val,len + val - 1 do
				table.insert(cards,pick_exactly(valuecards,1,i))
			end
			return table.union_tables(cards)
		end,
		[LAND_CARD_TYPE.DOUBLE_LINE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				table.insert(tbcards,pick_exactly(valuecards,2,i))
			end
			return table.union_tables(tbcards)
		end,
		[LAND_CARD_TYPE.BOMB] = function(val)
			if #valuecards[val] == 4 then
				return pick_exactly(valuecards,4,val)
			end
		end,
		[LAND_CARD_TYPE.MISSLE] = function(val)
			if #valuecards[16] > 0 and #valuecards[17] > 0 then
				return table.union(pick_exactly(valuecards,1,16),pick_exactly(valuecards,1,17))
			end
		end,
	}

	local seek_func = {
		[LAND_CARD_TYPE.SINGLE] = function()
			for i = 3,17 do
				if valuecounts[i] and valuecounts[i] == 1 then return pick_func[LAND_CARD_TYPE.SINGLE](i) end
			end
		end,
		[LAND_CARD_TYPE.DOUBLE] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] >= 2 and valuecounts[i] < 4 then return pick_func[LAND_CARD_TYPE.DOUBLE](i) end
			end
		end,
		[LAND_CARD_TYPE.THREE] = function() 
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 3 then return pick_func[LAND_CARD_TYPE.THREE](i) end
			end
		end,
		[LAND_CARD_TYPE.THREE_WITH_ONE] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 3 and total_count >= 4 then return pick_func[LAND_CARD_TYPE.THREE_WITH_ONE](i) end
			end
		end,
		[LAND_CARD_TYPE.THREE_WITH_TWO] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 3 and table.nums(countgroup[2]) > 0 then 
					return pick_func[LAND_CARD_TYPE.THREE_WITH_TWO](i) 
				end
			end
		end,
		[LAND_CARD_TYPE.FOUR_WITH_DOUBLE] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 4 and total_count >= 6  then 
					return pick_func[LAND_CARD_TYPE.FOUR_WITH_DOUBLE](i)
				end
			end
		end,
		[LAND_CARD_TYPE.FOUR_WITH_THREE] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 4  and total_count >= 7 then 
					return pick_func[LAND_CARD_TYPE.FOUR_WITH_THREE](i)
				end
			end
		end,
		[LAND_CARD_TYPE.PLANE] = function(val,len)
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,3)
			if lian_count >= 2 then
				return pick_func[LAND_CARD_TYPE.PLANE](first_value,lian_count)
			end
		end,
		[LAND_CARD_TYPE.PLANE_WITH_ONE] = function(val,len)
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,3)
			if lian_count >= 2 and table.nums(countgroup[1]) >= lian_count then
				return pick_func[LAND_CARD_TYPE.PLANE_WITH_ONE](first_value,lian_count)
			end
		end,
		[LAND_CARD_TYPE.PLANE_WITH_TWO] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,3)
			if lian_count >= 2 and table.nums(countgroup[2]) >= lian_count then
				return pick_func[LAND_CARD_TYPE.PLANE_WITH_TWO](first_value,lian_count)
			end
		end,
		[LAND_CARD_TYPE.SINGLE_LINE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,1)
			if lian_count >= 5 then
				return pick_func[LAND_CARD_TYPE.SINGLE_LINE](first_value,lian_count)
			end
		end,
		[LAND_CARD_TYPE.DOUBLE_LINE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,3)
			if lian_count >= 2 then
				return pick_func[LAND_CARD_TYPE.DOUBLE_LINE](first_value,lian_count)
			end
		end,
		[LAND_CARD_TYPE.BOMB] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 4  then 
					return pick_func[LAND_CARD_TYPE.BOMB](i)
				end
			end
		end,
		[LAND_CARD_TYPE.MISSLE] = function()
			if valuecounts[16] and valuecounts[16] > 0 and valuecounts[17] and valuecounts[17] > 0 then
				return pick_func[LAND_CARD_TYPE.MISSLE]()
			end
		end,
	}

	local seekorder = {
		LAND_CARD_TYPE.PLANE_WITH_ONE,
		LAND_CARD_TYPE.PLANE,
		LAND_CARD_TYPE.DOUBLE_LINE,
		LAND_CARD_TYPE.SINGLE_LINE,
		LAND_CARD_TYPE.THREE_WITH_ONE,
		LAND_CARD_TYPE.DOUBLE,
		LAND_CARD_TYPE.SINGLE,
		LAND_CARD_TYPE.BOMB,
		LAND_CARD_TYPE.MISSLE,
	}

	if has_triple_with_two then table.insert(seekorder,LAND_CARD_TYPE.THREE_WITH_TWO) end
	if has_triple then table.insert(seekorder,LAND_CARD_TYPE.THREE) end
	if has_four_with_two then table.insert(seekorder,LAND_CARD_TYPE.FOUR_WITH_TWO) end

	local typecards = table.series(seekorder,function(t) 
		return {type = t,cards = seek_func[t]()}
	end)

	log.dump(typecards)

	typecards = table.values(table.select(typecards,function(v) 
		if not v.cards or #v.cards == 0 then return false end
		return true
	end))

	log.dump(typecards)

	table.sort(typecards,function(l,r) 
		if l.type == LAND_CARD_TYPE.MISSLE then return false end
		if r.type == LAND_CARD_TYPE.MISSLE then return true end
		if l.type == LAND_CARD_TYPE.BOMB then return false end
		if r.type == LAND_CARD_TYPE.BOMB then return true end
		return #l.cards > #r.cards
	end)

	local cards = #typecards > 0 and typecards[1].cards or nil
	assert(cards and #cards > 0 and not check_cards_repeat(cards))
	return cards
end

-- 得到牌类型
function cards_util.get_cards_type(cards)
	local count = #cards
	if count == 1 then
		return LAND_CARD_TYPE.SINGLE, cards_util.value(cards[1]) -- 单牌
	end

	if count == 2 and ((cards[1] == 96 and cards[2] == 97) or cards[2] == 96 and cards[1] == 97)then
		return LAND_CARD_TYPE.MISSLE, 96
	end

	local valuegroup = table.group(cards,function(c) return cards_util.value(c) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)
	local countgroup =  table.group(valuecounts,function(c)  return c end)
	local countvalues = table.map(countgroup,function(cg,c) return c,table.keys(cg) end)
	local countcounts = table.map(countvalues,function(cs,c) return c,table.nums(cs) end)

	if countcounts[4] then
		if countcounts[1] == 2   and #cards ==  6 then
			return LAND_CARD_TYPE.FOUR_WITH_DOUBLE, countvalues[4][1] -- 四带两单
		end

		if countcounts[2] == 2   and #cards ==  8 then
			return LAND_CARD_TYPE.FOUR_WITH_DOUBLE, countvalues[4][1] -- 四带两对
		end

		if not countcounts[1]  and not countcounts[2] and not countcounts[3] then
			return LAND_CARD_TYPE.BOMB,  countvalues[4][1] -- 炸弹
		end

		return nil
	end

	local function max_continuity_cards(begin,value_count)
		local values = {}
		for i = begin,14 do
			if value_count[i] then
				table.insert(values,i)
			elseif #values == 1 then
				values = {}
			end
		end

		return values
	end

	if countcounts[3] then
		if countcounts[3] == 1 then
			if (countcounts[2] == 1 or countcounts[1] == 2) and #cards == 5 then
				return LAND_CARD_TYPE.THREE_WITH_TWO, countvalues[3][1] -- 三带一对
			end

			if countcounts[1] == 1 and #cards == 4  then
				return LAND_CARD_TYPE.THREE_WITH_ONE, countvalues[3][1] -- 三带一
			end

			if not countcounts[1] and not countcounts[2] and #cards == 3 then
				return LAND_CARD_TYPE.THREE, countvalues[3][1] -- 三不带
			end
		end

		if  countcounts[3] > 1 then
			local values = max_continuity_cards(3,countgroup[3])
			log.dump(values)
			if #values < 2 then return end

			if #cards == #values * 3 then
				return LAND_CARD_TYPE.PLANE, values[1] -- 飞机不带牌
			end

			--三带一飞机
			local probobility_3_count = #cards  /  4
			for i = 0,probobility_3_count - 1 do
				if #cards == (#values - i) * 4 then
					return LAND_CARD_TYPE.PLANE_WITH_ONE, values[i + 1]
				end
			end

			--三带二飞机
			probobility_3_count = #cards  /  5
			for i = 0,probobility_3_count - 1 do
				if #cards == (#values - i) * 5 then
					return LAND_CARD_TYPE.PLANE_WITH_TWO, values[i + 1]
				end
			end
		end

		return nil
	end


	if countcounts[2] and countcounts[2] > 0 then
		if countcounts[2] == 1 and #cards == 2 then
			return LAND_CARD_TYPE.DOUBLE, countvalues[2][1] -- 对子
		end

		local values = max_continuity_cards(3,countgroup[2])
		if #values >= 3 and #values == countcounts[2]  and #cards == #values * 2 then
			return LAND_CARD_TYPE.DOUBLE_LINE , values[1] -- 连对
		end
	end

	if countcounts[1] and countcounts[1] >= 5 then
		local values = max_continuity_cards(3,countgroup[1])
		if #values >= 5 and #values == countcounts[1] then
			return LAND_CARD_TYPE.SINGLE_LINE , values[1] -- 顺子
		end
	end

	return nil
end

-- 比较牌
function cards_util.compare_cards(l, r)
	if not l  then return r ~= nil  and - 1 or 0 end
	if l and not r then return 1 end

	log.info("cards_util.compare_cards l [%s,%s,%s]", l.type , l.count, l.value)
	log.info("cards_util.compare_cards r [%d,%d,%d]", r.type , r.count, r.value)

	if l.type == LAND_CARD_TYPE.MISSLE then return 1 end
	if r.type == LAND_CARD_TYPE.MISSLE then return -1 end

	if l.type == LAND_CARD_TYPE.BOMB then
		if r.type < LAND_CARD_TYPE.BOMB then return 1 end
		if r.type == LAND_CARD_TYPE.BOMB  and r.value < l.value  then return 1 end
	end

	if r.type == LAND_CARD_TYPE.BOMB then return - 1 end

	if l.type ~= r.type then return end

	if l.type == r.type and l.count == r.count then
		return l.value > r.value and 1 or (l.value < r.value and -1 or 0)
	end

	return
end

return cards_util