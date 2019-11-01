-- 斗地主出牌规则

local pb = require "pb_files"

-- enum LAND_CARD_TYPE
local LAND_CARD_TYPE_SINGLE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE")
local LAND_CARD_TYPE_DOUBLE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE")
local LAND_CARD_TYPE_THREE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE")
local LAND_CARD_TYPE_THREE_TAKE_ONE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_ONE")
local LAND_CARD_TYPE_THREE_TAKE_TWO = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_TWO")
local LAND_CARD_TYPE_FOUR_TAKE_ONE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_ONE")
local LAND_CARD_TYPE_FOUR_TAKE_TWO = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_TWO")
local LAND_CARD_TYPE_SINGLE_LINE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE_LINE")
local LAND_CARD_TYPE_DOUBLE_LINE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE_LINE")
local LAND_CARD_TYPE_PLANE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_PLANE")
local LAND_CARD_TYPE_PLANE_TAKE_ONE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_PLANE_TAKE_ONE")
local LAND_CARD_TYPE_PLANE_TAKE_TWO = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_PLANE_TAKE_TWO")
local LAND_CARD_TYPE_BOMB = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB")
local LAND_CARD_TYPE_MISSILE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE")


--ai出牌类型
local ddz_type_i_no_move			= 0
local ddz_type_i_alone_1			= 1
local ddz_type_i_pair				= 2
local ddz_type_i_triple				= 3
local ddz_type_i_triple_1			= 4
local ddz_type_i_triple_2			= 5
local ddz_type_i_order				= 6
local ddz_type_i_order_pair			= 7
local ddz_type_i_airplane			= 8
local ddz_type_i_airplane_with_pai	= 9
local ddz_type_i_bomb				= 10
local ddz_type_i_king_bomb			= 11
local ddz_type_i_four_with_alone1 	= 12
local ddz_type_i_four_with_pairs 	= 13

local pai_type_blackjack			= 16--ai中的小王
local pai_type_blossom				= 17--ai中的大王



-- 得到牌大小
local function get_value(card)
	return math.floor(card / 4)
end

-- 是大小王
local function is_king(card)
	return card == 52 or card == 53
end
--0  0： 方块3， 1： 梅花3， 2： 红桃3， 3： 黑桃3
--1  4： 方块4， 5： 梅花4， 6： 红桃4， 7： 黑桃4
--2  8： 方块5， 9： 梅花5， 10：红桃5， 11：黑桃5
--3  12：方块6， 13：梅花6， 14：红桃6， 15：黑桃6
--4  16：方块7， 17：梅花7， 18：红桃7， 19：黑桃7
--5  20：方块8， 21：梅花8， 22：红桃8， 23：黑桃8
--6  24：方块9， 25：梅花9， 26：红桃9， 27：黑桃9
--7  28：方块10，29：梅花10，30：红桃10，31：黑桃10
--8  32：方块J， 33：梅花J， 34：红桃J， 35：黑桃J
--9  36：方块Q， 37：梅花Q， 38：红桃Q， 39：黑桃Q
--10 40：方块K， 41：梅花K， 42：红桃K， 43：黑桃K
--11 44：方块A， 45：梅花A， 46：红桃A， 47：黑桃A
--12 48：方块2， 49：梅花2， 50：红桃2， 51：黑桃2，
--13 52：小王，  53：大王

land_cards = {}

-- 创建
function land_cards:new()
    local o = {}
    setmetatable(o, {__index = self})

    return o
end

-- 分析牌
function land_cards.analyseb_cards(cards)
	local ret = {{}, {}, {}, {}} -- 依次单，双，三，炸的数组
	local last_val = nil
	local i = 0

	for _, card in ipairs(cards) do
		if is_king(card) then
			table.insert(ret[1], card) -- 王默认是单牌
		else
			local val = get_value(card)
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
	end
	if i > 0 and i <= 4 then
		table.insert(ret[i], last_val)
	end
	return ret
end

--游戏牌值转化为ai对应的牌值
function land_cards.convert_gameCard_aiCard(card)
	local ai_card = 0
	if card == 52 then
		--小王
		ai_card = pai_type_blackjack
	elseif card == 53 then
		--大王
		ai_card = pai_type_blossom
	else
		ai_card = math.floor(card / 4) +  3
	end

	return ai_card
end

--游戏牌值(不分花色的值，3都是0，4都是1 大小王的value是  53和52)转化为ai对应的牌值
function land_cards.convert_cardValue_aiCard(cardValue)
	local ai_card = 0
	if cardValue == 52 then
		--小王
		ai_card = pai_type_blackjack
	elseif cardValue == 53 then
		--大王
		ai_card = pai_type_blossom
	else
		ai_card = cardValue +  3
	end

	return ai_card
