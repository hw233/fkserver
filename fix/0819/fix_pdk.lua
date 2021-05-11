
local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"


local cards_util = require "game.pdk.cards_util"
local pb = require "pb_files"
local log = require "log"

local tinsert = table.insert


local PDK_CARD_TYPE = {
	SINGLE = pb.enum("PDK_CARD_TYPE", "SINGLE"),
	DOUBLE = pb.enum("PDK_CARD_TYPE", "DOUBLE"),
	THREE = pb.enum("PDK_CARD_TYPE", "THREE"),
	THREE_WITH_ONE = pb.enum("PDK_CARD_TYPE", "THREE_WITH_ONE"),
	THREE_WITH_TWO = pb.enum("PDK_CARD_TYPE", "THREE_WITH_TWO"),
	FOUR_WITH_SINGLE = pb.enum("PDK_CARD_TYPE", "FOUR_WITH_SINGLE"),
	FOUR_WITH_DOUBLE = pb.enum("PDK_CARD_TYPE", "FOUR_WITH_DOUBLE"),
	SINGLE_LINE = pb.enum("PDK_CARD_TYPE", "SINGLE_LINE"),
	DOUBLE_LINE = pb.enum("PDK_CARD_TYPE", "DOUBLE_LINE"),
	PLANE = pb.enum("PDK_CARD_TYPE", "PLANE"),
	PLANE_WITH_ONE = pb.enum("PDK_CARD_TYPE", "PLANE_WITH_ONE"),
	PLANE_WITH_TWO = pb.enum("PDK_CARD_TYPE", "PLANE_WITH_TWO"),
	PLANE_WITH_MIX = pb.enum("PDK_CARD_TYPE","PLANE_WITH_MIX"),
	BOMB = pb.enum("PDK_CARD_TYPE", "BOMB"),
	FOUR_WITH_THREE = pb.enum("PDK_CARD_TYPE", "FOUR_WITH_THREE"),
	MISSLE = pb.enum("PDK_CARD_TYPE", "MISSLE"),
}

dump(print,cards_util)

-- 得到牌类型
function cards_util.get_cards_type(cards)
	log.info("cards_util.get_cards_type")
	local count = #cards
	if count == 1 then
		return PDK_CARD_TYPE.SINGLE, cards_util.value(cards[1]) -- 单牌
	end

	local valuegroup = table.group(cards,function(c) return cards_util.value(c) end)
	local valuecounts = table.map(valuegroup,function(cs,v) return v,table.nums(cs) end)
	local countgroup =  table.group(valuecounts,function(c)  return c end)
	local countvalues = table.map(countgroup,function(cg,c) return c,table.keys(cg) end)
	local countcounts = table.map(countvalues,function(cs,c) return c,table.nums(cs) end)

	if countcounts[4] and countcounts[4] == 1 then
		if (countcounts[1] == 2 or countcounts[2] == 1) and #cards ==  6 then
			return PDK_CARD_TYPE.FOUR_WITH_DOUBLE, countvalues[4][1] -- 四带二
		end

		if (countcounts[3] == 1 or (countcounts[2] == 1 and countcounts[1] == 1) or countcounts[1] == 3) and #cards == 7  then
			return PDK_CARD_TYPE.FOUR_WITH_THREE, countvalues[4][1] -- 四带三
		end

		if not countcounts[1]  and not countcounts[2] and not countcounts[3] then
			return PDK_CARD_TYPE.BOMB,  countvalues[4][1] -- 炸弹
		end

		if countcounts[1] == 1 and #cards == 5 then
			return PDK_CARD_TYPE.THREE_WITH_TWO, countvalues[4][1] -- 三带二
		end
	end

	if countcounts[3] and countcounts[3] == 1 then
		if (countcounts[2] == 1 or countcounts[1] == 2) and #cards == 5 then
			return PDK_CARD_TYPE.THREE_WITH_TWO, countvalues[3][1] -- 三带二
		end

		if countcounts[1] == 1 and #cards == 4  then
			return PDK_CARD_TYPE.THREE_WITH_ONE, countvalues[3][1] -- 三带一
		end

		if not countcounts[1] and not countcounts[2] and #cards == 3 then
			return PDK_CARD_TYPE.THREE, countvalues[3][1] -- 三不带
		end
	end

	-- 飞机
	if (countcounts[3] or 0) + (countcounts[4] or 0) > 1 then
		local values = {}
		for i = 3,14 do
			if countgroup[3] and countgroup[3][i] then
				tinsert(values,i)
			elseif countgroup[4] and countgroup[4][i] then
				tinsert(values,i)
			elseif #values == 1 then
				values = {}
			elseif #values > 1 then
				break
			end
		end

		local value_c = #values
		local card_c = #cards

		if value_c < 2 then
			return
		end

		if card_c == value_c * 3 then
			return PDK_CARD_TYPE.PLANE, values[1] -- 飞机不带牌
		end

		--三带一飞机
		if card_c == value_c * 4 then
			return PDK_CARD_TYPE.PLANE_WITH_ONE, values[1]
		end

		--三带二飞机
		if card_c == value_c * 5 then
			return PDK_CARD_TYPE.PLANE_WITH_TWO, values[1]
		end

		if card_c > value_c * 3 and card_c < value_c * 5 then
			return PDK_CARD_TYPE.PLANE_WITH_MIX, values[1]
		end

		return
	end

	local function max_continuity_cards(begin,value_count)
		local values = {}
		for i = begin,14 do
			if value_count[i] then
				tinsert(values,i)
			elseif #values == 1 then
				values = {}
			end
		end

		return values
	end

	if countcounts[2] and countcounts[2] > 0 then
		if countcounts[2] == 1 and #cards == 2 then
			return PDK_CARD_TYPE.DOUBLE, countvalues[2][1] -- 对子
		end

		local values = max_continuity_cards(3,countgroup[2])
		if #values >= 2 and #values == countcounts[2]  and #cards == #values * 2 then
			return PDK_CARD_TYPE.DOUBLE_LINE , values[1] -- 连对
		end
	end

	if countcounts[1] and countcounts[1] >= 5 then
		local values = max_continuity_cards(3,countgroup[1])
		if #values >= 5 and #values == countcounts[1] then
			return PDK_CARD_TYPE.SINGLE_LINE , values[1] -- 顺子
		end
	end

	return nil
end

dump(print,cards_util)