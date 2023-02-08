-- 牛牛逻辑
local base_table = require "game.lobby.base_table"
local log = require "log"
local enum = require "pb_enums"
local define = require "game.oxp.define"
local logic = require "game.oxp.gamelogic_1"
local base_rule = require "game.lobby.base_rule"
local card_dealer = require "card_dealer"
local timer = require "timer"

local table = table
local string = string
local math = math
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort

local TABLE_STATUS = define.STATUS
local CARDS_TYPE = define.CARDS_TYPE
local PLAYER_STATUS = define.PLAYER_STATUS

local CALLBANKER_TIMEOUT = 10
local BET_TIMEOUT = 15
local SPLIT_TIMEOUT = 10

local default_times = {
	[CARDS_TYPE.OX_NONE] = 1,
	[CARDS_TYPE.OX_1] = 1,
	[CARDS_TYPE.OX_2] = 1,
	[CARDS_TYPE.OX_3] = 1,
	[CARDS_TYPE.OX_4] = 1,
	[CARDS_TYPE.OX_5] = 1,
	[CARDS_TYPE.OX_6] = 1,
	[CARDS_TYPE.OX_7] = 1,
	[CARDS_TYPE.OX_8] = 1,
	[CARDS_TYPE.OX_9] = 1,
	[CARDS_TYPE.OX_10] = 1,
}

local all_cards = {
	1,2,3,4,5,6,7,8,9,10,11,12,13,
	21,22,23,24,25,26,27,28,29,30,31,32,33,
	41,42,43,44,45,46,47,48,49,50,51,52,53,
	61,62,63,64,65,66,67,68,69,70,71,72,73,
}

local default_bet_chips = {1}

local ox_table = setmetatable({},{__index = base_table})

-- 初始化
function ox_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)

	self.status = TABLE_STATUS.NIL
end


function ox_table:get_min_gamer_count()
	local min_gamer_count = 2
	if self.rule and self.rule.room.min_gamer_count then
		local private_room_conf = self:room_private_conf()
		min_gamer_count = private_room_conf.min_gamer_count_option[self.rule.room.min_gamer_count + 1]
	end

	return min_gamer_count
end

function ox_table:begin_start_ticker()
	local trustee,seconds = self:get_trustee_conf()
	if trustee then
		log.info("ox_table:begin_start_ticker table_id:%s",self:id())
		self:begin_kickout_no_ready_timer(seconds+1,function()
			log.info("ox_table:begin_start_ticker timeout,start,table_id:%s,is_play:%s",self:id(),self:is_play())
			self:cancel_kickout_no_ready_timer()
			if not self:is_play() then
				self:start()
			else
				log.warning("ox_table:begin_start_ticker timeout table_id:%s is gaming.",self:id())
			end
		end)
	end
end

function ox_table:stop_start_ticker()
	log.info("ox_table:stop_start_ticker table_id:%s",self:id())
	self:cancel_kickout_no_ready_timer()
end

