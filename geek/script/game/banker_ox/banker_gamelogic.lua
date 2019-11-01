local pb = require "pb_files"
--¸ß±¶³¡Å£Å£(1Åâ10)ÓÎÏ·Âß¼­
-- enum BANKER_CARD_TYPE
local BANKER_CARD_TYPE_NONE = pb.enum("BANKER_CARD_TYPE","BANKER_CARD_TYPE_NONE")
local BANKER_CARD_TYPE_ONE = pb.enum("BANKER_CARD_TYPE","BANKER_CARD_TYPE_ONE")
local BANKER_CARD_TYPE_TWO = pb.enum("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_TWO")
local BANKER_CARD_TYPE_TEN = pb.enum("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_TEN")
local BANKER_CARD_TYPE_FOUR_KING = pb.enum("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_FOUR_KING")
local BANKER_CARD_TYPE_FIVE_KING = pb.enum("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_FIVE_KING")
local BANKER_CARD_TYPE_FOUR_SAMES = pb.enum("BANKER_CARD_TYPE", "BANKER_CARD_TYPE_FOUR_SAMES")
local BANKER_CARD_TYPE_FIVE_SAMLL = pb.enum("BANKER_CARD_TYPE","BANKER_CARD_TYPE_FIVE_SAMLL")

-- 0£º·½¿éA£¬1£ºÃ·»¨A£¬2£ººìÌÒA£¬3£ººÚÌÒA ¡­¡­ 48£º·½¿éK£¬49£ºÃ·»¨K£¬50£ººìÌÒK£¬51£ººÚÌÒK //52:Ð¡Íõ £¬53´óÍõ

--[[-- ×î´óÅâÂÊ±¶Êý10±¶
local OX_MAX_TIMES = 10

-- ÊÇ·ñÓÐ´óÐ¡Íõ
local CLOWN_EXSITS = false

-- ÉÏ×¯Ìõ¼þ½ð±ÒÏÞÖÆ
local OX_BANKER_LIMIT = 500
--]]
-- µÃµ½ÅÆ´óÐ¡
function get_value(card)
	return math.floor(card / 4)
end

-- µÃµ½Å£Å£¼ÆËãÖµ
function get_value_ox(val)
	if val >= 9 then
		return 10
	end
	return val + 1
end

-- µÃµ½ÅÆ»¨É«
function get_color(card)
	return card % 4
end

-- µÃµ½±¶Êý
function get_type_times(cards_type, max_value)
	-- 1. ÎÞÅ££º1±¶¡£
	-- 2. Å£Ò»£º1±¶£¬Å£¶þ£º2±¶¡­¡­Å£°Ë£º8±¶£¬Å£¾Å£º9±¶¡£
	-- 3. Å£Å£¼°ÒÔÉÏ£º10±¶¡£
	-- Å£Å£¼°ÒÔÉÏ10±¶
	if cards_type >= BANKER_CARD_TYPE_TEN then
		return 10
	-- Å£N ·µ»Ø×î´óÊýÖµµÄ±¶ÂÊ
	elseif cards_type == BANKER_CARD_TYPE_ONE then
		return max_value
	end
	-- ÆäËü¾ùÎª1±¶
	return 1
end


-- µÃµ½ÅÆÀàÐÍ
function get_cards_type(cards)
	--[[
		params: cards
		return ox,val_list,max_color,max_value
	]]

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

	for i =1,5 do
		local  val = math.floor(list[i]/4)
		sum_value = sum_value + val +1
		val_list[i] = val
		if val > 9 then
			-- »¨É«
			king_ox = king_ox + 1
		elseif val == 9 then
			-- 10µã
			is_ten = true
		end

		if not last_value then
			last_value = val
			repeat_times = 1
		elseif last_value ~= val then
			if repeat_times ==4 then
				-- 4¸öÏàÍ¬
				four_same = true
				same_value = list[i]
			end
			last_value = val
			repeat_times = 1
		else
			repeat_times = repeat_times +1
			same_value = list[i]
		end
	end

	if sum_value <= 10 then
		return BANKER_CARD_TYPE_FIVE_SAMLL,val_list,get_color(list[1])
	end

	if repeat_times == 4 or four_same then
		return BANKER_CARD_TYPE_FOUR_SAMES,same_value,get_color(list[1])
	end

	-- Îå»¨Å£
	if king_ox == 5 then
		return BANKER_CARD_TYPE_FIVE_KING,val_list,get_color(list[1])
	end
	-- ËÄ»¨Å£
	if king_ox == 4 and is_ten then
		return BANKER_CARD_TYPE_FOUR_KING,val_list,get_color(list[1])
	end

	local is_three_eq_ten, is_ox_ox, ox_num, sort_cards = cal_ox_normal_type(val_list, list)

	if is_ox_ox then
		return BANKER_CARD_TYPE_TEN,val_list,get_color(list[1]), 10, sort_cards
	end
	if is_three_eq_ten then
		return BANKER_CARD_TYPE_ONE,val_list,get_color(list[1]),ox_num, sort_cards
	end
	return BANKER_CARD_TYPE_NONE, val_list, get_color(list[1])
end


