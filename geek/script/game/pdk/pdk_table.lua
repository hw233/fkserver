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
	NONE = pb.enum("PDK_CARD_TYPE", "ACTION_NONE"),
	DISCARD = pb.enum("PDK_ACTION", "ACTION_DISCARD"),
	PASS = pb.enum("PDK_CARD_TYPE", "ACTION_PASS"),
}

local TABLE_STATUS = {
	-- 等待开始
	FREE = 1,
	-- 开始倒记时
	START_COUNT_DOWN = 2,
	-- 游戏进行
	PLAY = 4,
	-- 玩家掉线
	PLAYOFFLINE = 5,
	-- 加倍阶段
	DOUBLE = 6,
	-- 结束阶段
	END = 7,
}


--地主掉线基础倍数
local PDK_ESCAPE_SCORE_BASE = 10
--地主掉线低于基础倍数后的扣分倍数
local PDK_ESCAPE_SCORE_LESS = 10
--地主掉线高于基础倍数后的扣分 乘以倍数
local PDK_ESCAPE_SCORE_GREATER = 2
--农民掉线基础倍数
local FARMER_ESCAPE_SCORE_BASE = 10
--农民掉线低于基础倍数后的扣分倍数
local FARMER_ESCAPE_SCORE_LESS = 10
--农民掉线高于基础倍数后的扣分 乘以倍数
local FARMER_ESCAPE_SCORE_GREATER = 2
--好牌基础概率默认3
local BASIC_COEFF = 3
--好牌浮动概率默认2
local FLOAT_COEFF = 2
--系统系数
local SYSTEM_COEFF = 100

local PDK_TIME_OVER = 1000

