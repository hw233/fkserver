local pb = require "pb_files"
local log = require "log"

local cards_util = {}

local PDK_CARD_TYPE = {
	SINGLE = pb.enum("PDK_CARD_TYPE", "SINGLE"),
	DOUBLE = pb.enum("PDK_CARD_TYPE", "DOUBLE"),
	THREE = pb.enum("PDK_CARD_TYPE", "THREE"),
	THREE_TAKE_ONE = pb.enum("PDK_CARD_TYPE", "THREE_TAKE_ONE"),
	THREE_TAKE_TWO = pb.enum("PDK_CARD_TYPE", "THREE_TAKE_TWO"),
	FOUR_TAKE_ONE = pb.enum("PDK_CARD_TYPE", "FOUR_TAKE_ONE"),
	FOUR_TAKE_TWO = pb.enum("PDK_CARD_TYPE", "FOUR_TAKE_TWO"),
	SINGLE_LINE = pb.enum("PDK_CARD_TYPE", "SINGLE_LINE"),
	DOUBLE_LINE = pb.enum("PDK_CARD_TYPE", "DOUBLE_LINE"),
	PLANE = pb.enum("PDK_CARD_TYPE", "PLANE"),
	PLANE_TAKE_ONE = pb.enum("PDK_CARD_TYPE", "PLANE_TAKE_ONE"),
	PLANE_TAKE_TWO = pb.enum("PDK_CARD_TYPE", "PLANE_TAKE_TWO"),
	BOMB = pb.enum("PDK_CARD_TYPE", "BOMB"),
	MISSILE = pb.enum("PDK_CARD_TYPE", "MISSILE"),
}

cards_util.PDK_CARD_TYPE = PDK_CARD_TYPE

-- 0:黑 1:红 2:梅 3:方

function cards_util.color(card)
	return math.floor(card / 20)
end

function cards_util.value(card)
	return math.floor(card % 20)
end

function cards_util.check(card)
	local color,value = cards_util.color(card),cards_util.value(card)
	return color >= 0 and color <= 5 and value > 0 and value < 16
end

-- 检查牌是否合法
function cards_util.check_cards(cards)
	return table.logic_and(cards,function(c) return cards_util.check(c) end)
end


-- 得到牌类型
function cards_util.get_card_type(cards)
	local count = #cards
	if count == 1 then
		return PDK_CARD_TYPE.SINGLE, cards_util.value(cards[1]) -- 单牌
	end

	local valuegroup = table.group(cards,function(c) return cards_util.value(c) end)
	local valuecounts = table.select(valuegroup,function(cs,v) return v,#cs end)
	local countgroup =  table.group(valuecounts,function(c)  return c end)
	local countvalues = table.map(countgroup,function(vg,c) return c,table.series(vg) end)

	if countvalues[4] and #countvalues[4] == 1 then
		if countvalues[2] and #countvalues[1] == 2 then
			return PDK_CARD_TYPE.FOUR_TAKE_ONE, countvalues[4][1] -- 四带两单
		end

		if countvalues[1] and #countvalues[2] == 1 then
			return PDK_CARD_TYPE.FOUR_TAKE_TWO, countvalues[4][1] -- 四带一对
		end

		if not countvalues[1]  and not countvalues[2] and not countvalues[3] then
			return PDK_CARD_TYPE.BOMB,  countvalues[4][1] -- 炸弹
		end

		return nil
	end

	if countvalues[3] then
		if #countvalues[3] == 1 then
			if countvalues[1] and #countvalues[1] == 1 then
				return PDK_CARD_TYPE.THREE_TAKE_ONE, countvalues[3][1] -- 三带一
			end

			if countvalues[2] and #countvalues[2] == 1 then
				return PDK_CARD_TYPE.THREE_TAKE_TWO, countvalues[3][1] -- 三带一对
			end

			if not countvalues[1] and not countvalues[2] and not countvalues[4] then
				return PDK_CARD_TYPE.THREE, countvalues[3][1] -- 三不带
			end
		end

		if  countvalues[3] > 1 then
			local count_3 = #countvalues[3]
			local count_other = table.sum(countvalues,function(vs,c) return c == 3 and 0 or #vs end)
			if count_other == count_3 then
				return PDK_CARD_TYPE.PLANE, countvalues[3][1] -- 飞机不带牌
			end

			if count_other == count_3 * 2 then
				return PDK_CARD_TYPE.PLANE_TAKE_TWO, countvalues[3][1] -- 飞机带对牌
			end

			if count_other == 0 then
				return PDK_CARD_TYPE.PLANE, countvalues[3][1] -- 飞机不带牌
			end
		end

		return nil
	end

	if countvalues[2] and #countvalues[2] > 0 then
		local values = countvalues[2]
		if #values == 1 then
			return PDK_CARD_TYPE.DOUBLE, values[1] -- 对子
		end

		local kied_values = table.map(values,function(_,v) return v,true end)
		local last_v
		local lian_count
		for i = 3,14 do
			if kied_values[i] then
				if last_v then 
					lian_count = lian_count + 1
					last_v = i
				else
					lian_count = 1
					last_v = i
				end
			end
		end

		if lian_count >= 3 and lian_count == #values then
			return PDK_CARD_TYPE.DOUBLE_LINE , values[1] -- 连对
		end
	end

	if countvalues[1] and #countvalues[1] >= 5 then
		local values = countvalues[1]
		local kied_values = table.map(values,function(_,v) return v,true end)
		local last_v
		local lian_count
		for i = 3,14 do
			if kied_values[i] then
				if last_v then 
					lian_count = lian_count + 1
					last_v = i
				else
					lian_count = 1
					last_v = i
				end
			end
		end

		if lian_count >= 5 and lian_count == #values then
			return PDK_CARD_TYPE.SINGLE_LINE , values[1] -- 顺子
		end
	end

	return nil
end


-- 比较牌
function cards_util.compare_cards(cur, last)
	log.info("pdk_cards  compare_cards")
	if cur.cards_val ~= nil then
		log.info(string.format("cur [%d,%d,%d]", cur.cards_type , cur.cards_count, cur.cards_val))
	else
		log.info(string.format("cur [%d,%d]", cur.cards_type , cur.cards_count))
	end

	if last ~= nil then
		log.info(string.format("last [%d,%d,%d]", last.cards_type , last.cards_count, last.cards_val))
	end

	if not last then
		return true
	end

	-- 比较火箭
	if cur.cards_type == PDK_CARD_TYPE.MISSILE then
		return true
	end

	-- 比较炸弹
	if last.cards_type == PDK_CARD_TYPE.BOMB then
		return cur.cards_type == PDK_CARD_TYPE.BOMB and cur.cards_val > last.cards_val
	elseif cur.cards_type == PDK_CARD_TYPE.BOMB then
		return true
	end

	return cur.cards_type == last.cards_type and cur.cards_count == last.cards_count and cur.cards_val > last.cards_val
end


return cards_util