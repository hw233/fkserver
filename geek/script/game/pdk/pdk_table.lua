-- 斗地主逻辑
local pb = require "pb"

local base_table = require "game.lobby.base_table"
require "data.land_data"
local log = require "log"
require "game.lobby.game_android"
local timer_manager = require "game.timer_manager"
local card_dealer = require "card_dealer"
local enum = require "pb_enums"
local json = require "cjson"
local cards_util = require "game.pdk.cards_util"
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

local CARD_TYPE = cards_util.PDK_CARD_TYPE

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
	-- 游戏进行
	PLAY = 3,
	-- 结束阶段
	END = 4,
}

local all_cards = {
	[2] = {
		[16] = {
			3,4,5,6,7,8,9,10,11,12,13,15,
			23,24,25,26,27,28,29,30,31,32,33,34,
			43,44,45,46,47,48,49,50,51,52,53,54,
			63,64,65,66,67,68,69,70,71,72,73,74,
		}
	},
	[3] = {
		[16] = {
			3,4,5,6,7,8,9,10,11,12,13,14,15,
			23,24,25,26,27,28,29,30,31,32,33,34,
			43,44,45,46,47,48,49,50,51,52,53,54,
			63,64,65,66,67,68,69,70,71,72,73,
		},
		[15] = {
			3,4,5,6,7,8,9,10,11,12,13,14,15,
			23,24,25,26,27,28,29,30,31,32,33,
			43,44,45,46,47,48,49,50,51,52,53,
			63,64,65,66,67,68,69,70,71,72,
		},
	}
}

local pdk_table = base_table:new()

-- 初始化
function pdk_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.status = TABLE_STATUS.FREE
end

function pdk_table:on_private_inited()
    self.cur_round = nil
    self.zhuang = nil
end

function pdk_table:on_private_dismissed()
    log.info("pdk_table:on_private_dismissed")
    self.cur_round = nil
    self.zhuang = nil
    self.status = nil
    for _,p in pairs(self.players) do
        p.total_money = nil
    end
end

function pdk_table:on_private_pre_dismiss()
    if self.private_id and self.cur_round and self.cur_round > 0 then
        self:on_final_game_overed()
    end
end

function pdk_table:can_dismiss()
	return true
end

function pdk_table:check_dismiss_commit(agrees)
	if table.logic_or(agrees,function(agree) return not agree end) then
		return
	end

	local agree_count = table.sum(self.players,function(p) return agrees[p.chair_id] and 1 or 0 end)
	local agree_count_at_least = self.rule.room.dismiss_all_agree and table.nums(self.players) or math.ceil(table.nums(self.players) / 2)
	return agree_count >= agree_count_at_least 
end