end


--ai的出牌转化为游戏的出牌列表
function land_cards.convert_aicards_cards(aicards,player_cards)
	--不出牌
	if aicards.type == ddz_type_i_no_move then
		return {}
	end

	--ai出牌列表
	local ai_play_cards = {}
	--玩家出的牌
	local player_out_cards = {}


	if aicards.type == ddz_type_i_alone_1 then
		ai_play_cards = {aicards.alone_1}

	elseif aicards.type == ddz_type_i_pair then
		ai_play_cards = {aicards.alone_1,aicards.alone_1}

	elseif aicards.type == ddz_type_i_triple then
		ai_play_cards = {aicards.alone_1,aicards.alone_1,aicards.alone_1}

	elseif aicards.type == ddz_type_i_triple_1 then
		ai_play_cards = {aicards.alone_1,aicards.alone_1,aicards.alone_1,aicards.alone_2}

	elseif aicards.type == ddz_type_i_triple_2 then
		ai_play_cards = {aicards.alone_1,aicards.alone_1,aicards.alone_1,aicards.alone_2,aicards.alone_2}

	elseif aicards.type == ddz_type_i_order then
		ai_play_cards = aicards.pb_combo_list.cards

	elseif aicards.type == ddz_type_i_order_pair then
		ai_play_cards = aicards.pb_combo_list.cards

	elseif aicards.type == ddz_type_i_airplane then
		ai_play_cards = aicards.pb_combo_list.cards

	elseif aicards.type == ddz_type_i_airplane_with_pai then
		ai_play_cards = aicards.pb_combo_list.cards
		local loop_count = 1
		if aicards.airplane_pairs == 1 then
			loop_count = 2
		end
		local with_cards = {aicards.alone_1,aicards.alone_2,aicards.alone_3,aicards.alone_4}
		for _,card in ipairs(with_cards) do
			if card > 0 then
				for i=1,loop_count do
					table.insert(ai_play_cards,card)
				end
			end
		end

	elseif aicards.type == ddz_type_i_bomb then
		ai_play_cards = {aicards.alone_1,aicards.alone_1,aicards.alone_1,aicards.alone_1}

	elseif aicards.type == ddz_type_i_king_bomb then
		ai_play_cards = {pai_type_blackjack,pai_type_blossom}

	elseif aicards.type == ddz_type_i_four_with_alone1 then
		ai_play_cards = {aicards.alone_1,aicards.alone_1,aicards.alone_1,aicards.alone_1,aicards.alone_2,aicards.alone_3}

	elseif aicards.type == ddz_type_i_four_with_pairs then
		ai_play_cards = {aicards.alone_1,aicards.alone_1,aicards.alone_1,aicards.alone_1,aicards.alone_2,aicards.alone_2,aicards.alone_3,aicards.alone_3}

	end

	local player_cards_check = {}
	--根据ai的牌，从玩家身上找出对应的牌
	for i,card in ipairs(ai_play_cards) do
		if card == pai_type_blackjack then
			table.insert(player_out_cards,52)
		elseif card == pai_type_blossom then
			table.insert(player_out_cards,53)
		else
			--游戏中的牌值没有花色的，0：方块3，1：梅花3，2：红桃3，3：黑桃3 都是0
			local card_value = card - 3
			for _,pcard in ipairs(player_cards) do
				if(get_value(pcard) == card_value and not player_cards_check[pcard]) then
					table.insert(player_out_cards,pcard)
					player_cards_check[pcard] = 1
					break
				end
			end
		end
	end
	--log.error("ai_play_cards------>%s",table.concat(ai_play_cards, ','))
	--log.error("player_cards------>%s",table.concat(player_cards, ','))
	--log.error("player_out_cards------>%s",table.concat(player_out_cards, ','))


	return player_out_cards
end


