

local pdk_table = require "game.pdk_sc.table"
local def = require "game.pdk_sc.define"
local cards_util = require "game.pdk_sc.cards_util"
local log = require "log"
local timer = require "timer"
local enum = require "pb_enums"

local CARDS_TYPE = def.CARDS_TYPE
local PDK_CARD_TYPE = def.CARDS_TYPE
local ACTION = def.ACTION

local value = cards_util.value
local laizi_card = cards_util.laizi_card
local kc2series = cards_util.kc2series
local tinsert = table.insert

local TABLE_STATUS = {
	NONE = 0,
	-- 等待开始
	FREE = 1,
	-- 开始倒记时
	START_COUNT_DOWN = 2,
	-- 游戏进行
	PLAY = 3,
	-- 结束阶段
	END = 4,
}

local function check_cards_repeat(cards)
	local cardsgroup = table.group(cards,function(c) return c end)
	local cardcounts = table.map(cardsgroup,function(cs,c) return c,table.nums(cs) end)
	return table.Or(cardcounts,function(n,c) return c < 80 and n > 1 end)
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


function pdk_table:check_discard_next_player_last_single(ctype,cvalue)
	local play = self.rule and self.rule.play
	if not play then return end

	-- 下家报单必出最大单牌
	if play.bao_dan_discard_max and not self.last_discard then
		local next_player = self.players[self:next_chair()]
		if table.nums(next_player.hand_cards) == 1 and ctype == CARDS_TYPE.SINGLE then
			local _,hand_max_value = table.max(self:cur_player().hand_cards,function(_,c) return cards_util.value(c) end)
			return hand_max_value ~= cvalue
		end
	end
end


-- 放弃出牌
function pdk_table:do_action_pass(player,auto)
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("pdk_table:pass_card guid[%d] status error", player.guid)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("pdk_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_discard_chair)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if not self.last_discard then
		log.error("pdk_table:pass_card guid[%d] first turn", player.guid)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if self.rule and self.rule.play.must_discard or self.rule.play.must_discard == nil then
		local cards = cards_util.try_great_than(player.hand_cards,self.last_discard.type,self.last_discard.value,self.last_discard.count,self.rule,self.laizi)
		if cards then
			log.error("pdk_table:pass_card guid[%d] must discard", player.guid)
			send2client(player,"SC_PdkDoAction",{
				result = enum.ERROR_PARAMETER_ERROR
			})
			return
		end
	end

	self:cancel_discard_timer()
	self:cancel_clock_timer()

	-- 记录日志
	tinsert(self.game_log.actions,{
		chair_id = player.chair_id,
		action = ACTION.PASS,
		time = timer.nanotime(),
		auto = auto,
	})

	log.info("cur_chair_id[%d],pass_chair_id[%d]",self.cur_discard_chair,player.chair_id)
	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.PASS
	})

	self.cur_discard_chair = self:next_chair()

	if self.last_discard and self.cur_discard_chair == self.last_discard.chair  then
		local p = self:cur_player()
		if self.last_discard.type >= CARDS_TYPE.SOFT_BOMB then
			p.bomb = (p.bomb or 0) + 1
		elseif self.last_discard.type >= CARDS_TYPE.SOFT_TRIPLE_BOMB then
			p.triple_bomb = (p.triple_bomb or 0) + 1
		end
		self.last_discard = nil
	end

	self:begin_discard()
end

-- 出牌
function pdk_table:do_action_discard(player, cards,laizi_replace,auto)
	log.info("pdk_table:do_action_discard {%s}",table.concat(cards,","))
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("pdk_table:discard guid[%d] status error", player.guid)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("pdk_table:discard guid[%s] chair[%s] error", player.guid, player.chair_id)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local kccards = player.hand_cards
	if not table.And(cards,function(c) return kccards[c] and kccards[c] > 0  end) then
		log.warning("pdk_table:discard guid[%d] cards[%s] error, has[%s]", player.guid, table.concat(cards, ','), 
			table.concat(table.keys(player.hand_cards), ','))
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end
	
	local cardstype, cardsval = self:get_cards_type(cards,laizi_replace)
	log.info("cardstype[%s] cardsval[%s]" , cardstype , cardsval)
	if not cardstype then
		log.warning("pdk_table:discard guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cards, ','))
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local cmp = cards_util.compare_cards({type = cardstype, count = #cards, value = cardsval}, self.last_discard)
	if self.last_discard and (not cmp or cmp <= 0) then
		log.warning("pdk_table:discard guid[%d] compare_cards error, cards[%s], cur_discards[%d,%d,%d], last_discard[%d,%d,%d]", 
			player.guid, table.concat(cards, ','),cardstype, #cards,
			cardsval,self.last_discard.type,self.last_discard.count,self.last_discard.value)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if 	not self:check_first_discards_with_5(cards) or
		self:check_discard_next_player_last_single(cardstype,cardsval)
	then
		log.warning("pdk_table:discard guid[%d] not with 5, cards[%s]", player.guid, table.concat(cards, ','))
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
   end

	self:cancel_discard_timer()
	self:cancel_clock_timer()

	self.last_discard = {
		cards = cards,
		chair = player.chair_id,
		type = cardstype,
		value = cardsval,
		count = #cards,
		laizi_replace = laizi_replace,
	}

	self.first_discard = nil

	player.discard_times = (player.discard_times or 0) + 1

	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.DISCARD,
		cards = cards,
		laizi_replace = laizi_replace,
	})

	log.info("pdk_table:do_action_discard  chair_id [%d] cards{%s}", player.chair_id, table.concat(cards, ','))
	
	local kvcards = player.hand_cards
	table.foreach(cards,function(c)
		local n = kvcards[c] - 1
		kvcards[c] = n > 0 and n or nil
	end)

	tinsert(self.game_log.actions,{
		action = ACTION.DISCARD,
		chair_id = player.chair_id,
		cards_type = cardstype,
		cards = cards,
		laizi_replace = laizi_replace,
		time = timer.nanotime(),
		auto = auto,
	})

	local cardsum = table.sum(player.hand_cards)
	if  cardsum == 0 then
		player.win = true
		player.statistics.win = (player.statistics.win or 0) + 1
		if cardstype >= CARDS_TYPE.SOFT_BOMB then
			player.bomb = (player.bomb or 0) + 1
		elseif cardstype >= CARDS_TYPE.SOFT_TRIPLE_BOMB then
			player.triple_bomb = (player.triple_bomb or 0) + 1
		end
		self:game_balance(player)
	else
		self.cur_discard_chair = self:next_chair()
		self:begin_discard()
	end
end
