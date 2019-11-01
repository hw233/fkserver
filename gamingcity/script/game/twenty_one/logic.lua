logic = logic or {}

logic.CardsType = {
	BlackJack = {i = 3,score = 1.5},
	WuLong ={i = 2,score = 1},
	Normal = {i = 1,score = 1},
}


function table.sum(tb,elem_func)
    local n = 0
    table.walk(tb,function(v,k) if v then n = n + elem_func(v) end end)
    return n
end


function logic.cards_num_sum(cards)
    return table.sum(cards,function(v) return logic.card_number(v) end)
end

function logic.card_number(card)
    local num = logic.real_card_number(card)
    return num > 10 and 10 or num
end

function logic.real_card_number(card)
	local num = card % 15
	return num == 14 and 1 or num
end

function logic.cards_num_array(cards)
    local num_array = {}
    table.walk(cards,function(c,i)  table.push_back(num_array,logic.card_number(c)) end)
    return num_array
end

function logic.is_blackjack(cards)
    if #cards ~= 2 then return false end
    return logic.get_cards_number(cards) == 21 
end

function logic.is_bomb(cards)
	local num = logic.get_cards_number(cards)
    return num == 0
end

function logic.is_wulong(cards)
    if table.nums(cards) ~= 5 then return false end
    if logic.get_cards_number(cards) == 0 then return false end
    return true
end

function logic.A_count(cards)
	local count = 0
	table.walk(cards,function(c,i) 
		local num = logic.real_card_number(c)
		count = count + (num == 1 and 1 or 0) 
	end)
	return count
end

function logic.get_cards_number(cards)
	local A_count = logic.A_count(cards)
    local cards_number = logic.cards_num_sum(cards) + A_count * 10

	if cards_number <= 21 then return cards_number end

	for i = A_count,1,-1 do
		cards_number = cards_number - 10
		if cards_number <= 21 then 
			return cards_number 
		end
	end

	return 0
end

function logic.get_cards_type(cards)
	if logic.is_blackjack(cards) then return logic.CardsType.BlackJack end
	if logic.is_wulong(cards) then return logic.CardsType.WuLong end
	return logic.CardsType.Normal
end

function test()
	print("lkdsajofdajifdjsaoifd:",logic.get_cards_number({1,2,6,17}))
end