--游戏的出牌列表转化为ai的出牌
function land_cards.convert_cards_aicards(out_cards,card_list)
	local analyseb_cards_ret = land_cards.analyseb_cards(card_list)

	local pb_pai_move = {
		type = 0,
		alone_1 = 0,
		alone_2 = 0,
		alone_3 = 0,
		alone_4 = 0,
		airplane_pairs = 0,
		pb_combo_list = {},
	}

	if not out_cards then
		log.error("convert_cards_aicards out_cards is nil")
		return pb_pai_move
	end

	local cardstype = out_cards.cards_type
	local cardsval  = out_cards.cards_val

	--log.error("convert_cards_aicards cardstype[%d] cardsval[%d] card_list[%s]",cardstype,cardsval,table.concat(card_list, ','))

	if cardstype == LAND_CARD_TYPE_SINGLE then
		pb_pai_move.type = ddz_type_i_alone_1
		pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[1][1])

	elseif cardstype == LAND_CARD_TYPE_DOUBLE then
		pb_pai_move.type = ddz_type_i_pair
		pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][1])

	elseif cardstype == LAND_CARD_TYPE_THREE  then
		pb_pai_move.type = ddz_type_i_triple
		pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[3][1])

	elseif cardstype == LAND_CARD_TYPE_THREE_TAKE_ONE   then
		pb_pai_move.type = ddz_type_i_triple_1
		pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[3][1])
		pb_pai_move.alone_2 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[1][1])

	elseif cardstype == LAND_CARD_TYPE_THREE_TAKE_TWO   then
		pb_pai_move.type = ddz_type_i_triple_2
		pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[3][1])
		pb_pai_move.alone_2 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][1])

	elseif cardstype == LAND_CARD_TYPE_FOUR_TAKE_ONE    then
		pb_pai_move.type = ddz_type_i_four_with_alone1
		pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[4][1])
		if analyseb_cards_ret[1][1] == nil then
			--4带1对
			pb_pai_move.alone_2 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][1])
			pb_pai_move.alone_3 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][1])
		else
			pb_pai_move.alone_2 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[1][1])
			pb_pai_move.alone_3 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[1][2])
		end

	elseif cardstype == LAND_CARD_TYPE_FOUR_TAKE_TWO    then
		pb_pai_move.type = ddz_type_i_four_with_pairs
		pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[4][1])
		pb_pai_move.alone_2 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][1])
		pb_pai_move.alone_3 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][2])

	elseif cardstype == LAND_CARD_TYPE_SINGLE_LINE then
		pb_pai_move.type = ddz_type_i_order
		pb_pai_move.pb_combo_list.cards = {}
		for _,card in ipairs(card_list) do
			table.insert(pb_pai_move.pb_combo_list.cards,land_cards.convert_gameCard_aiCard(card))
		end

	elseif cardstype == LAND_CARD_TYPE_DOUBLE_LINE then
		pb_pai_move.type = ddz_type_i_order_pair
		pb_pai_move.pb_combo_list.cards = {}
		for _,card in ipairs(card_list) do
			table.insert(pb_pai_move.pb_combo_list.cards,land_cards.convert_gameCard_aiCard(card))
		end

	elseif cardstype == LAND_CARD_TYPE_PLANE  then
		pb_pai_move.type = ddz_type_i_airplane
		pb_pai_move.pb_combo_list.cards = {}
		for _,card in ipairs(card_list) do
			table.insert(pb_pai_move.pb_combo_list.cards,land_cards.convert_gameCard_aiCard(card))
		end

	elseif cardstype == LAND_CARD_TYPE_PLANE_TAKE_ONE  then
		pb_pai_move.type = ddz_type_i_airplane_with_pai
		pb_pai_move.airplane_pairs = 0
		pb_pai_move.pb_combo_list.cards = {}
		for _,value in ipairs(analyseb_cards_ret[3]) do
			for i=1,3 do
				table.insert(pb_pai_move.pb_combo_list.cards,land_cards.convert_cardValue_aiCard(value))
			end
		end
		local len = #analyseb_cards_ret[1]
		if len > 1 then pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[1][1]) end
		if len > 2 then pb_pai_move.alone_2 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[1][2]) end
		if len > 3 then pb_pai_move.alone_3 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[1][3]) end
		if len > 4 then pb_pai_move.alone_4 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[1][4]) end


	elseif cardstype == LAND_CARD_TYPE_PLANE_TAKE_TWO  then
		pb_pai_move.type = ddz_type_i_airplane_with_pai
		pb_pai_move.airplane_pairs = 1
		pb_pai_move.pb_combo_list.cards = {}
		for _,value in ipairs(analyseb_cards_ret[3]) do
			for i=1,3 do
				table.insert(pb_pai_move.pb_combo_list.cards,land_cards.convert_cardValue_aiCard(value))
			end
		end
		local len = #analyseb_cards_ret[2]
		if len > 1 then pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][1]) end
		if len > 2 then pb_pai_move.alone_2 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][2]) end
		if len > 3 then pb_pai_move.alone_3 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][3]) end
		if len > 4 then pb_pai_move.alone_4 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[2][4]) end

	elseif cardstype == LAND_CARD_TYPE_BOMB    then
		pb_pai_move.type = ddz_type_i_bomb
		pb_pai_move.alone_1 = land_cards.convert_cardValue_aiCard(analyseb_cards_ret[4][1])

	elseif cardstype == LAND_CARD_TYPE_MISSILE then
		pb_pai_move.type = ddz_type_i_king_bomb
	end

	return pb_pai_move

