local pb = require "pb_files"
local log = require "log"


local table = table
local tinsert = table.insert
local tremove = table.remove

local cards_util = {}

local PDK_CARD_TYPE = {
	SINGLE = pb.enum("PDK_CARD_TYPE", "SINGLE"),
	DOUBLE = pb.enum("PDK_CARD_TYPE", "DOUBLE"),
	THREE = pb.enum("PDK_CARD_TYPE", "THREE"),
	THREE_WITH_ONE = pb.enum("PDK_CARD_TYPE", "THREE_WITH_ONE"),
	THREE_WITH_TWO = pb.enum("PDK_CARD_TYPE", "THREE_WITH_TWO"),
	FOUR_WITH_SINGLE = pb.enum("PDK_CARD_TYPE", "FOUR_WITH_SINGLE"),
	FOUR_WITH_DOUBLE = pb.enum("PDK_CARD_TYPE", "FOUR_WITH_DOUBLE"),
	SINGLE_LINE = pb.enum("PDK_CARD_TYPE", "SINGLE_LINE"),
	DOUBLE_LINE = pb.enum("PDK_CARD_TYPE", "DOUBLE_LINE"),
	PLANE = pb.enum("PDK_CARD_TYPE", "PLANE"),
	PLANE_WITH_ONE = pb.enum("PDK_CARD_TYPE", "PLANE_WITH_ONE"),
	PLANE_WITH_TWO = pb.enum("PDK_CARD_TYPE", "PLANE_WITH_TWO"),
	PLANE_WITH_MIX = pb.enum("PDK_CARD_TYPE","PLANE_WITH_MIX"),
	BOMB = pb.enum("PDK_CARD_TYPE", "BOMB"),
	FOUR_WITH_THREE = pb.enum("PDK_CARD_TYPE", "FOUR_WITH_THREE"),
	MISSLE = pb.enum("PDK_CARD_TYPE", "MISSLE"),
}

