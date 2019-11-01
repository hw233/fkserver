-- 梭哈逻辑
local pb = require "pb_files"
local base_table = require "game.lobby.base_table"
local base_player= require "game.lobby.base_player"
local log = require "log"
local random = require "random"
local multi_showhand_cardmake = require("game/multi_showhand/multi_showhand_cardmake")

local FSM_E = {  --时间
	UPDATE          = 0,	--time update
	ADD_SCORE 		= 1,
	PASS 			= 2,
	GIVE_UP 		= 3,
	GIVE_UP_EIXT	= 4,
}
local FSM_S = {
	WAITING                 =-1,    --准备状态
    PER_BEGIN       		= 0,	--预开始
    XI_PAI		    		= 1,    --洗牌 
	GAME_ROUND				= 2,	--游戏回合	

	GAME_BALANCE			= 15,	--结算
	GAME_CLOSE				= 16,	--关闭游戏
	GAME_ERR				= 17,	--发生错误
	GAME_IDLE_HEAD			= 0x1000, --用于客户端播放动画延迟				
}
local Card_Type = {
	Card_Type_TongHu_Shun 	= 9,			--同花顺
	Card_Type_SiTiao		= 8,			--四条
	Card_Type_HuLu			= 7,			--葫芦 33322
	Card_Type_TongHu		= 6,			--同花
	Card_Type_Shun			= 5,			--顺子
	Card_Type_SanTiao		= 4,			--三条
	Card_Type_LiangDui		= 3,			--两对
	Card_Type_YiDui			= 2,			--一对
	Card_Type_Normal		= 1,			--散牌
}
local ACTION_TIME_OUT = 15
local LOG_MONEY_OPT_TYPE_SHOWHAND = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_SHOWHAND")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
-- 中奖公告全服标准，超过该标准广播中奖消息
local MULTI_SHOWHAND_PRICE_BASE = 30000
local A_is_7 = 0
local WAIT_TIME = 5
local MAX_CALL = 64    --单轮最大加注上限
local CELL_SCORE = 100 --底注
--黑名单玩家差牌概率
local  BLACK_RATE = 0

local function arrayClone(arraySrc)
	local arrayDes = {}
	for k,v in pairs(arraySrc) do
		arrayDes[k] = v
	end
	return arrayDes
end

-- 得到牌大小
local function get_point(card)
	return math.floor((card-1) / 4)
end
-- 得到牌花色
local function get_color(card)
	return (card-1) % 4
end
local function is_tonghua(c_list)
	local last_color = nil
	for k,v in pairs(c_list) do
		if not last_color then last_color = v.color end
		if last_color ~= v.color then return false end
	end
	return true
end
local function is_sun(c_list)
	local last_point = nil
	for k,v in pairs(c_list) do
		if last_point and (last_point - 1) ~= v.point then 
			return false
		end
		last_point = v.point
	end
	return true
end