function pdk_table:ding_zhuang()
	local function random_zhuang()
		local ps = table.values(self.players)
		local i  = math.random(#ps)
		return ps[i].chair_id
	end

	local function with_3_zhuang()
		for chair,p in pairs(self.players) do
			if p.hand_cards[3] then return chair end
		end
	end

	local function room_owner_zhuang()
		if not self.private_id then
			log.error("pdk_table:ding_zhuang zhuang room owner but not private table.")
			return
		end

		return self.conf.owner.chair_id
	end

	local function trun_round_zhuang()
		if not self.zhuang or not self.cur_round or self.cur_round == 1 then
			log.error("pdk_table:ding_zhuang turn round, but first round.")
			return
		end

		local zhuang = self.zhuang
		repeat
			zhuang = (zhuang % #self.players) + 1
		until self.players[zhuang]

		return zhuang
	end

	local function winner_zhuang()
		log.dump(self.cur_round)
		if not self.cur_round or self.cur_round == 1 then return end

		for chair,p in pairs(self.players) do
			log.dump(p.win)
			if p.win then return chair end
		end
	end

	local ding_zhuang_fn = {
		[0] = winner_zhuang,
		[1] = trun_round_zhuang,
		[2] = with_3_zhuang,
		[3] = room_owner_zhuang,
		[4] = random_zhuang,
	}

	if self.private_id then
		local zhuang_conf = self.rule and self.rule.play and self.rule.play.zhuang
		local zhuang_opt = (not self.cur_round or self.cur_round == 1) and zhuang_conf.first_round or zhuang_conf.normal_round
		self.zhuang = ding_zhuang_fn[zhuang_opt]()

		if not self.zhuang then
			log.warning("pdk_table:ding_zhuang got nil zhuang,set default.")
			self.zhuang = self.chair_count == 2 and room_owner_zhuang() or with_3_zhuang()
		end
	end
end

function pdk_table:on_process_start()
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

	self:update_status(TABLE_STATUS.PLAY)

	self:ding_zhuang()

	self:foreach(function(p) 
		p.win = nil
		p.round_score = nil
		p.round_money = nil
		p.discard_times = nil
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
	}

	self.bomb = 0
	self.last_discard = nil

	-- 获取 牌局id
	log.info("gamestart =================================================")
	self:foreach(function(p) 
		log.info("Player InOut Log,pdk_table:startGame player %s, table_id %s ,private_table_id:%s",p.guid,p.table_id,self.private_id)
	end)

	self:deal_cards()
	self.cur_discard_chair = self.zhuang
	self.first_discard = true
	self.game_log.zhuang = self.zhuang
	self:begin_discard()
end

function pdk_table:deal_cards()
	local play = self.rule and self.rule.play
	local cards_count = 16
	if play and play.card_num then
		local play_card_num = play.card_num
		cards_count = (play_card_num == 15 or play_card_num == 16) and play_card_num or 16
	end
	local cards = clone(all_cards[self.start_count][cards_count])
	if play and play.abandon_3_4 then
		for i,c in pairs(cards) do
			local v = cards_util.value(c)
			if v == 3 or v == 4 then
				cards[i] = nil
			end
		end

		cards = table.values(cards)
	end

	local dealer = card_dealer.new(cards)
	dealer:shuffle()
	local pei_cards = {
		-- {3,23,43,63,4,24,44,64,5,25,45,65,14,34,54,15},
		-- {6,26,46,66,7,27,47,67,8,28,48,68,9,29,49,69},
		-- {10,30,50,70,11,31,51,71,12,32,52,72,13,33,53,73},
	}
	dealer:layout_cards(table.union_tables(pei_cards))
	self:foreach(function(p,chair)
		local cards = dealer:deal_cards(cards_count)
		self.game_log.players[chair].deal_cards = cards
		p.hand_cards = table.map(cards,function(c) return c,1 end)
	end)

	self:foreach(function(p)
		self:send_desk_enter_data(p)
	end)
end

function pdk_table:get_trustee_conf()
	local trustee = self.rule and self.rule.trustee or nil
	if trustee and trustee.type_opt ~= nil and trustee.second_opt ~= nil then
	    local trstee_conf = self.room_.conf.private_conf.trustee
	    local seconds = trstee_conf.second_opt[trustee.second_opt + 1]
	    local type = trstee_conf.type_opt[trustee.type_opt + 1]
	    return type,seconds
	end
    
	return nil
end

function pdk_table:set_trusteeship(player,trustee)
	player.trustee = trustee
	base_table.set_trusteeship(player,trustee)
end

function pdk_table:begin_discard()
	self:broadcast2client("SC_PdkDiscardRound",{
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

function pdk_table:send_desk_enter_data(player,reconnect)
	local msg = {
		status = self.status,
		zhuang = self.zhuang,
		self_chair_id = player.chair_id,
		act_time_limit = nil,
		is_reconnect = reconnect,
		round = self.cur_round  or 1,
	}

	msg.pb_players = table.series(self.players,function(p,chair)
		local d = {
			chair_id = chair,
			total_score = p.total_score,
		}

		if self.status == TABLE_STATUS.PLAY then
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
		}

		local trustee_type = self:get_trustee_conf()
		if trustee_type then
			self:set_trusteeship(player)
		end
	end
	send2client_pb(player,"SC_PdkDeskEnter",msg)
end


function pdk_table:set_trusteeship(player,trustee)
    if not self.rule.trustee or table.nums(self.rule.trustee) == 0 then
        return 
    end

    if player.trustee and trustee then
        return
    end

    base_table.set_trusteeship(self,player,trustee)
    player.trustee = trustee
end

function pdk_table:on_game_overed()
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

    base_table.on_game_overed(self)
end

function pdk_table:on_process_over()
    self.start_count = self.chair_count

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

    self.zhuang = nil
    base_table.on_process_over(self)
end

-- 检查是否可取消准备
function pdk_table:can_stand_up(player, reason)
    log.info("pdk_table:can_stand_up guid:%s,reason:%s",player.guid,reason)
    if reason == enum.STANDUP_REASON_DISMISS or
        reason == enum.STANDUP_REASON_FORCE then
        return true
    end

    return (not self.status or self.status == TABLE_STATUS.FREE) and not self.cur_round
end

function pdk_table:on_offline(player)
	
end

function pdk_table:load_lua_cfg()
	
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
	if not act or not act.action then
		log.error("pdk_table:do_action act is nil.")
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

	log.error("pdk_table:do_action invalid action:%s",act.action)
end

function pdk_table:get_cards_type(cards)
	local cardstype, cardsval = cards_util.get_cards_type(cards)
	if self.rule and self.rule.play.AAA_is_bomb and cardstype == CARD_TYPE.THREE and cardsval  == 14 then
		cardstype = CARD_TYPE.MISSLE
	end

	return cardstype,cardsval
end

function pdk_table:check_discard_next_player_last_single(ctype,cvalue)
	local play = self.rule and self.rule.play
	if not play then return end

	-- 下家报单必出最大单牌
	if play.bao_dan_discard_max and not self.last_discard then
		local next_player = self.players[self:next_chair()]
		if table.nums(next_player.hand_cards) == 1 and ctype == CARD_TYPE.SINGLE then
			local _,hand_max_value = table.max(self:cur_player().hand_cards,function(_,c) return cards_util.value(c) end)
			return hand_max_value ~= cvalue
		end
	end
end

function pdk_table:check_discard_cards_type(ctype,cvalue)
	local play = self.rule and self.rule.play
	if not play then return end

	if ( 	(ctype == CARD_TYPE.FOUR_WITH_TWO or ctype == CARD_TYPE.FOUR_WITH_ONE)  and not play.si_dai_er ) or --四带二
		(ctype == CARD_TYPE.FOUR_WITH_THREE and not play.si_dai_san) or --四带三
		(ctype == CARD_TYPE.THREE_WITH_ONE and (not play.san_dai_yi or table.nums(self:cur_player().hand_cards) ~= 4))  --三带一
	then
		return true
	end
end

function pdk_table:check_first_discards_with_3(cards)
	local play = self.rule and self.rule.play
	if not play then return end

	-- 首张带黑桃3
	if self.first_discard and play.first_discard and play.first_discard.with_3 then
		return table.logic_and(cards,function(c) return c ~= 3 end) 
	end
end

-- 出牌
function pdk_table:do_action_discard(player, cards)
	log.info("pdk_table:do_action_discard {%s}",table.concat(cards,","))
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("pdk_table:discard guid[%d] status error", player.guid)
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("pdk_table:discard guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn)
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERORR_PARAMETER_ERROR
		})
		return
	end

	if not table.logic_and(cards,function(c) return player.hand_cards[c] ~= nil end) then
		log.warning("pdk_table:discard guid[%d] cards[%s] error, has[%s]", player.guid, table.concat(cards, ','), 
			table.concat(table.keys(player.hand_cards), ','))
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERORR_PARAMETER_ERROR
		})
		return
	end

	local cardstype, cardsval = self:get_cards_type(cards)
	log.info("cardstype[%s] cardsval[%s]" , cardstype , cardsval)
	if not cardstype then
		log.warning("pdk_table:discard guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cards, ','))
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERORR_PARAMETER_ERROR
		})
		return
	end

	if self:check_discard_cards_type(cardstype,cardsval) or 
	   self:check_discard_next_player_last_single(cardstype,cardsval) or 
	   self:check_first_discards_with_3(cards) then
		log.warning("pdk_table:discard guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cards, ','))
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERORR_PARAMETER_ERROR
		})
		return
	end
	
	local cmp = cards_util.compare_cards({type = cardstype, count = #cards, value = cardsval}, self.last_discard)
	if self.last_discard and (not cmp or cmp <= 0) then
		log.warning("pdk_table:discard guid[%d] compare_cards error, cards[%s], cur_discards[%d,%d,%d], last_discard[%d,%d,%d]", 
			player.guid, table.concat(cards, ','),cardstype, #cards,
			cardsval,self.last_discard.type,self.last_discard.count,self.last_discard.value)
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERORR_PARAMETER_ERROR
		})
		return
	end

	self.first_discard = nil

	self.last_discard = {
		cards = cards,
		chair = player.chair_id,
		type = cardstype,
		value = cardsval,
		count = #cards,
	}

	player.discard_times = (player.discard_times or 0) + 1

	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.DISCARD,
		cards = cards,
	})

	log.info("pdk_table:do_action_discard  chair_id [%d] cards{%s}", player.chair_id, table.concat(cards, ','))
	
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
function pdk_table:do_action_pass(player)
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("pdk_table:pass_card guid[%d] status error", player.guid)
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("pdk_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_discard_chair)
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if not self.last_discard then
		log.error("pdk_table:pass_card guid[%d] first turn", player.guid)
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	if self.rule and self.rule.play.must_discard then
		local type,value = cards_util.seek_great_than(player.hand_cards,self.last_discard.type,self.last_discard.value,self.last_discard.count)
		dump(type)
		dump(value)
		if type then
			log.error("pdk_table:pass_card guid[%d] must discard", player.guid)
			send2client_pb(player,"SC_PdkDoAction",{
				result = enum.ERORR_PARAMETER_ERROR
			})
			return
		end
	end

	-- 记录日志
	table.insert(self.game_log.actions,{
		chair_id = player.chair_id,
		action = ACTION.PASS,
		time = os.time(),
	})

	log.info("cur_chair_id[%d],pass_chair_id[%d]",self.cur_discard_chair,player.chair_id)
	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.PASS
	})

	self.cur_discard_chair =  self:next_chair()

	if self.last_discard and self.cur_discard_chair == self.last_discard.chair  then
		log.dump(self.last_discard)
		if self.last_discard.type == CARD_TYPE.BOMB or self.last_discard.type == CARD_TYPE.MISSLE then
			local p = self:cur_player()
			p.bomb = (p.bomb or 0) + 1
		end
		log.dump(self:cur_player().bomb)
		self.last_discard = nil
	end

	self:begin_discard()