function ox_table:check_start(part)
	log.info("ox_table:check_start %s",self.table_id_)
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

	log.info("ox_table:check_start table_id:%s,[%s,%s,%s],ext_status:%s",
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

	local is_all_gamer_ready = table.And(self.gamers,function(p,c) 
		return  p.status == PLAYER_STATUS.BANKRUPTCY  or ( self.ready_list[c] and true or false )
	end)
	local gamer_count =  table.sum(self.gamers,function (p)
		return p.status == PLAYER_STATUS.BANKRUPTCY and 0 or 1
	end)
	if is_all_gamer_ready and ready_count >= gamer_count and gamer_count >= min_gamer_count then
		self:start(player_count)
	end
end

function  ox_table:is_play(player)
	if player then
		return player.status and (player.status == PLAYER_STATUS.PLAY or player.status  == PLAYER_STATUS.BANKRUPTCY)
	end

	return self.status and self.status ~= TABLE_STATUS.NIL and self.status ~= TABLE_STATUS.FREE
end

function ox_table:can_stand_up(player,reason)
	return self:lockcall(function()
		log.info("ox_table:can_stand_up guid:%s,reason:%s",player.guid,reason)
		if reason == enum.STANDUP_REASON_NORMAL or
			reason == enum.STANDUP_REASON_OFFLINE or 
			reason == enum.STANDUP_REASON_FORCE or
			reason == enum.STANDUP_REASON_DELAY_KICKOUT_TIMEOUT then
			return not self:is_play(player)
		end

		return true
	end)
end

function ox_table:on_started(player_count)
	base_table.on_started(self,player_count)
	self.status = TABLE_STATUS.FREE
	self.gamers = {}

	self.gamers = table.map(self.players,function(p,chair)
		return chair,self.ready_list[chair] and p or nil
	end)

	table.foreach(self.gamers,function(p) 
		p.callbanker = nil
		p.bet_score = nil
		p.cards_pair = nil
		p.cards = nil
		p.cards_type = nil
		p.status = PLAYER_STATUS.PLAY
	end)

	local play = self.rule and self.rule.play or {}
	self.rule_times = table.map(play.ox_times or {},function(v,k) 
		return tonumber(k),tonumber(v)
	end)

	self.bet_chips = play.base_score or default_bet_chips
	tsort(self.bet_chips,function(l,r) return l < r end)

	self.gamelog = {
		banker = nil,		 --庄家ID
		balance = {}, --游戏结算
		callbanker = {},
		bet = {},
		rule = self.rule and self.rule or nil,
		cur_round = self:gaming_round(),
		players = table.map(self.players,function(v,i) 
			return i,{
				chair_id = i,
				guid = v.guid,
				head_url = v.icon,
				nickname = v.nickname,
				sex = v.sex,
			}
		end)
    }

	
	self:broadcast2client("SC_OxStart",{
		players = table.map(self.gamers,function(p,chair) 
			return chair,{
				chair_id = chair,
				guid = p.guid,
				call_banker_times = 0,
				score = 0,
				total_money = p.total_money,
				total_score = p.total_score,
				status = p.status,
			}
		end),
		cur_round = self:gaming_round(),
		total_round = self.conf.round,
	})

	self:deal_cards()
end

function ox_table:begin_timer(timeout,fn)
	if self.auto_timer then 
        log.warning("ox_table:begin_timer timer not nil")
        self.auto_timer:kill()
    end

    self.auto_timer = self:new_timer(timeout,fn)
	self:begin_clock(timeout)

    log.info("ox_table:begin_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.auto_timer.id,timeout)
end

function ox_table:cancel_timer()
	if not self.auto_timer then return end
	self.auto_timer:kill()
	self.auto_timer = nil
end

function ox_table:next_banker(banker)
	local nc = self.chair_count
	log.dump( self.chair_count)
	log.dump(self.gamers)
	if not banker then
		while true do
			local bc = math.random(1,nc)
			if self.gamers[bc] then
				return bc
			end
		end
		return
	end

	local i = banker or self.banker
	log.dump(i + 1)
	log.dump(i + nc + 1)
	for c = i + 1,i + nc + 1  do
		local bc = c
		if bc > nc then
			bc = bc % nc
		end
		if self.gamers[bc] then
			log.dump(bc)
			return bc
		end
	end
	
end

function ox_table:get_an_cards(cards)
	local play = self.rule and self.rule.play or {}
	local an_opt = play.an_pai_option or 0

	local cc = #cards
	if an_opt == 0 then
		return table.series(cards,function() return 0 end)
	end

	if an_opt <= cc then
		return table.series(cards,function(v,i) return i > (cc - an_opt) and 0 or v end)
	end

	return table.series(cards,function() return 0 end)
end

-- 发牌
function ox_table:deal_cards()
	local dealer = card_dealer.new(all_cards)
	dealer:shuffle()

	table.foreach(self.players,function(p)
		local cards = dealer:deal_cards(5)
		p.cards = cards
		p.cards_type = logic.cards_type(cards,self.rule_times)
		send2client(p,"SC_OxDealCard", {
			cards = self:get_an_cards(cards)
		})
	end)

	self:allow_call_banker()
end

function ox_table:allow_call_banker()
	local play = self.rule and self.rule.play or {}
	if play.no_banker_compare then
		self:allow_bet()
		return
	end

	if play.banker_take_turn then
		self.banker = self:next_banker(self.banker)
		local banker = self.gamers[self.banker]
		banker.callbanker = 1
		self:broadcast2client("SC_OxBankerInfo",{
			banker_info = {
				chair_id = self.banker,
				bankertimes = 1,
				base = {
					guid = banker.guid,
					nickname = banker.nickname,
					icon = banker.icon,
					sex = banker.sex,
				}
			}
		})
		self:allow_bet()
		return
	end

	self.status = TABLE_STATUS.CALLBANKER
	self:broadcast2client("SC_AllowCallBanker",{})

	local trustee_type,seconds = self:get_trustee_conf()
	if trustee_type then
		self:begin_timer(seconds or CALLBANKER_TIMEOUT,function()
			self:cancel_timer()
			table.foreach(self.gamers,function(p)
				if not p.callbanker then
					self:call_banker(p,{times = 0})
				end
			end)
		end)
	end
end

function ox_table:call_banker(player,msg)
	self:lockcall(function()
		if not self.gamers[player.chair_id] then
			log.error("ox_table:call_banker guid[%s] not gaming",player.guid)
			return
		end

		if self.status ~= TABLE_STATUS.CALLBANKER then
			log.error("ox_table:call_banker guid[%s] table status not call banker",player.guid)
			send2client(player,"SC_OxCallBanker",{
				result = enum.ERROR_OPERATION_INVALID
			})
			return
		end

		if player.callbanker then
			log.error("ox_table:call_banker guid[%s] call banker already",player.guid)
			send2client(player,"SC_OxCallBanker",{
				result = enum.ERROR_OPERATION_REPEATED
			})
			return
		end

		local times = msg.times or 0

		player.callbanker = times

		self.gamelog.callbanker[player.chair_id] = times

		self:broadcast2client("SC_OxCallBanker",{
			result = enum.ERROR_NONE,
			chair_id = player.chair_id,
			times = times,
		})
		
		local done = table.And(self.gamers,function(p) return p.callbanker end)
		if done then
			self:cancel_timer()
			local bankertimes = table.series(self.gamers,function(p)
				return { chair_id = p.chair_id,times = p.callbanker}
			end)
			tsort(bankertimes,function(l,r) return l.times > r.times end)
			local maxtimes = bankertimes[1].times
			local maxcallers = {bankertimes[1]}
			for i = 2,#bankertimes do
				local calltimes = bankertimes[i]
				if maxtimes == calltimes.times then
					tinsert(maxcallers,calltimes)
				end
			end
			local bankerctx = maxcallers[math.random(1,#maxcallers)]
			self.banker = bankerctx.chair_id
			self.gamelog.banker = self.banker
			local p = self.players[self.banker]
			self:broadcast2client("SC_OxBankerInfo",{
				banker_info = {
					chair_id = self.banker,
					bankertimes = bankerctx.times,
					base = {
						guid = p.guid,
						nickname = p.nickname,
						icon = p.icon,
						sex = p.sex,
					}
				}
			})

			self:allow_bet()
		end
	end)
end

function ox_table:requestbanker(player)
	self:lockcall(function() end)
end

function ox_table:unrequest_banker(player)
	self:lockcall(function() end)
end

function ox_table:leave_banker(player)
	self:lockcall(function() end)
end

function ox_table:allow_bet()
	self.status = TABLE_STATUS.BET

	self:broadcast2client("SC_AllowAddScore",{})

	local trustee_type,seconds = self:get_trustee_conf()
	if trustee_type then
		local done = nil
		self:begin_timer(seconds,function()
			-- double check
			if done then return end

			done = true

			self:cancel_timer()
			table.foreach(self.gamers,function(p)
				if p.chair_id ~= self.banker and (not p.bet_score or p.bet_score < 1) then
					self:bet(p,{score = self.bet_chips[1] or 1})
				end
			end)

			self:allow_split_cards()
		end)
	end
end

function ox_table:bet(player, msg)
	self:lockcall(function()
		local chair_id = player.chair_id
		if not self.gamers[chair_id] then
			log.error("ox_table:bet guid[%s] not gaming", player.guid)
			return
		end

		local score = msg.score
		if self.status ~= TABLE_STATUS.BET then
			log.error("ox_table:bet guid[%s] status error", player.guid)
			send2client(player,"SC_OxAddScore",{
				result = enum.ERROR_OPERATION_INVALID,
			})
			return
		end

		if self.banker then
			local pbanker = self.players[self.banker]
			-- 庄家不能下注
			if player.chair_id == pbanker.chair_id then
				log.error("ox_table:bet, banker[%s] = guid[%s]",self.banker,player.chair_id)
				send2client(player,"SC_OxAddScore",{
					result = enum.ERROR_OPERATION_INVALID,
				})
				return
			end
		end

		if not table.Or(self.bet_chips,function(chip) return chip == score end) then
			log.error("ox_table:bet guid[%s] score[%s] <= 0", player.guid, score)
			send2client(player,"SC_OxAddScore",{
				result = enum.ERROR_OPERATION_INVALID,
			})
			return
		end

		if player.bet_score then
			log.error("ox_table:bet guid[%s] repeat", player.guid, score)
			send2client(player,"SC_OxAddScore",{
				result = enum.ERROR_OPERATION_REPEATED,
			})
			return
		end

		if self.club and self.club.type == enum.CT_UNION then
			local money_id = self:get_money_id()
			local money = player:get_money(money_id)
			if money < score then
				log.error("ox_table:bet less money %s,%s",player.guid,money,score)
				send2client(player,"SC_OxAddScore",{
					result = enum.ERROR_LESS_GOLD,
				})
				return
			end
		end

		player.bet_score = score

		self.gamelog.bet[player.chair_id] = score

		self:broadcast2client("SC_OxAddScore",{
			result = enum.ERROR_NONE,
			chair_id = player.chair_id,
			score = score,
			money = score,
		})

		if 
			table.And(self.gamers,function(p,c) return p.bet_score or c == self.banker end)
		then
			self:cancel_timer()
			self:allow_split_cards()
		end
	end)
end

function ox_table:check_cards_pair(player,cards_pair)
	local cm = table.map(player.cards,function(c) return c,true end)
	return table.And(cards_pair,function(cs)
		return table.And(cs,function(c) return cm[c] end)
	end)
end

function ox_table:split_cards(player,msg)
	self:lockcall(function()
		local chair_id = player.chair_id
		if not self.gamers[chair_id] then
			log.error("ox_table:split_cards guid[%s] not gaming", player.guid)
			return
		end

		if self.status ~= TABLE_STATUS.SPLIT then
			log.error("ox_table:split_cards guid[%s] status error", player.guid)
			send2client(player,"SC_OxSplitCards",{
				result = enum.ERROR_OPERATION_INVALID,
			})
			return
		end

		if player.cards_pair then
			log.error("ox_table:split_cards guid[%s] split already", player.guid)
			send2client(player,"SC_OxSplitCards",{
				result = enum.ERROR_OPERATION_REPEATED,
			})
			return
		end

		local cards_pair = msg.cards_pair
		local cards_count = table.sum(cards_pair,function(p)
			return p and p.cards and table.nums(p.cards) or 0
		end)

		local pair
		if #cards_pair < 1 or #cards_pair > 2 or cards_count ~= 5 then
			pair = player.cards_type.pair
		else
			pair = table.series(cards_pair or {},function(p) return p.cards end)
			if not self:check_cards_pair(player,pair) then
				log.error("ox_table:split_cards guid[%s] invalid cards!", player.guid)
				log.dump(pair,"cards pair")
				send2client(player,"SC_OxSplitCards",{
					result = enum.ERROR_OPERATION_REPEATED,
				})
				return
			end

			player.cards_type = logic.pair_type(pair,self.rule_times)
		end
		
		player.cards_pair = pair

		self:broadcast2client("SC_OxSplitCards",{
			result = enum.ERROR_NONE,
			chair_id = player.chair_id,
			cards_pair = table.series(pair,function(p) 
				return {cards = p}
			end),
			type = player.cards_type.type,
		})

		local done = table.And(self.gamers,function(p) return p.cards_pair end)
		if done then
			self:cancel_timer()
			self:do_balance()
		end
	end)
end

function ox_table:allow_split_cards()
	self.status = TABLE_STATUS.SPLIT
	table.foreach(self.players,function(p) 
		send2client(p,"SC_AllowSplitCards",{
			cards = p.cards,
		})
	end)

	local trustee_type,seconds = self:get_trustee_conf()
	if trustee_type then
		self:begin_timer(seconds,function()
			self:cancel_timer()
			table.foreach(self.gamers,function(p)
				if not p.cards_pair then
					self:split_cards(p,{
						cards_pair = {}
					})
				end
			end)
		end)
	end
end

function ox_table:do_balance()
	local play = self.rule and self.rule.play or {}
	local ox_times = self.rule_times
	local scores
	if play.no_banker_compare then
		local all_p  = table.series(self.gamers)
		tsort(all_p,function(l,r) return logic.compare(l.cards_type,r.cards_type) end)
		local winner = all_p[1]

		scores = table.map(self.gamers,function(p,chair)
			if p == winner then return end
			local winner_type = winner.cards_type and winner.cards_type.type or CARDS_TYPE.OX_NONE
			local times = ox_times[winner_type] or default_times[winner_type] or 1
			local score = (p.bet_score or 0) * times
			return chair,-score
		end)

		scores[winner.chair_id] = - table.sum(scores)
	else
		local banker = self.gamers[self.banker]
		scores = table.map(self.gamers,function(p,chair)
			if chair == self.banker then return end
			local win = logic.compare(banker.cards_type,p.cards_type)
			local winner = win and banker or p
			local winner_type = winner.cards_type and winner.cards_type.type or CARDS_TYPE.OX_NONE
			local times = ox_times[winner_type] or default_times[winner_type] or 1
			local score = (p.bet_score or 0) * (banker.callbanker > 0 and banker.callbanker or 1) * times
			return chair,p == winner and score or -score
		end)

		scores[self.banker] = -table.sum(scores)
	end

	log.dump(scores)

	local scoremonies = table.map(scores,function(s,chair) 
		return chair,self:calc_score_money(s)
	end)

	log.dump(enum.LOG_MONEY_OPT_TYPE_OX_DIANZI)
	local moneies = self:balance(scoremonies,enum.LOG_MONEY_OPT_TYPE_OX_DIANZI)
	local log_player = self.gamelog.players 
	table.foreach(self.gamers,function(p,chair)
		p.winlose_count = (p.winlose_count or 0) +  ((scores[chair] or 0) > 0 and 1 or -1)
		p.total_score = (p.total_score or 0) + (scores[chair] or 0)
		p.total_money = (p.total_money or 0) + (moneies[chair] or 0)
		if self:is_bankruptcy(p) then
			p.status = PLAYER_STATUS.BANKRUPTCY
		end
		log_player[chair].total_money = p.total_money or 0
		log_player[chair].win_money = moneies[chair] or 0
	end)



	self.gamelog.balance = table.series(self.gamers,function(v,i) 
		return {
			chair_id = i,
			score = scores[i] or 0,
			money = moneies[i] or 0,
			total_money = v.total_money,
			total_score = v.total_score,
			cards = v.cards,
			cards_pair = v.cards_pair,
			cards_type = v.cards_type.type,
		}
	end)
	
	self:broadcast2client("SC_OxBalance",{
		balances = table.series(self.gamers,function(p,chair)
			return {
				chair_id = chair,
				guid = p.guid,
				score = scores[chair] or 0,
				cards_pair = table.series(p.cards_type.pair or {},function(cp) return {cards = cp} end),
				type = p.cards_type.type,
				bet_money = p.bet_score,
				money = moneies[chair] or 0,
				total_score = p.total_score,
				total_money = p.total_money,
				pstatus = p.status,
			}
		end)
	})

	self:notify_game_money()

	self.status = TABLE_STATUS.END

	if not play.banker_take_turn then
		self.banker = nil
	end

	self:save_game_log(self.gamelog)

	self:calllater(table.nums(self.gamers) * 1,function()
		self:game_over()
	end)
end
function base_table:check_bankruptcy_fordismiss()
	return  table.sum(self.gamers,function (p)
		return p.status == PLAYER_STATUS.BANKRUPTCY and 0 or 1
	end) < self:get_min_gamer_count()
end 
function ox_table:on_game_overed()
	self.gamelog = nil
	log.info("ox_table:on_game_overed table_id = %s", self.table_id_)
	self:cancel_timer()
	self:cancel_kickout_no_ready_timer()

	self:clear_ready()
	
	table.foreach(self.gamers,function(p) 
		p.callbanker = nil
		p.bet_score = nil
		p.cards_pair = nil
		p.cards = nil
		p.cards_type = nil
	end)
	
	self.status = TABLE_STATUS.FREE

	base_table.on_game_overed(self)
end

function ox_table:on_process_start()
	self:cancel_timer()
	self.status = PLAYER_STATUS.FREE
	base_table.on_process_start(self)
end

function ox_table:on_process_over(reason)
	log.info("ox_table:on_process_over table_id:%s,reason:%s",self:id(),reason)
	self:cancel_timer()
	
	self.banker = nil
	self.status = nil

	self:broadcast2client("SC_OxFinalOver",{
		balances = table.series(self.players,function(p)
			return {
				chair_id = p.chair_id,
				guid = p.guid,
				total_score = p.total_score,
				total_money = p.total_money,
			}
		end)
	})

	self:cost_tax(table.map(self.players,function(p)
		return p.guid,p.total_money or 0
	end))
	
	base_table.on_process_over(self,reason,{
		balance = table.map(self.players,function(p)
			return p.guid,p.total_money
		end)
	})
	
	self:foreach(function(p) 
		if not p.status or p.status == PLAYER_STATUS.WATCHER then
			p:async_force_exit(enum.STANDUP_REASON_NORMAL)
		end
		p.total_money = nil
		p.total_score = nil
		p.winlose_count = nil
		p.round_score = nil
		p.round_money = nil
		p.callbanker = nil
		p.bet_score = nil
		p.cards_pair = nil
		p.cards = nil
		p.cards_type = nil
		p.status = nil
	end)
end


function ox_table:owner_check_start(player)
	log.info("ox_table:owner_check_start %s,owner:%s,player:%s",
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
	
	if self:is_play() then
		return enum.ERROR_NONE
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


function ox_table:owner_start_game(player)
	local result = self:lockcall(function()
		return self:owner_check_start(player)
	end)

	log.info("ox_table:owner_start_game %s,owner:%s,result:%s",self.table_id_,player.guid,result)
	if result ~= enum.ERROR_NONE then
		send2client_pb(player,"SC_OxStartGame",{
			result = result
		})
	end
end

function ox_table:on_reconnect_when_split_cards(player)
	if not player.cards_pair and self.auto_timer then
		send2client(player,"SC_AllowSplitCards",{})
	end
end

function ox_table:on_reconnect_when_bet(player)
	if not player.bet_score and self.auto_timer then
		send2client(player,"SC_AllowAddScore",{})
	end
end

function ox_table:on_reconnect_when_callbanker(player)
	if not player.callbanker and self.auto_timer then
		send2client(player,"SC_AllowCallBanker",{})
	end
end

function ox_table:reconnect(player)
	log.info("ox_table:reconnect %s %s",self:id(),player.guid)
	local chair_id = player.chair_id
	local msg = {
		banker = self.banker,
		status = self.status or TABLE_STATUS.FREE,
		round = self:gaming_round(),
		players = table.map(self.gamers,function(p,chair)
			return chair,{
				chair_id = chair,
				guid = p.guid,
				call_banker_times = p.callbanker or -1,
				status = p.status or PLAYER_STATUS.WATCHER,
				total_score = p.total_score,
				total_money = p.total_money,
				score = p.bet_score,
				cards_pair = table.series(p.cards_pair or {},function(p) return {cards = p} end),
			}
		end),
		pstatus_list = table.map(self.players,function(p,chair)
			return chair,p.status or  PLAYER_STATUS.WATCHER
		end)
	}
	if not msg.players[chair_id] or (player.status and player.status == PLAYER_STATUS.BANKRUPTCY ) then 
		send2client(player,"SC_OxTableInfo",msg) 
		return 
	end 
	if self.status == TABLE_STATUS.CALLBANKER then
		local p = msg.players[chair_id]
		p.cards = self:get_an_cards(player.cards)
 		send2client(player,"SC_OxTableInfo",msg)
		self:on_reconnect_when_callbanker(player)
	elseif self.status == TABLE_STATUS.BET then
		local p = msg.players[chair_id]
		p.cards = self:get_an_cards(player.cards)
		send2client(player,"SC_OxTableInfo",msg)
		self:on_reconnect_when_bet(player)
	elseif self.status == TABLE_STATUS.SPLIT then
		local p = msg.players[chair_id]
		p.cards = player.cards
		send2client(player,"SC_OxTableInfo",msg)
		self:on_reconnect_when_split_cards(player)
	else
		send2client(player,"SC_OxTableInfo",msg)
	end

	if self.auto_timer then
		self:begin_clock(self.auto_timer.remainder,player)
	end
end

function ox_table:check_kickout_no_ready()
	return
end
-- 检查是否可准备
function base_table:check_ready(player)
	if player and player.status and   player.status == PLAYER_STATUS.BANKRUPTCY then   
		return false 
	end 
	return true 
end
function ox_table:auto_ready(seconds)
	self:begin_kickout_no_ready_timer(seconds,function()
		self:cancel_kickout_no_ready_timer()
		table.foreach(self.gamers,function(p)
			if (not p.status or p.status~= PLAYER_STATUS.BANKRUPTCY )and not self.ready_list[p.chair_id] then
				self:ready(p)
			end
		end)
	end)
end

function ox_table:can_sit_down(player,chair_id,reconnect)
	if reconnect then 
		if self.players[chair_id] then
			log.info("reconnect player is exist guid:   %d chairid:   %d",player.guid,chair_id)
			return enum.ERROR_NONE 
		else
			log.info("-------牛牛出现重入玩家-------reconnect player is not exist chairid:   %d      tableid:    %d",chair_id,self.table_id_)
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

function ox_table:on_player_sit_downed(player,reconnect)
	log.info("ox_table:on_player_sit_downed %s",reconnect)
	if not self:is_play(player) then
		local msg = {
			banker = self.banker,
			status = self.status or TABLE_STATUS.FREE,
			round = self:gaming_round(),
			players = table.map(self.gamers,function(p,chair)
				return chair,{
					chair_id = chair,
					guid = p.guid,
					call_banker_times = p.callbanker or -1,
					status = p.status or PLAYER_STATUS.WATCHER,
					total_score = p.total_score,
					total_money = p.total_money,
					score = p.bet_score,
					cards_pair = table.series(p.cards_pair or {},function(p) return {cards = p} end),
				}
			end),
			pstatus_list = table.map(self.players,function(p,chair)
				return chair,p.status or  PLAYER_STATUS.WATCHER
			end)
		}

		send2client(player,"SC_OxTableInfo",msg)
		if self.status == TABLE_STATUS.CALLBANKER then
			self:on_reconnect_when_callbanker(player)
		elseif self.status == TABLE_STATUS.BET then
			self:on_reconnect_when_bet(player)
		elseif self.status == TABLE_STATUS.SPLIT then
			self:on_reconnect_when_split_cards(player)
		end

		if self.auto_timer then
			self:begin_clock(self.auto_timer.remainder,player)
		end
	end
	self:sync_kickout_no_ready_timer(player)
end


return ox_table