end

-- 初始化
function land_cards:init(cards)
    self.cards_ = cards
    self.bomb_count_ = 0
end

function land_cards:sort()
    -- body
    table.sort(self.cards_, function(a, b) return a < b end)
end
--转化为ai需要的牌型
function land_cards:convert_ai_cards()
	local ai_cards = {}
	for i=1,15 do
		ai_cards[i] = 0
	end

	for i,card in ipairs(self.cards_) do
		if card == 52 then
			--小王
			ai_cards[14] = 1
		elseif card == 53 then
			--大王
			ai_cards[15] = 1
		else
			local index = math.floor(card/4) + 1
			ai_cards[index] = ai_cards[index] + 1
		end
	end
	return ai_cards
end

-- 添加牌
function land_cards:add_cards(cards)
	for i,v in ipairs(cards) do
    	table.insert(self.cards_, v)
    end
end

-- 加炸弹
function land_cards:add_bomb_count()
	self.bomb_count_ = self.bomb_count_ + 1
end

-- 得到炸弹
function land_cards:get_bomb_count()
	return self.bomb_count_
end

-- 查找是否有拥有
function land_cards:find_card(card)
	for i,v in ipairs(self.cards_) do
		if v == card then
			return true
		end
	end
	return false
end

-- 删除牌
function land_cards:remove_card(card)
for i,v in ipairs(self.cards_) do
		if v == card then
			table.remove(self.cards_, i)
			return true
		end
	end
	return false
end

-- 检查牌是否合法
function land_cards:check_cards(cards)
	if not cards or #cards == 0 then
		return false
	end

	local set = {} -- 检查重复牌
	for i,v in ipairs(cards) do
		if v < 0 or v > 53 or set[v] then
			return false
		end

		if not self:find_card(v) then
			return false
		end

		set[v] = true
	end

	return true
end

-- 设定
function land_cards:set_DXcard(card)
	-- body
	if card == nil then
		self.DXcard = nil
	else
		self.DXcard = get_value(card)
	end
end
-- 设定
function land_cards:set_TXcard(card)
	-- body
	if card == nil then
		self.TXcard = nil
	else
		self.TXcard = get_value(card)
	end
end
function land_cards:is_Xcard(card)
	-- body
	if not self.TXcard or not self.DXcard then
		return false
	end
	return self.TXcard == get_value(card) or self.DXcard == get_value(card)
end
function land_cards:have_Xcard()
	-- body
	if self.TXcard == nil or self.DXcard == nil then
		return false
	end
	return true
end
--三不带
function land_cards:is_Type_Three(cards)
	-- body
	if #cards == 3 then
		-- 三张牌一样
		if get_value(cards[1]) == get_value(cards[2]) and get_value(cards[2]) == get_value(cards[3]) then
			return true , get_value(cards[1])
		end
		if self:have_Xcard() then
			-- 三张牌都是特殊牌
			if self:is_Xcard(cards[1]) and self:is_Xcard(cards[2]) and self:is_Xcard(cards[3]) then
				return false
			end
			local l_value = nil
			for i=1,3 do
				if not self:is_Xcard(cards[i]) then
					if l_value == nil then
						l_value = get_value(cards[i])
					else
						if l_value ~= get_value(cards[i]) then
							return false
						end
					end
				end
			end
			if l_value ~= nil then
				return true , l_value
			end
		end
	end
	return false
end
function land_cards:Get_Cards_Group(cards)
	-- body
	local card_group = {}
	for i,v in ipairs(cards) do
		local card = {}
		card.val = get_value(v)
		card.key = v
		if self:have_Xcard() then
			card.isX = self:is_Xcard(v)
		end
	end
end
-- 三带一 LAND_CARD_TYPE_THREE_TAKE_ONE
function land_cards:is_Type_Three_Take_One(cards)
	-- body
	if #cards == 4 then
		local cardGroup = self:Get_Cards_Group(cards)
		-- 四张一样 认为炸弹不做三带一
		if cardGroup[1].val == cardGroup[2].val and cardGroup[2].val == cardGroup[3].val and cardGroup[3].val == cardGroup[4].val then
			return false
		end
		if self:have_Xcard() then
		else
		end
	end
	return false