cards_util.PDK_CARD_TYPE = PDK_CARD_TYPE

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
		tinsert(nums,1)
		tinsert(combos,nums)
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
			tinsert(sections,{b = i,len = len})
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
				tinsert(cards,card)
				if #cards == count then break  end
			end
		end
	end

	if #cards < count then  
		for _,card in pairs(vcards) do
			if (not try_includes or not try_includes[card]) and (not excludes or not excludes[card]) then
				tinsert(cards,card)
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
		tinsert(cards_combination,cards)
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
	local has_missle = rule and rule.play and rule.play.AAA_is_bomb
	local pick_func = {
		[PDK_CARD_TYPE.SINGLE] = function(val) return pick_exactly(valuecards,1,val) end,
		[PDK_CARD_TYPE.DOUBLE] = function(val) return pick_exactly(valuecards,2,val) end,
		[PDK_CARD_TYPE.THREE] = function(val) return pick_exactly(valuecards,3,val) end,
		[PDK_CARD_TYPE.THREE_WITH_ONE] = function(val)
			local three = pick_exactly(valuecards,3,val)
			local one = search_min_combination(valuecards,1,table.map(valuecards[val],function(c) return c,true end))
			return table.union(three,one)
		end,
		[PDK_CARD_TYPE.THREE_WITH_TWO] = function(val)
			local three = pick_exactly(valuecards,3,val)
			local two = search_min_combination(valuecards,2,table.map(valuecards[val],function(c) return c,true end))
			return table.union(three,two)
		end,
		[PDK_CARD_TYPE.FOUR_WITH_DOUBLE] = function(val)
			local four = pick_exactly(valuecards,4,val)
			local two = search_min_combination(valuecards,2,table.map(valuecards[val],function(c) return c,true end))
			return table.union(four,two)
		end,
		[PDK_CARD_TYPE.FOUR_WITH_THREE] = function(val)
			local four = pick_exactly(valuecards,4,val)
			local three = search_min_combination(valuecards,3,table.map(valuecards[val],function(c) return c,true end))
			return table.union(four,three)
		end,
		[PDK_CARD_TYPE.PLANE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				tinsert(tbcards,pick_exactly(valuecards,3,i))
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.PLANE_WITH_ONE] = function(val,len)
			local tbcards = {}
			local excludes = {}
			for i = val,len + val - 1 do
				tinsert(tbcards,pick_exactly(valuecards,3,i))
				table.mergeto(excludes,
					table.map(valuecards[i],function(c) return c,true end),
					function(l,r) return l or r end
				)
				local combine_cards = search_min_combination(valuecards,1,excludes)
				table.mergeto(excludes,
					table.map(combine_cards,function(c) return c,true end),
					function(l,r) return l or r end
				)
				tinsert(tbcards,combine_cards)
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.PLANE_WITH_TWO] = function(val,len)
			local tbcards = {}
			local excludes = {}
			for i = val,len + val - 1 do
				local cards = pick_exactly(valuecards,3,i)
				tinsert(tbcards,cards)
				table.mergeto(excludes,table.map(cards,
					function(c) return c,true end),
					function(l,r) return l or r end)
				local combine_cards = search_min_combination(valuecards,2,excludes)
				table.mergeto(excludes,table.map(combine_cards,
					function(c) return c,true end),
					function(l,r) return l or r end)
				tinsert(tbcards,combine_cards)
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.SINGLE_LINE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				tinsert(tbcards,pick_exactly(valuecards,1,i))
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.DOUBLE_LINE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				tinsert(tbcards,pick_exactly(valuecards,2,i))
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.BOMB] = function(val)
			return pick_exactly(valuecards,4,val)
		end,
		[PDK_CARD_TYPE.MISSLE] = function(val)
			return pick_exactly(valuecards,3,14)
		end,
	}

	local seek_func = {
		[PDK_CARD_TYPE.SINGLE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] then return pick_func[PDK_CARD_TYPE.SINGLE](i) end
			end
		end,
		[PDK_CARD_TYPE.DOUBLE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] >= 2 and valuecounts[i] < 4 then  
					return pick_func[PDK_CARD_TYPE.DOUBLE](i) 
				end
			end
		end,
		[PDK_CARD_TYPE.THREE] = function() 
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 3 and (not has_missle or i ~= 14) then  
					return pick_func[PDK_CARD_TYPE.THREE](i) 
				end
			end
		end,
		[PDK_CARD_TYPE.THREE_WITH_ONE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 3 and total_count >= 4 and (not has_missle or i ~= 14) then 
					return pick_func[PDK_CARD_TYPE.THREE_WITH_ONE](i) 
				end
			end
		end,
		[PDK_CARD_TYPE.THREE_WITH_TWO] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 3 and total_count >= 5 and (not has_missle or i ~= 14) then 
					return pick_func[PDK_CARD_TYPE.THREE_WITH_TWO](i) 
				end
			end
		end,
		[PDK_CARD_TYPE.FOUR_WITH_DOUBLE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 4 and total_count >= 6  then 
					return pick_func[PDK_CARD_TYPE.FOUR_WITH_DOUBLE](i)
				end
			end
		end,
		[PDK_CARD_TYPE.FOUR_WITH_THREE] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 4  and total_count >= 7 then 
					return pick_func[PDK_CARD_TYPE.FOUR_WITH_THREE](i)
				end
			end
		end,
		[PDK_CARD_TYPE.PLANE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,3,ccount / 3)
			if lian_count >= ccount / 3 then
				return pick_func[PDK_CARD_TYPE.PLANE](first_value,lian_count)
			end
		end,
		[PDK_CARD_TYPE.PLANE_WITH_ONE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,3,ccount  /  4)
			if lian_count >= ccount  /  4 then
				return pick_func[PDK_CARD_TYPE.PLANE_WITH_ONE](first_value,ccount  /  4)
			end
		end,
		[PDK_CARD_TYPE.PLANE_WITH_TWO] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,3,ccount / 5)
			if lian_count >= ccount / 5 then
				return pick_func[PDK_CARD_TYPE.PLANE_WITH_TWO](first_value,ccount / 5)
			end
		end,
		[PDK_CARD_TYPE.SINGLE_LINE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,1,ccount)
			if lian_count >= ccount then
				return pick_func[PDK_CARD_TYPE.SINGLE_LINE](first_value,ccount)
			end
		end,
		[PDK_CARD_TYPE.DOUBLE_LINE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,2,ccount / 2)
			if lian_count >= ccount / 2 then
				return pick_func[PDK_CARD_TYPE.DOUBLE_LINE](first_value,ccount / 2)
			end
		end,
		[PDK_CARD_TYPE.BOMB] = function()
			for i = cvalue + 1,15 do
				if valuecounts[i] and valuecounts[i] == 4  then 
					return pick_func[PDK_CARD_TYPE.BOMB](i)
				end
			end
		end,
		[PDK_CARD_TYPE.MISSLE] = function()
			if valuecounts[14] and valuecounts[14] >= 3 then
				return pick_exactly(valuecards,3,14)
			end
		end,
	}

	local function seek_any_bomb()
		for i = 3,14 do
			if valuecounts[i] and valuecounts[i] == 4  then 
				return pick_func[PDK_CARD_TYPE.BOMB](i)
			end
		end

		if has_missle then
			return seek_func[PDK_CARD_TYPE.MISSLE]()
		end
	end

	if ctype == PDK_CARD_TYPE.MISSLE then
		return
	end

	local cards
	cards = seek_func[ctype]()
	if not cards and ctype ~= PDK_CARD_TYPE.BOMB then
		cards = seek_any_bomb()
	end

	log.dump(cards)

	assert((not cards or #cards > 0) and not check_cards_repeat(cards))

	return cards
end


function cards_util.seek_greatest(kcards,rule,first_discard)
	local total_count = table.nums(kcards)
	local valuegroup = table.group(kcards,function(_,c) return cards_util.value(c) end)
	local valuecards =  table.map(valuegroup,function(cs,v)  return v,table.keys(cs) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)
	local countgroup =  table.group(valuecounts,function(c)  return c end)

	local with_3_firstly = (first_discard and rule and rule.play and rule.play.first_discard and rule.play.first_discard.with_3) and true or false
	local try_includes = with_3_firstly and {[3] = true} or nil
	local has_three_with_one = rule and rule.play and rule.play.san_dai_yi
	local has_missle = rule and rule.play and rule.play.AAA_is_bomb

	local pick_func = {
		[PDK_CARD_TYPE.SINGLE] = function(val) return pick_exactly(valuecards,1,val,nil,try_includes) end,
		[PDK_CARD_TYPE.DOUBLE] = function(val) return pick_exactly(valuecards,2,val,nil,try_includes) end,
		[PDK_CARD_TYPE.THREE] = function(val) return pick_exactly(valuecards,3,val,nil,try_includes) end,
		[PDK_CARD_TYPE.THREE_WITH_ONE] = function(val)
			local three = pick_exactly(valuecards,3,val,nil,try_includes)
			local one = search_min_combination(valuecards,1,table.map(valuecards[val],function(c) return c,true end))
			return table.union(three,one)
		end,
		[PDK_CARD_TYPE.THREE_WITH_TWO] = function(val)
			local three = pick_exactly(valuecards,3,val,nil,try_includes)
			local two = search_min_combination(valuecards,2,table.map(valuecards[val],function(c) return c,true end))
			return table.union(three,two)
		end,
		[PDK_CARD_TYPE.FOUR_WITH_DOUBLE] = function(val)
			local four = pick_exactly(valuecards,4,val,nil,try_includes)
			local two = search_min_combination(valuecards,2,table.map(valuecards[val],function(c) return c,true end))
			return table.union(four,two)
		end,
		[PDK_CARD_TYPE.FOUR_WITH_THREE] = function(val)
			local four = pick_exactly(valuecards,4,val,nil,try_includes)
			local three = search_min_combination(valuecards,3,table.map(valuecards[val],function(c) return c,true end))
			return table.union(four,three)
		end,
		[PDK_CARD_TYPE.PLANE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				tinsert(tbcards,pick_exactly(valuecards,3,i,nil,try_includes))
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.PLANE_WITH_ONE] = function(val,len)
			local tbcards = {}
			local excludes = {}
			for i = val,len + val - 1 do
				tinsert(tbcards,pick_exactly(valuecards,3,i,nil,try_includes))
				table.mergeto(excludes,
					table.map(valuecards[i],function(c) return c,true end),
					function(l,r) return l or r end
				)
				local combine_cards = search_min_combination(valuecards,1,excludes)
				table.mergeto(excludes,
					table.map(combine_cards,function(c) return c,true end),
					function(l,r) return l or r end
				)
				tinsert(tbcards,combine_cards)
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.PLANE_WITH_TWO] = function(val,len)
			local tbcards = {}
			local excludes = {}
			for i = val,len + val - 1 do
				local cards = pick_exactly(valuecards,3,i,nil,try_includes)
				tinsert(tbcards,cards)
				table.mergeto(excludes,
					table.map(cards,function(c) return c,true end),
					function(l,r) return l or r end)
				log.dump(excludes)
				local combine_cards = search_min_combination(valuecards,2,excludes)
				table.mergeto(excludes,
					table.map(combine_cards,function(c) return c,true end),
					function(l,r) return l or r end)
				log.dump(excludes)
				tinsert(tbcards,combine_cards)
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.SINGLE_LINE] = function(val,len)
			local cards = {}
			for i = val,len + val - 1 do
				tinsert(cards,pick_exactly(valuecards,1,i,nil,try_includes))
			end
			return table.union_tables(cards)
		end,
		[PDK_CARD_TYPE.DOUBLE_LINE] = function(val,len)
			local tbcards = {}
			for i = val,len + val - 1 do
				tinsert(tbcards,pick_exactly(valuecards,2,i,nil,try_includes))
			end
			return table.union_tables(tbcards)
		end,
		[PDK_CARD_TYPE.BOMB] = function(val)
			if #valuecards[val] == 4 then
				return pick_exactly(valuecards,4,val,nil,try_includes)
			end
		end,
		[PDK_CARD_TYPE.MISSLE] = function(val)
			if #valuecards[14] >= 3 then
				return pick_exactly(valuecards,3,14,nil,try_includes)
			end
		end,
	}

	local seek_func = {
		[PDK_CARD_TYPE.SINGLE] = function()
			local b,e,s = 15,3,-1
			if with_3_firstly then b,e,s = 3,15,1 end
			for i = b,e,s do
				if valuecounts[i] and valuecounts[i] == 1 then return pick_func[PDK_CARD_TYPE.SINGLE](i) end
			end
		end,
		[PDK_CARD_TYPE.DOUBLE] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 2 then return pick_func[PDK_CARD_TYPE.DOUBLE](i) end
			end
		end,
		[PDK_CARD_TYPE.THREE] = function() 
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 3 then return pick_func[PDK_CARD_TYPE.THREE](i) end
			end
		end,
		[PDK_CARD_TYPE.THREE_WITH_ONE] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 3 and total_count >= 4 then return pick_func[PDK_CARD_TYPE.THREE_WITH_ONE](i) end
			end
		end,
		[PDK_CARD_TYPE.THREE_WITH_TWO] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 3 and total_count >= 5 then return pick_func[PDK_CARD_TYPE.THREE_WITH_TWO](i) end
			end
		end,
		[PDK_CARD_TYPE.FOUR_WITH_DOUBLE] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 4 and total_count >= 6  then 
					return pick_func[PDK_CARD_TYPE.FOUR_WITH_DOUBLE](i)
				end
			end
		end,
		[PDK_CARD_TYPE.FOUR_WITH_THREE] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 4  and total_count >= 7 then 
					return pick_func[PDK_CARD_TYPE.FOUR_WITH_THREE](i)
				end
			end
		end,
		[PDK_CARD_TYPE.PLANE] = function(val,len)
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,3)
			if lian_count >= 2 then
				return pick_func[PDK_CARD_TYPE.PLANE](first_value,lian_count)
			end
		end,
		[PDK_CARD_TYPE.PLANE_WITH_ONE] = function(val,len)
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,3)
			if lian_count >= 2 then
				return pick_func[PDK_CARD_TYPE.PLANE_WITH_ONE](first_value,lian_count)
			end
		end,
		[PDK_CARD_TYPE.PLANE_WITH_TWO] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,3)
			if lian_count >= 2 then
				return pick_func[PDK_CARD_TYPE.PLANE_WITH_TWO](first_value,lian_count)
			end
		end,
		[PDK_CARD_TYPE.SINGLE_LINE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,1)
			if lian_count >= 5 then
				return pick_func[PDK_CARD_TYPE.SINGLE_LINE](first_value,lian_count)
			end
		end,
		[PDK_CARD_TYPE.DOUBLE_LINE] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,3,2)
			if lian_count >= 2 then
				return pick_func[PDK_CARD_TYPE.DOUBLE_LINE](first_value,lian_count)
			end
		end,
		[PDK_CARD_TYPE.BOMB] = function()
			for i = 3,15 do
				if valuecounts[i] and valuecounts[i] == 4  then 
					return pick_func[PDK_CARD_TYPE.BOMB](i)
				end
			end
		end,
		[PDK_CARD_TYPE.MISSLE] = function()
			if valuecounts[14] and valuecounts[14] == 3 then
				return pick_func[PDK_CARD_TYPE.MISSLE]()
			end
		end,
	}

	local seekorder = {
		PDK_CARD_TYPE.PLANE_WITH_TWO,
		PDK_CARD_TYPE.PLANE,
		PDK_CARD_TYPE.DOUBLE_LINE,
		PDK_CARD_TYPE.SINGLE_LINE,
		PDK_CARD_TYPE.THREE_WITH_TWO,
		PDK_CARD_TYPE.THREE,
		PDK_CARD_TYPE.DOUBLE,
		PDK_CARD_TYPE.SINGLE,
		PDK_CARD_TYPE.BOMB,
	}

	if has_missle then
		tinsert(seekorder,PDK_CARD_TYPE.MISSLE)
	end

	if has_three_with_one then
		tinsert(seekorder,PDK_CARD_TYPE.THREE_WITH_ONE)
	end

	local typecards = table.series(seekorder,function(t) 
		return {type = t,cards = seek_func[t]()}
	end)

	log.dump(typecards)

	typecards = table.values(table.select(typecards,function(v) 
		if not v.cards or #v.cards == 0 then return false end
		if has_three_with_one and v.type == PDK_CARD_TYPE.THREE_WITH_ONE and total_count > 4 then return false end
		if with_3_firstly then return table.logic_or(v.cards,function(c) return c == 3 end) end
		return true
	end))

	log.dump(typecards)

	table.sort(typecards,function(l,r) 
		if l.type == PDK_CARD_TYPE.MISSLE then return false end
		if r.type == PDK_CARD_TYPE.MISSLE then return true end
		if l.type == PDK_CARD_TYPE.BOMB then return false end
		if r.type == PDK_CARD_TYPE.BOMB then return true end
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
		return PDK_CARD_TYPE.SINGLE, cards_util.value(cards[1]) -- 单牌
	end

	local valuegroup = table.group(cards,function(c) return cards_util.value(c) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)
	local countgroup =  table.group(valuecounts,function(c)  return c end)
	local countvalues = table.map(countgroup,function(cg,c) return c,table.keys(cg) end)
	local countcounts = table.map(countvalues,function(cs,c) return c,table.nums(cs) end)

	if countcounts[4] and countcounts[4] == 1 then
		if (countcounts[1] == 2 or countcounts[2] == 1) and #cards ==  6 then
			return PDK_CARD_TYPE.FOUR_WITH_DOUBLE, countvalues[4][1] -- 四带二
		end

		if (countcounts[3] == 1 or (countcounts[2] == 1 and countcounts[1] == 1) or countcounts[1] == 3) and #cards == 7  then
			return PDK_CARD_TYPE.FOUR_WITH_THREE, countvalues[4][1] -- 四带三
		end

		if not countcounts[1]  and not countcounts[2] and not countcounts[3] then
			return PDK_CARD_TYPE.BOMB,  countvalues[4][1] -- 炸弹
		end

		if countcounts[1] == 1 and #cards == 5 then
			return PDK_CARD_TYPE.THREE_WITH_TWO, countvalues[4][1] -- 三带二
		end
	end

	if countcounts[3] and countcounts[3] == 1 then
		if (countcounts[2] == 1 or countcounts[1] == 2) and #cards == 5 then
			return PDK_CARD_TYPE.THREE_WITH_TWO, countvalues[3][1] -- 三带二
		end

		if countcounts[1] == 1 and #cards == 4  then
			return PDK_CARD_TYPE.THREE_WITH_ONE, countvalues[3][1] -- 三带一
		end

		if not countcounts[1] and not countcounts[2] and #cards == 3 then
			return PDK_CARD_TYPE.THREE, countvalues[3][1] -- 三不带
		end
	end

	-- 飞机
	if (countcounts[3] or 0) + (countcounts[4] or 0) > 1 then
		local values = {}
		for i = 3,14 do
			if countgroup[3] and countgroup[3][i] then
				tinsert(values,i)
			elseif countgroup[4] and countgroup[4][i] then
				tinsert(values,i)
			elseif #values == 1 then
				values = {}
			elseif #values > 1 then
				break
			end
		end

		local value_c = #values
		local card_c = #cards

		if value_c < 2 then
			return
		end

		if card_c == value_c * 3 then
			return PDK_CARD_TYPE.PLANE, values[1] -- 飞机不带牌
		end

		--三带一飞机
		if card_c == value_c * 4 then
			return PDK_CARD_TYPE.PLANE_WITH_ONE, values[1]
		end

		--三带二飞机
		if card_c == value_c * 5 then
			return PDK_CARD_TYPE.PLANE_WITH_TWO, values[1]
		end

		if card_c > value_c * 3 and card_c < value_c * 5 then
			return PDK_CARD_TYPE.PLANE_WITH_MIX, values[1]
		end

		return
	end

	local function max_continuity_cards(begin,value_count)
		local values = {}
		for i = begin,14 do
			if value_count[i] then
				tinsert(values,i)
			elseif #values == 1 then
				values = {}
			end
		end

		return values
	end

	if countcounts[2] and countcounts[2] > 0 then
		if countcounts[2] == 1 and #cards == 2 then
			return PDK_CARD_TYPE.DOUBLE, countvalues[2][1] -- 对子
		end

		local values = max_continuity_cards(3,countgroup[2])
		if #values >= 2 and #values == countcounts[2]  and #cards == #values * 2 then
			return PDK_CARD_TYPE.DOUBLE_LINE , values[1] -- 连对
		end
	end

	if countcounts[1] and countcounts[1] >= 5 then
		local values = max_continuity_cards(3,countgroup[1])
		if #values >= 5 and #values == countcounts[1] then
			return PDK_CARD_TYPE.SINGLE_LINE , values[1] -- 顺子
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

	if l.type == PDK_CARD_TYPE.MISSLE then return 1 end
	if r.type == PDK_CARD_TYPE.MISSLE then return -1 end

	if l.type == PDK_CARD_TYPE.BOMB then
		if r.type < PDK_CARD_TYPE.BOMB then return 1 end
		if r.type == PDK_CARD_TYPE.BOMB  and r.value < l.value  then return 1 end
	end

	if r.type == PDK_CARD_TYPE.BOMB then return - 1 end

	if l.type ~= r.type then return end

	if l.type == r.type and l.count == r.count then
		return l.value > r.value and 1 or (l.value < r.value and -1 or 0)
	end

	return
end

return cards_util