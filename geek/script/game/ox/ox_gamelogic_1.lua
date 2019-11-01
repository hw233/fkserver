local pb = require "pb_files"
--�߱���ţţ(1��10)��Ϸ�߼�
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



-- �õ�������
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
			-- ��ɫ
			king_ox = king_ox + 1
		elseif val == 9 then
			-- 10��
			is_ten = true
		end

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
			repeat_times = 1
		else
			repeat_times = repeat_times +1
			same_value = list[i]
		end
	end
	if sum_value <= 10 then
		return OX_CARD_TYPE_FIVE_SAMLL,val_list,get_color(list[1])
	end

	if repeat_times == 4 or four_same then
		return OX_CARD_TYPE_FOUR_SAMES,same_value,get_color(list[1])
	end

	-- �廨ţ
	if king_ox == 5 then
		return OX_CARD_TYPE_FIVE_KING,val_list,get_color(list[1])
	end
	-- �Ļ�ţ
	if king_ox == 4 and is_ten then
		return OX_CARD_TYPE_FOUR_KING,val_list,get_color(list[1])
	end

	-- ���������ж�
	local val_ox = {}
	for i=1,5 do
		val_ox[i] = get_value_ox(val_list[i])
	end

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