--获取牌类型
local function get_card_type(cards)
	local c_list = {}
	local c_switch_list = {} -- A转换为7
	local c_point_list = {}
	local has_A = false
	local c_count = 0
	for k,v in pairs(cards) do
		local c = {
			point = get_point(v),
			color = get_color(v),
			val = v
		}
		table.insert(c_list,c)
		c_point_list[c.point] = c_point_list[c.point] or 0
		c_point_list[c.point] = c_point_list[c.point] + 1

		if v > 48 then
			v = v - (52 - 24)
			has_A = true
		end
		local c_switch = {
			point = get_point(v),
			color = get_color(v),
			val = v
		}
		table.insert(c_switch_list,c_switch)
		c_count = c_count + 1
	end

	-- 大牌在前
	table.sort(c_list,function (f,s) 
		return f.val > s.val
	end)
	table.sort(c_switch_list,function (f,s) 
		return f.val > s.val
	end)
	
	local c_is_shun = is_sun(c_list) 
	if A_is_7 == 1 then
		c_is_shun = c_is_shun or is_sun(c_switch_list)
	end

	local c_is_tonghua = is_tonghua(c_list)
	if c_count == 1 or c_count == 2 then
		c_is_shun = false
		c_is_tonghua = false
	end
	if c_count == 3 then
		c_is_shun = false
	end

	if c_is_shun and c_is_tonghua then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			value_tmp[#value_tmp + 1] = v.val
		end
		return {type = Card_Type.Card_Type_TongHu_Shun,value = value_tmp}
	end
	for k,v in pairs(c_point_list) do
		if v == 4 then
			return {type = Card_Type.Card_Type_SiTiao,value = {k}}
		end
	end
	local san_tong_point = nil
	local dui_zi_list = {}
	for k,v in pairs(c_point_list) do
		if v == 3 then
			san_tong_point = k
		elseif v == 2 then
			table.insert(dui_zi_list,k)
		end
	end
	if san_tong_point and #dui_zi_list > 0 then
		return {type = Card_Type.Card_Type_HuLu,value = {san_tong_point}}
	end
	if c_is_tonghua then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			table.insert(value_tmp,v.val)
		end
		return {type = Card_Type.Card_Type_TongHu,value = value_tmp}
	end
	if c_is_shun then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			table.insert(value_tmp,v.val)
		end
		return {type = Card_Type.Card_Type_Shun,value = value_tmp}
	end
	if san_tong_point then
		return {type = Card_Type.Card_Type_SanTiao,value = {san_tong_point}}
	end
	if #dui_zi_list > 1 then
		local danpai = 0
		local value_tmp = {}
		for k,v in pairs(c_list) do
			if v.point == dui_zi_list[1] or v.point == dui_zi_list[2] then
				table.insert(value_tmp,v.val)
			else
				danpai = v.val
			end
		end
		table.sort(value_tmp,function (f,s) 
			return f > s
		end)
		if danpai ~= 0 then value_tmp[#value_tmp + 1] = danpai end
		return {type = Card_Type.Card_Type_LiangDui,value = value_tmp}
	end
	if #dui_zi_list == 1 then
		local danpai_list = {}
		local value_tmp = {}
		for k,v in pairs(c_list) do
			if v.point == dui_zi_list[1] then
				table.insert(value_tmp,v.val)
			else
				table.insert(danpai_list,v.val)
			end
		end
		table.sort(danpai_list,function (f,s) 
			return f > s
		end)
		for k,v in pairs(danpai_list) do
			table.insert(value_tmp,v)
		end

		return {type = Card_Type.Card_Type_YiDui,value = value_tmp}
	end
	local value_tmp = {}
	for k,v in pairs(c_list) do
		table.insert(value_tmp,v.val)
	end
	return {type = Card_Type.Card_Type_Normal,value = value_tmp}
end




--获取牌类型-new
--在游戏回合时牌大发话时，同花和顺子算散牌
local function get_card_type_new(cards)
	local c_list = {}
	local c_switch_list = {} -- A转换为7
	local c_point_list = {}
	local has_A = false
	local c_count = 0
	for k,v in pairs(cards) do
		local c = {
			point = get_point(v),
			color = get_color(v),
			val = v
		}
		table.insert(c_list,c)
		c_point_list[c.point] = c_point_list[c.point] or 0
		c_point_list[c.point] = c_point_list[c.point] + 1

		if v > 48 then
			v = v - (52 - 24)
			has_A = true
		end
		local c_switch = {
			point = get_point(v),
			color = get_color(v),
			val = v
		}
		table.insert(c_switch_list,c_switch)
		c_count = c_count + 1
	end

	-- 大牌在前
	table.sort(c_list,function (f,s) 
		return f.val > s.val
	end)
	table.sort(c_switch_list,function (f,s) 
		return f.val > s.val
	end)
	
	local c_is_shun = is_sun(c_list) 
	if A_is_7 == 1 then
		c_is_shun = c_is_shun or is_sun(c_switch_list)
	end

	local c_is_tonghua = is_tonghua(c_list)
	if c_count == 1 or c_count == 2 then
		c_is_shun = false
		c_is_tonghua = false
	end
	if c_count == 3 then
		c_is_shun = false
	end

	if c_is_shun and c_is_tonghua then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			value_tmp[#value_tmp + 1] = v.val
		end
		return {type = Card_Type.Card_Type_Normal,value = value_tmp}
	end
	for k,v in pairs(c_point_list) do
		if v == 4 then
			return {type = Card_Type.Card_Type_SiTiao,value = {k}}
		end
	end
	local san_tong_point = nil
	local dui_zi_list = {}
	for k,v in pairs(c_point_list) do
		if v == 3 then
			san_tong_point = k
		elseif v == 2 then
			table.insert(dui_zi_list,k)
		end
	end
	if san_tong_point and #dui_zi_list > 0 then
		return {type = Card_Type.Card_Type_HuLu,value = {san_tong_point}}
	end
	if c_is_tonghua then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			table.insert(value_tmp,v.val)
		end
		return {type = Card_Type.Card_Type_Normal,value = value_tmp}
	end
	if c_is_shun then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			table.insert(value_tmp,v.val)
		end
		return {type = Card_Type.Card_Type_Normal,value = value_tmp}
	end
	if san_tong_point then
		return {type = Card_Type.Card_Type_SanTiao,value = {san_tong_point}}
	end
	if #dui_zi_list > 1 then
		local danpai = 0
		local value_tmp = {}
		for k,v in pairs(c_list) do
			if v.point == dui_zi_list[1] or v.point == dui_zi_list[2] then
				table.insert(value_tmp,v.val)
			else
				danpai = v.val
			end
		end
		table.sort(value_tmp,function (f,s) 
			return f > s
		end)
		if danpai ~= 0 then value_tmp[#value_tmp + 1] = danpai end
		return {type = Card_Type.Card_Type_LiangDui,value = value_tmp}
	end
	if #dui_zi_list == 1 then
		local danpai_list = {}
		local value_tmp = {}
		for k,v in pairs(c_list) do
			if v.point == dui_zi_list[1] then
				table.insert(value_tmp,v.val)
			else
				table.insert(danpai_list,v.val)
			end
		end
		table.sort(danpai_list,function (f,s) 
			return f > s
		end)
		for k,v in pairs(danpai_list) do
			table.insert(value_tmp,v)
		end

		return {type = Card_Type.Card_Type_YiDui,value = value_tmp}
	end
	local value_tmp = {}
	for k,v in pairs(c_list) do
		table.insert(value_tmp,v.val)
	end
	return {type = Card_Type.Card_Type_Normal,value = value_tmp}
end


--返回给客户端的牌型
local function get_card_type_client(cards)
	local card_count_err = {type=0,value={}} --张数不对

	if #cards < 5 then
		return card_count_err
	end

	for i,v in ipairs(cards) do
		--暗牌
		if v == 255 then
			return card_count_err
		end
	end

	return get_card_type(cards)
end

--比牌 flag = false表示在发牌阶段比牌只比明牌
--flag = true 表示在最后结算比牌
local function compare_cards(cardsL,cardsR,round,flag)
	local cardsL_tmp = {}
	local cardsR_tmp = {}
	local card_TypeL = {}
	local card_TypeR = {}
	--if round < 4 then
	if flag == false then
		for i=2,round+1 do
			table.insert(cardsL_tmp,cardsL[i])
			table.insert(cardsR_tmp,cardsR[i])
		end
	else
		cardsL_tmp = arrayClone(cardsL)
		cardsR_tmp = arrayClone(cardsR)
	end
	if flag == false then
		card_TypeL = get_card_type_new(cardsL_tmp)
		card_TypeR = get_card_type_new(cardsR_tmp)
	else
		card_TypeL = get_card_type(cardsL_tmp)
		card_TypeR = get_card_type(cardsR_tmp)
	end
	
	if card_TypeL.type ~= card_TypeR.type then
		return card_TypeL.type > card_TypeR.type
	end
	local valueL = card_TypeL.value
	local valueR = card_TypeR.value
	if card_TypeL.type == Card_Type.Card_Type_TongHu_Shun then
		if valueL[2] then
			local pointL01 = get_point(valueL[1])
			local pointL02 = get_point(valueL[2])
			local pointR01 = get_point(valueR[1])
			local pointR02 = get_point(valueR[2])
			if pointL01 ~= pointR01 then
				return pointL01 > pointR01
			elseif pointL02 ~= pointR02 then
				return pointL02 > pointR02
			else
				return valueL[1] > valueR[1]
			end
		else
			return valueL[1] > valueR[1]
		end
	end
	
	if card_TypeL.type == Card_Type.Card_Type_SiTiao or 
	   card_TypeL.type == Card_Type.Card_Type_HuLu or 
	   card_TypeL.type == Card_Type.Card_Type_SanTiao 
	then
		return valueL[1] > valueR[1] 
	end
	if card_TypeL.type == Card_Type.Card_Type_TongHu then
		for k,v in pairs(valueL) do
			if get_point(v) ~= get_point(valueR[k]) then
				return get_point(v) > get_point(valueR[k])
			end
		end
		return valueL[1] > valueR[1]
	end
	if card_TypeL.type == Card_Type.Card_Type_Shun then
		for k,v in pairs(valueL) do
			if get_point(v) ~= get_point(valueR[k]) then
				return get_point(v) > get_point(valueR[k])
			end
		end
		return valueL[1] > valueR[1]
	end
	if card_TypeL.type == Card_Type.Card_Type_LiangDui or
	   card_TypeL.type == Card_Type.Card_Type_YiDui or 
	   card_TypeL.type == Card_Type.Card_Type_Normal then
		for k,v in pairs(valueL) do
			if get_point(v) ~= get_point(valueR[k]) then
				return get_point(v) >get_point(valueR[k])
			end
		end
		return valueL[1] > valueR[1]
	end
end

function send2client_pb_sh(player,op_name,msg)
    send2client_pb(player,op_name,msg)
    if msg then
        print("send2client_pb : " .. op_name)
    end
end


multi_showhand_table = base_table:new()
function multi_showhand_table:broadcast2client_sh(op_name,msg)
    self:broadcast2client(op_name,msg)
    if msg then
        print("broadcast2client : " .. op_name)
    end
end

local total_make_count = 0
local total_make_success_count = 0
local total_card_count = {}

function multi_showhand_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self:reset()
	self.player_count = 0
	self.cards = {}
	for i = 25, 52 do
		self.cards[#self.cards + 1] = i
	end
	multi_showhand_cardmake.init_cards(self.cards)
	self.game_max_bet = self.room_.cell_score * 257 --默认该局梭哈上限为底注的256倍(底注×256倍)
	print("game_max_bet---------->",self.game_max_bet)
end


function multi_showhand_table:test()
	-- body
	local make_count = 0
	local make_success_count = 0
	local card_count = {}
	for i=1,9 do
		card_count[i] = 0
	end

	local player_count = 2

	for i=1,10000 do
		local is_make_card = multi_showhand_cardmake.need_make_card()

		if is_make_card then

			make_count = make_count + 1

			local make_success,cards_by_make = multi_showhand_cardmake.make_cards(2)
			if make_success then
				make_success_count = make_success_count + 1

				local cardsL_tmp = {}
				local cardsR_tmp = {}

				local cards = {cardsL_tmp,cardsR_tmp}

				local card_index = 1
				for i=1,player_count do
					for j=1,5 do
						cards[i][j] = cards_by_make[card_index]
						card_index = card_index+1
					end	
				end

				local card_TypeL = get_card_type(cardsL_tmp)
				local card_TypeR = get_card_type(cardsR_tmp)

				card_count[card_TypeL.type] = card_count[card_TypeL.type] + 1
				card_count[card_TypeR.type] = card_count[card_TypeR.type] + 1
			end
		end
		
	end

	print("make count------------------------>",make_count)
	print("make success count---------------->",make_success_count)
	local card_name = {"sanpai","yidui","liangdui","santiao","shunzi","tonghua","hulu","sitiao","tonghuashun"}
	for i=1,9 do
		print(card_name[i],card_count[i])

		total_card_count[i] = total_card_count[i] + card_count[i]
	end

	total_make_count = total_make_count + make_count
	total_make_success_count = total_make_success_count + make_success_count
	
end

function  multi_showhand_table:check_maintain()
	-- body
	local next_state = self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD
	if self.cur_state_FSM == FSM_S.WAITING or self.cur_state_FSM == FSM_S.PER_BEGIN or next_state == FSM_S.XI_PAI then --准备时间
		if self:check_single_game_is_maintain() == true or game_switch == 1 then
			log.info("Game will maintain..game_switch=[%d] self.room_.game_switch_is_open[%d].....................",game_switch,self.room_.game_switch_is_open)
			for i, p in pairs(self.players) do	
				if p and p.vip ~= 100 then
					p:forced_exit()
				end
			end
		end
	end
end

--载入配置
function multi_showhand_table:load_lua_cfg()
	log.info("multi_showhand_table: game_maintain_is_open = [%s] game_switch[%d]",self.room_.game_switch_is_open,game_switch)
	self:check_maintain()
	local funtemp = load(self.room_.room_cfg)
	local multi_showhand_config ,card_rate = funtemp()
	if multi_showhand_config then
		if multi_showhand_config.max_call ~= nil then
			MAX_CALL = multi_showhand_config.max_call --加注最高限制为max_call倍底注
		end
		
		if multi_showhand_config.A_is_7 ~= nil then
			A_is_7   = multi_showhand_config.A_is_7 --A是否可以当作7组合顺子
		end
		
		if multi_showhand_config.multi_showhand_price_base ~= nil then
			MULTI_SHOWHAND_PRICE_BASE = multi_showhand_config.multi_showhand_price_base
		end

		if multi_showhand_config.black_rate ~= nil then
			BLACK_RATE = multi_showhand_config.black_rate
		end
		log.info("max_call = [%d] A_is_7 = [%d] MULTI_SHOWHAND_PRICE_BASE = [%d] CELL_SCORE[%d] black_rate = [%d].",MAX_CALL,A_is_7,MULTI_SHOWHAND_PRICE_BASE,CELL_SCORE,BLACK_RATE)
	end

	if card_rate ~= nil then
		multi_showhand_cardmake.set_card_rate(card_rate)--设置做牌概率
	end
	
	
	--test--
--[[
	if self.max_call == 64 then
		local player = base_player:new()
		player:init(10000, "android", "android")
		player.session_id = 10000 + 1
		player.is_android = true
		player.chair_id = 1
		player.guid = 1
		player.room_id = 1
		player.table_id = 1
		player.pb_base_info = {money = 9999999,}
		self.players[1] = player
		self:ready(player)
	end
]]
	--test--
end


--玩家进入
function multi_showhand_table:can_enter(player)
	local next_state = self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD
	log.info("player guid[%d] can_enter next_state[%d] cur_state_FSM[%d]",player.guid,next_state,self.cur_state_FSM)
	if self.table_busy == 1 and next_state == FSM_S.XI_PAI and self.last_action_change_time_stamp <= get_second_time() + 1 then
		log.warning("Game jast begin can not enter, player guid[%d] can not enter.",player.guid)
		return false
	end

	if player.vip == 100 and self:getNum(self.players) < 5 then
		return true
	end
	
	if self:getNum(self.players) >= 5 then
		log.info("player[%d] can_enter room[%d] table[%d] false",player.guid, self.room_.id,self.table_id_)
		return false
	end
	-- body
	for _,v in ipairs(self.players) do		
		if v then
			print("===========judge_play_times")
			if player:judge_ip(v) then
				if not player.ipControlflag then
					print("multi_showhand_table:can_enter ipcontorl change false:",player.guid)
					return false
				else
					-- 执行一次后 重置
					print("multi_showhand_table:can_enter ipcontorl change true:",player.guid)
					return true
				end
			end
		end
	end
	print("multi_showhand_table:can_enter true")
	return true
end

function  multi_showhand_table:check_player_number()
	-- body
	local next_state = self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD
	if self.cur_state_FSM == FSM_S.WAITING or self.cur_state_FSM == FSM_S.PER_BEGIN or next_state == FSM_S.XI_PAI then
		if self:getNum(self.players) < 3 then
			self:reset()
		end
	end
end


-- 检查是否可取消准备
function multi_showhand_table:check_cancel_ready(player, is_offline)
	--return ture
	--if not player.is_dead or not player.cur_status then
	if player.cur_status == 0  then --观众
		log.info("player guid[%d] check cancel ready true,cur_status[%s]", player.guid,tostring(player.cur_status))
		self:check_player_number()
		return true
	end
	local next_state = self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD
	if self.cur_state_FSM == FSM_S.WAITING or self.cur_state_FSM == FSM_S.PER_BEGIN or player.is_dead == true or player.cur_status == 0 or next_state == FSM_S.XI_PAI then --准备时间
		log.info(string.format("player guid[%d] check cancel ready is true. game_cur_status[%d] is_dead[%s] player_cur_status[%s] next_state[%d] ",
				player.guid,self.cur_state_FSM,tostring(player.is_dead),tostring(player.cur_status),next_state))
		self:check_player_number()
		return true
	end
	return not self:is_play(player, is_offline)
end
function multi_showhand_table:is_play( player )
	if not player then 
		return false
	end
	if self.do_logic_update then
		if player.is_dead == true or player.cur_status == 0 then
			log.info("player guid[%d] is_dead[%s] cur_status[%d] can exit",player.guid, tostring(player.is_dead),player.cur_status)
			return false
		end
		local next_state = self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD
		log.info("player guid[%d] game_cur_status[%d] next_state[%d]",player.guid, self.cur_state_FSM,next_state)
		if self.cur_state_FSM == FSM_S.XI_PAI or self.cur_state_FSM == FSM_S.GAME_ROUND or self.cur_state_FSM == FSM_S.GAME_BALANCE or next_state == FSM_S.GAME_ROUND or next_state == FSM_S.GAME_BALANCE then
			if not player.is_dead and not player.cur_status then
				log.info("player guid[%d] can exit, is_dead[%s] cur_status[%s]",player.guid, tostring(player.is_dead),tostring(player.cur_status))
				return false
			else
				log.info("player guid[%d] is play true, cur_state = [%d],next_state[%d],can not exit.",player.guid,self.cur_state_FSM,next_state)
				return true
			end
		else
			self:check_player_number()
			return false
		end	
	end
	log.info("player guid[%d] is not play, cur_state = [%d] can exit",player.guid, self.cur_state_FSM)
	self:check_player_number()
	return false
end

-- 玩家站起
function multi_showhand_table:player_stand_up(player, is_offline)
	self.player_count = self:getNum(self.players)
	log.info("player guid[%d] stand up player_count[%d] player_list num[%d]",player.guid,self.player_count,self:getNum(self.players))
		
	
	
	--扣除未扣的钱
	self:cost_player_money_real(player)
	if player and  player.cur_status == 2  and player.is_dead == true then --中途玩家弃牌退出,保存下注金币信息
		local player_info = {
			guid = player.guid,
			chair_id = player.chair_id,
			tiles = self:get_cur_round_cards(player,false),
			is_win = false,
			is_give_up = true,
			card_type =  get_card_type_client(self:get_cur_round_cards(player,false)).type,
			nick = player.ip_area,
			icon = player:get_header_icon(),
			gold = self:get_player_money(player),
			win_money = -player.add_total,
			taxes = 0,
		}

		-- 下注流水
		self:player_bet_flow_log(player,player.add_total)

		self.giveup_player_info[player.guid] = player_info
		if self.money_log_flag[player.guid] == nil then
			self:player_money_log(player,1,player.old_money,0,-player.add_total,self.game_log.table_game_id)
			self.money_log_flag[player.guid] = 1
		end
		
		self.game_log.players[player.chair_id].increment_money = -player.add_total
		log.info("player guid[%d] give up and exit giveup_player_add_info[%d] = [%d] player.add_total = [%d]", player.guid, player.guid,self.giveup_player_info[player.guid].win_money,player.add_total)
		player.cur_status = 0 --准备中(0观众，1准备中，2游戏中)
	end

	
	local next_state = self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD
	log.info("player guid[%d] stand up ,player_cur_status[%s] player.is_dead[%s] game_cur_status[%d] next_state[%d]",player.guid, tostring(player.cur_status),tostring(player.is_dead),self.cur_state_FSM,next_state)
	if not player.cur_status and not player.is_dead then
		log.info("player guid[%d] except...................",player.guid)
	end

	--if self.cur_state_FSM == FSM_S.WAITING or self.cur_state_FSM == FSM_S.PER_BEGIN or next_state == FSM_S.XI_PAI then
	--	if self.player_count < 3 then
	--		self:reset()
	--	end
	--end

	local success = base_table.player_stand_up(self,player,is_offline) 
	if success == true then
		player.cur_status = 0 --准备中(0观众，1准备中，2游戏中)
	end
	return success
end

--替换玩家cost_money方法，先缓存，稍后一起扣钱
function multi_showhand_table:cost_player_money(player,money_cost)

	local money = self:get_player_money(player)

	if money_cost <= 0 or money < money_cost then
		log.error(string.format("player guid[%d] money_cost[%d] money[%d]",player.guid,money_cost,money))		
		return false
	end

	-- body
	if self.moeny_cost_info == nil then
		self.moeny_cost_info = {}
	end

	if self.moeny_cost_info[player.guid] == nil then
		self.moeny_cost_info[player.guid] = 0
	end
	
	self.moeny_cost_info[player.guid]  = self.moeny_cost_info[player.guid] + money_cost

	--notify money
	local new_money = self:get_player_money(player)
	player:notify_money(LOG_MONEY_OPT_TYPE_SHOWHAND,new_money,-money_cost)
	log.info("player guid[%d] money_cost[%d] new_money[%d]",player.guid,money_cost,new_money)
	return true
end

--真实扣除所有玩家待扣除的钱
function multi_showhand_table:cost_money_real()
	-- body
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 then
			self:cost_player_money_real(v)
		end
	end
end

function multi_showhand_table:cost_player_money_real(player)
	-- body
	local cost =  self:get_player_money_cost(player)
	if cost > 0 then
		log.info("player guid[%d] must cost money[%d]",player.guid,cost)
		player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cost}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
		self:save_player_collapse_log(player)
		self:set_player_money_cost(player,0)
	end
end

--获取玩家待扣除的钱
function multi_showhand_table:get_player_money_cost(player)
	-- body
	if self.moeny_cost_info ~= nil and self.moeny_cost_info[player.guid] ~= nil  then
		return self.moeny_cost_info[player.guid]
	end
	return 0
end

function multi_showhand_table:set_player_money_cost(player,cost)
	-- body
	if self.moeny_cost_info ~= nil and self.moeny_cost_info[player.guid] ~= nil  then
		self.moeny_cost_info[player.guid] = cost
	end
end

--替换玩家get_money方法
function multi_showhand_table:get_player_money(player)
	-- body
	return player:get_money() - self:get_player_money_cost(player)
end

--广播下一轮
function multi_showhand_table:broadcast_next_turn(left_time)
	if self.players[self.cur_turn] ~= nil and self.players[self.cur_turn].cur_status ~= 2 then
		log.error("guid[%d] broadcast_next_turn error.",self.players[self.cur_turn].guid)
		return
	end
	local player = self.players[self.cur_turn]
	if player == nil then
		log.error("player nil error.")
		return
	end

	local all_is_same = true
	local tmp_last = -1
	local cur_round_add_max = false --已经有人加到最大注
	local can_add_money = true --判断自己和对方的金钱是否可以加注
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 and not v.is_dead then
			if tmp_last == -1 then tmp_last = v.cur_round_add end
			if tmp_last ~= v.cur_round_add then all_is_same = false end
			if v.cur_round_add >= self.max_call*CELL_SCORE then cur_round_add_max = true end
			
			if v.guid ~= player.guid then
				--玩家自己的钱不够不能加注
				if (self:get_player_money(player)+player.cur_round_add) <= v.cur_round_add  or v.cur_round_add == self.single_round_max_bet then
					can_add_money = false
				end
			end
			
		end
	end
	local type = 0
	if not self.is_allin_state and not cur_round_add_max  and  can_add_money == true then
		type = type + 1 --加注
	end
	if self.cur_game_round > 1 then
		type = type + 2 --allin
	end
	if not all_is_same then
		type = type + 4 --跟注
	else 
		type = type + 8 --让牌
	end
	type = type + 16 --弃牌

	log.info(string.format("game_id[%s] cur_game_round[%d] next player guid[%d] cur_money[%d] cur_round_add[%d] add_total[%d] default single_round_max_bet[%d]",
		self.table_game_id,self.cur_game_round,player.guid,self:get_player_money(player),player.cur_round_add,player.add_total,self.single_round_max_bet))
	--计算下一个玩家当轮最大可下注金币数
	local cur_round_max_add	 = self.single_round_max_bet - player.cur_round_add  --下一个玩家当轮最大下注
	log.info("game_id[%s] cur_game_round[%d] next player guid[%d] cur_round_max_add[%d] cur_round_add[%d]",self.table_game_id,self.cur_game_round,player.guid, cur_round_max_add,player.cur_round_add)

	--计算下一个玩家最大可梭哈金币数
	local can_showhand_money = self.game_max_bet - player.cur_round_add
	log.info("game_id[%s] next player guid[%d] add_total[%d] cur_round_add[%d]  cur_money[%d] default showhand_money[%d] self.game_max_bet[%d]",self.table_game_id,player.guid,player.add_total,player.cur_round_add,self:get_player_money(player),can_showhand_money,self.game_max_bet)

	log.info("game_id[%s] next_player[%d] cur_round_max_add[%d], showhand_money[%d],cur_money[%d] add_total[%d]",self.table_game_id,player.guid,cur_round_max_add,can_showhand_money,self:get_player_money(player),player.add_total)

	self:broadcast2client_sh("SC_Multi_ShowHand_NextTurn",{chair_id = self.cur_turn,type = type,max_add = cur_round_max_add,act_left_time = left_time,showhand_money = can_showhand_money })
end

--下一轮
function multi_showhand_table:next_turn()
	local old = self.cur_turn
	repeat
		self.cur_turn = self.cur_turn + 1
		if self.cur_turn > #self.ready_list_ then
			self.cur_turn = 1
		end
		if old == self.cur_turn then
			log.error("turn error")
			return
		end
	until(self.players[self.cur_turn] and self.players[self.cur_turn].cur_status == 2 and (not self.players[self.cur_turn].is_dead))
	self:broadcast_next_turn(ACTION_TIME_OUT)
end

function  multi_showhand_table:reset()
	-- body
	--self.player_count = 0
	self.last_action_change_time_stamp = os.time()
	self.cur_state_FSM = FSM_S.WAITING
	self.do_logic_update = false
	self.table_busy = 0
	self.pass_action = {}
	self.giveup_player_info = {} --存储中途退出弃牌玩家下注信息
	self.single_round_max_bet = 0 --每轮最高下注
	self.max_call = MAX_CALL
	self.giveup_player_cards = {}
	self.money_log_flag = {}
	self.game_except_flag = 0 --游戏异常标志,1异常时该局结束后踢出所有玩家
	CELL_SCORE = self.room_.cell_score
	for _,v in pairs(self.players) do
		if v then
			v.cur_status = 0 --观众(0观众，1准备中，2游戏中)
			v.is_dead = false
			v.declare_this_round = false
			v.need_eixt = false
			v.cards = {}
			v.add_total = 0
			v.cur_round_add = 0
			v.last_round_add = 0
			--v.old_money = v:get_money()
			v.old_money = self:get_player_money(v)
		end
	end
end

-- 开始游戏
function multi_showhand_table:start(player_count,is_test)
	self.timer = {}
	self.cur_state_FSM   = FSM_S.PER_BEGIN
	self.last_action_change_time_stamp = os.time() --上次状态 更新的 时间戳
	self.is_allin_state = false
	self.allin_money = 0
	self.cur_game_round = 0
	self.money_log_flag = {}
	self:update_state(FSM_S.PER_BEGIN)
	self.is_test = is_test

end

-- 心跳
function multi_showhand_table:tick()
	-- test --
    self.old_player_count = self.old_player_count or 1 
	local tmp_player_count = self:get_player_count()
	if self.old_player_count ~= tmp_player_count then
		if tmp_player_count ~= 0 then 
			-- print("player count", tmp_player_count) 
		end
        self.old_player_count = tmp_player_count
	end
    -- test --
	if self.player_count > 1 and self.player_count < 6 and self.table_busy == 0 and self.cur_state_FSM == FSM_S.PER_BEGIN then --准备状态
		
		self.table_busy = 1
		self.last_action_change_time_stamp = os.time() + WAIT_TIME
		local msg = {
			s_start_time = self.last_action_change_time_stamp - os.time() - 1
		}
		self:broadcast2client_sh("SC_MultiStartCountdown",msg)
		self.do_logic_update = true
		return
	end
	
	if self.do_logic_update then
		self:safe_event({type = FSM_E.UPDATE})
		--[[if self.cur_state_FSM == FSM_S.GAME_ROUND then
			local cur_turn_player = self.players[self.cur_turn]
			self.android_try_time = self.android_try_time or os.time()
			if cur_turn_player.is_android and (os.time() - self.android_try_time > 1)then
				self.android_try_time = os.time()
				local act = random.boost(1,100)
				--if self.cur_game_round > 1 then act = 55 end
				if act < 50 then 
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.ADD_SCORE,
					target = cur_turn_player.add_total + CELL_SCORE * random.boost(1,20) }) 
				elseif act < 60 then 
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.ADD_SCORE,
					target = -1 })
				elseif act < 70 then 
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.ADD_SCORE,
					target = -2 }) 
				elseif act < 73 then 
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.GIVE_UP}) 
				else
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.PASS})
				end
			end
		end--]]
        local dead_list = {}
        for k,v in pairs(self.timer) do
            if os.time() > v.dead_line then
                v.execute()
                dead_list[#dead_list + 1] = k
            end
        end
        for k,v in pairs(dead_list) do
            self.timer[v] = nil
        end
    else
    	--do nothing
	end
end
function multi_showhand_table:safe_event(...)
    -- test --
    self:FSM_event(...)
   --[[
    local ok = xpcall(multi_showhand.FSM_event,function() print(debug.traceback()) end,self,...)
    if not ok then
        print("safe_event error") 
        self:update_state(FSM_S.GAME_ERR)
    end
    ]]
end
function multi_showhand_table:send_left_cards()
	repeat 
		self.cur_game_round = self.cur_game_round + 1
		self:GetSingleRoundMaxBet()
		self:GetCurRoundShowhandMax()
		for k,player in pairs(self.players) do
			--if player and player.cur_status == 2 then
			if player then
				local msg = {
					pb_players = {},
					current_round = self.cur_game_round
				}

				for k1,v in pairs(self.players) do
					if v and v.cur_status == 2 and not v.is_dead then
						local tplayer = {}
						tplayer.chair_id = v.chair_id
						tplayer.tiles = self:get_cur_round_cards(v,v.chair_id == player.chair_id)
						tplayer.add_total = v.add_total
						tplayer.cur_round_add = v.cur_round_add
						if v.is_android then
							tplayer.nick = "robot"
							tplayer.icon = 1
							tplayer.gold = 999999
						else
							tplayer.nick = v.ip_area
							tplayer.icon = v:get_header_icon()
							--tplayer.gold = v:get_money()
							tplayer.gold = self:get_player_money(v)
						end
						table.insert(msg.pb_players,tplayer)
					end
				end
				
				send2client_pb_sh(player,"SC_Multi_ShowHand_Next_Round",msg)
			end
		end
	until (self.cur_game_round >= 4)
end

--更新状态
function multi_showhand_table:update_state(new_state)
	print("update_state: new_state:",new_state)
	if new_state == FSM_S.XI_PAI  then
	   	for i, p in pairs(self.players) do	
			if p and self.ready_list_[p.chair_id] ~= true then
				log.info("player guid[%d] is not ready--------------------------->kick it,cur_state[XI_PAI].",p.guid)
				p:forced_exit()
			end
		end
	end
    self.cur_state_FSM = new_state
    self.last_action_change_time_stamp = os.time()
    self:broad_cast_desk_state()
	if new_state == FSM_S.GAME_ROUND then
		self.cur_game_round = self.cur_game_round + 1
		self:GetSingleRoundMaxBet()
		self:GetCurRoundShowhandMax()
		table.insert(self.game_log.action_table,{act = "GAME_ROUND",round = self.cur_game_round})
		local big_player = nil
		for k,v in pairs(self.players) do
			if v and v.cur_status == 2 and not v.is_dead then
				if not big_player or compare_cards(v.cards,big_player.cards,self.cur_game_round, false) then
					big_player = v
				end
				v.last_round_add = v.cur_round_add
				v.cur_round_add = 0
				v.declare_this_round = false
			end
		end
		self.cur_turn = big_player.chair_id
		
		for k,player in pairs(self.players) do
			--if player and player.cur_status == 2 then
			if player then
				local msg = {
					pb_players = {},
					current_round = self.cur_game_round
				}
				for k1,v in pairs(self.players) do
					if v and v.cur_status == 2 and not v.is_dead then
						local tplayer = {}
						tplayer.chair_id = v.chair_id
						print("v.chair_id, player.chair_id",v.chair_id,player.chair_id)
						tplayer.tiles = self:get_cur_round_cards(v,v.chair_id == player.chair_id)
						tplayer.add_total = v.add_total
						tplayer.cur_round_add = v.cur_round_add
						if v.is_android then
							tplayer.nick = "robot"
							tplayer.icon = 1
							tplayer.gold = 999999
						else
							tplayer.nick = v.ip_area
							tplayer.icon = v:get_header_icon()
							--tplayer.gold = v:get_money()
							tplayer.gold = self:get_player_money(v)
						end
						table.insert(msg.pb_players,tplayer)
					end
				end
				send2client_pb_sh(player,"SC_Multi_ShowHand_Next_Round",msg)
			end
			
			
		end
		self:broadcast_next_turn(ACTION_TIME_OUT)
		self:reset_action_time()
	elseif new_state == FSM_S.GAME_BALANCE then
		if self:live_count() > 1 then 
			self:send_left_cards()
		end
		table.insert(self.game_log.action_table,{act = "GAME_BALANCE"})
	else
		log.info("this state[%d] is not work",new_state)
	end
end

function multi_showhand_table:update_state_delay(new_state,delay_seconds)
	print("new_state delay_seconds----------->",new_state,delay_seconds)
    self.cur_state_FSM = new_state + FSM_S.GAME_IDLE_HEAD

    local act = {}
    act.dead_line = os.time() + delay_seconds
    act.execute = function()
        self:update_state(self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD)
    end
    self.timer[#self.timer + 1] = act
	
end

--玩家超时
function multi_showhand_table:is_action_time_out()
    --return false
	local tmp_act_time = ACTION_TIME_OUT
	if self.cur_state_FSM == FSM_S.GAME_ROUND then
		--客户端动画播放时间
		if self.cur_game_round == 1 then tmp_act_time = tmp_act_time + 2 end
		if self.cur_game_round > 1 then tmp_act_time = tmp_act_time + 1 end
	end
	local time_out = (os.time() - self.last_action_change_time_stamp) >= ACTION_TIME_OUT 
    return time_out
end

--重置时间
function multi_showhand_table:reset_action_time()
   self.last_action_change_time_stamp = os.time()
end

--广播桌面状态
function multi_showhand_table:broad_cast_desk_state()
    if self.cur_state_FSM == FSM_S.PER_BEGIN or self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
        return
    end
    print("broad_cast_desk_state------------>",self.cur_state_FSM)
    self:broadcast2client_sh("SC_Multi_ShowHand_Desk_State",{state = self.cur_state_FSM})
end


--请求玩家数据
function multi_showhand_table:reconnect(player)
	log.info("player guid[%d] chair_id[%d]---------------> reconnect",player.guid,player.chair_id)
	base_table.reconnect(self,player)
    self:send_data_to_enter_player(player,true)
end


--获取弃牌玩家在某一轮次的牌
function multi_showhand_table:get_give_up_player_cards(player,is_self, which_round)
	--游戏结束发送所有的牌
	if player then
		log.info("player guid [%d] which_round[%d]",player.guid, tostring(which_round))
	else
		return {}
	end

	if not which_round  then
		log.info("game_id[%s]:player guid [%d] which_round[%d] ------------------->game except",self.table_game_id,player.guid, tostring(which_round))
		self.game_except_flag = 1
		which_round = 1
	end
	if which_round >= 4 then
		local cards = arrayClone(player.cards)
		--弃牌就不显示对方第一张牌
		if player.is_dead and not is_self then
			cards[1] = 255
		end
		return cards
	end
	local cur_round_cards = {}
	for k,v in pairs(player.cards) do
		if is_self and k <= (which_round + 1) then
			table.insert(cur_round_cards,v)
		elseif k <= (which_round + 1) then
			if k==1 then table.insert(cur_round_cards,255) else table.insert(cur_round_cards,v) end
		end
	end
	return cur_round_cards
end

--获取当前轮牌
function multi_showhand_table:get_cur_round_cards(player,is_self)
	--游戏结束发送所有的牌
	if self.cur_game_round >= 4 then
		local cards = arrayClone(player.cards)
		--弃牌就不显示对方第一张牌
		if player.is_dead and not is_self then
			cards[1] = 255
		elseif player and player.cur_status == 0 and self.cur_state_FSM ~= FSM_S.GAME_BALANCE + FSM_S.GAME_IDLE_HEAD then
			cards[1] = 255
		elseif player.cur_status == 2 and not is_self and self.cur_state_FSM ~= FSM_S.GAME_BALANCE + FSM_S.GAME_IDLE_HEAD then
			cards[1] = 255
		end
		return cards
	end
	local cur_round_cards = {}
	for k,v in pairs(player.cards) do
		if is_self and k <= (self.cur_game_round + 1) then
			table.insert(cur_round_cards,v)
		elseif k <= (self.cur_game_round + 1) then
			if k==1 then table.insert(cur_round_cards,255) else table.insert(cur_round_cards,v) end
		end
	end
	return cur_round_cards
end

--玩家进入发送数据
function multi_showhand_table:send_data_to_enter_player(player,is_reconnect)
	log.info("player guid[%d] comming, chair_id[%d], table_id[%d] ,reconnect flag[%s]",player.guid, player.chair_id,self.table_id_,tostring(is_reconnect))
    local msg = {}
    msg.state = self.cur_state_FSM
    msg.zhuang = self.zhuang
    msg.self_chair_id = player.chair_id
    msg.act_time_limit = ACTION_TIME_OUT
    msg.is_reconnect = is_reconnect
	msg.base_score = CELL_SCORE
	msg.max_call = self.max_call
    msg.pb_players = {}
    for k,v in pairs(self.players) do
        if v and v.cur_status == 2 then
            local tplayer = {}
            tplayer.chair_id = v.chair_id
			tplayer.guid = v.guid
            tplayer.tiles = self:get_cur_round_cards(v,v.chair_id == player.chair_id)
			tplayer.add_total = v.add_total
    		tplayer.cur_round_add = v.cur_round_add
			if v.is_android then
				tplayer.nick = "robot"
				tplayer.icon = 1
				tplayer.gold = 999999
			else
				tplayer.nick = v.ip_area
				tplayer.icon = v:get_header_icon()
				--tplayer.gold = v:get_money()
				tplayer.gold = self:get_player_money(v)
			end
            table.insert(msg.pb_players,tplayer)
        end
    end

    if is_reconnect then
        msg.pb_rec_data = {}
        msg.pb_rec_data.act_left_time = self.last_action_change_time_stamp + ACTION_TIME_OUT - os.time()   
        if msg.pb_rec_data.act_left_time < 0 then msg.pb_rec_data.act_left_time = 0 end 
         msg.pb_rec_data.current_round = self.cur_game_round
        log.info("player guid[%d] act_left_time[%d] is_dead[%s] cur_status[%s]",player.guid,msg.pb_rec_data.act_left_time,tostring(player.is_dead),tostring(player.cur_status))
    end

    msg.pb_otherplayers = {}
    for _key, v in pairs(self.players) do
		if v and v.cur_status == 0 then
			-- 观众
			audience = {
				chair_id = v.chair_id,
				guid = v.guid,
				header_icon = v:get_header_icon(),
				money = self:get_player_money(v),
				ip_area = v.ip_area,
			}
			table.insert(msg.pb_otherplayers ,audience)
		end
	end

    send2client_pb_sh(player,"SC_Multi_ShowHand_Desk_Enter",msg)
	if is_reconnect then
		local left_time  = self.last_action_change_time_stamp + ACTION_TIME_OUT - os.time()
		if left_time < 0 then left_time = 0 end
		self:broadcast_next_turn(left_time)
		log.info("player guid[%d] broadcast_next_turn left_time[%d] is_dead[%s] cur_status[%s]",player.guid,left_time,tostring(player.is_dead),tostring(player.cur_status))
	end
	log.info("player guid[%d] self.cur_state_FSM[%d]",player.guid,self.cur_state_FSM)
	if self.cur_state_FSM == FSM_S.GAME_BALANCE or self.cur_state_FSM == FSM_S.GAME_CLOSE or 
	self.cur_state_FSM == (FSM_S.GAME_BALANCE+FSM_S.GAME_IDLE_HEAD) or self.cur_state_FSM == (FSM_S.GAME_CLOSE+FSM_S.GAME_IDLE_HEAD) then
		self:send_finish_msg_to_player(player,is_reconnect)
	end
end

--发送结算数据给玩家
function multi_showhand_table:send_finish_msg_to_player(player,is_reconnect)
	log.info("send_finish_msg_to_player:game_id[%s] player guid[%d] table_id[%d] , chair_id[%s] ,reconnect flag[%s]",self.table_game_id,player.guid, self.table_id_,tostring(player.chair_id),tostring(is_reconnect))
	local msg = {pb_players = {},
		tax_show = self.room_.tax_show_
	}
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 then
			local tplayer = {}
			tplayer.chair_id = v.chair_id
			if v.is_dead == true then
				--tplayer.tiles = self.giveup_player_cards[v.guid].tiles
				local dead_which_round = 1
				if self.giveup_player_cards[v.guid] then
					dead_which_round = self.giveup_player_cards[v.guid]
				end
				tplayer.tiles = self:get_give_up_player_cards(v,v.chair_id == player.chair_id,dead_which_round)
			else
				tplayer.tiles = self:get_cur_round_cards(v,v.chair_id == player.chair_id)
			end
			tplayer.is_win 		= v.chair_id == self.win_player_chair_id
			tplayer.is_give_up = v.is_dead
			tplayer.card_type = get_card_type_client(tplayer.tiles).type
			
			if v.is_android then
				tplayer.nick = "robot"
				tplayer.icon = 1
				tplayer.gold = 999999
			else
				tplayer.guid = v.guid
				tplayer.nick = v.ip_area
				tplayer.icon = v:get_header_icon()
				--tplayer.gold = v:get_money()
				tplayer.gold = self:get_player_money(v)
			end
			log.info("game_id[%s] player guid[%d] card_type = [%d],is_win=[%s]",self.table_game_id,v.guid, tplayer.card_type,tostring(tplayer.is_win))
			if tplayer.is_win then --赢了
				tplayer.win_money = self.win_money
				tplayer.taxes = self.win_taxes
				tplayer.gold = tplayer.gold + self.win_money + v.add_total
				log.info("game_id[%s] winner player guid[%d] win_money[%d] taxes[%d] gold[%d]",self.table_game_id,v.guid,tplayer.win_money,tplayer.taxes,tplayer.gold)
			else--输了
				tplayer.win_money = -v.add_total
				tplayer.taxes = 0
				log.info("game_id[%s] loser player guid[%d] win_money[%d] taxes[%d] gold[%d]",self.table_game_id,v.guid,tplayer.win_money,tplayer.taxes,tplayer.gold)
			end

			table.insert(msg.pb_players,tplayer)
		end
	end
  	for i, v in pairs(self.giveup_player_info) do
    	if v then
    		table.insert(msg.pb_players,v)
    	end
    end
	send2client_pb_sh(player,"SC_Multi_ShowHand_Game_Finish",msg)
end

-- 加注
function multi_showhand_table:add_score(player, msg)
	if msg then
		log.info("game_id[%s] player guid[%d] ------------->add_score,msg.round_index = [%d], target value[%d]",self.table_game_id,player.guid,msg.round_index,msg.target)
		if msg.round_index == self.cur_game_round then
			self:safe_event({chair_id = player.chair_id,type = FSM_E.ADD_SCORE,target = msg.target})
		else
			log.info("game_id[%s] add_score error round->%d cur_game_round->%d",self.table_game_id,msg.round_index,self.cur_game_round)
		end
    end
end


-- 弃牌
function multi_showhand_table:give_up(player, msg)
	log.info("game_id[%s] player guid[%d]---------------> give_up",self.table_game_id,player.guid)
	self:safe_event({chair_id = player.chair_id,type = FSM_E.GIVE_UP})
end


-- 让牌
function multi_showhand_table:pass(player,msg)
	log.info("game_id[%s] player guid[%d]----------------> pass,msg.round_index = [%d]",self.table_game_id,player.guid,msg.round_index)
	if msg then
		if msg.round_index == self.cur_game_round then
			if self.pass_action[self.cur_game_round] ~= player.guid then --该轮次第一次过牌
				self:safe_event({chair_id = player.chair_id,type = FSM_E.PASS})
				self.pass_action[self.cur_game_round] = player.guid
			else--该轮重复多次过牌
				log.error("game_id[%s] player guid[%d] pass more than 1 time,return",self.table_game_id,player.guid)
			end
			
		else
			log.info("game_id[%s] pass error round->%d cur_game_round->%d",self.table_game_id,msg.round_index,self.cur_game_round)
		end
    end
end


--弃牌并退出
function multi_showhand_table:give_up_eixt(player)
	log.info("game_id[%s] player guid[%d]--------------> give_up_eixt",self.table_game_id,player.guid)
	self:safe_event({chair_id = player.chair_id,type = FSM_E.GIVE_UP_EIXT})
end

--判断进入下一轮
function multi_showhand_table:can_next_round()
	local tmp_add_total = -1
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 and not v.is_dead then
			if not v.declare_this_round then return false end
			if tmp_add_total == -1 then tmp_add_total = v.add_total end
			if tmp_add_total ~= v.add_total then return false end
		end
	end
	return true
end

--还在继续的玩家
function multi_showhand_table:live_count()
	local player_count = 0
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 and not v.is_dead then
			player_count = player_count + 1
		end
	end
	return player_count
end

--判断下一个动作
function multi_showhand_table:judge_after_action()
	local l_c = self:live_count()
	if l_c == 1 then 
		--避免弃牌后不能立即退出
		--self:update_state_delay(FSM_S.GAME_BALANCE,1)
		self:update_state(FSM_S.GAME_BALANCE)
	elseif self:can_next_round() then
		if self.cur_game_round < 4 and not self.is_allin_state then
			self:update_state_delay(FSM_S.GAME_ROUND,1)
		else
			--self:update_state_delay(FSM_S.GAME_BALANCE,1)
			self:update_state(FSM_S.GAME_BALANCE)
		end
	else
		self:next_turn()
	end
end

--执行过牌操作
function multi_showhand_table:do_pass(player)
	
	local can_pass = true
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 then
			if v.add_total > player.add_total then
				can_pass = false
			end
		end
	end
	if can_pass then
		log.info("game_id[%s] player guid[%d] chair_id[%d] ------------------->do_pass",self.table_game_id,player.guid,player.chair_id)
		player.declare_this_round = true
		self:broadcast2client_sh("SC_Multi_ShowHandPass",{chair_id = player.chair_id})
		self:judge_after_action()
		table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "PASS"})
		self:reset_action_time()
	else
		log.info("game_id[%s] player guid[%d] chair_id[%d] can not pass,must give up.",self.table_game_id,player.guid,player.chair_id)
		self:do_give_up(player)
	end
