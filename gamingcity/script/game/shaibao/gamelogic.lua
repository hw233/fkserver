local pb = require "pb"
local random = require "random"

local BET_XIAO    = pb.enum("SHAIBAO_BET_AREA", "BET_XIAO")
local BET_DA      = pb.enum("SHAIBAO_BET_AREA", "BET_DA")
local BET_ZD_WS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_1")
local BET_ZD_WS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_2")
local BET_ZD_WS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_3")
local BET_ZD_WS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_4")
local BET_ZD_WS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_5")
local BET_ZD_WS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_6")
local BET_RY_WS   = pb.enum("SHAIBAO_BET_AREA", "BET_RY_WS")
local BET_ZD_DS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_1")
local BET_ZD_DS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_2")
local BET_ZD_DS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_3")
local BET_ZD_DS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_4")
local BET_ZD_DS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_5")
local BET_ZD_DS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_6")
local BET_ZD_SS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_1")
local BET_ZD_SS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_2")
local BET_ZD_SS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_3")
local BET_ZD_SS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_4")
local BET_ZD_SS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_5")
local BET_ZD_SS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_6")
local BET_DH_4    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_4")
local BET_DH_5    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_5")
local BET_DH_6    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_6")
local BET_DH_7    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_7")
local BET_DH_8    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_8")
local BET_DH_9    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_9")
local BET_DH_10   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_10")
local BET_DH_11   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_11")
local BET_DH_12   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_12")
local BET_DH_13   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_13")
local BET_DH_14   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_14")
local BET_DH_15   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_15")
local BET_DH_16   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_16")
local BET_DH_17   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_17")

-- �����ַ���
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

--����talbe����
function shuffle(t)
    if type(t)~="table" then
        return
    end
    local l=#t
    local tab={}
    local index=1
    while #t~=0 do
        local n=random.boost_integer(1,#t)
        if t[n]~=nil then
            tab[index]=t[n]
            table.remove(t,n)
            index=index+1
        end
    end
    return tab
end




gamelogic = {}


function print_cards(cards,id)
	print(id,cards[1],cards[2],cards[3])
end

--��ȡ����
function gamelogic.GetCardsTimes(cards,ctype)
	--Χ��
	if ctype >= BET_ZD_WS_1 and ctype <= BET_RY_WS then
		if cards[1] == cards[2] and cards[2] == cards[3] then
			if ctype == BET_RY_WS then
				return 24
			elseif ctype - BET_ZD_WS_1 + 1 == cards[1] then
				return 150
			end
		end
	--����
	elseif ctype >= BET_ZD_DS_1 and ctype <= BET_ZD_DS_6 then
		local num = gamelogic.GetCardsCount(cards,ctype - BET_ZD_DS_1 + 1)
		if num > 0 then
			return num
		end
	--˫��
	elseif ctype >= BET_ZD_SS_1 and ctype <= BET_ZD_SS_6 then
		local num = gamelogic.GetCardsCount(cards,ctype - BET_ZD_SS_1 + 1)
		if num >= 2 then
			return 8
		end
	--��ͣ���С
	else
		local num = cards[1] + cards[2] + cards[3]
		if ctype == BET_XIAO or ctype == BET_DA then
			--��Χׯ��ͨ��
			if cards[1] == cards[2] and cards[2] == cards[3] then
				return 0
			end
			if num >= 4 and num <= 10 and ctype == BET_XIAO then
				return 1
			elseif num >= 11 and num <= 17 and ctype == BET_DA then
				return 1
			end
		elseif ctype >= BET_DH_4 and ctype <= BET_DH_17 then
			local count = ctype - BET_DH_4 + 4
			if count == num and (num == 4 or num == 17) then
				return 50
			elseif count == num and (num == 5 or num == 16) then
				return 18
			elseif count == num and (num == 6 or num == 15) then
				return 14
			elseif count == num and (num == 7 or num == 14) then
				return 12
			elseif count == num and (num == 8 or num == 13) then
				return 8
			elseif count == num and (num == 9 or num == 10 or num == 11 or num == 12) then
				return 6
			end
		end
	end
	return 0
end

function gamelogic.GetCardsCount(cards,num)
	local count = 0
	for _,v in pairs(cards) do
		if num == v then
			count = count + 1
		end
	end
	return count
end

function gamelogic.GetPointCards(min,max)
	local result = {}
	for i=1,6 do
		for j=1,6 do
			for k=1,6 do
				if i + j + k <= max and i + j + k >= min and (i ~= j or j ~= k or i ~= k) then
					table.insert(result,{i,j,k})
				end
			end
		end
	end
	return result[random.boost_integer(1,#result)]
end