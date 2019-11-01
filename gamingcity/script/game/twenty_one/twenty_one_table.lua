require "functions"
local base_table = require "game.lobby.base_table"
require "game.lobby.base_player"
require "game.twenty_one.config"
require "game.timer_manager"
require "game.twenty_one.logic"
require "game.twenty_one.define"
local card_dealer = require("game/card_dealer")

local pb = require "pb"
local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local LOG_MONEY_OPT_TYPE_TWENTY_ONE = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_TWENTY_ONE")

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local redis_command = redis_command

local start_timeout = 5
local bet_timeout = 5
local buy_security_timeout = 10
local operation_timeout = 10
local max_robot_oper_timeout = 2
local balance_timeout = 4
local banker_blackjack_wait_balance = 1
local kick_offline_player_tick_time = 0.2
local operation_interval_wait_time = 0.5
local max_wait_time_after_dealcards = 5
local balance_player_timeout = 1
local deal_one_card_time = 0.4
local buy_security_wait_timeout = 3
local balance_security_timeout = 1
local banker_operation_time_interval = 1
local operation_time_interval = 0.5

function base_player:reset()
    self.cards = {}
    self.status = PlayerStatus.Idle
	self.bet_amount = 0
    self.surrender = false
    self.stand = false
    self.double = nil
	self.bomb = false
    self.security = nil
	self.parent = nil
	self.sub_player = nil
	self.is_open_cards = nil
	self.trusteeship = false
	self.balance_money = nil
	self.balance_security_money = 0
	self.total_balance = 0
	self.standby = true
	self.old_money = self:get_money()
	self.cur_money = self.old_money
	self.is_kill_score = false
end

function base_player:create_sub_player()
	self.sub_player = clone(self)
	self.sub_player.parent = self
	self.sub_player.chair_id =  -self.chair_id
	self.sub_player.security = nil
	self.sub_player.balance_security_money = 0
	return self.sub_player
end

function base_player:real_chair_id()
	return math.abs(self.chair_id)
end

function base_player:robot_operations()
	if logic.is_blackjack(self.cards) or self.bomb or self.stand or self.surrender then
		print(string.format("robot operations return"))
		return false 
	end

	dump(self.cards)
	if logic.get_cards_number(self.cards) <= 16 then 
		print("Operation.Hit")
		return Operation.Hit
	end

	if logic.get_cards_number(self.cards) > 16 then
		print("Operation.Stand")
		return Operation.Stand 
	end
	return false
end

function base_player:operations()
	if	self.surrender or 
		self.stand or 
		self.bomb or 
		(self.double and self.double > 0 ) or
		#self.cards >= 5 or 
		logic.get_cards_number(self.cards) >= 21 then
		print("base_player:operations nil  guid["..tostring(self.guid).."]")
		return nil 
	end

	local opers = {}
	if not self.double then 
		if #self.cards == 2 and
		(self:get_money() - self.bet_amount * 2 - (self.security or 0)) >= 0 then 
			table.push_back(opers,Operation.Double) 
		end
		table.push_back(opers,Operation.Hit) 
	end

	table.push_back(opers,Operation.Stand)
	if #self.cards == 2 then
		table.push_back(opers,Operation.Surrender)
		if	logic.card_number(self.cards[1]) == logic.card_number(self.cards[2]) and 
			(not self.parent and not self.sub_player) and 
			(self:get_money() - self.bet_amount * 2 - (self.security or 0)) >= 0 then
			table.push_back(opers,Operation.SplitCard)
		end
	end

	return opers
end

function base_player:can_balance_immediately()
	if self.bomb then return true end
	if self.surrender then return true end
	if logic.is_blackjack(self.cards) and (not self.parent and not self.sub_player) then return true end
	return false
end

function base_player:is_stop_operation()
	if self.bomb then return true end
	if self.surrender then return true end
	if #self.cards == 5 then return true end
	if logic.is_blackjack(self.cards) then return true end
	if logic.get_cards_number(self.cards) == 21 then return true end
	return false
end

function base_player:is_standby()
	return self.standby and not self.balance_money
end

function base_player:allow_stand_up()
	self.bet_amount = 0
	self.standby = true
end

local function to_string(value)
	if value == nil then
		return "nil"
	end

	if type(value) == 'table' then
		return '['..table.concat(value,",")..']'
	end

	if type(value) == "number" then
		return string.format("%d",value)
	end

	return value
end

twenty_one_table = class("twenty_one_table",base_table)

--  1,2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,   --???? A - K
--  16,17,18,19,20,21,22,23,24,25,26,27,28,   --???? A - K
--  31,32,33,34,35,36,37,38,39,40,41,42,43,   --???? A - K
--  46,47,48,49,50,51,52,53,54,55,56,57,58,   --???? A - K
function twenty_one_table:ctor()
    self.card_dealer = card_dealer.new(false,1,13)
end

function twenty_one_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)

    self.status = TableStatus.Idle

    self.card_dealer:shuffle()

	self.ready_start_timer_name = string.format("timer_ready_start_%d",self.table_id_)
	self.buy_security_timer_name = string.format("timer_security_%d",self.table_id_)
	self.oper_timer_name = string.format("timer_operation_%d",self.table_id_)
	self.bet_timer_name = string.format("timer_bet_%d",self.table_id_)
	self.ready_start_timer_delay_name = string.format("timer_ready_start_delay_%d",self.table_id_)
	
    self.s_cell = self.room_:get_room_cell_money()
    self.s_tax = self.room_:get_room_tax()
	self.banker = clone(base_player)
	self.banker:reset()
	self.banker.guid = 0
	self.banker.chair_id = 0
	self:reset()

	timer_manager:new_timer(kick_offline_player_tick_time,function() 
		self:foreach(function(p)
			if self.status == TableStatus.Idle and p.trusteeship then p:force_exit() end
		end)
	end,nil,true)
end

function twenty_one_table:reset()
	self.cur_oper_index = 0
    self.cur_operator = nil
	self.allow_operations = {}
    self.game_log = {
			players = {},
            game_server_id = def_game_id,
            first_game_type = def_first_game_type,
            second_game_type = def_second_game_type,
            game_name = def_game_name
		}
end

function twenty_one_table:foreach_and_oper_result(func)
	return self:foreach_condition_and_oper_result(function(p) return true end,func)
end

function twenty_one_table:foreach_condition_and_oper_result(cond,func)
	for i, p in pairs(self.player_list_) do
		if p and cond(p) then if not func(p)  then return false end end
	end

    return true
end

function twenty_one_table:foreach_not_ready(func)
    return self:foreach_condition_oper(function(p) return not self.ready_list_[p.chair_id] end,func)
end

