-- 斗地主逻辑
local pb = require "pb_files"

local base_table = require "game.lobby.base_table"
require "data.land_data"
require "game.net_func"
local send2client_pb = send2client_pb
local random = require "random"
require "game.land.land_cards"
local land_cards = land_cards
local json = require "cjson"
local log = require "log"
require "aiopt"
local ai_AiPlayCard = ai_AiPlayCard
local ai_AiPlayCardPassive = ai_AiPlayCardPassive
local ai_GrabLandlord = ai_GrabLandlord
local ai_GrabLandlord2 = ai_GrabLandlord2

require "game.lobby.game_android"
local game_android = game_android

require "timer"
local add_timer = add_timer

local redisopt = require "redisopt"

local reddb = redisopt.default

local offlinePunishment_flag = false

local LOG_MONEY_OPT_TYPE_LAND = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local LAND_CARD_TYPE_SINGLE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE")
local LAND_CARD_TYPE_DOUBLE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE")
local LAND_CARD_TYPE_THREE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE")
local LAND_CARD_TYPE_SINGLE_LINE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE_LINE")
local LAND_CARD_TYPE_DOUBLE_LINE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE_LINE")
local LAND_CARD_TYPE_THREE_LINE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_LINE")
local LAND_CARD_TYPE_THREE_TAKE_ONE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_ONE")
local LAND_CARD_TYPE_THREE_TAKE_TWO = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_TWO")
local LAND_CARD_TYPE_FOUR_TAKE_ONE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_ONE")
local LAND_CARD_TYPE_FOUR_TAKE_TWO = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_TWO")
local LAND_CARD_TYPE_BOMB = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB")
local LAND_CARD_TYPE_MISSILE = pb.enum("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE")

-- 斗地主人数
local LAND_PLAYER_COUNT = 3

-- 开始游戏倒记时
local LAND_TIME_START_COUNTDOWN = 3
-- 出牌时间
local LAND_TIME_OUT_CARD = 15
-- 叫分时间
local LAND_TIME_CALL_SCORE = 15
-- 首出时间
local LAND_TIME_HEAD_OUT_CARD = 15
-- 玩家掉线等待时间
local LAND_TIME_WAIT_OFFLINE = 30
-- ip限制等待时间
local LAND_TIME_IP_CONTROL = 20
-- ip限制开启人数
local LAND_IP_CONTROL_NUM = 20

-- 等待开始
local LAND_STATUS_FREE = 1
-- 开始倒记时
local LAND_STATUS_START_COUNT_DOWN = 2
-- 叫分状态
local LAND_STATUS_CALL = 3
-- 游戏进行
local LAND_STATUS_PLAY = 4
-- 玩家掉线
local LAND_STATUS_PLAYOFFLINE = 5
-- 加倍阶段
local LAND_STATUS_DOUBLE = 6
-- 结束阶段
local LAND_STATUS_END = 7

--地主掉线基础倍数
local LAND_ESCAPE_SCORE_BASE = 10
--地主掉线低于基础倍数后的扣分倍数
local LAND_ESCAPE_SCORE_LESS = 10
--地主掉线高于基础倍数后的扣分 乘以倍数
local LAND_ESCAPE_SCORE_GREATER = 2
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
local LAND_TIME_OVER = 1000

--差牌概率
local system_bad_card_coeff = 60

local land_table = base_table:new()

-- 初始化
function land_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.broad_money = 10000
	self.callsore_time = 0
	self.status = LAND_STATUS_FREE
	self.land_player_cards = {}
	for i = 1, chair_count do
		self.land_player_cards[i] = land_cards:new()
	end

	self.cards = {}
	for i = 1, 54 do
		self.cards[i] = i - 1
	end
	self:clear_ready()
	--self.GameLimitCdTime = self.room_.roomConfig.GameLimitCdTime
	self.GameLimitCdTime = 6
	--好牌总计副数(151)
	self.good_cards_total = #good_cards_array
	--print("self.GameLimitCdTime ....",self.GameLimitCdTime)
	reddb:del(string.format("player:%s_%d_%d",def_game_name,def_first_game_type,def_second_game_type))

	self.playWithAndroid = {}
	self.playWithAndroid_isopen = false
	self.ai_start_time1 = 0
	self.ai_start_time2 = 0
	self.new_cards = {}
	
	self.system_bad_card_coeff = system_bad_card_coeff
	self.BASIC_COEFF = BASIC_COEFF
	self.FLOAT_COEFF = FLOAT_COEFF
	
	--[[
	for k=1,10 do
		local numCount = 0
		for i=1,100000 do
			if self:shuffle_cheat_cards() == true then
				numCount = numCount + 1
			end
		end
		print("numCount---------------------------->",numCount)
		if numCount == 100000 then
			log.info("shuffle_cheat_cards--------------->all is ok")
		end
	end
	--]]
end

-- 检查是否可准备
function land_table:check_ready(player)
	if self.status ~= LAND_STATUS_FREE then
		return false
	end
	return true
end
--玩家站起离开房间
function land_table:player_stand_up(player, is_offline)
	--print(debug.traceback())
	log.info(" player_stand_uptable id[%d] guid[%s]",self.table_id_,tostring(player.guid))
	local ret = base_table.player_stand_up(self,player, is_offline)
	if ret then
		if self.status == LAND_STATUS_START_COUNT_DOWN then
			log.info(" ================ play start count down clean ==================table id[%d]",self.table_id_)
			self.status = LAND_STATUS_FREE
		end
	end
	return ret
end
-- 检查是否可取消准备
function land_table:check_cancel_ready(player, is_offline)
	log.info("check_cancel_ready guid [%d] status [%d] is_offline[%s]",player.guid and player.guid or 0,self.status,tostring(is_offline))
	base_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if self.status ~= LAND_STATUS_FREE and self.status ~= LAND_STATUS_START_COUNT_DOWN then  -- 游戏状态判断 只有游戏在未开始时才可以取消
		if is_offline then
			--掉线处理
			self:player_offline(player)
		end
		return false
	end
	--退出
	return true
end

-- 洗牌
function land_table:shuffle()
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	for i = 1, 27 do
		local x = random.boost(54)
		local y = random.boost(54)
		if x ~= y then
			self.cards[x], self.cards[y] = self.cards[y], self.cards[x]
		end
	end
	self.valid_card_idx = random.boost(51)
end

function dump(obj)
    local getIndent, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "" .. val .. ""
        elseif type(val) == "string" then
            return '"' .. val .. '"'
        else
            return "" .. tostring(val) .. ""
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return '"' .. val .. '"'
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    --return dumpObj(obj, 0)
    print(dumpObj(obj, 0))
end

function land_table:load_lua_cfg()
    log.warning("land_table:load_lua_cfg : [%s] ",self.room_.room_cfg)
    local land_config = json.decode(self.room_.room_cfg)
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

        if land_config.broad_money then
            log.info("broad_money : [%s]" , land_config.broad_money)
            self.broad_money = land_config.broad_money
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
        print("land_config is nil")
    end
end

--校验牌库牌型是否错误
function land_table:test_cards_type()
	local cards = {}
	for i=1,self.good_cards_total do
		cards = {}
		for i,v in ipairs(good_cards_array[i]) do
			for _,z in ipairs(v) do
				table.insert(cards,z)
			end
		end
		table.sort(cards, function(a, b) return a < b end)
		log.info(table.concat(cards, ','))
		for j=1,54 do
			local value_key = j - 1
			if value_key ~= cards[j] then
				log.error("~~~~~~~~~~~~index = [%d]",i)
				log.info(table.concat(cards, ','))
				return
			end
		end
	end
end

--校验抽出来的牌型
function land_table:check_this_good_cards(cards)
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
function land_table:handle_good_cards()
	local this_one_good_cards  = {}
	if self.good_cards_total ~= 0 then
		local good_cards_index = random.boost_integer(1,self.good_cards_total) --随机选一首好牌
		print("~~~~~~~~~good_cards_index:",good_cards_index)
		for i,v in ipairs(good_cards_array[good_cards_index]) do
			this_one_good_cards[i] = {}
			for _,z in ipairs(v) do
				table.insert(this_one_good_cards[i],z)
			end
		end
	end
	return this_one_good_cards
end

-- 开始游戏
function land_table:start()
	log.info(" ================ play start count down ==================table id[%d]",self.table_id_)
	self.status = LAND_STATUS_START_COUNT_DOWN
	self.time0_ = get_second_time()
end

function land_table:get_next_index(chair_id)
	chair_id = chair_id + 1
	if chair_id > 3 then
		chair_id = 1
	end
	return chair_id
end

