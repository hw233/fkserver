

local base_table = require "game.lobby.base_table"
local log = require "log"
local card_dealer = require "card_dealer"
local enum = require "pb_enums"
local cards_util = require "game.pdk_sc.cards_util"
local club_utils = require "game.club.club_utils"
local def = require "game.pdk_sc.define"
require "functions"

local table = table
local tinsert = table.insert
local math = math

local CARDS_TYPE = def.CARDS_TYPE

-- 开始游戏倒记时
local PDK_TIME_START_COUNTDOWN = 3
-- 出牌时间
local PDK_TIME_OUT_CARD = 15
-- 叫分时间
local PDK_TIME_CALL_SCORE = 15
-- 首出时间
local PDK_TIME_HEAD_OUT_CARD = 15
-- 玩家掉线等待时间
local PDK_TIME_WAIT_OFFLINE = 30

local TRIPLE_BOMB_SCORE = 5
local BOMB_SCORE = 10
local CHUN_TIAN_TIMES = 2
local FAN_CHUN_TIMES = 3

local ACTION = def.ACTION

local TABLE_STATUS = {
	NONE = 0,
	-- 等待开始
	FREE = 1,
	-- 开始倒记时
	START_COUNT_DOWN = 2,
	-- 游戏进行
	PLAY = 3,
	-- 结束阶段
	END = 4,
}

local all_cards = {
	5,6,7,8,9,10,11,12,13,14,
	25,26,27,28,29,30,31,32,33,34,
	45,46,47,48,49,50,51,52,53,54,
	65,66,67,68,69,70,71,72,73,74,
}

local pdk_table = setmetatable({},{__index = base_table})



function pdk_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.status = TABLE_STATUS.FREE
end

function pdk_table:on_private_inited()
    self.cur_round = nil
	self.zhuang = nil
end

function pdk_table:on_private_dismissed()
	self:cancel_discard_timer()
    log.info("pdk_table:on_private_dismissed")
    self.cur_round = nil
    self.zhuang = nil
    self.status = nil
    for _,p in pairs(self.players) do
        p.total_money = nil
	end

	base_table.on_private_dismissed(self)
end

function pdk_table:on_private_pre_dismiss()
	
end

function pdk_table:can_dismiss()
	return true
end

function pdk_table:ding_zhuang()
	local function with_5_zhuang()
		for chair,p in pairs(self.players) do
			if p.hand_cards[5] then return chair end
		end
	end

	local function room_owner_zhuang()
		if not self.private_id then
			log.error("pdk_table:ding_zhuang zhuang room owner but not private table.")
			return
		end

		return self.conf.owner.chair_id
	end

	local function winner_zhuang()
		if not self.cur_round or self.cur_round == 1 then return end
		
		for chair,p in pairs(self.players) do
			if p.win then return chair end
		end
	end

	local ding_zhuang_fn = {
		[0] = winner_zhuang,
		[1] = room_owner_zhuang,
		[2] = with_5_zhuang,
	}

	if self:is_private() then
		local zhuang_conf = self.rule and self.rule.play and self.rule.play.zhuang or {}
		local zhuang_opt = zhuang_conf.normal_round or 1
		self.zhuang = ding_zhuang_fn[zhuang_opt]() or winner_zhuang() or room_owner_zhuang()
	end
end

function pdk_table:on_process_start()
	base_table.on_process_start(self)
	self:foreach(function(p) 
		p.statistics = {}
		p.total_score = 0
		p.total_money = 0
	end)
end