--差牌概率
local system_bad_card_coeff = 60

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

	-- 获取 牌局id
	log.info("gamestart =================================================")

	self:foreach(function(v) 
		local t_guid = v.guid or 0
		local t_room_id = v.room_id or 0
		local t_table_id = v.table_id or 0
		log.info("Player InOut Log,pdk_table:startGame player %s, table_id %s ,room_id %s,game_id %s",t_guid,t_table_id,t_room_id,self.table_game_id)
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
		p.cards = table.map(cards,function(c) return c,1 end)
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
				hand_cards = p == player and table.keys(p.cards) or table.fill({},255,1,table.nums(p.cards)),
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

    return not self.status or self.status == TABLE_STATUS.FREE
end

-- 检查是否可取消准备
function pdk_table:check_cancel_ready(player, offline)
	log.info("check_cancel_ready guid [%d] status [%d] is_offline[%s]",player.guid and player.guid or 0,self.status,tostring(offline))
	base_table.check_cancel_ready(self,player,offline)
	player.offline = offline
	if self.status ~= TABLE_STATUS.FREE and self.status ~= TABLE_STATUS.START_COUNT_DOWN then  -- 游戏状态判断 只有游戏在未开始时才可以取消
		if offline then
			--掉线处理
			self:player_offline(player)
		end
		return false
	end
	--退出
	return true
end

function pdk_table:is_play(...)
	return self.status and self.status ~= TABLE_STATUS.FREE
end

function pdk_table:load_lua_cfg()
	if not self.room_.room_cfg then return end
	local land_config = self.room_.room_cfg
	if land_config then
		if land_config.GameLimitCdTime then
		log.info("GameLimitCdTime : [%s]" , land_config.GameLimitCdTime)
		self.GameLimitCdTime = land_config.GameLimitCdTime
		end
		if land_config.basic_coeff then
		log.info("basic_coeff : [%s]" , land_config.basic_coeff)
		self.BASIC_COEFF = land_config.basic_coeff
		end

		if land_config.float_coeff then
		log.info("float_coeff : [%s]" , land_config.float_coeff)
		self.FLOAT_COEFF = land_config.float_coeff
		end

		if land_config.playWithAndroid then -- self.playWithAndroid.status 0 关 1 全开 2 按渠道开 3 按渠道关
		log.info("playWithAndroid : [%s]" , land_config.playWithAndroid)
		self.playWithAndroid = land_config.playWithAndroid
		if self.playWithAndroid then
			if self.playWithAndroid.status then
			log.info("self.playWithAndroid.status [%d] ", self.playWithAndroid.status)
			if self.playWithAndroid.list_channelid then
				log.info(table.concat(self.playWithAndroid.list_channelid, ','))
			end
			else
			-- 没有配置 默认全开
			log.info("self.playWithAndroid.status is nil Android all open")
			self.playWithAndroid = {
				status = 1,
				list_channelid = {},
			}
			end
		else
			-- 没有配置 默认全开
			log.info("self.playWithAndroid is nil Android all open")
			self.playWithAndroid = {
			status = 1,
			list_channelid = {},
			}
		end
		log.info("self.playWithAndroid [%s] self.playWithAndroid.status[%s] self.playWithAndroid.status [%d]", tostring(self.playWithAndroid) , tostring(self.playWithAndroid.status) , self.playWithAndroid.status)
		end

		if land_config.system_bad_card_coeff then
		log.info("system_bad_card_coeff : [%s]" , land_config.system_bad_card_coeff)
		self.system_bad_card_coeff = land_config.system_bad_card_coeff
		end
	else
		log.info("land_config is nil")
	end
end

--校验抽出来的牌型
function pdk_table:check_this_good_cards(cards)
	local this_cards = {}
	for i,v in ipairs(cards) do
		for _,z in ipairs(v) do
			table.insert(this_cards,z)
		end
	end
	table.sort(this_cards, function(a, b) return a < b end)
	for j=1,54 do
		local value_key = j - 1
		if value_key ~= this_cards[j] then
			log.error(table.concat(this_cards, ','))
			return false
		end
	end
	return true
end

--做牌
function pdk_table:handle_good_cards()
	local this_one_good_cards  = {}
	if self.good_cards_total ~= 0 then
		local good_cards_index = math.random(1,self.good_cards_total) --随机选一首好牌
		log.info("~~~~~~~~~good_cards_index:",good_cards_index)
		for i,v in ipairs(good_cards_array[good_cards_index]) do
			this_one_good_cards[i] = {}
			for _,z in ipairs(v) do
				table.insert(this_one_good_cards[i],z)
			end
		end
	end
	return this_one_good_cards
end

function pdk_table:next_player()
	local chair = self.cur_discard_chair
	repeat
		chair = (chair + 1) % self.start_count + 1
	until self.players[chair] ~= nil
	self.cur_discard_chair = chair
	return chair
end

function pdk_table:prepare_cards()
	self.bad_card_make_flag = 0 --做差牌标记，成功标记为1
	--做差牌接口(满足概率和必须是开启了机器人的情况下再做差牌)
	local bad_card_coeff = math.random(1,100)
    	log.info("table_id [%d] playWithAndroid_isopen [%s] bad_card_coeff [%s]", self.table_id_ , self.playWithAndroid_isopen , bad_card_coeff , self.system_bad_card_coeff)
	if self.playWithAndroid_isopen and bad_card_coeff < self.system_bad_card_coeff then
		if self:shuffle_cheat_cards() == true then --做差牌成功
			log.info("shuffle_cheat_cards-------------------->ok.")
			self.bad_card_make_flag = 1
			log.info("befor change cards ----->last three cards [%d][%d][%d]",self.cards[52], self.cards[53], self.cards[54])
			self.cards = {}
			for _,value in ipairs(self.new_cards) do
				if value then
					table.insert(self.cards, value)
				end
			end

			log.info("after change cards ----->last three cards [%d][%d][%d]",self.cards[52], self.cards[53], self.cards[54])
		end
	end

	self.good_cards_flag = 0 --该局是否做好牌的标志，默认0,1做好牌
	self.three_cards = {} --存储底牌
	self.this_good_cards = {} --存储好牌
	self.all_player_cards = {} --存储3个玩家的17张牌
	local max_card = 0 --记录最大的牌,保证拿最大的牌的人第一个叫地主
	local last_three_cards = string.format("%d %d %d",self.cards[52], self.cards[53], self.cards[54])
	local good_cards_coeff = math.random(0,SYSTEM_COEFF)
	if self.FLOAT_COEFF == nil then
		self.FLOAT_COEFF = 2
	end
	local float_coeff = math.random(0,self.FLOAT_COEFF)
	local this_time_coeff = self.BASIC_COEFF + float_coeff
	if self.bad_card_make_flag == 0 and good_cards_coeff <  this_time_coeff then --满足概率，随机做1副好牌
		self.good_cards_flag = 1
		--log.info("~~~~~please send good cards............"))
	else
		--log.info("~~~~~please send normal cards............"))
	end
	if self.good_cards_flag == 1 then
		self.this_good_cards = self:handle_good_cards()
		if self.this_good_cards ~= nil and self:check_this_good_cards(self.this_good_cards) == true then --抽好牌成功
			--底牌和闲家的牌分开
			table.insert(self.three_cards,self.this_good_cards[4]) --底牌3张
			last_three_cards = string.format("%d %d %d",self.three_cards[1][1],self.three_cards[1][2],self.three_cards[1][3])--底牌3张
			--满足好牌概率并且成功抽出好牌,将底牌三张换掉在后面发送上去,后面发牌就会发抽取的该牌型
			--因为在后面发送到底牌还是self.cards[52] ～ self.cards[54]
			--[[self.cards[52] = three_cards[1][1]
			self.cards[53] = three_cards[1][2]
			self.cards[54] = three_cards[1][3]--]]
			--log.info("last_three_cards[%d] [%d] [%d]",self.three_cards[1][1],self.three_cards[1][2],self.three_cards[1][3]))

			for i=1,3 do
				table.insert(self.all_player_cards,self.this_good_cards[i])
				--log.info(table.concat(self.all_player_cards[i], ','))
			end
			--记录最大的牌,保证拿最大的牌的人第一个叫地主
			max_card = self.all_player_cards[1][1]
			--随机打乱三首牌顺序
			local len = #self.all_player_cards
			for i=1,len do
				local x = math.random(1,len)
				local y = math.random(1,len)
				if x ~= y then
					self.all_player_cards[x], self.all_player_cards[y] = self.all_player_cards[y], self.all_player_cards[x]
				end
				len = len - 1
			end
		else
			self.good_cards_flag = 0 --抽好牌出错按正常逻辑发牌
		end
	end

	-- 发牌
	self.first_turn = math.floor((self.valid_card_idx-1)/17)+1
	self.callpoints_log = {
		start_time = os.time(),
		first_turn = self.first_turn,
		player_cards = {},
		callpoints_process = {},
		land_card = last_three_cards,
	}
	local msg = {
		valid_card_chair_id = self.valid_card_idx,
		valid_card = self.cards[self.valid_card_idx],
	}

	--满足做好牌的概率
	if self.good_cards_flag == 1 then
		--机器人的牌局，不让玩家拿好牌(第一副牌就是好牌)
		local android_count,player_index = self:get_android_count()
		if android_count == 2 and player_index == 1 then
			--待交换的牌(随机第二副或者第三副)
			local change_index = math.random(2) + 1
			self.all_player_cards[1], self.all_player_cards[change_index] = self.all_player_cards[change_index], self.all_player_cards[1]
			log.info("player change cards index [%d]" ,change_index)
		end

		for i,v in ipairs(self.players) do
			if v then
				local cards = {}
				cards = self.all_player_cards[i]
				if max_card == cards[1] then  --保证拿最大的牌的人第一个叫地主
					self.first_turn = i
					self.callpoints_log.first_turn = self.first_turn
				end
				table.sort(cards, function(a, b) return a < b end)
				v.outTime = 0
				v.is_double = nil
				self.land_player_cards[v.chair_id]:init(cards)
				msg.cards = cards
				send2client_pb(v, "SC_LandStart", msg)
				--log.info("v.chair_id: [%d]" ,v.chair_id))
				--log.info(table.concat(msg.cards, ','))

				----------- 日志相关
				local player_card = {
					chair_id = v.chair_id,
					guid = v.guid,
					cards = table.concat(msg.cards, ','),
				}
				table.insert(self.callpoints_log.player_cards,player_card)
			end
		end
	else
		if self.bad_card_make_flag == 1 then
			local player_bad_cards = {} --差牌
			local player_other_cards = {}
			local cur = 0
			for i=1,3 do
				if i == 1 then
					for j = cur+1, cur+17 do
						table.insert(player_bad_cards, self.cards[j])
					end
				else
					for j = cur+1, cur+17 do
						table.insert(player_other_cards, self.cards[j])
					end
				end
				cur = cur + 17
			end
			local i_index = 0
			for i,v in ipairs(self.players) do
				if v then
					local cards = {}
					if v.guid > 0 then --给真实玩家差牌
						for j=1,17 do
							table.insert(cards, tonumber(player_bad_cards[j]))
						end
					else --机器人
						for j = i_index+1, i_index+17 do
							table.insert(cards, player_other_cards[j])
						end
						i_index = i_index + 17
					end

					table.sort(cards, function(a, b) return a < b end)
					v.outTime = 0
					v.is_double = nil
					self.land_player_cards[v.chair_id]:init(cards)
					msg.cards = cards
					send2client_pb(v, "SC_LandStart", msg)
					log.info("make bad cards-------->guid[%d]  chair_id: [%d]." ,v.guid,v.chair_id)
					log.info(table.concat(msg.cards, ','))

					----------- 日志相关
					local player_card = {
						chair_id = v.chair_id,
						guid = v.guid,
						cards = table.concat(msg.cards, ','),
					}
					table.insert(self.callpoints_log.player_cards,player_card)
				end
			end
		else
			local cur = 0
			for i,v in ipairs(self.players) do
				if v then
					local cards = {}
					for j = cur+1, cur+17 do
						table.insert(cards, self.cards[j])
					end
					cur = cur + 17
					table.sort(cards, function(a, b) return a < b end)
					v.outTime = 0
					v.is_double = nil
					self.land_player_cards[v.chair_id]:init(cards)
					msg.cards = cards
					send2client_pb(v, "SC_LandStart", msg)

					local player_card = {
						chair_id = v.chair_id,
						guid = v.guid,
						cards = table.concat(msg.cards, ','),
					}
					table.insert(self.callpoints_log.player_cards,player_card)
				end
			end
		end
	end
