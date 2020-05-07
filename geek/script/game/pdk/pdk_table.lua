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
		3,4,5,6,7,8,9,10,11,12,13,15,
		23,24,25,26,27,28,29,30,31,32,33,34,
		43,44,45,46,47,48,49,50,51,52,53,54,
		63,64,65,66,67,68,69,70,71,72,73,74,
	}
}

local pdk_table = base_table:new()

-- 初始化
function pdk_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.status = TABLE_STATUS.FREE
	self:clear_ready()
end

function pdk_table:on_private_inited()
    self.cur_round = nil
    self.zhuang = nil
end

function pdk_table:on_private_dismissed()
    log.info("pdk_table:on_private_dismissed")
    self.cur_round = nil
    self.zhuang = nil
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
	if table.sum(agrees,function(agree) return not agree and 1 or 0  end) > 0 then
		return
	end

	local agree_count = table.sum(self.players,function(p) return agrees[p.chair_id] and 1 or 0 end)
	local agree_count_at_least = self.conf.conf.room.dismiss_all_agree and table.nums(self.players) or math.floor(table.nums(self.players) / 2) + 1
	if agree_count < agree_count_at_least then
		return
	end

	return true
end

function pdk_table:ding_zhuang()
	if not self.cur_round then
		if self.private_id then
			local table_conf = base_private_table[self.private_id]
			self.zhuang = table_conf.owner
			return
		end

		for i,_ in pairs(self.players) do
			self.zhuang = i
			break
		end
	end

	self.zhuang = table.choice(self.players)
end

function pdk_table:on_started(player_count)
	log.info("pdk_table:on_started %s.",player_count)

	self.start_count = player_count
	base_table.on_started(self,player_count)

	self:update_status(TABLE_STATUS.PLAY)

	for _,v in pairs(self.players) do
		v.statistics = {}
	end

	self:ding_zhuang()
	self.game_log = {
		start_game_time = os.time(),
		zhuang = self.zhuang,
		players = table.map(self.players,function(_,chair) return chair,{} end),
		action_table = {},
		rule = self.private_id and self.conf.conf or nil,
		club = (self.private_id and self.conf.club) and club_utils.root(self.conf.club).id,
		table_id = self.private_id or nil,
	}

	self.last_discard = nil

	-- 获取 牌局id
	log.info("gamestart =================================================")
	self:foreach(function(p) 
		log.info("Player InOut Log,pdk_table:startGame player %s, table_id %s ,room_id %s",
			p.guid,p.table_id,p.room_id)
	end)

	self:deal_cards()
	self.cur_discard_chair = self.zhuang
	self:begin_discard()
end

function pdk_table:deal_cards()
	local dealer = card_dealer.new(clone(all_cards[self.start_count]))
	dealer:shuffle()
	self:foreach(function(p)
		local cards = dealer:deal_cards(16)
		p.hand_cards = table.map(cards,function(c) return c,1 end)
	end)

	self:foreach(function(p)
		self:send_desk_enter_data(p)
	end)
end

function pdk_table:get_trustee_conf()
	local trustee = (self.conf and self.conf.conf) and self.conf.conf.trustee or nil
	if trustee and trustee.type_opt ~= nil and trustee.second_opt ~= nil then
	    local trstee_conf = self.room_.conf.private_conf.trustee
	    local seconds = trstee_conf.second_opt[trustee.second_opt + 1]
	    local tp = trstee_conf.type_opt[trustee.type_opt + 1]
	    return tp,seconds
	end
    
	return nil
end

function pdk_table:begin_discard()
	self:broadcast2client("SC_PdkDiscardRound",{
		chair_id = self.cur_discard_chair
	})

	local trustee_type,trustee_seconds = self:get_trustee_conf()
    	if trustee_type and (trustee_type == 1 or (trustee_type == 2 and self.cur_round > 1))  then
		
	end
end

function pdk_table:send_desk_enter_data(player,reconnect)
	send2client_pb(player,"SC_PdkDeskEnter",{
		pb_players = table.series(self.players,function(p,chair)
			return {
				hand_cards = p == player and table.keys(p.hand_cards) or table.fill({},255,1,table.nums(p.hand_cards)),
				chair_id = chair,
				total_score = p.totoal_score,
				round_score = p.round_score,
			}
		end),
		status = self.status,
		zhuang = self.zhuang,
		self_chair_id = player.chair_id,
		act_time_limit = nil,
		is_reconnect = reconnect,
		round = self.cur_round  or 1,
		pb_rec_data = {
			act_left_time = nil,
			last_discard_chair = self.last_discard and self.last_discard.chair or nil,
			last_discard = self.last_discard and self.last_discard.cards or nil,
			total_scores = table.map(self.players,function(p,chair) return chair,p.totoal_score end),
		}
	})
end


