-- 斗地主逻辑
local pb = require "pb"

local base_table = require "game.lobby.base_table"
require "data.land_data"
local log = require "log"
require "game.lobby.game_android"
local timer_manager = require "game.timer_manager"
local card_dealer = require "card_dealer"
local enum = require "pb_enums"
local cards_util = require "game.land.cards_util"
local club_utils = require "game.club.club_utils"
require "functions"
local base_private_table = require "game.lobby.base_private_table"

local offlinePunishment_flag = false

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
-- ip限制等待时间
local PDK_TIME_IP_CONTROL = 20
-- ip限制开启人数
local LAND_IP_CONTROL_NUM = 20

local CARD_TYPE = cards_util.LAND_CARD_TYPE

local ACTION = {
	NONE = pb.enum("PDK_ACTION", "ACTION_NONE"),
	DISCARD = pb.enum("PDK_ACTION", "ACTION_DISCARD"),
	PASS = pb.enum("PDK_ACTION", "ACTION_PASS"),
}

local TABLE_STATUS = {
	NONE = 0,
	-- 等待开始
	FREE = 1,
	-- 开始倒记时
	START_COUNT_DOWN = 2,
	--叫地主
	COMPETE_LANDLORD = 3,
	-- 游戏进行
	PLAY = 4,
	-- 结束阶段
	END = 5,
}

local all_cards = {
	[3] = {
		3,4,5,6,7,8,9,10,11,12,13,14,15,
		23,24,25,26,27,28,29,30,31,32,33,34,35,
		43,44,45,46,47,48,49,50,51,52,53,54,55,
		63,64,65,66,67,68,69,70,71,72,73,74,75,
		96,97
	}
}

local land_table = base_table:new()

-- 初始化
function land_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.status = TABLE_STATUS.FREE
	self.cur_competer = nil
end

function land_table:on_private_inited()
    self.cur_round = nil
    self.landlord = nil
end

function land_table:on_private_dismissed()
    log.info("land_table:on_private_dismissed")
    self.cur_round = nil
    self.landlord = nil
    self.status = nil
    for _,p in pairs(self.players) do
        p.total_money = nil
    end
end

function land_table:on_private_pre_dismiss()
    if self.private_id and self.cur_round and self.cur_round > 0 then
        self:on_final_game_overed()
    end
end

function land_table:can_dismiss()
	return true
end

function land_table:check_dismiss_commit(agrees)
	if table.logic_or(agrees,function(agree) return not agree end) then
		return
	end

	local agree_count = table.sum(self.players,function(p) return agrees[p.chair_id] and 1 or 0 end)
	local agree_count_at_least = self.rule.room.dismiss_all_agree and table.nums(self.players) or math.ceil(table.nums(self.players) / 2)
	return agree_count >= agree_count_at_least 
end

function land_table:on_process_start()
	self.cur_competer = nil
	self:foreach(function(p) 
		p.statistics = {}
		p.total_score = 0
		p.total_money = 0
	end)
end

function land_table:on_started(player_count)
	log.info("land_table:on_started %s.",player_count)

	self.start_count = player_count
	base_table.on_started(self,player_count)
	self:do_game_start()
end

function land_table:do_game_start()
	self:update_status(TABLE_STATUS.COMPETE_LANDLORD)

	self:foreach(function(p) 
		p.win = nil
		p.round_score = nil
		p.round_money = nil
		p.discard_count = nil
		p.bomb = nil
	end)

	self.game_log = {
		start_game_time = os.time(),
		players = table.map(self.players,function(p,chair)
			return chair,{
				guid = p.guid,
			}
		end),
		actions = {},
		rule = self.private_id and self.rule or nil,
		club = (self.private_id and self.conf.club) and club_utils.root(self.conf.club).id,
		table_id = self.private_id or nil,
		landlord_compete = {},
		landlord_cards = nil,
		base_score = nil,
	}

	self.bomb = 0
	self.last_discard = nil
	self.base_score = 1
	self.landlord = nil
	self.last_landlord_cometition = nil
	self.landlord_cards  = nil
	self.landlord_competitions = nil
	self.begin_competition_normal = nil
	self.compete_landlord_2_round = nil
	self.multi = 0

	log.dump(self.rule.play)
	
	-- 获取 牌局id
	log.info("gamestart =================================================")
	self:foreach(function(p) 
		log.info("Player InOut Log,land_table:startGame player %s, table_id %s ,private_table_id:%s",p.guid,p.table_id,self.private_id)
	end)

	self:deal_cards()