function twenty_one_table:foreach_ready(func)
    return self:foreach_condition_oper(function(p) return self.ready_list_[p.chair_id] end,func)
end

function twenty_one_table:foreach_not_standby(func)
    return self:foreach_condition_oper(function(p) return not p.standby end,func)
end

function twenty_one_table:foreach_beted(func)
	return self:foreach_condition_oper(function(p) return self.ready_list_[p.chair_id] and p.bet_amount > 0 end,func)
end

function twenty_one_table:foreach_condition_oper(func_cond,func_op)
    for i,p in pairs(self.player_list_) do
        if p and func_cond(p) then  func_op(p) end
    end
end

function twenty_one_table:get_online_player_count()
    local online_player_count = 0
    for _,p in pairs(self.player_list_) do
        if p and not p.trusteeship then
            online_player_count = online_player_count + 1
        end
    end

    return online_player_count
end


function twenty_one_table:get_beted_player_count()
	local count = 0
	self:foreach_beted(function(p,k) count = count + 1 end)
	return count
end

function twenty_one_table:load_lua_cfg(...)
    self:broadcast2client("SC_RoomCfg",{bet_moneies = bet_money_units})
	self.s_cell = self.room_:get_room_cell_money()
    self.s_tax = self.room_:get_room_tax()
end

function twenty_one_table:is_play(player)
	if player then
		return not player.standby
	end

	log.info("twenty_one_table:is_play")
	return self.status ~= TableStatus.Idle
end

function twenty_one_table:check_start(part)
	local ready_mode = self.room_:get_ready_mode()
    print("twenty_one_table:check_start",ready_mode)

    if self:is_play() then return end

    local n = 0
    self:foreach_ready(function(p) n = n + 1 end)
	if n >= 1 then  
		if not self:start(n) then return end
	end
end

function twenty_one_table:start(player_count)
    log.info(string.format("twenty_one_table:start: %d",player_count))
	if base_table.start(self,player_count) == nil then  return false  end

	self:ready_start()

	return true
end

function twenty_one_table:ready_start()
	self:change_status(TableStatus.ReadyStart)
	self:broadcast2client("SC_ReadyStart",{
		total_wait_time = start_timeout,
		wait_time = start_timeout,
		stoped = 0
	})
	timer_manager:new_timer(start_timeout,function() 
		timer_manager:new_timer(1,function()
			self:real_start_game() 
		end,self.ready_start_timer_delay_name)
	end,self.ready_start_timer_name)
end

function twenty_one_table:stop_ready_start()
	timer_manager:kill_timer(self.ready_start_timer_name)
	timer_manager:kill_timer(self.ready_start_timer_delay_name)
	self:broadcast2client("SC_ReadyStart",{
		total_wait_time = 0,
		wait_time = 0,
		stoped = 1
	})
end

function twenty_one_table:can_enter(player)
	print("twenty_one_table:can_enter")
	local timer = timer_manager:get_timer(self.ready_start_timer_name)
	if timer and timer.remainder < 1 then return false end

    if player.vip == 100 then
		return true
	end
	
	-- body
	for _,v in pairs(self.player_list_) do
        if v and v.guid ~= player.guid then
		    print("===========judge_play_times")
		    if player:judge_ip(v) then
			    if not player.ipControlflag then
				    print("twenty_one_table:can_enter ipcontorl change false")
				    return false
			    else
				    -- ???????? ????
				    print("twenty_one_table:can_enter ipcontorl change true")
				    return true
			    end
		    end
        end
	end

	print("twenty_one_table:can_enter true")
	return true
end

-- ?????????????
function twenty_one_table:check_cancel_ready(player, is_offline)
	print("twenty_one_table:check_cancel_ready",player.guid,((player.bet_amount == 0 and self.status > TableStatus.WaitBet) or self.status <= TableStatus.ReadyStart))
	return (player.bet_amount == 0 and player.standby) or self.status <= TableStatus.ReadyStart
end

function twenty_one_table:change_status(status)
	self.status = status
	if status == TableStatus.Idle then
		self:broadcast2client("SC_TableInfo",{status = self.status})
	end
end

function twenty_one_table:increase_online_player()
    local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)
end

function twenty_one_table:decrease_online_player()
    local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
    log.info(str)
    redis_command(str)
end

-- ???????
function twenty_one_table:player_sit_down(player, chair_id_)
    log.warning(string.format("twenty_one_table:player_sit_down [%d] [%d]",player.guid,chair_id_))
	self.super.player_sit_down(self,player,chair_id_)
    player:reset()
    self:increase_online_player()
end

function twenty_one_table:player_sit_down_finished(player)
    print(string.format("twenty_one_table:player_sit_down_finished",player.guid))
	
	send2client_pb(player,"SC_RoomCfg",{bet_moneies = bet_money_units})

	local cur_money = player.old_money - player.bet_amount - (player.double and player.bet_amount or 0) - (player.security and player.bet_amount or 0)
	if player.sub_player then
		cur_money = cur_money - player.bet_amount - (player.sub_player.double and player.bet_amount or 0)
	end

	self:broadcast2client("SC_PlayerInfo",{
		guid = player.guid,
        chair_id = player.chair_id, 
        status  = player.status,
        pb_cards = nil,
		base_bet_amount = player.bet_amount,
		double = {player.double or 0},
		security_amount = player.security,
		standby = self.status > TableStatus.ReadyStart and player:is_standby() or false,
		cur_money = cur_money
	})
	self:notify_initialized_status_info(player)
end

function twenty_one_table:notify_initialized_status_info(player)
	send2client_pb(player,"SC_TableInfo",{status = self.status})
	self:get_player_infos(player)

	if self.status == TableStatus.ReadyStart then
		local timer = timer_manager:get_timer(self.ready_start_timer_name)
		send2client_pb(player,"SC_ReadyStart",{stoped = 0,total_wait_time = start_timeout,wait_time = (timer and timer.remainder or 0)})
	elseif self.status == TableStatus.WaitBet then
--		local timer = timer_manager:get_timer(self.bet_timer_name)
--		if timer and timer.remainder < 1 then return end