end
function land_cards:get_cards_type_new_(cards)
	-- body
	if not self:check_cards(cards) then
		return nil
	end

	local count = #cards
	if count == 1 then
		return LAND_CARD_TYPE_SINGLE, get_value(cards[1]) -- 单牌
	elseif count == 2 then
		if is_king(cards[1]) and is_king(cards[2]) then
			return LAND_CARD_TYPE_MISSILE -- 火箭
		elseif get_value(cards[1]) == get_value(cards[2]) then
			return LAND_CARD_TYPE_DOUBLE, get_value(cards[1]) -- 对牌
		elseif is_Xcard(cards[1]) then
			return LAND_CARD_TYPE_DOUBLE, get_value(cards[2]) -- 对牌
		elseif is_Xcard(cards[2]) then
			return LAND_CARD_TYPE_DOUBLE, get_value(cards[1]) -- 对牌
		end
		return nil
	end
	--三不带 LAND_CARD_TYPE_THREE
	local ret, cardsval = self:is_Type_Three(cards)
	if ret then
		return LAND_CARD_TYPE_THREE , cardsval
	end
	-- 三带一 LAND_CARD_TYPE_THREE_TAKE_ONE

	--三带一
	--三带一对
	--四带二
	--四带两对
	--顺子
	--连对
	--飞机 不带
	--飞机 带牌 单
	--飞机 带牌 对
	--炸弹
	--火箭

-- 更多牌型
-- LAND_CARD_TYPE_ERROR                    = 0;                                //错误类型
-- LAND_CARD_TYPE_SINGLE                   = 1;                                //单牌类型
-- LAND_CARD_TYPE_DOUBLE                   = 2;                                //对牌类型
-- LAND_CARD_TYPE_THREE                    = 3;                                //三不带
-- LAND_CARD_TYPE_THREE_TAKE_ONE           = 4;                                //三带一
-- LAND_CARD_TYPE_THREE_TAKE_TWO           = 5;                                //三带一对
-- LAND_CARD_TYPE_FOUR_TAKE_ONE            = 6;                                //四带二
-- LAND_CARD_TYPE_FOUR_TAKE_TWO            = 7;                                //四带两对
-- LAND_CARD_TYPE_SINGLE_LINE              = 8;                                //顺子
-- LAND_CARD_TYPE_DOUBLE_LINE              = 9;                                //连对
-- LAND_CARD_TYPE_PLANE                    = 10；                              //飞机 不带
-- LAND_CARD_TYPE_PLANE_TAKE_ONE           = 11；                              //飞机 带牌 单
-- LAND_CARD_TYPE_PLANE_TAKE_TWO           = 12；                              //飞机 带牌 对
-- LAND_CARD_TYPE_BOMB                     = 13;                               //炸弹
-- LAND_CARD_TYPE_MISSILE                  = 14;                               //火箭

end


