local pb = require "pb"
local random = require "random"

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



-- enum REDBLACK_CARD_TYPE
REDBLACK_CARD_TYPE_SPECIAL = pb.enum("REDBLACK_CARD_TYPE", "REDBLACK_CARD_TYPE_SPECIAL")
REDBLACK_CARD_TYPE_SINGLE = pb.enum("REDBLACK_CARD_TYPE", "REDBLACK_CARD_TYPE_SINGLE")
REDBLACK_CARD_TYPE_DOUBLE = pb.enum("REDBLACK_CARD_TYPE", "REDBLACK_CARD_TYPE_DOUBLE")
REDBLACK_CARD_TYPE_SHUN_ZI = pb.enum("REDBLACK_CARD_TYPE", "REDBLACK_CARD_TYPE_SHUN_ZI")
REDBLACK_CARD_TYPE_JIN_HUA = pb.enum("REDBLACK_CARD_TYPE", "REDBLACK_CARD_TYPE_JIN_HUA")
REDBLACK_CARD_TYPE_SHUN_JIN = pb.enum("REDBLACK_CARD_TYPE", "REDBLACK_CARD_TYPE_SHUN_JIN")
REDBLACK_CARD_TYPE_BAO_ZI = pb.enum("REDBLACK_CARD_TYPE", "REDBLACK_CARD_TYPE_BAO_ZI")


gamelogic = {}
gamelogic.cards = {}
for i = 0,51 do
	table.insert(gamelogic.cards,i)
end
-- 0������2��1��÷��2��2������2��3������2 ���� 48������A��49��÷��A��50������A��51������A
function gamelogic.RandCards()
	local red = {}
	local black = {}
	while true do
		red = {}
		black = {}
		gamelogic.cards = shuffle(gamelogic.cards)
		for i = 1,6 do
			if i % 2 == 0 then
				table.insert(black,gamelogic.cards[i])
			else
				table.insert(red,gamelogic.cards[i])
			end
		end
		if gamelogic.CheckCardsValue(red,black) == false then
			break
		end
	end
	return red,black
end