function pdk_table:set_trusteeship(player,trustee)
    if not self.conf.conf.trustee or table.nums(self.conf.conf.trustee) == 0 then
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
    self:ding_zhuang()

    self:clear_ready()

    self:foreach(function(v)
        if not self.private_id then
            if v.deposit then
                v:forced_exit()
            elseif v:is_android() then
                self:ready(v)
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

function pdk_table:on_final_game_overed()
    self.start_count = self.chair_count

    self:broadcast2client("SC_PdkFinalGameOver",{
	players = table.series(self.players,function(p,chair)
		return {
			chair_id = chair,
			guid = p.guid,
			score = p.total_score or 0,
			statistics = table.series(p.statistics or {},function(c,t) return {type = t,count = c} end),
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

    for _,p in pairs(self.players) do
        p.total_money = nil
        p.round_money = nil
        p.total_score = nil
    end

    self.zhuang = nil
    base_table.on_final_game_overed(self)
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

function pdk_table:next_player()
	local chair = self.cur_discard_chair
	repeat
		chair = chair  % self.start_count + 1
	until self.players[chair] ~= nil

	self.cur_discard_chair = chair
	return chair
end

function pdk_table:update_status(status)
	self.status = status
end

function pdk_table:pre_start( ... )
	self.gamelog.start_game_time = os.time()
	self:update_status(TABLE_STATUS.PLAY)
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
		log.warning("pdk_table:discard guid[%d] out cards[%s] error, has[%s]", player.guid, table.concat(cards, ','), 
			table.concat(table.keys(player.hand_cards), ','))
		send2client_pb(player,"SC_PdkDoAction",{
			result = enum.ERORR_PARAMETER_ERROR
		})
		return
	end

	local cardstype, cardsval = cards_util.get_cards_type(cards)
	log.info("cardstype[%s] cardsval[%s]" , cardstype , cardsval)
	if not cardstype then
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

	self.last_discard = {
		cards = cards,
		chair = player.chair_id,
		type = cardstype,
		value = cardsval,
		count = #cards,
	}

	if cardstype == CARD_TYPE.BOMB then
		player.bomb = (player.bomb  or 0) + 1
		self.bomb = self.bomb + 1
	end

	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.DISCARD,
		cards = cards,
	})
	log.info("pdk_table:do_action_discard  chair_id [%d] cards{%s}", player.chair_id, table.concat(cards, ','))
	
	table.foreach(cards,function(c) player.hand_cards[c] = nil end)

	table.insert(self.gamelog.actions,{
		action = ACTION.DISCARD,
		chair_id = player.chair_id,
		cards_type = cardstype,
		discards = cards,
		time = os.time(),
	})

	if  table.sum(player.hand_cards) == 0 then
		self:game_balance(player)
	else
		self:next_player()
		self:begin_discard()
	end
end

-- 放弃出牌
function pdk_table:do_action_pass(player, flag)
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("pdk_table:pass_card guid[%d] status error", player.guid)
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("pdk_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_discard_chair)
		return
	end

	if not self.last_discard then
		log.error("pdk_table:pass_card guid[%d] first turn", player.guid)
		return
	end

	-- 记录日志
	table.insert(self.gamelog.actions,{
		chair_id = player.chair_id,
		action = ACTION.PASS,
		time = os.time(),
	})

	self.last_discard = nil

	log.info("cur_chair_id[%d],pass_chair_id[%d]",self.cur_discard_chair,player.chair_id)
	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.PASS
	})
	self:next_player()
	self:begin_discard()
end

--玩家上线处理
function  pdk_table:reconnect(player)
	-- 新需求 玩家掉线不暂停游戏 只是托管
	log.info("pdk_table:reconnect guid:%s",player.guid)
	self:send_desk_enter_data(player)
	if self.status == TABLE_STATUS.PLAY then
		send2client_pb(player,"SC_PdkDiscardRound",{
			chair_id = self.cur_discard_chair
		})
	end
end

function  pdk_table:is_play( ... )
	log.info("pdk_table:is_play : [%s]",self.status)
	return  self.status and self.status ~= TABLE_STATUS.FREE and self.status ~= TABLE_STATUS.END
end

function pdk_table:game_balance()
	local card_scores = table.map(self.players,function(p,chair) return chair, - table.nums(p.hand_cards)  end )
	local bomb_scores = table.map(self.players,function(p,chair) return chair,(p.bomb or 0) * 5 end)
	local card_score_group = table.group(card_scores,function(s) return s < 0 and 1 or 0 end)
	local card_win_chair = table.keys(card_score_group[0])[1]
	card_scores[card_win_chair] = math.abs(table.sum(card_score_group[1]))
	local bomb_score_group = table.group(bomb_scores,function(s) return s < 0 and 1 or 0 end)
	local bomb_win_chair = table.keys(bomb_score_group[0])[1]
	bomb_scores[bomb_win_chair] = math.abs(table.sum(bomb_score_group[1]))
	
	local scores = table.map(self.players,function(_,chair)  return chair,(card_scores[chair] or 0) + (bomb_scores[0] or 0) end)

	self:foreach(function(p,chair)
		p.total_score = (p.total_score or 0) + scores[chair]
	end)

	self:broadcast2client("SC_PdkGameOver",{
		player_balance = table.series(self.players,function(p,chair)
			return {
				chair_id = chair,
				round_score = scores[chair],
				total_score = p.total_score,
				bomb_score = bomb_scores[chair] or 0,
				hand_cards = table.keys(p.hand_cards),
			}
		end)
	})

	self:update_status(TABLE_STATUS.FREE)
	self:clear_ready()
	self:game_over()
end

function pdk_table:clear_ready( ... )
	base_table.clear_ready(self)
	self.status = TABLE_STATUS.FREE
	self.bomb = 0
	self.table_game_id = 0
	self.gamelog = {
		start_game_time = nil,
		end_game_time = nil,
		win_chair = 0,
		finishgameInfo = {},
		playInfo = {},
		actions = {},
    	}
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