end

--执行弃牌操作
function multi_showhand_table:do_give_up(player)
	player.is_dead = true
	player.declare_this_round = true
	--local card_info = {
	--	tiles = self:get_cur_round_cards(player,true)
	--}
	
	-- 下注流水
	self:player_bet_flow_log(player,player.add_total)

	log.info("game_id[%s] player guid[%d] chair_id[%d]------------------->do_give_up",self.table_game_id,player.guid,player.chair_id)
	self.giveup_player_cards[player.guid] = self.cur_game_round
	self:broadcast2client_sh("SC_Multi_ShowHandGiveUp",{chair_id = player.chair_id})
	self:judge_after_action()
	table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "GIVE_UP"})
	self:reset_action_time()
end

--执行加注操作
function multi_showhand_table:do_add_score(player,target)
	log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] --------------->do_add_score,target[%d] cur_game_round[%d],cur_round_add[%d] add_total[%d] cur_money[%d]",
			self.table_game_id,self.cur_game_round,player.guid,target,self.cur_game_round,player.cur_round_add,player.add_total,self:get_player_money(player)))
	if target == -1 and self.cur_game_round > 1 then --allin
		log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] allin------------->target[%d] self.is_allin_state[%s], cur_round_add[%d] add_total[%d] cur_money[%d]",
				self.table_game_id,self.cur_game_round,player.guid, target,tostring(self.is_allin_state),player.cur_round_add,player.add_total,self:get_player_money(player)))
		local allin_money = 0
		if not self.is_allin_state then
			allin_money = self.game_max_bet - player.cur_round_add
			log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] allin, allin_money[%d] add_total[%d] cur_round_add[%d] cur_money[%d] self.game_max_bet[%d]",
					self.table_game_id,self.cur_game_round,player.guid, allin_money,player.add_total,player.cur_round_add,self:get_player_money(player),self.game_max_bet))
		else
			allin_money = self.game_max_bet - player.cur_round_add
			log.info(string.format("game_id[%s] cur_game_round[%d] have player allin player guid[%d] allin, allin_money[%d] add_total[%d] cur_round_add[%d] cur_money[%d] self.game_max_bet[%d]",
					self.table_game_id,self.cur_game_round,player.guid, allin_money,player.add_total,player.cur_round_add,self:get_player_money(player),self.game_max_bet))
		end
		assert(allin_money > 0)
		if (not self.is_test) and (not player.is_android) then 
			self:cost_player_money(player,allin_money)
		end
		player.add_total = player.add_total + allin_money
		player.declare_this_round = true
		player.cur_round_add = player.cur_round_add + allin_money
		log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] allin_money[%d] add_total[%d] cur_round_add[%d] cur_money[%d]",
				self.table_game_id,self.cur_game_round,player.guid, allin_money,player.add_total,player.cur_round_add,self:get_player_money(player)))
		self.is_allin_state = true
		local player_left_money = self:get_player_money(player)
		log.info(string.format("1111game_id[%s] cur_game_round[%d]  player guid[%d] target[%d] left_money[%d] add_total_money[%d] cur_add_money[%d] cur_round_add[%d]",
				self.table_game_id,self.cur_game_round,player.guid,target,player_left_money,player.add_total,allin_money,player.cur_round_add))
		if allin_money > 0 then self:broadcast2client_sh("SC_Multi_ShowHandAddScore",{target = target,chair_id = player.chair_id, guid = player.guid,left_money = player_left_money,add_total_money = player.add_total,cur_add_money = allin_money,cur_round_money = player.cur_round_add}) end 
		self:judge_after_action()
		table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "ALL_IN",money = allin_money})
		self:reset_action_time()
	elseif target == -2 then --跟注
		log.info("game_id[%s] cur_game_round[%d] player guid[%d] add_total[%d] cur_round_add[%d] cur_money[%d]",self.table_game_id,self.cur_game_round,player.guid, player.add_total,player.cur_round_add,self:get_player_money(player))
		local gengzhu_val = 0
		for k,v in pairs(self.players) do
			if v and v.cur_status == 2 and not v.is_dead then
				if v.add_total - player.add_total > gengzhu_val then
					gengzhu_val = v.add_total - player.add_total
				end
			end
		end
		if gengzhu_val > 0 then
			if (not self.is_test) and (not player.is_android) then 
				self:cost_player_money(player,gengzhu_val)
			end
			player.add_total = player.add_total + gengzhu_val
			player.declare_this_round = true
			player.cur_round_add = player.cur_round_add + gengzhu_val
			if self:get_player_money(player) == 0 then
				self.is_allin_state = true
			end
			local player_left_money = self:get_player_money(player)
			if self.is_allin_state then
				log.info(string.format("2222game_id[%s] cur_game_round[%d] player guid[%d] target[%d] left_money[%d] add_total_money[%d] cur_add_money[%d] cur_round_add[%d]",
						self.table_game_id,self.cur_game_round,player.guid,target,player_left_money,player.add_total,gengzhu_val,player.cur_round_add))
				self:broadcast2client_sh("SC_Multi_ShowHandAddScore",{target = -1,chair_id = player.chair_id, guid = player.guid,left_money = player_left_money,add_total_money = player.add_total,cur_add_money = gengzhu_val,cur_round_money = player.cur_round_add})
			else
				log.info(string.format("3333game_id[%s] cur_game_round[%d] player guid[%d] target[%d] left_money[%d] add_total_money[%d] cur_add_money[%d] cur_round_add[%d]",
						self.table_game_id,self.cur_game_round,player.guid,target,player_left_money,player.add_total,gengzhu_val,player.cur_round_add))
				self:broadcast2client_sh("SC_Multi_ShowHandAddScore",{target = target,chair_id = player.chair_id, guid = player.guid,left_money = player_left_money,add_total_money = player.add_total,cur_add_money = gengzhu_val,cur_round_money = player.cur_round_add})
			end
			self:judge_after_action()
			table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "FOLLOW",money = gengzhu_val})
			self:reset_action_time()
			log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] add_total[%d] cur_round_add[%d] gengzhu_val[%d]",
					self.table_game_id,self.cur_game_round,player.guid, player.add_total,player.cur_round_add,gengzhu_val))
		end
	elseif target > 0 then
		log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] target[%d] player.cur_round_add[%d] player add_total[%d] cur_money[%d]",
			self.table_game_id,self.cur_game_round,player.guid, target,player.cur_round_add,player.add_total,self:get_player_money(player)))

		local is_bigest = true
		if is_bigest then 
			local player_left_money = 0
			local cur_add = target
			log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] cur_add[%d] target[%d] cur_round_add[%d] add_total[%d] cur_money[%d]",
					self.table_game_id,self.cur_game_round,player.guid, cur_add,target,player.cur_round_add,player.add_total,self:get_player_money(player)))
			if cur_add > 0 and cur_add > self:get_player_money(player) then
				log.info("game_id[%s] player guid[%d] cur_add[%d] > player cur_money[%d] add_total[%d] cur_round_add[%d]",self.table_game_id,player.guid, cur_add,self:get_player_money(player),player.add_total,player.cur_round_add)
				cur_add = self:get_player_money(player)
				self.is_allin_state = true
				self.allin_money = cur_add	
			end
			if cur_add > 0 and (player.cur_round_add + cur_add) > self.single_round_max_bet then
				cur_add = self.single_round_max_bet - player.cur_round_add
				log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] cur_add[%d] target[%d] add_total[%d] cur_round_add[%d] cur_money[%d] single_round_max_bet[%d]",
					self.table_game_id,self.cur_game_round,player.guid, cur_add,target,player.add_total,player.cur_round_add,self:get_player_money(player),self.single_round_max_bet))
			end

			if cur_add > 0 then
				if (not self.is_test) and (not player.is_android) then 
					self:cost_player_money(player,cur_add)
				end
				player.add_total = player.add_total + cur_add
				player.declare_this_round = true
				player.cur_round_add = player.cur_round_add + cur_add
				if self:get_player_money(player) == 0 then
					self.is_allin_state = true
					self.allin_money = cur_add
				end
				player_left_money = self:get_player_money(player)
				if self.is_allin_state then
					log.info(string.format("4444game_id[%s] cur_game_round[%d] player guid[%d] target[%d] left_money[%d] add_total_money[%d] cur_add_money[%d] cur_round_add[%d]",
							self.table_game_id,self.cur_game_round,player.guid,target,player_left_money,player.add_total,cur_add,player.cur_round_add))
					self:broadcast2client_sh("SC_Multi_ShowHandAddScore",{target = -1,chair_id = player.chair_id, guid = player.guid, left_money = player_left_money,add_total_money = player.add_total,cur_add_money = cur_add,cur_round_money = player.cur_round_add})
				else
					log.info(string.format("5555game_id[%s] cur_game_round[%d] player guid[%d] target[%d] left_money[%d] add_total_money[%d] cur_add_money[%d] cur_round_add[%d]",
							self.table_game_id,self.cur_game_round,player.guid,target,player_left_money,player.add_total,cur_add,player.cur_round_add))
					self:broadcast2client_sh("SC_Multi_ShowHandAddScore",{target = player.cur_round_add,chair_id = player.chair_id, guid = player.guid, left_money = player_left_money,add_total_money = player.add_total,cur_add_money = cur_add,cur_round_money = player.cur_round_add})
				end
				self:judge_after_action()
				table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "ADD",money = cur_add})
				self:reset_action_time()
				log.info(string.format("game_id[%s] cur_game_round[%d] player guid[%d] add_total[%d] cur_round_add[%d] cur_add[%d]",
						self.table_game_id,self.cur_game_round,player.guid, player.add_total,player.cur_round_add,cur_add))
			end
		else
			if not self.is_test then log.error("client addscore erroe guid " .. player.guid) end
		end
	end