--		local guids = {}
--		local chair_ids = {}
--		self:foreach_not_standby(function(p) 
--			if p.bet_amount == 0 then return end
--			table.push_back(guids,p.guid)
--			table.push_back(chair_ids,p.chair_id)
--		end)
--		send2client_pb(player,"SC_AllowBet",{guid = guids,chair_id = chair_ids,timeout = bet_timeout,
--								time_remainder = timer and timer.remainder or 0})
	elseif self.status == TableStatus.WaitBuySecurity then
		local timer = timer_manager:get_timer(self.buy_security_timer_name)
		if timer and timer.remainder < 1 then return end

		local guids = {}
		local chair_ids = {}
		self:foreach_not_standby(function(p) 
			if p.bet_amount == 0 then return end
			if p.security then return end
			if not self:can_buy_security(p) then return end

			table.push_back(guids,p.guid)
			table.push_back(chair_ids,p.chair_id)
		end)

		self:foreach_not_standby(function(p)
			if p.bet_amount == 0 then return end
			send2client_pb("SC_AllowBuySecurity",{
				guids = guids,chair_ids = chair_ids,timeout = buy_security_timeout,time_remainder = timer and timer.remainder or 0 
			})
		end)
	elseif self.status == TableStatus.WaitOperate then
		local timer = timer_manager:get_timer(self.oper_timer_name)
		if timer and timer.remainder < 1 then return end

		local oper_list = {}
		self:foreach_beted(function(p)  
			table.push_back(oper_list,{guid = p.guid,chair_id = p.chair_id,operations = (p:operations() or nil)})
		end)
		send2client_pb(player,"SC_AllowOperation",{guid = self.cur_operator.guid,chair_id = self.cur_operator.chair_id,cards_index = self.cur_operator.parent and 2 or 1,
			pb_player_operations = oper_list,timeout = operation_timeout,time_remainder = timer and timer.remainder or 0})
	end
end

function twenty_one_table:player_stand_up(player, is_offline)
	local can = base_table.player_stand_up(self,player,is_offline)
	print("twenty_one_table:player_stand_up",player.guid,can)
	if can then
		player:reset()
		log.warning(string.format("twenty_one_table:player_stand_up normally [%d]",player.guid))
		if self:get_player_count() == 0 then
			dump("lidasoijfdiolajfodsajfdlkjklfjdaiojfd")
			self:change_status(TableStatus.Idle)
			self:stop_ready_start()
		end

		self:decrease_online_player()

		return true
	end

	player.trusteeship = true
	return false
end

function twenty_one_table:ready(player)
    log.info(string.format("twenty_one_table:ready [%d]",player.guid))
    player.status = PlayerStatus.ReadyStart
    player.trusteeship = false
    base_table.ready(self,player)
	self:notify_initialized_status_info(player)
end

function twenty_one_table:can_buy_security(p)
	return logic.card_number(self.banker.cards[1]) == 1 and (p and p:get_money() - (p.bet_amount * 1.5)) >= 0
end

function twenty_one_table:begin_buy_security()
	print("twenty_one_table:begin_buy_security")
	timer_manager:new_timer(buy_security_timeout,function()
		print("buy security timeout")
		self:foreach_beted(function(p)  
			if not p.security and self:can_buy_security(p) then 
				self:on_buy_security(p,true) 
			end
		end)
	end,self.buy_security_timer_name)

	self.allow_operations = {Operation.BuySecurity}
	local guids = {}
	local chair_ids = {}
	self:foreach_beted(function(p)  
		table.push_back(guids,p.guid)
		table.push_back(chair_ids,p.chair_id)
	end)

	self:foreach_beted(function(p)
		if self:can_buy_security(p) then
			send2client_pb(p,"SC_AllowBuySecurity",{
				guids = guids,chair_ids = chair_ids,timeout = buy_security_timeout,time_remainder = buy_security_timeout 
			})
		end
	end)

	self:change_status(TableStatus.WaitBuySecurity)
end

function twenty_one_table:next_player_and_opers(current_operator)
	if current_operator then 
		local ops = current_operator:operations()
		if ops then 
			print(string.format("twenty_one_table:next_player_and_opers [%d] switch to next player",current_operator.guid))
			return current_operator,ops 
		end

		if current_operator.sub_player then
			ops = current_operator.sub_player:operations()
			if ops then return current_operator.sub_player,ops end
		end
	end

	local cur = nil
	local opers = nil
	table.elements_or_operation(self.player_list_,function(p,k) 
		if not p or p.bet_amount == 0 then return false end

		local tmp_oper = nil
		if current_operator == nil then 
			tmp_oper = p
		elseif current_operator:real_chair_id() < p:real_chair_id() then
			tmp_oper = p
		end

		if not tmp_oper then  return false  end

		local ops = tmp_oper:operations()
		if not ops then return false  end

		cur = tmp_oper
		opers = ops
		return true
	end)

	return cur,opers
end

function twenty_one_table:next_operation()	
	timer_manager:kill_timer(self.oper_timer_name)

	if self.cur_operator ~= self.banker then
		local current_operator,operations = self:next_player_and_opers(self.cur_operator)
		if current_operator and operations then
			self:begin_operations(current_operator,operations)
			return
		end
	end
	
	local operations = self.banker:operations()
	if operations then
		dump(operations,"self.banker:operations")
		self:begin_banker_operations(operations)
		return
	end
		
	self:balance()
end

function twenty_one_table:do_operation(player,opers)
	if player and opers then
		self:begin_operations(player,opers)
		return
	end

	local operations = self.banker:operations()
	if operations then
		dump(operations,"self.banker:operations")
		self:begin_banker_operations(operations)
		return
	end

	self:balance()
end

function twenty_one_table:on_operation(player,msg)
	print("twenty_one_table:on_operation",player.guid)
	if player.standby and not player.sub_player then
		log.warning(string.format("twenty_one_table:on_operation standby player guid[%d]",player.guid))
		return 
	end

	if msg.operation == Operation.BuySecurity then
		if self.status ~= TableStatus.WaitBuySecurity then
			log.warning(string.format("twenty_one_table:on_operation buy security when table is not on WaitBuySecurity [%d]",player.guid))
			return
		end

        self:on_buy_security(player,msg.is_cancel ~= 0)
	else
		if self.status ~= TableStatus.WaitOperate then
			log.warning(string.format("twenty_one_table:on_operation operate when table is not on WaitOperate [%d]",player.guid))
			return
		end

		if not self.cur_operator  then
			log.warning(string.format("twenty_one_table:on_operation cur_operator got nil,player [%d]",player.guid))
			return 
		end

		if player ~= self.cur_operator and player.sub_player ~= self.cur_operator then 
			log.warning(string.format("twenty_one_table:on_operation cur_oper ~= player,cur[%d] player[%d]",self.cur_operator.guid,player.guid))
			return 
		end

		if self.cur_operator == player.sub_player then  player = player.sub_player end

		dump(self.allow_operations)
		if not table.elements_or_operation(self.allow_operations,function(v,k) return v == msg.operation end) then
			log.warning(string.format("twenty_one_table:on_operation not check right  [%d]",player.guid))
			return
		end

		self.allow_operations = {}
		timer_manager:kill_timer(self.oper_timer_name)

		print("operation",msg.operation)
		if msg.operation == Operation.Hit then
			self:on_hit(player,false)
		end

		if msg.operation == Operation.Double then
			self:on_hit(player,true)
		end

		if msg.operation == Operation.Stand then
			self:on_stand(player)
		end

		if msg.operation == Operation.Surrender then
			self:on_surrender(player)
		end

		if msg.operation == Operation.SplitCard then
			self:on_split_cards(player)
		end

		self:end_operations(player,{Operation.Stand,Operation.Hit,Operation.SplitCard,Operation.Surrender,Operation.Double})

		timer_manager:new_timer(operation_interval_wait_time,function()
			if self:can_balance() then
				self:balance()
				return
			end

			if self:can_balance(player) then
				local opers = nil
				local p = nil
				p,opers = self:next_player_and_opers(player)
				self:balance_player(player)
				timer_manager:new_timer(balance_player_timeout,function()  self:do_operation(p,opers) end)
			elseif self:can_balance() then
				self:balance()
			else
				timer_manager:new_timer(operation_time_interval,function()
					self:next_operation()
				end)
			end
		end)
	end
