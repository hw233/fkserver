-- 斗地主逻辑
local pb = require "pb"

local base_table = require "game.lobby.base_table"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.bigtwo.bigtwo_cards"
local random = require "random"
local bigtwo_cards = bigtwo_cards

local offlinePunishment_flag = false

local GAME_SERVER_RESULT_READY_FAILED = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_READY_FAILED")
local LOG_MONEY_OPT_TYPE_BIGTWO = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_BIGTWO")
-- enum BIGTWO_CARD_TYPE
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local BT_Error = pb.enum("BIGTWO_CARD_TYPE", "BT_Error")
local BT_HIGH_CARD = pb.enum("BIGTWO_CARD_TYPE", "BT_HIGH_CARD")
local BT_ONE_PAIR = pb.enum("BIGTWO_CARD_TYPE", "BT_ONE_PAIR")
local BT_THREE_OF_A_KIND = pb.enum("BIGTWO_CARD_TYPE", "BT_THREE_OF_A_KIND")
local BT_STRAIGHT = pb.enum("BIGTWO_CARD_TYPE", "BT_STRAIGHT")
local BT_FLUSH = pb.enum("BIGTWO_CARD_TYPE", "BT_FLUSH")
local BT_FULL_HOUSE = pb.enum("BIGTWO_CARD_TYPE", "BT_FULL_HOUSE")
local BT_FOUR_OF_KIND = pb.enum("BIGTWO_CARD_TYPE", "BT_FOUR_OF_KIND")
local BT_STRAIT_FLUSH = pb.enum("BIGTWO_CARD_TYPE", "BT_STRAIT_FLUSH")

-- 锄大地人数
local BIGTWO_PLAYER_COUNT = 4

-- 出牌时间
local BIGTWO_TIME_OUT_CARD = 15
-- 叫分时间
local BIGTWO_TIME_CALL_SCORE = 15
-- 首出时间
local BIGTWO_TIME_HEAD_OUT_CARD = 15
-- 玩家掉线等待时间
local BIGTWO_TIME_WAIT_OFFLINE = 30
-- ip限制等待时间
local BIGTWO_TIME_IP_CONTROL = 20
-- ip限制开启人数
local BIGTWO_IP_CONTROL_NUM = 20

-- 等待开始
local BIGTWO_STATUS_FREE = 1
-- 叫分状态
local BIGTWO_STATUS_CALL = 2
-- 游戏进行
local BIGTWO_STATUS_PLAY = 3
-- 玩家掉线
local BIGTWO_STATUS_PLAYOFFLINE = 4

--中奖公告标准,超过该标准全服公告
local BIGTWO_GRAND_PRICE_BASE = 10000

local BIGTWO_TIME_OVER = 1000

bigtwo_table = base_table:new()

--@add paramter to record game runtimes 17.05.25 hy
--	self.game_runtimes = 0
--	self.privateRules={}	            --private_rules reserv
	local def_first_game_type = def_first_game_type
	local def_second_game_type = def_second_game_type
	local def_game_name = def_game_name
--end

-- 初始化
function bigtwo_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)	
	self.callsore_time = 0
	self.status = BIGTWO_STATUS_FREE
	self.bigtwo_player_cards = {}
	for i = 1, chair_count do
		self.bigtwo_player_cards[i] = bigtwo_cards:new()
	end

	self.cards = {}
	for i = 1, 52 do
		self.cards[i] = i - 1
	end
	self:clear_ready()
	self.black_rate = 0
	--print(string.format("-----def_second_game_type %d--def_game_name %s--def_private %d-----",def_second_game_type, def_game_name, def_private))
end

-- 检查是否可准备
function bigtwo_table:check_ready(player)
	if self.status ~= BIGTWO_STATUS_FREE then
		return false
	end
	return true
end
--操作次数
function bigtwo_table:operation(player)
	--if player.chair_id ~= nil then
		--self.private_player_operation[player.chair_id] = self.private_player_operation[player.chair_id] + 1
	--end
end
-- 检查是否可取消准备
function bigtwo_table:check_cancel_ready(player, is_offline)
	base_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if is_offline then
		print("========================operation private false")
		--掉线
		if  self.status ~= BIGTWO_STATUS_FREE then
			--掉线处理
			self:player_offline(player)
			return false
		end
	end	

	--退出
	return true
end

-- 洗牌
function bigtwo_table:shuffle()
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	--[[
	--同花顺
		for i = 1, 4 do
			local k = 0
			local j = 4
			for v = 1 + (i - 1) * 13, i * 13 do
				self.cards[v] = (k * j) + i - 1
				k = k + 1
			end
		end
		log.info(table.concat(self.cards, ','))
	--]]
	--[[
	--顺子
	for i = 1, 4 do
		local k = 0
		local j = 4
		for v = 1 + (i - 1) * 13, i * 13 do
			self.cards[v] = (k * j) + i - 1
			k = k + 1
		end
	end
	for i = 1 , 12, 2 do 
		local t = self.cards[i]
		self.cards[i] = self.cards[i + 13]
		self.cards[i + 13] = self.cards[i + 13 * 2]
		self.cards[i + 13 * 2] = self.cards[i + 13 * 3]
		self.cards[i + 13 * 3] = t
	end
	--]]
    ----[[
    --正常
	for i = 1, 27 do
		local x = math.random(52)
		local y = math.random(52)
		if x ~= y then
			self.cards[x], self.cards[y] = self.cards[y], self.cards[x]
		end
	end
	--]]
end

function bigtwo_table:load_lua_cfg()
	print ("--------------------###############################load_lua_cfg", self.room_.room_cfg)
	log.info(string.format("bigtwo_table: game_maintain_is_open = [%d]",self.room_.game_switch_is_open))
	--local fucT = load(self.room_.room_cfg)
	--local sangong_config = fucT()
	print ("-------------------",self.room_.room_cfg)
	if self.room_.room_cfg == "" then
		return
	end
	local bigtwo_config = json.decode(self.room_.room_cfg)
	if bigtwo_config then
		if bigtwo_config.black_rate then
			self.black_rate = bigtwo_config.black_rate
			log.info(string.format("#########black_rate:[%f]",self.black_rate))
		end
	else
		print("land_config is nil")
	end
end