end

function land_table:deal_cards()
	local dealer = card_dealer.new(clone(all_cards[self.start_count]))
	dealer:shuffle()
	local pei_cards = {
		-- {3,23,43,63,4,24,44,64,5,25,45,65,14,34,54,15},
		-- {6,26,46,66,7,27,47,67,8,28,48,68,9,29,49,69},
		-- {10,30,50,70,11,31,51,71,12,32,52,72,13,33,53,73},
	}
	dealer:layout_cards(table.union_tables(pei_cards))
	self:foreach(function(p,chair)
		local cards = dealer:deal_cards(17)
		self.game_log.players[chair].deal_cards = cards
		p.hand_cards = table.map(cards,function(c) return c,1 end)
	end)


	self:foreach(function(p)
		self:send_desk_enter_data(p)
	end)

	self.landlord_cards = dealer:deal_cards(3)

	self:begin_compete_landlord()
end

function land_table:begin_compete_landlord()
	local play = self.rule.play
	if self.cur_round == 1 then
		if play.random_call then
			self.cur_competer = math.random(self.chair_count)
		else
			self.cur_competer = self.conf.owner_chair_id
		end
	end

	self.landlord_swap = nil
	self:allow_compete_landlord()
end

function land_table:allow_compete_landlord()
	self:broadcast2client("SC_DdzCallLandlordRound",{
		chair_id = self.cur_competer
	})
end

function land_table:next_landlord_competer()
	local competer = self.cur_competer
	repeat
		competer = competer  % self.start_count + 1
		local p = self.players[competer]
		if p then
			if not self.begin_competition_normal or self.landlord_competitions[p.chair_id] ~= -4 then
				break
			end
		end
	until false

	self.cur_competer = competer
end

function  land_table:do_compete_landlord_score(player,msg)
	local action = msg.action
	if self.last_landlord_cometition then
		if (self.last_landlord_cometition < 0 and self.last_landlord_cometition ~= -4) or 
			(action < 0 and action ~= -4) then
			send2client_pb(player,"SC_DdzCallLandlord",{
				result = enum.ERROR_PARAMETER_ERROR
			})
			return
		end

		if self.last_landlord_cometition >= action and action ~= -4 then
			send2client_pb(player,"SC_DdzCallLandlord",{
				result = enum.ERROR_PARAMETER_ERROR
			})
			return
		end

		local play = self.rule.play
		if play.san_da_must_call then
			local da_sum = table.sum(player.hand_cards,function(_,c)
				return  (c == 96 or c == 97 or c %  20 == 15) and 1 or 0
			end)

			if da_sum >= 3 and action ~= 3 then
				send2client_pb(player,"SC_DdzCallLandlord",{
					result = enum.ERROR_PARAMETER_ERROR
				})
				return
			end
		end
	end

	table.insert(self.game_log.landlord_compete,{
		chair_id = player.chair_id,
		action = action,
	})

	self.landlord_competitions = self.landlord_competitions or {}
	self.landlord_competitions[player.chair_id] = action
	self.last_landlord_cometition = action
	if action > 0 then
		self.base_score = action
	end
	if self.base_score == 3 then
		self:broadcast2client("SC_DdzCallLandlord",{
			result = enum.ERROR_NONE,
			chair_id = self.cur_competer,
			aciton = action,
			base_score = self.base_score,
			times = 2 ^ self.multi,
		})

		self.landlord = self.cur_competer
		self:on_compete_landlord_over()
		return
	end

	self:broadcast2client("SC_DdzCallLandlord",{
		result = enum.ERROR_NONE,
		chair_id = self.cur_competer,
		aciton = action,
		base_score = self.base_score,
		times = 2 ^ self.multi,
	})

	if table.logic_and(self.players,function(_,chair) return self.landlord_competitions[chair] ~= nil end) then
		local max_chair,max_action
		for c,a in pairs(self.landlord_competitions) do
			if not max_action or max_action < a then
				max_chair = c
				max_action = a
			end
		end

		if max_action == -4 then
			self:broadcast2client("SC_DdzRestart",{})
			self:do_game_start()
			return
		end

		self.landlord = max_chair
		self:on_compete_landlord_over()
		return
	end

	return true