function pdk_table:on_started(player_count)
	log.info("pdk_table:on_started %s.",player_count)

	self.start_count = player_count
	base_table.on_started(self,player_count)

	self:cancel_clock_timer()

	self:update_status(TABLE_STATUS.PLAY)

	self.game_log = {
		start_game_time = os.time(),
		players = table.map(self.players,function(p,chair) 
			return chair,{
				guid = p.guid,
				chair_id = chair,
			}
		end),
		actions = {},
		rule = self.private_id and self.rule or nil,
		club = (self.private_id and self.conf.club) and club_utils.root(self.conf.club).id,
		table_id = self.private_id or nil,
	}

	self.bomb = 0
	self.last_discard = nil

	log.info("gamestart ====================")
	self:foreach(function(p) 
		log.info("Player InOut Log,pdk_table:startGame player %s, table_id %s ,private_table_id:%s",p.guid,p.table_id,self.private_id)
	end)

	self:deal_cards()
	self:ding_zhuang()
	self.cur_discard_chair = self.zhuang
	self.game_log.zhuang = self.zhuang

	self.first_discard = true

	self:foreach(function(p)
		p.win = nil
		p.round_score = nil
		p.round_money = nil
		p.discard_times = nil
		p.bomb = nil
	end)

	self:begin_discard()
end

function pdk_table:deal_cards()
	local all_count = self.start_count * 10
	local cards = {5}
	local c_cards = clone(all_cards)
	local k = #c_cards
	local n = 1
	while n <= all_count - 1 do
		local i = math.random(1,k)
		local c = c_cards[i]
		if c ~= 5 then
			tinsert(cards,c)
			n = n + 1
		end

		c_cards[i],c_cards[k] = c_cards[k],c_cards[i]
		k = k - 1
	end

	local dealer = card_dealer.new(cards)
	dealer:shuffle()
	local pei_cards = {
		-- {5,25,45,6,26,46,7,27,47,8},
		-- {10,30,50,70,11,31,51,71,12,32,52,72,13,33,53,73},
	}
	dealer:layout_cards(table.union_tables(pei_cards))

	local laizi_value
	local play = self.rule and self.rule.play or {}
	if play.lai_zi then
		laizi_value = math.random(5,14)
		self.laizi = cards_util.laizi_card(laizi_value)
	end

	self:foreach(function(p,chair)
		local cards = dealer:deal_cards(10)
		if laizi_value then
			cards = table.series(cards,function(c)
				return cards_util.value(c) == laizi_value and self.laizi or c
			end)
		end
		self.game_log.players[chair].deal_cards = cards
		p.hand_cards = cards_util.series2kc(cards)
		p.zha_niao =  play.zha_niao and table.Or(cards,function(c) return c == 30 end) or nil
		if play.special_score then
			p.quan_hei = self:quan_hei(cards)
			p.quan_hong = self:quan_hong(cards)
			p.quan_da = self:quan_da(cards)
			p.quan_xiao = self:quan_xiao(cards)
			p.quan_dan = self:quan_dan(cards)
			p.quan_suang = self:quan_suang(cards)
		end
	end)

	self:foreach(function(p)
		self:send_desk_enter_data(p)
	end)
end