--�����ض�����
function gamelogic.RandCardsType(cards_type)
	gamelogic.cards = shuffle(gamelogic.cards)
	local red = {}
	local black = {}
	local sidx = 1
	local eidx = 52
	--����
	if cards_type == REDBLACK_CARD_TYPE_BAO_ZI then
		local card = gamelogic.cards[random.boost_integer(sidx,eidx)]
		local v = gamelogic.GetValue(card)
		table.insert(black,card)
		for i = sidx,eidx do
			if v == gamelogic.GetValue(gamelogic.cards[i]) then
				local ok = true
				for _,c in pairs(black) do
					if c == gamelogic.cards[i] then
						ok = false
						break
					end
				end
				if ok then
					table.insert(black,gamelogic.cards[i])
					if #black == 3 then
						break
					end
				end
			end
		end
	end
	--˳��
	if cards_type == REDBLACK_CARD_TYPE_SHUN_JIN then
		local card = gamelogic.cards[random.boost_integer(sidx,eidx)]
		local c = gamelogic.GetColor(card)
		local v1 = gamelogic.GetValue(card)
		local v2 = v1 + 1
		local v3 = v2 + 1		
		if v1 == 12 then
			v2 = v1 - 1
			v3 = v2 - 1
		end
		table.insert(black,card)
		for i = sidx,eidx do
			if c == gamelogic.GetColor(gamelogic.cards[i]) and (v2 == gamelogic.GetValue(gamelogic.cards[i]) or v3 == gamelogic.GetValue(gamelogic.cards[i])) then
				local ok = true
				for _,c in pairs(black) do
					if c == gamelogic.cards[i] or gamelogic.GetValue(gamelogic.cards[i]) == gamelogic.GetValue(c) then
						ok = false
						break
					end
				end
				if ok then
					table.insert(black,gamelogic.cards[i])
					if #black == 3 then
						break
					end
				end
			end
		end
	end
	--��
	if cards_type == REDBLACK_CARD_TYPE_JIN_HUA then
		local card = gamelogic.cards[random.boost_integer(sidx,eidx)]
		local c = gamelogic.GetColor(card)
		table.insert(black,card)
		for i = sidx,eidx do
			if c == gamelogic.GetColor(gamelogic.cards[i]) then
				local ok = true
				for _,c in pairs(black) do
					if c == gamelogic.cards[i] then
						ok = false
						break
					end
				end
				if ok then
					table.insert(black,gamelogic.cards[i])
					if #black == 3 then
						break
					end
				end
			end
		end
	end
	--˳��
	if cards_type == REDBLACK_CARD_TYPE_SHUN_ZI then
		local card = gamelogic.cards[random.boost_integer(sidx,eidx)]
		local c = gamelogic.GetColor(card)
		local v1 = gamelogic.GetValue(card)
		local v2 = v1 + 1
		local v3 = v2 + 1		
		if v1 == 12 then
			v2 = v1 - 1
			v3 = v2 - 1
		end
		table.insert(black,card)
		for i = sidx,eidx do
			if c ~= gamelogic.GetColor(gamelogic.cards[i]) and (v2 == gamelogic.GetValue(gamelogic.cards[i]) or v3 == gamelogic.GetValue(gamelogic.cards[i])) then
				local ok = true
				for _,c in pairs(black) do
					if c == gamelogic.cards[i] or gamelogic.GetValue(gamelogic.cards[i]) == gamelogic.GetValue(c) then
						ok = false
						break
					end
				end
				if ok then
					table.insert(black,gamelogic.cards[i])
					if #black == 3 then
						break
					end
				end
			end
		end
	end
	--����
	if cards_type == REDBLACK_CARD_TYPE_DOUBLE then
		local card = gamelogic.cards[random.boost_integer(sidx,eidx)]
		local v = gamelogic.GetValue(card)
		table.insert(black,card)
		for i = sidx,eidx do
			if v == gamelogic.GetValue(gamelogic.cards[i]) then
				local ok = true
				for _,c in pairs(black) do
					if c == gamelogic.cards[i] then
						ok = false
						break
					end
				end
				if ok then
					table.insert(black,gamelogic.cards[i])
					if #black == 2 then
						break
					end
				end
			end
		end
	end
	--����
	for bidx = #black,2 do
		for i = sidx,eidx do
			local ok = true
			for _,v in pairs(black) do
				if v == gamelogic.cards[i] or gamelogic.GetValue(v) == gamelogic.GetValue(gamelogic.cards[i]) then
					ok = false
					break
				end
			end
			if ok then
				table.insert(black,gamelogic.cards[i])
				if #black == 3 then
					break
				end
			end
		end
	end
	for ridx = 1,3 do
		for i = sidx,eidx do
			local ok = true
			for _,v in pairs(black) do
				if v == gamelogic.cards[i] then
					ok = false
					break
				end
			end
			for _,v in pairs(red) do
				if v == gamelogic.cards[i] then
					ok = false
					break
				end
			end
			if ok then
				table.insert(red,gamelogic.cards[i])
				if #red == 3 then
					break
				end
			end
		end
		if #red == 3 then
			break
		end
	end
	if random.boost_integer(1,100) < 50 then
		return red,black
	end
	return black,red
end

function print_cards(cards,id)
	local str = string.format("%s==>",id)
	for _,card in pairs(cards) do
		local c = gamelogic.GetColor(card)
		if c == 0 then
			c = "��"
		elseif c == 1 then
			c = "÷"
		elseif c == 2 then
			c = "��"
		else
			c = "��"
		end
		local v = gamelogic.GetValue(card)
		if v == 12 then
			v = "A"
		elseif v == 11 then
			v = "K"
		elseif v == 10 then
			v = "Q"
		elseif v == 9 then
			v = "J"
		else
			v = string.format("%d",v + 2)
		end
		str = string.format("%s%s%s ",str,c,v)
	end
	log.info(str)
end

--��ȡ����
--��ʤ	1��2
--��ʤ	1��2
--����	1��11
--˳��	1��6
--ͬ��	1��4
--˳��	1��3
--����8������	1��2
function gamelogic.GetCardsTimes(cardsinfo)
	if cardsinfo.cards_type == REDBLACK_CARD_TYPE_BAO_ZI then
		return 11
	end
	if cardsinfo.cards_type == REDBLACK_CARD_TYPE_SHUN_JIN then
		return 6
	end
	if cardsinfo.cards_type == REDBLACK_CARD_TYPE_JIN_HUA then
		return 4
	end
	if cardsinfo.cards_type == REDBLACK_CARD_TYPE_SHUN_ZI then
		return 3
	end
	if cardsinfo.cards_type == REDBLACK_CARD_TYPE_DOUBLE and cardsinfo[1] >= 6 then
		return 2
	end
	return 0
end

-- �õ��ƴ�С
function gamelogic.GetValue(card)
	return math.floor(card / 4)
end

-- �õ��ƻ�ɫ
function gamelogic.GetColor(card)
	return card % 4
end