function land_table:do_ai_grab_landlord(chair_id)
	log.info("ai_grab_landlord table_id[%d] chairid[%d]",self.table_id_,chair_id)
	local player = self.players[chair_id]

	--按大小分为15种牌，传递每张牌的数量
	local ai_cards1 = self.land_player_cards[1]:convert_ai_cards()
	local ai_cards2 = self.land_player_cards[2]:convert_ai_cards()
	local ai_cards3 = self.land_player_cards[3]:convert_ai_cards()

	local cards_temp = {ai_cards1,ai_cards2,ai_cards3}

	local land_left_cards = self:get_land_cards()
	local left_cards = {}
	for i,v in ipairs(land_left_cards) do
		table.insert(left_cards,land_cards.convert_gameCard_aiCard(v))
	end

	local landAiPlayCard = {
		pb_pai_list1 = {},
		pb_pai_list2 = {},
		pb_pai_list3 = {},
		landlord = 0,
		pb_grab_pai = {cards = left_cards},
	}

	--先叫分的在前面
	local cards_index_ = chair_id
	landAiPlayCard.pb_pai_list1.cards = cards_temp[cards_index_]

	cards_index_ = self:get_next_index(cards_index_)
	landAiPlayCard.pb_pai_list2.cards = cards_temp[cards_index_]

	cards_index_ = self:get_next_index(cards_index_)
	landAiPlayCard.pb_pai_list3.cards = cards_temp[cards_index_]


	local stringbuffer = pb.encode("S_LandAiGrabLandlord", landAiPlayCard)
	ai_GrabLandlord(stringbuffer, function(reply)
		local score = tonumber(reply)
		log.info("ai_grab_landlord table_id[%d] score[%d]",self.table_id_,score)

		if score <= self.cur_call_score then
			--小于别人叫的分数就不叫
			self:call_score(player, 0)
		else
			self:call_score(player, score)
		end

	end)
end

--机器人叫分
function land_table:ai_grab_landlord(chair_id,callscore_time_)
	local callscore_time = 1
	if callscore_time_ then
		callscore_time = callscore_time_
	else
		callscore_time = math.random(2,5)
	end
	add_timer(callscore_time, function()
		self:do_ai_grab_landlord(chair_id)
	end)
end

--机器人叫分2（这个接口会实时运算一下，返回一个抢地主能否打赢的0-100概率值，现在只运算10次？）
function land_table:ai_grab_landlord2()
	local landAiPlayCard = {
		pb_pai_list1 = {cards = {0,0,1,1,1,1,1,1,1,1,2,1,0,0,0}},
		pb_pai_list2 = {cards = {2,2,2,0,2,0,2,2,0,0,0,0,0,0,0}},
		pb_pai_list3 = {cards = {0,1,0,1,0,0,0,0,3,0,0,0,2,0,0}},
		pb_grab_pai = {cards = {0,1,0}},
	}
	local stringbuffer = pb.encode("S_LandAiGrabLandlord2", landAiPlayCard)
	ai_GrabLandlord2(stringbuffer, function(reply)
		local score = tonumber(reply)
		log.info("ai_grab_landlord2 score[%d]",score)
	end)
end


function land_table:do_ai_play_card(chair_id)
	local player = self.players[chair_id]

	local ai_cards1 = self.land_player_cards[1]:convert_ai_cards()
	local ai_cards2 = self.land_player_cards[2]:convert_ai_cards()
	local ai_cards3 = self.land_player_cards[3]:convert_ai_cards()

	local cards_temp = {ai_cards1,ai_cards2,ai_cards3}

	--其中要出牌的玩家，放在第一个位置，后面二个玩家按出牌顺序放置
	local landAiPlayCard = {
		pb_pai_list1 = {},
		pb_pai_list2 = {},
		pb_pai_list3 = {},
		landlord = 0,
	}

	local out_card_order = {}
	local cards_index_ = chair_id
	landAiPlayCard.pb_pai_list1.cards = cards_temp[cards_index_]
	table.insert(out_card_order,cards_index_)

	cards_index_ = self:get_next_index(cards_index_)
	landAiPlayCard.pb_pai_list2.cards = cards_temp[cards_index_]
	table.insert(out_card_order,cards_index_)

	cards_index_ = self:get_next_index(cards_index_)
	landAiPlayCard.pb_pai_list3.cards = cards_temp[cards_index_]
	table.insert(out_card_order,cards_index_)

	for i,chair_id_ in ipairs(out_card_order) do
		if chair_id_ == self.flag_land then
			landAiPlayCard.landlord = i - 1
			break
		end
	end

	--玩家剩下的牌(根据ai出牌，从里面去找牌，因为ai不分花色)
	local player_cards = self.land_player_cards[chair_id].cards_


	local stringbuffer = pb.encode("S_LandAiPlayCard", landAiPlayCard)
	ai_AiPlayCard(stringbuffer, function(reply)
		local landAiPaiMove = pb.decode("LandAiPaiMove", reply)
		--log.error("ai_play_card type[%d] alone_1[%d] alone_2[%d] alone_3[%d] alone_4[%d] pb_combo_list[%s]",landAiPaiMove.type,landAiPaiMove.alone_1,landAiPaiMove.alone_2,landAiPaiMove.alone_3,landAiPaiMove.alone_4,table.concat(landAiPaiMove.pb_combo_list.cards, ","))
		local newCards =  land_cards.convert_aicards_cards(landAiPaiMove,player_cards)
		if #newCards == 0 then
			log.error("ai_play_card #cards==0")
		else
			self:out_card(player, newCards)
		end

		local ai_time = get_second_time() - self.ai_start_time1
		if ai_time > 14 then
			log.error("do_ai_play_card table [%d] time [%d]",self.table_id_,ai_time)
		end

	end)
end

--机器人主动出牌
function land_table:ai_play_card(chair_id)
	local play_card_time = math.random(2,4)

	--剩余一张牌的时候思考时间缩短至1秒
	local player_cards = self.land_player_cards[chair_id].cards_
	if #player_cards == 1 then
		play_card_time = 1
	end

	self.ai_start_time1 = get_second_time()

	add_timer(play_card_time, function()
		self:do_ai_play_card(chair_id)
	end)
end

function land_table:do_ai_play_card_passive(chair_id)
	local player = self.players[chair_id]

	local ai_cards1 = self.land_player_cards[1]:convert_ai_cards()
	local ai_cards2 = self.land_player_cards[2]:convert_ai_cards()
	local ai_cards3 = self.land_player_cards[3]:convert_ai_cards()

	local cards_temp = {ai_cards1,ai_cards2,ai_cards3}

	--上一个玩家出的牌:self.last_out_cards是分析后的牌，self.last_cards是原始牌列表
	local pb_pai_move_ =  land_cards.convert_cards_aicards(self.last_out_cards,self.last_cards)

	local landAiPlayCardPassive = {
		pb_pai_list1 = {},
		pb_pai_list2 = {},
		pb_pai_list3 = {},
		landlord = 0,
		outPaiIndex = 0,
		pb_pai_move = pb_pai_move_,
	}

	local out_card_order = {}
	local cards_index_ = chair_id
	landAiPlayCardPassive.pb_pai_list1.cards = cards_temp[cards_index_]
	table.insert(out_card_order,cards_index_)

	cards_index_ = self:get_next_index(cards_index_)
	landAiPlayCardPassive.pb_pai_list2.cards = cards_temp[cards_index_]
	table.insert(out_card_order,cards_index_)

	cards_index_ = self:get_next_index(cards_index_)
	landAiPlayCardPassive.pb_pai_list3.cards = cards_temp[cards_index_]
	table.insert(out_card_order,cards_index_)

	for i,chair_id_ in ipairs(out_card_order) do
		--地主的位置
		if chair_id_ == self.flag_land then
			landAiPlayCardPassive.landlord = i - 1
		end
		--最后出牌人的位置
		if chair_id_ == self.last_out_cards_chair_id then
			landAiPlayCardPassive.outPaiIndex = i - 1
		end
	end


	--玩家剩下的牌(根据ai出牌，从里面去找牌，因为ai不分花色)
	local player_cards = self.land_player_cards[chair_id].cards_

	local stringbuffer = pb.encode("S_LandAiPlayCardPassive", landAiPlayCardPassive)

	ai_AiPlayCardPassive(stringbuffer, function(reply)
		local landAiPaiMove = pb.decode("LandAiPaiMove", reply)
		--log.error("ai_play_card_passive type[%d] alone_1[%d] alone_2[%d] alone_3[%d] alone_4[%d] pb_combo_list[%s]",landAiPaiMove.type,landAiPaiMove.alone_1,landAiPaiMove.alone_2,landAiPaiMove.alone_3,landAiPaiMove.alone_4,table.concat(landAiPaiMove.pb_combo_list.cards, ","))
		local newCards =  land_cards.convert_aicards_cards(landAiPaiMove,player_cards)
		if #newCards == 0 then
			self:pass_card(player)
		else
			self:out_card(player, newCards)
		end

		local ai_time = get_second_time() - self.ai_start_time2
		if ai_time > 14 then
			log.error("do_ai_play_card_passive table [%d] time [%d]",self.table_id_,ai_time)
		end

	end)
end

--机器人被动出牌
function land_table:ai_play_card_passive(chair_id)
	local play_card_time = math.random(2,4)

	--剩余一张牌的时候思考时间缩短至1秒
	local player_cards = self.land_player_cards[chair_id].cards_
	if #player_cards == 1 then
		play_card_time = 1
	end

	self.ai_start_time2 = get_second_time()

	add_timer(play_card_time, function()
		self:do_ai_play_card_passive(chair_id)
	end)
end


