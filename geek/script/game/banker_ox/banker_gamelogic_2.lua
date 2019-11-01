local pb = require "pb_files"
--�ͱ���ţţ(1��3)��Ϸ�߼�
-- enum OX_CARD_TYPE
local OX_CARD_TYPE_OX_NONE = pb.enum("OX_CARD_TYPE","OX_CARD_TYPE_OX_NONE")
local OX_CARD_TYPE_OX_ONE = pb.enum("OX_CARD_TYPE","OX_CARD_TYPE_OX_ONE")
local OX_CARD_TYPE_OX_TWO = pb.enum("OX_CARD_TYPE", "OX_CARD_TYPE_OX_TWO")
local OX_CARD_TYPE_FOUR_KING = pb.enum("OX_CARD_TYPE", "OX_CARD_TYPE_FOUR_KING")
local OX_CARD_TYPE_FIVE_KING = pb.enum("OX_CARD_TYPE", "OX_CARD_TYPE_FIVE_KING")
local OX_CARD_TYPE_FOUR_SAMES = pb.enum("OX_CARD_TYPE", "OX_CARD_TYPE_FOUR_SAMES")
local OX_CARD_TYPE_FIVE_SAMLL = pb.enum("OX_CARD_TYPE","OX_CARD_TYPE_FIVE_SAMLL")
-- enum OX_SCORE_AREA
local OX_AREA_ONE = pb.enum("OX_SCORE_AREA","OX_AREA_ONE")
local OX_AREA_TWO = pb.enum("OX_SCORE_AREA","OX_AREA_TWO")
local OX_AREA_THREE = pb.enum("OX_SCORE_AREA","OX_AREA_THREE")
local OX_AREA_FOUR = pb.enum("OX_SCORE_AREA","OX_AREA_FOUR")

-- 0������A��1��÷��A��2������A��3������A ���� 48������K��49��÷��K��50������K��51������K��52:С�� ��53����

--[[-- ������ʱ���10��
local OX_MAX_TIMES = 10

-- �Ƿ��д�С��
local CLOWN_EXSITS = false

-- ��ׯ�����������
local OX_BANKER_LIMIT = 500
--]]
-- �õ��ƴ�С
function get_value(card)
	return math.floor(card / 4)
end

-- �õ�ţţ����ֵ
function get_value_ox(val)
	if val >= 9 then
		return 10
	end
	return val + 1
end

-- �õ��ƻ�ɫ
function get_color(card)
	return card % 4
end

-- �õ�����
function get_type_times(cards_type,max_value)
	-- 1. ��ţ��1����
	-- 2. ţһ��1����ţ����2������ţ�ˣ�8����ţ�ţ�9����
	-- 3. ţţ�����ϣ�10����
	-- ţţ������10��
	if cards_type >= OX_CARD_TYPE_OX_TWO then
		return 10
	-- ţN ���������ֵ�ı���
	elseif cards_type == OX_CARD_TYPE_OX_ONE then
		return max_value
	end
	-- ������Ϊ1��
	return 1
end

-- �д�����С��(Ҳ�п��ܰ���������)
function include_king(card)
	local bomb_num = 0
	for i=1,5 do
		if card[i] == 52 or card[i] == 53 then
			bomb_num = bomb_num + 1
		end
	end
	return bomb_num
end

-- �õ�������
function get_cards_type(cards)
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
			-- 10��
			is_ten = true
		elseif val > 9 and val < 13 then
			-- ��ɫ
			king_ox = king_ox + 1
		elseif val == 13 then
			-- ����
			bomb_num = bomb_num + 1
		end
	
		if list[i] ~= 52 and list[i] ~= 53 then
			if not last_value then
				last_value = val
				repeat_times = 1
			elseif last_value ~= val then
				if repeat_times ==4 then
					-- 4����ͬ
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
		return OX_CARD_TYPE_FIVE_SAMLL,val_list,get_color(list[1])
	end

	if repeat_times == 4 - king_num or four_same then
		return OX_CARD_TYPE_FOUR_SAMES,same_value,get_color(list[1])
	end

	-- �廨ţ
	if king_ox == 5 - king_num then
		return OX_CARD_TYPE_FIVE_KING,val_list,get_color(list[1])
	end
	-- �Ļ�ţ
	if king_ox == 4 - king_num and is_ten then
		return OX_CARD_TYPE_FOUR_KING,val_list,get_color(list[1])
	end

	-- ���������ж�
	local val_ox = {}
	for i=1,5 do
		val_ox[i] = get_value_ox(val_list[i])
	end

	if king_num == 2 then --������ֱ�ӷ���ţţ
		return OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
	elseif king_num == 1 then --ֻ��һ����
		for i=2, 3 do
			for j=i+1, 4 do
				for k =j+1, 5 do
					if (val_ox[i] + val_ox[j] + val_ox[k]) %10 ==0 then
						return OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
					end
				end
			end
		end             
	
		local max_value = 0
		for i=2, 4 do
			for j=i+1,5 do
				if (val_ox[i] + val_ox[j]) %10 == 0 then
					return OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
				end
				if (val_ox[i] + val_ox[j]) %10 > max_value then
					max_value = (val_ox[i] + val_ox[j]) %10
				end
			end
		end
		return OX_CARD_TYPE_OX_ONE,val_list,get_color(list[1]),max_value
	else  --�޴�С��
	
		local is_three_eq_ten =false -- �Ƿ����������ĺ�Ϊ10�ı���
		local is_ox_two = false -- �Ƿ���ţţ
		local ox_num = 0 -- ţ1��ţ��
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
							--ţţ
							is_ox_two = true
						else
							ox_num = other_sum %10
						end
					end
				end
			end
		end

		if is_ox_two then
			return OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
		end
		if is_three_eq_ten then
			return OX_CARD_TYPE_OX_ONE,val_list,get_color(list[1]),ox_num
		end
		return OX_CARD_TYPE_OX_NONE, val_list, get_color(list[1])
	end

end

-- �Ƚ���
function compare_cards(first, second)
	-- ox_type= ox_type_,val_list = value_list_,color = color_,extro_num = extro_num_
	if first.ox_type ~= second.ox_type then
		return first.ox_type > second.ox_type
	end

	--��ţ�ж�,�жϱ���
	if first.ox_type == OX_CARD_TYPE_OX_ONE then
		if first.cards_times ~= second.cards_times then
			return first.cards_times > second.cards_times
		end
	end
	

	if first.ox_type == OX_CARD_TYPE_FOUR_SAMES then
		return first.val_list > second.val_list
	end

	for i=1,5 do
		local v1 = first.val_list[i]
		local v2 = second.val_list[i]
		if v1 > v2 then
			return true
		elseif v1 < v2 then
			return false
		else -- v1 = v2 ������ȱȵ����ƴ�СҲ���,�ٱȻ�ɫ
			return first.color > second.color
		end
	end
	return first.color > second.color
end

--�������
function get_cards_odds(cards_times)
	local times = 1
	if cards_times < 7 then --��ţ~~ţ�� 1��1
		times = 1
	elseif cards_times >= 7 and cards_times < 10 then--ţ��~~ţ�� 1��2
		times = 2
	else --ţţ������ 1��3
		times = 3
	end
	return times
end