-- 得到牌类型
function land_cards:get_cards_type(cards)
	local count = #cards
	if count == 1 then
		return LAND_CARD_TYPE_SINGLE, get_value(cards[1]) -- 单牌
	elseif count == 2 then
		if is_king(cards[1]) and is_king(cards[2]) then
			return LAND_CARD_TYPE_MISSILE -- 火箭
		elseif get_value(cards[1]) == get_value(cards[2]) then
			return LAND_CARD_TYPE_DOUBLE, get_value(cards[1]) -- 对牌
		end
		return nil
	end

	local ret = land_cards.analyseb_cards(cards)

	if #ret[4] == 1 then
		if count == 4 then
			return LAND_CARD_TYPE_BOMB, ret[4][1] -- 炸弹
		elseif count == 6 then
			return LAND_CARD_TYPE_FOUR_TAKE_ONE, ret[4][1] -- 四带两单
		elseif count == 8 and #ret[2] == 2 then
			return LAND_CARD_TYPE_FOUR_TAKE_TWO, ret[4][1] -- 四带两对
		elseif count >= 8 then
			table.insert(ret[3], ret[4][1])
			table.insert(ret[1], ret[4][1])
			table.sort(ret[3], function(a, b) return a < b end)
			table.sort(ret[1], function(a, b) return a < b end)
		else
			return nil
		end
	end
	local three_count = #ret[3]
	if three_count > 0 then
		--检查飞机
		if three_count > 1 then
			--飞机不允许出现2以上的
			if ret[3][1] >= 12 then
				return nil
			end
			local cur_val = nil
			for _, card in ipairs(ret[3]) do
				if card >= 12 then 	--飞机不允许出现2以上的
					return nil
				end
				if not cur_val then
					cur_val = card + 1
				elseif cur_val == card then
					cur_val = cur_val + 1
				else
					return nil
				end
			end

			if count == three_count * 3 then
				return LAND_CARD_TYPE_PLANE, ret[3][1] -- 飞机不带牌
			elseif count == three_count * 4 then
				return LAND_CARD_TYPE_PLANE_TAKE_ONE, ret[3][1] -- 飞机带单牌
			elseif count == three_count * 5 and #ret[2] == three_count then
				return LAND_CARD_TYPE_PLANE_TAKE_TWO, ret[3][1] -- 飞机带对牌
			end

		else

			--three_count == 1 only
			if count == three_count * 3 then
				return LAND_CARD_TYPE_THREE, ret[3][1]	-- 三不带
			elseif count == three_count * 4 then
				return LAND_CARD_TYPE_THREE_TAKE_ONE, ret[3][1] -- 三带一单
			elseif count == three_count * 5 and #ret[2] == three_count then
				return LAND_CARD_TYPE_THREE_TAKE_TWO, ret[3][1] -- 三带一对
			end

		end

		return nil
	end

	local two_count = #ret[2]
	if two_count >= 3 then
		if ret[2][1] >= 12 then
			return nil
		end
		local cur_val = nil
		for _, card in ipairs(ret[2]) do
			if not cur_val then
				cur_val = card + 1
			elseif cur_val == card then
				cur_val = cur_val + 1
			else
				return nil
			end
		end

		if count == two_count * 2 then
			return LAND_CARD_TYPE_DOUBLE_LINE, ret[2][1] -- 对连
		end
		return nil
	end

	local one_count = #ret[1]
	if one_count >= 5 and count == one_count then
		if ret[1][1] >= 12 then
			return nil
		end
		local cur_val = nil
		for _, card in ipairs(ret[1]) do
			if not cur_val then
				cur_val = card + 1
			elseif cur_val == card then
				cur_val = cur_val + 1
			else
				return nil
			end
		end

		return LAND_CARD_TYPE_SINGLE_LINE, ret[1][1] -- 单连
	end

	return nil
end

-- 比较牌
function land_cards:compare_cards(cur, last)
	print("land_cards  compare_cards")
	if cur.cards_val ~= nil then
		print(string.format("cur [%d,%d,%d]", cur.cards_type , cur.cards_count, cur.cards_val))
	else
		print(string.format("cur [%d,%d]", cur.cards_type , cur.cards_count))
	end
	if last ~= nil then
		print(string.format("last [%d,%d,%d]", last.cards_type , last.cards_count, last.cards_val))
	end
	if not last then
		return true
	end

	-- 比较火箭
	if cur.cards_type == LAND_CARD_TYPE_MISSILE then
		return true
	end

	-- 比较炸弹
	if last.cards_type == LAND_CARD_TYPE_BOMB then
		return cur.cards_type == LAND_CARD_TYPE_BOMB and cur.cards_val > last.cards_val
	elseif cur.cards_type == LAND_CARD_TYPE_BOMB then
		return true
	end

	return cur.cards_type == last.cards_type and cur.cards_count == last.cards_count and cur.cards_val > last.cards_val
end

