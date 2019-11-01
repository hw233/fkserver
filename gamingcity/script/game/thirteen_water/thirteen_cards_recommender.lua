-- 牌型推荐

local thirteen_cards_utils = require("game/thirteen_water/thirteen_cards_utils")

require "game.thirteen_water.thirteen_configs"
local Special_cards_type = Special_cards_type
local Cards_type = Cards_type
local Not_This_Card_Type = Not_This_Card_Type


thirteen_cards_recommender = {}

-- 创建
function thirteen_cards_recommender:new()
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 初始化(存放未整理的牌型)
function thirteen_cards_recommender:init(cards)
     --排序后的cards，便于分析牌
    self.cards_ = cards
    table.sort(self.cards_, function(a, b) return a < b end)

    --将所有牌按照张数和花色分组便于计算
    self.cards_by_count_ = thirteen_cards_utils.analy_cards_by_count(self.cards_)
	self.cards_by_color_ = thirteen_cards_utils.analy_cards_by_color(self.cards_)
end

function thirteen_cards_recommender:get_recommend_cards()
	-- body
	local recommend_cards = {}

	local cards_Info1 = {
		cards = {0,4,8,12,16,20,24,28,32,36,40,44,48},
		is_special = true,
		card_type = {13}
	}
	local cards_Info2 = {
		cards = {0,5,8,12,16,20,24,28,32,36,40,44,48},
		is_special = true,
		card_type = {13}
	}
	local cards_Info3 = {
		cards = self.cards_,
		is_special = false,
		card_type = {1,2,3}
	}
	
	
	table.insert(recommend_cards,cards_Info1)
	table.insert(recommend_cards,cards_Info2)
	table.insert(recommend_cards,cards_Info3)

	return recommend_cards
end


--检查特殊牌型
function thirteen_cards_recommender:check_special_cards()
	-- body
	local server_cards_Info = {
		pb_cards_all = {}
	}
	
	local special_cards_checks = {
	{func = thirteen_cards_recommender.check_QingLong},
	{func = thirteen_cards_recommender.check_Long},
	{func = thirteen_cards_recommender.check_All_AKQJ},
	{func = thirteen_cards_recommender.check_Three_Tonghua_Shun},
	{func = thirteen_cards_recommender.check_Three_Four},
	{func = thirteen_cards_recommender.check_All_Big},
	{func = thirteen_cards_recommender.check_All_Small},
	{func = thirteen_cards_recommender.check_Same_Color},
	{func = thirteen_cards_recommender.check_Four_Three},
	{func = thirteen_cards_recommender.check_Five_Double_Three},
	{func = thirteen_cards_recommender.check_Six_Double},
	{func = thirteen_cards_recommender.check_Three_Shunzi},
	{func = thirteen_cards_recommender.check_Three_Tonghua}
	}

	for i,v in ipairs(special_cards_checks) do
		local type,values = v.func(self)
		--是特殊牌型
		if type > 0 then
			print("sepcial card_type_-------------->>",type)
			local cards_Part = {
				cards = cards_,
				is_special = true,
				card_type = type,
				card_values = values
			}
			table.insert(server_cards_Info.pb_cards_all, cards_Part)
			return server_cards_Info
		end
	end

	return nil
end


--特殊牌型----------------------------------------------------------------------start
function thirteen_cards_recommender.test()
	-- body
	print("test start---------------------->>>>")
	local cards = {
	{0,4,8,12,16,20,24,28,32,36,40,44,48},
	{0,5,8,12,16,20,24,28,32,36,40,44,48},
	{36,37,38,39,40,41,42,44,46,47,48,49,50},
	{0,4,8,12,16,32,36,40,44,48,24,29,33},
	}
	local player_card = thirteen_cards_recommender:new()
	for i,v in ipairs(cards) do
		player_card:init(v)
		player_card:check_special_cards()
	end
	
	print("test end---------------------->>>>")
end