end

--玩家上线处理
function  pdk_table:reconnect(player)
	-- 新需求 玩家掉线不暂停游戏 只是托管
	log.info("pdk_table:reconnect guid:%s",player.guid)
	if self:is_play(player) then
		self:send_desk_enter_data(player,true)
	end
	if self.status == TABLE_STATUS.PLAY then
		send2client_pb(player,"SC_PdkDiscardRound",{
			chair_id = self.cur_discard_chair
		})
	end
	base_table.reconnect(self,player)
end

function  pdk_table:is_play( ... )
	log.info("pdk_table:is_play : [%s]",self.status)
	return  self.status and self.status ~= TABLE_STATUS.FREE and self.status ~= TABLE_STATUS.END
end

function pdk_table:game_balance(winner)
	local play = self.rule and self.rule.play
	local function calc_score(p)
		local count = table.nums(p.hand_cards)
		local score = (play and play.lastone_not_consume and count <= 1) and 0 or count
		score = ((not p.discard_times or p.discard_times == 0 or (p.discard_times == 1 and self.zhuang == p.chair_id)) and 2  or 1) * score
		return score
	end

	local card_win_matrix = table.map(self.players,function(p,chair)
		local score = calc_score(p)
		return chair, table.map(self.players,function(_,c) if c == winner.chair_id then return c,score end end)
	end )

	local card_losers = table.map(card_win_matrix,function(winer,c) return c, - table.sum(winer) end)
	log.dump(card_losers)
	local card_winers = table.merge_tables(card_win_matrix,function(l,r) return (l or 0) + (r or 0)  end)
	log.dump(card_winers)
	local card_scores = table.merge(card_winers,card_losers,function(l,r) return (l or 0) + (r or 0) end)
	log.dump(card_scores)

	local bomb_lose_matrix = table.map(self.players,function(p,chair)
		local score = (p.bomb or 0) * 5
		return chair,table.map(self.players,function(_,c) return c,c ~= chair and -score or nil end)
	end)
	local bomb_winners = table.map(bomb_lose_matrix,function(losers,chair) return chair,math.abs(table.sum(losers)) end)
	dump(bomb_winners)
	local bomb_losers = table.merge_tables(bomb_lose_matrix,function(l,r) return (l or 0) + (r or 0) end) 
	dump(bomb_losers)
	local bomb_scores = table.merge(bomb_winners,bomb_losers,function(l,r) return (l or 0) + (r  or 0) end)

	log.dump(bomb_scores)
	
	local scores = table.map(self.players,function(_,chair)  return chair,(card_scores[chair] or 0) + (bomb_scores[chair] or 0) end)

	self:foreach(function(p,chair)
		local score = scores[chair]
		if score >= 0 and (p.statistics.max_score or 0) < score then
			p.statistics.max_score = score
		end
	end)

	local moneies = table.map(scores,function(score,chair) return chair,self:calc_score_money(score) end)
	moneies = self:balance(moneies,enum.LOG_MONEY_OPT_TYPE_PDK)
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
				hand_cards = table.keys(p.hand_cards),
			}
		end)
	})

	self:notify_game_money()

	table.foreach(self.players,function(p,chair) 
		local plog = self.game_log.players[chair]
		plog.total_money = p.total_money
		plog.total_score = p.total_score
		plog.round_money = p.round_money
		plog.score = p.round_score
		plog.nickname = p.nickname
		plog.head_url = p.icon
		plog.guid = p.guid
		plog.sex = p.sex
		plog.bomb_score = bomb_scores[chair]
	end)

	self.game_log.cur_round = self.cur_round
	self:save_game_log(self.game_log)

	self.last_discard = nil
	self:update_status(TABLE_STATUS.FREE)
	self:clear_ready()
	self:game_over()
end

function pdk_table:can_enter(player)
	log.info("pdk_table:can_enter ===============")
	if not player then
		log.info ("player is nil")
		return false
	end

	local can = self.status == TABLE_STATUS.FREE and  not self.cur_round
	log.info("pdk_table:can_enter %s",can)
	return can
end

return pdk_table