end


function multi_showhand_table:FSM_event(event_table)
    if self.cur_state_FSM == FSM_S.PER_BEGIN then  --预准备
        if event_table.type == FSM_E.UPDATE then
            self:update_state_delay(FSM_S.XI_PAI,WAIT_TIME+1)
        else 
            log.error("FSM_event error cur_state[%d] event_table.type[%d] ",self.cur_state_FSM,event_table.type)
        end
    elseif self.cur_state_FSM == FSM_S.XI_PAI then  --洗牌
        if event_table.type == FSM_E.UPDATE then
     
        	for k,v in pairs(self.players) do
				if v then
					v.is_dead = false
					v.declare_this_round = false
					v.need_eixt = false
					v.cards = {}
					v.add_total = 0
					v.cur_round_add = 0
					v.last_round_add = 0
					--v.old_money = v:get_money()
					v.old_money = self:get_player_money(v)
					v.cur_status = 1 --准备中(0观众，1准备中，2游戏中)
				end
			end
        	
			self.table_game_id = self:get_now_game_id()
		    self:next_game()
			self.game_log = {
		        table_game_id = self.table_game_id,
		        start_game_time = os.time(),
		        zhuang = self.zhuang,
		        max_call = self.max_call,
		        action_table = {},
		        players = {},
		    }

		    
        	for k,v in pairs(self.players) do
				if v and v.cur_status == 1 then
					v.cur_status = 2 --游戏中玩家
					self.giveup_player_cards[v.guid] = 1 --默认值
					local tmp_p = {account = v.account,nickname = v.nickname,ip_area = v.ip_area,
					guid = v.guid,chair_id = v.chair_id,money_old = self:get_player_money(v)}
					self.game_log.players[v.chair_id] = tmp_p

					local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
					log.info(str)
					redis_command(str)
				end
			end	

			self:GetCurRoundShowhandMax()
			self:GetSingleRoundMaxBet()
			local CurPlayerTotal = self:GetActuralPlayerNum()
			log.info("game_id[%s] CurPlayerTotal------------->[%d] game_cur_status[%d] game start............",self.table_game_id,CurPlayerTotal,self.cur_state_FSM)
			if CurPlayerTotal < 2 then
        		log.error("Actural player count total less than 2 ,return")
        		self:reset()
        		return
        	end

        	local big_player = nil
			for k,v in pairs(self.players) do
				if v and v.cur_status == 2 and not v.is_dead then
					if not big_player or compare_cards(v.cards,big_player.cards,self.cur_game_round, false) then
						big_player = v
						break
					end
				end
			end
			if big_player then
				self.zhuang = big_player.chair_id
			else
				self.zhuang = self.zhuang or random.boost(1,CurPlayerTotal)
			end
				
			log.info("game_id[%s] cur_game_round[%d] game_max_bet----->[%d] single_round_max_bet----->[%d] zhuang[%d]",self.table_game_id,self.cur_game_round,self.game_max_bet,self.single_round_max_bet,self.zhuang)
			math.randomseed(tostring(os.time()):reverse():sub(1, 6))
			-- 发底牌
			local k = #self.cards
	
			--是否需要做牌
			local card_index = 1
			local is_make_card = multi_showhand_cardmake.need_make_card()
			local make_success = false
			local cards_by_make = {}
			if is_make_card then
				make_success,cards_by_make = multi_showhand_cardmake.make_cards(CurPlayerTotal)
			end
			
			for i,v in ipairs(self.players) do
				if v and v.cur_status == 2 then 
					--v.cur_status = 2 --游戏中玩家
					--做牌
					if is_make_card and make_success then
						for j=1,5 do
							v.cards[j] = cards_by_make[card_index][j]
						end	
						card_index = card_index+1
					else
						local cards = v.cards
						for j=1,5 do
							local r = random.boost(k)
							cards[j] = self.cards[r]
							if r ~= k then
								self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
							end
							k = k-1
						end	
					end
					log.info("player guid[%d], chair_id[%d]", v.guid, v.chair_id)
					log.info(table.concat(v.cards, ','))
					self.game_log.players[v.chair_id].cards = arrayClone(v.cards)
					self.game_log.players[v.chair_id].cards_type = get_card_type(v.cards).type
				end
			end

			--检查黑名单
			self:check_blackplayer()
			--test--
			--1-4,>>>
			--  方块 草花 红桃 黑桃
			-- (x-2)*4 + color
			-- 8 	25 26 27 28
			-- 9	29 30 31 32
			-- 10   33 34 35 36	
			-- J 	37 38 39 40
			-- Q 	41 42 43 44
			-- K 	45 46 47 48
			-- A 	49 50 51 52
			--self.players[1].cards = {25,29,33,37,49}
			--self.players[2].cards = {46,37,33,27,26}
			--test--
            for k,v in pairs(self.players) do
                if v and v.cur_status == 2 then 
					v.add_total = v.add_total + CELL_SCORE
					if (not self.is_test) and (not v.is_android) then 
						--v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = self.room_.cell_score}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
						self:cost_player_money(v,CELL_SCORE)
					end
				end 
            end
			for k,v in pairs(self.players) do
                if v and v.cur_status == 2 then 
					self:send_data_to_enter_player(v,false) 
				end 
            end
			self:update_state_delay(FSM_S.GAME_ROUND,2)
        else
            log.error("FSM_event error cur_state[%d]/event.type[%d]",self.cur_state_FSM, event_table.type)
        end
	elseif self.cur_state_FSM == FSM_S.GAME_ROUND then --游戏回合
		if self.players[self.cur_turn] ~= nil and self.players[self.cur_turn].cur_status ~= 2 then
			 self.game_except_flag = 1
			 self:update_state(FSM_S.GAME_CLOSE)
			 log.error(string.format("game_id[%s] guid[%d] is not play game player.",self.table_game_id,self.players[self.cur_turn].guid)) 
			 return
		end
		
		local cur_turn_player = self.players[self.cur_turn]
		if not cur_turn_player then
			log.error("cur_turn_player nil error.")
			return
		end
		local cur_player_add_total = cur_turn_player.add_total or 0
        if event_table.type == FSM_E.UPDATE then
			if self:is_action_time_out() then
				local can_pass = true
				for k,v in pairs(self.players) do
					if v and v.cur_status == 2 then
						if v.add_total > cur_player_add_total then
							can_pass = false
						end
					end
				end
				if can_pass then 
					log.info("game_id[%s] player guid[%d] will ------------------->time_out do_pass",self.table_game_id,cur_turn_player.guid)
					self:do_pass(cur_turn_player)
				else
					log.info("game_id[%s] player guid[%d] will ------------------->time_out do_give_up",self.table_game_id,cur_turn_player.guid)
					self:do_give_up(cur_turn_player)
				end
			end
		elseif event_table.type == FSM_E.ADD_SCORE then  --加注
			if event_table.chair_id == cur_turn_player.chair_id then
				self:do_add_score(cur_turn_player,event_table.target)
			end
		elseif event_table.type == FSM_E.PASS then  --过牌
			if event_table.chair_id == cur_turn_player.chair_id then
				self:do_pass(cur_turn_player)
			end
		elseif event_table.type == FSM_E.GIVE_UP then  --弃牌
		 	if event_table.chair_id == cur_turn_player.chair_id then
				self:do_give_up(cur_turn_player)
			end
		elseif event_table.type == FSM_E.GIVE_UP_EIXT then --弃牌并退出
			local cur_chair_player = self.players[event_table.chair_id]
			if not cur_chair_player then
				log.error("cur_chair_player nil error.")
				return
			end
			if self.players[event_table.chair_id] ~= nil and self.players[event_table.chair_id].cur_status == 2 then  --非观众
				local cur_player = self.players[event_table.chair_id]
				cur_player.need_eixt = true
			 	self:do_give_up(cur_player)
			end
        else
            log.error("FSM_event error cur_state[%d]/event.type[%d]",self.cur_state_FSM, event_table.type)
        end
	elseif self.cur_state_FSM == FSM_S.GAME_BALANCE then  --游戏结算
        if event_table.type == FSM_E.UPDATE then
    		self.cur_state_FSM = self.cur_state_FSM + FSM_S.GAME_IDLE_HEAD
        	--扣除所有未扣除的钱
        	self:cost_money_real()
        	local player_win_total = 0
			local win_player = nil
			local all_add_total = 0
			for k,v in pairs(self.players) do
				if v and v.cur_status == 2 and not v.is_dead then
					-- 下注流水
					self:player_bet_flow_log(v,v.add_total)

					log.info("111game_id[%s] player guid[%d] cur_status = [%d]",self.table_game_id,v.guid, v.cur_status)
					if win_player then
						if compare_cards(v.cards,win_player.cards,4,true) then
							win_player = v
						end
					else
						win_player = v
					end
				end
				if v and v.cur_status == 2 then 
					all_add_total = all_add_total + v.add_total 
					log.info("2222game_id[%s] player guid[%d] cur_status = [%d] v.add_total[%d] all_add_total[%d]",self.table_game_id,v.guid, v.cur_status,v.add_total,all_add_total)
				end
			end

			for i,v in pairs(self.giveup_player_info) do
				if v then
					local player_add_total = -v.win_money
					all_add_total = all_add_total + player_add_total
					log.info("game_id[%s] give up player[%d] add_total[%d] all_add_total[%d]",self.table_game_id, v.guid, player_add_total,all_add_total)
				end
			end
	
			self.zhuang = win_player.chair_id
			self.win_taxes = math.ceil((all_add_total - win_player.add_total) * self.room_:get_room_tax())
			if self.win_taxes == 1 then self.win_taxes = 0 end -- 一分就不收税
			self.win_money = all_add_total - self.win_taxes - win_player.add_total
            self.win_player_chair_id = win_player.chair_id

			for k,v in pairs(self.players) do
				--if v and v.cur_status == 2 then
				if v then
					self:send_finish_msg_to_player(v,false)
				end
			end
			player_win_total = self.win_money + win_player.add_total
			if (not self.is_test) and (not win_player.is_android) then 
				win_player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = self.win_money + win_player.add_total}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
			end

			--赢得玩家达到中奖基数后全服广播
			if self.win_money >= MULTI_SHOWHAND_PRICE_BASE then 		
				log.info("game_id[%s] player guid[%d] in multi_showhand game earn money[%d] upto [%d],broadcast to all players.",self.table_game_id,win_player.guid,self.win_money,MULTI_SHOWHAND_PRICE_BASE)
				broadcast_world_marquee(def_first_game_type,def_second_game_type,0,win_player.nickname,self.win_money/100)
			end
			print("winner gold after add---------------->",win_player:get_money())

			self.game_log.taxes = self.win_taxes
			self.game_log.win_money = self.win_money
			self.game_log.win_chair_id = win_player.chair_id
            self.game_log.end_game_time = os.time()
            log.info("game_id[%s] player guid[%d] win_money[%d] taxes[%d] chair_id[%d] now money[%d]",self.table_game_id,win_player.guid,self.win_money,self.win_taxes,win_player.chair_id,win_player:get_money())

	        for k,v in pairs(self.players) do

	        	--reduce player count
				local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
				log.info(str)
				redis_command(str)

				--moneylog-------
				if v and v.cur_status == 2 then
					if self.win_player_chair_id == v.chair_id then
						if self.money_log_flag[v.guid] == nil then 
							self:player_money_log(v,2,v.old_money,self.win_taxes,self.win_money,self.game_log.table_game_id)
							self.money_log_flag[v.guid]  = 1
							log.info("game_id[%s] player guid[%d] old_money[%d] win_money[%d] chair_id[%s]",self.table_game_id,v.guid, v.old_money,self.win_money,tostring(v.chair_id))
						end
					else
						if self.money_log_flag[v.guid] == nil then 
							log.info("game_id[%s] player guid[%d] old_money[%d] cost add_total[%d] chair_id[%s]",self.table_game_id,v.guid, v.old_money,v.add_total,tostring(v.chair_id))
							self:player_money_log(v,1,v.old_money,0,-v.add_total,self.game_log.table_game_id)
							self.money_log_flag[v.guid]  = 1
						end
					end

					if not v.chair_id then
						v.chair_id = k
					end
					self.game_log.players[v.chair_id].increment_money = self:get_player_money(v) - v.old_money
				end
			end

			local s_log = json.encode(self.game_log)
	        log.info(s_log)
	        self:save_game_log(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)


            if self.is_test then
				self:update_state_delay(FSM_S.GAME_CLOSE,10)
			else
				self:update_state(FSM_S.GAME_CLOSE)
			end
        else
            log.error("FSM_event error cur_state[%d]/event.type[%d]",self.cur_state_FSM, event_table.type)
        end
    elseif self.cur_state_FSM == FSM_S.GAME_CLOSE then  --游戏结束
        if event_table.type == FSM_E.UPDATE then
			self.do_logic_update = false
			self:check_single_game_is_maintain()
            self:clear_ready()
            --异常牌局,玩家全部踢出
            if self.game_except_flag == 1 then
            	log.info("game_id[%s] is except.....................",self.table_game_id)
            	for i,v in ipairs(self.players) do
            		if v then
            			v:forced_exit()
            		end
            	end
            end

            local room_limit = self.room_:get_room_limit()
            for i,v in ipairs(self.players) do
                if v then
                    if v.need_eixt or v.in_game == false then
                    	log.info("player guid[%d] is not in game. forced exit.",v.guid)
                        v:forced_exit()
                    else
                        if not self.is_test then v:check_forced_exit(room_limit) end
                        if v.is_android then
                            self:ready(v)
                        end
                    end
                end
            end
            log.info("Game_id[%s] Game is over.........................................",self.table_game_id)
            self:reset()
			-- test --
			if self.is_test then self:start(2,true) end
			-- test --
        else
            log.error("FSM_event error cur_state[%d]/event.type[%d]",self.cur_state_FSM, event_table.type)
        end
    elseif self.cur_state_FSM == FSM_S.GAME_ERR then  --游戏错误
        if event_table.type == FSM_E.UPDATE then  
            self:update_state(FSM_S.GAME_CLOSE)
        else
            log.error("FSM_event error cur_state[%d]/event.type[%d]",self.cur_state_FSM, event_table.type)
        end
    elseif self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
    end
    return true