--清龙
function thirteen_cards_recommender:check_QingLong()
	-- body
	if thirteen_cards_utils.do_check_tonghua_shun(self.cards_,0) then
		return Special_cards_type.THIRTEEN_SPECIAL_QING_LONG
	end 
	return Not_This_Card_Type
end

--一条龙
function thirteen_cards_recommender:check_Long()
	-- body
	if thirteen_cards_utils.do_check_shunzi(self.cards_,0) then
		return Special_cards_type.THIRTEEN_SPECIAL_LONG
	end
	return Not_This_Card_Type
end

--十二皇族
function thirteen_cards_recommender:check_All_AKQJ()
	-- body
	for i,v in ipairs(self.cards_) do
		if thirteen_cards_utils.get_value(v) < 9 then
			return Not_This_Card_Type
		end
	end

	return Special_cards_type.THIRTEEN_SPECIAL_ALL_AKQJ
end

--三同花顺
function thirteen_cards_recommender:check_Three_Tonghua_Shun()
	-- body
	--必须是同花
	local card_type,values = self:check_Three_Tonghua()

	if card_type == Not_This_Card_Type then
		return Not_This_Card_Type
	end

	for _,v in ipairs(self.cards_by_color_) do
		if not thirteen_cards_utils.do_check_shunzi(v) then
			return Not_This_Card_Type
		end
	end 
	return Special_cards_type.THIRTEEN_SPECIAL_THREE_TONGHUA_SHUN
end

--三分天下(三组铁支)
function thirteen_cards_recommender:check_Three_Four()
	-- body
	if #self.cards_by_count_[4] == 3 then
		return Special_cards_type.THIRTEEN_SPECIAL_THREE_FOUR
	end
	return Not_This_Card_Type
end

--全大(8910JQKA)
function thirteen_cards_recommender:check_All_Big()
	-- body
	for i,v in ipairs(self.cards_) do
		if thirteen_cards_utils.get_value(v) < 6 then
			return Not_This_Card_Type
		end
	end

	return Special_cards_type.THIRTEEN_SPECIAL_ALL_BIG
end

--全小(2345678)
function thirteen_cards_recommender:check_All_Small()
	-- body
	for i,v in ipairs(self.cards_) do
		if thirteen_cards_utils.get_value(v) > 6 then
			return Not_This_Card_Type
		end
	end
	return Special_cards_type.THIRTEEN_SPECIAL_ALL_SMALL
end