-- 出牌
function land_cards:out_cards(cards)
	print("remove_card: "..table.concat( cards, ", "))
	for i,v in ipairs(cards) do
		self:remove_card(v)
	end
	print(string.format("card_count[%d],cards[%s]",#self.cards_ , table.concat( self.cards_, ", ")))
	return #self.cards_ > 0
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


--0  0： 方块3， 1： 梅花3， 2： 红桃3， 3： 黑桃3
--1  4： 方块4， 5： 梅花4， 6： 红桃4， 7： 黑桃4
--2  8： 方块5， 9： 梅花5， 10：红桃5， 11：黑桃5
--3  12：方块6， 13：梅花6， 14：红桃6， 15：黑桃6
--4  16：方块7， 17：梅花7， 18：红桃7， 19：黑桃7
--5  20：方块8， 21：梅花8， 22：红桃8， 23：黑桃8
--6  24：方块9， 25：梅花9， 26：红桃9， 27：黑桃9
--7  28：方块10，29：梅花10，30：红桃10，31：黑桃10
--8  32：方块J， 33：梅花J， 34：红桃J， 35：黑桃J
--9  36：方块Q， 37：梅花Q， 38：红桃Q， 39：黑桃Q
--10 40：方块K， 41：梅花K， 42：红桃K， 43：黑桃K
--11 44：方块A， 45：梅花A， 46：红桃A， 47：黑桃A
--12 48：方块2， 49：梅花2， 50：红桃2， 51：黑桃2，
--13 52：小王，  53：大王

function land_cards.analyseb_cards_new_sorting( cards , val , cards_table)
	-- body
    if val ~= nil then
        if cards.val == val and val < 13 then
    		cards.index = cards.index + 1
    		if cards.index == cards.max then
    			cards.index = 0
    			cards.val = nil
    			table.insert(cards_table.cards , val)
    		end
    	else
    		if cards.index > 0 and cards.val ~= nil then
    			if cards.index >= cards.max then
    				-- 不可能 不处理
    				log.error("analyseb_cards_new_sorting error cards.index[%d] cards.max[%d]" , cards.index , cards.max)
    			else
                    if cards_table[cards.index] == nil then
            			for i=1,cards.index do
                            table.insert(cards_table[1], cards.val)
                        end
                    else
                        table.insert(cards_table[cards.index], cards.val)
                    end
                end
    		end
    		cards.val = val
    		cards.index = 1
    	end
    else
        if cards.index > 0 and cards.val ~= nil then
            if cards.index >= cards.max then
                -- 不可能 不处理
                log.error("analyseb_cards_new_sorting error cards.index[%d] cards.max[%d]" , cards.index , cards.max)
            else
                if cards_table[cards.index] == nil then
                    for i=1,cards.index do
                        table.insert(cards_table[1], cards.val)
                    end
                else
                    table.insert(cards_table[cards.index], cards.val)
                end
            end
        end
    end
end

-- 分析牌
function land_cards.analyseb_cards_new(cards)

	if #cards > 1 then
		table.sort(cards, function(a, b) return a < b end)
	end

	local ret = {
					{ cards = {} }, 	                    -- 单
					{ cards = {} , [1] = {}},               -- 双
					{ cards = {} , [1] = {} , [2] = {}}, 	-- 三
					{ cards = {} , [1] = {} , [2] = {} , [3] = {}}     -- 炸
				} -- 依次单，双，三，炸的数组
    local twocards   = { index = 0 , val = nil , max = 2 , }
    local threecards = { index = 0 , val = nil , max = 3 , }
    local fourcards  = { index = 0 , val = nil , max = 4 , }

	for _, card in ipairs(cards) do
		local val = get_value(card)
		table.insert(ret[1].cards, val)
		land_cards.analyseb_cards_new_sorting(twocards   , val , ret[2])
		land_cards.analyseb_cards_new_sorting(threecards , val , ret[3])
		land_cards.analyseb_cards_new_sorting(fourcards  , val , ret[4])
	end


    land_cards.analyseb_cards_new_sorting(twocards   , nil , ret[2])
    land_cards.analyseb_cards_new_sorting(threecards , nil , ret[3])
    land_cards.analyseb_cards_new_sorting(fourcards  , nil , ret[4])

	return ret
end


-- 更多牌型
-- LAND_CARD_TYPE_ERROR                    = 0;                                //错误类型
-- LAND_CARD_TYPE_SINGLE                   = 1;                                //单牌类型
-- LAND_CARD_TYPE_DOUBLE                   = 2;                                //对牌类型
-- LAND_CARD_TYPE_THREE                    = 3;                                //三不带
-- LAND_CARD_TYPE_THREE_TAKE_ONE           = 4;                                //三带一
-- LAND_CARD_TYPE_THREE_TAKE_TWO           = 5;                                //三带一对
-- LAND_CARD_TYPE_FOUR_TAKE_ONE            = 6;                                //四带二
-- LAND_CARD_TYPE_FOUR_TAKE_TWO            = 7;                                //四带两对
-- LAND_CARD_TYPE_SINGLE_LINE              = 8;                                //顺子
-- LAND_CARD_TYPE_DOUBLE_LINE              = 9;                                //连对
-- LAND_CARD_TYPE_PLANE                    = 10；                              //飞机 不带
-- LAND_CARD_TYPE_PLANE_TAKE_ONE           = 11；                              //飞机 带牌 单
-- LAND_CARD_TYPE_PLANE_TAKE_TWO           = 12；                              //飞机 带牌 对
-- LAND_CARD_TYPE_BOMB                     = 13;                               //炸弹
-- LAND_CARD_TYPE_MISSILE                  = 14;                               //火箭


-- 得到牌类型
function land_cards:get_cards_type_new(cards)
	local count = #cards
	if count == 1 then
        if cards[1] == 53 then
		    return LAND_CARD_TYPE_SINGLE, get_value(cards[1]) + 1 -- 单牌
        else
            return LAND_CARD_TYPE_SINGLE, get_value(cards[1]) -- 单牌
        end
	elseif count == 2 then
		if is_king(cards[1]) and is_king(cards[2]) then
			return LAND_CARD_TYPE_MISSILE -- 火箭
		elseif get_value(cards[1]) == get_value(cards[2]) then
			return LAND_CARD_TYPE_DOUBLE, get_value(cards[1]) -- 对牌
		end
		return nil
	end

	local ret = land_cards.analyseb_cards_new(cards)
    dump(ret)

    if #ret[4].cards == 1 then
        if count == 4 then
            return LAND_CARD_TYPE_BOMB,  ret[4].cards[1] -- 炸弹
        elseif #ret[4][1] == 2 and #ret[4][2] == 0 and #ret[4][3] == 0 then
            return LAND_CARD_TYPE_FOUR_TAKE_ONE, ret[4].cards[1] -- 四带两单
        elseif #ret[4][1] == 0 and #ret[4][2] == 1 and #ret[4][3] == 0 then
            return LAND_CARD_TYPE_FOUR_TAKE_TWO, ret[4].cards[1] -- 四带两对
        end
    end

    if #ret[3].cards == 1 then
        if count == 3 then
            return LAND_CARD_TYPE_THREE, ret[3].cards[1] -- 三不带
        elseif count == 4 then
            return LAND_CARD_TYPE_THREE_TAKE_ONE, ret[3].cards[1] -- 三带一
        elseif #ret[3][1] == 0 and #ret[3][2] == 1 then
            return LAND_CARD_TYPE_THREE_TAKE_TWO, ret[3].cards[1] -- 三带一对
        end
    elseif #ret[3].cards > 1 then
        local card3_table = {}
        local card3_index = 0
        for k,v in ipairs(ret[3].cards) do
            if card3_table[card3_index] and card3_table[card3_index].card_val == v - 1 and v < 12 then -- 小于12 即 2点
                card3_table[card3_index].card_val = card3_table[card3_index].card_val + 1
                card3_table[card3_index].card_num = card3_table[card3_index].card_num + 1
            else
                local tempTable = {
                    card_val = v,
                    card_num = 1
                }
                table.insert(card3_table,tempTable)
                card3_index = card3_index + 1
            end
        end

        dump(card3_table)

        local take_cards_num = 0
        local card3_num = 0
        local card3_temp_num = 0
        for k,v in ipairs(card3_table) do
            if take_cards_num < v.card_num then
                take_cards_num = v.card_num
                card3_num = card3_num + card3_temp_num
                card3_temp_num = v.card_num
            else
                card3_num = card3_num + v.card_num
            end
        end
        if take_cards_num > 1 then  --  顺序必须相等 即为飞机 且 小于12 即 2点
            if #ret[3][1] == 0 and #ret[3][2] == 0 and card3_num == 0 then
                return LAND_CARD_TYPE_PLANE, ret[3].cards[1] -- 飞机不带牌
            elseif #ret[3][1] + #ret[3][2] * 2 + card3_num * 3 == take_cards_num then
                return LAND_CARD_TYPE_PLANE_TAKE_ONE, ret[3].cards[1] -- 飞机带单牌
            elseif #ret[3][1] == 0 and #ret[3][2] == take_cards_num and card3_num == 0 then
                return LAND_CARD_TYPE_PLANE_TAKE_TWO, ret[3].cards[1] -- 飞机带对牌
            end
        end
    end

    if #ret[2].cards >= 3 and #ret[2][1] == 0 then
        local cards2_value = ret[2].cards[1]
        local cards2_tmpe = 0
        for k,v in ipairs(ret[2].cards) do
            cards2_tmpe = v
            cards2_value = cards2_value + 1
        end
        if cards2_tmpe == cards2_value - 1 and cards2_tmpe < 12 then  --  顺序必须相等 即为飞机 且 小于12 即 2点
            return LAND_CARD_TYPE_DOUBLE_LINE , ret[2].cards[1] -- 对连
        end
    end

    if count >= 5 then
        local cards1_value = ret[1].cards[1]
        local cards1_tmpe = 0
        for k,v in ipairs(ret[1].cards) do
            cards1_tmpe = v
            cards1_value = cards1_value + 1
        end
        if cards1_tmpe == cards1_value - 1 and cards1_tmpe < 12 then  --  顺序必须相等 即为飞机 且 小于12 即 2点
            return LAND_CARD_TYPE_SINGLE_LINE, ret[1].cards[1]  -- 单连
        end
    end
	return nil
end