end


function multi_showhand_table:ready(player)
	base_table.ready(self,player)
	local next_state = self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD
	log.info("player guid[%d] chair_id[%d] player.cur_status[%d] ready next_state[%d] cur_state_FSM[%d]",player.guid,player.chair_id,player.cur_status,next_state,self.cur_state_FSM)
	if self.cur_state_FSM == FSM_S.WAITING or self.cur_state_FSM == FSM_S.PER_BEGIN or next_state == FSM_S.XI_PAI then --准备时间,游戏未开始
		self.player_count = self:getNum(self.players)
		log.info("#######player_count-------------->[%d]",self.player_count)
		if self.player_count > 1 and self.player_count < 6  then
			local msg = {
				s_start_time = self.last_action_change_time_stamp - os.time() - 1
			}
			send2client_pb(player,"SC_MultiStartCountdown", msg)
		else
			self.last_action_change_time_stamp = os.time() + WAIT_TIME
		end
		log.info("player guid[%d] room[%d] table[%d] chair_id[%d] player_num[%d]",player.guid,self.room_.id, self.table_id_ , player.chair_id, self.player_count)
	else
		self:send_data_to_enter_player(player,false)
		log.info("multi_showhand_table:ready room[%d] table[%d] player[%d] chair_id[%d] in table but game in player ,self.table_busy[%d], wait game end",self.room_.id,self.table_id_ ,player.guid,player.chair_id,self.table_busy)
		return
	end

	local notify = {
		room_id = self.room_.id,
		table_id = self.table_id_,
		chair_id = player.chair_id,
	}
	self:foreach_except(player.chair_id, function (p)
		local v = {
			chair_id = p.chair_id,
			guid = p.guid,
			account = p.account,
			nickname = p.nickname,
			money = self:get_player_money(p),
			header_icon = p:get_header_icon(),
			ip_area = p.ip_area,
		}
		notify.pb_visual_info = notify.pb_visual_info or {}
		table.insert(notify.pb_visual_info, v)
	end)
	log.info("multi_showhand_table:ready guid[%d],chair_id[%d],table_id[%d] cur_player_count[%d] players [%d]",player.guid,player.chair_id,self.table_id_,self.player_count,self:getNum(self.players))
	send2client_pb(player, "SC_MultiGetSitDown", notify)