--做差牌
function bigtwo_table:shuffle_cheat_cards( bad_num)

	if bad_num > 2 then
		bad_num = 2
	end

	-- body
	local bad_cards_list = {}

	local arrAllCards = {}
	for i=0,3 do
		arrAllCards[i] = {}
		for j=0,12 do
			arrAllCards[i][j] = 1
		end
	end

	for n = 1, bad_num do
		bad_cards_list[n] = {}
		local bad_cards = bad_cards_list[n]
		--6,7随机一个空位
		local iLackValue1 = {}
		local iLackValue2 = {}
		if (random.boost_integer(1,2) + 2) == 3 then
			iLackValue1[1] = 3
			iLackValue1[2] = 4
		else
			iLackValue1[1] = 4
			iLackValue1[2] = 2
		end

		--10, J随机一个空位
		if (random.boost_integer(1,2) + 6) == 7 then
			iLackValue2[1] = 7
			iLackValue2[2] = 8
		else
			iLackValue2[1] = 8
			iLackValue2[2] = 7
		end


		--花色数量
		local tColor = {}
		for i= 0,3 do
			tColor[i] = 0
		end
		local tNum = {}
		for i= 0,11 do
			tNum[i] = 0
		end

		local iBadCardsCount = 1

		--10以上的选5张
		--50概率给一张A
		local coeff_value = random.boost_integer(1,100)
		if coeff_value < 50 then --抽A
			while (iBadCardsCount < 2) do
				local card_A = 11
				local iColor = random.boost_integer(0,3)
				if tColor[iColor] < 4 and arrAllCards[iColor][card_A] == 1 then					
					arrAllCards[iColor][card_A] = 0	
					bad_cards[iBadCardsCount] = getIntPart(card_A * 4 + iColor)	
					print("A:", bad_cards[iBadCardsCount])				
					iBadCardsCount = iBadCardsCount + 1
					tColor[iColor] = tColor[iColor] + 1
					tNum[card_A] = tNum[card_A] + 1
				end
			end
		end

		while (iBadCardsCount < 4) do
			local iColor = random.boost_integer(0,3)
			if tColor[iColor] < 6 then
				local iValueIndex = random.boost_integer(9,10)
				if tNum[iValueIndex] < 3 and arrAllCards[iColor][iValueIndex] == 1 then
					arrAllCards[iColor][iValueIndex] = 0	
					bad_cards[iBadCardsCount] = getIntPart(iValueIndex * 4 + iColor)	
					print("B:", bad_cards[iBadCardsCount])				
					iBadCardsCount = iBadCardsCount + 1
					tColor[iColor] = tColor[iColor] + 1
					tNum[iValueIndex] = tNum[iValueIndex] + 1
				end
			end
		end

		while (iBadCardsCount < 14) do
			local iColor = random.boost_integer(0,3)
			if tColor[iColor] < 6 then
				local iValueIndex = random.boost_integer(0,8)
				if tNum[iValueIndex] < 2 and iValueIndex ~= iLackValue1[n] and iValueIndex ~= iLackValue2[n] and arrAllCards[iColor][iValueIndex] == 1 then
					arrAllCards[iColor][iValueIndex] = 0	
					bad_cards[iBadCardsCount] = getIntPart(iValueIndex * 4 + iColor)	
					print("C:", bad_cards[iBadCardsCount])				
					iBadCardsCount = iBadCardsCount + 1
					tColor[iColor] = tColor[iColor] + 1
					tNum[iValueIndex] = tNum[iValueIndex] + 1
				end
			end
		end
	end


	local arr_last_Cards = {}
	for i=0,3 do
		for j=0,12 do
			if arrAllCards[i][j] == 1 then
				table.insert(arr_last_Cards, getIntPart(j * 4 + i))
			end
		end
	end
	local ilen = #arr_last_Cards
	if ilen ~= (52 - (13 * bad_num)) then		
		log.error(string.format("bigtwo_cards:shuffle_cheat_cards black_num[%d] ilen[%d] cards[%s]  black1[%s] black2[%s]",bad_num, ilen,  table.concat(arr_last_Cards, ','), table.concat(bad_cards_list[1], ','), table.concat(bad_cards_list[2], ',')))
	end

	--混乱剩余扑克
	for i = 1, ilen/2 do
		local x = random.boost(ilen)
		local y = random.boost(ilen)
		if x ~= y then
			arr_last_Cards[x], arr_last_Cards[y] = arr_last_Cards[y], arr_last_Cards[x]
		end
	end

	local cur = 0
	for i = 1,  (4 - bad_num) do
		bad_cards_list[i + bad_num] = {}
		for j = cur + 1, cur + 13 do
			table.insert(bad_cards_list[i + bad_num], arr_last_Cards[j])
		end
		cur = cur + 13
	end

	local icard_id = 1
	for i = 1, 4 do
		for _,z in ipairs(bad_cards_list[i]) do
			self.cards[icard_id] = z
			icard_id = icard_id + 1
		end
	end

	if self:check_cards_type(self.cards) == true then
		--log.info("check_cards_type---------->ok")
		return true
	else
		--log.error("check_cards_type---------->error")
		return false
	end

end

--校验牌库牌型是否错误
function bigtwo_table:check_cards_type(all_cards)
	if not all_cards then
		--log.error("------------------------->all_cards is nil")
		return false
	end

	local cards_count = getNum(all_cards)
	if cards_count ~= 54 then
		--log.error(string.format("all_cards count error,curCards total[%d]", cards_count))
		return false
	end


	local cards = {}
	for _,z in ipairs(all_cards) do
		if z then
			table.insert(cards,z)
		end
	end
	table.sort(cards, function(a, b) return a < b end)
	--log.info(table.concat(cards, ','))
	--校验牌是否有重复的牌和牌型
	local cards_voctor = {}
	for i,v in ipairs(cards) do
		local value_key = i - 1
		if v < 0 or v > 53 then
			log.error(table.concat(cards, ','))
			--log.error(string.format("cards value error [%d]",v))
			return false
		end
		if value_key ~= v then
			--log.error(string.format("~~~~~~~~~~~~index = [%d]",v))
			log.info(table.concat(cards, ','))
			return false
		end

		if not cards_voctor[v] then
			cards_voctor[v] = 1
		else
			log.error(table.concat(cards, ','))
			--log.error(string.format("repeat cards error----------->[%d]",v))
			return false
		end
	end

	return true