function pdk_table:begin_discard()
	self:broadcast2client("SC_PdkDiscardRound",{
		chair_id = self.cur_discard_chair
	})

	local function auto_discard(player)
		if not self.last_discard then
			local cards,replace = cards_util.try_greatest(player.hand_cards,self.rule,self.laizi,self.first_discard)
			assert(cards and #cards > 0)
			self:do_action_discard(player,cards,replace)
		else
			local cards,replace = cards_util.try_great_than(player.hand_cards,self.last_discard.type,self.last_discard.value,self.last_discard.count,self.rule,self.laizi)
			if not cards then
				self:do_action_pass(player)
			else
				assert(cards and #cards > 0)
				self:do_action_discard(player,cards,replace)
			end
		end
	end

	local trustee_type,trustee_seconds = self:get_trustee_conf()
	if trustee_type and trustee_seconds then
		local player = self:cur_player()
		self:begin_clock_timer(trustee_seconds,function()
			auto_discard(player)
			self:set_trusteeship(player,true)
		end)

		if player.trustee then
			self:begin_discard_timer(math.random(1,2),function()
				auto_discard(player)
			end)
		end
	end
end

function pdk_table:begin_clock_timer(timeout,fn)
	if self.clock_timer then 
        log.warning("pdk_table:begin_clock_timer timer not nil")
        self.clock_timer:kill()
    end

    self.clock_timer = self:new_timer(timeout,fn)
    self:begin_clock(timeout)

    log.info("pdk_table:begin_clock_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.clock_timer.id,timeout)
end

function pdk_table:cancel_clock_timer()
	log.info("pdk_table:cancel_clock_timer table_id:%s,timer:%s",self.table_id_,self.clock_timer and self.clock_timer.id or nil)
    if self.clock_timer then
        self.clock_timer:kill()
        self.clock_timer = nil
    end
end

function pdk_table:begin_discard_timer(timeout,fn)
	if self.auto_discard_timer then 
        log.warning("pdk_table:begin_discard_timer timer not nil")
        self.auto_discard_timer:kill()
    end

    self.auto_discard_timer = self:new_timer(timeout,fn)

    log.info("pdk_table:begin_discard_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.auto_discard_timer.id,timeout)
end

function pdk_table:cancel_discard_timer()
	log.info("pdk_table:cancel_discard_timer table_id:%s,timer:%s",self.table_id_,self.auto_discard_timer and self.auto_discard_timer.id or nil)
	if self.auto_discard_timer then
		self.auto_discard_timer:kill()
		self.auto_discard_timer = nil
	end
end

function pdk_table:send_desk_enter_data(player,reconnect)
	local msg = {
		status = self.status,
		zhuang = self.zhuang,
		self_chair_id = player.chair_id,
		act_time_limit = nil,
		is_reconnect = reconnect,
		round = self:gaming_round(),
		pb_players = table.series(self.players,function(p,chair)
			local d = {
				chair_id = chair,
				total_score = p.total_score,
			}
	
			if self.status == TABLE_STATUS.PLAY then
				if p == player then 
					d.hand_cards = cards_util.kc2series(p.hand_cards)
				else  
					d.hand_cards = table.fill({},255,1,table.sum(p.hand_cards)) 
				end
			end
	
			if self.status ~= TABLE_STATUS.FREE then
				d.round_score = p.round_score
			end
	
			return d
		end),
		pb_rec_data = reconnect and {
			act_left_time = nil,
			last_discard_chair = self.last_discard and self.last_discard.chair or nil,
			last_discard = self.last_discard and self.last_discard.cards or nil,
			total_scores = table.map(self.players,function(p,chair) return chair,p.total_score end),
			total_money = table.map(self.players,function(p,chair) return chair,p.total_money end),
			laizi_replace = self.last_discard and self.last_discard.laizi_replace or nil,
		} or nil,
		laizi = self.laizi,
	}

	if reconnect then
		local trustee_type = self:get_trustee_conf()
		if trustee_type then
			self:set_trusteeship(player)
		end
	end

	if self:is_round_gaming() then
		send2client(player,"SC_PdkDeskEnter",msg)
	end
end

function pdk_table:on_game_overed()
    self.game_log = {}
	
    self:clear_ready()

    self:foreach(function(p)
		p.statistics.bomb = (p.statistics.bomb or 0) + (p.bomb or 0) + (p.triple_bomb or 0)
		p.bomb = nil
		p.triple_bomb = nil
	end)

	self.status = TABLE_STATUS.FREE
	base_table.on_game_overed(self)
end

function pdk_table:on_process_over(reason)
	self:cancel_discard_timer()
	self:cancel_clock_timer()
	
    self:broadcast2client("SC_PdkFinalGameOver",{
		players = table.series(self.players,function(p,chair)
			local statistics = table.series(p.statistics or {},function(c,t) 
				return {type = t == "win" and 1 or (t == "max_score" and 2 or (t == "bomb" and 3 or 0)),count = c}
			end)
			log.dump(statistics,tostring(chair))
			return {
				chair_id = chair,
				guid = p.guid,
				score = p.total_score or 0,
				money = p.total_money or 0,
				statistics = statistics,
			}
		end),
    })

    local total_winlose = {}
    for _,p in pairs(self.players) do
        total_winlose[p.guid] = p.total_money or 0
    end

    self:cost_tax(total_winlose)
	self.status = nil

    for _,p in pairs(self.players) do
        p.total_money = nil
        p.round_money = nil
        p.total_score = nil
    end

	self.zhuang = nil
	base_table.on_process_over(self,reason,{
        balance = total_winlose,
    })
end

function pdk_table:next_chair()
	local chair = self.cur_discard_chair
	repeat
		chair = chair  % self.start_count + 1
	until self.players[chair] ~= nil

	return chair
end

function pdk_table:update_status(status)
	self.status = status
end

function pdk_table:cur_player()
	return self.players[self.cur_discard_chair]
end

function pdk_table:do_action(player,act)
	self.lock(function()
		if not act or not act.action then
			log.error("pdk_table:do_action act is nil.")
			return
		end

		log.dump(act)

		local do_actions = {
			[ACTION.DISCARD] = function(act)
				self:do_action_discard(player,act.cards,act.laizi_replace)
			end,
			[ACTION.PASS] = function(act)
				self:do_action_pass(player)
			end,
		}

		local fn = do_actions[act.action]
		if fn then
			fn(act)
			return
		end

		log.error("pdk_table:do_action invalid action:%s",act.action)
	end)
end

function pdk_table:check_first_discards_with_5(cards)
	local play = self.rule and self.rule.play
	if not play then return true end

	-- 首张带黑桃5
	if self.first_discard and play.first_discard and play.first_discard.with_5 then
		return table.Or(cards,function(c) return c == 5 end) 
	end
	
	return true
end

function pdk_table:get_cards_type(cards,laizi_replace)
	local cardstype, cardsval = cards_util.get_cards_type(cards,self.rule,self.laizi,laizi_replace)
	return cardstype,cardsval
end

-- 出牌
function pdk_table:do_action_discard(player, cards,laizi_replace)
	log.info("pdk_table:do_action_discard {%s}",table.concat(cards,","))
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("pdk_table:discard guid[%d] status error", player.guid)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("pdk_table:discard guid[%s] chair[%s] error", player.guid, player.chair_id)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local kccards = player.hand_cards
	if not table.And(cards,function(c) return kccards[c] and kccards[c] > 0  end) then
		log.warning("pdk_table:discard guid[%d] cards[%s] error, has[%s]", player.guid, table.concat(cards, ','), 
			table.concat(table.keys(player.hand_cards), ','))
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if not self:check_first_discards_with_5(cards) then
	 	log.warning("pdk_table:discard guid[%d] not with 5, cards[%s]", player.guid, table.concat(cards, ','))
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	local cardstype, cardsval = self:get_cards_type(cards,laizi_replace)
	log.info("cardstype[%s] cardsval[%s]" , cardstype , cardsval)
	if not cardstype then
		log.warning("pdk_table:discard guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cards, ','))
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local cmp = cards_util.compare_cards({type = cardstype, count = #cards, value = cardsval}, self.last_discard)
	if self.last_discard and (not cmp or cmp <= 0) then
		log.warning("pdk_table:discard guid[%d] compare_cards error, cards[%s], cur_discards[%d,%d,%d], last_discard[%d,%d,%d]", 
			player.guid, table.concat(cards, ','),cardstype, #cards,
			cardsval,self.last_discard.type,self.last_discard.count,self.last_discard.value)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	self:cancel_discard_timer()
	self:cancel_clock_timer()

	self.last_discard = {
		cards = cards,
		chair = player.chair_id,
		type = cardstype,
		value = cardsval,
		count = #cards,
		laizi_replace = laizi_replace,
	}

	self.first_discard = nil

	player.discard_times = (player.discard_times or 0) + 1

	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.DISCARD,
		cards = cards,
		laizi_replace = laizi_replace,
	})

	log.info("pdk_table:do_action_discard  chair_id [%d] cards{%s}", player.chair_id, table.concat(cards, ','))
	
	local kvcards = player.hand_cards
	table.foreach(cards,function(c)
		local n = kvcards[c] - 1
		kvcards[c] = n > 0 and n or nil
	end)

	tinsert(self.game_log.actions,{
		action = ACTION.DISCARD,
		chair_id = player.chair_id,
		cards_type = cardstype,
		cards = cards,
		laizi_replace = laizi_replace,
		time = os.time(),
	})

	local cardsum = table.sum(player.hand_cards)
	if  cardsum == 0 then
		player.win = true
		player.statistics.win = (player.statistics.win or 0) + 1
		if cardstype >= CARDS_TYPE.SOFT_BOMB then
			player.bomb = (player.bomb or 0) + 1
		elseif cardstype >= CARDS_TYPE.SOFT_TRIPLE_BOMB then
			player.triple_bomb = (player.triple_bomb or 0) + 1
		end
		self:game_balance(player)
	else
		self.cur_discard_chair = self:next_chair()
		self:begin_discard()
	end
end

-- 放弃出牌
function pdk_table:do_action_pass(player)
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("pdk_table:pass_card guid[%d] status error", player.guid)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("pdk_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_discard_chair)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if not self.last_discard then
		log.error("pdk_table:pass_card guid[%d] first turn", player.guid)
		send2client(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	self:cancel_discard_timer()
	self:cancel_clock_timer()

	-- 记录日志
	tinsert(self.game_log.actions,{
		chair_id = player.chair_id,
		action = ACTION.PASS,
		time = os.time(),
	})

	log.info("cur_chair_id[%d],pass_chair_id[%d]",self.cur_discard_chair,player.chair_id)
	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.PASS
	})

	self.cur_discard_chair = self:next_chair()

	if self.last_discard and self.cur_discard_chair == self.last_discard.chair  then
		local p = self:cur_player()
		if self.last_discard.type >= CARDS_TYPE.SOFT_BOMB then
			p.bomb = (p.bomb or 0) + 1
		elseif self.last_discard.type >= CARDS_TYPE.SOFT_TRIPLE_BOMB then
			p.triple_bomb = (p.triple_bomb or 0) + 1
		end
		self.last_discard = nil
	end

	self:begin_discard()
end

--玩家上线处理
function  pdk_table:reconnect(player)
	-- 新需求 玩家掉线不暂停游戏 只是托管
	log.info("pdk_table:reconnect guid:%s",player.guid)
	self:send_desk_enter_data(player,true)
	if self.status == TABLE_STATUS.PLAY then
		send2client(player,"SC_PdkDiscardRound",{
			chair_id = self.cur_discard_chair
		})
	end

	if self.clock_timer then
		self:begin_clock(self.clock_timer.remainder,player)
	end
	base_table.reconnect(self,player)
end

function  pdk_table:is_play( ... )
	log.info("pdk_table:is_play : [%s]",self.status)
	return  self.status and self.status ~= TABLE_STATUS.FREE and self.status ~= TABLE_STATUS.END
end

function pdk_table:quan_da(cards)
	return table.And(cards,function(c)
		return c == self.laizi or cards_util.value(c) > 10
	end)
end

function pdk_table:quan_xiao(cards)
	return table.And(cards,function(c)
		return c == self.laizi or cards_util.value(c) <= 10
	end)
end

local black <const> = {
	[0] = true,
	[2] = true,
}

local red <const> = {
	[1] = true,
	[3] = true,
}

function pdk_table:quan_hei(cards)
	return table.And(cards,function(c)
		return c == self.laizi or black[cards_util.color(c)]
	end)
end

function pdk_table:quan_hong(cards)
	return table.And(cards,function(c)
		return c == self.laizi or red[cards_util.color(c)]
	end)
end

function pdk_table:quan_dan(cards)
	return table.And(cards,function(c)
		return c == self.laizi or cards_util.value(c) % 2 == 1
	end)
end

function pdk_table:quan_suang(cards)
	return table.And(cards,function(c)
		return c == self.laizi or cards_util.value(c) % 2 == 0
	end)
end

function pdk_table:game_balance(winner)
	local play = self.rule and self.rule.play or {}
	
	local function calc_score(p)
		local count = table.sum(p.hand_cards)
		local score = count
		local chun_tian = not p.discard_times or p.discard_times == 0
		local fan_chun = (play.fan_chun ~= false) and p.discard_times == 1 and self.zhuang == p.chair_id
		if chun_tian then
			score = CHUN_TIAN_TIMES * score
		elseif fan_chun then
			score = FAN_CHUN_TIMES * score
		end

		return score
	end

	local winner_chair = winner.chair_id
	local winner_zha_niao = winner.zha_niao
	local winner_special = winner.quan_da or winner.quan_xiao or winner.quan_dan or 
			winner.quan_suang or winner.quan_hei or winner.quan_hong
	local card_scores = table.map(self.players,function(p,chair)
		if p == winner then return end
		local score = calc_score(p)
		if winner_zha_niao or p.zha_niao then  score = score * 2 end
		if winner_special then score = score + (play.special_score or 0) end
		return chair,-score
	end)

	card_scores[winner_chair] = -table.sum(card_scores)

	log.dump(card_scores)

	local triple_bomb_score = play.bomb_score and play.bomb_score[1] or TRIPLE_BOMB_SCORE
	local bomb_score = play.bomb_score and play.bomb_score[2] or BOMB_SCORE
	local bomb_lose_matrix = table.map(self.players,function(p,chair)
		local score = (p.bomb or 0) * bomb_score + (p.triple_bomb or 0) * triple_bomb_score
		return chair,table.map(self.players,function(_,c) return c,c ~= chair and -score or nil end)
	end)
	local bomb_winners = table.map(bomb_lose_matrix,function(losers,chair) return chair,math.abs(table.sum(losers)) end)
	local bomb_losers = table.merge_tables(bomb_lose_matrix,function(l,r) return (l or 0) + (r or 0) end) 
	local bomb_scores = table.merge(bomb_winners,bomb_losers,function(l,r) return (l or 0) + (r  or 0) end)

	log.dump(bomb_scores)
	
	local scores = table.map(self.players,function(_,chair)  
		return chair,(card_scores[chair] or 0) + (bomb_scores[chair] or 0) 
	end)

	self:foreach(function(p,chair)
		local score = scores[chair]
		if score >= 0 and (p.statistics.max_score or 0) < score then
			p.statistics.max_score = score
		end
	end)
	
	local moneies = table.map(scores,function(score,chair) return chair,self:calc_score_money(score) end)
	moneies = self:balance(moneies,enum.LOG_MONEY_OPT_TYPE_PDK_SC)
	self:foreach(function(p,chair)
		p.total_score = (p.total_score or 0) + scores[chair]
		p.round_score = scores[chair]
		p.total_money = (p.total_money or 0) + moneies[chair]
		p.round_money = moneies[chair]
	end)

	self:broadcast2client("SC_PdkGameOver",{
		player_balance = table.series(self.players,function(p,chair)
			return {
				chair_id = chair,
				round_score = scores[chair],
				round_money = p.round_money,
				total_score = p.total_score,
				total_money = p.total_money,
				bomb_score = bomb_scores[chair] or 0,
				hand_cards = cards_util.kc2series(p.hand_cards),
			}
		end),
	})

	self:notify_game_money()

	table.foreach(self.players,function(p,chair) 
		local plog = self.game_log.players[chair]
		plog.chair_id = chair
		plog.total_money = p.total_money
		plog.total_score = p.total_score
		plog.round_money = p.round_money
		plog.score = p.round_score
		plog.bomb_score = bomb_scores[chair]
		plog.nickname = p.nickname
		plog.head_url = p.icon
		plog.guid = p.guid
		plog.sex = p.sex
	end)

	self.game_log.cur_round = self:gaming_round()
	self:save_game_log(self.game_log)

	self.last_discard = nil
	self:update_status(TABLE_STATUS.FREE)
	self:clear_ready()
	self:game_over()
end

return pdk_table