end

function twenty_one_table:on_hit(player,double)
	local card = 0
	if player.is_kill_score then
		if player == self.banker then 
			dump("lkdsaofijdsakjfoeijjfjdlasjk;dfkpafdi")
		end
		card = self.card_dealer:deal_one_by_condition(function(c) 
			local cards = clone(player.cards)
			table.push_back(cards,c)
			local num_sum = logic.get_cards_number(cards)
			if #cards == 5 then return num_sum == 0 end
			return (num_sum > 11 and num_sum < 15 and c % 15 ~= 1) or num_sum == 0
		end)
		if card == 0 then
			card = self.card_dealer:deal_one()
		end
	else
		card = self.card_dealer:deal_one()
	end

--	if player.chair_id == 0 then
--		card = self.card_dealer:deal_one_by_condition(function(c)  
--			if logic.get_cards_number(player.cards) < 11 then
--				return c % 15 < 7
--			end
--			return logic.get_cards_number(player.cards) +  logic.card_number(c) == 21 
--		end)
--		if card == 0 then
--			card = self.card_dealer:deal_one()
--		end
--	else
--		card = self.card_dealer:deal_one_by_condition(function(c)  
--			if logic.get_cards_number(player.cards) < 11 then
--				return c % 15 < 10
--			end
--			return logic.get_cards_number(player.cards) +  logic.card_number(c) == 21 
--		end)
--		if card == 0 then
--			card = self.card_dealer:deal_one()
--		end
--	end

	table.push_back(player.cards,card)
	print("twenty_one_table:on_hit   "..to_string(player.guid).."  "..to_string(player.cards).."  ".. to_string(logic.get_cards_number(player.cards)))
	local notify = {guid = player.guid,chair_id = player:real_chair_id(),card = card}
    if double then 
		notify.double_amount = player.bet_amount
		player.double = player.bet_amount
	else
		notify.double_amount = 0
	end
    
	if logic.is_bomb(player.cards) then
		print("twenty_one_table:on_hit   ["..to_string(player.guid).."]is bomb  ["..to_string(player.cards).."]  "  .. to_string(logic.get_cards_number(player.cards)))
		player.bomb = true
		player.status = PlayerStatus.Bomb
		notify.bomb = 1 
	else
		if logic.get_cards_number(player.cards) == 21 then
			player.stand = true
		end
		notify.bomb = 0
	end
	
    self:broadcast2client("SC_Hit",notify)
end

function twenty_one_table:on_surrender(player)
    player.surrender = true
	player.status = PlayerStatus.Surrender
    self:broadcast2client("SC_OperatorReply",{chair_id = player:real_chair_id(),guid = player.guid,operation = Operation.Surrender,succeed = true})
end

function twenty_one_table:on_buy_security(player,is_cancel)
	print("twenty_one_table:on_buy_security",player.guid,is_cancel)
	if player.security ~= nil then
		send2client_pb(player,"SC_OperatorReply",{operation = Operation.BuySecurity,succeed = false})
		return
	end

	if is_cancel then 
		player.security = 0
		self:broadcast2client("SC_BuySecurity",{guid = player.guid,chair_id = player.chair_id,amount = 0})
	else
		local amount = math.floor(player.bet_amount * 0.5)
		player.security = amount
		self:broadcast2client("SC_BuySecurity",{guid = player.guid,chair_id = player.chair_id,amount = amount})
	end

	if self:foreach_and_oper_result(function(p) 
		return not p or p.standby or not self:can_buy_security(p) or (p.bet_amount > 0 and p.security ~= nil)
	end) 
	then
		log.info("finish buy security....")
		timer_manager:kill_timer(self.buy_security_timer_name)
		
		self:balance_security()

		local function after_balance_security()
			if self:can_balance() then 
				self:open_banker_cards()
				timer_manager:new_timer(banker_blackjack_wait_balance,function() self:balance() end)
			else
				local is_balance_player = false
				self:foreach_beted(function(p) 
					if self:can_balance(p) then 
						print("black jack balance ",p.guid)
						is_balance_player = true
						self:balance_player(p) 
					end
				end)

				if is_balance_player then
					timer_manager:new_timer(balance_player_timeout,function()  self:next_operation() end)
				else
					self:next_operation() 
				end

				self:change_status(TableStatus.WaitOperate) 
			end
		end

		if table.elements_or_operation(self.player_list_,function(p) return p and p.bet_amount > 0 and p.security and p.security > 0 end) then
			timer_manager:new_timer(buy_security_wait_timeout,function() after_balance_security() end)
		else
			after_balance_security()
		end
	end
end

function twenty_one_table:on_split_cards(player)
	local sub_player = player:create_sub_player()
    sub_player.cards[1] = player.cards[2]
	player.cards[2] = self.card_dealer:deal_one()
	sub_player.cards[2] = self.card_dealer:deal_one()
	self:broadcast2client("SC_SplitCard",{guid = player.guid,chair_id = player:real_chair_id(),pb_cards = {{cards = player.cards},{cards = sub_player.cards}}})
end

function twenty_one_table:on_stand(player)
    player.stand = true
	player.status = PlayerStatus.Stand
    self:broadcast2client("SC_OperatorReply",{guid = player.guid,chair_id = player:real_chair_id(),operation = Operation.Stand,succeed = true})
end