function cal_ox_normal_type(val_list, list)
	local val_ox = {}
	for i=1,5 do
		val_ox[i] = get_value_ox(val_list[i])
	end

	local is_three_eq_ten =false -- ÊÇ·ñÓÐÈý¸öÊýµÄºÍÎª10µÄ±¶Êý
	local is_ox_ox = false -- ÊÇ·ñÊÇÅ£Å£
	local ox_num = 0 -- Å£1µÄÅ£Êý
	local sort_cards = {}

	for i=1,3 do
		for j =i+1,4 do
			for k=j+1,5 do
				if (val_ox[i] + val_ox[j] + val_ox[k]) %10 ==0 then
					is_three_eq_ten = true
					
					--ÅÅÐòµÄÈýÕÅÅÆ
					sort_cards = {list[i], list[j], list[k]}

					--Ê£ÏÂÁ½ÕÅÅÆ·ÅÈësort_cardsÄ©Î²
					for x=1,5 do
						local same_flag = 0
						for y=1,3 do
							if list[x] == sort_cards[y] then
								same_flag = 1
								break
							end
						end
						
						if same_flag == 0 then
							table.insert(sort_cards, list[x])
						end						
					end

					local other_sum =0
					for m=1,5 do
						if m ~=i and m ~=j and m~=k then
							other_sum = other_sum + val_ox[m]
						end
					end
					if(other_sum)%10 ==0 then
						--Å£Å£
						is_ox_ox = true
					else
						ox_num = other_sum %10
					end

					return is_three_eq_ten, is_ox_ox, ox_num, sort_cards
				end
			end
		end
	end

	return is_three_eq_ten, is_ox_ox, ox_num, {}
end

--»ñµÃÅâÂÊ
function get_cards_odds(cards_times)
	local times = 1
	if cards_times < 7 then --ÎÞÅ£~~Å£Áù 1Åâ1
		times = 1
	elseif cards_times >= 7 and cards_times < 10 then--Å£Æß~~Å£¾Å 1Åâ2
		times = 2
	else --Å£Å£¼°ÒÔÉÏ 1Åâ3
		times = 3
	end
	return times
end

-- ±È½ÏÅÆ
function compare_cards(first, second)
	-- ox_type= ox_type_,val_list = value_list_,color = color_,extro_num = extro_num_
	if first.ox_type ~= second.ox_type then
		return first.ox_type > second.ox_type
	end

	--ÓÐÅ£ÅÐ¶Ï,ÅÐ¶Ï±¶Êý
	if first.ox_type == BANKER_CARD_TYPE_ONE then
		if first.cards_times ~= second.cards_times then
			return first.cards_times > second.cards_times
		end
	end
	

	if first.ox_type == BANKER_CARD_TYPE_FOUR_SAMES then
		return first.val_list > second.val_list
	end

	for i=1,5 do
		local v1 = first.val_list[i]
		local v2 = second.val_list[i]
		if v1 > v2 then
			return true
		elseif v1 < v2 then
			return false
		else -- v1 = v2 ±¶ÊýÏàµÈ±Èµ¥ÕÅÅÆ´óÐ¡Ò²ÏàµÈ,ÔÙ±È»¨É«
			return first.color > second.color
		end
	end
	return first.color > second.color
end

function  change_card( cards_1, cards_2, index)
	local var = cards_1[5]
	cards_1[5] = cards_2[index]
	cards_2[index] = var
end

function get_max_card(cards_list, cards, cards_num)
	local list = {}
	local new_cards_list = {}
	for i = 1, 4 do
		list[i] = cards[i]
	end
	table.sort(list, function (a, b)
		return a > b
	end)

	for i = 1, cards_num do
		new_cards_list[i] = cards_list[i]
	end
	table.sort(new_cards_list, function (a, b)
		return a > b
	end)

	local index = 0
	local b_player = get_cards_run_type( cards )
	local val = nil
	--找出最大的
	for i = 1, cards_num do
		local b_check = true
		if val == nil then
			val = new_cards_list[i]
		elseif get_value(val) == get_value(new_cards_list[i]) then
			b_check = false
		end
		if b_check then
			list[5] = new_cards_list[i]
			local b_new = get_cards_run_type( list )
			local win = compare_cards(b_new, b_player)
			if win == true then
				b_player = b_new
				index = i
			end
		end
	end
	cards_list = new_cards_list
	if index == 0 then
		print("---------------------change_card A")
		return false,cards_list
	else		
		change_card(cards, cards_list, index)
		print("---------------------change_card B")
		return true,cards_list
	end
end

function get_mix_card(cards_list, cards, cards_num)
	local list = {}
	local new_cards_list = {}
	for i = 1, 4 do
		list[i] = cards[i]
	end
	table.sort(list, function (a, b)
		return a > b
	end)

	for i = 1, cards_num do
		new_cards_list[i] = cards_list[i]
	end
	table.sort(new_cards_list, function (a, b)
		return a > b
	end)

	local index = 0
	local b_player = get_cards_run_type( cards )
	local val = nil
	--找出最大的
	for i = 1, cards_num do
		local b_check = true
		if val == nil then
			val = new_cards_list[i]
		elseif get_value(val) == get_value(new_cards_list[i]) then
			b_check = false
		end
		if b_check then
			list[5] = new_cards_list[i]
			local b_new = get_cards_run_type( list )
			local win = compare_cards(b_new, b_player)
			if win == false then
				b_player = b_new
				index = i
			end
		end
	end
	cards_list = new_cards_list
	if index == 0 then
		print("---------------------change_card A")
		return false,cards_list
	else		
		change_card(cards, cards_list, index)
		print("---------------------change_card B")
		return true,cards_list
	end
end

function get_cards_run_type( cards )

	--算出牌型，倍数
	local ox_type_,value_list_,color_, extro_num_, sort_cards_ = get_cards_type(cards)
	local times = get_type_times(ox_type_,extro_num_)
	b_ret = 
	{
		ox_type = ox_type_, 
		val_list = value_list_, 
		color = color_, 
		extro_num = extro_num_, 
		cards_times = times
	}
	return b_ret
end