function land_table:statrGameBegin( ... )
	-- body
	if base_table.start(self) == nil then
		log.info("cant Start Game ====================================================")
		self:clear_ready()
		return
	end
	self.gamelog.start_game_time = get_second_time()
	self:shuffle()
	self.bad_card_make_flag = 0 --做差牌标记，成功标记为1
	--做差牌接口(满足概率和必须是开启了机器人的情况下再做差牌)
	local bad_card_coeff = random.boost_integer(1,100)
    log.info("table_id [%d] playWithAndroid_isopen [%s] bad_card_coeff [%s]", self.table_id_ , tostring(self.playWithAndroid_isopen) , tostring(bad_card_coeff) , tostring(self.system_bad_card_coeff))
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
	local good_cards_coeff = random.boost_integer(0,SYSTEM_COEFF)
	if self.FLOAT_COEFF == nil then
		self.FLOAT_COEFF = 2
	end
	local float_coeff = random.boost_integer(0,self.FLOAT_COEFF)
	local this_time_coeff = self.BASIC_COEFF + float_coeff
	if self.bad_card_make_flag == 0 and good_cards_coeff <  this_time_coeff then --满足概率，随机做1副好牌
		self.good_cards_flag = 1
		--log.info("~~~~~please send good cards............")
	else
		--log.info("~~~~~please send normal cards............")
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
			--log.info("last_three_cards[%d] [%d] [%d]",self.three_cards[1][1],self.three_cards[1][2],self.three_cards[1][3])

			for i=1,3 do
				table.insert(self.all_player_cards,self.this_good_cards[i])
				--log.info(table.concat(self.all_player_cards[i], ',')
			end
			--记录最大的牌,保证拿最大的牌的人第一个叫地主
			max_card = self.all_player_cards[1][1]
			--随机打乱三首牌顺序
			local len = #self.all_player_cards
			for i=1,len do
				local x = random.boost_integer(1,len)
				local y = random.boost_integer(1,len)
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
		start_time = get_second_time(),
		first_turn = self.first_turn,
		player_cards = {},
		callpoints_process = {},
		--land_card = string.format("%d %d %d",self.cards[52], self.cards[53], self.cards[54]),
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
				--log.info("v.chair_id: [%d]" ,v.chair_id)
				--log.info(table.concat(msg.cards, ',')

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
					--log.info("v.chair_id: [%d]" ,v.chair_id)
					--log.info(table.concat(msg.cards, ',')

					----------- 日志相关
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



	log.info("first call soure chairid : %s ", tostring(self.first_turn))
	self.cur_turn = self.first_turn
	self.cur_call_score = 0
	self.cur_call_score_chair_id = 0
	self.status = LAND_STATUS_CALL

	--add new 通知客服端叫分
	local notify = {
		cur_chair_id = self.cur_turn,
		call_chair_id = cur_chair_id,
		call_score = 0,
		}
	self:broadcast2client("SC_LandCallScore", notify)
	self.time0_ = get_second_time() + 4

	--机器人叫分
	if self.players[self.cur_turn].is_android then
		self:ai_grab_landlord(self.cur_turn,10)
	end
end


--获取地主最后拿的3张牌
function land_table:get_land_cards()
	local cards_ = {}
	if self.good_cards_flag == 1 then
		cards_ = {self.three_cards[1][1],self.three_cards[1][2],self.three_cards[1][3]}
	else
		cards_ = {self.cards[52], self.cards[53], self.cards[54]}
	end
	return cards_
end

-- 发地主底牌
function land_table:send_land_cards(player)
	self:start_save_info()

	log.info("==========send_land_cards: [%s]" ,tostring(self.cur_call_score_chair_id))

	for i=1,3 do
		local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
		log.info(str)
		redis_command(str)
	end

	self.flag_land = self.cur_call_score_chair_id
	self.flag_chuntian = true
	self.flag_fanchuntian = true
	self.time_outcard_ = LAND_TIME_HEAD_OUT_CARD
	self.cur_turn = self.cur_call_score_chair_id

	--
	local cards_ = self:get_land_cards()
	--local cards_ = {self.cards[52], self.cards[53], self.cards[54]}

	self.landcards = cards_
	log.info("landcards [%s]",table.concat(cards_,","))
	log.info("befor landplayercards [%s]",table.concat(self.land_player_cards[self.cur_call_score_chair_id].cards_,","))
	self.land_player_cards[self.cur_call_score_chair_id]:add_cards(cards_)
	self.land_player_cards[self.cur_call_score_chair_id]:sort()
	log.info("after number [%d] landplayercards [%s]",#self.land_player_cards[self.cur_call_score_chair_id].cards_,table.concat(self.land_player_cards[self.cur_call_score_chair_id].cards_,","))

	self.last_out_cards = nil
	self.last_out_cards_chair_id = 0
	self.Already_Out_Cards = {}
	local msg = {
		land_chair_id = self.first_turn,
		call_score = self.cur_call_score,
		cards = cards_,
		}
	self:broadcast2client("SC_LandInfo", msg)

	-- f需求 修改 取消 加倍时间
	-- self.status = LAND_STATUS_DOUBLE
	self:status_double_finish()
	self.time0_ = get_second_time()
	for i,v in ipairs(self.players) do
		if v and v.chair_id == self.first_turn then
			v.is_double = false
			break
		end

	end

end
function land_table:status_double_finish()
	self.status = LAND_STATUS_PLAY
	self.time0_ = curtime

	local msg = {
		land_chair_id = self.first_turn
		}
	self:broadcast2client("SC_LandCallDoubleFinish", msg)

	--游戏开始
	self:startGame()
end
-- 加倍
function land_table:call_double(player,is_double)
	if true then
		return
	end
	if self.status ~= LAND_STATUS_DOUBLE or self.first_turn == player.chair_id then
		return --地主不能加倍
	end
	log.info("call_double begin ---- %s",tostring(is_double))
	player.is_double = is_double --is_double and true or false
	local notify = {
		call_chair_id = player.chair_id,
		is_double = 1
	}
	if is_double then notify.is_double = 2 end
	self:broadcast2client("SC_LandCallDouble", notify) -- SC_LandCallScorePlayerOffline
	log.info("SC_LandCallDouble call_double end ---- ")
	local all_is_done = true
	for i,v in ipairs(self.players) do
		if v and v.is_double == nil then
			all_is_done = false
			break
		end
	end
	if all_is_done then self:status_double_finish()	end
end

function land_table:startGame( ... )
	-- body
	-- 获取 牌局id
	log.info("gamestart =================================================")
	self.table_game_id = self:get_now_game_id()
	log.info("table_game_id is %s",self.table_game_id)
	self:next_game()

	log.info("get_now_game_id is %s",tostring(self:get_now_game_id()))
	-- 获取开始时间
	self.time0_ = get_second_time()
	self.start_time = self.time0_
	self:Next_Player_Proc()
	-- 记录日志
	table.insert(self.gamelog.CallPoints,self.callpoints_log)
	self.gamelog.landid = self.flag_land
	self.gamelog.land_cards = string.format("%s",table.concat(self.land_player_cards[self.flag_land].cards_,","))
	self.gamelog.table_game_id = self.table_game_id
	self.gamelog.start_game_time = self.time0_

	for i,v in ipairs(self.players) do
		if v then
			v.LastTrusteeship = false
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log.info(string.format("Player InOut Log,land_table:startGame player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),self.table_game_id))
		end
	end
end

function land_table:set_LandLastTrusteeship(player,msg)
	-- body
	if msg then
		if msg.isTrusteeship == nil then
			msg.isTrusteeship = false
		end
	else
		log.info("msg is nil")
		msg = { isTrusteeship = false }
	end
	log.info("player guid [%d] set LastTrusteeship [%s]" , player.guid , tostring(msg.isTrusteeship))

	if #self.land_player_cards[player.chair_id].cards_  == 1 then
		if msg.isTrusteeship then
			player.LastTrusteeship = true
			if self.cur_turn == player.chair_id then
				self:trusteeship(player)
			end
		else
			player.LastTrusteeship = false
		end
	else
		player.LastTrusteeship = false
	end

	local msgT = {
		chair_id = player.chair_id,
		LastTrusteeship = player.LastTrusteeship,
	}

	log.info("player guid [%d] player.LastTrusteeship [%s]" , player.guid , tostring(player.LastTrusteeship))
	send2client_pb(player,"SC_LandLastTrusteeship", msgT)
end

function land_table:set_trusteeship(player,flag)
	-- body
	player.TrusteeshipTimes = 0
	player.isTrusteeship = not player.isTrusteeship
	log.info("chair_id:"..player.chair_id)
	if player.isTrusteeship then
		log.info("**************:true")
		if self.cur_turn == player.chair_id then
			self:trusteeship(player)
		end
		if flag == true then
			player.finishOutGame = true
		end
	else
		log.info("**************:false")
		player.finishOutGame = false
	end
	local msg = {
		chair_id = player.chair_id,
		isTrusteeship = player.isTrusteeship,
		}
	self:broadcast2client("SC_LandTrusteeship", msg)
end
-- 叫分
function land_table:call_score(player, callscore)
	log.info("==========call_score status[%d]",self.status)
	if self.status ~= LAND_STATUS_CALL then
		log.warning("land_table:call_score guid[%d] status error", player.guid)
		return
	end

	if player.chair_id ~= self.cur_turn then
		log.warning("land_table:call_score guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn)
		return
	end

	if callscore < 0 or callscore > 3 then
		log.error("land_table:call_score guid[%d] score[%d] error", player.guid, callscore)
		return
	end

	if callscore > 0 and callscore <= self.cur_call_score then
		log.error("land_table:call_score guid[%d] score[%d] error, cur[%d]", player.guid, callscore, self.cur_call_score)
		return
	end
	-- 记录叫分 日志
	local call_log = {
		chair_id = player.chair_id,
		callscore = callscore,
		calltimes = self.callsore_time + 1,
	}
	table.insert(self.callpoints_log.callpoints_process,call_log)


	log.info("callscore is : %s",tostring(callscore))
	if callscore == 3 then
		local notify = {
			cur_chair_id = self.cur_turn,
			call_chair_id = player.chair_id,
			call_score = callscore,
			}
		self:broadcast2client("SC_LandCallScore", notify)

		self.cur_call_score = callscore
		self.cur_call_score_chair_id = self.cur_turn
		self.first_turn = self.cur_turn
		self:send_land_cards(player)
		return
	end

	if callscore == 0 then
		--do nothing
	end
	if callscore > 0 then
		self.cur_call_score_chair_id = self.cur_turn
		self.cur_call_score = callscore
	end

	if self.cur_turn == 3 then
		self.cur_turn = 1
	else
		self.cur_turn = self.cur_turn + 1
	end
	local notify = {
		cur_chair_id = self.cur_turn,
		call_chair_id = player.chair_id,
		call_score = callscore,
		}
	self:broadcast2client("SC_LandCallScore", notify)

	--又回到第一个人了
	if self.first_turn == self.cur_turn then
		if self.cur_call_score > 0 then
			self.first_turn = self.cur_call_score_chair_id
			self:send_land_cards(player)
		else
			self.callsore_time = self.callsore_time + 1
			if self.callsore_time < 3 then
				self:broadcast2client("SC_LandCallFail")
				-- 重新洗牌 记录叫分日志
				table.insert(self.gamelog.CallPoints,self.callpoints_log)
				self:statrGameBegin()
			else
				self.cur_call_score_chair_id = self.first_turn
				self.cur_call_score = 1
				self:send_land_cards(player)
			end
			return
		end
	end
	self.time0_ = get_second_time()
	self:Next_Player_Proc()
end

-- 出牌
function land_table:out_card(player, cardslist, flag)
	--log.info("player: %d" , player.chair_id)
	log.info(table.concat(cardslist,","))
	if self.status ~= LAND_STATUS_PLAY then
		log.warning("land_table:out_card guid[%d] status error", player.guid)
		return
	end

	if player.chair_id ~= self.cur_turn then
		log.warning("land_table:out_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn)
		return
	end

	local playercards = self.land_player_cards[player.chair_id]
	if not playercards:check_cards(cardslist) then
		log.error("land_table:out_card guid[%d] out cards[%s] error, has[%s]", player.guid, table.concat(cardslist, ','), table.concat(playercards.cards_, ','))
		return
	end

	-- 排序
	-- if #cardslist > 1 then
	-- 	table.sort(cardslist, function(a, b) return a < b end)
	-- end

	local cardstype, cardsval = playercards:get_cards_type_new(cardslist)
	log.info("gameid[%s] cardstype[%s] cardsval[%s]" , tostring(self.table_game_id) , tostring(cardstype) , tostring(cardsval) )
	if not cardstype then
		log.error("land_table:out_card guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cardslist, ','))
		return
	end
	--if cardstype == LAND_CARD_TYPE_SINGLE and cardslist[1] == 53 then
	--	cardsval = 14
	--end
	local cur_out_cards = {cards_type = cardstype, cards_count = #cardslist, cards_val = cardsval}
	if not playercards:compare_cards(cur_out_cards, self.last_out_cards) then
		log.error(string.format("land_table:out_card guid[%d] compare_cards error, cards[%s], cur_out_cards[%d,%d,%d], last_out_cards[%d,%d,%d]", player.guid, table.concat(cardslist, ','),
			cur_out_cards.cards_type , cur_out_cards.cards_count, cur_out_cards.cards_val,self.last_out_cards.cards_type,self.last_out_cards.cards_count,self.last_out_cards.cards_val))
		return
	end

	if not flag or flag == false then
		player.TrusteeshipTimes = 0
	end

	-- 记录日志
	local outcard = {
		chair_id = player.chair_id,
		outcards = string.format("%s",table.concat(cardslist, ',')),
		sparecards = "",
		time = get_second_time(),
		isTrusteeship = player.isTrusteeship and 1 or 0,
	}

	self.last_out_cards = cur_out_cards
	self.last_cards = cardslist
	self.last_out_cards_chair_id = player.chair_id
	table.insert(self.Already_Out_Cards,cardslist)
	if self.flag_fanchuntian == true and self.cur_turn == self.flag_land and #self.land_player_cards[self.cur_turn].cards_ < 20 then
		self.flag_fanchuntian = false
	end

	if self.cur_turn ~= self.flag_land and self.flag_chuntian then
		self.flag_chuntian = false
	-- elseif self.time_outcard_ == LAND_TIME_OUT_CARD then
	-- 	self.flag_fanchuntian = false
	end
	if self.flag_chuntian == false and self.cur_turn == self.flag_land then
		-- 如果 春天没有的情况下 地主出牌 则 反春天不成立 另外 结算时 没有农民玩家牌数达到17也没有反春天
		self.flag_fanchuntian = false
	end
	self.time_outcard_ = LAND_TIME_OUT_CARD
	if cardstype == LAND_CARD_TYPE_MISSILE or cardstype == LAND_CARD_TYPE_BOMB then
		playercards:add_bomb_count()
		self.bomb = self.bomb + 1
	end

	self.first_turn = self.cur_turn
--	if cardstype ~= LAND_CARD_TYPE_MISSILE then
		if self.cur_turn == 3 then
			self.cur_turn = 1
		else
			self.cur_turn = self.cur_turn + 1
		end
--	else
--		self.last_out_cards = nil
--	end

	local notify = {
		cur_chair_id = self.cur_turn,
		out_chair_id = player.chair_id,
		cards = cardslist,
		turn_over = (cardstype == LAND_CARD_TYPE_MISSILE and 1 or 0),
		}
	self:broadcast2client("SC_LandOutCard", notify)
	log.info("outcard ==========================   chair_id [%d] cards[%s]", player.chair_id, table.concat(cardslist, ','))
	player.outTime = 0
	self.time0_ = get_second_time()

	local outCardFlag = not playercards:out_cards(cardslist)
	-- 记录剩下的牌
	outcard.sparecards = string.format("%s",table.concat(playercards.cards_, ','))
	table.insert(self.gamelog.outcard_process,outcard)

	if outCardFlag then
		self:finishgame(player)
	else
		self:Next_Player_Proc()
	end
end

-- 放弃出牌
function land_table:pass_card(player, flag)
	if self.status ~= LAND_STATUS_PLAY then
		log.warning("land_table:pass_card guid[%d] status error", player.guid)
		return
	end

	if player.chair_id ~= self.cur_turn then
		log.warning("land_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn)
		return
	end

	if not self.last_out_cards then
		log.error("land_table:pass_card guid[%d] first turn", player.guid)
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
		time = get_second_time(),
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
		self.last_out_cards = nil
	end
	-- self.time0_ = get_second_time()
	local notify = {
		cur_chair_id = self.cur_turn,
		pass_chair_id = player.chair_id,
		turn_over = is_turn_over,
		}
	log.info("cur_chair_id[%d],pass_chair_id[%d]",notify.cur_chair_id,notify.pass_chair_id)
	self:broadcast2client("SC_LandPassCard", notify)
	self:Next_Player_Proc()
end
function land_table:Next_Player_Proc( ... )
	-- body
	if  self.status == LAND_STATUS_CALL then
		if not self.players[self.cur_turn] then
			log.error("not find player gameTableid [%s]",self.table_game_id)
			self:finishgameError()
		elseif self.players[self.cur_turn].Dropped or self.players[self.cur_turn].isTrusteeship then
			-- self:call_score(self.players[self.cur_turn], 0)
			self.time0_ = get_second_time() - LAND_TIME_CALL_SCORE + 1
		elseif self.players[self.cur_turn].is_android then
			--机器人叫分
			self:ai_grab_landlord(self.cur_turn)
		end
	elseif self.status == LAND_STATUS_PLAY then
		--log.info("========================================Next_Player_Proc")
		if self.players[self.cur_turn].Dropped or self.players[self.cur_turn].isTrusteeship or self.players[self.cur_turn].LastTrusteeship then
			log.info("========================================Trusteeship123")
			self.time0_ = get_second_time() - self.time_outcard_ + 1
		elseif self.players[self.cur_turn].is_android then
			self.time0_ = get_second_time()
			if self.last_out_cards then
				--机器人被动出牌
				self:ai_play_card_passive(self.cur_turn)
			else
				--机器人主动出牌
				self:ai_play_card(self.cur_turn)
			end

		else
			self.time0_ = get_second_time()
		end
	end
end
--玩家上线处理
function  land_table:reconnect(player)
	-- body
	-- 新需求 玩家掉线不暂停游戏 只是托管
end
function  land_table:is_play( ... )
	log.info("land_table:is_play : [%s]",tostring(self.status))
	-- body
	if self.status ~= LAND_STATUS_FREE and self.status ~= LAND_STATUS_END and self.status ~= LAND_STATUS_START_COUNT_DOWN then
		log.info("is_play  return true")
		return true
	end
	return false
end
--请求玩家数据
function land_table:reconnect(player)
	-- body
	log.info("player online : %s " , tostring(player.chair_id))
	base_table.reconnect(self,player)
	local notify = {
			room_id = player.room_id,
			table_id = player.table_id,
			chair_id = player.chair_id,
			result = GAME_SERVER_RESULT_SUCCESS,
			ip_area = player.ip_area,
		}
	self:foreach_except(player.chair_id, function (p)
		local v = {
			chair_id = p.chair_id,
			guid = p.guid,
			account = p.account,
			nickname = p.nickname,
			level = p:get_level(),
			money = p:get_money(),
			header_icon = p:get_header_icon(),
			ip_area = p.ip_area,
		}
		notify.pb_visual_info = notify.pb_visual_info or {}
		table.insert(notify.pb_visual_info, v)
	end)

	send2client_pb(player, "SC_PlayerReconnection", notify)
	self:recoveryplayercard(player)

	--发送加倍情况
	local notify_double = {
		pb_double_state = {},
		double_count_down = 0
	}

	if self.status == LAND_STATUS_DOUBLE and player.is_double == nil then
		local curtime = get_second_time()
		notify_double.double_count_down = LAND_TIME_CALL_SCORE + self.time0_ - curtime
		log.info("-------------------------------cool down------------------------------------")
	end

	for i,v in ipairs(self.players) do
		if v then
			local m = {
				chair_id = v.chair_id,
				is_double = 1
			}
			if v.is_double then
				m.is_double = 2
			elseif v.is_double == nil then
				m.is_double = 3
			end
			table.insert(notify_double.pb_double_state,m)
		end
	end

	send2client_pb(player, "SC_LandRecoveryPlayerDouble", notify_double)

	local notify = {
		cur_online_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
	}
	self:broadcast2client("SC_LandPlayerOnline", notify)
	player.isTrusteeship = true
	self:set_trusteeship(player,false)
end

function  land_table:inList(player)
	-- body
	local channellist = self.playWithAndroid.list_channelid
	if channellist then
		for _,v in pairs(channellist) do
			log.info("v [%s] player.channel_id [%s]" , v , player.channel_id)
			if v == player.channel_id then
				return true
			end
		end
	end
	return false
end

function  land_table:isAndroidWithPlay(player)				-- self.playWithAndroid.status 0 关 1 全开 2 按渠道开 3 按渠道关
	-- body
	log.info("self.playWithAndroid [%s] self.playWithAndroid.status[%s] self.playWithAndroid.status [%d]", tostring(self.playWithAndroid) , tostring(self.playWithAndroid.status) , self.playWithAndroid.status)
	if self.playWithAndroid and self.playWithAndroid.status and self.playWithAndroid.status > 0 then
		if self.playWithAndroid.status == 1 then
			return true
		elseif self.playWithAndroid.status == 2 and self:inList(player) then
			return true
		elseif self.playWithAndroid.status == 3 and not self:inList(player) then
			return true
		end
	end
	return false
end

function  land_table:canAddAndroid(player)
	-- body
	log.info("player.is_android[%s] self:get_player_count() [%d] elf:isAndroidWithPlay(player) [%s]", tostring(not player.is_android) ,self:get_player_count() , tostring(self:isAndroidWithPlay(player)))
	if not player.is_android and self:get_player_count() == 1 and self:isAndroidWithPlay(player) then
		return true
	end
	return false
end

function land_table:player_sit_down(player, chair_id_)
	-- body
	base_table.player_sit_down(self,player, chair_id_)
	self:ready(player)

	--添加机器人
	if self:canAddAndroid(player) then
		log.info("add_android ============================================== [%d]",player.guid)
        if not player.is_android then
            self.playWithAndroid_isopen = true
        end
		self:add_android(chair_id_)
	else
        if not player.is_android then
            self.playWithAndroid_isopen = false
        end
		log.info("can not add_android ==============================================")
	end
end

--添加机器人
function land_table:add_android(except_chair)
	local guid = -10 * self.table_id_
	for i=1,3 do
		if i ~= except_chair then
			guid = guid - 1
			local android_player = game_android:new()
			local account  =  "android_"..tostring(guid)
			local nickname =  "android_"..tostring(guid)
			android_player:init(self.room_.id, guid, account, nickname)
			android_player:think_on_sit_down(self.room_.id, self.table_id_, i)
		end
	end
end

--获取机器人数量
function land_table:get_android_count()
	local android_count = 0
	local player_index = 0
	for i,v in ipairs(self.players) do
		if v then
			if v.is_android then
				android_count = android_count + 1
			else
				player_index = i
			end
		end
	end
	return android_count,player_index
end

function land_table:ready(player)

	log.info("land_table:ready ======= :%s guid[%s]",tostring(player.table_id),tostring(player.guid))
	if self:is_play() then
		log.info("land_table: is play  can not ready ======= tableid: %s",tostring(player.table_id))
		return
	end
	--[[
	for _,v in ipairs(self.players) do
		if v and v.guid ~= player.guid then
			log.info("===========judge_play_times")
			local LimtCDTime = 0
			if self.GameLimitCdTime then
				log.info("============self.room_.GameLimitCdTime:"..self.GameLimitCdTime)
				LimtCDTime = self.GameLimitCdTime
			end
			if player:judge_play_times(v,LimtCDTime) then
				log.info("tableid [%d] ready judge_play_times is true playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid)
			else
				-- 再判断
				if v:judge_play_times(player,LimtCDTime) then
					log.info("tableid [%d] ready judge_play_times is true playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid)
				else
					log.info("tableid [%d] ready judge_play_times is false playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid)
					player.ipControlTime = get_second_time()
		            log.info("===============land_table tick")
		            self.room_.room_manager_:change_table(player)
		            local tab = self.room_:find_table(player.table_id)
		            tab:ready(player)
					return
				end
			end
		end
	end
	]]
	if not self:can_enter(player) then
		self.room_.room_manager_:change_table(player)
		local tab = self.room_:find_table(player.table_id)
		--tab:ready(player)
		return
	end

	base_table.ready(self,player)
	player.offtime = nil
	player.isTrusteeship = false
	player.finishOutGame = false
end

function  land_table:GetCards( player, msg )
    -- body
    local notify = {
            cards = self.land_player_cards[player.chair_id].cards_,
        }
    send2client_pb(player, "SC_LandGetCards", notify)
end

--恢复玩家当前数据
function  land_table:recoveryplayercard(player)
	-- 游戏进行时发牌
	if self.status == LAND_STATUS_PLAY or self.status == LAND_STATUS_DOUBLE then
		local notify = {
			cur_chair_id = player.chair_id,
			cards = self.land_player_cards[player.chair_id].cards_,
			pb_msg = {},
			landchairid = self.flag_land,
			landcards = self.landcards,
			call_score = self.cur_call_score,
			lastCards  = self.last_cards,
			lastcardid = self.first_turn,
			outcardid  = self.cur_turn,
			alreadyoutcards = self.Already_Out_Cards,
			bomb = self.bomb,
		}
		for i,v in ipairs(self.players) do
			if v.chair_id ~= player.chair_id then
				local m = {
					chair_id = v.chair_id,
					cardsnum = #self.land_player_cards[v.chair_id].cards_,
					isTrusteeship = v.isTrusteeship,
				}
				table.insert(notify.pb_msg,m)
			end
		end

		log.info("chairid[%d] cards[%s]",player.chair_id,table.concat( self.land_player_cards[player.chair_id].cards_, ", "))
		log.info("---------SC_LandRecoveryPlayerCard-----------")
		send2client_pb(player, "SC_LandRecoveryPlayerCard", notify)
	elseif self.status == LAND_STATUS_PLAYOFFLINE or self.status == LAND_STATUS_CALL then
		local notify = {
			cur_chair_id = self.cur_turn,
			call_chair_id = self.cur_call_score_chair_id,
			call_score = self.cur_call_score,
			cards = self.land_player_cards[player.chair_id].cards_,
			pb_playerOfflineMsg = {}
		}
		player.offtime = nil
		local waitT = 0
		for i,v in ipairs(self.players) do
			if v then
				if v.offtime then
					local pptime = get_second_time() - v.offtime
					if pptime >= LAND_TIME_WAIT_OFFLINE then
						pptime = 0
					else
						pptime = LAND_TIME_WAIT_OFFLINE - pptime
					end
					local xxnotify = {
						chair_id = v.chair_id,
						outTimes = pptime,
					}
					table.insert(notify.pb_playerOfflineMsg, xxnotify)
					if v.offtime then
						if v.offtime > waitT then
							waitT = v.offtime
						end
					end
				end
			end
		end
		send2client_pb(player, "SC_LandRecoveryPlayerCallScore", notify)
		if waitT == 0 then
			self.time0_ = get_second_time()
			self.status = LAND_STATUS_CALL
		else
			self.time0_ = waitT
		end
	end
end
--玩家掉线处理
function  land_table:player_offline( player )
	log.info("land_table:player_offline")
	base_table.player_offline(self,player)
	log.info("player offline : guid[%d] chairid[%s]",player.guid,player.chair_id)
	-- body
	if self.status == LAND_STATUS_FREE then
		-- 等待开始时 掉线则强制退出玩家
		player:forced_exit()
	--elseif self.status == LAND_STATUS_CALL then
	--	-- 叫分状态时 掉线则所有玩家待
	--	--发送掉线消息
	--	local notify = {
	--		cur_chair_id = player.chair_id,
	--		wait_time = LAND_TIME_WAIT_OFFLINE,
	--	}
	--	self:broadcast2client("SC_LandCallScorePlayerOffline", notify)
	--	--设置状态为等待
	--	player.offtime = get_second_time()
	--	log.info("set LAND_STATUS_PLAYOFFLINE")
	--	self.status = LAND_STATUS_PLAYOFFLINE
	--	self.time0_ = get_second_time()
	elseif self.status == LAND_STATUS_PLAY or self.status == LAND_STATUS_CALL or self.status == LAND_STATUS_DOUBLE then
		-- 游戏进行时 则暂停游戏
		-- 新需求更新为 不再暂停游戏 托管玩家
		player.isTrusteeship = false
		self:set_trusteeship(player,true)
	elseif self.status == LAND_STATUS_PLAYOFFLINE then
		-- 叫分状态时 掉线则所有玩家待
		--发送掉线消息
		local notify = {
			cur_chair_id = player.chair_id,
			wait_time = LAND_TIME_WAIT_OFFLINE,
		}
		self:broadcast2client("SC_LandCallScorePlayerOffline", notify)
		--设置状态为等待
		player.offtime = get_second_time()
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

function land_table:finishgameError()
	self.status = LAND_STATUS_END
	for i=1,3 do
		local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
		log.info(str)
		redis_command(str)
	end
	for i,v in ipairs(self.players) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log.info(string.format("Player InOut Log,land_table:finishgameError player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),tostring(self.table_game_id)))
		end
	end

	log.info("============finishgameError")
	local notify = {
		pb_conclude = {},
		chuntian = 0,
		fanchuntian = 0,
	}
	for i=1,3 do
		c = {}
		c.score = 0
		c.bomb_count = 0
		c.cards = {}
		c.flag = self.room_.tax_show_
		c.tax = 0
		notify.pb_conclude[i] = c
	end
	self:broadcast2client("SC_LandConclude",notify)
	-- body 异常牌局
	self.status = LAND_STATUS_FREE
	self.gamelog.end_game_time = get_second_time()
	self.gamelog.onlinePlayer = {}
	for i,v in pairs(self.players) do
		if v then -- 保存在线的玩家 并T出游戏
			table.insert(self.gamelog.onlinePlayer, i)
			v:forced_exit()
		end
	end

	local s_log = json.encode(self.gamelog)
	log.info(s_log)
	self:save_game_log(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	self:clear_ready()
end

function  land_table:finishgame(player)
	self.status = LAND_STATUS_END
	for i=1,3 do
		local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
		log.info(str)
		redis_command(str)
	end
	for i,v in ipairs(self.players) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log.info(string.format("Player InOut Log,land_table:finishgame player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),tostring(self.table_game_id)))
		end
	end

	-- body
	-- 游戏结束 进行结算
	self.gamelog.end_game_time = get_second_time()
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
	local offtimes = get_second_time()
	log.info("self.room_.tax_show_ [%d]",self.room_.tax_show_)
	for i,v in ipairs(self.players) do
		if v then
			local c = {}
			carNum = 0
			carNum = #self.land_player_cards[v.chair_id].cards_
			c.cards = self.land_player_cards[v.chair_id].cards_
			c.bomb_count = self.land_player_cards[v.chair_id]:get_bomb_count()
			c.score = 0
			bomb_count = bomb_count + c.bomb_count
			if #c.cards == 0 then
				--c.cards = {99}
			end
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
				old_money = v.money,
				new_money = v.money,
				tax = 0,
				gameEndStatus = "",
			}
			if v.chair_id == self.flag_land then
				land_M.landMoney = v.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.money,
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
		else
			log.error("========players [%d] is nil or false",i)
		end
	end

	if carNums == 2 then
		--有两个人 还剩17张牌
		self.flag_chuntian = true
	end

	--local score = self.room_.cell_score_*(self.cur_call_score + 1)
	local score = self.cur_call_score
	if self.cur_call_score <= 0 then
		score = 1
	end
	if bomb_count > 0 then
		score = score * (2^bomb_count)
	end
	local score_multiple = 0
	local room_cell_score = self.cell_score_
	local land_master_win = true
	if self.status == LAND_STATUS_PLAYOFFLINE then
		-- 掉线玩家扣分


		land_M = {}
		farmer_M = {}

		for i,v in ipairs(self.players) do
			if v.chair_id == offcharid then
				land_M.landMoney = v.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.money,
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

		--[[
		--- 比较地主身上的钱 得出 最多收益
		if land_score > land_M.landMoney/2 then
			land_score = land_M.landMoney/2
		end

		if farmer_M[1].farmerMoney > land_score then
			farmer_M[1].farmerMoney = land_score
		end
		if farmer_M[2].farmerMoney > land_score then
			farmer_M[2].farmerMoney = land_score
		end
		]]

		--扣分

		log.info("offline player chairid is [%d] offtime is [%d]",offcharid,offtimes)
--		self.table_game_id = self:get_now_game_id()
--		self.gamelog.table_game_id = self.table_game_id
--		self:next_game()

		for i,v in ipairs(self.players) do
			log.info("======== chairid is %d",v.chair_id)
			if self:isDroppedline(v) then
				log.info("this player is offline: %d",v.chair_id)
			end
			local s_type = 1
			local s_old_money = v.money
			local s_tax = 0
			if v.chair_id == offcharid then
				s_type = 3
				--land_score = farmer_M[1].farmerMoney + farmer_M[2].farmerMoney
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure offline loss"
				notify.pb_conclude[v.chair_id].score = -(m_f1_score + m_f2_score)-- -land_score * 2
				v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = (m_f1_score + m_f2_score)--[[land_score *2]]}}, LOG_MONEY_OPT_TYPE_LAND,true)
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
				v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_LAND)

				self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
			end
			self.gamelog.playInfo[v.chair_id].tax = s_tax
			self.gamelog.playInfo[v.chair_id].new_money = v.money
			log.info("game finish playerid[%d] guid[%d] money [%d]",v.chair_id,v.guid,v.money)
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

			--[[
			--- 比较地主身上的钱 得出 最多收益
			if land_score > land_M.landMoney/2 then
				land_score = land_M.landMoney/2
			end

			if farmer_M[1].farmerMoney > land_score then
				farmer_M[1].farmerMoney = land_score
			end
			if farmer_M[2].farmerMoney > land_score then
				farmer_M[2].farmerMoney = land_score
			end
			]]

			for i,v in ipairs(self.players) do
				local s_type = 1
				local s_old_money = v.money
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
						v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_LAND)
						log.info("land win add money: %s",tostring(notify.pb_conclude[v.chair_id].score))

						self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land win"
						if notify.pb_conclude[v.chair_id].score > self.broad_money then
							broadcast_world_marquee(def_first_game_type,def_second_game_type,0,v.nickname,notify.pb_conclude[v.chair_id].score/100)
						end
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
						if farmer_score > v.money then
							farmer_score = v.money
						end
					end
					notify.pb_conclude[v.chair_id].score = -farmer_score
					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = farmer_score}}, LOG_MONEY_OPT_TYPE_LAND,true)
					self:save_player_collapse_log(v)
					log.info("farmer loss cost money: %s",tostring(notify.pb_conclude[v.chair_id].score))
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.money
				notify.pb_conclude[v.chair_id].tax = s_tax
				notify.pb_conclude[v.chair_id].flag = self.room_.tax_show_
				log.info("game finish playerid[%d] guid[%d] money [%d] tax[%d]",v.chair_id,v.guid,v.money,s_tax)
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
			--[[--- 比较地主身上的钱 得出 最多收益
			if land_score > land_M.landMoney/2 then
				land_score = land_M.landMoney/2
			end

			if farmer_M[1].farmerMoney > land_score then
				farmer_M[1].farmerMoney = land_score
			end
			if farmer_M[2].farmerMoney > land_score then
				farmer_M[2].farmerMoney = land_score
			end
			]]

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
				local s_old_money = v.money
				local s_tax = 0
				if self.flag_land == v.chair_id then
					s_type = 1
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss"
					if self:isDroppedline(v) and offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss and offline"
						s_type = 3
						log.info("land is Dropped")
						--如果地主是掉线 果逃跑时的游戏倍数不足 10 倍（指游戏行为的倍数非初始倍数），按照 20 倍分数扣。如果超过 10 倍按照实际的分数的 4 倍扣除。
						if score_multiple < LAND_ESCAPE_SCORE_BASE then
							land_score = LAND_ESCAPE_SCORE_LESS * room_cell_score
						else
							land_score = score_multiple * LAND_ESCAPE_SCORE_GREATER * room_cell_score
						end
						if land_score > land_M.landMoney/2 then
							land_score = land_M.landMoney
						end
					else
						--land_score = farmer_M[1].farmerMoney + farmer_M[2].farmerMoney
						land_score = m_f1_score + m_f2_score
					end
					notify.pb_conclude[v.chair_id].score = -land_score
					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = land_score}}, LOG_MONEY_OPT_TYPE_LAND,true)
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
						v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_LAND)
						self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)


						if notify.pb_conclude[v.chair_id].score > self.broad_money then
							broadcast_world_marquee(def_first_game_type,def_second_game_type,0,v.nickname, notify.pb_conclude[v.chair_id].score/100)
						end
					else
						s_type = 3
						log.info("chair_id[%d] win but offline",v.chair_id)
						notify.pb_conclude[v.chair_id].score = 0
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer win but offline"
					end
					log.info("farmer win add money: %d",notify.pb_conclude[v.chair_id].score)
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.money
				log.info("game finish playerid[%d] guid[%d] money[%d] tax[%d]",v.chair_id,v.guid,v.money,s_tax)
				self:player_money_log(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
				notify.pb_conclude[v.chair_id].tax = s_tax
				notify.pb_conclude[v.chair_id].flag = self.room_.tax_show_
			end
		end
	end

	for i,v in ipairs(self.players) do
		if v then
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

	self:broadcast2client("SC_LandConclude", notify)

	-- 踢人
	self.status = LAND_STATUS_FREE
	for i,v in pairs(self.players) do
		if v then
			v:forced_exit()
		end
	end
	--local room_limit = self.room_:get_room_limit()
	--for i,v in ipairs(self.players) do
	--	if v then
	--		if  self:isDroppedline(v) or (v.isTrusteeship and v.finishOutGame) then
	--			log.info("chair_id [%d] is offline forced_exit~! guid is [%d]" , v.chair_id, v.guid)
	--			if self:isDroppedline(v) or v.isTrusteeship then
	--				log.info("====================1")
	--				v.isTrusteeship = false
	--				v.finishOutGame = false
	--			end
	--			v:forced_exit()
	--			--if self:isDroppedline(v) then
	--			--		log.info("====================2")
	--			--	if not player.online then
	--			--		log.info("====================3")
	--			--	end
	--			--	if player.droped then
	--			--		log.info("====================4")
	--			--	end
	--			--	logout(v.guid)
	--			--end
	--		else
	--			v.isTrusteeship = false
	--			v:check_forced_exit(room_limit)
	--		end
	--		v.ipControlTime = get_second_time()
	--	else
	--		log.info("v is nil: %d",i)
	--	end
	--end

--[[	local iRet = base_table.check_game_maintain(self)--检查游戏是否维护
	if iRet == true then
		print("Game land  card will maintain......")
	end--]]
	log.info("game init")
	self:clear_ready()
end
function  land_table:isDroppedline(player)
	-- body
	if player then
		player.ipControlTime = get_second_time()
		if player.chair_id then
			log.info("land_table:isDroppedline:guid[%d] table[%d] chair[%d]",player.guid,player.table_id,player.chair_id)
		end
		return not player.online or player.droped
	end
	return false
end
function land_table:clear_ready( ... )
	-- body
	base_table.clear_ready(self)
	log.info("set LAND_STATUS_FREE")
	self.status = LAND_STATUS_FREE
	self.time0_ = get_second_time()
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
        land_cards = "",
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

-- 得到牌大小
local function get_value(card)
	if card == 53 then
		return math.floor(card / 4) + 1
	else
		return math.floor(card / 4)
	end
end

-- 托管
function land_table:trusteeship(player)
	-- body
	if player then
		if self.status == LAND_STATUS_PLAY then
			if self.last_out_cards and player.chair_id ~= self.first_turn then
				if player.LastTrusteeship and #self.last_cards == 1 then
					local playercards = self.land_player_cards[player.chair_id]
					if get_value(self.last_cards[1]) < get_value(playercards.cards_[1]) then
						self:out_card(player, {playercards.cards_[1]} , true)
					else
						self:pass_card(player,true)
					end
				else
					log.info("time out call pass")
					self:pass_card(player,true)
				end
			else
				log.info("time out call out card")
				local playercards = self.land_player_cards[self.cur_turn]
				self:out_card(player, {playercards.cards_[1]} , true)
			end
		elseif self.status == LAND_STATUS_CALL then
			self:call_score(player, 0)
		elseif self.status == LAND_STATUS_DOUBLE then
			if player.is_double == nil then
				self:call_double(player,false)
			end
		end
	end
end
function land_table:can_enter(player)
	log.info("land_table:can_enter ===============")
	--if true then
	--	return true
	--end
	if player then
		log.info ("player have data")
	else
		log.info ("player no data")
		return false
	end

	if player.vip ~= 100 then
		-- body
		if self.status ~= LAND_STATUS_FREE then
			log.info("land_table:can_enter false")
			return false
		end
		for _,v in ipairs(self.players) do
			if v and v.guid ~= player.guid then
				if player:judge_ip(v) then
					log.info("land_table:can_enter false ip limit")
					return false
				end

				player.friend_list = player.friend_list or {}
				for k1,v1 in pairs(player.friend_list) do
					if v.guid == v1 then
						log.info("land_table:can_enter false friend limit")
						return false
					end
				end

				v.friend_list = v.friend_list or {}
				for k1,v1 in pairs(v.friend_list) do
					if player.guid == v1 then
						log.info("land_table:can_enter false friend limit")
						return false
					end
				end
			end
		end
	end
	if not player.is_android and self:get_player_count() > 0 then
		-- 已经有人了 判断玩家是否需要和机器人一起玩
		if self:isAndroidWithPlay(player) then
			if self:get_player_count() == 1 and self:intable(player) then 			-- 准备时也会调用，这时候 玩家已经在桌子中了
				log.info("===============================================land_table:can_enter true")
				return true
			end
			log.info("===============================================land_table:can_enter false [%d] " ,player.guid)
			return false
		end
	end
	log.info("===============================================land_table:can_enter true")
	return true
	--[[
	for _,v in ipairs(self.players) do
		if v and v.guid ~= player.guid then
			log.info("===========judge_play_times")
			local LimtCDTime = 0
			if self.GameLimitCdTime then
				log.info("============self.room_.GameLimitCdTime:"..self.GameLimitCdTime)
				LimtCDTime = self.GameLimitCdTime
			end
			if player:judge_play_times(v,LimtCDTime) then
				log.info("tableid[%d] judge_play_times is true playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid)
				v.ipControlTime = get_second_time()
			else
				-- 再判断
				if v:judge_play_times(player,LimtCDTime)	then
					log.info("tableid[%d] judge_play_times is true playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid)
					v.ipControlTime = get_second_time()
				else
					log.info("tableid[%d] judge_play_times is false playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid)
					return false
				end
			end
			log.info(self.room_.cur_player_count_)
			log.info(LAND_IP_CONTROL_NUM)
			player.ipControlTime = get_second_time()
			if player:judge_ip(v) then
				if not player.ipControlflag then
					log.info("land_table:can_enter ipcontorl change false")
					return false
				else
					-- 执行一次后 重置
					player.ipControlflag = false
					log.info("land_table:can_enter ipcontorl change true")
					return true
				end
			end
		end
	end
	log.info("land_table:can_enter true")
	return true
	]]
end
function  land_table:intable(player)
	-- body
	for k,v in pairs(self.players) do
		if v and v.guid == player.guid then
			return true
		end
	end
	return false
end

function  aaaaaaaaaa( ... )
	log.info "aaaaaaaaaa .........................."

end
aTemp = 1
-- 心跳
function land_table:tick()
	--if self.status == LAND_STATUS_FREE  and (aTemp == 1 or self.tempT) then
	--	local curtime = get_second_time()
	--	if not self.tempT then
	--		self.tempT = get_second_time()
	--		aTemp = 2
	--	else
	--		if curtime - self.tempT > 10 then
	--			aaaaaaaaaa()
	--			self.tempT = get_second_time()
	--		end
	--	end
	--end
	if self.status == LAND_STATUS_FREE then
		if get_second_time() - self.time0_ > 2 then
			self.time0_ = get_second_time()
			local curtime = self.time0_
			local maintainFlg = 0
			for _,v in ipairs(self.players) do
				if v then
					v.ipControlTime = v.ipControlTime or get_second_time()
					local t = v.ipControlTime
					--维护时将准备阶段正在匹配的玩家踢出
					--[[local iRet = base_table:on_notify_ready_player_maintain(v)--检查游戏是否维护
					if iRet == true then
						maintainFlg = 1
					end--]]
					if t then
						if curtime -  t >= LAND_TIME_IP_CONTROL then
							v.ipControlTime = get_second_time()
							if self:isDroppedline(v) then
								--掉线了就T掉
								if self:isDroppedline(v) or v.isTrusteeship then
									log.info("====================1")
									v.isTrusteeship = false
									v.finishOutGame = false
								end
								v:forced_exit()
							else
								log.info("tableid is %s",tostring(v.table_id))
								v.ipControlflag = true
								log.info("===============land_table tick")
								--[[]]
								if self.ready_list_[v.chair_id] then
									log.info("guid[%d] tableid [%d] chairid [%d] chair is ready",v.guid,self.table_id_,v.chair_id)
								else
									log.info("guid[%d] tableid [%d] chairid [%d] chair is not ready",v.guid,self.table_id_,v.chair_id)
								end
								log.info("player[%d] readyPlayer[%d]",self:get_player_count() ,#self.ready_list_)
								if self:get_player_count() == 1 and self.ready_list_[v.chair_id] then
									self.room_.room_manager_:change_table(v)
									local tab = self.room_:find_table(v.table_id)
									--tab:ready(v)
								end
							end
						end
					end
				end
			end
	--[[		if maintainFlg == 1 then
				print("############Game ready player land  card will maintain.")
			end	--]]
		end
	elseif self.status == LAND_STATUS_START_COUNT_DOWN then
		local curtime = get_second_time()
		if curtime - self.time0_ > LAND_TIME_START_COUNTDOWN then
			self:statrGameBegin()
		end
	elseif self.status == LAND_STATUS_PLAY then
		local curtime = get_second_time()
		if curtime == nil then
			log.info("curtime is nil")
		end
		if self.time0_ == nil then
			log.info("self.time0_ is nil")
		end
		if self.time_outcard_ == nil then
			log.info("self.time_outcard_ is nil")
		end
		if curtime - self.time0_ >= self.time_outcard_ then
			-- 超时
			log.info("time0[%d],time[%d],out[%d],cur_turn[%d]",self.time0_,curtime,self.time_outcard_,self.cur_turn)
			local player = self.players[self.cur_turn]
			if player and player.chair_id then
				log.info("time out : %d" ,player.chair_id)
				if not player.TrusteeshipTimes then
					player.TrusteeshipTimes = 0
				end
				player.TrusteeshipTimes = player.TrusteeshipTimes + 1
				log.info("player.is_android [%s] player.TrusteeshipTimes [%d] player.isTrusteeship[%s] player.LastTrusteeship[%s]",tostring(player.is_android),player.TrusteeshipTimes,tostring(player.isTrusteeship),tostring(player.LastTrusteeship))
				if not player.is_android and player.TrusteeshipTimes >= 1 and not player.isTrusteeship and not player.LastTrusteeship then
					player.isTrusteeship = false
					self:set_trusteeship(player,true)
				else
					self:trusteeship(player)
				end
			else
				-- 游戏出现异常 结束 游戏
				log.error("not find player gameTableid [%s]",self.table_game_id)
				self:finishgameError()
			end
		end
		if self.status == LAND_STATUS_PLAY and curtime - self.gamelog.start_game_time > LAND_TIME_OVER then
			self:finishgameError()
			log.warning("LAND_TIME_OVER gameTableid [%s]",self.table_game_id)
		end
	elseif self.status == LAND_STATUS_CALL then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_CALL_SCORE then
			-- 超时
			local player = self.players[self.cur_turn]
			if player then
				log.info("call_score time out call 0: [%d]",player.chair_id)
				self:call_score(player, 0)
			else
				log.info("player is offline chairid [%d]",self.cur_turn)
			end
			self.time0_ = curtime
		end
	elseif self.status == LAND_STATUS_DOUBLE then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_CALL_SCORE then
			-- 超时
			for i,v in ipairs(self.players) do
				if v and v.is_double == nil then
					self:call_double(v,false)
				end
			end
		end
	elseif self.status == LAND_STATUS_PLAYOFFLINE then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_WAIT_OFFLINE then
		-- 游戏结束 进行结算
			log.info("LAND_TIME_WAIT_OFFLINE time out time0[%d] curtime[%d]",self.time0_ ,curtime)
			self:finishgame()
		end
	end
end
-- function abc( ... )
--     -- body
--     log.info("================================abc=================================")
--     local aTest = {
--         startTime = 123456,
--         endTime = 987654321,
--         callsource = {},
--         abc = {},
--     }
--     local callsource1 = {
--         calltime = 111111111,
--         source = 1,
--         chairid = 1,
--     }
--     local callsource2 = {
--         calltime = 222222222,
--         source = 2,
--         chairid = 2,
--     }
--     local callsource3 = {
--         calltime = 3333333,
--         source = 3,
--         chairid = 3,
--     }
--     table.insert(aTest.callsource,callsource1)
--     table.insert(aTest.callsource,callsource2)
--     table.insert(aTest.callsource,callsource3)
--     local f = json.encode(aTest)
--     log.info("================================abc=================================")
--     log.info(f)
-- end
-- abc()
--

--做差牌，第一个17张是差牌
function land_table:shuffle_cheat_cards()
	-- body
	local bad_cards = {}
	self.new_cards = {}
	for i = 1, 54 do
		self.new_cards[i] = i - 1
	end
	--4,5,6随机一个空位
	local iLackValue1 = random.boost_integer(1,3) + 1
	--print("iLackValue1-------->",iLackValue1)
	--7,8,9随机一个空位
	local iLackValue2 = random.boost_integer(1,3) + 4
	--print("iLackValue2-------->",iLackValue2)
	local iBadCardsCount = 1
	local arrSmallCardStat = {}
	for i=0,3 do
		arrSmallCardStat[i] = {}
		for j=0,7 do
			arrSmallCardStat[i][j] = 1
		end
	end

	--print("arrSmallCardStat[3][3] = ",arrSmallCardStat[3][3])

	while (iBadCardsCount < 13) do
		local iColor = random.boost_integer(0,3)
		--print("iColor-------->",iColor)
		local iValueIndex = random.boost_integer(0,7)
		--print("iValueIndex-------->",iValueIndex)
		if arrSmallCardStat[iColor][iValueIndex] == 1 and iValueIndex ~= iLackValue1 and iValueIndex ~= iLackValue2 then
			if arrSmallCardStat[0][iValueIndex] + arrSmallCardStat[1][iValueIndex] + arrSmallCardStat[2][iValueIndex] + arrSmallCardStat[3][iValueIndex] > 1 then
				arrSmallCardStat[iColor][iValueIndex] = 0
				bad_cards[iBadCardsCount] = getIntPart(iValueIndex * 4 + iColor)
				self.new_cards[iValueIndex * 4 + iColor + 1] = -1
				iBadCardsCount = iBadCardsCount + 1
				--log.info("%d is  iValueIndex[%d] iColor[%d]" , iBadCardsCount - 1 , iValueIndex , iColor)
			end
		end
	end

	--log.info(table.concat(bad_cards, ',')
	--log.info(table.concat(self.new_cards, ',')
	--print("11111111111111111111111")
	--10以上的选5张
	--50概率给一张2或小王
	local coeff_value = random.boost_integer(1,100)
	if coeff_value < 25 then --抽小王
		bad_cards[iBadCardsCount] = 52 --小王
		iBadCardsCount = iBadCardsCount + 1
		self.new_cards[52 + 1] = -1
	elseif coeff_value < 50 then--抽2
		local iSelectedColor = random.boost_integer(0,3)
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

	local arrBigCardCanUse = {}
	arrBigCardCanUse[0] = 3
	arrBigCardCanUse[1] = 3
	arrBigCardCanUse[2] = 2
	arrBigCardCanUse[3] = 2

	local arrBigCardRealValue = {}
	arrBigCardRealValue[0] = 32
	arrBigCardRealValue[1] = 36
	arrBigCardRealValue[2] = 40
	arrBigCardRealValue[3] = 44
	--print("2222222222222222222iBadCardsCount----->",iBadCardsCount)
	while (iBadCardsCount < 18) do
		local iColor = random.boost_integer(0,3)
		local iValueIndex = random.boost_integer(0,3)

		if arrBigCardStat[iColor][iValueIndex] == 1 then
			if arrBigCardStat[0][iValueIndex] + arrBigCardStat[1][iValueIndex] + arrBigCardStat[2][iValueIndex] + arrBigCardStat[3][iValueIndex] > 4 - arrBigCardCanUse[iValueIndex] then
				arrBigCardStat[iColor][iValueIndex] = 0
				bad_cards[iBadCardsCount] = getIntPart(arrBigCardRealValue[iValueIndex] + iColor)
				iBadCardsCount = iBadCardsCount + 1
				self.new_cards[arrBigCardRealValue[iValueIndex] + iColor + 1] = -1
				--print("--------------------iBadCardsCount----->",iBadCardsCount)
			end
		end
	end
	--print("33333333333333333")
	table.sort(bad_cards, function(a, b) return a < b end)
	--log.info(table.concat(bad_cards, ',')
	-- log.info("bad_cards count---------------->[%d]", getNum(bad_cards))
	-- log.info(table.concat(self.new_cards, ',')
	local left_cards = {}
	for _,z in ipairs(self.new_cards) do
		if z and z ~= -1 then
			local value = tonumber(z)
			table.insert(left_cards,value)
		end
	end
	table.sort(left_cards, function(a, b) return a < b end)
	-- log.info(table.concat(left_cards, ',')
	-- log.info("left_cards count---------------->[%d]", getNum(left_cards))

	local ilen = #left_cards
	--混乱剩余扑克
	for i = 1, 18 do
		local x = random.boost(ilen)
		local y = random.boost(ilen)
		if x ~= y then
			left_cards[x], left_cards[y] = left_cards[y], left_cards[x]
		end
	end

	self.new_cards = {}
	for i=1,getNum(bad_cards) do
		local value = getIntPart(bad_cards[i])
		table.insert(self.new_cards, value)
	end
	for i=1,getNum(left_cards) do
		table.insert(self.new_cards, left_cards[i])
	end

	if self:check_cards_type(self.new_cards) == true then
		--log.info("check_cards_type---------->ok")
		return true
	else
		--log.error("check_cards_type---------->error")
		return false
	end

end

--校验牌库牌型是否错误
function land_table:check_cards_type(all_cards)
	if not all_cards then
		--log.error("------------------------->all_cards is nil")
		return false
	end

	local cards_count = getNum(all_cards)
	if cards_count ~= 54 then
		--log.error("all_cards count error,curCards total[%d]", cards_count)
		return false
	end


	local cards = {}
	for _,z in ipairs(all_cards) do
		if z then
			table.insert(cards,z)
		end
	end
	table.sort(cards, function(a, b) return a < b end)
	--log.info(table.concat(cards, ',')
	--校验牌是否有重复的牌和牌型
	local cards_voctor = {}
	for i,v in ipairs(cards) do
		local value_key = i - 1
		if v < 0 or v > 53 then
			log.error(table.concat(cards, ','))
			--log.error("cards value error [%d]",v)
			return false
		end
		if value_key ~= v then
			--log.error("~~~~~~~~~~~~index = [%d]",v)
			log.info(table.concat(cards, ','))
			return false
		end

		if not cards_voctor[v] then
			cards_voctor[v] = 1
		else
			log.error(table.concat(cards, ','))
			--log.error("repeat cards error----------->[%d]",v)
			return false
		end
	end

	return true
end

return land_table