end

function land_table:do_compete_landlord_normal(player,msg)
	local action = msg.action
	if self.last_landlord_cometition then
		if self.last_landlord_cometition > 0  or action > 0  then
			send2client_pb(player,"SC_DdzCallLandlord",{
				result = enum.ERROR_PARAMETER_ERROR
			})
			return
		end

		if self.last_landlord_cometition == -2 and action ~= -1 and action ~= -3 then
			send2client_pb(player,"SC_DdzCallLandlord",{
				result = enum.ERROR_PARAMETER_ERROR
			})
			return
		end

		local play = self.rule.play
		if play.san_da_must_call then
			local da_sum = table.sum(player.hand_cards,function(_,c)
				return  (c == 96 or c == 97 or c %  20 == 15) and 1 or 0
			end)

			if da_sum >= 3 and action ~= -2 and not self.begin_competition_normal then
				send2client_pb(player,"SC_DdzCallLandlord",{
					result = enum.ERROR_PARAMETER_ERROR
				})
				return
			end
		end
	end

	table.insert(self.game_log.landlord_compete,{
		chair_id = player.chair_id,
		action = action,
	})

	self.landlord_competitions = self.landlord_competitions or {}
	self.landlord_competitions[player.chair_id] = action
	self.last_landlord_cometition = action

	if action == -1 then
		self.multi = (self.multi or 0)  + 1
		self.landlord_swap = player.chair_id
	end

	if action == -2 then
		self.begin_competition_normal = player.chair_id
		self.landlord_swap = player.chair_id
	end

	self:broadcast2client("SC_DdzCallLandlord",{
		result = enum.ERROR_NONE,
		chair_id = self.cur_competer,
		aciton = action,
		base_score = self.base_score,
		times = 2 ^ self.multi,
	})

	if table.logic_and(self.players,function(p) return self.landlord_competitions[p.chair_id] ~= nil end) then
		if table.logic_and(self.players,function(p) return self.landlord_competitions[p.chair_id] == -4 end) then
			self:broadcast2client("SC_DdzRestart",{})
			self:do_game_start()
			return
		end

		local all_call = table.sum(self.players,function(p)
			local compete = self.landlord_competitions[p.chair_id]
			return  (compete == -2 or compete == -1) and 1 or 0
		end)

		if self.begin_competition_normal == player.chair_id or all_call == 1 then
			self.landlord = self.landlord_swap
			self.landlord_swap = nil
			self:on_compete_landlord_over()
			return
		end
	end

	return true
end

