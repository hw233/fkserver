require "functions"
local base_table = require "game.lobby.base_table"
require "game.lobby.base_player"
require "game.shelongmen.config"
require "game.timer_manager"
require "game.shelongmen.define"
local card_dealer = require("game/card_dealer")

local pb = require "pb"
local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local LOG_MONEY_OPT_TYPE_SHELONGMEN = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_SHELONGMEN")

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local redis_command = redis_command

local kick_offline_player_tick_time = 1

local idle_timeout = 3
local bet_timeout = 20
local game_over_timeout = 10
local update_bet_info_timeout = 1

function base_player:reset()
	self.bet = {area = {},total = 0}
	self.profit = 0
	self.tax = 0
end

function base_player:is_standby()
	return self.standby
end

function base_player:on_bet(area,money)
	self.bet.total = self.bet.total + money
	self.bet.area[area] = (self.bet.area[area] or 0) + money
end

function base_player:is_trusteeship()
	return self.trusteeship == true
end

function base_player:is_beted()
	return self.bet.total
end

function base_player:format_area_bets_2_msg()
	local area_bets = {}
	table.walk(self.bet.area,function(money,area) 
		table.insert(area_bets,{money = money,area = area})
	end)

	return area_bets
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


shelongmen_table = class("shelongmen_table",base_table)

--  1,2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,   --���� A - K
--  16,17,18,19,20,21,22,23,24,25,26,27,28,   --÷�� A - K
--  31,32,33,34,35,36,37,38,39,40,41,42,43,   --���� A - K
--  46,47,48,49,50,51,52,53,54,55,56,57,58,   --���� A - K
function shelongmen_table:ctor()
    self.card_dealer = card_dealer.new(false,1,13)
end

function shelongmen_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)

	self.max_bet = table_bet_limit --�����ע�ܶ�
	self.card_dealer:shuffle()
	self.trends = {}

	self.status_timer = {
		[TableStatus.Idle] = {name = string.format("timer_idle_%d",self.table_id_),timeout = idle_timeout},
		[TableStatus.WaitBet] = {name = string.format("timer_bet_%d",self.table_id_),timeout = bet_timeout},
		[TableStatus.GameOver] = {name = string.format("timer_game_over_%d",self.table_id_),timeout = game_over_timeout}
	}

	self.update_bet_timer_name = string.format( "timer_update_bet_%d",self.table_id_)
	
    self.s_cell = self.room_:get_room_cell_money()
    self.s_tax = self.room_:get_room_tax()

	self:reset()

	timer_manager:new_timer(kick_offline_player_tick_time,function() 
		self:foreach(function(p)
			if self.status == TableStatus.Idle and p:is_trusteeship() then 
				p:forced_exit() 
			end
		end)
	end,nil,true)

	timer_manager:new_timer(3,function()  --�ӳ������Զ���ʼ
		self:game_start() 
	end)
end

function shelongmen_table:reset()
	self.card_dealer:shuffle()
	self.cards_dipai = {}
	self.card_shechu = nil
	self.status = TableStatus.Idle
	self.bet = {total = 0,area = {}}
	
	self.bet_log = {}

    self.game_log = {
        game_server_id = def_game_id,
        first_game_type = def_first_game_type,
        second_game_type = def_second_game_type,
        game_name = def_game_name
	}
end

function shelongmen_table:foreach_and_oper_result(func)
	return self:foreach_condition_and_oper_result(function(p) return true end,func)
end

function shelongmen_table:foreach_condition_and_oper_result(cond,func)
	for i, p in pairs(self.player_list_) do
		if p and cond(p) then if not func(p)  then return false end end
	end

    return true
end

function shelongmen_table:foreach_condition_oper(func_cond,func_op)
    for i,p in pairs(self.player_list_) do
        if p and func_cond(p) then  func_op(p) end
    end
end

function shelongmen_table:foreach_not_ready(func)
    return self:foreach_condition_oper(function(p) return not self.ready_list_[p.chair_id] end,func)
end

function shelongmen_table:foreach_ready(func)
    return self:foreach_condition_oper(function(p) return self.ready_list_[p.chair_id] end,func)
end

function shelongmen_table:foreach_not_standby(func)
    return self:foreach_condition_oper(function(p) return not p.standby end,func)
end

function shelongmen_table:foreach_beted(func)
	return self:foreach_condition_oper(function(p) return p:is_beted() end,func)
end

function shelongmen_table:get_online_player_count()
    local online_player_count = 0
    for _,p in pairs(self.player_list_) do
        if p and not p:is_trusteeship() then
            online_player_count = online_player_count + 1
        end
    end

    return online_player_count
end


function shelongmen_table:get_beted_player_count()
	local count = 0
	self:foreach_beted(function(p,k) count = count + 1 end)
	return count
end

