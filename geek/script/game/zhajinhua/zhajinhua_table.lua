-- 炸金花逻辑

local pb = require "pb_files"
local log = require "log"
local define = require "game.zhajinhua.base.define"
local enum = require "pb_enums"
local card_dealer = require "card_dealer"
local cards_util = require "game.zhajinhua.base.cards_util"
require "data.zhajinhua_data"
require "random_mt19937"
local player_winlose = require "game.lobby.player_winlose"
local base_rule = require "game.lobby.base_rule"
local player_money = require "game.lobby.player_money"
local timer = require "timer"

local table = table
local string = string
local math = math
local tinsert = table.insert

local base_table = require "game.lobby.base_table"

local dismiss_timeout = 60
local compare_anim_timeout = 2

local CARDS_TYPE = define.CARDS_TYPE
local TABLE_STATUS = define.TABLE_STATUS
local PLAYER_STATUS = define.PLAYER_STATUS
local ACTION = define.ACTION

--系统系数
local SYSTEM_COEFF = 100
--基础概率
local BASIC_COEFF = 3
--浮动概率
local FLOAT_COEFF = 2
--对子概率
local DUIZI_COEFF = 50
--顺子概率
local SHUIZI_COEFF = 20
--金花概率
local JINHUA_COEFF = 10
--顺金概率
local SHUNJIN_COEFF = 2
--豹子概率
local BAOZI_COEFF = 1

--比牌时间
local COMPARE_CARD_TIME = 6

--赢钱金额的百分比进入奖池
local BONUS_POOL_RATE = 0.01

local ready_timeout = 12

local all_cards = {
	2,3,4,5,6,7,8,9,10,11,12,13,14,
	22,23,24,25,26,27,28,29,30,31,32,33,34,
	42,43,44,45,46,47,48,49,50,51,52,53,54,
	62,63,64,65,66,67,68,69,70,71,72,73,74,
}

local zhajinhua_table = base_table:new()

-- 初始化
function zhajinhua_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.game_status = nil
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
end

function zhajinhua_table:player_money(player)
	local p = type(player) == "table" and player or self.players[player]
	return self.old_moneies[p.guid]
end


function zhajinhua_table:request_dismiss(player)
	local timer = self:new_timer(dismiss_timeout,function()
		table.foreach(self.gamers or {},function(p)
			if not self.dismiss_request then
				return
			end

			if self.dismiss_request.commissions[p.chair_id] == nil then
				self:commit_dismiss(p,true)
			end
		end)
	end)

	if self.dismiss_request then
		send2client(player.guid,"SC_DismissTableReq",{
			result = enum.ERROR_OPERATION_REPEATED
		})
		return
	end

	self.dismiss_request = {
		commissions = {},
		requester = player,
		datetime = os.time(),
		timer = timer,
	}

	self.dismiss_request.commissions[player.chair_id] = true

	broadcast2client(self.gamers,"SC_DismissTableReq",{
		result = enum.ERROR_NONE,
		request_guid = player.guid,
		request_chair_id = player.chair_id,
		datetime = os.time(),
		timeout = dismiss_timeout,
	})

	broadcast2client(self.gamers,"SC_DismissTableCommit",{
		result = enum.ERROR_NONE,
		chair_id = player.chair_id,
		guid = player.guid,
		agree = true,
	})

	return enum.ERROR_NONE
end

function zhajinhua_table:check_dismiss_commit(agrees)
	local all_count = table.nums(self.gamers)
    local done_count = table.nums(agrees)
    local agree_count_at_least = self.rule.room.dismiss_all_agree and all_count or math.floor(all_count / 2) + 1
    local refuse_done_count = all_count - agree_count_at_least
    local agree_count = table.sum(agrees,function(agree) return agree and 1 or 0 end)
    local refuse_count = done_count - agree_count
    local agreed = agree_count >= agree_count_at_least
    local refused = refuse_count > refuse_done_count
    local done = agreed or refused or done_count >= all_count
	return done,agreed
end


function zhajinhua_table:set_trusteeship(player,trustee)
    base_table.set_trusteeship(self,player,trustee)
	if self.gamelog then
    	table.insert(self.gamelog.actions,{chair = player.chair_id,act = "Trustee",trustee = trustee,time = timer.nanotime()})
	end
end

function zhajinhua_table:on_offline(player)
	base_table.on_offline(self,player)
	if self.gamelog then
		table.insert(self.gamelog.actions,{chair = player.chair_id,act = "Offline",time = timer.nanotime()})
	end
end

function zhajinhua_table:on_reconnect(player)
	base_table.on_reconnect(self,player)
	if self.gamelog then
		table.insert(self.gamelog.actions,{chair = player.chair_id,act = "Reconnect",time = timer.nanotime()})
	end
end

function zhajinhua_table:on_started(player_count)
	base_table.on_started(self,player_count)
	self.base_score = (self.rule and self.rule.play) and self.rule.play.base_score or self.cell_score_	
	self.all_score = 0  --总金币
	self.cur_chair = 1
	self.bet_round = 1 -- 当前回合
	self.round_turn_count = 0
    self.gamers = table.map(self.players,function(p,chair) return chair,self.ready_list[chair] and p or nil end) 
	self.show_cards_to = {}
	self.game_status = TABLE_STATUS.FREE
	self.banker = nil
	self.desk_scores = {}
	self.last_score = self.base_score
	local chip_scores = (self.rule and self.rule.play) and self.rule.play.chip_score or {}
	local _,max_chip_multi = table.max(chip_scores)
	self.max_score = (max_chip_multi or 1) * self.base_score

	self:cancel_clock_timer()
	self:cancel_action_timer()
	self:stop_start_ticker()
	self:clear_action()

	for i,_ in pairs(self.gamers)  do
		self.show_cards_to[i] = {}
		for j = 1,  self.chair_count  do
			self.show_cards_to[i][j] = false
		end
	end

	self.banker = self:ding_zhuang(self.winner)
	self.winner = nil

	self.gamelog = {
        winner = nil,
        actions = {},
		balance = {},
		rule = self.rule,
		cur_round = self:gaming_round(),
		banker = self.banker,
		players = table.series(self.players,function(v,i) 
			return {
				chair_id = i,
				guid = v.guid,
				head_url = v.icon,
				nickname = v.nickname,
				sex = v.sex,
			}
		end)
	}

	for i,v in pairs(self.gamers) do
		v.game_status = PLAYER_STATUS.WAIT
		v.remain_score = math.floor(self:money_score(self.old_moneies[v.guid]))
		v.remain_money = self.old_moneies[v.guid]
		v.bet_score = 0
		v.bet_money = 0
		v.bet_scores = {}
		v.all_in = nil
		v.death = nil
		v.is_look_cards = nil
		
		v.cards = nil

		self.show_cards_to[i][i] = true
	end

	-- 底注
	self:bet_base_score()

	self.is_compare_card_flag = false
	self.max_add_score_ = 0
	self.last_record = {} --上局回放
	self.black_rate = 0 --黑名单换牌概率

	self.game_status = TABLE_STATUS.PLAY
	self:broadcast2client("SC_ZhaJinHuaStart", {
		banker = self.banker,
		all_chairs = table.series(self.gamers,function(_,i) return i end),
		all_guids = table.series(self.gamers,function(p) return p.guid end),
		cur_round = self:gaming_round(),
		total_round = self.conf.round,
	})

	log.info("game start ID =%s   guid=%s", self.table_id_, 
		table.concat(table.series(self.players,function(p) return p.guid end),","))

	self:deal_cards()
	self:first_turn(self.banker)
end

function zhajinhua_table:cur_player()
	return self.players[self.cur_chair]
end

function zhajinhua_table:player_bet(player,score)
	local bet_score = score
	player.bet_score = (player.bet_score or 0) + bet_score
	tinsert(self.desk_scores,bet_score)
	tinsert(player.bet_scores,bet_score)
	self.all_score = (self.all_score or 0) + bet_score
end

