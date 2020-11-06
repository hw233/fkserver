-- 炸金花逻辑

local pb = require "pb_files"
local log = require "log"
local define = require "game.zhajinhua.base.define"
local timer_manager = require "game.timer_manager"
local enum = require "pb_enums"
local card_dealer = require "card_dealer"
local cards_util = require "game.zhajinhua.base.cards_util"
local channel = require "channel"
require "data.zhajinhua_data"

local table = table
local string = string

local base_table = require "game.lobby.base_table"

local dismiss_timeout = 60

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
	self.status = nil
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
end

function zhajinhua_table:player_money(player)
	local p = type(p) == "table" and player or self.players[player]
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
		send2client_pb(player.guid,"SC_DismissTableReq",{
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


function zhajinhua_table:on_started(player_count)
	base_table.on_started(self,player_count)
	self.base_score = (self.rule and self.rule.play) and self.rule.play.base_score or self.cell_score_	
	self.all_score = 0  --总金币
	self.cur_chair = 1
	self.bet_round = 1 -- 当前回合
	self.round_turn_count = 0
    self.gamers = table.map(self.players,function(p,chair) return chair,self.ready_list[chair] and p or nil end) 
	self.show_cards_to = {}
	self.status = TABLE_STATUS.FREE
	self.banker = nil
	self.desk_scores = {}
	self.last_score = self.base_score
	local chip_scores = (self.rule and self.rule.play) and self.rule.play.chip_score or {}
	local _,max_chip_multi = table.max(chip_scores)
	self.max_score = (max_chip_multi or 1) * self.base_score

	self:cancel_clock_timer()
	self:cancel_action_timer()
	self:cancel_kickout_no_ready_timer()

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
		cur_round = self.cur_round,
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
		v.status = PLAYER_STATUS.WAIT
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
	-- self.basic_config_coeff = {}
	self.last_record = {} --上局回放
	self.black_rate = 0 --黑名单换牌概率

	--basic_config_coeff: 1 基础概率; 2 浮动概率; 3 对子概率; 4 顺子概率; 5 金花概率; 6 顺金概率,7 豹子概率;
	-- if zhajinhua_room_score[6] ~= nil then
	-- 	self.basic_config_coeff = zhajinhua_room_score[6]
	-- 	log.info("zhajinhua_table:basic_config_coeff[%d][%d][%d][%d][%d][%d][%d] ", self.basic_config_coeff[1],self.basic_config_coeff[2],self.basic_config_coeff[3],self.basic_config_coeff[4],self.basic_config_coeff[5],self.basic_config_coeff[6],self.basic_config_coeff[7])
	-- 	BASIC_COEFF = self.basic_config_coeff[1]
	-- 	FLOAT_COEFF = self.basic_config_coeff[2]
	-- 	DUIZI_COEFF = self.basic_config_coeff[3]
	-- 	SHUNZI_COEFF = self.basic_config_coeff[4]
	-- 	JINHUA_COEFF = self.basic_config_coeff[5]
	-- 	SHUNJIN_COEFF = self.basic_config_coeff[6]
	-- 	BAOZI_COEFF = self.basic_config_coeff[7]
	-- end

	self.status = TABLE_STATUS.PLAY
	self:broadcast2client("SC_ZhaJinHuaStart", {
		banker = self.banker,
		all_chairs = table.series(self.gamers,function(_,i) return i end),
		all_guids = table.series(self.gamers,function(p) return p.guid end),
		cur_round = self.cur_round,
		total_round = self.conf.round,
	})

	log.info("game start ID =%s   guid=%s   timeis:%s", self.round_id, 
		table.concat(table.series(self.players,function(p) return p.guid end)), 
		os.date("%y%m%d%H%M%S"))

	self:deal_cards()
	self:first_turn(self.banker)
end

function zhajinhua_table:cur_player()
	return self.players[self.cur_chair]
end

function zhajinhua_table:player_bet(player,score)
	local bet_score = score
	player.bet_score = (player.bet_score or 0) + bet_score
	table.insert(self.desk_scores,bet_score)
	table.insert(player.bet_scores,bet_score)
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
        log.warning("pdk_table:begin_action_timer timer not nil")
        self.auto_action_timer:kill()
    end

    self.auto_action_timer = self:new_timer(timeout,fn)

    log.info("pdk_table:begin_action_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.auto_action_timer.id,timeout)
end

function zhajinhua_table:cancel_action_timer()
	log.info("pdk_table:cancel_action_timer table_id:%s,timer:%s",self.table_id_,self.auto_action_timer and self.auto_action_timer.id or nil)
	if self.auto_action_timer then
		self.auto_action_timer:kill()
		self.auto_action_timer = nil
	end
end

function zhajinhua_table:start_player_turn(player)
	local player = type(player) == "number" and self.players[player] or player
	local actions = self:get_player_actions(player)
	self:foreach_except(player,function(p)
		send2client_pb(p,"SC_ZhaJinHuaTurn",{
			chair_id = player.chair_id,
			actions = {},
		})
	end)

	send2client_pb(player,"SC_ZhaJinHuaTurn",{
		chair_id = player.chair_id,
		actions = table.series(actions,function(v,k) return v and k or nil end),
	})

	self.waiting_actions = {}
	self.waiting_actions[player.chair_id] = actions
	local trustee_type,seconds = self:get_trustee_conf()
	if trustee_type then
		local function auto_action(p)
			if (actions[ACTION.DROP] and self.rule.play.trustee_drop) or not actions[ACTION.FOLLOW] then
				self:give_up(p)
				return
			end

			if (actions[ACTION.FOLLOW] and self.rule.play.trustee_follow) or not actions[ACTION.DROP] then
				self:follow(p)
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
	if not club or club.type ~= enum.CT_UNION then
		return
	end

	return true
end

function zhajinhua_table:check_player_money_leak(player,money)
	if not self:is_check_money_limit() then
		return
	end

	return player.remain_money < money
end

function zhajinhua_table:get_player_actions(player_or_chair)
	local player = type(player_or_chair) == "number" and self.players[player_or_chair] or player_or_chair
	local score = player.is_look_cards and self.last_score * 2 or self.last_score
	local is_money_leak = self:check_player_money_leak(player,score)
	local men_turn_count = self:get_men_turn_count()
	local play = self.rule and self.rule.play
	local can_add_score_in_men_turns = (play and play.can_add_score_in_men_turns) or (self.bet_round and self.bet_round > men_turn_count)
	return {
		[ACTION.ADD_SCORE] = not is_money_leak and self.last_score < self.max_score and can_add_score_in_men_turns,
		[ACTION.LOOK_CARDS] = not player.is_look_cards and self.bet_round > men_turn_count,
		[ACTION.DROP] = self.bet_round and self.bet_round > men_turn_count,
		[ACTION.ALL_IN] = is_money_leak and not player.all_in,
		[ACTION.COMPARE] = (self.bet_round and self.bet_round > math.max(1,men_turn_count)) and not is_money_leak,
		[ACTION.FOLLOW] = not is_money_leak,
	}
end

function zhajinhua_table:bet_base_score()
	local base_score = self.base_score
	table.foreach(self.gamers,function(p)
		self:fake_cost_money(p,base_score)
		self:player_bet(p,base_score)
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

	table.foreach(self.gamers,function(p,chair)
		local cards = dealer:deal_cards(3)
		log.info("game_id[%s]:player guid[%s] --------------> cards:[%s]",self.round_id,p.guid,table.concat(cards,","))
		p.cards_type = cards_util.get_cards_type(cards)
		p.cards = cards
	end)
end

function zhajinhua_table:ding_zhuang(winner)
	return winner and winner.chair_id or self.conf.owner.chair_id
end

function zhajinhua_table:on_process_start(player_count)
	self:foreach(function(p)
		p.total_score = 0
		p.total_money = 0 
	end)
	base_table.on_process_start(self,player_count)
end

function zhajinhua_table:on_process_over(reason)
	self:cancel_clock_timer()
	self:cancel_action_timer()
	self:cancel_kickout_no_ready_timer()
	
	self.status = nil
	self.all_score = nil
	self.last_score = nil
	self.all_scores = nil
	self.cur_chair = nil
	self.bet_round = nil -- 当前回合
	self.round_turn_count = nil
    self.gamers = nil
	self.show_cards_to = nil
	self.status = nil
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

	self:foreach(function(p) 
		p.total_money = nil
		p.total_score = nil
		p.status = nil
	end)
end

-- 检查是否可准备
function zhajinhua_table:check_ready(player)
	if self.status ~= TABLE_STATUS.FREE and  self.status ~= TABLE_STATUS.READY then
		return false
	end
	return true
end

function zhajinhua_table:compare_with_all(player)
	log.info("game_id[%s]------->all f cards",self.round_id)

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
	local gamers = table.values(self.gamers)
	if #gamers < 1 then return end

	local all_count = table.sum(self.gamers,function(p) 
		return (not p.all_in and not p.death) and 1 or 0
	end)
	table.sort(gamers,function(l,r)
		local l_death = l.death or l.all_in
		local r_death = r.death or r.all_in
		if l_death and r_death then return false end
		if l_death and not r_death then return false end
		if not l_death and r_death then return true end
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
	local c = banker_chair
	local p
	repeat
		c = (c % self.chair_count) + 1
		p = self.gamers[c]
	until (p and not p.death and not p.all_in)
	self.cur_chair = c
	log.info("---------------------------------first_turn end,turn:%s",c )
	self:start_player_turn(c)
end

-- 下一个
function zhajinhua_table:next_turn(chair)
	log.info("---------------------------------next_turn %s", #self.ready_list)
	local c = chair or self.cur_chair
	local p
	repeat
		c = c % self.chair_count + 1
		p = self.gamers[c]
	until (p and not p.death and not p.all_in)
	self.cur_chair = c
	log.info("---------------------------------next_turn end,turn:%s",self.cur_chair )
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

function zhajinhua_table:check_start(part)
	log.info("check_start-----------------")
	if self.status and self.status ~= TABLE_STATUS.FREE then
		return
	end

	local min_gamer_count = self:get_min_gamer_count()
	local player_count = table.nums(self.players)
	local ready_count = table.sum(self.players,function(_,c) return self.ready_list[c] and 1 or 0 end)
	if ready_count >= min_gamer_count then
		if ready_count == player_count then
			self:start(player_count)
		elseif not self.cur_round and ready_count < player_count then
			local trustee,seconds = self:get_trustee_conf()
			if trustee then
				self:begin_kickout_no_ready_timer(seconds,function()
					self:cancel_kickout_no_ready_timer()
					self:start(player_count)
				end)
			end
		end
	end
end

-- 重新上线
function zhajinhua_table:reconnect(player)
	if self.gamelog and self.round_id then
		log.info("zhajinhua_table:game_id[%s] reconnect---------->guid[%d],chair_id[%d]",self.round_id,player.guid,player.chair_id)
	else
		log.info("zhajinhua_table:reconnect---------->guid[%d],chair_id[%d]",player.guid,player.chair_id)
	end

	send2client_pb(player, "SC_ZhaJinHuaReconnect",{
		players = table.map(self.players,function(p,chair)
			return chair,{
				status = p.status or PLAYER_STATUS.WATCHER,
				cards = (p == player and p.is_look_cards) and p.cards or nil,
				total_money = p.total_money,
				total_score = p.total_score,
				bet_score = p.bet_score,
				bet_chips = p.bet_scores,
				is_look_cards = p.is_look_cards,
			}
		end),
		status = self.status,
		banker = self.banker,
		bet_round = self.bet_round,
		desk_chips = self.desk_scores,
		round = self.cur_round,
		desk_score = self.all_score,
		base_score = self.base_score,
		cur_bet_score = self.last_score,
	})

	if self.status == TABLE_STATUS.PLAY then
		send2client_pb(player,"SC_ZhaJinHuaTurn",{
			chair_id = self.cur_chair,
			actions = player.chair_id == self.cur_chair and 
				table.series(self.waiting_actions[self.cur_chair],function(v,k) return v and k or nil end) or 
				nil,
		})

		if self.clock_timer then
			self:begin_clock(self.clock_timer.remainder,player)
		end
	end

	base_table.reconnect(self,player)
end

function zhajinhua_table:load_lua_cfg()

end

--玩家游戲結束后亮牌給所有玩家
function zhajinhua_table:show_cards_to_all(player,info)
	if info.cards ~= nil then
		self:foreach_except(player,function(p) 
			send2client_pb(p, "SC_ZhaJinHuaShowCardsToAll",{
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
		send2client_pb(player, "SC_ZhaJinHuaLastRecord", self.last_record[player.guid])
	else
		send2client_pb(player, "SC_ZhaJinHuaLastRecord", {
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
		table.insert(sp_cards,tempcards)
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
		table.insert(sp_cards,remain_cards)
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

function zhajinhua_table:follow(player)
	if not self.gamers[player.chair_id] or 
		not self:check_player_action(player,ACTION.FOLLOW) then
		send2client_pb(player,"SC_ZhaJinHuaFollowBet",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	self:cancel_clock_timer()
	self:cancel_action_timer()

	local score = player.is_look_cards and self.last_score * 2 or self.last_score
	local is_all_in = self:is_check_money_limit() and player.remain_money < score or false	
	score = is_all_in and player.remain_money or score

	self:player_bet(player,score)

	table.insert(self.gamelog.actions, {
		action = "follow",
		chair_id = player.chair_id,
		turn = self.bet_round,
		score = score,
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
	end

	self:next_turn()
end

function zhajinhua_table:cs_follow(player,msg)
	self:follow(player,msg)
end

function zhajinhua_table:all_in(player)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.ALL_IN) then
		send2client_pb(player,"SC_ZhaJinHuaAllIn",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	self:cancel_clock_timer()
	self:cancel_action_timer()

	local score = player.remain_money
	self:player_bet(player,score)
	player.all_in = true

	local is_win = self:compare_with_all(player)
	self:broadcast2client("SC_ZhaJinHuaAllIn",{
		chair_id = player.chair_id,
		score = score,
		is_win = is_win,
	})

	self:next_turn()
end

function zhajinhua_table:cs_all_in(player,msg)
	self:all_in(player,msg)
end

-- 加注
function zhajinhua_table:add_score(player,msg)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.ADD_SCORE) then
		send2client_pb(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	local score = msg.score
	log.info("game_id[%s] player guid[%d]--------> add score[%d]",self.round_id,player.guid,score)

	if score < 0 then
		log.warning("game_id[%s]: add_score guid[%d] status error  is score %s < 0", self.round_id, player.guid,score)
		send2client_pb(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	if player.all_in then
		log.warning("game_id[%s]: add_score guid[%d] status error  is all_score_  true", self.round_id, player.guid)
		send2client_pb(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	if player.death then
		log.error("game_id[%s]:add_score guid[%d] is dead", self.round_id,player.guid)
		send2client_pb(player,"SC_ZhaJinHuaAddScore",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	self:cancel_clock_timer()
	self:cancel_action_timer()

	local is_all_in = false
	if self:is_check_money_limit() then
		score = score > self.max_score and self.max_score or score

		score = player.remain_money < score and player.remain_money or score

		--第一个全压的人
		if not self.ball_begin then
			--获取玩家数量
			if table.sum(self.gamers,function(p) return not p.death and 1 or 0 end) == 2 then
				local min_score = table.min(
						table.select(self.gamers,function(p) return not p.death end),
						function(p)  return p.remain_money end
					)

				local all_add_score = (21 - self.bet_round) * self.base_score * 20

				all_add_score = min_score < all_add_score and min_score or all_add_score

				self.max_score = all_add_score
				score = all_add_score

				log.info("game_id [%s]: guid[%s] add_score self.max_score[%s]:", self.round_id,player.guid,self.max_score)
			else
				log.warning("game_id[%s]: add_score guid[%s] status error",self.round_id, player.guid)
				return
			end
		end
	end

	if score < self.last_score then
		log.error("game_id[%s]:add_score guid[%d] score[%d] < last[%d]",self.round_id, player.guid, score, self.last_score)
		return
	end

	if score > self.max_score then
		log.error("game_id[%s]:add_score guid[%s] score[%s] > max[%s]",self.round_id, player.guid, money_add, self.max_score)
		return
	end

	self.last_score = score

	local score_add = player.is_look_cards and score * 2 or score
	log.info("game_id[%s]: player guid[%d]----->score[%d],money[%d].",self.round_id,player.guid,score, score_add)

	-- if score_add <= 0 or player.remain_money < score_add then
	-- 	log.error("game_id[%s]:add_score guid[%d] money[%d] > player_money[%d]",self.round_id, player.guid, score_add, player.remain_money)
	-- 	return false
	-- end

	self:fake_cost_money(player,score_add)
	self:player_bet(player,score_add)
	
	--日志处理
	table.insert(self.gamelog.actions,{
		action = is_all_in and "all_in" or "add_score",
		chair_id = player.chair_id,
		score = score_add, -- 注码
		turn = self.bet_round,
	})

	log.info("-------------------is_all: %s",is_all_in)
	self:broadcast2client("SC_ZhaJinHuaAddScore", {
		result = enum.NONE,
		chair_id = player.chair_id,
		score = score_add,
	})

	--处理全押
	
	local cur_player = self:cur_player()
	if is_all_in then
		log.info("game_id[%s]:player guid[%d]--------->all score money score[%d]", self.round_id,player.guid,score_add)
		player.all_in = true

		if cur_player.all_in then
			self:compare(self.players[self.cur_chair], player.chair_id, true, true)
		end

		self.ball_begin = true
	end

	self:next_turn()
end

function zhajinhua_table:cs_add_score(player,msg)
	self:add_score(player,msg)
end

-- 放弃跟注
function zhajinhua_table:give_up(player)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.DROP) then
		send2client_pb(player,"SC_ZhaJinHuaGiveUp",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	local chair_id = player.chair_id
	log.info("game_id[%s]:player guid[%d]------> give_up", self.round_id,player.guid)

	if player.death then
		log.error("game_id[%s]:add_score guid[%d] is dead", self.round_id,player.guid)
		send2client_pb(player,"SC_ZhaJinHuaGiveUp",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if self.ball_begin and self.cur_chair ~= chair_id then
		log.error("game_id[%s]:give_up is ball_begin guid[%d] can not giveup charid [%d] cur_turn[%d]",self.round_id, player.guid, player.charid , self.cur_chair)
	end

	self:cancel_clock_timer()
	self:cancel_action_timer()

	player.death = true
	player.status = PLAYER_STATUS.DROP

	--日志处理
	table.insert(self.gamelog.actions, {
		action = "giveup",
		chair_id = chair_id,
		now_chair = self.cur_chair,
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
	if 	self.status == TABLE_STATUS.PLAY and
		self.cur_chair == chair and 
		self.waiting_actions and 
		self.waiting_actions[chair] and 
		self.waiting_actions[chair][action] then
		return true
	end

	log.warning("zhajinhua_table:check_player_action invalid operation,chair:%s,action:%s",chair,action)
end
-- 看牌
function zhajinhua_table:look_card(player)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.LOOK_CARDS) then
		send2client_pb(player,"SC_ZhaJinHuaLookCard",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	self:cancel_clock_timer()
	self:cancel_action_timer()

	log.info("game_id[%s]:player guid[%d]-------------->look cards",self.round_id,player.guid)

	--全压已经取了钱最少玩家的所有钱，不受看牌×2规则影响，所以可以看牌
	--if self.ball_begin and player.remain_money < (self.max_score  * 2)  then
	--	log.error("zhajinhua_table:look_card guid[%d] player_money[%d] max_money[%d] ball_begin and player money error", player.guid,player.remain_money,self.max_score)
	--	return
	--end

	player.is_look_cards = true

	send2client_pb(player, "SC_ZhaJinHuaLookCard", {
		chair_id = player.chair_id,
		cards = player.cards,
	})

	self:broadcast2client_except(player, "SC_ZhaJinHuaLookCard", {
		chair_id = player.chair_id,
	})

	--日志处理
	table.insert(self.gamelog.actions, {
		action = "look_cards",
		chair_id = player.chair_id,
		turn = self.bet_round,
	})

	self:start_player_turn(player)
end

function zhajinhua_table:cs_look_card(player,msg)
	self:look_card(player,msg)
end


-- 终
 -- 比牌
function zhajinhua_table:compare(player, msg)
	if not self.gamers[player.chair_id] or
		not self:check_player_action(player,ACTION.COMPARE) then
		send2client_pb(player,"SC_ZhaJinHuaCompareCards",{
			result = enum.ERROR_OPERATION_INVALID,
		})
		return
	end

	local compare_with = msg.compare_with

	local chair_id = player.chair_id
	log.info("game_id[%s]:player guid[%d] chair_id[%d]-------------->compare_with[%d] COMPARE_CARD",self.round_id,player.guid,player.chair_id,compare_with)

 	local target = self.players[compare_with]
 	if not target then
		log.error("game_id[%s]:compare guid[%d] compare[%d] error",self.round_id, player.guid, compare_with)
		send2client_pb(player,"SC_ZhaJinHuaCompareCards",{
			result = enum.ERROR_OPERATION_INVALID
		})
 		return
	end

	if player.all_in or target.all_in or player.death or target.death then
		log.error("game_id[%s]:compare error compare [%s]vs[%s]  is dead",self.round_id, player.guid,target.guid)
		send2client_pb(player,"SC_ZhaJinHuaCompareCards",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

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

	log.info("game_id[%s]:player guid[%d],target guid[%d]----------> win[%s].",self.round_id,player.guid,target.guid,ret)

	local loser = is_win and target or player
	local winner = is_win and player or target
	loser.death = true
	loser.status = PLAYER_STATUS.LOSE
	
	--日志处理
	log.info("game_id[%s]: player guid[%d] charid[%d] , target guid[%d] ,turn [%d] , otherplayer [%d] money[%d] win [%s]" ,
		self.round_id,player.guid,chair_id,target.guid,self.bet_round,compare_with,score,ret)
	table.insert(self.gamelog.actions, {
		action = "compare",
		chair_id = chair_id,
		turn = self.bet_round,
		compare_with = compare_with,		--被比牌玩家
		money = score,		--比牌花费
		win = is_win,		--是否获胜
		score = score,
	})

	self:broadcast2client("SC_ZhaJinHuaCompareCards",{
		comparer = player.chair_id,
		compare_with = target.chair_id,
		winner = winner.chair_id,
		loser = loser.chair_id,
		score = score,
	})

	if self:is_end() then
		log.info("game_id[%s]:------------->This Game Is  Over!",self.round_id)
		self:calllater(1.5,function() --比牌动画延时
			self:game_balance()
		end)
		return
	end

	self:next_turn()
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
	if not winner then
		local winners = table.select(self.gamers,function(p) return not p.death end,true)
		winner = winners[1]
	end

	self.winner = winner

	log.info("game_id[%s]: game_balance---->Game is Over !!",self.round_id)
	self.status = TABLE_STATUS.FREE

	local winner_score = self.all_score - winner.bet_score
	local scores = table.map(self.gamers,function(p,chair)
		if p == winner then  return chair,winner_score end
		return chair,- p.bet_score
	end)

	local bonus_scores = self:balance_bonus(winner)
	table.mergeto(scores,bonus_scores,function(l,r)
		return (l or 0) + (r or 0) 
	end)

	log.dump(scores)
	
	local moneies = self:balance(table.map(scores,function(s,chair) 
		return chair,self:calc_score_money(s) end
	),enum.LOG_MONEY_OPT_TYPE_ZHAJINHUA)

	log.dump(moneies)

	table.foreach(self.gamers,function(p,chair)
		p.total_score = (p.total_score or 0) + scores[chair]
		p.total_money = (p.total_money or 0) + moneies[chair]
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
				status = p.status,
				total_score = p.total_score,
				total_money = p.total_money,
				cards = p.cards,
				bet_score = p.bet_score,
			}
		end)
	})

	self.last_record = nil

	self:save_game_log(self.gamelog)

	self:check_single_game_is_maintain()
	self:game_over()
end

function zhajinhua_table:on_game_overed()
	log.info("game end ID =%s   guid=%s   timeis:%s", self.round_id, self.log_guid, os.date("%y%m%d%H%M%S"))
	self:cancel_clock_timer()
	self:cancel_action_timer()
	self:cancel_kickout_no_ready_timer()

	self:clear_ready()
	log.info("self.chair_count %s", self.chair_count)

	self.desk_scores = nil
	self.all_score = 0
	self.last_score = 0
	self.bet_round = nil
	self.status = TABLE_STATUS.FREE
	table.foreach(self.gamers,function(p) 
		p.status = PLAYER_STATUS.FREE
		p.all_in = nil
		p.death = nil
		p.is_look_cards = nil
		p.bet_score = nil
		p.remain_money = nil
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

function zhajinhua_table:can_stand_up(player,reason)
	if  reason == enum.STANDUP_REASON_FORCE or 
		reason == enum.STANDUP_REASON_DISMISS 
	then
		return true
	end

	if reason == enum.STANDUP_REASON_OFFLINE then
		return false
	end

	return not player.status or player.status == PLAYER_STATUS.WATCHER
end

--替换玩家cost_money方法，先缓存，稍后一起扣钱
function zhajinhua_table:fake_cost_money(player,score)
	local money = self:calc_score_money(score)
	local remain = player.remain_money
	if self.gamelog and self.round_id then
		log.info("game_id[%s]: player guid[%d] cur money[%d],money[%d].",self.round_id,player.guid,money,money)
	else
		log.info("player guid[%d] cur money[%d],money[%d].",player.guid,money,money)
	end

	if self:check_player_money_leak(player,money) then 
		log.error("game_id[%s]:guid[%d] fake_cost_money error.curmoney[%d], must cost money[%d]",self.round_id,player.guid,remain,money)
		return false
	end

	player.remain_money = player.remain_money - money

	local new_money = player.remain_money
	if self.gamelog and self.round_id then
		log.info("game_id[%s]: player guid[%d] new_money[%d],money[%d].",self.round_id,player.guid,new_money,money)
	else
		log.info("player guid[%d] new_money[%d],money[%d].",player.guid,new_money,money)
	end

	player:notify_money(self:get_money_id(),new_money)

	return true
end

--替换玩家get_money方法
function zhajinhua_table:get_player_money(player)
	return player.remain_money
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
					add_timer(math.random(2,4),add_score_timer_func)
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
							add_timer(math.random(2,4),add_score_timer_func)
						else
							score = 1
						end
					end
				end
			else
				if r < 90 and self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					add_timer(math.random(2,4),add_score_timer_func)
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
							add_timer(math.random(2,4),add_score_timer_func)
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
					add_timer(math.random(2,4),add_score_timer_func)
				else
					score = 1
				end
			else
				--弃牌
				if self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					add_timer(math.random(2,4),add_score_timer_func)
				else
					self:give_up(player)
				end
			end
		end
		if self:is_compare_card() then
			log.error("is compare card guid[%d]", player.guid)
			return
		end
		if score and self:check_compare_cards(player) == false then
			self:add_score(player, score)
		else
			log.error("guid[%d] add score No score", player.guid)
		end
	end
	add_timer(time,add_score_timer_func)
end

--全比
function zhajinhua_table:check_compare_cards(player)
	local cout = table.sum(self.death,function(_,chair) return not self.death[chair] and 1 or 0 end)
	local last_score = self.last_score
	if self.is_look_card_[player.chair_id] then
		last_score = self.last_score * 2
	end

	local player_score = player.remain_money
	if player_score < last_score and not player.death and cout >= 3 then
		--触发全比
		local money_ = player_score
		self:fake_cost_money(player,money_)

		self:player_bet(player,money_)

		--日志处理
		table.insert(self.gamelog.actions, {
			action = "add_score",
			chair_id = player.chair_id,
			score = player_score, -- 注码
			money = player_score,
			turn = self.bet_round,
			isallscore = false ,  --是否全压
			isallcom = true, --是否为全比
		})

		self:broadcast2client("SC_ZhaJinHuaAddScore", {
			add_score_chair_id = player.chair_id,
			cur_chair_id = self.cur_chair,
			score = score_,
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
			player.status = PLAYER_LOSE
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
			table.insert(white,v)
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
			if not self.ready_list[p.chair_id] then
				self:ready(p)
			end
		end)

		local min_gamer_count = self:get_min_gamer_count()
		local player_count = table.nums(self.players)
		local ready_count = table.sum(self.players,function(_,chair) 
			return self.ready_list[chair] and 1 or 0 
		end)
		if ready_count < player_count and ready_count >= min_gamer_count then
			self:start(player_count)
		end
	end)
end

function zhajinhua_table:can_sit_down(player,chair_id,reconnect)
	if reconnect then 
		return enum.ERROR_NONE 
	end

	if self.players[chair_id] then
		return enum.ERROR_INTERNAL_UNKOWN
	end

	local cheat_check = self:check_cheat_control(player,reconnect)
	if cheat_check ~= enum.ERROR_NONE then
		return cheat_check
	end

	return enum.ERROR_NONE
end

function zhajinhua_table:is_play(player)
	if player then
		return player.status
	end

	return self.status
end

function zhajinhua_table:on_player_sit_downed(player,reconnect)
	if not reconnect then
		self:check_kickout_no_ready()
		if self:is_play() then
			send2client_pb(player, "SC_ZhaJinHuaTableGamingInfo",{
				players = table.map(self.players,function(p,chair)
					return chair,{
						status = p.status or PLAYER_STATUS.WATCHER,
						cards = (p == player and p.is_look_cards) and p.cards or nil,
						total_money = p.total_money,
						total_score = p.total_score,
						bet_score = p.bet_score,
						bet_chips = p.bet_scores,
						is_look_cards = p.is_look_cards,
					}
				end),
				status = self.status,
				banker = self.banker,
				bet_round = self.bet_round,
				desk_chips = self.desk_scores,
				round = self.cur_round,
				desk_score = self.all_score,
				base_score = self.base_score,
				cur_bet_score = self.last_score,
			})
		end

		if self.cur_round then
			channel.publish("db.?","msg","SD_LogExtGameRoundPlayerJoin",{
				guid = player.guid,
				ext_round = self.ext_round_id,
			})
		end
	end

	self:sync_kickout_no_ready_timer(player)
end

return zhajinhua_table