function shelongmen_table:new_status_timer(status,func,repeated)
	timer_manager:new_timer(self.status_timer[status].timeout,func,self.status_timer[status].name,repeated)
end

function shelongmen_table:kill_status_timer(status)
	timer_manager:kill_timer(self.status_timer[status].name)
end

function shelongmen_table:load_lua_cfg(...)
    self:broadcast2client("SC_RoomCfg",{chips_optional = bet_chips})
	self.s_cell = self.room_:get_room_cell_money()
    self.s_tax = self.room_:get_room_tax()
end

function shelongmen_table:is_play(player)
	if player then
		 return player.bet.total > 0
	end

	return self.status ~= TableStatus.Idle
end

-- ����Ƿ��ȡ��׼��
function shelongmen_table:check_cancel_ready(player, is_offline)
	print("shelongmen_table:check_cancel_ready",player.guid,is_offline)
	if player and player.bet.total > 0 then
		if is_offline then
			player.trusteeship = true
		end

		return false
	end

	--�˳�
	return true
end


function shelongmen_table:player_sit_down(player, chair_id_)
	player:reset()
	return base_table.player_sit_down(self,player,chair_id_)
end


function shelongmen_table:game_start()
	self:start()
	self:foreach(function(p) p:reset() end)
	self:reset()

	print("game_start",self.table_id_)
	self:change_status(TableStatus.Idle)
	self:new_status_timer(TableStatus.Idle,function() 
		self:begin_bet()
	end)

	self:send_trends()
end

function shelongmen_table:on_ready_start(player,msg)
	dump(player)
	self:send_bet_chips(player)
	self:send_trends(player)
	self:send_status(player)
	self:send_table_info(player)
end

function shelongmen_table:player_sit_down_finished(player)
	base_table.player_sit_down_finished(self,player)
	print(string.format("shelongmen_table:player_sit_down_finished",player.guid))
	self:send_bet_chips(player)
end

function shelongmen_table:can_bet(player,money,area)
	return  (player:get_money() - player.bet.total >= money) and (self.bet.total + money < self.max_bet)
end

function shelongmen_table:format_bet_area_2_msg()
	local area_bets = {}

	table.walk(self.bet.area,function(money,area) 
		table.insert(area_bets,{money = money,area = area})
	end)
	
	return area_bets
end

function shelongmen_table:format_cards_2_msg(cards_dipai,card_shechu)
	return {cards_dipai = cards_dipai,card_shechu = card_shechu}
end

function shelongmen_table:send_status(player)
	local running_timer = timer_manager:get_timer(self.status_timer[self.status].name)

	local timer = {
		total = running_timer and running_timer.interval or self.status_timer[self.status].timeout,
		remain = running_timer and running_timer.remainder or self.status_timer[self.status].timeout
	}

	dump(timer)

	if player then
		player:send_pb('SC_Switch2TableStatus', {status = self.status,pb_timer = timer})
	else
		self:broadcast2client('SC_Switch2TableStatus', {status = self.status,pb_timer = timer})
	end
end

function shelongmen_table:send_bet_result(player,error)
	player:send_pb("SC_PlayerBet",{
		money = player:get_money() - player.bet.total,
		pb_player_area_bets = player:format_area_bets_2_msg(),
		pb_table_area_bets = self:format_bet_area_2_msg(),
		error = error
	})
end

function shelongmen_table:send_trends(player)
	if player then 
		player:send_pb("SC_GameHistory",{pb_trends = self.trends}) 
	else
		self:broadcast2client("SC_GameHistory",{ pb_trends = self.trends })
	end
end

function shelongmen_table:send_bet_chips(player)
	if player then
   		player:send_pb('SC_RoomCfg', {chips_optional = bet_chips})
	else
		self:broadcast2client('SC_RoomCfg', {chips_optional = bet_chips})
	end
end

function shelongmen_table:change_status(status)
    self.status = status
    self:broadcast2client('SC_Switch2TableStatus', {
		status = self.status,
		pb_timer = {total = self.status_timer[status].timeout,remain = self.status_timer[status].timeout}
	})
end

function shelongmen_table:send_table_info(player)
	if player then
		player:send_pb('SC_TableInfo', {
			status = self.status,
			pb_player_bets = self.bet_log,
			pb_area_bets = self:format_bet_area_2_msg()
		})
	else
		self:broadcast2client('SC_TableInfo',{
				status = self.status,
				pb_player_bets = self.bet_log,
				pb_area_bets = self:format_bet_area_2_msg()
		})
	end
end