function zhajinhua_table:begin_clock_timer(timeout,fn)
    if self.clock_timer then 
        log.warning("zhajinhua_table:begin_clock_timer timer not nil")
        self.clock_timer:kill()
    end

    self.clock_timer = self:new_timer(timeout,fn)
    self:begin_clock(timeout)

    log.info("zhajinhua_table:begin_clock_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.clock_timer.id,timeout)
end

function zhajinhua_table:cancel_clock_timer()
    log.info("zhajinhua_table:cancel_clock_timer table_id:%s,timer:%s",self.table_id_,self.clock_timer and self.clock_timer.id or nil)
    if self.clock_timer then
        self.clock_timer:kill()
        self.clock_timer = nil
    end
end


function zhajinhua_table:begin_action_timer(timeout,fn)
	if self.auto_action_timer then 
        log.warning("zhajinhua_table:begin_action_timer timer not nil")
        self.auto_action_timer:kill()
    end

    self.auto_action_timer = self:new_timer(timeout,fn)

    log.info("zhajinhua_table:begin_action_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.auto_action_timer.id,timeout)
end

function zhajinhua_table:cancel_action_timer()
	log.info("zhajinhua_table:cancel_action_timer table_id:%s,timer:%s",self.table_id_,self.auto_action_timer and self.auto_action_timer.id or nil)
	if self.auto_action_timer then
		self.auto_action_timer:kill()
		self.auto_action_timer = nil
	end
end

function zhajinhua_table:start_player_turn(player)
	local player = type(player) == "number" and self.players[player] or player
	local actions = self:get_player_actions(player)
	self:foreach_except(player,function(p)
		send2client(p,"SC_ZhaJinHuaTurn",{
			chair_id = player.chair_id,
			actions = {},
		})
	end)

	send2client(player,"SC_ZhaJinHuaTurn",{
		chair_id = player.chair_id,
		actions = table.series(actions,function(v,k) return v and k or nil end),
	})

	self.waiting_actions = {}
	self.waiting_actions[player.chair_id] = actions
	local trustee_type,seconds = self:get_trustee_conf()
	if trustee_type then
		local function auto_action(p)
			if (actions[ACTION.DROP] and self.rule.play.trustee_drop) or not actions[ACTION.FOLLOW] then
				self:give_up(p,nil,true)
				return
			end

			if (actions[ACTION.FOLLOW] and self.rule.play.trustee_follow) or not actions[ACTION.DROP] then
				self:follow(p,nil,true)
				return
			end
		end

		self:begin_clock_timer(seconds,function()
			auto_action(player)
		end)
	end

	return actions
end

function zhajinhua_table:get_men_turn_count()
	local conf = self:room_private_conf()
	if self.rule and self.rule.play then
		local men_turn_opt = (self.rule.play.men_turn_option or 0) + 1
		return conf.men_turn_option[men_turn_opt]
	end

	return 0
end

function zhajinhua_table:is_check_money_limit()
	local club = self.conf and self.conf.club or nil
	local limit = self:is_private() and self.rule.union and self.rule.union.min_score or 0
	return club and club.type == enum.CT_UNION and limit >= 0
end

function zhajinhua_table:check_player_money_leak(player,score)
	if not self:is_check_money_limit() then
		return
	end

	return player.remain_score <= score
end

function zhajinhua_table:get_player_actions(player_or_chair)
	local player = type(player_or_chair) == "number" and self.players[player_or_chair] or player_or_chair
	local score = player.is_look_cards and self.last_score * 2 or self.last_score
	local is_money_leak = self:check_player_money_leak(player,score)
	local men_turn_count = self:get_men_turn_count()
	local play = self.rule and self.rule.play
	local can_add_score_in_men_turns = (play and play.can_add_score_in_men_turns) or (self.bet_round and self.bet_round > men_turn_count)
	local as =  {
		[ACTION.ADD_SCORE] = not is_money_leak and self.last_score < self.max_score and can_add_score_in_men_turns,
		[ACTION.LOOK_CARDS] = not player.is_look_cards and self.bet_round > men_turn_count,
		[ACTION.DROP] = self.bet_round and self.bet_round > men_turn_count,
		[ACTION.ALL_IN] = is_money_leak and not player.all_in,
		[ACTION.COMPARE] = (self.bet_round and self.bet_round > math.max(1,men_turn_count)) and not is_money_leak,
		[ACTION.FOLLOW] = not is_money_leak,
	}
	return as
end

function zhajinhua_table:guard_score(p,score)
	if not self:is_check_money_limit() then
		return score
	end
	score = score > 0 and score or 0
	local remain_score = p.remain_score
	remain_score = remain_score > 0 and remain_score or 0
	return remain_score > score and score or remain_score
end

function zhajinhua_table:bet_base_score()
	local play = self.rule.play
	local base_score = play and play.base_men_score or self.base_score
	table.foreach(self.gamers,function(p)
		local score = self:guard_score(p,base_score)
		self:fake_cost_money(p,score)
		self:player_bet(p,score)
	end)
end

function zhajinhua_table:deal_cards()
	local dealer = card_dealer.new(all_cards)
	dealer:shuffle()

	-- local precards = {
	-- 	[1] = {14,42,63},
	-- 	[2] = {53,54,32},
	-- 	[3] = {11,12,33},
	-- 	[4] = {2,3,64}
	-- }

	local rconf = self.room_.conf

	local coeff = rconf.cards_coeff or 0

	if math.random(1,10000) < coeff then
		local chair_cards = table.series(self.gamers,function()
			local cards = dealer:deal_cards(3)
			return {
				cards = cards,
				type = cards_util.get_cards_type(cards)
			}
		end)

		table.sort(chair_cards,function(l,r)
			return cards_util.compare(l.type,r.type)
		end)

		local money_id = self:get_money_id()
		local winloses = table.map(self.gamers,function(p,chair)
			return chair,tonumber(player_winlose[p.guid][money_id]) or 0
		end)

		local _,max_winlose_abs = table.max(winloses,math.abs)
		local _,max_roundwinlose_abs = table.max(self.gamers,function(p) 
			return math.abs(p.total_score or 0)
		end)

		local coeff_weight = rconf.coeff_weight or {}

		log.dump(coeff_weight)

		local gamer_coeffes = table.series(self.gamers,function(p,chair)
			local count_coeff = self:gaming_round() > 0 and (p.winlose_count or 0) / self:gaming_round() or 0
			local score_coeff = (p.total_score or 0) / max_roundwinlose_abs
			local winlose_coeff = winloses[chair] / max_winlose_abs
			return {
				p = p,
				coeff = count_coeff * (coeff_weight[1] or 1000) + score_coeff * (coeff_weight[2] or 1000) + winlose_coeff * (coeff_weight[3] or 1000),
			}
		end)

		table.sort(gamer_coeffes,function(l,r) return l.coeff < r.coeff end)

		for i,c in pairs(chair_cards) do
			local p = gamer_coeffes[i].p
			log.info("table_id[%s]:player guid[%s] --------------> sorted cards:[%s]",self.table_id_,p.guid,table.concat(c.cards,","))
			p.cards = c.cards
			p.cards_type = c.type
		end
	else
		table.foreach(self.gamers,function(p,chair)
			local cards = dealer:deal_cards(3)
			log.info("table_id[%s]:player guid[%s] --------------> cards:[%s]",self.table_id_,p.guid,table.concat(cards,","))
			p.cards_type = cards_util.get_cards_type(cards)
			p.cards = cards
		end)
	end
end

function zhajinhua_table:ding_zhuang(winner)
	local banker = winner and winner.chair_id or self.conf.owner.chair_id
	log.info("zhajinhua_table:ding_zhuang banker:%s",banker)
	return banker
end

function zhajinhua_table:on_private_dismissed(reason)
	log.info("zhajinhua_table:on_private_dismissed table_id:%s,reason:%s",self:id(),reason)
	base_table.on_private_dismissed(self,reason)
	self:stop_start_ticker()
	self:cancel_clock_timer()
	self:cancel_action_timer()
	self:compare_animate_done()
end

function zhajinhua_table:on_process_start(player_count)
	self:foreach(function(p)
		p.total_score = 0
		p.total_money = 0 
		p.winlose_count = nil
	end)
	base_table.on_process_start(self,player_count)
end

function zhajinhua_table:on_process_over(reason)
	log.info("zhajinhua_table:on_process_over table_id:%s,reason:%s",self:id(),reason)
	self:cancel_clock_timer()
	self:cancel_action_timer()
	self:cancel_kickout_no_ready_timer()
	self:stop_start_ticker()
	
	self.game_status = nil
	self.all_score = nil
	self.last_score = nil
	self.all_scores = nil
	self.cur_chair = nil
	self.bet_round = nil -- 当前回合
	self.round_turn_count = nil
    self.gamers = nil
	self.show_cards_to = nil
	self.banker = nil
	self.desk_scores = nil
	self.gamers = {}
	self.winner = nil

	self:broadcast2client("SC_ZhaJinHuaFinalOver",{
		balances = table.series(self.players,function(p)
			return {
				chair_id = p.chair_id,
				guid = p.guid,
				total_score = p.total_score,
				total_money = p.total_money,
			}
		end)
	})
	
	base_table.on_process_over(self,reason,{
		balance = table.map(self.players,function(p,chair)
			return p.guid,p.total_money 
		end)
	})

	self:cost_tax(table.map(self.players,function(p)
		return p.guid,p.total_money or 0
	end))
	
	self:foreach(function(p) 
		if not p.game_status or p.game_status == PLAYER_STATUS.WATCHER then
			p:async_force_exit(enum.STANDUP_REASON_NORMAL)
		end
		p.total_money = nil
		p.total_score = nil
		p.game_status = nil
		p.winlose_count = nil
		p.pstatus = nil
	end)
end

-- 检查是否可准备
function zhajinhua_table:check_ready(player)
	if player and player.pstatus and   player.pstatus == PLAYER_STATUS.BANKRUPTCY then   
		return false 
	end 
	if self.game_status ~= TABLE_STATUS.FREE and  self.game_status ~= TABLE_STATUS.READY then
		return false
	end
	
	return true
end

function zhajinhua_table:compare_with_all(player)
	log.info("table_id[%s]------->all f cards",self.table_id_)

	local all_count = table.sum(self.gamers,function(p) 
		return (not p.all_in and not p.death) and 1 or 0
	end)
	local is_win_all = table.logic_and(self.gamers,function(p,i) 
		if p.all_in or p.death or p == player then
			return true
		end

		return self:compare_player(player,p,true,all_count > 2)
	end)

	return is_win_all
end

function zhajinhua_table:compare_each_other()
	local gamers = table.series(self.gamers,function(p)
		return (not p.all_in and not p.death) and p or nil
	end)
	
	if #gamers < 1 then
		log.trace("zhajinhua_table:compare_each_other table_id:%s got 0 players.",self:id())
		return 
	end

	local all_count = #gamers
	table.sort(gamers,function(l,r)
		return self:compare_player(l,r,true,all_count > 2)
	end)

	return gamers[1]
end


function zhajinhua_table:get_max_round()
	local round_opt = (self.rule and self.rule.play) and self.rule.play.max_turn_option or 0
	local round = self:room_private_conf().max_turn_option[round_opt + 1] or 8
	return round
end

function zhajinhua_table:next_round()
	local max_round = self:get_max_round()
	if not self.bet_round or self.bet_round <= max_round then
		local live_count = table.sum(self.gamers,function(p)
			return (not p.death and not p.all_in) and 1 or 0
		end)
		if self.round_turn_count >= live_count then
			self.round_turn_count = 0
			self.bet_round = (self.bet_round or 0) + 1

			--超过上限轮数处理
			if self.bet_round > max_round then
				local winner = self:compare_each_other()
				self:game_balance(winner)
				return
			end

			self:broadcast2client("SC_ZhaJinHuaRound", {
				round = self.bet_round,
			})

			return true
		end

		return true
	else
		local winner = self:compare_each_other()
		self:game_balance(winner)
	end
end

function zhajinhua_table:first_turn(banker_chair)
	local reamin = table.sum(self.gamers,function(p) return (not p.death and not p.all_in) and 1 or 0 end)
	log.info("zhajinhua_table:first_turn table_id:%s,first_turn %s,banker:%s", self:id(),reamin,banker_chair)
	local c = banker_chair
	local p
	repeat
		c = (c % self.chair_count) + 1
		if c == banker_chair then
			log.error("zhajinhua_table:first_turn got same next chair %s,%s",c,banker_chair)
			return
		end
		p = self.gamers[c]
	until (p and not p.death and not p.all_in)
	self.cur_chair = c
	log.info("zhajinhua_table:first_turn table_id:%s first_turn end,turn:%s",self:id(),c)
	self:start_player_turn(c)
end

-- 下一个
function zhajinhua_table:next_turn(chair)
	local reamin = table.sum(self.gamers,function(p) return (not p.death and not p.all_in) and 1 or 0 end)
	log.info("next_turn %s %s", reamin,chair)
	chair = chair or self.cur_chair
	local c = chair
	local p
	repeat
		c = (c % self.chair_count) + 1
		if c == chair then 
			log.error("zhajinhua_table:next_turn got same next chair %s,%s",c,chair)
			return
		end
		p = self.gamers[c]
	until (p and not p.death and not p.all_in)

	self.cur_chair = c

	log.info("next_turn end,turn:%s",self.cur_chair )

	self.round_turn_count = (self.round_turn_count or 0) + 1
	local go_next = self:next_round()
	if go_next then
		self:start_player_turn(c)
	end
end

function zhajinhua_table:get_min_gamer_count()
	local min_gamer_count = 2
	if self.rule and self.rule.room.min_gamer_count then
		local private_room_conf = self:room_private_conf()
		min_gamer_count = private_room_conf.min_gamer_count_option[self.rule.room.min_gamer_count + 1]
	end
	return min_gamer_count
end

function zhajinhua_table:begin_start_ticker()
	local trustee,seconds = self:get_trustee_conf()
	if trustee then
		log.info("zhajinhua_table:begin_start_ticker table_id:%s",self:id())
		self:begin_kickout_no_ready_timer(seconds,function()
			log.info("zhajinhua_table:begin_start_ticker timeout,start,table_id:%s,is_play:%s",self:id(),self:is_play())
			self:cancel_kickout_no_ready_timer()
			if not self:is_play() then
				self:start()
			else
				log.warning("zhajinhua_table:begin_start_ticker timeout table_id:%s is gaming.",self:id())
			end
		end)
	end
end

function zhajinhua_table:stop_start_ticker()
	log.info("zhajinhua_table:stop_start_ticker table_id:%s",self:id())
	self:cancel_kickout_no_ready_timer()
end

function zhajinhua_table:owner_check_start(player)
	log.info("zhajinhua_table:owner_check_start %s,owner:%s,player:%s",
		self.table_id_,self.owner.guid,player.guid)
	if not base_rule.is_owner_start_game(self.rule) then
		return enum.ERROR_OPERATION_INVALID
	end

	if player.guid ~= self.owner.guid then
		return enum.ERROR_OPERATION_INVALID
	end

	if self:is_round_gaming() then
		return enum.ERROR_OPERATION_INVALID
	end

	local min_gamer_count = self:get_min_gamer_count()
	
	local ready_count = table.sum(self.players,function(_,c) return self.ready_list[c] and 1 or 0 end)
	if ready_count < min_gamer_count then
		return enum.ERROR_LESS_READY_PLAYER
	end

	local player_count = table.nums(self.players)
	self:start(player_count)

	return enum.ERROR_NONE
end

function zhajinhua_table:owner_start_game(player)
	local result = self:lockcall(function()
		return self:owner_check_start(player)
	end)

	log.info("zhajinhua_table:owner_start_game %s,owner:%s,result:%s",self.table_id_,player.guid,result)
	if result ~= enum.ERROR_NONE then
		send2client(player,"SC_ZhaJinHuaStartGame",{
			result = result
		})
	end
end

function zhajinhua_table:check_start(part)
	log.info("zhajinhua_table:check_start %s-----------------",self.table_id_)
	if self:is_play() then
		return
	end

	if base_rule.is_owner_start_game(self.rule)
		and not self:is_round_gaming() then
		return
	end

	local min_gamer_count = self:get_min_gamer_count()
	local player_count = table.nums(self.players)
	local ready_count = table.sum(self.players,function(_,c) return self.ready_list[c] and 1 or 0 end)

	log.info("zhajinhua_table:check_start table_id:%s,[%s,%s,%s],ext_status:%s",
		self:id(),min_gamer_count,player_count,ready_count,self.ext_round_status)
	if not self:is_round_gaming() then
		if ready_count >= min_gamer_count then
			if ready_count == player_count then
				self:start(player_count)
			else
				self:begin_start_ticker()
			end
		else
			self:stop_start_ticker()
		end
		return
	end

	local is_all_gamer_ready = table.logic_and(self.gamers,function(p,c) 
		return  (p.pstatus and p.pstatus == PLAYER_STATUS.BANKRUPTCY ) or (self.ready_list[c] and true or false) 
	end)
	local gamer_count = table.sum(self.gamers,function (p)
		return (p.pstatus and p.pstatus == PLAYER_STATUS.BANKRUPTCY ) and 0 or 1
	end)
	if is_all_gamer_ready and ready_count >= gamer_count and gamer_count >= min_gamer_count then
		self:start(player_count)
	end
end

-- 重新上线
function zhajinhua_table:reconnect(player)
	log.info("zhajinhua_table:reconnect---------->table_id[%s],guid[%s],chair_id[%s]",
		self.table_id_,player.guid,player.chair_id)

	send2client(player, "SC_ZhaJinHuaReconnect",{
		players = table.map(self.players,function(p,chair)
			return chair,{
				status = p.game_status or PLAYER_STATUS.WATCHER,
				cards = (p == player and p.is_look_cards) and p.cards or nil,
				total_money = p.total_money,
				total_score = p.total_score,
				bet_score = p.bet_score,
				bet_chips = p.bet_scores,
				is_look_cards = p.is_look_cards,
				pstatus = p.pstatus or PLAYER_STATUS.WATCHER,
			}
		end),
		status = self.game_status,
		banker = self.banker,
		bet_round = self.bet_round,
		desk_chips = self.desk_scores,
		round = self:gaming_round(),
		desk_score = self.all_score,
		base_score = self.base_score,
		cur_bet_score = self.last_score,
	})
	
	if self.game_status == TABLE_STATUS.PLAY then
		local turn = {
			chair_id = self.cur_chair,
		}

		if 	player.chair_id == self.cur_chair and 
			self.waiting_actions and 
			self.waiting_actions[self.cur_chair] 
		then
			turn.actions = table.series(self.waiting_actions[self.cur_chair],function(v,k) 
				return v and k or nil 
			end)
		end
		send2client(player,"SC_ZhaJinHuaTurn",turn)

		if self.clock_timer then
			self:begin_clock(self.clock_timer.remainder,player)
		end
	end

	base_table.reconnect(self,player)
end

--玩家游戲結束后亮牌給所有玩家
function zhajinhua_table:show_cards_to_all(player,info)
	if info.cards ~= nil then
		self:foreach_except(player,function(p) 
			send2client(p, "SC_ZhaJinHuaShowCardsToAll",{
				chair_id = p.chair_id,
				cards = info.cards
			})
		end)

		--更新牌局回放信息
		if self.last_record[player.guid] then
			for j,v in pairs(self.last_record) do
				for x,y in ipairs(v.pb_conclude) do
					if y.guid == player.guid then
						y.cards = info.cards
						break;
					end
				end
			end
		end
	end
end

function zhajinhua_table:get_last_record(player,msg)
	if self.last_record[player.guid] then
		send2client(player, "SC_ZhaJinHuaLastRecord", self.last_record[player.guid])
	else
		send2client(player, "SC_ZhaJinHuaLastRecord", {
			win_chair_id = 0,
			pb_conclude = {},
			tax = 0
		})
	end
end

-- 做牌
function zhajinhua_table:handle_cards()
	local sp_cards = {}
	local ct_type = {}
	local spnum = math.random(1,2) + 2 --每一把洗2~3个特殊牌型
	--local spnum = 5
	--好牌碰撞概率
	local baozi_prob = BAOZI_COEFF
	local shunjin_prob = baozi_prob + SHUNJIN_COEFF
	local jinhua_prob = shunjin_prob + JINHUA_COEFF
	local shunzi_prob = jinhua_prob + SHUIZI_COEFF
	for i = 1,spnum do
		local rand_num = math.random(1,SYSTEM_COEFF)
		local cardtype = CARDS_TYPE.DOUBLE --最低对子

		if rand_num <= baozi_prob then --豹子
			cardtype = CARDS_TYPE.BAOZI
		elseif rand_num <= shunjin_prob then --顺金
			cardtype = CARDS_TYPE.SHUNJIN
		elseif rand_num <= jinhua_prob then --金花
			cardtype = CARDS_TYPE.JINHUA
		elseif rand_num <= shunzi_prob then --順子
			cardtype = CARDS_TYPE.SHUNZI
		else --對子
			cardtype = CARDS_TYPE.DOUBLE
		end
		ct_type[i] = cardtype
		--log.info("--------------ct_type:", i, ct_type[i])
	end

	local k = #self.cards
	for j=1,spnum do
		local tempcards = {}
		local isok = false
		local sp_key = math.random(k) --随机抽取一张牌
		tempcards[1] = self.cards[sp_key]
		if sp_key ~= k then
			self.cards[sp_key], self.cards[k] = self.cards[k], self.cards[sp_key]
		end
		k = k-1
		local first_card = cards_util.value(tempcards[1])
		local first_card_color = cards_util.color(tempcards[1])
		local flag_this_card = 1
		if first_card < 11 then --顺子第一张牌在K以下走正常流程
			flag_this_card = 1
		elseif first_card == 11 then --大于等于K时流程
			flag_this_card = 2
		end

		if ct_type[j] == CARDS_TYPE.DOUBLE then --对子
			local i_index=1
			while ( i_index < k and isok == false) do
				if cards_util.value(tempcards[1]) == cards_util.value(self.cards[i_index]) and cards_util.color(tempcards[1]) ~= cards_util.color(self.cards[i_index]) then
					isok = true
					tempcards[2] = self.cards[i_index]
					if i_index ~= k then
						self.cards[i_index], self.cards[k] = self.cards[k], self.cards[i_index]
					end
					k = k-1
					break
				end
				i_index = i_index + 1
			end

			if isok == true then
				local lastindex = math.random(k)
				tempcards[3] = self.cards[lastindex]
				if lastindex ~= k then
					self.cards[lastindex], self.cards[k] = self.cards[k], self.cards[lastindex]
				end
				k = k-1
			end
		elseif ct_type[j] == CARDS_TYPE.SHUNZI then --顺子
			local n = 2
			if flag_this_card == 1 then
				local i_index=1
				while ( i_index < k and isok == false) do
					if first_card+1 == cards_util.value(self.cards[i_index]) then
						tempcards[n] = self.cards[i_index]
						first_card = cards_util.value(self.cards[i_index])
						if i_index ~= k then
							self.cards[i_index], self.cards[k] = self.cards[k], self.cards[i_index]
						end
						k = k-1
						if n == 3 then
							isok = true
							break
						end
						n = n + 1
					end
					i_index = i_index + 1
				end
			elseif flag_this_card == 2  then --第一张牌为K或A
				local i_index=1
				while (i_index < k and isok == false) do
					if first_card-1 == cards_util.value(self.cards[i_index]) then
						tempcards[n] = self.cards[i_index]
						first_card = cards_util.value(self.cards[i_index])
						if i_index ~= k then
							self.cards[i_index], self.cards[k] = self.cards[k], self.cards[i_index]
						end
						k = k-1
						if n == 3 then
							isok = true
							break
						end
						n = n + 1
					end
					i_index = i_index + 1
				end
			end


		elseif ct_type[j] == CARDS_TYPE.JINHUA then --金花
			local m = 2
			local i_index=1
			while ( i_index < k and isok == false) do
				if cards_util.color(tempcards[1]) == cards_util.color(self.cards[i_index]) then
					tempcards[m] = self.cards[i_index]
					if i_index ~= k then
						self.cards[i_index], self.cards[k] = self.cards[k], self.cards[i_index]
					end
					k = k-1
					if m == 3 then
						isok = true
						break
					end
					m = m + 1
				end
				i_index = i_index + 1
			end
		elseif ct_type[j] == CARDS_TYPE.SHUNJIN then --顺金
			local n = 2
			if flag_this_card == 1 then
				local i_index=1
				while( i_index < k and isok == false ) do
					if first_card+1 == cards_util.value(self.cards[i_index]) and first_card_color == cards_util.color(self.cards[i_index]) then
						tempcards[n] = self.cards[i_index]
						first_card = cards_util.value(self.cards[i_index])
						if i_index ~= k then
							self.cards[i_index], self.cards[k] = self.cards[k], self.cards[i_index]
						end
						k = k-1
						if n == 3 then
							isok = true
							break
						end
						n = n + 1
					end
					i_index = i_index + 1
				end
			elseif flag_this_card == 2  then --第一张牌为K或A
				local i_index=1
				while( i_index < k and isok == false ) do
					if first_card-1 == cards_util.value(self.cards[i_index]) and first_card_color == cards_util.color(self.cards[i_index]) then
						tempcards[n] = self.cards[i_index]
						first_card = cards_util.value(self.cards[i_index])
						if i_index ~= k then
							self.cards[i_index], self.cards[k] = self.cards[k], self.cards[i_index]
						end
						k = k-1
						if n == 3 then
							isok = true
							break
						end
						n = n + 1
					end
					i_index = i_index + 1
				end
			end
		elseif ct_type[j] == CARDS_TYPE.BAOZI then --豹子
			local m = 2
			local i_index=1
			local check_index = 1
			while( i_index < k and isok == false ) do
				if cards_util.value(tempcards[1]) == cards_util.value(self.cards[i_index]) and  cards_util.color(tempcards[check_index]) ~= cards_util.color(self.cards[i_index]) then
					check_index = check_index + 1
					tempcards[m] = self.cards[i_index]
					if i_index ~= k then
						self.cards[i_index], self.cards[k] = self.cards[k], self.cards[i_index]
					end
					k = k-1
					if m == 3 then
				--[[		if check_index > 2 and cards_util.color(tempcards[1]) ~=  cards_util.color(self.cards[i_index]) then
							isok = true
						end--]]
						isok = true
						break
					end
					m = m + 1
				end
				i_index = i_index + 1
			end
		end
		if isok == false then --未匹配上
			for n = 2,3 do
				local in_dex = math.random(k)
				tempcards[n] = self.cards[in_dex]
				if in_dex ~= k then
					self.cards[in_dex], self.cards[k] = self.cards[k], self.cards[in_dex]
				end
				k = k-1
			end
		end
		tinsert(sp_cards,tempcards)
	end
	--每局总共做随机2~3首好牌,剩下2首随机洗牌
	local remainder_num = 5 - spnum
	for i=1,remainder_num do
		local remain_cards = {}
		-- 洗牌
		for j=1,3 do
			local r = math.random(k)
			remain_cards[j] = self.cards[r]
			if r ~= k then
				self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
			end
			k = k-1
		end
		tinsert(sp_cards,remain_cards)
	end
	--打乱顺序
	local len = #sp_cards
	for i=1,len do
		local x = math.random(1,len)
		local y = math.random(1,len)
		if x ~= y then
			sp_cards[x], sp_cards[y] = sp_cards[y], sp_cards[x]
		end
		len = len - 1
	end

	return sp_cards
end

--校验抽出来的牌型
function zhajinhua_table:check_spec_cards(cards)
	local this_cards = table.union_tables(cards)
	table.sort(this_cards, function(a, b) return a < b end)
	local cards_len = #this_cards
	if cards_len ~= 15 then
		log.error(table.concat(this_cards, ','))
		return false
	end
	local cards_voctor = {}
	for i,v in ipairs(this_cards) do
		if v < 0 or v > 51 then
			log.error(table.concat(this_cards, ','))
			return false
		end

		if not cards_voctor[v] then
			cards_voctor[v] = 1
		else
			log.error(table.concat(this_cards, ','))
			return false
		end
	end

	return true
end

function zhajinhua_table:follow(player,msg,auto)
	if not self.gamers[player.chair_id] or 
		not self:check_player_action(player,ACTION.FOLLOW) then
		send2client(player,"SC_ZhaJinHuaFollowBet",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	self:clear_action()
	self:cancel_clock_timer()
	self:cancel_action_timer()

	local score = player.is_look_cards and self.last_score * 2 or self.last_score
	local is_all_in = self:check_player_money_leak(player,score)
	score = is_all_in and self:guard_score(player,score) or score

	self:player_bet(player,score)
	self:fake_cost_money(player,score)

	tinsert(self.gamelog.actions, {
		action = "follow",
		chair_id = player.chair_id,
		turn = self.bet_round,
		score = score,
		time = timer.nanotime(),
		auto = auto,
	})

	if not is_all_in then
		self:broadcast2client("SC_ZhaJinHuaFollowBet",{
			result = enum.ERROR_NONE,
			chair_id = player.chair_id,
			score = score,
		})
	else
		player.all_in = true
	
		self:broadcast2client("SC_ZhaJinHuaAllIn",{
			result = enum.ERROR_NONE,
			chair_id = player.chair_id,
			score = score,
		})

		log.info("table_id[%s]:player guid[%s]--------->allin score[%s]", self.table_id_,player.guid,score)

		if self:compare_with_all(player) then
			self:game_balance(player)
			return
		end

		player.death = true
		
		if self:is_end() then
			self:game_balance()
			return
		end
	end

	self:next_turn()
end

function zhajinhua_table:cs_follow(player,msg)
	self:follow(player,msg)
end

function zhajinhua_table:all_in(player)
	local chair_id = player.chair_id
	if not self.gamers[chair_id] or
		not self:check_player_action(player,ACTION.ALL_IN) then
		send2client(player,"SC_ZhaJinHuaAllIn",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	self:clear_action()
	self:cancel_clock_timer()
	self:cancel_action_timer()

	local score = self:guard_score(player,self.last_score or self.base_score)
	self:fake_cost_money(player,score)
	self:player_bet(player,score)
	player.all_in = true

	local is_win = self:compare_with_all(player)
	self:broadcast2client("SC_ZhaJinHuaAllIn",{
		chair_id = chair_id,
		score = score,
		is_win = is_win,
	})

	if is_win then
		self:game_balance(player)
		return
	end

	player.death = true

	if self:is_end() then
		self:game_balance()
		return
	end

	self:next_turn()
end

function zhajinhua_table:cs_all_in(player,msg)
	self:all_in(player,msg)
end

-- 加注
function zhajinhua_table:add_score(player,msg)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.ADD_SCORE) then
		send2client(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	local score = msg.score
	log.info("table_id[%s] player guid[%s]--------> add score[%s]",self.table_id_,player.guid,score)

	if score < 0 then
		log.warning("table_id[%s]: add_score guid[%s] status error  is score %s < 0", self.table_id_, player.guid,score)
		send2client(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	if player.all_in then
		log.warning("table_id[%s]: add_score guid[%s] status error  is all_score_  true", self.table_id_, player.guid)
		send2client(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	if player.death then
		log.error("table_id[%s]:add_score guid[%s] is dead", self.table_id_,player.guid)
		send2client(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	if score > self.max_score then
		log.error("table_id[%s]:add_score guid[%s] score[%s] > max[%s]",self.table_id_, player.guid, score, self.max_score)
		send2client(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	self:clear_action()
	self:cancel_clock_timer()
	self:cancel_action_timer()

	local is_all_in
	local score_add = player.is_look_cards and score * 2 or score
	if self:check_player_money_leak(player,score_add) then
		score_add = self:guard_score(player,score_add)
		is_all_in = true
	else
		if score < self.last_score then
			log.error("table_id[%s]:add_score guid[%s] score[%s] < last[%s]",self.table_id_, player.guid, score, self.last_score)
			send2client(player,"SC_ZhaJinHuaAddScore",{
				result = enum.ERROR_OPERATION_INVALID,
			})
			return
		end
	end

	self.last_score = score

	log.info("table_id [%s]: player guid[%s]----->score[%s],money[%s].",self.table_id_,player.guid,score, score_add)

	self:fake_cost_money(player,score_add)
	self:player_bet(player,score_add)
	
	tinsert(self.gamelog.actions,{
		action = is_all_in and "all_in" or "add_score",
		chair_id = player.chair_id,
		score = score_add, -- 注码
		turn = self.bet_round,
		time = timer.nanotime(),
	})

	self:broadcast2client("SC_ZhaJinHuaAddScore", {
		result = enum.NONE,
		chair_id = player.chair_id,
		score = score_add,
	})

	if is_all_in then
		log.info("table_id[%s]:player guid[%s]--------->allin score[%s]", self.table_id_,player.guid,score_add)
		player.all_in = true

		if self:compare_with_all(player) then
			self:game_balance(player)
			return
		end

		player.death = true

		if self:is_end() then
			self:game_balance()
			return
		end
	end

	self:next_turn()
end

function zhajinhua_table:cs_add_score(player,msg)
	self:add_score(player,msg)
end

-- 放弃跟注
function zhajinhua_table:give_up(player,msg,auto)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.DROP) then
		send2client(player,"SC_ZhaJinHuaGiveUp",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	local chair_id = player.chair_id
	log.info("table_id[%s]:player guid[%s]------> give_up", self.table_id_,player.guid)

	if player.death then
		log.error("table_id[%s]:give_up guid[%s] is dead", self.table_id_,player.guid)
		send2client(player,"SC_ZhaJinHuaGiveUp",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if self.ball_begin and self.cur_chair ~= chair_id then
		log.error("table_id[%s]:give_up is ball_begin guid[%s] can not giveup charid [%s] cur_turn[%s]",
			self.table_id_, player.guid, player.charid , self.cur_chair)
	end

	self:clear_action()
	self:cancel_clock_timer()
	self:cancel_action_timer()

	player.death = true
	player.game_status = PLAYER_STATUS.DROP

	--日志处理
	tinsert(self.gamelog.actions, {
		action = "giveup",
		chair_id = chair_id,
		now_chair = self.cur_chair,
		time = timer.nanotime(),
		auto = auto,
	})

	self:broadcast2client("SC_ZhaJinHuaGiveUp",{
		chair_id = chair_id,
	})

	if self:is_end() then -- 结束
		self:game_balance()
		return
	end

	self:next_turn()
end

function zhajinhua_table:cs_give_up(player,msg)
	self:give_up(player,msg)
end

function zhajinhua_table:check_player_action(player_or_chair,action)
	local chair = type(player_or_chair) == "table" and player_or_chair.chair_id or player_or_chair
	if 	self.game_status == TABLE_STATUS.PLAY and
		self.cur_chair == chair and 
		self.waiting_actions and 
		self.waiting_actions[chair] and 
		self.waiting_actions[chair][action] then
		return true
	end

	log.warning("zhajinhua_table:check_player_action invalid operation,chair:%s,action:%s",chair,action)
end

function zhajinhua_table:clear_action(chair)
	local chair = type(chair) == "table" and chair.chair_id or chair
	if not chair then
		self.waiting_actions = {}
		return
	end

	self.waiting_actions[chair] = nil
end

-- 看牌
function zhajinhua_table:look_card(player)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.LOOK_CARDS) then
		send2client(player,"SC_ZhaJinHuaLookCard",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	self:clear_action()
	self:cancel_clock_timer()
	self:cancel_action_timer()

	log.info("table_id[%s]:player guid[%s]-------------->look cards",self.table_id_,player.guid)

	player.is_look_cards = true

	send2client(player, "SC_ZhaJinHuaLookCard", {
		chair_id = player.chair_id,
		cards = player.cards,
	})

	self:broadcast2client_except(player, "SC_ZhaJinHuaLookCard", {
		chair_id = player.chair_id,
	})
	
	tinsert(self.gamelog.actions, {
		action = "look_cards",
		chair_id = player.chair_id,
		turn = self.bet_round,
		time = timer.nanotime(),
	})

	self:start_player_turn(player)
end

function zhajinhua_table:cs_look_card(player,msg)
	self:look_card(player,msg)
end


function zhajinhua_table:wait_compare_animate(timeout,fn)
	if self.compare_waiting_timer then
		self.compare_waiting_timer:kill()
	end
	self.compare_waiting_timer = self:new_timer(timeout,fn)
end

function zhajinhua_table:compare_animate_done()
	if not self.compare_waiting_timer then
		return
	end

	self.compare_waiting_timer:kill()
	self.compare_waiting_timer = nil
end

-- 终
 -- 比牌
function zhajinhua_table:compare(player, msg)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.COMPARE) then
		send2client(player,"SC_ZhaJinHuaCompareCards",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	local compare_with = msg.compare_with

	local chair_id = player.chair_id
	log.info("table_id[%s]:player guid[%s] chair_id[%s]-------------->compare_with[%s] COMPARE_CARD",
		self.table_id_,player.guid,player.chair_id,compare_with)

 	local target = self.players[compare_with]
 	if not target then
		log.error("table_id[%s]:compare guid[%s] compare[%s] error",self.table_id_, player.guid, compare_with)
		send2client(player,"SC_ZhaJinHuaCompareCards",{
			result = enum.ERROR_OPERATION_INVALID
		})
 		return
	end

	if player.all_in or target.all_in or player.death or target.death then
		log.error("table_id[%s]:compare anyone [%s]vs[%s]  is dead",self.table_id_, player.guid,target.guid)
		send2client(player,"SC_ZhaJinHuaCompareCards",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	self:clear_action()

	self:cancel_clock_timer()
	self:cancel_action_timer()

	local score = player.is_look_cards and self.last_score * 2 or self.last_score
	local play = self.rule.play
	score = play.double_compare and score * 2 or score

	self:fake_cost_money(player,score)
	self:player_bet(player,score)

	-- 比牌
	log.dump(player.cards)
	log.dump(target.cards)
	local is_win = self:compare_player(player, target)

	--修改双方结束时对方牌可见
	self.show_cards_to[chair_id][compare_with] = true
	self.show_cards_to[compare_with][chair_id] = true

	log.info("table_id[%s]:player guid[%s],target guid[%s]----------> win[%s].",
		self.table_id_,player.guid,target.guid,is_win)

	local loser = is_win and target or player
	local winner = is_win and player or target
	loser.death = true
	loser.game_status = PLAYER_STATUS.LOSE
	
	log.info("table_id[%s]: player guid[%s] charid[%s] , target guid[%s] ,turn [%s] , otherplayer [%s] money[%s] win [%s]" ,
		self.table_id_,player.guid,chair_id,target.guid,self.bet_round,compare_with,score,is_win)
	tinsert(self.gamelog.actions, {
		action = "compare",
		chair_id = chair_id,
		turn = self.bet_round,
		compare_with = compare_with,		--被比牌玩家
		money = score,		--比牌花费
		win = is_win,		--是否获胜
		score = score,
		time = timer.nanotime(),
	})

	self:broadcast2client("SC_ZhaJinHuaCompareCards",{
		comparer = player.chair_id,
		compare_with = target.chair_id,
		winner = winner.chair_id,
		loser = loser.chair_id,
		score = score,
	})

	if self:is_end() then
		log.info("table_id[%s]:------------->This Game Is  Over!",self.table_id_)
		self:wait_compare_animate(compare_anim_timeout,function() --比牌动画延时
			self:compare_animate_done()
			self:game_balance()
		end)
		return
	end

	self:wait_compare_animate(compare_anim_timeout,function()
		self:compare_animate_done()
		self:next_turn()
	end)
end

function zhajinhua_table:cs_compare(player,msg)
	self:compare(player,msg)
end

local deepcopy  = clone

function zhajinhua_table:check_get_bonus_pool_money(card_type)
	if card_type == CARDS_TYPE.BAOZI then
		return self.base_score * 50
	end
	if card_type == CARDS_TYPE.SHUNJIN then
		return self.base_score * 10
	end

	return 0
end

function zhajinhua_table:is_end()
	local gamer_count = table.sum(self.gamers,function(p) 
		return (not p.death and not p.all_in) and 1 or 0  
	end)

	return gamer_count == 1
end

function zhajinhua_table:balance_bonus(winner)
	local play = self.rule and self.rule.play
	local winner_chair = winner.chair_id
	local bonus_bao_zi_scores = {}
	if play and play.bonus_bao_zi then
		if winner.cards_type.type == CARDS_TYPE.BAO_ZI then
			table.foreach(self.gamers,function(p,c) 
				bonus_bao_zi_scores[c] = (bonus_bao_zi_scores[c] or 0) - 5
				bonus_bao_zi_scores[winner_chair] = (bonus_bao_zi_scores[winner_chair] or 0) + 5
			end,function(p,c) return c ~= winner_chair end)
		end
	end

	local bonus_shunjin_scores = {}
	if play and play.bonus_shunjin then
		if winner.cards_type.type == CARDS_TYPE.SHUN_JIN then
			table.foreach(self.gamers,function(p,c) 
				bonus_shunjin_scores[c] = (bonus_shunjin_scores[c] or 0) - 5
				bonus_shunjin_scores[winner_chair] = (bonus_shunjin_scores[winner_chair] or 0) + 5
			end,function(p,c) return c ~= winner_chair end)
		end
	end

	return table.merge(bonus_shunjin_scores,bonus_bao_zi_scores,function(l,r) 
			return (l or 0) + (r or 0)
		end)
end

-- 检查结束
function zhajinhua_table:game_balance(winner)
	self:cancel_clock_timer()
	self:cancel_action_timer()
	self:compare_animate_done()
	
	if not winner then
		local winners = table.select(self.gamers,function(p) return not p.death end,true)
		winner = winners[1]
	end

	self.winner = winner

	log.info("table_id[%s]: game_balance---->Game is Over !!",self.table_id_)
	self.game_status = TABLE_STATUS.FREE

	local winner_score = self.all_score - winner.bet_score
	local scores = table.map(self.gamers,function(p,chair)
		if p == winner then  return chair,winner_score end
		return chair,- p.bet_score
	end)

	local bonus_scores = self:balance_bonus(winner)
	table.mergeto(scores,bonus_scores,function(l,r)
		return (l or 0) + (r or 0) 
	end)

	table.foreach(self.gamers,function(p,chair) 
		local s = scores[chair]
		if s > 0 then
			p.remain_score = p.remain_score + s
		end
	end)

	log.dump(scores)
	
	local moneies = self:balance(table.map(scores,function(s,chair) 
		return chair,self:score_money(s) end
	),enum.LOG_MONEY_OPT_TYPE_ZHAJINHUA)

	self:notify_game_money()

	log.dump(moneies)

	table.foreach(self.gamers,function(p,chair)
		p.winlose_count = (p.winlose_count or 0) +  (scores[chair] > 0 and 1 or -1)
		p.total_score = (p.total_score or 0) + scores[chair]
		p.total_money = (p.total_money or 0) + moneies[chair]
		if self:is_bankruptcy(p) then
			p.pstatus = PLAYER_STATUS.BANKRUPTCY
		end
	end)

	self.gamelog.balance = table.series(self.gamers,function(v,i) 
		return {
			chair_id = i,
			round_score = scores[i],
			round_money = moneies[i],
			total_money = v.total_money,
			total_score = v.total_score,
			cards = v.cards,
		}
	end)

	self.gamelog.all_score = self.all_score
	self:broadcast2client("SC_ZhaJinHuaGameOver",{
		winner = winner.chair_id,
		cards_type = winner.cards_type.type,
		balances = table.series(self.gamers,function(p,chair) 
			return {
				chair_id = p.chair_id,
				guid = p.guid,
				money = moneies[chair],
				score = scores[chair],
				status = p.game_status,
				total_score = p.total_score,
				total_money = p.total_money,
				cards = p.cards,
				bet_score = p.bet_score,
				pstatus = p.pstatus or PLAYER_STATUS.WATCHER,
			}
		end)
	})

	self.last_record = nil

	self:save_game_log(self.gamelog)

	self:game_over()
end

function zhajinhua_table:is_bankruptcy(player)
	local club = self.club
	if not club or club.type ~= enum.CT_UNION then
		return
	end

	local money_id = self:get_money_id()
	local min_limit = self.rule.union and self.rule.union.min_score or 0
	local base_limit = self:score_money(self.base_score)
	local money = player_money[player.guid][money_id]
	return money < math.max(min_limit,base_limit)
end
function base_table:check_bankruptcy_fordismiss()
	return  table.sum(self.gamers,function (p)
		return (p.pstatus and p.pstatus== PLAYER_STATUS.BANKRUPTCY) and 0 or 1
	end) < self:get_min_gamer_count()
end 
function zhajinhua_table:on_game_overed()
	log.info("game end table_id =%s   guid=%s   timeis:%s", self.table_id_, self.log_guid, os.date("%y%m%d%H%M%S"))
	self.gamelog = nil
	self:cancel_clock_timer()
	self:cancel_action_timer()
	self:cancel_kickout_no_ready_timer()

	self.desk_scores = nil
	self.all_score = 0
	self.last_score = 0
	self.bet_round = nil
	self.game_status = TABLE_STATUS.FREE
	table.foreach(self.gamers,function(p)
		p.game_status = PLAYER_STATUS.FREE
		p.all_in = nil
		p.death = nil
		p.is_look_cards = nil
		p.bet_score = nil
		p.remain_score = nil
		p.bet_scores = nil
		p.cards = nil
		p.cards_type = nil
	end)

	base_table.on_game_overed(self)
end

-- 比较牌 first 申请比牌的
function zhajinhua_table:compare_player(l, r,with_color,with_each_other)
	local function is_A_2_3(ct)
		if ct.type ~= CARDS_TYPE.SHUN_ZI and ct.type ~= CARDS_TYPE.SHUN_JIN then return false end
		local vals = ct.vals
		return vals[1][1] == 2 and vals[1][2] == 3 and vals[1][3] == 14
	end
 
	local play = self.rule.play
	local lt,rt = l.cards_type,r.cards_type
	with_color = with_color or (play and play.color_compare)
	local comp = cards_util.compare(lt,rt,with_color)

	if not with_each_other and play and play.baozi_less_than_235  then
		if lt.type == CARDS_TYPE.BAO_ZI and rt.type == CARDS_TYPE.CT235 then
			return false
		end

		if lt.type == CARDS_TYPE.CT235 and rt.type == CARDS_TYPE.BAO_ZI then
			return true
		end
	end

	if play and play.small_A23 then
		if lt.type == rt.type and is_A_2_3(lt) and not is_A_2_3(rt) then
			return false
		end

		if lt.type == rt.type and is_A_2_3(rt) and not is_A_2_3(lt) then
			return true
		end
	end

	return comp
end

--替换玩家cost_money方法，先缓存，稍后一起扣钱
function zhajinhua_table:fake_cost_money(player,score)
	local chair_id = player.chair_id
	local money = self:score_money(score)
	local new_money = player.remain_money - money
	player.remain_money = new_money
	player.remain_score = player.remain_score - score
	log.info("table_id[%s] player guid[%s] new_money[%s],money[%s].",self.table_id_,player.guid,new_money,money)
	
	self:notify_game_money({
		[chair_id] = new_money,
	})

	return true
end

function zhajinhua_table:is_compare_card()
	return self.is_compare_card_flag
end

function zhajinhua_table:start_add_score_timer(time,player)
	local function add_score_timer_func()
		local score = self.last_score
		if self.bet_round > 1 then
			local r = math.random(1,100)
			if player:is_max() then
				if r < 70 and self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					self:calllater(math.random(2,4),add_score_timer_func)
					return
				else
					if r < 70 then
						--跟注
						score = self.last_score
					elseif r < 95 then
						--加注
						for _,v in pairs(self.add_score_) do
							if v > score then
								score = v
								break
							end
						end
					else
						--全下
						if self.is_look_card_[player.chair_id] == false then
							--看牌
							self:look_card(player)
							self:calllater(math.random(2,4),add_score_timer_func)
						else
							score = 1
						end
					end
				end
			else
				if r < 90 and self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					self:calllater(math.random(2,4),add_score_timer_func)
					return
				else
					if r < 5 then
						--跟注
						score = self.last_score
					elseif r < 10 then
						--加注
						for _,v in pairs(self.add_score_) do
							if v > score then
								score = v
								break
							end
						end
					else
						--弃牌
						if self.is_look_card_[player.chair_id] == false then
							--看牌
							self:look_card(player)
							self:calllater(math.random(2,4),add_score_timer_func)
						else
							self:give_up(player)
						end
					end
				end
			end
		end
		if self.ball_begin then
			--全下状态
			if player:is_max() then
				--全下
				if self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					self:calllater(math.random(2,4),add_score_timer_func)
				else
					score = 1
				end
			else
				--弃牌
				if self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					self:calllater(math.random(2,4),add_score_timer_func)
				else
					self:give_up(player)
				end
			end
		end
		if self:is_compare_card() then
			log.error("is compare card guid[%s]", player.guid)
			return
		end
		if score and self:check_compare_cards(player) == false then
			self:add_score(player, score)
		else
			log.error("guid[%s] add score No score", player.guid)
		end
	end
	self:calllater(time,add_score_timer_func)
end

function zhajinhua_table:check_compare_cards(player)
	local cout = table.sum(self.death,function(_,chair) return not self.death[chair] and 1 or 0 end)
	local last_score = self.last_score
	if self.is_look_card_[player.chair_id] then
		last_score = self.last_score * 2
	end

	local player_score = player.remain_score
	if player_score < last_score and not player.death and cout >= 3 then
		--触发全比
		local money_ = player_score
		self:fake_cost_money(player,money_)

		self:player_bet(player,money_)

		tinsert(self.gamelog.actions, {
			action = "add_score",
			chair_id = player.chair_id,
			score = player_score, -- 注码
			money = player_score,
			turn = self.bet_round,
			isallscore = false ,  --是否全压
			isallcom = true, --是否为全比
			time = timer.nanotime(),
		})

		self:broadcast2client("SC_ZhaJinHuaAddScore", {
			add_score_chair_id = player.chair_id,
			cur_chair_id = self.cur_chair,
			score = last_score,
			money = money_,
			is_all = false,
		})

		local max_chair_id = 0
		local max_cards_type = 0
		for k,v in pairs(self.player_cards_type_) do
			if self.death[k] == false then
				if v.cards_type > max_cards_type then
					max_chair_id = k
					max_cards_type = v.cards_type
				elseif v.cards_type == max_cards_type then
					local ret = self:compare_player(self.player_cards_type_[k], self.player_cards_type_[max_chair_id])
					if ret then
						max_chair_id = k
						max_cards_type = v.cards_type
					end
				end
			end
		end

		if max_chair_id == player.chair_id then
			--胜，结算游戏
			self:compare_with_all(player)
			log.info("check_compare_cards =====> win")
		else
			--负，继续游戏
			player.death = true
			player.game_status = PLAYER_STATUS.LOSE
			local notify = {
				lose_chair_id = player.chair_id,
				cur_chair_id = self.cur_chair,
			}
			if player.chair_id == self.cur_chair then
				self:next_turn()
			end
			notify.cur_chair_id = self.cur_chair
			self:broadcast2client("SC_ZhaJinHuaAllComCards", notify)
			log.info("check_compare_cards =====> lose")
		end
		return true
	end
	return false
end

--黑名单处理
function zhajinhua_table:check_black_user()
	--检查概率
	if self.black_rate < math.random(1,100) then
		return
	end
	--获取最大牌型
	local max_chair_id = 0
	local max_cards_type = 0
	for k,v in pairs(self.player_cards_type_) do
		if v.cards_type > max_cards_type then
			max_chair_id = k
			max_cards_type = v.cards_type
		elseif v.cards_type == max_cards_type then
			local ret = self:compare_player(self.player_cards_type_[k], self.player_cards_type_[max_chair_id])
			if ret then
				max_chair_id = k
				max_cards_type = v.cards_type
			end
		end
	end
	local white = {}
	for k,v in pairs(self.players) do
		if v and self:check_blacklist_player(v.guid) == false then
			tinsert(white,v)
			if max_chair_id == k then
				--最大牌已经在非黑名单玩家手里
				return
			end
		end
	end
	--不存在白名单玩家
	if #white == 0 then
		return
	end
	--换牌
	local max_cards_type = deepcopy(self.player_cards_type_[max_chair_id])
	local swap_chair_id = white[math.random(1,#white)].chair_id
	self.player_cards_type_[max_chair_id] = deepcopy(self.player_cards_type_[swap_chair_id])
	self.player_cards_type_[swap_chair_id] = deepcopy(max_cards_type)

	local max_cards = deepcopy(self.gamers[max_chair_id].card)
	self.gamers[max_chair_id].card = deepcopy(self.gamers[swap_chair_id].card)
	self.gamers[swap_chair_id].card = deepcopy(max_cards)

	self.player_cards_[max_chair_id] = deepcopy(self.player_cards_[swap_chair_id])
	self.player_cards_[swap_chair_id] = deepcopy(max_cards)

	--更新日志记录
	self.gamelog.cards[max_chair_id].card = deepcopy(self.gamelog.cards[swap_chair_id].card)
	self.gamelog.cards[swap_chair_id].card = deepcopy(max_cards)

	log.info("----------------------------------------------------------------------------------------------------------")
	log.info(self.players[max_chair_id].guid,"===>",self.players[swap_chair_id].guid)
	log.info("----------------------------------------------------------------------------------------------------------")
end


function zhajinhua_table:check_kickout_no_ready()
	return
end

function zhajinhua_table:auto_ready(seconds)
	self:begin_kickout_no_ready_timer(seconds,function()
		self:cancel_kickout_no_ready_timer()
		table.foreach(self.gamers,function(p)
			if (not p.pstatus or p.pstatus~= PLAYER_STATUS.BANKRUPTCY ) and not self.ready_list[p.chair_id] then
				self:ready(p)
			end
		end)
	end)
end

function zhajinhua_table:can_sit_down(player,chair_id,reconnect)
	if reconnect then 
		if self.players[chair_id] then
			log.info("reconnect player is exist guid:   %d chairid:   d%",player.guid,chair_id)
			return enum.ERROR_NONE 
		else
			log.info("-------金花出现重入玩家-------reconnect player is not exist chairid:  %d      tableid:    %d",chair_id,self.table_id_)
			return enum.ERROR_INTERNAL_UNKOWN
		end
	end

	if self.players[chair_id] then
		return enum.ERROR_INTERNAL_UNKOWN
	end

	local cheat_check = self:check_cheat_control(player,reconnect)
	if cheat_check ~= enum.ERROR_NONE then
		return cheat_check
	end
	
	if base_rule.is_block_join_when_gaming(self.rule,self) then
		return enum.ERROR_BLOCK_JOIN_WHEN_GAMING
	end

	return enum.ERROR_NONE
end

function zhajinhua_table:is_play(player)
	if player then
		return (player.pstatus and player.pstatus  == PLAYER_STATUS.BANKRUPTCY) or (player.game_status and player.game_status ~= PLAYER_STATUS.WATCHER )  
	end

	return self.game_status and self.game_status ~= TABLE_STATUS.FREE
end

function zhajinhua_table:can_stand_up(player,reason)
	return self:lockcall(function()
		log.info("zhajinhua_table:can_stand_up guid:%s,reason:%s",player.guid,reason)
		if reason == enum.STANDUP_REASON_NORMAL or
			reason == enum.STANDUP_REASON_OFFLINE or 
			reason == enum.STANDUP_REASON_FORCE or
			reason == enum.STANDUP_REASON_DELAY_KICKOUT_TIMEOUT then
			return not self:is_play(player)
		end

		return true
	end)
end

function zhajinhua_table:on_player_sit_downed(player,reconnect)
	if not reconnect then
		self:check_kickout_no_ready()
		if self:is_play() then
			send2client(player, "SC_ZhaJinHuaTableGamingInfo",{
				players = table.map(self.players,function(p,chair)
					return chair,{
						status = p.game_status or PLAYER_STATUS.WATCHER,
						cards = (p == player and p.is_look_cards) and p.cards or nil,
						total_money = p.total_money,
						total_score = p.total_score,
						bet_score = p.bet_score,
						bet_chips = p.bet_scores,
						is_look_cards = p.is_look_cards,
						pstatus = p.pstatus
					}
				end),
				status = self.game_status,
				banker = self.banker,
				bet_round = self.bet_round,
				desk_chips = self.desk_scores,
				round = self:gaming_round(),
				desk_score = self.all_score,
				base_score = self.base_score,
				cur_bet_score = self.last_score,
			})
		end

		-- if self:is_round_gaming() then
		-- 	channel.publish("db.?","msg","SD_LogExtGameRoundPlayerJoin",{
		-- 		guid = player.guid,
		-- 		ext_round = self.ext_round_id,
		-- 	})
		-- end
	end

	self:sync_kickout_no_ready_timer(player)
end

return zhajinhua_table