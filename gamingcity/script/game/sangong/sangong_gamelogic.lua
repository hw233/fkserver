local pb = require "pb"
--¸ß±¶³¡Å£Å£(1Åâ10)ÓÎÏ·Âß¼­
-- enum CLASSICS_CARD_TYPE

local SG_CARD_TYPE_NONE = pb.enum("SG_CARD_TYPE", "SG_CARD_TYPE_NONE")
local SG_CARD_TYPE_ONE = pb.enum("SG_CARD_TYPE", "SG_CARD_TYPE_ONE")
local SG_CARD_TYPE_H_KING = pb.enum("SG_CARD_TYPE", "SG_CARD_TYPE_H_KING")
local SG_CARD_TYPE_LIT_KING = pb.enum("SG_CARD_TYPE", "SG_CARD_TYPE_LIT_KING")
local SG_CARD_TYPE_BIG_KING = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_BIG_KING")
local SG_CARD_TYPE_ONE = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_ONE")
local SG_CARD_TYPE_TWO = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_TWO")
local SG_CARD_TYPE_THREE = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_THREE")
local SG_CARD_TYPE_FOUR = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_FOUR")
local SG_CARD_TYPE_FIVE = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_FIVE")
local SG_CARD_TYPE_SIX = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_SIX")
local SG_CARD_TYPE_SEVEN = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_SEVEN")
local SG_CARD_TYPE_EIGHT = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_EIGHT")
local SG_CARD_TYPE_NIGHT = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_NIGHT")
local SG_CARD_TYPE_TEN = pb.enum("SG_CARD_TYPE","SG_CARD_TYPE_TEN")

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
function get_type_times(ox_type_, extro_num_)
	-- 1. 大三公 4
	-- 2. 小三公 4
	-- 3. 混三公 3
	-- 4. 特点数 2
	-- 5. 散牌点 1
	if ox_type_ >= SG_CARD_TYPE_BIG_KING then
		return 4
	elseif ox_type_ >= SG_CARD_TYPE_LIT_KING then
		return 4
	elseif ox_type_ >= SG_CARD_TYPE_H_KING then
		return 3
	elseif  ox_type_ == SG_CARD_TYPE_ONE and  extro_num_ >= 8 then
		return 2
	else
		return 1
	end
end

-- µÃµ½ÅÆÀàÐÍ
function get_cards_type(cards)
	local list = {}
	for i=1,3 do
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
	local all_same = false
	local same_value = nil
	local sum_value =0
	local other = 0  --除去10 + 花色

	for i =1,3 do
		local  val = math.floor(list[i]/4)
		sum_value = sum_value + val +1
		val_list[i] = val
		if val > 9 then
			-- 花色
			king_ox = king_ox + 1
		elseif val == 9 then
			-- 10点
			is_ten = true
		else
			other = other + 1
		end

		if not last_value then
			last_value = val
			repeat_times = 1
		elseif last_value ~= val then
			if repeat_times ==3 then
				-- 3个相同
				all_same = true
				same_value = list[i]
			end
			last_value = val
			repeat_times = 1
		else
			repeat_times = repeat_times +1
			same_value = list[i]
		end
	end

	-- 大三公
	if king_ox == 3 and repeat_times == 3 then
		return SG_CARD_TYPE_BIG_KING,val_list,get_color(list[1]),get_value(list[1])
	end

	-- 小三公
	if repeat_times == 3 or all_same then
		return SG_CARD_TYPE_LIT_KING,val_list,get_color(list[1]),get_value(list[1])
	end

	-- 混三公
	if other == 0 then
		return SG_CARD_TYPE_H_KING,val_list,get_color(list[1]),get_value(list[1])
	end

	local t_num = sum_value % 10
	-- 点数	
	return SG_CARD_TYPE_ONE,val_list, get_color(list[1]), t_num, get_value(list[1])
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
	if first.ox_type ~= second.ox_type then
		return first.ox_type > second.ox_type
	end

	--有牛判断,判断倍数
	if first.ox_type == SG_CARD_TYPE_ONE then
		if first.extro_num_ ~= second.extro_num_ then
			return first.extro_num_ > second.extro_num_
		end
	end

	if  first.big_num ~= second.big_num then
		return first.big_num > second.big_num
	else
		return first.color > second.color
	end
end


-- ·ÖÀë×Ö·û´®
function lua_string_split(str, split_char)      
	local sub_str_tab = {}
   
	while (true) do
		local pos = string.find(str, split_char)  
		if (not pos) then
			local number = tonumber(str)            
			table.insert(sub_str_tab,number)  
			break
		end  
	   
		local sub_str = string.sub(str, 1, pos - 1)
		local number = tonumber(sub_str)
		table.insert(sub_str_tab,number)
		local t = string.len(str)
		str = string.sub(str, pos + 1, t)    
	end      
	return sub_str_tab
end 




function dump(obj)
	local getIndent, wrapKey, wrapVal, dumpObj
	getIndent = function(level)
		return string.rep("\t", level)
	end
	wrapKey = function(val)
		if type(val) == "number" then
			return "" .. val .. ""
		elseif type(val) == "string" then
			return '"' .. val .. '"'
		else
			return "" .. tostring(val) .. ""
		end
	end
	wrapVal = function(val, level)
		if type(val) == "table" then
			return dumpObj(val, level)
		elseif type(val) == "number" then
			return val
		elseif type(val) == "string" then
			return '"' .. val .. '"'
		else
			return tostring(val)
		end
	end
	dumpObj = function(obj, level)
		if type(obj) ~= "table" then
			return wrapVal(obj)
		end
		level = level + 1
		local tokens = {}
		tokens[#tokens + 1] = "{"
		for k, v in pairs(obj) do
			tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
		end
		tokens[#tokens + 1] = getIndent(level - 1) .. "}"
		return table.concat(tokens, "\n")
	end
	--return dumpObj(obj, 0)
	print(dumpObj(obj, 0))
end