end
function  multi_showhand_table:player_sit_down(player,chair_id)
	for i, p in pairs(self.players) do
		if p and p.guid ~= player.guid and p.chair_id == chair_id then
			log.error("sit down error,player guid[%d] chair_id[%d], p.guid[%d],",player.guid, chair_id,p.guid)
			return
		end
	end

	base_table.player_sit_down(self,player,chair_id)
	self.ready_list_[player.chair_id] = false

	player.is_dead = false
	player.declare_this_round = false
	player.need_eixt = false
	player.cards = {}
	player.add_total = 0
	player.cur_round_add = 0
	player.last_round_add = 0
	player.old_money = self:get_player_money(player)
	player.cur_status = 0 --准备中(0观众，1准备中，2游戏中)

	--正在玩状态，该玩家为观众
	local next_state = self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD
	log.info("player guid[%d] chair_id[%d] player_sit_down cur_status[%d] cur_state_FSM[%d]",player.guid,player.chair_id,next_state,self.cur_state_FSM)
	if self.cur_state_FSM == FSM_S.WAITING or self.cur_state_FSM == FSM_S.PER_BEGIN or next_state == FSM_S.XI_PAI then --准备时间,游戏未开始
		player.cur_status = 1 --准备玩家
		--准备状态
		self.player_count = self:getNum(self.players)
		--log.info("222player_count-------------->[%d], player_list num[%d]",self.player_count,getNum(self.players))
		--if self.player_count > 1 and self.player_count < 6  then
		--	local msg = {
		--		s_start_time = self.last_action_change_time_stamp - os.time() - 1
		--	}
		--	send2client_pb(player,"SC_MultiStartCountdown", msg)
		--else
		--	self.last_action_change_time_stamp = os.time() + WAIT_TIME
		--end
		log.info("player guid[%d] room[%d] table[%d] chair_id[%d] player.cur_status[%d] player_num[%d]",player.guid,self.room_.id, self.table_id_ , player.chair_id, player.cur_status,self.player_count)
	else --其他状态都为观众
		player.cur_status = 0 --观众
		--self:send_data_to_enter_player(player,false)
		log.info("multi_showhand_table:player_sit_down room[%d] table[%d] player[%d] chair_id[%d] player.cur_status[%d] in table but game in player ,self.table_busy[%d], wait game end",self.room_.id,self.table_id_ ,player.guid,player.chair_id,player.cur_status,self.table_busy)
		return
	end

