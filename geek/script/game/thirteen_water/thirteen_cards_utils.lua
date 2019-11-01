--十三水牌型处理工具类

-- 0：方块2，1：梅花2，2：红桃2，3：黑桃2 …… 48：方块A，49：梅花A，50：红桃A，51：黑桃A

local thirteen_cards_utils = {}


-- 得到牌大小
function thirteen_cards_utils.get_value(card)
	return math.floor(card / 4)
end
-- 得到牌花色(0：方块 1：梅花 2：红桃 3：黑桃)
function thirteen_cards_utils.get_color(card)
	return card % 4
end

-- 分析牌，将牌按张数分组(cards牌必须有序)
function thirteen_cards_utils.analy_cards_by_count(cards)

	local ret = {{}, {}, {}, {}} -- 依次单，双，三，四的数组
	local last_val = nil
	local i = 0

	for _, card in ipairs(cards) do
		local val = thirteen_cards_utils.get_value(card)
		if last_val == val then
			i = i + 1
		else
			if i > 0 and i <= 4 then
				table.insert(ret[i], last_val)
			end
			last_val = val
			i = 1
		end
	end
	if i > 0 and i <= 4 then
		table.insert(ret[i], last_val)
	end
	return ret
end

-- 分析牌，将牌按花色分组(cards牌必须有序)
function thirteen_cards_utils.analy_cards_by_color(cards)

	local ret = {{}, {}, {}, {}} -- 依次方块、梅花、红桃、黑桃

	for _, card in ipairs(cards) do
		local color = thirteen_cards_utils.get_color(card)
		table.insert(ret[color+1], card)
	end
	
	return ret
end

--检查是否同花顺
function thirteen_cards_utils.do_check_tonghua_shun(cards,start_value)
	-- body
	local first_card_value = thirteen_cards_utils.get_value(cards[1])
	if first_card_value ~= start_value then
		return false
	end
	local current_card = cards[1]

	for i=2,#cards do
		if cards[i] ~= (current_card + 4) then
			return false
		end
		current_card = cards[i]
	end
	return true
end

--检查是否顺子
function thirteen_cards_utils.do_check_shunzi(cards,start_value)
	-- body
	local card_value = start_value
	for i,v in ipairs(cards) do
		if thirteen_cards_utils.get_value(v) ~= card_value then
			return false
		end

		card_value = card_value + 1
	end

	return true
end


return thirteen_cards_utils