function land_table:do_compete_landlord(player,msg)
	local action = msg.action
	if player.chair_id ~= self.cur_competer then
		send2client_pb(player,"SC_DdzCallLandlord",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if not action or action < -4 or action > 3 then
		send2client_pb(player,"SC_DdzCallLandlord",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	local play = self.rule.play
	if play.call_landlord then
		if not self:do_compete_landlord_normal(player,msg) then 
			return
		end
	else
		if not self:do_compete_landlord_score(player,msg) then
			return
		end
	end

	self:next_landlord_competer()
	self:allow_compete_landlord()
end

function land_table:on_compete_landlord_over()
	self:update_status(TABLE_STATUS.PLAY)
	self:broadcast2client("SC_DdzCallLandlordOver",{
		landlord = self.landlord,
		cards = self.landlord_cards,
	})

	local p = self.players[self.landlord]
	local card_counts = table.map(self.landlord_cards,function(c) return c,1 end)
	table.mergeto(p.hand_cards,card_counts,function(l,r) return (l or 0) + (r or 0) end)

	self.game_log.landlord = self.landlord
	self.game_log.landlord_cards = self.landlord_cards

	self.game_log.base_score = self.base_score
	self.game_log.base_times = 2 ^ self.multi
	self.cur_discard_chair = self.landlord
	self:begin_discard()
end

function land_table:get_trustee_conf()
	local trustee = self.rule and self.rule.trustee or nil
	if trustee and trustee.type_opt ~= nil and trustee.second_opt ~= nil then
	    local trstee_conf = self.room_.conf.private_conf.trustee
	    local seconds = trstee_conf.second_opt[trustee.second_opt + 1]
	    local type = trstee_conf.type_opt[trustee.type_opt + 1]
	    return type,seconds
	end
    
	return nil
end

function land_table:set_trusteeship(player,trustee)
	player.trustee = trustee
	base_table.set_trusteeship(player,trustee)
end

function land_table:get_max_times()
	local play = self.rule.play
	if play and play.max_times then
		local times_conf = self.room_.conf.private_conf.times
		return times_conf and times_conf[play.max_times + 1] or 16
	end

	return 16
end

function land_table:begin_discard()
	self:broadcast2client("SC_DdzDiscardRound",{
		chair_id = self.cur_discard_chair
	})

	local function auto_discard(player)
		if not self.last_discard then

		else
			local type,value = cards_util.seek_great_than(player.hand_cards,self.last_discard.type,self.last_discard.value,self.last_discard.count)
		end
	end

	local trustee_type,trustee_seconds = self:get_trustee_conf()
	if trustee_type and (trustee_type == 1 or (trustee_type == 2 and self.cur_round > 1))  then
		-- local player = self:cur_player()
		-- if not player.trustee then
		-- 	timer_manager:calllater(math.random(1,3),function()
		-- 		auto_discard(player)
		-- 	end)
		-- else
		-- 	timer_manager:calllater(trustee_seconds,function()
		-- 		auto_discard(player)
		-- 		self:set_trusteeship(player,true)
		-- 	end)
		-- end

		-- self:begin_clock(trustee_seconds)
	end
end

function land_table:send_desk_enter_data(player,reconnect)
	local times = 2 ^ ((self.multi or 0) + (self.bomb or 0))
	local max_times = self:get_max_times()
	times = max_times > times and times or max_times

	local msg = {
		status = self.status,
		landlord = self.landlord,
		self_chair_id = player.chair_id,
		act_time_limit = nil,
		is_reconnect = reconnect,
		round = self.cur_round  or 1,
		times = times,
		base_score = self.base_score,
	}

	msg.pb_players = table.series(self.players,function(p,chair)
		local d = {
			chair_id = chair,
			total_score = p.total_score,
		}

		if self.status == TABLE_STATUS.COMPETE_LANDLORD or self.status == TABLE_STATUS.PLAY then
			if p == player then  d.hand_cards = table.keys(p.hand_cards)
			else  d.hand_cards = table.fill({},255,1,table.nums(p.hand_cards)) end
		end

		if self.status ~= TABLE_STATUS.FREE then
			d.round_score = p.round_score
		end

		return d
	end)

	if reconnect then
		msg.pb_rec_data =  {
			act_left_time = nil,
			last_discard_chair = self.last_discard and self.last_discard.chair or nil,
			last_discard = self.last_discard and self.last_discard.cards or nil,
			total_scores = table.map(self.players,function(p,chair)
				if p.total_score  and p.total_score ~= 0 then return chair,p.total_score end
				return chair,nil
			end),
			landlord_cards = self.status == TABLE_STATUS.PLAY and  self.landlord_cards or nil,
		}

		local trustee_type = self:get_trustee_conf()
		if trustee_type then
			self:set_trusteeship(player)
		end
	end

	if self.cur_round and self.cur_round > 0 then
		send2client_pb(player,"SC_DdzDeskEnter",msg)
	end
end


function land_table:set_trusteeship(player,trustee)
    if not self.rule.trustee or table.nums(self.rule.trustee) == 0 then
        return 
    end

    if player.trustee and trustee then
        return
    end

    base_table.set_trusteeship(self,player,trustee)
    player.trustee = trustee
end

function land_table:on_game_overed()
    self.game_log = {}

    self:clear_ready()

    self:foreach(function(p)
	p.statistics.bomb = (p.statistics.bomb or 0) + (p.bomb or 0)
        if not self.private_id then
            if p.deposit then
                p:forced_exit()
            elseif p:is_android() then
                self:ready(p)
            end
        end
    end)

    local trustee_type,_ = self:get_trustee_conf()
    self:foreach(function(p)
        if trustee_type and trustee_type == 3 then
            self:set_trusteeship(p)
        end
	end)

	self.landlord = nil
	self.last_discard = nil
	self.base_score = nil
	self.last_landlord_cometition = nil
	self.landlord_cards  = nil
	self.landlord_competitions = nil
	self.begin_competition_normal = nil
	self.compete_landlord_2_round = nil
	
	self:update_status(TABLE_STATUS.FREE)

    base_table.on_game_overed(self)
end

function land_table:on_process_over()
	self.cur_competer = nil
    self:broadcast2client("SC_DdzFinalGameOver",{
	players = table.series(self.players,function(p,chair)
		local statistics = table.series(p.statistics or {},function(c,t) 
			return {type = t == "win" and 1 or (t == "max_score" and 2 or (t == "bomb" and 3 or 0)),count = c}
		end)
		log.dump(statistics,tostring(chair))
		return {
			chair_id = chair,
			guid = p.guid,
			score = p.total_score or 0,
			statistics = statistics,
		}
	end),
    })

    local trustee_type,_ = self:get_trustee_conf()
    self:foreach(function(p)
        p.statistics = nil
        if trustee_type then
            self:set_trusteeship(p)
        end
    end)

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

    self.landlord = nil
    base_table.on_process_over(self)
end

-- 检查是否可取消准备
function land_table:can_stand_up(player, reason)
    log.info("land_table:can_stand_up guid:%s,reason:%s",player.guid,reason)
    if reason == enum.STANDUP_REASON_DISMISS or
        reason == enum.STANDUP_REASON_FORCE then
        return true
	end
	
	if reason == enum.STANDUP_REASON_OFFLINE and self.status ~= nil then
        return false
    end

    return (not self.status or self.status == TABLE_STATUS.FREE) and not self.cur_round
end

function land_table:on_offline(player)
	
end

function land_table:load_lua_cfg()
	
end

function land_table:next_chair()
	local chair = self.cur_discard_chair
	repeat
		chair = chair  % self.start_count + 1
	until self.players[chair] ~= nil

	return chair
end

function land_table:update_status(status)
	self.status = status
end

function land_table:cur_player()
	return self.players[self.cur_discard_chair]
end

function land_table:do_action(player,act)
	if not act or not act.action then
		log.error("land_table:do_action act is nil.")
		return
	end

	log.dump(act)

	local do_actions = {
		[ACTION.DISCARD] = function(act)
			self:do_action_discard(player,act.cards)
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

	log.error("land_table:do_action invalid action:%s",act.action)
end

function land_table:get_cards_type(cards)
	local cardstype, cardsval = cards_util.get_cards_type(cards)

	return cardstype,cardsval
end

-- 出牌
function land_table:do_action_discard(player, cards)
	log.info("land_table:do_action_discard {%s}",table.concat(cards,","))
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("land_table:discard guid[%d] status error", player.guid)
		send2client_pb(player,"SC_DdzDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("land_table:discard guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn)
		send2client_pb(player,"SC_DdzDoAction",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	if not table.logic_and(cards,function(c) return player.hand_cards[c] ~= nil end) then
		log.warning("land_table:discard guid[%d] cards[%s] error, has[%s]", player.guid, table.concat(cards, ','), 
			table.concat(table.keys(player.hand_cards), ','))
		send2client_pb(player,"SC_DdzDoAction",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	local cardstype, cardsval = self:get_cards_type(cards)
	log.info("cardstype[%s] cardsval[%s]" , cardstype , cardsval)
	local play = self.rule.play
	if not cardstype  or 
		(cardstype == CARD_TYPE.FOUR_WITH_DOUBLE and not play.si_dai_er) or 
		(cardstype == CARD_TYPE.THREE and not play.san_zhang) or 
		(cardstype == CARD_TYPE.THREE_WITH_TWO and not play.san_dai_er)then
		log.warning("land_table:discard guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cards, ','))
		send2client_pb(player,"SC_DdzDoAction",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end
	
	local cmp = cards_util.compare_cards({type = cardstype, count = #cards, value = cardsval}, self.last_discard)
	if self.last_discard and (not cmp or cmp <= 0) then
		log.warning("land_table:discard guid[%d] compare_cards error, cards[%s], cur_discards[%d,%d,%d], last_discard[%d,%d,%d]", 
			player.guid, table.concat(cards, ','),cardstype, #cards,
			cardsval,self.last_discard.type,self.last_discard.count,self.last_discard.value)
		send2client_pb(player,"SC_DdzDoAction",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	self.last_discard = {
		cards = cards,
		chair = player.chair_id,
		type = cardstype,
		value = cardsval,
		count = #cards,
	}

	player.discard_count = (player.discard_count or 0) + 1

	if cardstype == CARD_TYPE.BOMB or cardstype == CARD_TYPE.MISSLE then
		self.bomb = (self.bomb or 0) + 1
		player.statistics.bomb = (player.statistics.bomb or 0) + 1
	end

	self:broadcast2client("SC_DdzDoAction", {
		chair_id = player.chair_id,
		action = ACTION.DISCARD,
		cards = cards,
	})

	log.info("land_table:do_action_discard  chair_id [%d] cards{%s}", player.chair_id, table.concat(cards, ','))
	
	table.foreach(cards,function(c) player.hand_cards[c] = nil end)

	table.insert(self.game_log.actions,{
		action = ACTION.DISCARD,
		chair_id = player.chair_id,
		cards_type = cardstype,
		cards = cards,
		time = os.time(),
	})

	if  table.sum(player.hand_cards) == 0 then
		player.win = true
		player.statistics.win = (player.statistics.win or 0) + 1
		if cardstype == CARD_TYPE.BOMB or cardstype == CARD_TYPE.MISSLE then
			player.bomb = (player.bomb or 0) + 1
		end
		self:game_balance(player)
	else
		self.cur_discard_chair = self:next_chair()
		self:begin_discard()
	end
end

-- 放弃出牌
function land_table:do_action_pass(player)
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("land_table:pass_card guid[%d] status error", player.guid)
		send2client_pb(player,"SC_DdzDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("land_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_discard_chair)
		send2client_pb(player,"SC_DdzDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if not self.last_discard then
		log.error("land_table:pass_card guid[%d] first turn", player.guid)
		send2client_pb(player,"SC_DdzDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	-- 记录日志
	table.insert(self.game_log.actions,{
		chair_id = player.chair_id,
		action = ACTION.PASS,
		time = os.time(),
	})

	log.info("cur_chair_id[%d],pass_chair_id[%d]",self.cur_discard_chair,player.chair_id)
	self:broadcast2client("SC_DdzDoAction", {
		chair_id = player.chair_id,
		action = ACTION.PASS
	})

	self.cur_discard_chair =  self:next_chair()
	if self.cur_discard_chair == self.last_discard.chair then
		self.last_discard = nil
	end

	self:begin_discard()
end

--玩家上线处理
function  land_table:reconnect(player)
	-- 新需求 玩家掉线不暂停游戏 只是托管
	log.info("land_table:reconnect guid:%s",player.guid)
	self:send_desk_enter_data(player,true)
	if self.status == TABLE_STATUS.PLAY then
		send2client_pb(player,"SC_DdzDiscardRound",{
			chair_id = self.cur_discard_chair
		})
	end

	if self.status == TABLE_STATUS.COMPETE_LANDLORD then
		if self.landlord_competitions then
			send2client_pb(player,"SC_DdzCallLandlordInfo",{
				result = enum.ERROR_NONE,
				info = self.landlord_competitions,
			})
		end

		send2client_pb(player,"SC_DdzCallLandlordRound",{
			chair_id = self.cur_competer
		})
	end

	base_table.reconnect(self,player)
end

function  land_table:is_play( ... )
	log.info("land_table:is_play : [%s]",self.status)
	return  self.status and self.status ~= TABLE_STATUS.FREE and self.status ~= TABLE_STATUS.END
end

function land_table:game_balance(winner)
	self.cur_competer = winner.chair_id

	local is_chuntian = table.logic_and(self.players,function(p)
		if p.chair_id == self.landlord then return true end
		return not p.discard_count or p.discard_count == 0
	end)

	local is_fanchun = self.landlord ~= winner.chair_id and self.players[self.landlord].discard_count == 1

	local multi = 2 ^ (self.bomb + (self.multi or 0))
	if is_fanchun or is_chuntian then
		multi = multi * 2
	end

	local max_times = self:get_max_times()
	multi = max_times > multi and multi or max_times

	local function  is_win(chair)
		if winner.chair_id == self.landlord then
			return chair == self.landlord
		end

		return chair ~= self.landlord
	end

	local scores = table.map(self.players,function(_,chair)
		local score = multi * self.base_score
		if is_win(chair) then
			score = self.landlord == chair  and 2 * score or score
		else
			score = self.landlord == chair and -2 * score or -score
		end
		return chair,score
	end)

	self:foreach(function(p,chair)
		local score = scores[chair]
		if score >= 0 and (p.statistics.max_score or 0) < score then
			p.statistics.max_score = score
		end
	end)

	local moneies = table.map(scores,function(score,chair) return chair,self:calc_score_money(score) end)
	moneies = self:balance(moneies,enum.LOG_MONEY_OPT_TYPE_LAND)
	self:foreach(function(p,chair)
		p.total_score = (p.total_score or 0) + scores[chair]
		p.round_score = scores[chair]
		p.total_money = (p.total_money or 0) + moneies[chair]
		p.round_money = moneies[chair]
	end)

	self:foreach(function(p,chair)
		local plog = self.game_log.players[chair]
		plog.chair_id = chair
		plog.total_money = p.total_money
		plog.total_score = p.total_score
		plog.round_money = p.round_money
		plog.score = p.round_score
		plog.nickname = p.nickname
		plog.head_url = p.icon
		plog.guid = p.guid
		plog.sex = p.sex
	end)

	self:broadcast2client("SC_DdzGameOver",{
		player_balance = table.series(self.players,function(p,chair)
			return {
				chair_id = chair,
				base_score = self.base_score,
				times = multi,
				round_score = scores[chair],
				round_money = p.round_money,
				total_score = p.total_score,
				total_money = p.total_money,
				hand_cards = table.keys(p.hand_cards),
			}
		end),
		chun_tian = is_fanchun and 2 or (is_chuntian and 1 or 0),
	})

	self:notify_game_money()

	self:foreach(function(p)
		local plog = self.game_log.players[p.chair_id]
		plog.total_money = p.total_money
		plog.total_score = p.total_score
		plog.round_money = p.round_money
		plog.score = p.round_score
		plog.nickname = p.nickname
		plog.head_url = p.icon
		plog.guid = p.guid
		plog.sex = p.sex
	end)

	self.game_log.cur_round = self.cur_round
	self:save_game_log(self.game_log)

	self.last_discard = nil
	self:update_status(TABLE_STATUS.FREE)
	self:clear_ready()
	self:game_over()
end

function land_table:can_enter(player)
	log.info("land_table:can_enter ===============")
	if not player then
		log.info ("player is nil")
		return false
	end

	local can = self.status == TABLE_STATUS.FREE and  not self.cur_round
	log.info("land_table:can_enter %s",can)
	return can
end

return land_table