function twenty_one_table:on_bet(player,msg)
	if self.status ~= TableStatus.WaitBet then
		log.warning(string.format("twenty_one_table:on_bet self.status ~= TableStatus.WaitBet guid[%d]",player.guid))
		return 
	end

	if player.standby then
		log.warning(string.format("twenty_one_table:on_bet standby player guid[%d]",player.guid))
		return 
	end

	if not table.elements_or_operation(bet_money_units,function(cell) return cell == msg.amount end) then
		log.warning(string.format("twenty_one_table:on_bet bet amount not in bet_money_units guid[%d] [%d]",player.guid,msg.amount))
		return
	end

	log.info(string.format("twenty_one_table:on_bet guid[%d] [%d]",player.guid,player.bet_amount + msg.amount))
    player.bet_amount = msg.amount
    
    self:broadcast2client("SC_Bet",{guid = player.guid,chair_id = player.chair_id,amount = player.bet_amount})

	if table.elements_and_operation(self.player_list_,function(p) return not p or p.standby or p.bet_amount > 0 end) then
		timer_manager:kill_timer(self.bet_timer_name)
		print("end bet...............")
        self:end_bet()

        if self:total_bet_amount() == 0 then  
			print("total bet amount is 0,game_end")
			self:game_over()  
			return
		end

		self:deal_cards()

		local deal_cards_player_counts = self:get_beted_player_count()

		timer_manager:new_timer((deal_cards_player_counts + 1) * deal_one_card_time * 2,function()
			if	table.elements_or_operation(self.player_list_,function(p)  return p and p.bet_amount > 0 and self:can_buy_security(p) end) then 
				self:begin_buy_security()
			else 
				if self:can_balance() then
					self:balance()
					return
				end

				self:foreach_beted(function(p)  
					if self:can_balance(p) then self:balance_player(p) end 
				end)

				self:change_status(TableStatus.WaitOperate) 
				self:next_operation()
			end
		end)
	end
end


function twenty_one_table:can_balance(player)
	if player then
		return player:can_balance_immediately() 
	end

	local can_balance_normal = self:foreach_and_oper_result(function(p)
			if not p then return true end
			local can =  p:is_stop_operation() or p.stand
			if p.sub_player then can = can and (p.sub_player:is_stop_operation() or p.sub_player.stand) end
			if p.parent then can = can and (p.parent:is_stop_operation() or p.parent.stand)end
			return can
		end)
	
	local can_balance_immediately = self:foreach_and_oper_result(function(p)
		if not p then return true end
		local can = p:can_balance_immediately()
		if p.sub_player then can = can and p.sub_player:can_balance_immediately() end
		if p.parent then can = can and p.parent:can_balance_immediately() end
		return can
	end)

	return logic.is_blackjack(self.banker.cards) or can_balance_immediately or (can_balance_normal and  self.banker:is_stop_operation())
end