end


function multi_showhand_table:getNum(arraylist)
	-- body
	local iNum = 0
	for _,v in pairs(arraylist) do
		if v then
			iNum = iNum + 1
		end
	end
	return iNum
end


function multi_showhand_table:check_start(part)
	print ("check_start-----------------multi_showhand_table:",self.table_busy)
	
	if self.do_logic_update then
		--log.info("game is start ,game_id[%s]",self.table_game_id)
		return
	else
		base_table.check_start(self,part)
	end
end

--获取下一轮单轮加注下限
function  multi_showhand_table:GetSingleRoundMaxBet()
	-- body
	self.single_round_max_bet  =  self.max_call*CELL_SCORE 
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 and not v.is_dead then
			if self:get_player_money(v) < self.single_round_max_bet then
				self.single_round_max_bet = self:get_player_money(v)
			end
		end
	end
	log.info("game_id[%s] cur_game_round[%d] and single_round_max_bet[%d]",self.table_game_id,self.cur_game_round,self.single_round_max_bet)
end

--求出当轮梭哈下限
--计算该轮最大梭哈值，根据玩家金币数定，若不满足底注*256倍则取开始玩家中最小的一个玩家金币数
function  multi_showhand_table:GetCurRoundShowhandMax()
	-- body
	--先算出所有玩家最小的金币玩家
	local default_min_money = -1
	local player_guid = -1
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 and not v.is_dead then
			log.info("player guid[%d] ------------->cur_money[%d]",v.guid, self:get_player_money(v))
			if default_min_money == -1 then
				default_min_money = self:get_player_money(v)
				player_guid = v.guid
			else
				if self:get_player_money(v) < default_min_money then
					log.info("player guid[%d] cur_money[%d] default_min_money[%d]",v.guid,self:get_player_money(v),default_min_money)
					default_min_money = self:get_player_money(v)
					player_guid = v.guid
				end
			end
		end
	end

	if player_guid == -1 then
		log.error("----------------------->get min money player error.")
		return
	end
	log.info("game_id[%s] cur_game_round[%d] player guid[%d] and default_min_money[%d]",self.table_game_id,self.cur_game_round,player_guid,default_min_money)
	self.game_max_bet = CELL_SCORE * MAX_CALL * 4 + CELL_SCORE --默认该局梭哈上限为底注的256倍(底注×256倍) 加底注
	for k,v in pairs(self.players) do
		if v and v.cur_status == 2 and not v.is_dead and v.guid == player_guid then
			local cur_player_money = self:get_player_money(v)
			log.info("game_id[%s] cur_game_round[%d] player guid[%d] cur_money[%d] add_total[%d] and default_min_money[%d]",self.table_game_id,self.cur_game_round,v.guid,cur_player_money,v.add_total,default_min_money)
			if (cur_player_money + v.add_total) <= self.game_max_bet then
				self.game_max_bet = cur_player_money
			else
				self.game_max_bet = self.game_max_bet - v.add_total
			end
		end
	end

	log.info("game_id[%s] cur_game_round[%d] and canshowhand_money[%d]",self.table_game_id,self.cur_game_round,self.game_max_bet)
