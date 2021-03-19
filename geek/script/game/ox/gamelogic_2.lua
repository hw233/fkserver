
--低倍场牛牛(1赔3)游戏逻辑

local const = require "game.ox.const"

local math = math
local table = table
local mfloor = math.floor

local logic = {}


--[[-- 最大赔率倍数10倍
local OX_MAX_TIMES = 10

-- 是否有大小王
local CLOWN_EXSITS = false

-- 上庄条件金币限制
local OX_BANKER_LIMIT = 500
--]]
-- 得到牌大小
local function get_value(card)
	return mfloor(card / 4)
end

-- 得到牛牛计算值
local function get_value_ox(val)
	return val >= 9 and 10 or val + 1
end

-- 得到牌花色
local function get_color(card)
	return card % 4
end

-- 得到倍数
function logic.get_type_times(cards_type,max_value)
	-- 1. 无牛：1倍。
	-- 2. 牛一：1倍，牛二：2倍……牛八：8倍，牛九：9倍。
	-- 3. 牛牛及以上：10倍。
	-- 牛牛及以上10倍
	if cards_type >= const.OX_CARD_TYPE_OX_TWO then
		return 10
	-- 牛N 返回最大数值的倍率
	elseif cards_type == const.OX_CARD_TYPE_OX_ONE then
		return max_value
	end
	-- 其它均为1倍
	return 1
end

-- 有大王或小王(也有可能包含两个王)
local function include_king(card)
	local bomb_num = 0
	for i=1,5 do
		if card[i] == 52 or card[i] == 53 then
			bomb_num = bomb_num + 1
		end
	end
	return bomb_num
end

-- 得到牌类型
function logic.get_cards_type(cards)
	--[[
		params: cards
		return ox,val_list,max_color,max_value
	]]
	local king_num = include_king(cards)
	local list = {}
	for i=1,5 do
		list[i] = cards[i]
	end
	table.sort(list, function (a, b)
		return a > b
	end)

	local king_ox = 0
	local is_ten = false
	local repeat_times =0
	local last_value = nil
	local val_list = {}
	local four_same = false
	local same_value = nil
	local sum_value =0
	local bomb_num = 0
	for i =1,5 do
		local  val = math.floor(list[i]/4)
		if list[i] ~= 52 and list[i] ~= 53 then
			sum_value = sum_value + val +1
		end
		val_list[i] = val
		if val == 9 then
			-- 10点
			is_ten = true
		elseif val > 9 and val < 13 then
			-- 花色
			king_ox = king_ox + 1
		elseif val == 13 then
			-- 带王
			bomb_num = bomb_num + 1
		end
	
		if list[i] ~= 52 and list[i] ~= 53 then
			if not last_value then
				last_value = val
				repeat_times = 1
			elseif last_value ~= val then
				if repeat_times ==4 then
					-- 4个相同
					four_same = true
					same_value = list[i]
				end
				last_value = val
				if king_num == 0  then
					repeat_times = 1
				elseif king_num == 1 and repeat_times == 2 then
					repeat_times = 1
				elseif king_num == 2 and repeat_times < 2 then
					repeat_times = 1
				end
				--repeat_times = 1
			else
				repeat_times = repeat_times +1
				same_value = list[i]
			end
		end
	end
	
	if sum_value <= 10 - king_num then
		return const.OX_CARD_TYPE_FIVE_SAMLL,val_list,get_color(list[1])
	end

	if repeat_times >= 4 - king_num or four_same then
		return const.OX_CARD_TYPE_FOUR_SAMES,same_value,get_color(list[1])
	end

	-- 五花牛
	if king_ox == 5 - king_num then
		return const.OX_CARD_TYPE_FIVE_KING,val_list,get_color(list[1])
	end
	-- 四花牛
	if king_ox == 4 - king_num and is_ten then
		return const.OX_CARD_TYPE_FOUR_KING,val_list,get_color(list[1])
	end

	-- 其它类型判断
	local val_ox = {}
	for i=1,5 do
		val_ox[i] = get_value_ox(val_list[i])
	end

	if king_num == 2 then --两个王直接返回牛牛
		return const.OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
	elseif king_num == 1 then --只带一个王
		for i=2, 3 do
			for j=i+1, 4 do
				for k =j+1, 5 do
					if (val_ox[i] + val_ox[j] + val_ox[k]) %10 ==0 then
						return const.OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
					end
				end
			end
		end             
	
		local max_value = 0
		for i=2, 4 do
			for j=i+1,5 do
				if (val_ox[i] + val_ox[j]) %10 == 0 then
					return const.OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
				end
				if (val_ox[i] + val_ox[j]) %10 > max_value then
					max_value = (val_ox[i] + val_ox[j]) %10
				end
			end
		end
		return const.OX_CARD_TYPE_OX_ONE,val_list,get_color(list[1]),max_value
	else  --无大小王
	
		local is_three_eq_ten =false -- 是否有三个数的和为10的倍数
		local is_ox_two = false -- 是否是牛牛
		local ox_num = 0 -- 牛1的牛数
		for i=1,3 do
			for j =i+1,4 do
				for k=j+1,5 do
					if (val_ox[i] + val_ox[j] + val_ox[k]) %10 ==0 then
						is_three_eq_ten = true
						local other_sum =0
						for m=1,5 do
							if m ~=i and m ~=j and m~=k then
								other_sum = other_sum + val_ox[m]
							end
						end
						if(other_sum)%10 ==0 then
							--牛牛
							is_ox_two = true
						else
							ox_num = other_sum %10
						end
					end
				end
			end
		end

		if is_ox_two then
			return const.OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
		end
		if is_three_eq_ten then
			return const.OX_CARD_TYPE_OX_ONE,val_list,get_color(list[1]),ox_num
		end
		return const.OX_CARD_TYPE_OX_NONE, val_list, get_color(list[1])
	end
end

-- 比较牌
function logic.compare_cards(first, second)
	-- ox_type= ox_type_,val_list = value_list_,color = color_,extro_num = extro_num_
	if first.ox_type ~= second.ox_type then
		return first.ox_type > second.ox_type
	end

	--有牛判断,判断倍数
	if first.ox_type == const.OX_CARD_TYPE_OX_ONE then
		if first.cards_times ~= second.cards_times then
			return first.cards_times > second.cards_times
		end
	end
	

	if first.ox_type == const.OX_CARD_TYPE_FOUR_SAMES then
		return first.val_list > second.val_list
	end

	for i=1,5 do
		local v1 = first.val_list[i]
		local v2 = second.val_list[i]
		if v1 > v2 then
			return true
		elseif v1 < v2 then
			return false
		else -- v1 = v2 倍数相等比单张牌大小也相等,再比花色
			return first.color > second.color
		end
	end
	return first.color > second.color
end

--获得赔率
function logic.get_cards_odds(cards_times)
	local times = 1
	if cards_times < 7 then --无牛~~牛六 1赔1
		times = 1
	elseif cards_times >= 7 and cards_times < 10 then--牛七~~牛九 1赔2
		times = 2
	else --牛牛及以上 1赔3
		times = 3
	end
	return times
end

return logic