function twenty_one_table:get_player_infos(player,msg)
	local infos = {}
    self:foreach(function(p) 
			local cur_money = p.old_money - p.bet_amount - (p.double and p.bet_amount or 0) - (p.security and p.bet_amount or 0)
			if p.sub_player then
				cur_money = cur_money - p.bet_amount - (p.sub_player.double and p.bet_amount or 0)
			end
            local info = {
				guid = p.guid,
                chair_id = p.chair_id, 
                status  = p.status,
                pb_cards = self.status > TableStatus.WaitBet and {{cards = p.cards}} or nil,
				base_bet_amount = p.bet_amount,
				double = {p.double or 0},
				security_amount = p.security,
				standby = self.status > TableStatus.ReadyStart and p:is_standby() or false,
				cur_money = cur_money
            }

			if p.sub_player then 
				if info.pb_cards then info.pb_cards[2] = {cards = p.sub_player.cards} end
				info.double[2] = p.sub_player.double or 0
			end

			infos[#infos + 1] = info
    end)

	infos[#infos + 1] = {
		guid = 0,
        chair_id = 0, 
        status  = self.banker.status,
        pb_cards = self.status > TableStatus.WaitBet and {{cards = {self.banker.cards[1],0}}} or nil,
		base_bet_amount = self.banker.bet_amount,
		double = {0},
		security_amount = 0,
		standby = false,
		cur_money = 0
    }

	send2client_pb(player,"SC_PlayerInfos",{pb_infos = infos})
end


function twenty_one_table:reconnection_play_msg(player)
    log.info(string.format("twenty_one_table:reconnect %d",player.guid))
	player.trusteeship = false
	base_table.reconnection_play_msg(self,player)

    self:foreach(function(p)
	    local notify = {
		    table_id = p.table_id,
		    pb_visual_info = {
			    chair_id = p.chair_id,
			    guid = p.guid,
			    account = p.account,
			    nickname = p.nickname,
			    level = p:get_level(),
			    money = p:get_money(),
			    header_icon = p:get_header_icon(),				
			    ip_area = p.ip_area,
		    },
		    is_onfline = true,
	    }

	    print("ip_area--------------------A",  p.ip_area)
	    print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
	    player:on_notify_sit_down(notify)
    end)
	send2client_pb(player,"SC_RoomCfg",{bet_moneies = bet_money_units})
	self:notify_initialized_status_info(player)
end

function twenty_one_table:total_bet_amount()
    local amount = 0
    self:foreach_ready(function(p)  amount = amount + p.bet_amount + (p.sub_player and p.sub_player.bet_amount or 0) end)
	print("total bet amount",amount)
    return amount
end

function twenty_one_table:real_start_game()
	log.info(string.format("twenty_one_table:real_start_game [%s]",self:get_now_game_id()))
	self:foreach_ready(function(p) 
		p.standby = false  
	end)



	self.banker.standby = false
	
	self.game_start_time = get_second_time()
    self:begin_bet()
end


function twenty_one_table:balance_moneies(player)
	local function balance_score_with_banker_cards(p)
		if not p or #p.cards == 0 then return 0 end

		local type_p = self:get_player_cards_type(p)
		local type_banker = self:get_player_cards_type(self.banker)

		if type_p.i > type_banker.i then return type_p.score  end
		if type_p.i < type_banker.i then return -1 end
		
		if type_p ~= logic.CardsType.Normal then return 0 end

		local cards_p_number = logic.get_cards_number(p.cards)
		local cards_banker_number = logic.get_cards_number(self.banker.cards)
		if cards_p_number > cards_banker_number then return 1 end
		if cards_p_number < cards_banker_number then return -1 end

		return 0
	end

	local function balance_with_banker(p)
		if not p then return 0 end

		if p1 == self.banker or p.bet_amount == 0 then 
			return 0 
		end

		if p.bomb then 
			return -((p.double or 0) + p.bet_amount) 
		end

		if p.surrender then
			return -(p.bet_amount + (p.double or 0)) / 2
		end

		return balance_score_with_banker_cards(p) * (p.bet_amount + (p.double or 0))
	end

	if not player then
		self:foreach(function(p)  
			if not p then return end
			if p.bet_amount == 0 and (not p.sub_player or p.sub_player.bet_amount == 0) then return end

			self:balance_moneies(p)
			if p.sub_player then self:balance_moneies(p.sub_player) end
		end)
	else
		if player.balance_money then return end
		player.balance_money = balance_with_banker(player)
	end
end

function twenty_one_table:caculate_tax(money)
	local l_tax = 0
	if money > 0 then 
		l_tax = money * self.s_tax
		l_tax = l_tax < 1 and 0 or math.floor(l_tax + 0.5)
	end
	return l_tax
end

function twenty_one_table:balance_security_money(p)
	if p.bet_amount == 0 or not p.security or p.security == 0 then return 0 end

	if self:get_player_cards_type(self.banker) == logic.CardsType.BlackJack then
		p.balance_security_money = p.security or 0
	else
		p.balance_security_money = -p.security or 0
	end
end

function twenty_one_table:balance_security()
	self:foreach_condition_oper(function(p)
		return self.ready_list_[p.chair_id] and p.bet_amount > 0 and p.security and p.security > 0
	end,function(p) 
		self:balance_security_money(p)
		self:broadcast2client("SC_PlayerScurityBalance",{chair_id = p.chair_id,guid = p.guid,security_money = p.balance_security_money})
		p.cur_money = p.cur_money + p.balance_security_money
		self.game_log.players[p.chair_id].security_balance = p.balance_security_money
	end)
end

function twenty_one_table:balance_player(player)
	print("twenty_one_table:balance_player")

	self:end_operations(player,{Operation.Double,Operation.Hit,Operation.SplitCard,Operation.Stand,Operation.Surrender})

	self:balance_moneies(player)

	log.warning(string.format("balance player [%d] [%d] [%d]",player.guid,player.chair_id,player.balance_money))
	
	self.game_log.players[player.chair_id] = {
		guid = player.guid,
		cards = player.cards,
		diff_money = player.balance_money,
		bet = player.bet_amount,
		double = player.double or 0,
		security = player.security or 0,
		surrender = player.surrender,
		bomb = player.bomb,
		security_balance = player.balance_security_money,
		points = logic.get_cards_number(player.cards),
		type = self:get_player_cards_type(player).i
	}

	if not player.sub_player and not player.parent then
		local l_money = player.balance_money
		local l_tax = self:caculate_tax(l_money)
		l_money = l_money - l_tax
		local cur_money = player.cur_money + l_money
		l_money = l_money + player.balance_security_money

		self:broadcast2client("SC_PlayerBalance",{
			guid = player.guid,chair_id = player:real_chair_id(),tax = l_tax,money = player.balance_money - l_tax,cur_money = cur_money,
			card_index = 1,bet_amount = player.bet_amount + (player.double or 0),
			show_tax = self.room_.tax_show_ ~= 0
		})

		self.game_log.players[player.chair_id].total_balance = l_money
		self.game_log.players[player.chair_id].tax = l_tax

		if l_money > 0 then
			player:add_money(
				{{ money_type = ITEM_PRICE_TYPE_GOLD, money = l_money }}, 
				LOG_MONEY_OPT_TYPE_TWENTY_ONE
			)

			--?????limit??????????
			if l_money >= broadcast_cfg.money then
				broadcast_world_marquee(def_first_game_type,def_second_game_type,0,player.nickname,string.format("%.02f",l_money / 100))
			end
		elseif l_money < 0 then
			player:cost_money(
				{{ money_type = ITEM_PRICE_TYPE_GOLD, money = -l_money }}, 
				LOG_MONEY_OPT_TYPE_TWENTY_ONE
			)
		end

		self:player_bet_flow_log(player,player.bet_amount)

		if l_money ~= 0 then 
			self:player_money_log(player,l_money > 0 and 2 or 1,player.old_money,l_tax,l_money,self:get_now_game_id()) 
		end

		player:allow_stand_up()
		return
	end

	player.cur_money = player.cur_money + player.balance_money
	self:broadcast2client("SC_PlayerBalance",{
			guid = player.guid,chair_id = player:real_chair_id(),tax = 0,money = player.balance_money,cur_money = player.cur_money,
			card_index = player.chair_id < 0 and 2 or 1,bet_amount = player.bet_amount + (player.double or 0)
	})

	if	(player.sub_player and player.sub_player.balance_money) or 
		(player.parent and player.parent.balance_money) 
	then
		local l_money = player.balance_money
		l_money = l_money + (player.sub_player and player.sub_player.balance_money or 0)
		l_money = l_money + (player.parent and player.parent.balance_money or 0)
		l_money = l_money + player.balance_security_money

		dump(l_money)

		self.game_log.players[player.chair_id].total_balance = l_money
		self.game_log.players[player.chair_id].tax = l_tax

		if l_money > 0 then
			player:add_money(
				{{ money_type = ITEM_PRICE_TYPE_GOLD, money = l_money }}, 
				LOG_MONEY_OPT_TYPE_TWENTY_ONE
			)

			--?????limit??????????
			if l_money >= broadcast_cfg.money then
				broadcast_world_marquee(def_first_game_type,def_second_game_type,0,player.nickname,string.format("%.02f",l_money / 100))
			end
		elseif l_money < 0 then
			player:cost_money(
				{{ money_type = ITEM_PRICE_TYPE_GOLD, money = -l_money }}, 
				LOG_MONEY_OPT_TYPE_TWENTY_ONE
			)
		end

		self:player_bet_flow_log(player,player.bet_amount)
		
		if l_money ~= 0 then 
			self:player_money_log(player,l_money > 0 and 2 or 1,player.old_money,0,l_money,self:get_now_game_id()) 
		end
	end

	player:allow_stand_up()
end

function twenty_one_table:balance()
	print("twenty_one_table:balance")
	self:open_banker_cards()
	self:end_operations(self.cur_operator or self.banker,{Operation.Double,Operation.Hit,Operation.SplitCard,Operation.Stand,Operation.Surrender})

	self:balance_moneies()

	local balance_infos = {}
	self:foreach(function(p)
		if p.standby and (not p.sub_player or (p.sub_player and p.sub_player.standby)) then return end

		local old_money = p:get_money()

		local balance_card_index_1 = nil
		local balance_card_index_2 = nil

		if not p.standby then
			balance_card_index_1 = {
				guid = p.guid,chair_id = p.chair_id,
				tax = 0,money = p.balance_money,
				cur_money = 0,
				bet_amount = p.bet_amount + (p.double or 0),
				card_index = 1,
				show_tax = self.room_.tax_show_ ~= 0}

			self.game_log.players[p.chair_id] = {
				guid = p.guid,cards = p.cards,
				diff_money = p.balance_money,
				bet = p.bet_amount,
				double = p.double or 0,
				security = p.security or 0,
				surrender = p.surrender,
				bomb = p.bomb,
				security_balance = p.balance_security_money,
				points = logic.get_cards_number(p.cards),
				type = self:get_player_cards_type(p).i
			}
		end

		if p.sub_player and not p.sub_player.standby then
			local sub_p = p.sub_player
			balance_card_index_2 = {
				guid = p.guid,chair_id = p.chair_id,
				tax = 0,money = sub_p.balance_money,
				cur_money = 0,
				bet_amount = sub_p.bet_amount + (sub_p.double or 0),
				card_index = 2,
				show_tax = self.room_.tax_show_ ~= 0}

			self.game_log.players[-p.chair_id] = {
				guid = p.guid,cards = sub_p.cards,
				diff_money = sub_p.balance_money,
				bet = sub_p.bet_amount,
				double = sub_p.double or 0,
				security = sub_p.security or 0,
				surrender = sub_p.surrender,
				bomb = sub_p.bomb,
				points = logic.get_cards_number(sub_p.cards),
				type = self:get_player_cards_type(sub_p).i
			}
		end

		local l_money = p.balance_money + (p.sub_player and p.sub_player.balance_money or 0)
		local l_tax = self:caculate_tax(l_money)
		local l_total_balance = l_money + p.balance_security_money - l_tax
		local cur_money = p.old_money + l_total_balance

		if balance_card_index_1 then  
			balance_card_index_1.tax = l_tax / (p.sub_player and 2 or 1)
			balance_card_index_1.money = balance_card_index_1.money - balance_card_index_1.tax
			balance_card_index_1.cur_money = cur_money
			table.push_back(balance_infos,balance_card_index_1) 
		end

		if balance_card_index_2 then 
			balance_card_index_2.tax = l_tax / (p.sub_player and 2 or 1)
			balance_card_index_2.money = balance_card_index_2.money - balance_card_index_2.tax
			balance_card_index_2.cur_money = cur_money
			table.push_back(balance_infos,balance_card_index_2) 
		end
		
		log.warning(string.format("player change money [%d] [%d] [%d] [%d]",p.guid,p.chair_id,l_total_balance or 0,l_tax or 0))

		dump(l_total_balance)
		dump(l_tax)

		p.tax = l_tax
		p.total_balance = l_total_balance

		self.game_log.players[p.chair_id].total_balance = l_total_balance
		self.game_log.players[p.chair_id].tax = l_tax

		self:player_bet_flow_log(p,p.bet_amount)
		
		if l_total_balance > 0 then
			p:add_money(
				{{ money_type = ITEM_PRICE_TYPE_GOLD, money = l_total_balance}}, 
				LOG_MONEY_OPT_TYPE_TWENTY_ONE
			)

			--?????limit??????????
			if l_total_balance >= broadcast_cfg.money then
				broadcast_world_marquee(def_first_game_type,def_second_game_type,0,p.nickname,string.format("%.02f",l_total_balance / 100))
			end
		elseif l_total_balance < 0 then
			p:cost_money(
				{{ money_type = ITEM_PRICE_TYPE_GOLD, money = -l_total_balance }}, 
				LOG_MONEY_OPT_TYPE_TWENTY_ONE
			)
		end

		if l_total_balance ~= 0 then
			self:player_money_log(p,l_total_balance > 0 and 2 or 1,p.old_money,l_tax,l_total_balance,self:get_now_game_id()) 
		end
	end)

	self.game_log.players[0] = {guid = 0,cards = self.banker.cards,bomb = self.banker.bomb}
	self:broadcast2client("SC_Balance",{pb_balances = balance_infos})

	dump(balance_infos)

	dump(self.game_log)
	local s_log = json.encode(self.game_log)
	log.warning(s_log)
	self:save_game_log(self:get_now_game_id(),def_game_name,s_log,self.game_start_time,get_second_time())
	self:next_game()

	self:change_status(TableStatus.WaitBalance)

	self:foreach(function(p) 
		self:save_player_collapse_log(p)
	end)

	timer_manager:new_timer(balance_timeout,function()  
		print("balance wait timeout")
		self:game_over()
	end)
end

function twenty_one_table:get_player_cards_type(p)
	local type = logic.get_cards_type(p.cards)
	if (p.parent or p.sub_player)  and type == logic.CardsType.BlackJack then
		return logic.CardsType.Normal
	end

	return type
end

function twenty_one_table:begin_bet()
	log.info("twenty_one_table:begin_bet")
	timer_manager:kill_timer(self.bet_timer_name)

	local guids = {}
	local chair_ids = {}
	self:foreach_not_standby(function(p)
		guids[#guids + 1] = p.guid
		chair_ids[#chair_ids + 1] = p.chair_id
		p.status = PlayerStatus.Bet
	end)

	self:broadcast2client("SC_AllowBet",{guid = guids,chair_id = chair_ids,timeout = bet_timeout,time_remainder = bet_timeout})
	
	self:change_status(TableStatus.WaitBet)

	timer_manager:new_timer(bet_timeout,function() 
		self:foreach_not_standby(function(p) 
			if p.bet_amount == 0 then self:on_bet(p,{amount = bet_money_units[1]}) end
		end)
    end,self.bet_timer_name)
end

function twenty_one_table:open_banker_cards()
	if not self.banker.is_open_cards then
		print("banker open cards")
		self:broadcast2client("SC_PlayerOpenCards",{guid = 0,chair_id = 0,cards_index = 1, cards = self.banker.cards})
		self.banker.is_open_cards = true
	end
end

function twenty_one_table:begin_banker_operations(opers)
	log.warning("twenty_one_table:begin_operations banker operation")
	self:open_banker_cards()
	local current_operator = self.cur_operator
	self.cur_operator = self.banker
	self.allow_operations = opers
	local oper = self.banker:robot_operations()
	if oper == false then   
		self:balance()
		return
	end
	if current_operator ~= self.banker then
		self:on_operation(self.banker,{operation = oper})
	else
		timer_manager:new_timer(banker_operation_time_interval,function()
			self:on_operation(self.banker,{operation = oper})
		end)
	end

end

function twenty_one_table:begin_operations(player,opers)
	self.cur_operator = player
	log.warning(string.format("twenty_one_table:begin_operations [%d] %s",player.guid,to_string(opers)))

	timer_manager:new_timer(operation_timeout,function()
		self:on_operation(player,{operation = Operation.Stand})
		print("timer_oper timeout",player.guid,player.chair_id)
	end,self.oper_timer_name)

	print("begin_operations(player,opers)",player.guid,player.chair_id,player.parent and 2 or 1)

	local oper_list = {}
	self:foreach(function(p)
		if p.bet_amount == 0 then
			if not p.sub_player or p.sub_player.bet_amount == 0 then return end
			if p.chair_id == player:real_chair_id() then 
				table.push_back(oper_list,{guid = p.guid,chair_id = p.chair_id,operations = opers}) 
				return
			end
			
			table.push_back(oper_list,{guid = p.guid,chair_id = p.chair_id,operations = (p.sub_player:operations() or nil)})
			return
		end
		if p.chair_id == player:real_chair_id() then 
			table.push_back(oper_list,{guid = p.guid,chair_id = p.chair_id,operations = opers}) 
			return
		end
		table.push_back(oper_list,{guid = p.guid,chair_id = p.chair_id,operations = (p:operations() or nil)})
	end)

	self.allow_operations = opers

	self:broadcast2client("SC_AllowOperation",{
		pb_player_operations = oper_list,timeout = operation_timeout,time_remainder = operation_timeout,
		guid = player.guid,chair_id = player:real_chair_id(),cards_index = (player.chair_id < 0 and 2 or 1)
	})
end


function twenty_one_table:end_operations(player,opers)
	self:broadcast2client("SC_DisallowOperation",{guid = player.guid,chair_id = player:real_chair_id(),operations = opers,cards_index = player.parent and 2 or 1})
end

function twenty_one_table:end_bet()
    self:broadcast2client("SC_DisallowOperation",{guid = -1,chair_id = -1,cards_index = 1,operations = {Operation.Bet}})
end

function twenty_one_table:on_exception(ex_msg)
	log.error(ex_msg)
	self:foreach(function(p) 
		p:reset()
		p:forced_exit() 
	end)
	self.banker:reset()
	self:reset()
	self:change_status(TableStatus.Idle)
end

function twenty_one_table:deal_cards()
    print("twenty_one_table:deal_cards_start_game")
    self:foreach_beted(function(p) 
        p.status = PlayerStatus.WaitHit
        p.cards = {}
        self.game_log.players[p.chair_id] = {}
    end)

	self:change_status(TableStatus.DealCards)
    self.card_dealer:shuffle()

	dump(kill_points_prob)
	local player_balckjack_count = 0
	if kill_points_prob.player_blackjack_count > 0 then 
		player_balckjack_count = math.random(kill_points_prob.player_blackjack_count)
	end
	dump(player_balckjack_count)
    local function deal_player_cards(p)
        local p_cards = {} 

		if math.random(10000) <= kill_points_prob.player_kill_prob and p ~= self.banker then
			p.is_kill_score = true
			local card = self.card_dealer:deal_one_by_condition(function(c) return c % 15 ~= 1 end)
			p_cards = {card,self.card_dealer:deal_one_by_condition(function(c) 
				local card_sum = logic.get_cards_number({card,c})
				return card_sum < 15 and c % 15 ~= 1
			end)}
		else
			if p == self.banker then
				local x = math.random(10000)
				if x > 0 and x <= kill_points_prob.banker_blackjack_prob[1] then
					p_cards = {	self.card_dealer:deal_one_by_condition(function(c) return c % 15 >= 10 end),
										self.card_dealer:deal_one_by_condition(function(c) return c % 15 == 1 end)}
				elseif x > kill_points_prob.banker_blackjack_prob[1] and 
						x <= kill_points_prob.banker_blackjack_prob[1] + kill_points_prob.banker_blackjack_prob[2] 
				then
					p_cards = {	self.card_dealer:deal_one_by_condition(function(c) return c % 15 == 1 end),
										self.card_dealer:deal_one_by_condition(function(c) return c % 15 >= 10 end)}
				else
					p_cards = self.card_dealer:deal_cards(2)
				end
			else
				if player_balckjack_count >= 0 then
					local x = math.random(10000)
					if logic.is_blackjack(self.banker.cards) then
						if x > 0 and x <= kill_points_prob.player_blackjack_prob[1] then
							p_cards = {	self.card_dealer:deal_one_by_condition(function(c) return c % 15 >= 10 end),
												self.card_dealer:deal_one_by_condition(function(c) return c % 15 == 1 end)}
						else
							p_cards = self.card_dealer:deal_cards(2)
						end
					else
						if	x > kill_points_prob.player_blackjack_prob[1] and 
							x <= kill_points_prob.player_blackjack_prob[1] + kill_points_prob.player_blackjack_prob[2] 
						then
							p_cards = {	self.card_dealer:deal_one_by_condition(function(c) return c % 15 >= 10 end),
												self.card_dealer:deal_one_by_condition(function(c) return c % 15 == 1 end)}
						else
							p_cards = self.card_dealer:deal_cards(2)
						end
					end

					player_balckjack_count = player_balckjack_count - 1
				else
					local x = math.random(10000)
					if x >= 0 and x < kill_points_prob.player_no_aice_double_prob then
						local c1 = self.card_dealer:deal_one_by_condition(function(c) return c % 15 ~= 1 end)
						local c2 = self.card_dealer:deal_one_by_condition(function(c) return c % 15 == c1 % 15 end)
						p_cards = {c1,c2}
					else
						p_cards = self.card_dealer:deal_cards(2)
					end
				end
			end

		end

--		if p.chair_id == 1 then
--			local card = self.card_dealer:deal_one()
--			p_cards = {card, self.card_dealer:deal_one_by_condition(function(c) return c % 15 == card % 15 end)} 
--		elseif p.chair_id == 2 then
--			local card = self.card_dealer:deal_one_by_condition(function(c) return c % 15 == 1 end)
--			p_cards = {card, self.card_dealer:deal_one_by_condition(function(c) return c % 15 >= 10 end)} 
--		elseif p.chair_id == 0 then
--			local card = self.card_dealer:deal_one_by_condition(function(c) return c % 15 == 1 end)
--			p_cards = {card, self.card_dealer:deal_one_by_condition(function(c) return c % 15 < 10 end)} 
--		end

        log.info(string.format("deal_cards,guid:%d,cards:%s",p.guid,to_string(p_cards)))
        p.cards = p_cards

		return p_cards
    end

	local player_cards = {}
	local banker_cards = deal_player_cards(self.banker)
	table.push_back(player_cards,{guid = 0,chair_id = 0,cards = {banker_cards[1],0}})

	self:foreach_beted(function(p)
		table.push_back(player_cards,{guid = p.guid,chair_id = p.chair_id,cards = deal_player_cards(p)})
	end)

	self:broadcast2client("SC_DealCards",{pb_cards = player_cards})
end

function twenty_one_table:game_over()
	self:foreach(function(p)
		p:allow_stand_up()
		if p.trusteeship then 
			log.warning(string.format("offline kick out,guid:[%d]",p.guid))
			p:forced_exit() 
		end
	end)

	self:foreach(function(p)
		p:check_forced_exit(self.room_:get_room_limit())
	end)

	self:change_status(TableStatus.Idle)
	self:check_single_game_is_maintain()
	self:foreach(function(p) p:reset() end)
	self.banker:reset()
	self:reset()
	self:clear_ready()
end