end

function  multi_showhand_table:GetActuralPlayerNum()
	-- body
	local iNum = 0
	for _,v in pairs(self.players) do
		if v and v.cur_status == 2 and not v.is_dead then
			iNum = iNum + 1
		end
	end
	return iNum
end

--求出最大牌索引
function multi_showhand_table:check_blackplayer()
	-- body
	if BLACK_RATE < random.boost_integer(1,100) then
		return
	end

 	local big_player = nil
 	local max_cards_index = 1
	--log.info("start exchange cards............................")
	--for k,v in pairs(self.players) do
	--	if v and  v.cur_status == 2 then
	--		log.error("players guid[%d] chair_id[%d]", v.guid, v.chair_id)
	--		log.error(table.concat(v.cards, ',')
	--	end
	--end

	for k,v in pairs(self.players) do
		if v and  v.cur_status == 2 then
			if big_player then
				if compare_cards(v.cards,big_player.cards,4,true) then
					big_player = v
					max_cards_index = k
				end
			else
				big_player = v
				max_cards_index = k
			end
		end
	end

	log.info("max_cards_index---------->[%d], player guid[%d] chair_id[%d]",max_cards_index,big_player.guid, big_player.chair_id)
	log.info(table.concat(big_player.cards, ','))

	local white_players = {}
	for i,v in ipairs(self.players) do
		if v and v.cur_status == 2  then 
			if self:check_blacklist_player(v.guid) == false then
				table.insert(white_players, v)
				if max_cards_index == i then
					--最大牌已经在非黑名单玩家手里
					return
				end
			end
		end
	end

	--不存在白名单玩家
	if #white_players == 0 then
		log.info("this game is not white player, all are black list players.")
		return
	end
	--随机一个白名单玩家
	local player_info  = white_players[random.boost_integer(1,#white_players)]
	if not player_info then 
		return 
	end
	
	log.info("exchange white players guid[%d] chair_id[%d]", player_info.guid, player_info.chair_id)
	log.info(table.concat(player_info.cards, ','))

	if player_info.guid == big_player.guid then
		log.info("player guid[%d] is the same player.", player_info.guid)
		return
	end

	local swap_player_info_cards = {}
	swap_player_info_cards = deepcopy_table(player_info.cards)
	player_info.cards = {}
	player_info.cards = deepcopy_table(big_player.cards)
	self.game_log.players[player_info.chair_id].cards = arrayClone(player_info.cards)
	self.game_log.players[player_info.chair_id].cards_type = get_card_type(player_info.cards).type
	log.info("white players guid[%d] chair_id[%d]", player_info.guid, player_info.chair_id)
	log.info(table.concat(player_info.cards, ','))

	big_player.cards = {}
	big_player.cards = deepcopy_table(swap_player_info_cards)
	self.game_log.players[big_player.chair_id].cards = arrayClone(big_player.cards)
	self.game_log.players[big_player.chair_id].cards_type = get_card_type(big_player.cards).type
	log.info("black list players guid[%d] chair_id[%d]", big_player.guid, big_player.chair_id)
	log.info(table.concat(big_player.cards, ','))


	--log.info("exchange cards complete............................")
	--for k,v in pairs(self.players) do
	--	if v and  v.cur_status == 2 then
	--		log.error("players guid[%d] chair_id[%d]", v.guid, v.chair_id)
	--		log.error(table.concat(v.cards, ',')
	--	end
	--end
end


function deepcopy_table(object)      
    local lookup_table = {}  
    local function _copy(object)  
        if type(object) ~= "table" then  
            return object  
        elseif lookup_table[object] then  
  
            return lookup_table[object]  
        end  -- if          
        local new_table = {}  
        lookup_table[object] = new_table  
  
  
        for index, value in pairs(object) do  
            new_table[_copy(index)] = _copy(value)  
        end   
        return setmetatable(new_table, getmetatable(object))      
    end       
    return _copy(object)  
end  