end

function pdk_table:update_status(status)
	self.status = status
end

function pdk_table:pre_start( ... )
	self.status = TABLE_STATUS.START_COUNT_DOWN
	self.gamelog.start_game_time = os.time()
	log.info("first call soure chairid : %s ", tostring(self.first_turn))
	self.cur_turn = self.first_turn
	self.cur_call_score = 0
	self.cur_call_score_chair_id = 0
	self:update_status(TABLE_STATUS.PLAY)
end


-- 发地主底牌
function pdk_table:send_pdk_cards(player)
	log.info("==========send_pdk_cards: [%s]" ,self.cur_call_score_chair_id)

	self.flag_land = self.cur_call_score_chair_id
	self.flag_chuntian = true
	self.flag_fanchuntian = true
	self.time_outcard_ = PDK_TIME_HEAD_OUT_CARD
	self.cur_turn = self.cur_call_score_chair_id

	self.landcards = cards_
	log.info("landcards [%s]",table.concat(cards_,","))
	log.info("befor landplayercards [%s]",table.concat(self.land_player_cards[self.cur_call_score_chair_id].cards_,","))
	self.land_player_cards[self.cur_call_score_chair_id]:add_cards(cards_)
	log.info("after number [%d] landplayercards [%s]",#self.land_player_cards[self.cur_call_score_chair_id].cards_,table.concat(self.land_player_cards[self.cur_call_score_chair_id].cards_,","))

	self.last_discards = nil
	self.last_discards_chair_id = 0
	self.Already_Out_Cards = {}
	local msg = {
		land_chair_id = self.first_turn,
		call_score = self.cur_call_score,
		cards = cards_,
		}
	self:broadcast2client("SC_LandInfo", msg)
end


function pdk_table:do_action(player,act)
	if not act or not act.action then
		log.error("pdk_table:do_action act is nil.")
		return
	end

	local do_actions = {
		[ACTION.DISCARD] = function(act)
			self:do_action_discard(player,act.cards)
		end,
		[ACTION.PASS] = function(act)
			self:do_action_pass(player)
		end,
	}

	if do_actions[act.action] then
		do_actions[act.action](act)
		return
	end

	log.error("pdk_table:do_action invalid action:%s",act.action)
end


-- 出牌
function pdk_table:do_action_discard(player, cards)
	log.info(table.concat(cards,","))
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning("pdk_table:discard guid[%d] status error", player.guid)
		return
	end

	if player.chair_id ~= self.cur_discard_chair then
		log.warning("pdk_table:discard guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn)
		return
	end

	if not table.logic_and(cards,function(c) return player.hand_cards[c] ~= nil end) then
		log.error("pdk_table:discard guid[%d] out cards[%s] error, has[%s]", player.guid, table.concat(cards, ','), table.concat(table.keys(player.hand_cards), ','))
		return
	end

	local cardstype, cardsval = cards_util.get_cards_type(cards)
	log.info("gameid[%s] cardstype[%s] cardsval[%s]" , self.table_game_id , cardstype , cardsval)
	if not cardstype then
		log.error("pdk_table:discard guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cards, ','))
		return
	end
	
	local cur_discards = {cards_type = cardstype, cards_count = #cards, cards_val = cardsval}
	if not cards_util.compare_cards(cur_discards, self.last_discards) then
		log.error("pdk_table:discard guid[%d] compare_cards error, cards[%s], cur_discards[%d,%d,%d], last_discards[%d,%d,%d]", player.guid, table.concat(cards, ','),
			cur_discards.cards_type , cur_discards.cards_count, cur_discards.cards_val,self.last_discards.cards_type,self.last_discards.cards_count,self.last_discards.cards_val)
		return
	end

	self.last_discard = {
		cards = cards,
		chair = player.chair_id,
	}
	if self.flag_fanchuntian == true and self.cur_turn == self.flag_land and #self.land_player_cards[self.cur_turn].cards_ < 20 then
		self.flag_fanchuntian = false
	end

	if self.cur_turn ~= self.flag_land and self.flag_chuntian then
		self.flag_chuntian = false
	end

	if self.flag_chuntian == false and self.cur_turn == self.flag_land then
		-- 如果 春天没有的情况下 地主出牌 则 反春天不成立 另外 结算时 没有农民玩家牌数达到17也没有反春天
		self.flag_fanchuntian = false
	end

	if cardstype == CARD_TYPE.MISSILE or cardstype == CARD_TYPE.BOMB then
		player.bomb_count = (player.bomb_count  or 0) + 1
		self.bomb = self.bomb + 1
	end

	self:broadcast2client("SC_PdkDoAction", {
		chair_id = player.chair_id,
		action = ACTION.DISCARD,
		cards = cards,
	})
	log.info("outcard ==========================   chair_id [%d] cards[%s]", player.chair_id, table.concat(cards, ','))
	
	table.foreach(cards,function(c) player.cards[c] = nil end)
	table.insert(self.gamelog.actions,{
		action = ACTION.DISCARD,
		chair_id = player.chair_id,
		cards_type = cardstype,
		discards = cards,
		time = os.time(),
	})

	if  table.sum(player.hand_cards) == 0 then
		self:finishgame(player)
	else
		self:next_player()
		self:begin_discard()
	end
end

-- 放弃出牌
function pdk_table:do_action_pass(player, flag)
	if self.status ~= TABLE_STATUS.PLAY then
		log.warning(string.format("pdk_table:pass_card guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log.warning(string.format("pdk_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	if not self.last_discards then
		log.error(string.format("pdk_table:pass_card guid[%d] first turn", player.guid))
		return
	end

	if not flag or flag == false then
		player.TrusteeshipTimes = 0
	end

	-- 记录日志
	local outcard = {
		chair_id = player.chair_id,
		outcards = "pass card",
		sparecards = string.format("%s",table.concat(self.land_player_cards[player.chair_id].cards_, ',')),
		time = os.time(),
		isTrusteeship = player.isTrusteeship and 1 or 0,
	}
	table.insert(self.gamelog.outcard_process,outcard)


	if self.cur_turn == 3 then
		self.cur_turn = 1
	else
		self.cur_turn = self.cur_turn + 1
	end

	local is_turn_over = (self.cur_turn == self.first_turn and 1 or 0)
	if is_turn_over == 1 then
		self.last_discards = nil
	end
	-- self.time0_ = os.time()
	local notify = {
		cur_chair_id = self.cur_turn,
		pass_chair_id = player.chair_id,
		turn_over = is_turn_over,
		}
	log.info("cur_chair_id[%d],pass_chair_id[%d]",notify.cur_chair_id,notify.pass_chair_id)
	self:broadcast2client("SC_LandPassCard", notify)
	self:next_player_proc()
end

function pdk_table:next_player_proc( ... )
	if  self.status == TABLE_STATUS.CALL then
		if not self.players[self.cur_turn] then
			log.error(string.format("not find player gameTableid [%s]",self.table_game_id))
			self:finishgameError()
		elseif self.players[self.cur_turn].Dropped or self.players[self.cur_turn].isTrusteeship then
			-- self:call_score(self.players[self.cur_turn], 0)
			self.time0_ = os.time() - PDK_TIME_CALL_SCORE + 1
		end
	elseif self.status == TABLE_STATUS.PLAY then
		--log.info("========================================next_player_proc")
		if self.players[self.cur_turn].Dropped or self.players[self.cur_turn].isTrusteeship or self.players[self.cur_turn].LastTrusteeship then
			log.info("========================================Trusteeship123")
			self.time0_ = os.time() - self.time_outcard_ + 1
			self.time0_ = os.time()
		end
	end
end

--玩家上线处理
function  pdk_table:reconnect(player)
	-- 新需求 玩家掉线不暂停游戏 只是托管
	log.info("pdk_table:reconnect guid:%s",player.guid)
	self:send_desk_enter_data(player)
end

function  pdk_table:is_play( ... )
	log.info("pdk_table:is_play : [%s]",tostring(self.status))
	if self.status and self.status ~= TABLE_STATUS.FREE and self.status ~= TABLE_STATUS.END then
		log.info("is_play  return true")
		return true
	end
	return false
end

--玩家掉线处理
function  pdk_table:player_offline( player )
	log.info("pdk_table:player_offline")
	base_table.player_offline(self,player)
	log.info("player offline : guid[%d] chairid[%s]",player.guid,player.chair_id)
	-- body
	if self.status == TABLE_STATUS.FREE then
		-- 等待开始时 掉线则强制退出玩家
		player:forced_exit()
	elseif self.status == TABLE_STATUS.PLAY or self.status == TABLE_STATUS.CALL or self.status == TABLE_STATUS.DOUBLE then
		-- 游戏进行时 则暂停游戏
		-- 新需求更新为 不再暂停游戏 托管玩家
		player.isTrusteeship = false
		self:set_trusteeship(player,true)
	elseif self.status == TABLE_STATUS.PLAYOFFLINE then
		-- 叫分状态时 掉线则所有玩家待
		--发送掉线消息
		local notify = {
			cur_chair_id = player.chair_id,
			wait_time = PDK_TIME_WAIT_OFFLINE,
		}
		self:broadcast2client("SC_LandCallScorePlayerOffline", notify)
		--设置状态为等待
		player.offtime = os.time()
		local i = 0
		for i,v in ipairs(self.players) do
			if v then
				i = i + 1
			end
		end
		if i == 3 then
			--3个玩家都退出了 直接结束游戏 踢人
			local room_limit = self.room_:get_room_limit()
			self:clear_ready()
			for i,v in ipairs(self.players) do
				if v then
					log.info("chair_id [%d] is offline forced_exit~! guid is [%d]" , v.chair_id, v.guid)
					v:forced_exit()
				end
			end
			log.info("game init")
			return
		end
	end
end

function pdk_table:finishgameError()
	self.status = TABLE_STATUS.END
	for i,v in ipairs(self.players) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log.info("Player InOut Log,pdk_table:finishgameError player %s, table_id %s ,room_id %s,game_id %s",
				t_guid,t_table_id,t_room_id,self.table_game_id)
		end
	end

	log.info("============finishgameError")
	local notify = {
		chuntian = 0,
		fanchuntian = 0,
		pb_conclude = table.fill({},{
			score = 0,
			bomb_count = 0,
			cards = {},
			flag = self.room_.tax_show_,
			tax = 0,
		} ,1,3)
	}

	self:broadcast2client("SC_LandConclude",notify)
	--  异常牌局
	self.status = TABLE_STATUS.FREE
	self.gamelog.end_game_time = os.time()
	self.gamelog.onlinePlayer = {}
	for i,v in pairs(self.players) do
		-- 保存在线的玩家 并T出游戏
		table.insert(self.gamelog.onlinePlayer, i)
		v:forced_exit()
	end

	log.info(json.encode(self.gamelog))
	self:save_game_log(self.gamelog.table_game_id,self.def_game_name,self.gamelog,self.gamelog.start_game_time,self.gamelog.end_game_time)
	self:clear_ready()
end

function  pdk_table:finishgame(player)
	self.status = TABLE_STATUS.END
	for i,v in ipairs(self.players) do
		local t_guid = v.guid or 0
		local t_room_id = v.room_id or 0
		local t_table_id = v.table_id or 0
		log.info("Player InOut Log,pdk_table:finishgame player %s, table_id %s ,room_id %s,game_id %s",
			t_guid,t_table_id,t_room_id,self.table_game_id)
	end

	-- 游戏结束 进行结算
	self.gamelog.end_game_time = os.time()
	local notify = {
		pb_conclude = {},
		chuntian = 0,
		fanchuntian = 0,
	}
	local bomb_count = 0
	--剩余牌数
	local carNum
	local carNums = 0
	local land_M = {
		chair_id = self.flag_land,
		landMoney = 0,
	}
	local farmer_M = {}


	local offcharid = 0
	local offtimes = os.time()
	log.info("self.room_.tax_show_ [%d]",self.room_.tax_show_)
	for i,v in ipairs(self.players) do
		local c = {}
		carNum = #self.land_player_cards[v.chair_id].cards_
		c.cards = self.land_player_cards[v.chair_id].cards_
		c.bomb_count = self.land_player_cards[v.chair_id]:get_bomb_count()
		c.score = 0
		bomb_count = bomb_count + c.bomb_count
		notify.pb_conclude[v.chair_id] = c

		-- 一个假设判断
		if v.chair_id ~= self.flag_land and carNum == 17 then
			carNums = carNums + 1;
		end
		if v.offtime ~= nil then
			local offlinePlayers = {
				chair_id = v.chair_id,
				offtime = v.offtime,
			}
			table.insert(self.gamelog.offlinePlayers,offlinePlayers)
		end
		self.gamelog.playInfo[v.chair_id] = {
			chair_id = v.chair_id,
			guid = v.guid,
			old_money = v.pb_base_info.money,
			new_money = v.pb_base_info.money,
			tax = 0,
			gameEndStatus = "",
		}
		if v.chair_id == self.flag_land then
			land_M.landMoney = v.pb_base_info.money
			land_M.is_double = v.is_double
		else
			local farmerM = {
				farmerMoney = v.pb_base_info.money,
				chair_id = v.chair_id,
				is_double = v.is_double
			}
			table.insert(farmer_M,farmerM)
		end


		if v.offtime ~= nil then
			if v.offtime < offtimes then
				offcharid = v.chair_id
				offtimes = v.offtime
			end
		end
	end

	if carNums == 2 then
		--有两个人 还剩17张牌
		self.flag_chuntian = true
	end

	local score = self.cur_call_score
	if self.cur_call_score <= 0 then
		score = 1
	end

	if bomb_count > 0 then
		score = score * (2 ^ bomb_count)
	end

	local score_multiple = 0
	local room_cell_score = self.cell_score_
	local land_master_win = true
	if self.status == TABLE_STATUS.PLAYOFFLINE then
		-- 掉线玩家扣分
		land_M = {}
		farmer_M = {}

		for i,v in ipairs(self.players) do
			if v.chair_id == offcharid then
				land_M.landMoney = v.pb_base_info.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.pb_base_info.money,
					chair_id = v.chair_id,
					is_double = v.is_double
				}
				table.insert(farmer_M,farmerM)
			end
		end

		--- 新需求 输赢加上 最大上限 提前算出 值
		local land_score = 0
		land_score = score* room_cell_score

		local m_f1_score = land_score
		local m_f2_score = land_score
		if land_M.is_double then
			m_f1_score = m_f1_score*2
			m_f2_score = m_f2_score*2
		end
		if farmer_M[1].is_double then
			m_f1_score = m_f1_score*2
		end
		if farmer_M[2].is_double then
			m_f2_score = m_f2_score*2
		end
		if m_f1_score > farmer_M[1].farmerMoney then
			m_f1_score = farmer_M[1].farmerMoney
		end
		if m_f2_score > farmer_M[2].farmerMoney then
			m_f2_score = farmer_M[2].farmerMoney
		end

		local f_score_total = m_f1_score+m_f2_score
		if (m_f1_score+m_f2_score) > land_M.landMoney then
			--按比例平分
			m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
			m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
		end

		--扣分
		log.info("offline player chairid is [%d] offtime is [%d]",offcharid,offtimes)

		for i,v in ipairs(self.players) do
			log.info("======== chairid is %d",v.chair_id)
			if self:isDroppedline(v) then
				log.info("this player is offline: %d",v.chair_id)
			end
			local s_type = 1
			local s_old_money = v.pb_base_info.money
			local s_tax = 0
			if v.chair_id == offcharid then
				s_type = 3
				--land_score = farmer_M[1].farmerMoney + farmer_M[2].farmerMoney
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure offline loss"
				notify.pb_conclude[v.chair_id].score = -(m_f1_score + m_f2_score)-- -land_score * 2
				v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = (m_f1_score + m_f2_score)--[[land_score *2]]}}, LOG_MONEY_OPT_TYPE_PDK,true)
				self:save_player_collapse_log(v)
			else
				s_type = 2
				local farmer_score = 0
				if v.chair_id == farmer_M[1].chair_id then
					farmer_score = m_f1_score --farmer_M[1].farmerMoney
				else
					farmer_score = m_f2_score --farmer_M[2].farmerMoney
				end
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure online win"
				notify.pb_conclude[v.chair_id].score = farmer_score
				s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
				-- 收取%5 税收 math.ceil 可能没必要
				notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
				v:add_money({{money_type = enum.ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, enum.LOG_MONEY_OPT_TYPE_PDK)

				self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
			end
			self.gamelog.playInfo[v.chair_id].tax = s_tax
			self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
			log.info("game finish playerid[%d] guid[%d] money [%d]",v.chair_id,v.guid,v.pb_base_info.money)
			self:player_money_log(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
		end
	else
		self.gamelog.win_chair = player.chair_id
		-- 配合客户端 两位小数精确 服务器 用整数下发 客户端 自动除以100
		if self.flag_land == player.chair_id then
			log.info("land win")
			land_master_win = true
			-- 地主赢了
			if self.flag_chuntian then
				score = score * 2
				notify.chuntian = 1
			end
			score_multiple = score
			-- score = score_multiple * room_cell_score
			log.info("score_multiple[%d] room_cell_score[%d]",score_multiple,room_cell_score)

			--- 新需求 输赢加上 最大上限 提前算出 值
			local land_score = 0
			land_score = score_multiple * room_cell_score

			local m_f1_score = land_score
			local m_f2_score = land_score
			if land_M.is_double then
				m_f1_score = m_f1_score*2
				m_f2_score = m_f2_score*2
			end
			if farmer_M[1].is_double then
				m_f1_score = m_f1_score*2
			end
			if farmer_M[2].is_double then
				m_f2_score = m_f2_score*2
			end
			if m_f1_score > farmer_M[1].farmerMoney then
				m_f1_score = farmer_M[1].farmerMoney
			end
			if m_f2_score > farmer_M[2].farmerMoney then
				m_f2_score = farmer_M[2].farmerMoney
			end

			local f_score_total = m_f1_score+m_f2_score
			if (m_f1_score+m_f2_score) > land_M.landMoney then
				--按比例平分
				m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
				m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
			end

			for i,v in ipairs(self.players) do
				local s_type = 1
				local s_old_money = v.pb_base_info.money
				local s_tax = 0
				if self.flag_land == v.chair_id then
					s_type = 2
					if self:isDroppedline(v) and offlinePunishment_flag then
						s_type = 3
						log.info("land win chair_id[%d] but offline",v.chair_id)
						notify.pb_conclude[v.chair_id].score = 0

						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land win but offline"
					else
						notify.pb_conclude[v.chair_id].score = m_f1_score + m_f2_score --farmer_M[1].farmerMoney + farmer_M[2].farmerMoney
						s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
						-- 收取%5 税收 math.ceil 可能没必要
						log.info("ceil befor : %s",tostring(notify.pb_conclude[v.chair_id].score))
						notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
						log.info("ceil after : %s",tostring(notify.pb_conclude[v.chair_id].score))
						v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_PDK)
						log.info("land win add money: %s",tostring(notify.pb_conclude[v.chair_id].score))

						self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land win"
					end
				else
					s_type = 1
					local farmer_score = 0
					if v.chair_id == farmer_M[1].chair_id then
						farmer_score = m_f1_score --farmer_M[1].farmerMoney
					else
						farmer_score = m_f2_score --farmer_M[2].farmerMoney
					end
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer loss"
					if self:isDroppedline(v) and offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer loss and offline"
						s_type = 3
						log.info("farmer is Dropped")
						if score_multiple < FARMER_ESCAPE_SCORE_BASE then
							farmer_score = FARMER_ESCAPE_SCORE_LESS* room_cell_score
						else
							farmer_score = score_multiple * room_cell_score * FARMER_ESCAPE_SCORE_GREATER
						end
						if farmer_score > v.pb_base_info.money then
							farmer_score = v.pb_base_info.money
						end
					end
					notify.pb_conclude[v.chair_id].score = -farmer_score
					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = farmer_score}}, LOG_MONEY_OPT_TYPE_PDK,true)
					self:save_player_collapse_log(v)
					log.info("farmer loss cost money: %s",tostring(notify.pb_conclude[v.chair_id].score))
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
				notify.pb_conclude[v.chair_id].tax = s_tax
				notify.pb_conclude[v.chair_id].flag = self.room_.tax_show_
				log.info("game finish playerid[%d] guid[%d] money [%d] tax[%d]",v.chair_id,v.guid,v.pb_base_info.money,s_tax)
				self:player_money_log(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
			end
		else
			log.info("land loss")
			land_master_win = false
			-- 地主输了
			if self.flag_fanchuntian then
				score = score * 2
				notify.fanchuntian = 1
			end
			score_multiple = score
			--score = score_multiple * room_cell_score
			log.info("score_multiple[%d] room_cell_score[%d]",score_multiple,room_cell_score)

			--- 新需求 输赢加上 最大上限 提前算出 值
			local land_score = 0
			land_score = score_multiple * room_cell_score

			local m_f1_score = land_score
			local m_f2_score = land_score
			if land_M.is_double then
				m_f1_score = m_f1_score*2
				m_f2_score = m_f2_score*2
			end
			if farmer_M[1].is_double then
				m_f1_score = m_f1_score*2
			end
			if farmer_M[2].is_double then
				m_f2_score = m_f2_score*2
			end
			if m_f1_score > farmer_M[1].farmerMoney then
				m_f1_score = farmer_M[1].farmerMoney
			end
			if m_f2_score > farmer_M[2].farmerMoney then
				m_f2_score = farmer_M[2].farmerMoney
			end
			local f_score_total = m_f1_score+m_f2_score
			if (m_f1_score+m_f2_score) > land_M.landMoney then
				--按比例平分
				m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
				m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
			end

			for i,v in ipairs(self.players) do
				local s_type = 1
				local s_old_money = v.pb_base_info.money
				local s_tax = 0
				if self.flag_land == v.chair_id then
					s_type = 1
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss"
					if self:isDroppedline(v) and offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss and offline"
						s_type = 3
						log.info("land is Dropped")
						--如果地主是掉线 果逃跑时的游戏倍数不足 10 倍（指游戏行为的倍数非初始倍数），按照 20 倍分数扣。如果超过 10 倍按照实际的分数的 4 倍扣除。
						if score_multiple < PDK_ESCAPE_SCORE_BASE then
							land_score = PDK_ESCAPE_SCORE_LESS * room_cell_score
						else
							land_score = score_multiple * PDK_ESCAPE_SCORE_GREATER * room_cell_score
						end
						if land_score > land_M.landMoney/2 then
							land_score = land_M.landMoney
						end
					else
						--land_score = farmer_M[1].farmerMoney + farmer_M[2].farmerMoney
						land_score = m_f1_score + m_f2_score
					end
					notify.pb_conclude[v.chair_id].score = -land_score
					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = land_score}}, LOG_MONEY_OPT_TYPE_PDK,true)
					log.info("land loss cost money: %s", tostring(notify.pb_conclude[v.chair_id].score))
					self:save_player_collapse_log(v)
				else
					s_type = 2
					local farmer_score = 0
					if v.chair_id == farmer_M[1].chair_id then
						farmer_score = m_f1_score --farmer_M[1].farmerMoney
					else
						farmer_score = m_f2_score --farmer_M[2].farmerMoney
					end
					if not self:isDroppedline(v) or not offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer win"
						notify.pb_conclude[v.chair_id].score = farmer_score
						s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
						-- 收取%5 税收 math.ceil 可能没必要
						log.info("ceil befor :%s",tostring(notify.pb_conclude[v.chair_id].score))
						notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
						log.info("ceil after :%s",tostring(notify.pb_conclude[v.chair_id].score))
						v:add_money({{money_type = enum.ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, enum.LOG_MONEY_OPT_TYPE_PDK)
						self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
					else
						s_type = 3
						log.info("chair_id[%d] win but offline",v.chair_id)
						notify.pb_conclude[v.chair_id].score = 0
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer win but offline"
					end
					log.info("farmer win add money: %d",notify.pb_conclude[v.chair_id].score)
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
				log.info("game finish playerid[%d] guid[%d] money[%d] tax[%d]",v.chair_id,v.guid,v.pb_base_info.money,s_tax)
				self:player_money_log(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
				notify.pb_conclude[v.chair_id].tax = s_tax
				notify.pb_conclude[v.chair_id].flag = self.room_.tax_show_
			end
		end
	end

	for i,v in ipairs(self.players) do
		if v.is_double then
			self.gamelog.playInfo[v.chair_id].is_double = 1
		else
			self.gamelog.playInfo[v.chair_id].is_double = 0
		end
		--不是机器人才记录对手
		if not v.is_android then
			v.friend_list = {}
			if land_master_win then
				if v.chair_id == self.flag_land then
					for ct,pt in ipairs(self.players) do
						--不记录机器人
						if ct ~= v.flag_land and not pt.is_android then
							table.insert( v.friend_list, pt.guid )
						end
					end
				end
			else
				if v.chair_id ~= self.flag_land then
					for ct,pt in ipairs(self.players) do
						--不记录机器人
						if ct ~= v.chair_id and ct ~= v.flag_land and not pt.is_android then
							table.insert( v.friend_list, pt.guid )
						end
					end
				end
			end
		end
	end
	self.gamelog.cell_score = self.cell_score_
	self.gamelog.finishgameInfo = notify
	local s_log = json.encode(self.gamelog)
	log.info(s_log)
	self:save_game_log(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	-- end
	log.info("game end")
	log.info("chuntian [%d] ,fanchuntian [%d]",notify.chuntian,notify.fanchuntian)
	for _,var in ipairs(notify.pb_conclude) do
		log.info("score [%d] ,bomb_count [%d], cards[%s]",var.score,var.bomb_count,table.concat( var.cards, ", "))
	end

	self:broadcast2client("SC_PdkGameOver", notify)

	-- 踢人
	self.status = TABLE_STATUS.FREE
	self:foreach(function(v)
		v:forced_exit()
	end)
	
	log.info("game init")
	self:clear_ready()
end

function pdk_table:clear_ready( ... )
	base_table.clear_ready(self)
	log.info("set TABLE_STATUS.FREE")
	self.status = TABLE_STATUS.FREE
	self.time0_ = os.time()
	self.landcards = nil
	self.last_cards = nil
	self.Already_Out_Cards = {}
	self.bomb = 0
	self.callsore_time = 0
	self.table_game_id = 0
	self.good_cards_flag = 0 --该局是否做好牌的标志，默认0,1做好牌
	self.three_cards = {} --存储底牌
	self.this_good_cards = {} --存储好牌
	self.all_player_cards = {} --存储3个玩家的17张牌
	self.gamelog = {
		CallPoints = {},
		landid = 0,
		pdk_cards = "",
		table_game_id = 0,
		start_game_time = 0,
		end_game_time = 0,
		win_chair = 0,
		outcard_process = {},
		finishgameInfo = {},
		playInfo = {},
		offlinePlayers = {},
		cell_score = 0,
    	}
    	self.playWithAndroid_isopen = false
end

function pdk_table:can_enter(player)
	log.info("pdk_table:can_enter ===============")
	if not player then
		log.info ("player no data")
		return false
	end

	log.info ("player have data")

	if self.status ~= TABLE_STATUS.FREE then
		log.info("pdk_table:can_enter already playing.")
		return false
	end

	log.info("===============================================pdk_table:can_enter true")
	return true
end

--做差牌，第一个17张是差牌
function pdk_table:shuffle_cheat_cards()
	local bad_cards = {}
	self.new_cards = {}
	for i = 1, 54 do
		self.new_cards[i] = i - 1
	end
	--4,5,6随机一个空位
	local iLackValue1 = math.random(1,3) + 1
	--log.info("iLackValue1-------->",iLackValue1)
	--7,8,9随机一个空位
	local iLackValue2 = math.random(1,3) + 4
	--log.info("iLackValue2-------->",iLackValue2)
	local iBadCardsCount = 1
	local arrSmallCardStat = {}
	for i=0,3 do
		arrSmallCardStat[i] = {}
		for j=0,7 do
			arrSmallCardStat[i][j] = 1
		end
	end

	while (iBadCardsCount < 13) do
		local iColor = math.random(0,3)
		--log.info("iColor-------->",iColor)
		local iValueIndex = math.random(0,7)
		--log.info("iValueIndex-------->",iValueIndex)
		if arrSmallCardStat[iColor][iValueIndex] == 1 and iValueIndex ~= iLackValue1 and iValueIndex ~= iLackValue2 then
			if arrSmallCardStat[0][iValueIndex] + arrSmallCardStat[1][iValueIndex] + arrSmallCardStat[2][iValueIndex] + arrSmallCardStat[3][iValueIndex] > 1 then
				arrSmallCardStat[iColor][iValueIndex] = 0
				bad_cards[iBadCardsCount] = getIntPart(iValueIndex * 4 + iColor)
				self.new_cards[iValueIndex * 4 + iColor + 1] = -1
				iBadCardsCount = iBadCardsCount + 1
				--log.info("%d is  iValueIndex[%d] iColor[%d]" , iBadCardsCount - 1 , iValueIndex , iColor))
			end
		end
	end

	--10以上的选5张
	--50概率给一张2或小王
	local coeff_value = math.random(1,100)
	if coeff_value < 25 then --抽小王
		bad_cards[iBadCardsCount] = 52 --小王
		iBadCardsCount = iBadCardsCount + 1
		self.new_cards[52 + 1] = -1
	elseif coeff_value < 50 then--抽2
		local iSelectedColor = math.random(0,3)
		bad_cards[iBadCardsCount] = getIntPart(48 + iSelectedColor)
		iBadCardsCount = iBadCardsCount + 1
		self.new_cards[48 + iSelectedColor + 1] = -1
	end

	--剩余的分给JQKA，JQ可以给0-3张，KA可以0-2张
	local arrBigCardStat = {}
	for i=0,3 do
		arrBigCardStat[i] = {}
		for j=0,3 do
			arrBigCardStat[i][j] = 1
		end
	end

	local arrBigCardCanUse = {
		[0] = 3,
		[1] = 3,
		[2] = 2,
		[3] = 2,
	}

	local arrBigCardRealValue = {
		[0] = 32,
		[1] = 36,
		[2] = 40,
		[3] = 44,
	}
	while (iBadCardsCount < 18) do
		local iColor = math.random(0,3)
		local iValueIndex = math.random(0,3)

		if arrBigCardStat[iColor][iValueIndex] == 1 then
			if arrBigCardStat[0][iValueIndex] + arrBigCardStat[1][iValueIndex] + arrBigCardStat[2][iValueIndex] + arrBigCardStat[3][iValueIndex] > 4 - arrBigCardCanUse[iValueIndex] then
				arrBigCardStat[iColor][iValueIndex] = 0
				bad_cards[iBadCardsCount] = getIntPart(arrBigCardRealValue[iValueIndex] + iColor)
				iBadCardsCount = iBadCardsCount + 1
				self.new_cards[arrBigCardRealValue[iValueIndex] + iColor + 1] = -1
			end
		end
	end
	table.sort(bad_cards, function(a, b) return a < b end)
	local left_cards = {}
	for _,z in ipairs(self.new_cards) do
		if z and z ~= -1 then
			local value = tonumber(z)
			table.insert(left_cards,value)
		end
	end
	table.sort(left_cards, function(a, b) return a < b end)

	local ilen = #left_cards
	--混乱剩余扑克
	for i = 1, 18 do
		local x = math.random(ilen)
		local y = math.random(ilen)
		if x ~= y then
			left_cards[x], left_cards[y] = left_cards[y], left_cards[x]
		end
	end

	self.new_cards = {}
	for i=1,table.nums(bad_cards) do
		local value = getIntPart(bad_cards[i])
		table.insert(self.new_cards, value)
	end
	for i=1,table.nums(left_cards) do
		table.insert(self.new_cards, left_cards[i])
	end

	if self:check_cards_type(self.new_cards) == true then
		return true
	else
		return false
	end
end

--校验牌库牌型是否错误
function pdk_table:check_cards_type(all_cards)
	if not all_cards then
		--log.error("------------------------->all_cards is nil")
		return false
	end

	local cards_count = table.nums(all_cards)
	if cards_count ~= 54 then
		--log.error(string.format("all_cards count error,curCards total[%d]", cards_count))
		return false
	end

	local cards = {}
	for _,z in ipairs(all_cards) do
		if z then
			table.insert(cards,z)
		end
	end
	table.sort(cards, function(a, b) return a < b end)
	--校验牌是否有重复的牌和牌型
	local cards_voctor = {}
	for i,v in ipairs(cards) do
		local value_key = i - 1
		if v < 0 or v > 53 then
			log.error(table.concat(cards, ','))
			--log.error(string.format("cards value error [%d]",v))
			return false
		end
		if value_key ~= v then
			--log.error(string.format("~~~~~~~~~~~~index = [%d]",v))
			log.info(table.concat(cards, ','))
			return false
		end

		if not cards_voctor[v] then
			cards_voctor[v] = 1
		else
			log.error(table.concat(cards, ','))
			--log.error(string.format("repeat cards error----------->[%d]",v))
			return false
		end
	end

	return true
end

return pdk_table