-- �õ�������
function gamelogic.GetCardsType(cards)
	local v = {
		gamelogic.GetValue(cards[1]),
		gamelogic.GetValue(cards[2]),
		gamelogic.GetValue(cards[3]),
	}

	-- ����
	if v[1] == v[2] and v[2] == v[3] then
		return REDBLACK_CARD_TYPE_BAO_ZI, v[1]
	end

	-- ����
	if v[1] == v[2] then
		return REDBLACK_CARD_TYPE_DOUBLE, v[1], v[3]
	elseif v[1] == v[3] then
		return REDBLACK_CARD_TYPE_DOUBLE, v[1], v[2]
	elseif v[2] == v[3] then
		return REDBLACK_CARD_TYPE_DOUBLE, v[2], v[1]
	end
	
	table.sort(v)

	local val = nil
	local is_shun_zi = false
	if v[1]+1 == v[2] and v[2]+1 == v[3] then 
		is_shun_zi = true
		val = v[3]
	elseif v[1] == 0 and v[2] == 1 and v[3] == 12 then
		is_shun_zi = true
		val = 1
	end

	local c1 = gamelogic.GetColor(cards[1])
	local c2 = gamelogic.GetColor(cards[2])
	local c3 = gamelogic.GetColor(cards[3])
	if c1 == c2 and c2 == c3 then
		if is_shun_zi then
			-- ˳��
			return REDBLACK_CARD_TYPE_SHUN_JIN, val
		else
			-- ��
			return REDBLACK_CARD_TYPE_JIN_HUA, v[3], v[2], v[1]
		end
	elseif is_shun_zi then
		-- ˳��
		return REDBLACK_CARD_TYPE_SHUN_ZI, val
	end

	return REDBLACK_CARD_TYPE_SINGLE, v[3], v[2], v[1]
end

--������Ƿ���ֵһ��
function gamelogic.CheckCardsValue(first,second)
	local v1 = {
		gamelogic.GetValue(first[1]),
		gamelogic.GetValue(first[2]),
		gamelogic.GetValue(first[3]),
	}
	local v2 = {
		gamelogic.GetValue(second[1]),
		gamelogic.GetValue(second[2]),
		gamelogic.GetValue(second[3]),
	}
	table.sort(v1)
	table.sort(v2)
	if v1[1] == v2[1] and v1[2] == v2[2] and v1[3] == v2[3] then
		return true
	end
	if v1[1] == 2 and v1[2] == 3 and v1[3] == 5 then
		local c1 = gamelogic.GetColor(first[1])
		local c2 = gamelogic.GetColor(first[2])
		local c3 = gamelogic.GetColor(first[3])
		if c1 ~= c2 or c1 ~= c3 or c2 ~= c3 then
			return true
		end
	end
	if v2[1] == 2 and v2[2] == 3 and v2[3] == 5 then
		local c1 = gamelogic.GetColor(second[1])
		local c2 = gamelogic.GetColor(second[2])
		local c3 = gamelogic.GetColor(second[3])
		if c1 ~= c2 or c1 ~= c3 or c2 ~= c3 then
			return true
		end
	end
	return false
end

function gamelogic.BuildCardsInfo(cards)
	local type, v1, v2, v3 = gamelogic.GetCardsType(cards)
	local item = {cards_type = type}
	if v1 then
		item[1] = v1
	end
	if v2 then
		item[2] = v2
	end
	if v3 then
		item[3] = v3
	end
	item.cards = cards
	return item
end

-- ����
function gamelogic.CompareCards(first, second)
	if first.cards_type ~= second.cards_type then
		-- ����
		if first.cards_type == REDBLACK_CARD_TYPE_BAO_ZI and second.cards_type == REDBLACK_CARD_TYPE_SPECIAL then
			return false
		elseif second.cards_type == REDBLACK_CARD_TYPE_BAO_ZI and first.cards_type == REDBLACK_CARD_TYPE_SPECIAL then
		 	return true
		end
		return first.cards_type > second.cards_type
	end

	if first.cards_type == REDBLACK_CARD_TYPE_SHUN_ZI or first.cards_type == REDBLACK_CARD_TYPE_SHUN_JIN or first.cards_type == REDBLACK_CARD_TYPE_BAO_ZI then
		return first[1] > second[1]
	end

	if first.cards_type == REDBLACK_CARD_TYPE_DOUBLE then
		if first[1] > second[1] then
			return true
		elseif first[1] == second[1] then
			return first[2] > second[2]
		end
		return false
	end

	if first[1] > second[1] then
		return true
	elseif first[1] == second[1] then
		if first[2] > second[2] then
			return true
		elseif first[2] == second[2] then
			return first[3] > second[3]
		end
	end
	return false
end

