local def = require "game.pdk_sc.define"
local log = require "log"

local table = table
local tinsert = table.insert
local tsort = table.sort
local tremove = table.remove
local math = math

local cards_util = {}


local PDK_CARD_TYPE = def.CARDS_TYPE

cards_util.PDK_CARD_TYPE = PDK_CARD_TYPE

-- 0:黑 1:红 2:梅 3:方

local function color(card)
	return math.floor(card / 20)
end

local function value(card)
	return math.floor(card % 20)
end

local function laizi_card(v)
	return 80 + v
end

local function kc2series(kc)
	local ser = {}
	for k,n in pairs(kc) do
		for i = 1,n do ser[#ser + 1] = k end
	end

	return ser
end

local function series2kc(ser)
	local kc = {}
	for _,k in pairs(ser) do
		kc[k] = (kc[k] or 0) + 1
	end

	return kc
end

cards_util.kc2series = kc2series
cards_util.series2kc = series2kc
cards_util.color = color
cards_util.value = value
cards_util.laizi_card = laizi_card

function cards_util.check(card)
	local color,value = cards_util.color(card),value(card)
	return color >= 0 and color <= 5 and value > 0 and value < 16
end

-- 检查牌是否合法
function cards_util.check_cards(cards)
	return table.And(cards,function(c) return cards_util.check(c) end)
end

local function check_cards_repeat(cards)
	local cardsgroup = table.group(cards,function(c) return c end)
	local cardcounts = table.map(cardsgroup,function(cs,c) return c,table.nums(cs) end)
	return table.Or(cardcounts,function(n,c) return c < 80 and n > 1 end)
end

function cards_util.try_great_than(kccards,ctype,cvalue,ccount,rule,laizi)
	local play = rule and rule.play or {}
	local has_bomb = play.bomb_type_option and play.bomb_type_option < 2 or false
	local triple_bomb = play.bomb_type_option == 0

	local valuegroup = table.group(kccards,function(_,c) return c ~= laizi and value(c) or laizi end)
	local valuecards =  table.map(valuegroup,function(cs,v) return v,kc2series(cs) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)
	local laizi_count = laizi and valuecounts[laizi] or 0

	local function check_bomb_func(fn)
		return function()
			if not has_bomb then return end
			return fn()
		end
	end

	local function check_triple_bomb_func(fn)
		return function()
			if not triple_bomb then return end
			return fn()
		end
	end

	local function try_single()
		local c
		for i = cvalue + 1,14 do
			c = valuecounts[i] or 0
			if c >= 1 then
				return {valuecards[i][1]}
			end
		end
	end

	local function try_laizi_single()
		local c = valuecounts[laizi]
		return laizi and c and c > 0 and {laizi} or nil
	end
	
	local function try_double()
		local c
		for i = cvalue + 1,14 do
			c = valuecounts[i] or 0
			if c >= 2 then
				return {valuecards[i][1],valuecards[i][2]}
			end

			if c >= 1 and laizi_count >= 1 then
				return {valuecards[i][1],laizi},{laizi_card(i)}
			end
		end
	end

	local function try_laizi_double()
		local c = valuecounts[laizi]
		return laizi and c and c > 1 and {laizi,laizi} or nil
	end
	
	local function try_single_line()
		local used_laizi = 0
		local values = {}
		local replace = {}
		for i = cvalue + 1,14 do
			local c = valuecounts[i] or 0
			if c >= 1 then
				tinsert(values,i)
			elseif laizi_count - used_laizi > 0 then
				tinsert(values,laizi)
				tinsert(replace,laizi_card(i))
				used_laizi = used_laizi + 1
			else
				if #values >= ccount then
					local cs = {}
					for j = 1,ccount do
						cs[#cs + 1] = valuecards[values[j]][1]
					end
					return cs,replace
				end
				
				values = {}
				replace = {}
				used_laizi = 0
			end
		end

		if #values >= ccount then
			local cs = {}
			for j = 1,ccount do
				cs[#cs + 1] = valuecards[values[j]][1]
			end
			return cs,replace
		end
	end
	
	local function try_double_line()
		local used_laizi = 0
		local values = {}
		local replace = {}
		for i = cvalue + 1,14 do
			local c = valuecounts[i] or 0
			if c >= 2 then
				tinsert(values,i)
			elseif c == 1 and laizi_count - used_laizi >= 1 then
				tinsert(values,laizi)
				tinsert(replace,laizi_card(i))
				used_laizi = used_laizi + 1
			elseif c == 0 and laizi_count - used_laizi >= 2 then
				tinsert(values,laizi)
				used_laizi = used_laizi + 2
			else
				if #values == ccount then
					local cs = {}
					local v
					for j = 1,ccount do
						v = values[j]
						cs[#cs + 1] = valuecards[v][1]
						cs[#cs + 1] = valuecards[v][2]
					end
					return cs,replace
				end
				
				values = {}
				replace = {}
				used_laizi = 0
			end
		end

		if #values >= ccount then
			local cs = {}
			local v
			for j = 1,ccount do
				v = values[j]
				cs[#cs + 1] = valuecards[v][1]
				cs[#cs + 1] = valuecards[v][2]
			end
			return cs,replace
		end
	end
	
	local function try_triple()
		local c 
		local bv = (ctype == PDK_CARD_TYPE.TRIPLE_BOMB or ctype == PDK_CARD_TYPE.THREE) and cvalue + 1 or 5
		for i = bv,14 do
			c = valuecounts[i] or 0
			if c == 3 then
				return {valuecards[i][1],valuecards[i][2],valuecards[i][3]}
			end
		end
	end

	local function try_soft_triple()
		local c 
		local bv = ctype == PDK_CARD_TYPE.SOFT_TRIPLE_BOMB and cvalue + 1 or 5
		for i = bv,14 do
			c = valuecounts[i] or 0
			if c == 2 and laizi_count >= 1 then
				return {valuecards[i][1],valuecards[i][2],laizi},{laizi_card(i)}
			end

			if c == 1 and laizi_count >= 2 then
				return {valuecards[i][1],laizi,laizi},{laizi_card(i),laizi_card(i)}
			end

			if c > 3 then
				return {valuecards[i][1],valuecards[i][2],valuecards[i][3]}
			end
		end
	end

	local function try_four()
		local c 
		local bv = ctype == PDK_CARD_TYPE.BOMB and cvalue + 1 or 5
		for i = bv,14 do
			c = valuecounts[i] or 0
			if c == 4 then
				return {valuecards[i][1],valuecards[i][2],valuecards[i][3],valuecards[i][4]}
			end
		end
	end

	local function try_soft_four()
		local c 
		local bv = ctype == PDK_CARD_TYPE.SOFT_BOMB and cvalue + 1 or 5
		for i = bv,14 do
			c = valuecounts[i] or 0
			if c == 3 and laizi_count >= 1 then
				return {valuecards[i][1],valuecards[i][2],valuecards[i][3],laizi},{laizi_card(i)}
			end

			if c == 2 and laizi_count >= 2 then
				return {valuecards[i][1],valuecards[i][2],laizi,laizi},{laizi_card(i),laizi_card(i)}
			end

			if c == 1 and laizi_count >= 3 then
				return {valuecards[i][1],laizi,laizi,laizi},{laizi_card(i),laizi_card(i),laizi_card(i)}
			end
		end
	end

	local function try_laizi_triple()
		if laizi_count >= 3 then
			return {laizi,laizi,laizi}
		end
	end

	local function try_laizi_four()
		if laizi_count >= 4 then
			return {laizi,laizi,laizi,laizi}
		end
	end

	local function try_none()
		return
	end

	local typefunc = {
		[PDK_CARD_TYPE.SINGLE] = try_single,
		[PDK_CARD_TYPE.LAIZI_SINGLE] = try_laizi_single,
		[PDK_CARD_TYPE.DOUBLE] = try_double,
		[PDK_CARD_TYPE.LAIZI_DOUBLE] = try_laizi_double,
		[PDK_CARD_TYPE.THREE] = try_triple,
		[PDK_CARD_TYPE.LAIZI_THREE] = try_laizi_triple,
		[PDK_CARD_TYPE.SINGLE_LINE] = try_single_line,
		[PDK_CARD_TYPE.DOUBLE_LINE] = try_double_line,
		[PDK_CARD_TYPE.FOUR] = try_four,
		[PDK_CARD_TYPE.LAIZI_FOUR] = try_laizi_four,
		[PDK_CARD_TYPE.BOMB] = check_bomb_func(try_four),
		[PDK_CARD_TYPE.LAIZI_BOMB] = check_bomb_func(try_laizi_four),
		[PDK_CARD_TYPE.LAIZI_TRIPLE_BOMB] = check_triple_bomb_func(try_laizi_triple),
		[PDK_CARD_TYPE.TRIPLE_BOMB] = check_triple_bomb_func(try_triple),
		[PDK_CARD_TYPE.SOFT_TRIPLE_BOMB] = check_triple_bomb_func(try_soft_triple),
		[PDK_CARD_TYPE.SOFT_BOMB] = check_bomb_func(try_soft_four),
	}

	local function try(tps)
		if type(tps) == "number" then
			local f = assert(typefunc[tps])
			local cards,rep = f()
			if cards then
				assert((not cards or #cards > 0) and not check_cards_repeat(cards))
				return cards,rep
			end
		else
			for _,t in pairs(tps) do
				local cs,rep = try(t)
				if cs then return cs,rep end
			end
		end
	end

	local function tryer(tps)
		return function()
			return try(tps)
		end
	end

	local triplebombtps = {
		PDK_CARD_TYPE.SOFT_TRIPLE_BOMB,PDK_CARD_TYPE.TRIPLE_BOMB,PDK_CARD_TYPE.LAIZI_TRIPLE_BOMB,
	}

	local fourbombtps = {
		PDK_CARD_TYPE.SOFT_BOMB,PDK_CARD_TYPE.BOMB,PDK_CARD_TYPE.LAIZI_BOMB
	}

	local tryfunc = {
		[PDK_CARD_TYPE.SINGLE] = tryer({PDK_CARD_TYPE.SINGLE,triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.LAIZI_SINGLE] = tryer({triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.DOUBLE] = tryer({PDK_CARD_TYPE.DOUBLE,triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.LAIZI_DOUBLE] = tryer({triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.THREE] = tryer({PDK_CARD_TYPE.THREE,triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.LAIZI_THREE] = tryer({triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.SINGLE_LINE] = tryer({PDK_CARD_TYPE.SINGLE_LINE,triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.DOUBLE_LINE] = tryer({PDK_CARD_TYPE.DOUBLE_LINE,triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.FOUR] = tryer({PDK_CARD_TYPE.FOUR,PDK_CARD_TYPE.LAIZI_FOUR}),
		[PDK_CARD_TYPE.LAIZI_FOUR] = try_none,
		[PDK_CARD_TYPE.BOMB] = tryer({PDK_CARD_TYPE.BOMB,PDK_CARD_TYPE.LAIZI_BOMB}),
		[PDK_CARD_TYPE.LAIZI_BOMB] = try_none,
		[PDK_CARD_TYPE.LAIZI_TRIPLE_BOMB] = tryer({PDK_CARD_TYPE.BOMB,PDK_CARD_TYPE.SOFT_BOMB,PDK_CARD_TYPE.LAIZI_BOMB}),
		[PDK_CARD_TYPE.TRIPLE_BOMB] = tryer({PDK_CARD_TYPE.TRIPLE_BOMB,PDK_CARD_TYPE.LAIZI_TRIPLE_BOMB,PDK_CARD_TYPE.BOMB,PDK_CARD_TYPE.SOFT_BOMB,PDK_CARD_TYPE.LAIZI_BOMB}),
		[PDK_CARD_TYPE.SOFT_TRIPLE_BOMB] = tryer({triplebombtps,fourbombtps}),
		[PDK_CARD_TYPE.SOFT_BOMB] = tryer(fourbombtps),
	}

	local fn = assert(tryfunc[ctype])
	local cards,rep = fn()
	if cards then
		assert((not cards or #cards > 0) and not check_cards_repeat(cards))
		return cards,rep
	end
end

local function pick(fromcards,count,includes,excludes)
	assert(count > 0 and fromcards and #fromcards >= count)

	local cards = {}
	if includes then
		for _,card in pairs(fromcards) do
			if includes[card] and (not excludes or not excludes[card]) then
				tinsert(cards,card)
				if #cards == count then return cards  end
			end
		end
	end

	if #cards < count then
		for _,card in pairs(fromcards) do
			if (not includes or not includes[card]) and (not excludes or not excludes[card]) then
				tinsert(cards,card)
				if #cards == count then return cards  end
			end
		end
	end

	log.error("pick cards not enough cards,count:%s,expect:%s",#cards,count)

	return cards
end

local function try_with_card(kccards,rule,laizi,card)
	if not kccards[card] or kccards[card] == 0 then
		return
	end

	local play = rule and rule.play or {}
	local has_bomb = play.bomb_type_option and play.bomb_type_option < 2 or false
	local zi_mei_dui = play.zi_mei_dui
	local triple_bomb = play.bomb_type_option == 0
	
	local includes = {[card] = true}

	local val = value(card)

	local valuegroup = table.group(kccards,function(_,c) return c ~= laizi and value(c) or laizi end)
	local valuecards =  table.map(valuegroup,function(cs,v) return v,kc2series(cs) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)

	local function check_bomb_func(fn)
		return function()
			if not has_bomb then return end
			return fn()
		end
	end

	local function check_triple_bomb_func(fn)
		return function()
			if not triple_bomb then return end
			return fn()
		end
	end

	local function try_single()
		if valuecounts[val] == 1 then
			return {card}
		end
	end
	
	local function try_double()
		local laizi_count = laizi and valuecounts[laizi] or 0
		local c = valuecounts[val] or 0
		if c >= 2 then
			return pick(valuecards[val],2,includes)
		end

		if c >= 1 and laizi_count >= 1 then
			return {card,laizi},{laizi_card(val)}
		end
	end
	
	local function try_single_line()
		local laizi_count = laizi and valuecounts[laizi] or 0
		local used_laizi = 0
		local cards = {}
		local replace = {}
		for i = 5,14 do
			local c = valuecounts[i] or 0
			if c >= 1 then
				tinsert(cards,i == val and card or valuecards[i][1])
			elseif laizi_count - used_laizi > 0 and #cards > 0 then
				tinsert(cards,laizi)
				tinsert(replace,laizi_card(i))
				used_laizi = used_laizi + 1
			else
				if #cards >= 3 and
					table.Or(cards,function(c) return c == card end)
				then 
					return cards,replace
				end

				cards = {}
				used_laizi = 0
				replace = {}
			end
		end

		if 	#cards >= 3 and 
			table.Or(cards,function(c) return c == card end) 
		then
			return cards,replace
		end
	end
	
	local function try_double_line()
		local min_c = zi_mei_dui and 2 or 3
		local laizi_count = laizi and valuecounts[laizi] or 0
		local used_laizi = 0
		local cards = {}
		local cardpairs = {}
		local replace = {}
		for i = 5,14 do
			local c = valuecounts[i] or 0
			if c == 2 and i ~= laizi then
				tinsert(cardpairs,pick(valuecards[i],2,includes))
			elseif c == 1 and laizi_count - used_laizi >= 1 and #cardpairs > 0 then
				tinsert(cardpairs,{i == val and card or valuecards[i][1],laizi})
				tinsert(replace,laizi_card(i))
				used_laizi = used_laizi + 1
			elseif c == 0 and laizi_count - used_laizi >= 2 and #cardpairs > 0 then
				tinsert(cardpairs,{laizi,laizi})
				tinsert(replace,laizi_card(i))
				tinsert(replace,laizi_card(i))
				used_laizi = used_laizi + 2
			else
				if #cardpairs >= min_c then
					cards = table.flatten(cardpairs)
					if table.Or(cards,function(c) return c == card end) then
						return cards,replace
					end
				end
				cardpairs = {}
				replace = {}
				used_laizi = 0
			end
		end

		if #cardpairs >= min_c then
			cards = table.flatten(cardpairs)
			if table.Or(cards,function(c) return c == card end) then
				return cards,replace
			end
		end
	end
	
	local function try_triple()
		local laizi_count = laizi and valuecounts[laizi] or 0
		local c = valuecounts[val] or 0
		if c == 3 then
			return pick(valuecards[val],3,includes)
		end

		if c == 2 and laizi_count >= 1 then
			return pick(valuecards[val],3,{[5] = true,[laizi] = true}),{laizi_card(val)}
		end

		if c == 1 and laizi_count >= 2 then
			return {card,laizi,laizi},{laizi_card(val),laizi_card(val)}
		end

		if c > 3 then
			return pick(valuecards[val],3,includes)
		end
	end
	
	local function try_four()
		local laizi_count = laizi and valuecounts[laizi] or 0
		local c = valuecounts[val] or 0
		if c == 4 then
			return {valuecards[val][1],valuecards[val][2],valuecards[val][3],valuecards[val][4]}
		end

		if c == 3 and laizi_count >= 1 then
			return {valuecards[val][1],valuecards[val][2],valuecards[val][3],laizi},{laizi_card(val)}
		end

		if c == 2 and laizi_count >= 2 then
			return {valuecards[val][1],valuecards[val][2],laizi,laizi},{laizi_card(val),laizi_card(val)}
		end

		if c == 1 and laizi_count >= 3 then
			return {valuecards[val][1],laizi,laizi,laizi},{laizi_card(val),laizi_card(val),laizi_card(val)}
		end
	end

	local tryfunc = {
		[PDK_CARD_TYPE.SINGLE] = try_single,
		[PDK_CARD_TYPE.DOUBLE] = try_double,
		[PDK_CARD_TYPE.LAIZI_DOUBLE] = try_double,
		[PDK_CARD_TYPE.THREE] = try_triple,
		[PDK_CARD_TYPE.SINGLE_LINE] = try_single_line,
		[PDK_CARD_TYPE.DOUBLE_LINE] = try_double_line,
		[PDK_CARD_TYPE.BOMB] = check_bomb_func(try_four),
		[PDK_CARD_TYPE.SOFT_BOMB] = check_bomb_func(try_four),
		[PDK_CARD_TYPE.TRIPLE_BOMB] = check_triple_bomb_func(try_triple),
		[PDK_CARD_TYPE.SOFT_TRIPLE_BOMB] = check_triple_bomb_func(try_triple),
	}

	local tryorder = {
		PDK_CARD_TYPE.DOUBLE_LINE,
		PDK_CARD_TYPE.SINGLE_LINE,
		PDK_CARD_TYPE.THREE,
		PDK_CARD_TYPE.DOUBLE,
		PDK_CARD_TYPE.SINGLE,
		PDK_CARD_TYPE.TRIPLE_BOMB,
		PDK_CARD_TYPE.BOMB,
	}

	for _,t in pairs(tryorder) do
		local fn = assert(tryfunc[t])
		local cards,replace = fn()
		if cards then
			log.dump(t)
			log.dump(cards)
			assert(#cards > 0 and not check_cards_repeat(cards))
			return cards,replace
		end
	end
end

function cards_util.try_greatest(kccards,rule,laizi,first_discard)
	local play = rule and rule.play or {}
	local has_bomb = play.bomb_type_option and play.bomb_type_option < 2 or false
	local zi_mei_dui = play.zi_mei_dui
	local triple_bomb = play.bomb_type_option == 0
	local with_5_firstly = (rule and rule.play and rule.play.first_discard and rule.play.first_discard.with_5) and true or false
	if first_discard and with_5_firstly and kccards[5] then
		return try_with_card(kccards,rule,laizi,5)
	end
	
	local valuegroup = table.group(kccards,function(_,c) return c ~= laizi and value(c) or laizi end)
	local valuecards =  table.map(valuegroup,function(cs,v) return v,kc2series(cs) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)

	local function check_bomb_func(fn)
		return function()
			if not has_bomb then return end
			return fn()
		end
	end

	local function check_triple_bomb_func(fn)
		return function()
			if not triple_bomb then return end
			return fn()
		end
	end

	local function try_single()
		local c 
		for i = 14,5,-1 do
			c = valuecounts[i] or 0
			if c >= 1 then
				return {valuecards[i][1]}
			end
		end
	end
	
	local function try_double()
		local laizi_count = laizi and valuecounts[laizi] or 0
		local c
		for i = 5,14 do
			c = valuecounts[i] or 0
			if c >= 2 then
				return {valuecards[i][1],valuecards[i][2]}
			end

			if c >= 1 and laizi_count >= 1 then
				return {valuecards[i][1],laizi},{laizi_card(i)}
			end

			if laizi_count >= 2 then
				return {laizi,laizi},{laizi_card(i),laizi_card(i)}
			end
		end
	end
	
	local function try_single_line()
		local laizi_count = laizi and valuecounts[laizi] or 0
		local used_laizi = 0
		local cards = {}
		local replace = {}
		for i = 5,14 do
			local c = valuecounts[i] or 0
			if c == 1 then
				tinsert(cards,valuecards[i][1])
			elseif laizi_count - used_laizi > 0 and #cards > 0 then
				tinsert(cards,laizi)
				tinsert(replace,laizi_card(i))
				used_laizi = used_laizi + 1
			else
				if #cards >= 3 then return cards,replace end
				cards = {}
				used_laizi = 0
				replace = {}
			end
		end

		if #cards >= 3 then
			return cards,replace
		end
	end
	
	local function try_double_line()
		local min_c = zi_mei_dui and 2 or 3
		local laizi_count = laizi and valuecounts[laizi] or 0
		local used_laizi = 0
		local cardpairs = {}
		local replace = {}
		for i = 5,14 do
			local c = valuecounts[i] or 0
			if c == 2 and i ~= laizi then
				tinsert(cardpairs,{valuecards[i][1],valuecards[i][2]})
			elseif c == 1 and laizi_count - used_laizi >= 1 and #cardpairs > 0 then
				tinsert(cardpairs,{valuecards[i][1],laizi})
				tinsert(replace,laizi_card(i))
				used_laizi = used_laizi + 1
			elseif c == 0 and laizi_count - used_laizi >= 2 and #cardpairs > 0 then
				tinsert(cardpairs,{laizi,laizi})
				tinsert(replace,laizi_card(i))
				tinsert(replace,laizi_card(i))
				used_laizi = used_laizi + 2
			else
				if #cardpairs >= min_c then return table.flatten(cardpairs),replace end
				replace = {}
				used_laizi = 0
				cardpairs = {}
			end
		end

		if #cardpairs >= min_c then
			return table.flatten(cardpairs),replace
		end
	end
	
	local function try_triple()
		local laizi_count = laizi and valuecounts[laizi] or 0
		local c 
		for i = 5,14 do
			c = valuecounts[i] or 0
			if c == 3 then
				return {valuecards[i][1],valuecards[i][2],valuecards[i][3]}
			end

			if c == 2 and laizi_count >= 1 then
				return {valuecards[i][1],valuecards[i][2],laizi},{laizi_card(i)}
			end

			if c == 1 and laizi_count >= 2 then
				return {valuecards[i][1],laizi,laizi},{laizi_card(i),laizi_card(i)}
			end

			if c > 3 then
				return {valuecards[i][1],valuecards[i][2],valuecards[i][3]}
			end
		end
	end
	
	local function try_four()
		local laizi_count = laizi and valuecounts[laizi] or 0
		local c 
		for i = 5,14 do
			c = valuecounts[i] or 0
			if c == 4 then
				return {valuecards[i][1],valuecards[i][2],valuecards[i][3],valuecards[i][4]}
			end

			if c == 3 and laizi_count >= 1 then
				return {valuecards[i][1],valuecards[i][2],valuecards[i][3],laizi},{laizi_card(i)}
			end

			if c == 2 and laizi_count >= 2 then
				return {valuecards[i][1],valuecards[i][2],laizi,laizi},{laizi_card(i),laizi_card(i)}
			end

			if c == 1 and laizi_count >= 3 then
				return {valuecards[i][1],laizi,laizi,laizi},{laizi_card(i),laizi_card(i),laizi_card(i)}
			end
		end
	end

	local function try_laizi_triple()
		if laizi and valuecounts[laizi] and valuecounts[laizi] >= 3 then
			return {laizi,laizi,laizi}
		end
	end

	local function try_laizi_bomb()
		if has_bomb and laizi and valuecounts[laizi] and valuecounts[laizi] >= 4 then
			return {laizi,laizi,laizi,laizi}
		end
	end

	local tryfunc = {
		[PDK_CARD_TYPE.SINGLE] = try_single,
		[PDK_CARD_TYPE.DOUBLE] = try_double,
		[PDK_CARD_TYPE.LAIZI_DOUBLE] = try_double,
		[PDK_CARD_TYPE.THREE] = try_triple,
		[PDK_CARD_TYPE.LAIZI_THREE] = try_laizi_triple,
		[PDK_CARD_TYPE.SINGLE_LINE] = try_single_line,
		[PDK_CARD_TYPE.DOUBLE_LINE] = try_double_line,
		[PDK_CARD_TYPE.BOMB] = check_bomb_func(try_four),
		[PDK_CARD_TYPE.SOFT_BOMB] = check_bomb_func(try_four),
		[PDK_CARD_TYPE.LAIZI_BOMB] = check_bomb_func(try_laizi_bomb),
		[PDK_CARD_TYPE.LAIZI_TRIPLE_BOMB] = check_triple_bomb_func(try_laizi_triple),
		[PDK_CARD_TYPE.TRIPLE_BOMB] = check_triple_bomb_func(try_triple),
		[PDK_CARD_TYPE.SOFT_TRIPLE_BOMB] = check_triple_bomb_func(try_triple),
	}

	local tryorder = {
		PDK_CARD_TYPE.DOUBLE_LINE,
		PDK_CARD_TYPE.SINGLE_LINE,
		PDK_CARD_TYPE.THREE,
		PDK_CARD_TYPE.DOUBLE,
		PDK_CARD_TYPE.SINGLE,
		PDK_CARD_TYPE.TRIPLE_BOMB,
		PDK_CARD_TYPE.BOMB,
		PDK_CARD_TYPE.LAIZI_TRIPLE_BOMB,
		PDK_CARD_TYPE.LAIZI_BOMB,
	}

	for _,t in pairs(tryorder) do
		local fn = assert(tryfunc[t])
		local cards,replace = fn()
		if cards then
			log.dump(t)
			log.dump(cards)
			assert(#cards > 0 and not check_cards_repeat(cards))
			return cards,replace
		end
	end
end


-- 得到牌类型
function cards_util.get_cards_type(cards,rule,laizi,laizi_replace)
	local play = rule and rule.play or {}
	local has_bomb = (play.bomb_type_option or 0) < 2
	local triple_bomb = play.bomb_type_option == 0
	local zi_mei_dui = play.zi_mei_dui
	
	if laizi_replace and laizi then
		laizi_replace = table.series(laizi_replace)
		cards = table.series(cards,function(c)
			return laizi == c and tremove(laizi_replace) or c
		end)
	end

	local laizi_count = table.sum(cards,function(c) return color(c) == 4 and 1 or 0 end)
	local remain_laizi = table.sum(cards,function(c) return c == laizi and 1 or 0 end)

	local count = #cards
	if count == 1 then
		if laizi_count == 1 then
			return PDK_CARD_TYPE.LAIZI_SINGLE, value(cards[1])
		end
		return PDK_CARD_TYPE.SINGLE, value(cards[1]) -- 单牌
	end

	local valuegroup = table.group(cards,function(c) return c == laizi and laizi or value(c) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)
	local countgroup =  table.group(valuecounts,function(c)  return c end)
	local countvalues = table.map(countgroup,function(cg,c) return c,table.keys(cg) end)
	local countcounts = table.map(countvalues,function(cs,c) return c,table.nums(cs) end)

	if count == 2 then
		if countcounts[2] then
			return valuecounts[laizi] == count and PDK_CARD_TYPE.LAIZI_DOUBLE or PDK_CARD_TYPE.DOUBLE,countvalues[2][1]
		elseif countcounts[1] and laizi and valuecounts[laizi] == 1 then
			return PDK_CARD_TYPE.DOUBLE,countvalues[1][1]
		end
	end

	local function is_single_line(begin,value_count)
		local used_laizi = 0
		local values = {}
		for i = begin,14 do
			local c = value_count[i] or 0
			if c == 1 and i ~= laizi then
				tinsert(values,i)
			elseif remain_laizi - used_laizi > 0 and #values > 0 then
				tinsert(values,i)
				used_laizi = used_laizi + 1
			else
				if #values >= 3 then return values end
				if #values > 0 then values = {} end
				used_laizi = 0
			end
		end

		return values
	end

	local function is_double_line(begin,value_count)
		local min_c = zi_mei_dui and 2 or 3
		local used_laizi = 0
		local values = {}
		for i = begin,14 do
			local c = value_count[i] or 0
			if c == 2 and i ~= laizi then
				tinsert(values,i)
			elseif c == 1 and remain_laizi - used_laizi >= 1 and #values > 0 then
				tinsert(values,i)
				used_laizi = used_laizi + 1
			elseif c == 0 and remain_laizi - used_laizi >= 2 and #values > 0 then
				tinsert(values,i)
				used_laizi = used_laizi + 2
			else
				if #values >= min_c then return values end
				if #values > 0 then values = {} end
				used_laizi = 0
			end
		end

		return values
	end

	if count == 3 then
		if countcounts[3] == 1 then
			local t = laizi_count == count and PDK_CARD_TYPE.LAIZI_THREE or PDK_CARD_TYPE.THREE
			local c = countvalues[3][1]
			if triple_bomb then
				if laizi_count == count then
					t = PDK_CARD_TYPE.LAIZI_TRIPLE_BOMB
				elseif laizi_count > 0 and laizi_count < count then
					t = PDK_CARD_TYPE.SOFT_TRIPLE_BOMB
				else 
					t = PDK_CARD_TYPE.TRIPLE_BOMB
				end
			end
			return t, c
		end

		if laizi then
			if countcounts[2] == 1 and valuecounts[laizi] == 1 then
				return triple_bomb and PDK_CARD_TYPE.SOFT_TRIPLE_BOMB or PDK_CARD_TYPE.THREE,countvalues[2][1]
			end
	
			if countcounts[1] == 1 and valuecounts[laizi] == 2 then
				return triple_bomb and PDK_CARD_TYPE.SOFT_TRIPLE_BOMB or PDK_CARD_TYPE.THREE,countvalues[1][1]
			end
		end
	end
	
	if count == 4 then
		if countcounts[4] == 1 then
			local t = laizi_count == count and PDK_CARD_TYPE.LAIZI_FOUR or PDK_CARD_TYPE.FOUR
			local c = countvalues[4][1]
			if has_bomb then
				if laizi_count == count then
					t = PDK_CARD_TYPE.LAIZI_BOMB
				elseif laizi_count > 0 and laizi_count < count then
					t = PDK_CARD_TYPE.SOFT_BOMB
				else
					t = PDK_CARD_TYPE.BOMB
				end
			end

			return t ,c
		end

		if laizi then
			if countcounts[3] == 1 and valuecounts[laizi] == 1 then
				return has_bomb and PDK_CARD_TYPE.SOFT_BOMB or PDK_CARD_TYPE.FOUR,countvalues[3][1]
			end

			if countcounts[2] == 1 and valuecounts[laizi] == 2 then
				return has_bomb and PDK_CARD_TYPE.SOFT_BOMB or PDK_CARD_TYPE.FOUR,countvalues[2][1]
			end

			if countcounts[1] == 1 and valuecounts[laizi] == 3 then
				return has_bomb and PDK_CARD_TYPE.SOFT_BOMB or PDK_CARD_TYPE.FOUR,countvalues[1][1]
			end
		end
	end

	local values = is_double_line(5,valuecounts)
	local min_c = zi_mei_dui and 2 or 3
	if #values == count / 2 and #values >= min_c then
		return PDK_CARD_TYPE.DOUBLE_LINE , values[1] -- 连对
	end

	values = is_single_line(5,valuecounts)
	if #values == count then
		return PDK_CARD_TYPE.SINGLE_LINE , values[1] -- 顺子
	end

	return nil
end

-- 比较牌
function cards_util.compare_cards(l, r)
	if not l  then return r ~= nil  and -1 or 0 end
	if l and not r then return 1 end

	log.info("cards_util.compare_cards l [%s,%s,%s]", l.type , l.count, l.value)
	log.info("cards_util.compare_cards r [%d,%d,%d]", r.type , r.count, r.value)

	if l.type ~= r.type then
		if l.type >= PDK_CARD_TYPE.SOFT_TRIPLE_BOMB and r.type < PDK_CARD_TYPE.SOFT_TRIPLE_BOMB then
			return 1
		end

		if l.type < PDK_CARD_TYPE.SOFT_TRIPLE_BOMB and r.type >= PDK_CARD_TYPE.SOFT_TRIPLE_BOMB then
			return -1
		end

		if l.type >= PDK_CARD_TYPE.SOFT_TRIPLE_BOMB and r.type >= PDK_CARD_TYPE.SOFT_TRIPLE_BOMB then
			return l.type > r.type and 1 or -1
		end

		if l.count ~= r.count then return end
		
		return l.type > r.type and 1 or (l.type < r.type and -1 or 0)
	end
	
	if l.count ~= r.count then return end
	
	return l.value > r.value and 1 or (l.value < r.value and -1 or 0)
end

-- local t = {cards_util.get_cards_type({85,31,29},nil,85,{90})}
-- log.dump(t)

return cards_util