end
-- 开始游戏
function bigtwo_table:start()	
 	--print(debug.traceback())
	
	if base_table.start(self) == nil then
		log.info(string.format("cant Start Game ===================================================="))
		self:clear_ready()
		return
	end
	self.gamelog.start_game_time = get_second_time()
	self:shuffle()
	-- 发牌
	self.callpoints_log = {
		start_time = get_second_time(),
		player_cards = {},
		--bigtwo_card = string.format("%d %d %d",self.cards[52], self.cards[53], self.cards[54]),
	}
	self.first_turn = 0
	self.last_out_cards = nil

	--检查黑名单
	local black_user_list = {}
	if self.black_rate > 0 then
		for i,v in ipairs(self.player_list_) do
			if self:check_blacklist_player(v.guid) and self.black_rate > random.boost_integer(1,100) then
				table.insert(black_user_list, v)		
			end
		
		end
	end

	local send_card_list = self.player_list_
	if #black_user_list > 0 then
		while #black_user_list > 2 do
			table.remove(black_user_list, random.boost_integer(1,#black_user_list))
		end
		self:shuffle_cheat_cards(#black_user_list)
		send_card_list = {}
		local send_in = 1
		for i,v in ipairs(black_user_list) do
			send_card_list[send_in] = v	
			send_in = send_in + 1
		end

		for i,v in ipairs(self.player_list_) do
			local is_in = true
			for _,t in ipairs(black_user_list) do
				if v.guid == t.guid then
					is_in = false
				end
			end
			if is_in then
				send_card_list[send_in] = v	
				send_in = send_in + 1
			end
		end
	end
	local cur = 0
	for i,v in ipairs(send_card_list) do
		if v then
			local cards = {}
			for j = cur + 1, cur + 13 do
				table.insert(cards, self.cards[j])
				--方块三先出
				if self.cards[j] == 0 then
					self.first_turn = v.chair_id
				elseif self.cards[j] == 51 then
					self.black_two = v.chair_id
				end
			end
			cur = cur + 13
			table.sort(cards, function(a, b) return a < b end)
			v.outTime = 0
			v.isTrusteeship = false
			v.TrusteeshipTimes = 0
			self.bigtwo_player_cards[v.chair_id]:init(cards)
			log.info("----------------------")
			log.info("v.chair_id:" .. v.chair_id)
			log.info(table.concat(self.bigtwo_player_cards[v.chair_id].cards_, ','))

			----------- 日志相关
			local player_card = {
				chair_id = v.chair_id,
				guid = v.guid,
				cards = table.concat(cards, ','),
			}
			table.insert(self.callpoints_log.player_cards,player_card)
		end
	end
	--设置黑桃二
	self.bigtwo_player_cards[self.black_two]:SetBlackTwo()
	self.callpoints_log.first_turn = self.first_turn

	for i,v in ipairs(self.player_list_) do
		local msg = {
		first_turn = self.first_turn
		}	
		msg.cards = self.bigtwo_player_cards[v.chair_id]:get_cards()	
		send2client_pb(v, "SC_BTStart", msg)
	end

	log.info("first call soure chairid : "..self.first_turn)
	self.cur_turn = self.first_turn
	self.status = BIGTWO_STATUS_PLAY
	--游戏开始
	self:startGame()
end

function bigtwo_table:startGame( ... )
	-- body
	-- 获取 牌局id
	log.info("gamestart =================================================")
	self.table_game_id = self:get_now_game_id()
	log.info(self.table_game_id)
	self:next_game()	
	log.info(self:get_now_game_id())
	-- 获取开始时间
	self.time0_ = get_second_time()
	self.start_time = self.time0_

	-- 记录日志
	table.insert(self.gamelog.CallPoints,self.callpoints_log)
	self.gamelog.table_game_id = self.table_game_id
	self.gamelog.start_game_time = self.time0_
	self.time_outcard_ = BIGTWO_TIME_HEAD_OUT_CARD

	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log.info(string.format("Player InOut Log,bigtwo_table:startGame player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),tostring(self.table_game_id)))
		end
	end
end
--托管
function bigtwo_table:set_trusteeship(player,flag)
	-- body
	player.TrusteeshipTimes = 0
	player.isTrusteeship = not player.isTrusteeship
	log.info("chair_id:"..player.chair_id)
	if player.isTrusteeship then 
		log.info("**************:true")
		if self.cur_turn == player.chair_id then
			self:trusteeship(player)
		end
		if flag == true then
			player.finishOutGame = true
		end
	else
		log.info("**************:false")
		player.finishOutGame = false
	end
	local msg = {
		chair_id = player.chair_id,
		isTrusteeship = player.isTrusteeship,
		}
	self:broadcast2client("SC_BTTrusteeship", msg)
end

-- 出牌
function bigtwo_table:out_card(player, cardslist, flag)
	log.info("player:" .. player.chair_id)
	log.info(table.concat(cardslist,","))
	if self.status ~= BIGTWO_STATUS_PLAY then
		log.warning(string.format("bigtwo_table:out_card guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log.warning(string.format("bigtwo_table:out_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	--判断牌是否属于自己列表 
	local playercards = self.bigtwo_player_cards[player.chair_id]
	if  not cardslist or #cardslist > 5 or  #cardslist == 0 then
		log.error(string.format("bigtwo_table:out_card guid[%d] out cards[%s] error, has[%s]", player.guid, table.concat(cardslist, ','), table.concat(playercards.cards_, ',')))
		return
	end

	if not playercards:check_cards(cardslist) then
		log.error(string.format("bigtwo_table:out_card guid[%d] out cards[%s] error, has[%s]", player.guid, table.concat(cardslist, ','), table.concat(playercards.cards_, ',')))
		return
	end

	-- 排序
	if #cardslist > 1 then
		table.sort(cardslist, function(a, b) return a < b end)
	end

	local cardstype, cardsval, cardscolor, cardscount = playercards:get_cards_type(cardslist)
	if not cardstype then
		log.error(string.format("bigtwo_table:out_card guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cardslist, ',')))
		return
	end	
	local cur_out_cards = {cards_type = cardstype, cards_val = cardsval, cards_color = cardscolor, cards_count = cardscount}
	if not playercards:compare_cards(cur_out_cards, self.last_out_cards) then
		log.error(string.format("bigtwo_table:out_card guid[%d] compare_cards error, cards[%s], cur_out_cards[%d,%d,%d,%d], last_out_cards[%d,%d,%d,%d]", player.guid, table.concat(cardslist, ','), 
			cur_out_cards.cards_type , cur_out_cards.cards_color, cur_out_cards.cards_val,cur_out_cards.cards_count,
			self.last_out_cards.cards_type,self.last_out_cards.cards_color,self.last_out_cards.cards_val,self.last_out_cards.cards_count))
		return
	end	

	if not flag or flag == false then
		player.TrusteeshipTimes = 0
	end

	-- 记录日志
	local outcard = {
		chair_id = player.chair_id,
		outcards = string.format("%s",table.concat(cardslist, ',')),
		sparecards = "",
		time = get_second_time(),
		isTrusteeship = player.isTrusteeship and 1 or 0,
	}

	self.last_out_cards = cur_out_cards
	self.last_cards = cardslist
	table.insert(self.Already_Out_Cards,cardslist)

	self.time_outcard_ = BIGTWO_TIME_OUT_CARD
	if cardstype == BIGTWO_CARD_TYPE_MISSILE or cardstype == BIGTWO_CARD_TYPE_BOMB then
		playercards:add_bomb_count()
		self.bomb = self.bomb + 1
	end

	self.first_turn = self.cur_turn
	if cardstype ~= BIGTWO_CARD_TYPE_MISSILE then
		if self.cur_turn == 4 then
			self.cur_turn = 1
		else
			self.cur_turn = self.cur_turn + 1
		end
	else
		self.last_out_cards = nil
	end

	local notify = {
		cur_chair_id = self.cur_turn,
		out_chair_id = player.chair_id,
		cards = cardslist,
		}
	self:broadcast2client("SC_BTOutCard", notify)
	log.info(string.format("outcard ==========================   chair_id [%d] cards[%s]", player.chair_id, table.concat(cardslist, ',')))
	player.outTime = 0
	self.time0_ = get_second_time()

	local outCardFlag = not playercards:out_cards(cardslist)
	-- 记录剩下的牌
	outcard.sparecards = string.format("%s",table.concat(playercards.cards_, ','))
	table.insert(self.gamelog.outcard_process,outcard)

	if outCardFlag then
		self:finishgame(player)
	else
		self:Next_Player_Proc()
	end
end

-- 放弃出牌
function bigtwo_table:pass_card(player, flag)
	if self.status ~= BIGTWO_STATUS_PLAY then
		log.warning(string.format("bigtwo_table:pass_card guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log.warning(string.format("bigtwo_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	if not self.last_out_cards then
		log.error(string.format("bigtwo_table:pass_card guid[%d] first turn", player.guid))
		return
	end

	if not flag or flag == false then
		player.TrusteeshipTimes = 0
	end

	-- 记录日志
	local outcard = {
		chair_id = player.chair_id,
		outcards = "pass card",
		sparecards = string.format("%s",table.concat(self.bigtwo_player_cards[player.chair_id].cards_, ',')),
		time = get_second_time(),		
		isTrusteeship = player.isTrusteeship and 1 or 0,
	}
	table.insert(self.gamelog.outcard_process,outcard)


	if self.cur_turn == 4 then
		self.cur_turn = 1
	else
		self.cur_turn = self.cur_turn + 1
	end

	local is_turn_over = (self.cur_turn == self.first_turn and 1 or 0)
	if is_turn_over == 1 then
		self.last_out_cards = nil
	end

	-- self.time0_ = get_second_time()
	local notify = {
		cur_chair_id = self.cur_turn,
		pass_chair_id = player.chair_id,
		}
	log.info(string.format("cur_chair_id[%d],pass_chair_id[%d]",notify.cur_chair_id,notify.pass_chair_id))
	self:broadcast2client("SC_BTPassCard", notify)
	self:Next_Player_Proc()
end
function bigtwo_table:Next_Player_Proc( ... )
	-- body
	if  self.status == BIGTWO_STATUS_CALL then
		if not self.player_list_[self.cur_turn] then
			log.error(string.format("not find player gameTableid [%s]",self.table_game_id))
			self:finishgameError()
		elseif self.player_list_[self.cur_turn].Dropped or self.player_list_[self.cur_turn].isTrusteeship then
			-- self:call_score(self.player_list_[self.cur_turn], 0)
			self.time0_ = get_second_time() - BIGTWO_TIME_CALL_SCORE + 1
		end
	elseif self.status == BIGTWO_STATUS_PLAY then
		log.info("========================================Next_Player_ProcA", self.cur_turn, self.player_list_[self.cur_turn])
		print("========================================Next_Player_ProcB", self.player_list_[self.cur_turn].Dropped , self.player_list_[self.cur_turn].isTrusteeship)
		if self.player_list_[self.cur_turn].Dropped or self.player_list_[self.cur_turn].isTrusteeship then
			log.info("========================================Trusteeship123")
			--self:trusteeship(self.player_list_[self.cur_turn])
			log.info(self.time0_,get_second_time(),self.time_outcard_)
			self.time0_ = get_second_time() - self.time_outcard_ + 1
			log.info(self.time0_,get_second_time(),self.time_outcard_)
		else
			self.time0_ = get_second_time()
		end
	end
end
--玩家上线处理
function  bigtwo_table:reconnect(player)
	-- body
	-- 新需求 玩家掉线不暂停游戏 只是托管
end
function  bigtwo_table:is_play( ... )
	log.info("bigtwo_table:is_play :"..self.status)
	-- body
	if self.status == BIGTWO_STATUS_PLAY or self.status == BIGTWO_STATUS_PLAYOFFLINE or self.status == BIGTWO_STATUS_CALL or self.private_isplay == true then
		log.info("is_play  return true")
		return true
	end
	return false
end
--请求玩家数据
function bigtwo_table:reconnection_play_msg(player)
	-- body
	log.info("player online : "..player.chair_id)
	base_table.reconnection_play_msg(self,player)
	if def_second_game_type == def_private and self.status == BIGTWO_STATUS_FREE then
		player.isTrusteeship = true
		self:set_trusteeship(player,false)
		send2client_pb(player, "SC_RecconectReady")
		return
	end
	local notify = {
			room_id = player.room_id,
			table_id = player.table_id,
			chair_id = player.chair_id,
			result = GAME_SERVER_RESULT_SUCCESS,
			ip_area = player.ip_area,
		}
	self:foreach_except(player.chair_id, function (p)
		local v = {
			chair_id = p.chair_id,
			guid = p.guid,
			account = p.account,
			nickname = p.nickname,
			level = p:get_level(),
			money = p:get_money(),
			header_icon = p:get_header_icon(),
			ip_area = p.ip_area,
		}
		notify.pb_visual_info = notify.pb_visual_info or {}
		table.insert(notify.pb_visual_info, v)
	end)
	
	send2client_pb(player, "SC_PlayerReconnection", notify)
	self:recoveryplayercard(player)


	local notify = {
		cur_online_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
	}
	self:broadcast2client("SC_BTPlayerOnline", notify)
	player.isTrusteeship = true
	self:set_trusteeship(player,false)
end
function bigtwo_table:ready(player)
	log.info("bigtwo_table:ready ======= :"..player.table_id)
	if self:is_play() and self.private_isplay ~= true then
		log.info("bigtwo_table: is play  can not ready ======= tableid:"..player.table_id)
		return
	end
	if not self:can_enter(player) then
		self.room_.room_manager_:change_table(player)
		local tab = self.room_:find_table(player.table_id)
		tab:ready(player)
		return
	end

	base_table.ready(self,player)
	player.offtime = nil
	player.isTrusteeship = false
	player.finishOutGame = false
end
--恢复玩家当前数据
function  bigtwo_table:recoveryplayercard(player)
	log.info("---------recoveryplayercard-----------")
	-- 游戏进行时发牌
	if self.status == BIGTWO_STATUS_PLAY or self.status == BIGTWO_STATUS_DOUBLE then
	log.info("---------recoveryplayercard-----------1")
		local notify = {
			cur_chair_id = player.chair_id,
			cards = self.bigtwo_player_cards[player.chair_id].cards_,
			pb_msg = {},
			lastCards  = self.last_cards,
			lastcardid = self.first_turn,
			outcardid  = self.cur_turn,
			alreadyoutcards = self.Already_Out_Cards,
		}
		for i,v in ipairs(self.player_list_) do
			if v.chair_id ~= player.chair_id then
				local m = {
					chair_id = v.chair_id,
					cardsnum = #self.bigtwo_player_cards[v.chair_id].cards_,
					isTrusteeship = v.isTrusteeship,
				}
				table.insert(notify.pb_msg,m)
			end
		end

		log.info(string.format("chairid[%d] cards[%s]",player.chair_id,table.concat( self.bigtwo_player_cards[player.chair_id].cards_, ", ")))
		log.info("---------SC_BTRecoveryPlayerCard-----------")
		send2client_pb(player, "SC_BTRecoveryPlayerCard", notify)
	elseif self.status == BIGTWO_STATUS_PLAYOFFLINE or self.status == BIGTWO_STATUS_CALL then
	log.info("---------recoveryplayercard-----------2")
		local notify = {
			cards = self.bigtwo_player_cards[player.chair_id].cards_,
			pb_playerOfflineMsg = {}
		}
		player.offtime = nil
		local waitT = 0
		for i,v in ipairs(self.player_list_) do
			if v then
				if v.offtime then
					local pptime = get_second_time() - v.offtime
					if pptime >= BIGTWO_TIME_WAIT_OFFLINE then
						pptime = 0
					else
						pptime = BIGTWO_TIME_WAIT_OFFLINE - pptime
					end
					local xxnotify = {
						chair_id = v.chair_id,
						outTimes = pptime,
					}
					table.insert(notify.pb_playerOfflineMsg, xxnotify)
					if v.offtime then
						if v.offtime > waitT then
							waitT = v.offtime
						end
					end
				end
			end
		end
		send2client_pb(player, "SC_BTRecoveryPlayerCallScore", notify)
		if waitT == 0 then
			self.time0_ = get_second_time()
			self.status = BIGTWO_STATUS_CALL
		else
			self.time0_ = waitT
		end
	end
end
--玩家掉线处理
function  bigtwo_table:player_offline( player )
	log.info("bigtwo_table:player_offline")
	base_table.player_offline(self,player)
	log.info("player offline : ".. player.chair_id)
	-- body
	if self.status == BIGTWO_STATUS_FREE then
		-- 等待开始时 掉线则强制退出玩家
		player:forced_exit()
	elseif self.status == BIGTWO_STATUS_PLAY or self.status == BIGTWO_STATUS_CALL or self.status == BIGTWO_STATUS_DOUBLE then
		-- 游戏进行时 则暂停游戏
		-- 新需求更新为 不再暂停游戏 托管玩家
		self:set_trusteeship(player,true)
	elseif self.status == BIGTWO_STATUS_PLAYOFFLINE then
		--设置状态为等待
		player.offtime = get_second_time()
		local i = 0
		for i,v in ipairs(self.player_list_) do
			if v then
				i = i + 1
			end
		end
		if i == 4 then
			--4个玩家都退出了 直接结束游戏 踢人
			local room_limit = self.room_:get_room_limit()
			for i,v in ipairs(self.player_list_) do
				if v then
					log.info(string.format("chair_id [%d] is offline forced_exit~! guid is [%d]" , v.chair_id, v.guid))
					v:forced_exit()
				end
			end
			log.info("game init")
			self:clear_ready()
			return
		end
	end		
end

function bigtwo_table:finishgameError()
	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log.info(string.format("Player InOut Log,bigtwo_table:finishgameError player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),tostring(self.table_game_id)))
		end
	end

	log.info("============finishgameError")
	local notify = {
		pb_conclude = {},
	}
	for i=1,4 do
		c = {}
		c.score = 0
		c.cards = {}
		notify.pb_conclude[i] = c
	end
	self:broadcast2client("SC_BTConclude",notify)
	-- body 异常牌局
	self.gamelog.end_game_time = get_second_time()
	self.gamelog.onlinePlayer = {}
	for i,v in pairs(self.player_list_) do
		if v then -- 保存在线的玩家 并T出游戏
			table.insert(self.gamelog.onlinePlayer, i)
			v:forced_exit()
		end
	end

	local s_log = json.encode(self.gamelog)
	log.info(s_log)
	self:save_game_log(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	self:clear_ready()
end

function  bigtwo_table:runscore(chair_id)
	local lscore = 0
	for i,v in ipairs(self.player_list_) do
		if v and v.chair_id ~= chair_id then
			lscore = lscore + (self.bigtwo_player_cards[v.chair_id].score - self.bigtwo_player_cards[chair_id].score)
		end
	end
	return lscore
end
function  bigtwo_table:finishgame(player)
	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log.info(string.format("Player InOut Log,bigtwo_table:finishgame player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),tostring(self.table_game_id)))
		end
	end

	-- body	
	-- 游戏结束 进行结算
	self.gamelog.end_game_time = get_second_time()
	local notify = {
		pb_conclude = {},
	}
	local bomb_count = 0
	local offcharid = 0
	local offtimes = get_second_time()
	log.info(string.format("self.room_.tax_show_ [%d]",self.room_.tax_show_))

	--剩余牌数
	for i,v in ipairs(self.player_list_) do
		if v then
			local c = {}
			c.cards = self.bigtwo_player_cards[v.chair_id].cards_
			self.bigtwo_player_cards[v.chair_id]:get_score()
			print("XXXXXXXXXXXXXXXXXXXXXXXXXXX_AAAA", v.chair_id, self.bigtwo_player_cards[v.chair_id].score)
			c.score = 0
			notify.pb_conclude[v.chair_id] = c
			log.info("player:"..v.chair_id.." cards:"..#self.bigtwo_player_cards[v.chair_id].cards_)
			if v.offtime ~= nil then
				local offlinePlayers = {
					chair_id = v.chair_id,
					offtime = v.offtime,
				}
				table.insert(self.gamelog.offlinePlayers,offlinePlayers)
			end
			self.gamelog.playInfo[v.chair_id] = {
				chair_id = v.chair_id,
				guid = v.guid,
				old_money = v.pb_base_info.money,
				new_money = v.pb_base_info.money,
				tax = 0,
			}
			if v.offtime ~= nil then
				if v.offtime < offtimes then
					offcharid = v.chair_id
					offtimes = v.offtime
				end
			end
		else
			log.error(string.format("========player_list_ [%d] is nil or false",i))
		end
	end

	log.info(string.format("offline player chairid is [%d] offtime is [%d]",offcharid,offtimes))
	self.table_game_id = self:get_now_game_id()
	self.gamelog.table_game_id = self.table_game_id
	self:next_game()

	local molecular = 0			  --分子
	local denominator = 0         --分母
	local is_proportion = false   --按比例来
	local is_change_md = false
	local trigger = {}
	--查看是否需要按比例计算
	for i,v in ipairs(self.player_list_) do
		if v then
			trigger[v.chair_id] = false
			local tmp = self:runscore(v.chair_id) * self.cell_score_
			if math.abs(tmp) > v.pb_base_info.money then
				is_proportion = true
				trigger[v.chair_id] = true
				print("change score:", tmp, v.pb_base_info.money)
				if tmp > 0 then
					tmp = v.pb_base_info.money
				else				
					tmp = -v.pb_base_info.money
				end
			end
			if tmp > 0 then
				molecular = molecular + tmp
			else
				denominator = denominator + tmp
			end		
			notify.pb_conclude[v.chair_id].score = tmp
		end
	end
	if is_proportion then
		local temp = 0
		molecular = math.abs(molecular)
		denominator =  math.abs(denominator)
		if molecular > denominator then
			temp = molecular
			molecular = denominator
			denominator = temp
			is_change_md = true
		end
		log.info(string.format("molecular[%d]  denominator[%d]",molecular, denominator))
	else
		molecular = 1			  
		denominator = 1        
	end
	--计算结果
	local molecular_var = 0
	local denominator_var = 0

	for i,v in ipairs(self.player_list_) do
		if v then
    		if (is_change_md and notify.pb_conclude[v.chair_id].score > 0 ) or (is_change_md == false and notify.pb_conclude[v.chair_id].score < 0)then
    			log.info(string.format("-----------------score run A chair_id[%d]  score[%d]", v.chair_id, notify.pb_conclude[v.chair_id].score))
				notify.pb_conclude[v.chair_id].score = math.floor(notify.pb_conclude[v.chair_id].score * molecular / denominator)
    			log.info(string.format("-----------------score run B chair_id[%d]  score[%d]", v.chair_id, notify.pb_conclude[v.chair_id].score))
				denominator_var = denominator_var + notify.pb_conclude[v.chair_id].score
			else
				molecular_var = molecular_var + notify.pb_conclude[v.chair_id].score
    		end
		end
	end
	log.info(string.format("molecular_var:[%d]   denominator_var:[%d] ",molecular_var, denominator_var))
	--补差值
	if is_proportion and molecular_var ~= denominator_var then
		local temp = math.abs(math.abs(molecular_var) - math.abs(denominator_var))
		local big_m = 0
		local chair_id_m = nil
		if molecular_var > 0 then
			temp = -temp
		end
		for i,v in ipairs(self.player_list_) do
			if v then
    			if (is_change_md and notify.pb_conclude[v.chair_id].score < 0) or (is_change_md == false and notify.pb_conclude[v.chair_id].score > 0) then
    				if math.abs(notify.pb_conclude[v.chair_id].score) > big_m then
    					chair_id_m = v.chair_id
    					big_m = math.abs(notify.pb_conclude[v.chair_id].score)
    				end
    			end
			end
		end
		if chair_id_m ~= nil then
			log.info(string.format("supplement------------------A score[%d]  chair_id[%d] temp[%d]",notify.pb_conclude[chair_id_m].score, chair_id_m, temp ))
			notify.pb_conclude[chair_id_m].score = notify.pb_conclude[chair_id_m].score + temp
			log.info(string.format("supplement------------------A score[%d]", notify.pb_conclude[chair_id_m].score))
		end
	end



	--结算
	for i,v in ipairs(self.player_list_) do
		if v then
			local s_type = 2
			local s_old_money = v.pb_base_info.money
			local s_tax = 0
			log.info("======== chairid is "..v.chair_id)
			if self:isDroppedline(v) then
				log.info("this player is offline:"..v.chair_id)
			end

			notify.pb_conclude[v.chair_id].tax = 0
			if notify.pb_conclude[v.chair_id].score > 0 then
				table.insert(self.gamelog.win_chair, v.chair_id)
				--税收运算
				if self.tax_open_ == 1  then
					s_tax = notify.pb_conclude[v.chair_id].score * self.tax_
					if s_tax < 1 then
						s_tax = 0
					end
					s_tax = math.ceil(s_tax)
					notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
					notify.pb_conclude[v.chair_id].tax = s_tax
				end
				--判断跑马灯
				local bigtwo_player_stdard_award = notify.pb_conclude[v.chair_id].score
				if bigtwo_player_stdard_award >= BIGTWO_GRAND_PRICE_BASE and v.is_player ~= false then
					log.info(string.format("player guid[%d] nickname[%s]in bigtwo game earn money[%d] upto [%d],broadcast to all players.",v.guid,v.nickname,bigtwo_player_stdard_award,BIGTWO_GRAND_PRICE_BASE))
					bigtwo_player_stdard_award = bigtwo_player_stdard_award / 100
					broadcast_world_marquee(def_first_game_type,def_second_game_type,0,v.nickname,bigtwo_player_stdard_award)
				end
				--[[
				if  notify.pb_conclude[v.chair_id].score >= self.room_:get_broadcast_limit() then
					self.room_:broadcast2game(v.nickname, notify.pb_conclude[v.chair_id].score)
				end]]
				v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_BIGTWO)
				self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
			elseif notify.pb_conclude[v.chair_id].score < 0 then
				s_type = 1
				v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_BIGTWO, true)
			else
				s_type = 3
			end
			
			self.gamelog.playInfo[v.chair_id].tax = s_tax
			self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
			log.info(string.format("game finish playerid[%d] guid[%d] money [%d]",v.chair_id,v.guid,v.pb_base_info.money))
			self:player_money_log(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
		end
	end

	self.gamelog.cell_score = self.cell_score_
	self.gamelog.finishgameInfo = notify
	local s_log = json.encode(self.gamelog)
	log.info(s_log)
	self:save_game_log(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	-- end
	log.info("game end")
	for _,var in ipairs(notify.pb_conclude) do 
		log.info(string.format("score [%d] , cards[%s]",var.score,table.concat( var.cards, ", ")))
	end	

	self:broadcast2client("SC_BTConclude", notify)

	-- 踢人
	local room_limit = self.room_:get_room_limit()
	for i,v in ipairs(self.player_list_) do
		if v then
			if  self:isDroppedline(v) or (v.isTrusteeship and v.finishOutGame) then
				log.info(string.format("chair_id [%d] is offline forced_exit~! guid is [%d]" , v.chair_id, v.guid))
				if self:isDroppedline(v) or v.isTrusteeship then
					log.info("====================1")
					v.isTrusteeship = false
					v.finishOutGame = false
				end
				v:forced_exit()
				--if self:isDroppedline(v) then
				--		log.info("====================2")
				--	if not player.online then
				--		log.info("====================3")
				--	end
				--	if player.Dropped then
				--		log.info("====================4")
				--	end
				--	logout(v.guid)
				--end
			else
				v:check_forced_exit(room_limit)
			end
			v.ipControlTime = get_second_time()
		else
			log.info("v is nil:"..i)
		end
	end

--[[	local iRet = base_table.check_game_maintain(self)--检查游戏是否维护
	if iRet == true then
		print("Game bigtwo  card will maintain......")
	end--]]
	log.info("game init")
	self:clear_ready()	
	self:check_single_game_is_maintain()
end

function  bigtwo_table:isDroppedline(player)
	-- body
	if player then
		player.ipControlTime = get_second_time()
		if player.chair_id then
			log.info("bigtwo_table:isDroppedline:"..player.chair_id)
		end
		return not player.online or player.Dropped
	end
	return false
end

function bigtwo_table:clear_ready( ... )	
	-- body
	base_table.clear_ready(self)
	log.info("set BIGTWO_STATUS_FREE")
	self.status = BIGTWO_STATUS_FREE
	if def_second_game_type == 99 then
		self.time0_ = get_second_time() + 12
	else
		self.time0_ = get_second_time()
	end
	self.bigtwocards = nil
	self.last_cards = nil
	self.Already_Out_Cards = {}
	self.bomb = 0
	self.callsore_time = 0
	self.table_game_id = 0
	self.black_two = nil --黑桃二
	self.gamelog = {
        CallPoints = {},
        table_game_id = 0,
        start_game_time = 0,
        end_game_time = 0,
        win_chair = {},   --需要插入
        outcard_process = {}, 
        finishgameInfo = {},
        playInfo = {},
        offlinePlayers = {},
        cell_score = 0,
    }
end
-- 托管
function bigtwo_table:trusteeship(player)	
	-- body	
	-- log.info("trusteeship:"..player.chair_id)
	if self.last_out_cards and player.chair_id ~= self.first_turn then
		log.info("time out call pass")
		local out_card_list = self.bigtwo_player_cards[self.cur_turn]:get_out_card(self.last_out_cards.cards_type,self.last_out_cards.cards_color,self.last_out_cards.cards_val)		
		if out_card_list == nil then
			self:pass_card(player,true)
		else
			self:out_card(player, out_card_list, true)
		end
	else
		log.info("time out call out card", self.cur_turn)
		local playercards = self.bigtwo_player_cards[self.cur_turn]
		log.info(table.concat(self.bigtwo_player_cards[self.cur_turn].cards_, ','))
		log.info(table.concat(playercards.cards_, ','))
		self:out_card(player, {playercards.cards_[1]} , true)
	end
	--self.time0_ = get_second_time()
end

function bigtwo_table:can_enter(player)
	return true
end
-- 心跳
function bigtwo_table:tick()
	if self.status == BIGTWO_STATUS_FREE  and self.private_vote_status ~= true then
		if def_second_game_type == 99 then
			if get_second_time() - self.time0_ > 0 and self.private_isplay == true then
				print("start=====================================send")
				self:start(4)
				return
			else
				return
			end
		end
		if get_second_time() - self.time0_ > 2 then
			self.time0_ = get_second_time()
			local curtime = self.time0_
			local maintainFlg = 0
			for _,v in ipairs(self.player_list_) do
				if v then
					v.ipControlTime = v.ipControlTime or get_second_time()
					local t = v.ipControlTime
					--维护时将准备阶段正在匹配的玩家踢出
					--[[local iRet = base_table:on_notify_ready_player_maintain(v)--检查游戏是否维护
					if iRet == true then
						maintainFlg = 1
					end--]]
					if t then
						if curtime -  t >= BIGTWO_TIME_IP_CONTROL then
							v.ipControlTime = get_second_time()
							if self:isDroppedline(v) then
								--掉线了就T掉
								if self:isDroppedline(v) or v.isTrusteeship then
									log.info("====================1")
									v.isTrusteeship = false
									v.finishOutGame = false
								end
								v:forced_exit()
							else
								log.info(v.table_id)
								v.ipControlflag = true
								log.info("===============bigtwo_table tick")
								--[[]]
															
								if self:get_player_count() == 1 and self.ready_list_[v.chair_id] then
									self.room_.room_manager_:change_table(v)
									local tab = self.room_:find_table(v.table_id)
									tab:ready(v)
								end
							end
						end
					end
				end
			end
	--[[		if maintainFlg == 1 then
				print("############Game ready player bigtwo  card will maintain.")
			end	--]]
		end
	elseif self.status == BIGTWO_STATUS_PLAY  and self.private_vote_status ~= true then
		local curtime = get_second_time()
		if curtime == nil then
			log.info("curtime is nil")
		end
		if self.time0_ == nil then
			log.info("self.time0_ is nil")
		end
		if self.time_outcard_ == nil then
			log.info("self.time_outcard_ is nil")
		end
		if curtime - self.time0_ >= self.time_outcard_ then
			-- 超时
			log.info(string.format("time0[%d],time[%d],out[%d],cur_turn[%d]",self.time0_,curtime,self.time_outcard_,self.cur_turn))
			local player = self.player_list_[self.cur_turn]
			if player and player.chair_id then
				log.info("time out :" ..player.chair_id)
				if not player.TrusteeshipTimes then
					player.TrusteeshipTimes = 0
				end
				player.TrusteeshipTimes = player.TrusteeshipTimes + 1
				if player.TrusteeshipTimes >= 2 and not player.isTrusteeship then
					self:set_trusteeship(player,true)
				else
					self:trusteeship(player)
				end
			else
				-- 游戏出现异常 结束 游戏
				log.error(string.format("not find player gameTableid [%s]",self.table_game_id))
				self:finishgameError()
			end
		elseif curtime - self.gamelog.start_game_time > BIGTWO_TIME_OVER then
			self:finishgameError()	
			log.warning(string.format("BIGTWO_TIME_OVER gameTableid [%s]",self.table_game_id))	
		end
	elseif self.status == BIGTWO_STATUS_CALL  and self.private_vote_status ~= true then
		local curtime = get_second_time()
		if curtime - self.time0_ >= BIGTWO_TIME_CALL_SCORE then
			-- 超时
			local player = self.player_list_[self.cur_turn]
			if player then
				log.info("call_score time out call 0:".. player.chair_id)
				self:call_score(player, 0)
			else
				log.info(string.format("player is offline chairid [%d]",self.cur_turn))
			end
			self.time0_ = curtime
		end	
	elseif self.status == BIGTWO_STATUS_DOUBLE  and self.private_vote_status ~= true then
		local curtime = get_second_time()
		if curtime - self.time0_ >= BIGTWO_TIME_CALL_SCORE then
			-- 超时
			for i,v in ipairs(self.player_list_) do
				if v and v.is_double == nil then
					self:call_double(v,false)
				end
			end
		end
	elseif self.status == BIGTWO_STATUS_PLAYOFFLINE  and self.private_vote_status ~= true then
		local curtime = get_second_time()
		if curtime - self.time0_ >= BIGTWO_TIME_WAIT_OFFLINE then
		-- 游戏结束 进行结算
			log.info(string.format("BIGTWO_TIME_WAIT_OFFLINE time out time0[%d] curtime[%d]",self.time0_ ,curtime))
			if def_second_game_type==def_private then
				print("ztest----------privatefinishgame")
				self:privatefinishgame(player)
			else
				self:finishgame(player)
			end
		end
	end

end



---
-- @function: 获取table的字符串格式内容，递归
-- @tab： table
-- @ind：不用传此参数，递归用（前缀格式（空格））
-- @return: format string of the table
function bigtwo_table:dumpTab(tab,ind)
  if(tab==nil)then return "nil" end;
  local str="{";
  if(ind==nil)then ind="  "; end;
  --//each of table
  for k,v in pairs(tab) do
    --//key
    if(type(k)=="string")then
      k=tostring(k).." = ";
    else
      k="["..tostring(k).."] = ";
    end;--//end if
    --//value
    local s="";
    if(type(v)=="nil")then
      s="nil";
    elseif(type(v)=="boolean")then
      if(v) then s="true"; else s="false"; end;
    elseif(type(v)=="number")then
      s=v;
    elseif(type(v)=="string")then
      s="\""..v.."\"";
    elseif(type(v)=="table")then
      s=dumpTab(v,ind.."  ");
      s=string.sub(s,1,#s-1);
    elseif(type(v)=="function")then
      s="function : "..v;
    elseif(type(v)=="thread")then
      s="thread : "..tostring(v);
    elseif(type(v)=="userdata")then
      s="userdata : "..tostring(v);
    else
      s="nuknow : "..tostring(v);
    end;--//end if
    --//Contact
    str=str.."\n"..ind..k..s.." ,";
  end --//end for
  --//return the format string
  local sss=string.sub(str,1,#str-1);
  if(#ind>0)then ind=string.sub(ind,1,#ind-2) end;
  sss=sss.."\n"..ind.."}\n";
  return sss;--string.sub(str,1,#str-1).."\n"..ind.."}\n";
end;--//end function


--end