function shelongmen_table:on_bet(player,msg)
	dump(self.bet)
	local error_num = 0
	if self.status ~= TableStatus.WaitBet then
		log.warning(string.format("shelongmen_table:on_bet self.status ~= TableStatus.WaitBet guid[%d]",player.guid))
		error_num = 1
	end

	if player.standby then
		log.warning(string.format("shelongmen_table:on_bet standby player guid[%d]",player.guid))
		error_num = 2
	end

	if not table.elements_or_operation(bet_chips,function(cell) return cell == msg.money end) then
		log.warning(string.format("shelongmen_table:on_bet bet amount not in bet_chips guid[%d] [%d]",player.guid,msg.money))
		error_num = 3
	end

	if not self:can_bet(player,msg.money,msg.area) then
		log.warning(string.format("shelongmen_table:on_bet no enought money guid[%d] total[%d] money[%d]",player.guid,player.bet.total,msg.money))
		error_num = 4
	end

	if error_num ~= 0 then
		self:send_bet_result(player, error_num)
		return 
	end

	log.info(string.format("shelongmen_table:on_bet guid[%d] [%d]",player.guid,player.bet.total + msg.money))
    player:on_bet(msg.area,msg.money)
	self.bet.total = self.bet.total + msg.money
	self.bet.area[msg.area] = (self.bet.area[msg.area] or 0) + msg.money
	
	self:send_bet_result(player,0)
	table.insert(self.bet_log,{guid = player.guid,area = msg.area,money = msg.money})
end

function shelongmen_table:caculate_tax(money)
	local l_tax = 0
	if money > 0 then 
		l_tax = money * self.s_tax
		l_tax = l_tax < 1 and 0 or math.floor(l_tax + 0.5)
	end
	return l_tax
end

function shelongmen_table:begin_bet()
	print("begin_bet",self.table_id_)
	self.game_start_time = get_second_time()
	self:kill_status_timer(TableStatus.WaitBet)
	timer_manager:kill_timer(self.update_bet_timer_name)
	self:kill_status_timer(TableStatus.Idle)

	self:change_status(TableStatus.WaitBet)

	local players = {}
	self:foreach(function(p) 
		table.insert(players,{guid = p,header = p:get_header_icon(),money = p:get_money(),location = p.ip_area})
	end)

	self:broadcast2client("SC_GameStart",{
		pb_timer = {total = bet_timeout,remain = bet_timeout},
		pb_players = players
	})

	self:new_status_timer(TableStatus.WaitBet,function() 
		timer_manager:kill_timer(self.update_bet_timer_name)

		self:send_table_info()
		self.bet_log = {}

		self:wait_game_over()
	end)

	timer_manager:new_timer(update_bet_info_timeout,function() 
		self:send_table_info()
		self.bet_log = {}
	end,self.update_bet_timer_name,true)
end

function shelongmen_table:get_cards_area(cards_dipai,card_shechu)
	if #cards_dipai ~= 2 then 
		return BetArea.ShePian
	end 

	if math.abs(cards_dipai[1] % 15 - cards_dipai[2] % 15) == 1 then
		return BetArea.ShunZi
	end

	if cards_dipai[1] % 15 == cards_dipai[2] % 15 then
		return BetArea.DuiZi
	end

	if card_shechu % 15 == cards_dipai[1] % 15 or card_shechu % 15 == cards_dipai[2] % 15 then
		return BetArea.ZhuangZhu
	end

	if (cards_dipai[1] % 15 > card_shechu % 15 and cards_dipai[2] % 15 < card_shechu % 15) or 
		(cards_dipai[2] % 15 > card_shechu % 15 and cards_dipai[1] % 15 < card_shechu % 15)
	then
		return BetArea.SheZhong
	end	

	return BetArea.ShePian
end	

function shelongmen_table:deal_area_cards(area)
	local func = {
		[BetArea.ShePian] = function() 
			local card = self.card_dealer:deal_one()
			local cards = {card,self.card_dealer:deal_one_by_condition(function(c) return math.abs(c % 15 - card % 15) > 1 end)}
			local card_shechu = self.card_dealer:deal_one_by_condition(function(c) return c % 15 > math.max(cards) or c % 15 < math.min(cards) end)

			return cards,card_shechu
		end,
		[BetArea.SheZhong] = function() 
			local card = self.card_dealer:deal_one()
			local cards = {card,self.card_dealer:deal_one_by_condition(function(c) return math.abs(c % 15 - card % 15) > 1 end)}
			local card_shechu = self.card_dealer:deal_one_by_condition(function(c) return c % 15 < math.max(cards) or c % 15 > math.min(cards) end)

			return cards,card_shechu
		end,
		[BetArea.ShunZi] = function() 
			local card = self.card_dealer:deal_one()
			local cards = {card,self.card_dealer:deal_one_by_condition(function(c) return math.abs(c % 15 - card % 15) == 1 end)}

			return cards,nil
		end,
		[BetArea.ZhuangZhu] = function() 
			local card = self.card_dealer:deal_one()
			local cards = {card,self.card_dealer:deal_one_by_condition(function(c) return math.abs(c % 15 - card % 15) > 1 end)}
			local card_shechu = self.card_dealer:deal_one_by_condition(function(c) return c % 15 == math.max(cards) or c % 15 == math.min(cards) end)
			return cards,card_shechu
		end,
		[BetArea.DuiZi] = function() 
			local card = self.card_dealer:deal_one()
			local cards = {card,self.card_dealer:deal_one_by_condition(function(c) return c % 15 == card % 15 end)}
			return cards,nil
		end,
	}

	return func[area] and func[area]() or nil
