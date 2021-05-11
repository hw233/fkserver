local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local cards_util = require "game.pdk.cards_util"
local pb = require "pb_files"
local log = require "log"

local tinsert = table.insert


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


local function pick_exactly(valuecards,count,val,excludes,try_includes)
	assert(count > 0 and valuecards[val] and #valuecards[val] >= count)

	local cards = {}
	local vcards = valuecards[val]
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

local function check_cards_repeat(cards)
	local cardsgroup = table.group(cards,function(c) return c end)
	local cardcounts = table.map(cardsgroup,function(cs,c) return c,table.nums(cs) end)
	return table.logic_or(cardcounts,function(n) return n > 1 end)
end

function cards_util.seek_great_than(kcards,ctype,cvalue,ccount,rule)
	log.info("cards_util.seek_great_than")
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
			if lian_count >= ccount  /  4 and total_count >= ccount then
				return pick_func[PDK_CARD_TYPE.PLANE_WITH_ONE](first_value,ccount  /  4)
			end
		end,
		[PDK_CARD_TYPE.PLANE_WITH_TWO] = function()
			local lian_count,first_value = seek_continuity_cards_count(valuecounts,cvalue + 1,3,ccount / 5)
			if lian_count >= ccount / 5 and total_count >= ccount then
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

	assert((not cards or #cards > 0) and not check_cards_repeat(cards))

	return cards
end