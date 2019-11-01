local pb = require "pb_files"
--???????(1??10)??????
-- enum CLASSICS_CARD_TYPE
local CLASSICS_CARD_TYPE_NONE = pb.enum("CLASSICS_CARD_TYPE","CLASSICS_CARD_TYPE_NONE")
local CLASSICS_CARD_TYPE_ONE = pb.enum("CLASSICS_CARD_TYPE","CLASSICS_CARD_TYPE_ONE")
local CLASSICS_CARD_TYPE_TWO = pb.enum("CLASSICS_CARD_TYPE", "CLASSICS_CARD_TYPE_TWO")
local CLASSICS_CARD_TYPE_TEN = pb.enum("CLASSICS_CARD_TYPE", "CLASSICS_CARD_TYPE_TEN")
local CLASSICS_CARD_TYPE_FOUR_KING = pb.enum("CLASSICS_CARD_TYPE", "CLASSICS_CARD_TYPE_FOUR_KING")
local CLASSICS_CARD_TYPE_FIVE_KING = pb.enum("CLASSICS_CARD_TYPE", "CLASSICS_CARD_TYPE_FIVE_KING")
local CLASSICS_CARD_TYPE_FOUR_SAMES = pb.enum("CLASSICS_CARD_TYPE", "CLASSICS_CARD_TYPE_FOUR_SAMES")
local CLASSICS_CARD_TYPE_FIVE_SAMLL = pb.enum("CLASSICS_CARD_TYPE","CLASSICS_CARD_TYPE_FIVE_SAMLL")

-- 0??????A??1??��??A??2??????A??3??????A ???? 48??????K??49??��??K??50??????K??51??????K //52:��?? ??53????

--[[-- ??????????10??
local OX_MAX_TIMES = 10

-- ????��?��??
local CLOWN_EXSITS = false

-- ??????????????
local OX_CLASSICS_LIMIT = 500
--]]
-- ??????��
function get_value(card)
	return math.floor(card / 4)
end

-- ??????????
function get_value_ox(val)
	if val >= 9 then
		return 10
	end
	return val + 1
end

-- ???????
function get_color(card)
	return card % 4
end

-- ???????
function get_type_times(cards_type, max_value)
	-- 1. ?????1????
	-- 2. ????1?????????2??????????8????????9????
	-- 3. ?????????10????
	-- ????????10??
	if cards_type >= CLASSICS_CARD_TYPE_TEN then
		return 10
	-- ?N ???????????????
	elseif cards_type == CLASSICS_CARD_TYPE_ONE then
		return max_value
	end
	-- ???????1??
	return 1
end


-- ?????????
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
			-- ???
			king_ox = king_ox + 1
		elseif val == 9 then
			-- 10??
			is_ten = true
		end

		if not last_value then
			last_value = val
			repeat_times = 1
		elseif last_value ~= val then
			if repeat_times ==4 then
				-- 4?????
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
		return CLASSICS_CARD_TYPE_FIVE_SAMLL,val_list,get_color(list[1])
	end

	if repeat_times == 4 or four_same then
		return CLASSICS_CARD_TYPE_FOUR_SAMES,same_value,get_color(list[1])
	end

	-- ?��?
	if king_ox == 5 then
		return CLASSICS_CARD_TYPE_FIVE_KING,val_list,get_color(list[1])
	end
	-- ????
	if king_ox == 4 and is_ten then
		return CLASSICS_CARD_TYPE_FOUR_KING,val_list,get_color(list[1])
	end

	local is_three_eq_ten, is_ox_ox, ox_num, sort_cards = cal_ox_normal_type(val_list, list)

	if is_ox_ox then
		return CLASSICS_CARD_TYPE_TEN,val_list,get_color(list[1]), 10, sort_cards
	end
	if is_three_eq_ten then
		return CLASSICS_CARD_TYPE_ONE,val_list,get_color(list[1]),ox_num, sort_cards
	end
	return CLASSICS_CARD_TYPE_NONE, val_list, get_color(list[1])
end


function cal_ox_normal_type(val_list, list)
	local val_ox = {}
	for i=1,5 do
		val_ox[i] = get_value_ox(val_list[i])
	end

	local is_three_eq_ten =false -- ???????????????10?????
	local is_ox_ox = false -- ???????
	local ox_num = 0 -- ?1?????
	local sort_cards = {}

	for i=1,3 do
		for j =i+1,4 do
			for k=j+1,5 do
				if (val_ox[i] + val_ox[j] + val_ox[k]) %10 ==0 then
					is_three_eq_ten = true
					
					--???????????
					sort_cards = {list[i], list[j], list[k]}

					--????????????sort_cards?��
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
						--??
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

--???????
function get_cards_odds(cards_times)
	local times = 1
	if cards_times < 7 then --???~~??? 1??1
		times = 1
	elseif cards_times >= 7 and cards_times < 10 then--???~~??? 1??2
		times = 2
	else --???????? 1??3
		times = 3
	end
	return times
end


-- ?????
function compare_cards(first, second)
	-- ox_type= ox_type_,val_list = value_list_,color = color_,extro_num = extro_num_
	if first.ox_type ~= second.ox_type then
		return first.ox_type > second.ox_type
	end

	--????��?,?��????
	if first.ox_type == CLASSICS_CARD_TYPE_ONE then
		if first.cards_times ~= second.cards_times then
			return first.cards_times > second.cards_times
		end
	end
	

	if first.ox_type == CLASSICS_CARD_TYPE_FOUR_SAMES then
		return first.val_list > second.val_list
	end

	for i=1,5 do
		local v1 = first.val_list[i]
		local v2 = second.val_list[i]
		if v1 > v2 then
			return true
		elseif v1 < v2 then
			return false
		else -- v1 = v2 ??????????????��????,?????
			return first.color > second.color
		end
	end
	return first.color > second.color
end