end

function shelongmen_table:deal_cards()
	local cur_prob = 0
	local rand_num = math.random(10000)
	for area,prob in ipairs(type_prob) do
		if rand_num > cur_prob and rand_num <= cur_prob + prob then
			return area,self:deal_area_cards(area)
		end
		cur_prob = cur_prob + prob
	end

	return nil
end

function shelongmen_table:alway_kill_deal_cards()
	if always_kill_prob >= math.random(10000) then
		return nil
	end

	local min_win = 100000000000
	local min_area = 0
	for area = BetArea.ShePian,BetArea.DuiZi do
		local area_win = (self.bet.area[area] or 0) * AreaMultiple[cards_area]
		if area_win < min_win then
			min_area = area
			min_win = area_win
		end
	end

	if min_area ~= 0 then
		return min_area,self:deal_area_cards(min_area)
	end

	return nil
end

function shelongmen_table:wait_game_over()
	print("wait_game_over",self.table_id_)
	self:change_status(TableStatus.GameOver)

	local cards_area,cards_dipai,card_shechu = self:deal_cards()
	if not cards_area then
		cards_area,cards_dipai,card_shechu = self:aalway_kill_deal_cards()
	end

--	local cards_area = self:get_cards_area(cards_dipai,card_shechu)
	
	if cards_area then 
		self:foreach_beted(function(p)
			if p.bet.total > 0 then
				p.profit = -p.bet.total + (p.bet.area[cards_area] or 0) * AreaMultiple[cards_area]
			end
		
			p.tax = self:caculate_tax(p.profit)
			p.profit = p.profit - p.tax
		end)

		local bigwin_player = nil
		self:foreach_beted(function(p) 
			if p.profit > 0 and (not bigwin_player or p.profit > bigwin_player.profit) then 
				bigwin_player = p
			end
		end)

		self:foreach_beted(function(p) 
			dump(p)
			local old_money = p:get_money()
			if p.profit > 0 then
				p:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = p.profit}}, LOG_MONEY_OPT_TYPE_SHELONGMEN)
				self:player_money_log(p, 2, old_money, p.tax, p.profit, self:get_now_game_id())
			elseif p.profit < 0 then
				p:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -p.profit}}, LOG_MONEY_OPT_TYPE_SHELONGMEN)
				self:player_money_log(p, 1, old_money, p.tax, p.profit, self:get_now_game_id())
			end

			p:send_pb("SC_NotifyGameOver",{
					pb_timer = {total = game_over_timeout, remain = game_over_timeout},
					pb_money = {profit = p.profit, tax = p.tax, money = p:get_money()},
					cards_area = cards_area,
					pb_game = {cards_dipai = cards_dipai, card_shechu = card_shechu},
					pb_bigwin = (not bigwin_player) and  {} or {guid = bigwin_player.guid,header = bigwin_player:get_header_icon(),
								money = p.profit,location = bigwin_player.ip_area}
			})
		end)

		table.insert(self.trends, {cards_dipai = cards_dipai, card_shechu = card_shechu,area = cards_area})
		if table.nums(self.trends) > 10 then
			table.remove(self.trends,1)
		end

		self.game_log.cards = {cards_dipai[1], cards_dipai[2], card_shechu}
		self.game_log.bet = self.bet
		self.game_log.area = cards_area

		if self.bet.total > 0 then
			local s_log = json.encode(self.game_log)
			log.warning(s_log)
			self:save_game_log(self:get_now_game_id(), def_game_name, s_log, self.game_start_time, get_second_time())
		end
	else
		log.error(string.format("shelongmen_table:wait_game_over deal cards error %s",self:get_now_game_id()))
	end

	self:next_game()

	self:send_trends()

	self:new_status_timer(TableStatus.GameOver,function() 
		self:game_over()
	end)
end

function shelongmen_table:game_over()
	self:kill_status_timer(TableStatus.GameOver)
	self:foreach(function(p)
		if p.profit > broadcast.money then
			broadcast_world_marquee(def_first_game_type,def_second_game_type,0,player.nickname,string.format("%.02f",p.profit / 100))
		end
		if p:is_trusteeship() then 
			log.warning(string.format("offline kick out,guid:[%d]",p.guid))
			p:forced_exit() 
		end
	end)

	self:check_single_game_is_maintain()
	
	self:clear_ready()
	self:game_start()
end