--全黑色或者红色
function thirteen_cards_recommender:check_Same_Color()
	-- body
	if (#self.cards_by_color_[1] == 0 and #self.cards_by_color_[3] == 0) or (#self.cards_by_color_[2] == 0 and #self.cards_by_color_[4] == 0)  then
		return Special_cards_type.THIRTEEN_SPECIAL_SAME_COLOR
	end
	return Not_This_Card_Type
end

--四套三条
function thirteen_cards_recommender:check_Four_Three()
	-- body
	if #self.cards_by_count_[3] == 4 then
		return Special_cards_type.THIRTEEN_SPECIAL_FOUR_THREE
	end
	return Not_This_Card_Type
end

--五对三条
function thirteen_cards_recommender:check_Five_Double_Three()
	-- body
	if #self.cards_by_count_[2] == 5 and #self.cards_by_count_[3] == 1 then
		return Special_cards_type.THIRTEEN_SPECIAL_FIVE_DOUBLE_THREE
	end
	return Not_This_Card_Type
end

--六对半
function thirteen_cards_recommender:check_Six_Double()
	-- body
	if #self.cards_by_count_[2] == 6 then
		return Special_cards_type.THIRTEEN_SPECIAL_SIX_DOUBLE
	end
	return Not_This_Card_Type
end

--三顺子--------------------------------------------------------------------------start
function thirteen_cards_recommender:check_Three_Shunzi()
	-- body
	--如果是三顺子就将结果放到这里
	self.three_shunzi_ = nil

	--将牌放入3组有序数
	local cards_temp = {{},{},{}}
	self:add_card_to_all_shunzi(self.cards_,1,cards_temp)

	if self.three_shunzi_ then
		print("check_Three_Shunzi--------------------------------1")
		for i,v in ipairs(self.three_shunzi_) do
			print("-------------------------")
			for j,card in ipairs(v) do
				print("card->",thirteen_cards_utils.get_value(card))
			end
		end
		print("check_Three_Shunzi--------------------------------2")
		return Special_cards_type.THIRTEEN_SPECIAL_THREE_SHUN_ZI
	end
	
	return Not_This_Card_Type

end

function thirteen_cards_recommender:add_card_to_all_shunzi(cards,card_index,all_shunzi)
	-- body
	if card_index > #cards then
		return
	end

	local row_nums = self:check_add_card_rows(cards,card_index,all_shunzi)

	if #row_nums < 1 then
		return
	end

	local all_types_shunzi = {all_shunzi}

	--对其他每种结果都复制一份
	for i=2,#row_nums do
		local shunzi_copy = self:copy_all_shunzi(all_shunzi)
		table.insert(all_types_shunzi,shunzi_copy)
	end

	--依次加入每一行
	for i,num in ipairs(row_nums) do
		self:add_card_to_shunzi(cards,card_index,all_types_shunzi[i],num)
	end
end

--检测可以添加到哪几行
function thirteen_cards_recommender:check_add_card_rows(cards,card_index,all_shunzi)
	-- body
	local add_card = cards[card_index]
	local card_value = thirteen_cards_utils.get_value(add_card)

	local row_nums = {}
	local add_to_empty_row = true

	for i=1,#all_shunzi do
		
		local shunzi = all_shunzi[i]
		local cards_len = #shunzi
		local success = false

		if cards_len == 0 then--尚未添加元素
			if add_to_empty_row then
				table.insert(row_nums,i)
				add_to_empty_row = false
			end
			
		elseif cards_len < 5 then
		    --检查是否比最后一张牌大1
			local last_card_value = thirteen_cards_utils.get_value(shunzi[cards_len])
			if card_value == (last_card_value + 1)  then		
				table.insert(row_nums,i)
			end
		end
	end
	return row_nums
end

--将牌添加到顺子后面
function thirteen_cards_recommender:add_card_to_shunzi(cards,card_index,all_shunzi,order_index)
	-- body
	table.insert(all_shunzi[order_index],cards[card_index])

	--牌全部插完
	if card_index == #cards then
		self:check_ordered_Three_Shunzi(all_shunzi)
	else
		--插入下一张牌
		self:add_card_to_all_shunzi(cards,card_index+1,all_shunzi)
	end
end

--复制多组有序数列
function thirteen_cards_recommender:copy_all_shunzi(all_shunzi)
	-- body
	local all_shunzi_copy = {}
	for i,cards_ in ipairs(all_shunzi) do
		all_shunzi_copy[i] = {}
		for j,card in ipairs(cards_) do
			table.insert(all_shunzi_copy[i],card)
		end
	end
	return all_shunzi_copy
end

--检查三组有序数是否是三顺子
function thirteen_cards_recommender:check_ordered_Three_Shunzi(cards_temp)
	-- body
	for i,v in ipairs(cards_temp) do
		local cards_len = #v
		if cards_len ~= 5 and cards_len ~= 3 then
			return
		end
	end

	--是三顺子，赋值
	self.three_shunzi_ = cards_temp
end
--三顺子--------------------------------------------------------------------------end

--三同花
function thirteen_cards_recommender:check_Three_Tonghua()
	-- body
	local color_count = 0--花色数量
	for i,v in ipairs(self.cards_by_color_) do
		local cards_count = #v

		--每种花色必须为3张或者5张牌
		if cards_count ~= 3 and cards_count ~= 5 then
			return Not_This_Card_Type
		end

	 	if cards_count > 0 then
	 		color_count = color_count + 1
	 	end

	 	--只能有三种花色
	 	if color_count > 3 then
	 		return Not_This_Card_Type
	 	end
	end 

	return Special_cards_type.THIRTEEN_SPECIAL_THREE_TONG_HUA
end
--特殊牌型----------------------------------------------------------------------end