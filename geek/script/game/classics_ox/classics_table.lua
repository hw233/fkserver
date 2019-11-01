local pb = require "pb_files"
local base_table = require "game.lobby.base_table"
require "game.classics_ox.classics_table_gamelogic"
require "data.texas_data"
require "table_func"
local random = require("random")
local log = require "log"

require "game.classics_ox.classics_robot"
local classics_android = classics_android

local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

local classics_table = base_table:new()

local DEBUG_MODE = true

local	CLASSICS_CARD_TYPE_NONE           = 100;
local	CLASSICS_CARD_TYPE_ONE            = 101;
local	CLASSICS_CARD_TYPE_TWO            = 102;
local   CLASSICS_CARD_TYPE_THREE 			= 103;
local	CLASSICS_CARD_TYPE_FOUR 			= 104;
local	CLASSICS_CARD_TYPE_FIVE 			= 105;
local	CLASSICS_CARD_TYPE_SIX 			= 106;
local	CLASSICS_CARD_TYPE_SEVEN 			= 107;
local	CLASSICS_CARD_TYPE_EIGHT 			= 108;
local	CLASSICS_CARD_TYPE_NIGHT 			= 109;
local	CLASSICS_CARD_TYPE_TEN			= 110;
local	CLASSICS_CARD_TYPE_FOUR_KING		= 201;
local	CLASSICS_CARD_TYPE_FIVE_KING		= 202;
local	CLASSICS_CARD_TYPE_FOUR_SAMES		= 203;
local	CLASSICS_CARD_TYPE_FIVE_SAMLL		= 204;

local SYS_CARDS_NUM = 52
local SYS_CARDS_VALUE = 37

local ACTION_INTERVAL_TIME  = 2
local STAGE_INTERVAL_TIME   = 2

local STATUS_WAITING				= 0
local STATUS_SEND_CARDS				= 1
local STATUS_CONTEND_CLASSICS		= 2
local STATUS_CONTEND_END 			= 3
local STATUS_DICISION_CLASSICS		= 4
local STATUS_BET					= 5
local STATUS_BET_END				= 6
local STATUS_SHOW_CARD				= 7
local STATUS_SHOW_CARD_END  		= 8

local STATUS_SHOW_DOWN				= 9
local STATUS_OVER					= 10

local LOG_MONEY_OPT_TYPE_CLASSICS_OX = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_CLASSICS_OX")


local PLAYER_STATUS_READY	= 1
local PLAYER_STATUS_GAME	= 1
local PLAYER_STATUS_OFFLINE	= 3

local POSITION_CLASSICS		= 1
local POSITION_NORMAL		= 2

local CS_ERR_OK = 0 	 --正常
local CS_ERR_MONEY = 1   --钱不够
local CS_ERR_STATUS = 2  --状态和阶段不同步错误

local START_TIME = 5
local CONTEND_CLASSICS_TIME = 6
local DICISION_CLASSICS = 5
local BET_TIME = 6
local SHOWCARD_TIME = 5
local END_TIME = 5
local MAX_TIMES = 3 --最大赔率

-- 下注倍数选项
local bet_times_option = {5,10,15,20}
-- 最大索引
local MAX_CARDS_INDEX = 1
-- 最小索引
local MIN_CARDS_INDEX = 2

--中奖公告标准,超过该标准全服公告
local CLASSIC_OX_GRAND_PRICE_BASE = 10000

local getNum = getNum
function classics_table:init_load_texas_config_file()
 	package.loaded["data/texas_data"] = nil
	require "data.texas_data"
end

function classics_table:load_texas_config_file()
	TEXAS_FreeTime = texas_room_config.Texas_FreeTime
	--print("BetTime = "..OX_TIME_ADD_SCORE)
end

--重置
function classics_table:reset()
	self.b_status = STATUS_WAITING
	self.b_timer = 0
	--self.b_status_table = TABLE_STAT_BETTING
	--self.b_pob_player = {}	-- to load from config


	self.b_ret = {}
	self.b_pool = 0
	self.b_player = {}
	self.b_end_player = {}
	self.b_player_count = 0
	self.b_classics = {guid = 0}
	self.b_recoonect = {}
	self.b_max_bet = 0
	self.player_contend_count = {} --统计抢庄发话人数
	self.b_total_time = 0
	self.b_contend_count = {} --抢庄人数
	self.b_bet_count = {}
	self.b_guess_count = {}
	self.b_table_busy = 0
	self.t_card_set = {}
	local cards_num = SYS_CARDS_NUM
	for i = 1, cards_num do
		self.t_card_set[i] = i - 1
	end
end

-- 初始化 0 - 51
function classics_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.b_player = {}
	self:reset()
	--self:init_load_texas_config_file()
	--self:load_texas_config_file()
	self.b_tax = self.room_:get_room_tax()
	self.b_bottom_bet = self.room_:get_room_cell_money()

	self.area_cards_ = {} --区域里的牌
	--self:test_card()
	-- 计分板
	self.last_score_record = {}
	self.classics_player_record = {}

	self.black_rate = 0
	--初始化不同变量和基础配置
	if def_first_game_type == 24 then
		if def_second_game_type == 4 then --银牛场
			bet_times_option = {10,15,20,30}
		elseif def_second_game_type == 5 or def_second_game_type == 6 then --金牛或神牛场
			bet_times_option = {10,20,30,40}
		end
		log.info("-------->type[%d]:bet_times_option:[%d,%d,%d,%d]",def_second_game_type,bet_times_option[1],bet_times_option[2],bet_times_option[3],bet_times_option[4])
	end
	self:robot_init()
end

local SYSTEM_BEAST_PROB = 3
local SYSTEM_FLOAT_PROB = 2
function classics_table:load_lua_cfg()
	print ("-------------classics_table-------###############################load_lua_cfg", self.room_.room_cfg)
	log.info("classics_table: game_maintain_is_open = [%s]",self.room_.game_switch_is_open)
	local fucT = load(self.room_.room_cfg)
	local classics_config = fucT()
	if classics_config then
		if classics_config.SYSTEM_BEAST_PROB then
			SYSTEM_BEAST_PROB = classics_config.SYSTEM_BEAST_PROB
			log.info("######### classics_configSYSTEM_BEAST_PROB:[%f]",SYSTEM_BEAST_PROB)
		end

		if classics_config.SYSTEM_FLOAT_PROB then
			SYSTEM_FLOAT_PROB = classics_config.SYSTEM_FLOAT_PROB
			log.info("#########classics_config SYSTEM_FLOAT_PROB:[%f]",SYSTEM_FLOAT_PROB)
		end

		if classics_config.CLASSIC_OX_GRAND_PRICE_BASE then
			CLASSIC_OX_GRAND_PRICE_BASE = classics_config.CLASSIC_OX_GRAND_PRICE_BASE
			log.info("######### CLASSIC_OX_GRAND_PRICE_BASE:[%d]",CLASSIC_OX_GRAND_PRICE_BASE)
		end

		if classics_config.BASIC_BET_TIMES then
			bet_times_option = classics_config.BASIC_BET_TIMES
			log.info("######### bet_times_option:[%d,%d,%d,%d]",bet_times_option[1],bet_times_option[2],bet_times_option[3],bet_times_option[4])
		end

		if classics_config.black_rate then
			self.black_rate = classics_config.black_rate
			log.info("#########self.black_rate:[%d]",self.black_rate)
		end

		if classics_config.robot_switch then
			self.robot_switch = classics_config.robot_switch
			log.info("#########self.robot_switch:[%d]",self.robot_switch)
		end

		self:init_robot_random()
		if classics_config.robot_strategy then
			self.robot_strategy = classics_config.robot_strategy
			log.info("#########self.robot_strategy:error")
		end

		if classics_config.robot_bet then
			self.robot_bet = classics_config.robot_bet
			log.info("#########self.robot_strategy:error")
		end

		if classics_config.robot_change_card then
			self.robot_change_card = classics_config.robot_change_card
			log.info("#########self.robot_change_card: [%d]", self.robot_change_card)
		end
		self:run_rob_ramdom_value()
	else
		print("land_config is nil")
	end
end
-- 心跳
function classics_table:tick()
	self:check_robot_enter()
	if self.b_timer < get_second_time() then
		if self.b_table_busy == 0 and getNum(self.players) > self.b_player_count then
			for i,v in pairs(self.players) do
				if v and v.enterTime and v.enterTime > get_second_time() - 15 and v.enterTime < get_second_time() - 13 then
					log.info("player[%d] time out  forced_exit room[%s]",v.guid , tostring(v.room_id))
					v.enterTime = nil
					v:forced_exit()
				end
			end
		end
		self.b_timer = get_second_time()
	end
	if get_second_time() < self.b_timer then
		return
	end
	if self.b_status == STATUS_OVER then
		for i,player in pairs(self.players) do
			if player and player.classics_enterflag == true then
				if player then
					self:playerReady(player)
				else
					log.info("v is nil:"..i)
				end
			end
		end
		self.b_status = STATUS_WAITING
	end
	if self.b_player_count > 1 and self.b_table_busy == 0 and self.b_status ~= STATUS_OVER then
		--self.b_status = STATUS_SEND_CARDS
		log.info("player > 1 time [%s]",tostring(get_second_time()))
		self.b_table_busy = 1
		self.b_timer = get_second_time() + START_TIME
		local msg = {
			s_start_time = self.b_timer - get_second_time() - 1
		}
		self:t_broadcast("SC_StartCountdown_Ox", msg)
		self.last_score_record = self.classics_player_record
		self.classics_player_record = {}
		return
	end

	if self.b_table_busy == 1 and self.b_status == STATUS_WAITING and self.b_player_count > 1 then
		-- 开始 游戏
		if base_table.start(self) == nil then
			log.info("cant Start Game ====================================================")
			return
		end
		
		for i,v in pairs (self.players) do
			if v and v.ready ~= true then
				v:forced_exit()
			end
		end
		self.b_status = STATUS_SEND_CARDS
		log.info("b_status = STATUS_SEND_CARDS   time [%s]",tostring(get_second_time()))
	end

	if self.b_table_busy == 1 and self.b_status > STATUS_WAITING and self.b_status < STATUS_OVER then
		self:game_start()
	end

	if self.b_status == STATUS_OVER then
		self:reset()
	end
end

--游戏阶段
--game
function classics_table:game_start()
	if self.b_status == STATUS_SEND_CARDS then
		self:send_player_cards()
	elseif self.b_status == STATUS_CONTEND_CLASSICS then
		self:begin_to_contend()
	elseif self.b_status == STATUS_CONTEND_END then
		self:decide_banker()
	elseif self.b_status == STATUS_BET then
		self:begin_bet()
	 elseif self.b_status == STATUS_BET_END then
	 	self:show_cards()
	 elseif self.b_status == STATUS_SHOW_CARD_END then
	 	self:send_result()
	end
end
--玩家进入
function classics_table:can_enter(player)
	log.info("classics_table:can_enter ===============")

	if self.b_table_busy == 1 and self.b_status == STATUS_WAITING and self.b_timer <= get_second_time() + 1 then
		log.warning("classics_table Game jast begin can not enter")
		return false
	end
	if player.vip == 100 then
		if self.b_player_count >= 5 then
			log.info("player[%d] can_enter room[%d] table[%d] false",player.guid, self.room_.id,self.table_id_)
			return false
		end
		if self.b_table_busy == 1 then
			player.classics_enterflag = nil
		end
		player.is_offline = false
		return true
	end
	if player then
		log.info ("classics_table player have date guid[%d] room[%d] table[%d] ",player.guid, self.room_.id,self.table_id_)
	else
		log.info ("player no data")
		return false
	end

	for _,v in ipairs(self.players) do
		if v and v.guid ~= player.guid then
			if player:judge_ip(v) then
				log.info("classics table:can_enter false ip limit")
				return false
			end
		end
	end

	print("======== classics_table:can_enter =====")
	--if self.b_table_busy == 1 or self.b_player_count == 5 then
	if self.b_player_count >= 5 then
		log.info("player[%d] can_enter room[%d] table[%d] false",player.guid, self.room_.id,self.table_id_)
		return false
	end
	if self.b_table_busy == 1 then
		player.classics_enterflag = nil
	end
	print("------- classics_table:can_enter true    ")

	log.info("player[%d] can_enter room[%d] table[%d] true",player.guid, self.room_.id,self.table_id_)
	--self.b_timer = get_second_time() + 1
	log.info("player[%d] is_offline false",player.guid)
	player.is_offline = false
	return true
end

function classics_table:test_card()
	local good_cards_num = 0
	local have_ox_num = 0
	local player_Num_test = 4
	for i=1,10 do
		have_ox_num = 0
		good_cards_num = 0
		for j=1,10000 do

			local user_cards_idx = 0
			self.t_card_set = {}
			local cards_num = SYS_CARDS_NUM
			for i = 1, cards_num do
				self.t_card_set[i] = i - 1
			end
			local setCount = getNum(self.t_card_set) or SYS_CARDS_NUM
			--log.info("user_cards_idx is  [%d]",user_cards_idx)

			local cards_ = nil
			local prob = random.boost_integer(0,100)
			local Goocards = 3 + random.boost_integer(0,2)
			local isGoodCard = false
			if prob <  Goocards then
				isGoodCard = true
				good_cards_num = good_cards_num + 1
			end

			--  log.info("*********************")
			for k=1,player_Num_test do
				local save_cards = {}
				--log.info("Goocards is [%d] prob is [%d]" , Goocards, prob)
				if prob <  Goocards then
					-- 做牌型
					--log.info("get goold cards")
					cards_ = { true, true , true , false , false }
					local a, b , c , d = random.boost_integer(1,5), random.boost_integer(1,5), random.boost_integer(1,5), random.boost_integer(1,5)

					--log.info("a is [%d] b is [%d] c is [%d] d is [%d]" , a, b ,c ,d)
					if a ~= b then
						cards_[a] ,cards_[b] = cards_[b] ,cards_[a]
					end
					if c ~= d then
						cards_[c] ,cards_[d] = cards_[d] ,cards_[c]
					end
				else
					-- 不做牌型
					cards_ = { false , false , false , false , false }
				end

				local haveTenCards = true
				-- log.info("=============================")
				for i = 1,5 do
					local idx = 0
					if cards_[i] then
						if setCount - user_cards_idx >= SYS_CARDS_VALUE then
							idx = random.boost_integer(SYS_CARDS_VALUE,setCount - user_cards_idx)
							-- log.info("==== %d [%d]",idx,self.t_card_set[idx])
						else
							if haveTenCards then
								local x = 1
								idx = 0
								while( x < setCount - user_cards_idx and idx == 0 ) do
									if self.t_card_set[x] >= 36 then
										idx = x
									end
									x = x + 1
								end
								if idx == 0 then
									haveTenCards = false
								end
							end

							if idx == 0 then
								idx = random.boost(1,setCount - user_cards_idx)
							end
						end
					else
						idx = random.boost(1,setCount - user_cards_idx)
						--log.info("tt i is [%d] idx is [%d]" ,i, idx)
					end
					local card = self.t_card_set[idx]
					table.insert(save_cards, card)
					self.t_card_set[idx] = self.t_card_set[getNum(self.t_card_set) - user_cards_idx]
					self.t_card_set[getNum(self.t_card_set) - user_cards_idx] = card
					user_cards_idx = user_cards_idx + 1
				end
				if isGoodCard then
					local ox_type_,value_list_,color_, extro_num_, sort_cards_ = get_cards_type(save_cards)
					local times = get_type_times(ox_type_,extro_num_)
					if ox_type_ > 100 then
						have_ox_num = have_ox_num + 1
					else
						log.info("cards[%s] type[%d]",table.concat(save_cards,","),ox_type_)
					end
				end
			end

		end
		log.info("have_ox_num = [%d] ,good_cards_num = [%d] [%d]",have_ox_num,good_cards_num * player_Num_test,good_cards_num)
	end
end

function classics_table:send_player_cards()
	log.info("game start  time [%s]",tostring(get_second_time()))
	self.b_status = STATUS_SEND_CARDS
	self.table_game_id = self:get_now_game_id()
	self:next_game()
	self.game_log = {
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        bottom_bet  = self.b_bottom_bet,
        banker = {},
        classics_contend = {},
        players = {},
    }

	local notify = {}
	notify.pb_player = {}
	notify.pb_table = {
		state = self.b_status,
		bottom_bet = self.b_bottom_bet,
	}
	local user_cards_idx = 0

	for _guid, b_player in pairs(self.b_player) do
		local player = self:get_player(b_player.chair)
		table.insert(notify.pb_player, {
			guid = _guid,
			chair = b_player.chair,
			name = player.nickname,
			icon =  player:get_header_icon(),
			money = player:get_money(),
			ip_area = player.ip_area
		})
		self.game_log.classics_contend[b_player.chair] = -1
		self.game_log.players[b_player.chair] = {
			nickname = player.nickname,
			chair = b_player.chair,
			money_old = player:get_money()
		}

		local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
		log.info(str)
		redis_command(str)
	end




	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
-- local _idx = 1

	local prob = random.boost(0,100)
	local Goocards = SYSTEM_BEAST_PROB + random.boost(0,SYSTEM_FLOAT_PROB)
	local setCount = getNum(self.t_card_set) or SYS_CARDS_NUM
	local robot_num = 0
	local player_num = 0
	local playerstemp = {}
	local robot_list_temp = {}
	for _key, _player in pairs(notify.pb_player) do
		log.info("user_cards_idx is  [%d]",user_cards_idx)
		notify.pb_table.chair = _player.chair
		local cards_ = nil
		log.info("Goocards is [%d] prob is [%d]" , Goocards, prob)
		if prob <  Goocards then
			-- 做牌型
			log.info("get goold cards")
			 cards_ = { true, true , true , false , false }
			local a, b , c , d = random.boost(5), random.boost(5), random.boost(5), random.boost(5)

			log.info("a is [%d] b is [%d] c is [%d] d is [%d]" , a, b ,c ,d)
			if a ~= b then
				cards_[a] ,cards_[b] = cards_[b] ,cards_[a]
			end
			if c ~= d then
				cards_[c] ,cards_[d] = cards_[d] ,cards_[c]
			end
		else
			-- 不做牌型
			cards_ = { false , false , false , false , false }
		end

		local haveTenCards = true
		for i = 1,5 do
			local idx = 0
			if cards_[i] then
				if setCount - user_cards_idx >= SYS_CARDS_VALUE then
					idx = random.boost(SYS_CARDS_VALUE,setCount - user_cards_idx)
				else
					if haveTenCards then
						--log.info("=================================================")
						local x = 1
						idx = 0
						while( x < setCount - user_cards_idx and idx == 0 ) do
							if self.t_card_set[x] >= 36 then
								idx = x
							end
							x = x + 1
						end
						--log.info("=================================================end[%d]",idx)
						if idx == 0 then
							haveTenCards = false
						end
					end

					if idx == 0 then
						idx = random.boost(1,setCount - user_cards_idx)
					end

					--if idx == 0 and i == 1 then
					--	idx = random.boost(1,setCount - user_cards_idx)
					--elseif idx == 0 then
					--	local upCards = get_value(self.b_player[_player.guid].cards[i - 1]) + 1
					--	log.info("1. upCards[%d][%d] ",self.b_player[_player.guid].cards[i - 1] , upCards )
					--	local x = 1
					--	while( x < setCount - user_cards_idx and idx == 0 ) do
					--		log.info("x is [%d]",x)
					--		local thisCards = get_value(self.t_card_set[x]) + 1
					--		log.info("2. thisCards[%d][%d] ",self.t_card_set[x] , thisCards )
					--		if thisCards + upCards == 10 then
					--			log.info("3. upCards[%d][%d] t_card_set[%d][%d]",self.b_player[_player.guid].cards[i - 1] , upCards , self.t_card_set[x] , thisCards )
					--			idx = x
					--		end
					--		x = x + 1
					--	end
					--end
				end
			else
				idx = random.boost(1,setCount - user_cards_idx)
				--log.info("tt i is [%d] idx is [%d]" ,i, idx)
			end
			local card = self.t_card_set[idx]
			table.insert(self.b_player[_player.guid].cards, card)
			self.t_card_set[idx] = self.t_card_set[getNum(self.t_card_set) - user_cards_idx]
			self.t_card_set[getNum(self.t_card_set) - user_cards_idx] = card
			user_cards_idx = user_cards_idx + 1
			--log.info("self.t_card_set is [%s]",table.concat(self.t_card_set,","))
		end
		-----test-----
		--self.b_player[145].cards = {49,34,41,18,30}
		--self.b_player[144].cards = {25,42,28,6,32}
		--self.b_player[141].cards = {26,12,3,40,17}
		--self.b_player[146].cards = {36,51,23,46,1}
		-----test-----

		self.game_log.players[_player.chair].cards = self.b_player[_player.guid].cards
		log.info("player is [%d] chair_id [%s]" , _player.guid , _player.chair)
		log.info(table.concat( self.b_player[_player.guid].cards, ","))

		notify.cards = {}
		for i = 1,5 do
			--notify.cards[i] = self.b_player[_player.guid].cards[i]
			notify.cards[i] = -1
		end


		local player = self:get_player(_player.chair)
		send2client_pb(player, "SC_ClassicsSendCards", notify)
		send2client_pb(player, "SC_ClassicsBasicBetTimesOptions", {bet_options = bet_times_option})
		if player.is_player then
			table.insert(playerstemp, player)
			player_num = player_num + 1
		else
			table.insert(robot_list_temp, player)
			robot_num = robot_num + 1
		end
	end

    --检查黑名单玩家
	self:check_black_user()
	--运算所有玩家牌类型
	self:run_cards_type()
	--计算机器人是否为最大牌型
	local max_chair_id, mix_chair_id = self:robot_start_game()
	local r = random.boost_integer(1,100)
	local b_change_cards = false
	if (r < self.robot_change_card) and self.robot_switch ~= 0 then
		b_change_cards = true
	end
	local now_cards_num = setCount - user_cards_idx
	if b_change_cards then
		local random_chair =  -1
		--最大牌
		local v = self:get_player(max_chair_id)
		if v and v.is_player and robot_num ~= 0 then
			random_chair = random.boost_integer(1, robot_num)
			local player_temp = robot_list_temp[random_chair]
			if player_temp then
				local _ =  self.b_player[player_temp.guid]
				random_chair = player_temp.chair_id
				log.info("change____player____cards_____begin:")
				log.info(table.concat(_.cards, ','))
				if next(_.cards) ~= nil then
					local cards_temp = _.cards
					local b_player = self.b_player[v.guid]
					if next(b_player.cards) ~= nil then
						_.cards = b_player.cards
						b_player.cards = cards_temp
					end
				end
				log.info("change____player____cards_____end:")
				log.info(table.concat(_.cards, ','))
			end
		end

		log.info("------------------------T :[%d] [%d]", random_chair, mix_chair_id)
		--最小牌
		v = self:get_player(mix_chair_id)
		if v and v.is_player == false and random_chair ~= mix_chair_id and player_num ~= 0 then
			random_chair = random.boost_integer(1, player_num)
			local player_temp = playerstemp[random_chair]
			if player_temp then
				local _ =  self.b_player[player_temp.guid]
				log.info("change____Robot____cards_____begin:")
				log.info(table.concat(_.cards, ','))
				if next(_.cards) ~= nil then
					local cards_temp = _.cards
					local b_player = self.b_player[v.guid]
					if next(b_player.cards) ~= nil then
						_.cards = b_player.cards
						b_player.cards = cards_temp
					end
				end
				log.info("change____Robot____cards_____end:")
				log.info(table.concat(_.cards, ','))
			end
		end
		self:run_cards_type()
	end

	self.b_status = STATUS_CONTEND_CLASSICS
	self.b_timer = get_second_time() + STAGE_INTERVAL_TIME
end
--运算所有玩家牌类型
function classics_table:run_cards_type()
	for _guid, b_player in pairs(self.b_player) do
		--tmp added for b_player error
		if next(b_player.cards) ~= nil then
			--算出牌型，倍数
			local ox_type_,value_list_,color_, extro_num_, sort_cards_ = get_cards_type(b_player.cards)
			local times = get_type_times(ox_type_,extro_num_)
			self.b_ret[_guid] =
			{
				guid = _guid,
				ox_type = ox_type_,
				val_list = value_list_,
				color = color_,
				extro_num = extro_num_,
				cards_times = times
			}

			if ox_type_ == CLASSICS_CARD_TYPE_ONE then
				--牛1 - 牛9·
				self.b_player[_guid].cards_type = CLASSICS_CARD_TYPE_NONE + extro_num_
				self.b_player[_guid].sort_cards = sort_cards_
			elseif ox_type_ == CLASSICS_CARD_TYPE_TEN then
				self.b_player[_guid].cards_type = ox_type_
				self.b_player[_guid].sort_cards = sort_cards_
			else
				self.b_player[_guid].cards_type = ox_type_
			end
		end
	end
end
function classics_table:getNum(arraylist)
	-- body
	local iNum = 0
	for _,v in pairs(arraylist) do
		iNum = iNum + 1
	end
	return iNum
end

function classics_table:decide_banker()

	log.info("gameid [%s] self.b_contend_count is [%d]",self.table_game_id, getNum(self.b_contend_count))
	--定庄阶段
	self.b_status = STATUS_DICISION_CLASSICS
	self.b_total_time = 0
	local classics_candidate = {}		--抢庄的候选人

	if getNum(self.b_contend_count) == 0 then
		-- 没人抢庄
		log.info("gameid [%s] no one contend count ~!",self.table_game_id)
		for _guid, b_player in pairs(self.b_player) do
			--未表态，群发默认不抢
			self.b_player[_guid].ratio = -1
			local msg = {
				chair = b_player.chair,
				ratio = -1
			}
			self:t_broadcast("SC_ClassicsPlayerContend", msg)
			self.game_log.classics_contend[b_player.chair] = 1
			log.info("not find  player contend banker.")
			local b_contend_data = {
				guid = _guid,
				ratio = 1,
				chair = b_player.chair,
			}
			table.insert(classics_candidate, b_contend_data)
		end
	else
		for _,v in pairs(self.b_contend_count) do
			if #classics_candidate == 0 then
				table.insert(classics_candidate,v)
			elseif classics_candidate[1].ratio == v.ratio then
				table.insert(classics_candidate,v)
			elseif classics_candidate[1].ratio < v.ratio then
				classics_candidate = {}
				table.insert(classics_candidate,v)
			end
		end
	end

	log.info("banker_candidate is [%d]", getNum(classics_candidate))
	local msg = {}
	if getNum(classics_candidate) > 1 then
		msg.chairs = {}
		for _,v in pairs(classics_candidate) do
			table.insert(msg.chairs, v.chair)
		end

		math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		local idx = random.boost(1, getNum(msg.chairs))

		self.b_classics = {
			chair = classics_candidate[idx].chair,
			guid = classics_candidate[idx].guid,
			ratio = classics_candidate[idx].ratio
		}

		msg.classics_chair = classics_candidate[idx].chair
	else
		-- #classics_candidate == 1
		self.b_classics = {
			chair = classics_candidate[1].chair,
			guid = classics_candidate[1].guid,
			ratio = classics_candidate[1].ratio
		}

		msg.classics_chair = classics_candidate[1].chair
		msg.chairs = { msg.classics_chair }

	end

	if self.b_classics.ratio < 1 then
		self.b_classics.ratio = 1
		self.b_player[self.b_classics.guid].ratio = 1
	end
	msg.classics_ratio = self.b_classics.ratio
	log.info("self.b_classics.ratio = [%d],guid = [%d]", self.b_classics.ratio,self.b_classics.guid)
	self.game_log.banker = self.b_classics

	if DEBUG_MODE then
		print("||||||   decide_classics()  |||||||||")
		dump(msg)
	end

	--闲家最大压注
	local classics_player = self:get_player(self.b_classics.chair)
	local classics_money = classics_player:get_money()  --庄家的钱
	self.b_max_bet = math.floor(classics_money / (self.b_player_count - 1) / MAX_TIMES) --本局闲家最大押注为庄家总金额/闲家人数/最大赔率
	self:t_broadcast("SC_ClassicsChoosingBanker", msg)
	self.b_status = STATUS_BET
	--self.b_timer = get_second_time() + DICISION_CLASSICS
	--只有一人抢庄时不延时5s给客户端播放动画
	if getNum(self.b_contend_count) == 1 then
		self.b_timer = get_second_time()
	else--抢庄人数大于1时或者都没有人抢庄时加延时给客户端播放动画时间
		self.b_timer = get_second_time() + DICISION_CLASSICS
	end
	log.info("Cur Banker guid = [%d]",self.b_classics.guid)
end


--摊牌
function classics_table:show_cards()
	if DEBUG_MODE then
		print("============ test print b_player  ================")
		dump(self.b_player)
		print("============ test print end  ================")
	end

	--摊牌阶段
	self.b_status = STATUS_SHOW_CARD
	self.b_total_time = 0
	--未下注的，默认下最低倍
	for _guid, b_player in pairs(self.b_player) do
		--tmp added for b_player error
		if next(b_player.cards) ~= nil then
			if b_player.bet == 0 and _guid ~= self.b_classics.guid then
				self.b_player[_guid].bet = bet_times_option[1] * self.b_bottom_bet * self.b_classics.ratio

				local msg = {
					chair = b_player.chair,
					bet_money = self.b_player[_guid].bet,
					bet_times = bet_times_option[1] --默认的该场次的最低倍数
				}
				self:t_broadcast("SC_ClassicsPlayerBet", msg)
				self.game_log.players[b_player.chair].bet_times = msg.bet_times
				self.game_log.players[b_player.chair].bet = self.b_player[_guid].bet
			end

			--[[算出牌型，倍数
			local ox_type_,value_list_,color_, extro_num_, sort_cards_ = get_cards_type(b_player.cards)
			local times = get_type_times(ox_type_,extro_num_)
			self.b_ret[_guid] =
			{
				guid = _guid,
				ox_type = ox_type_,
				val_list = value_list_,
				color = color_,
				extro_num = extro_num_,
				cards_times = times
			}

			if ox_type_ == CLASSICS_CARD_TYPE_ONE then
				--牛1 - 牛9·
				self.b_player[_guid].cards_type = CLASSICS_CARD_TYPE_NONE + extro_num_
				self.b_player[_guid].sort_cards = sort_cards_
			elseif ox_type_ == CLASSICS_CARD_TYPE_TEN then
				self.b_player[_guid].cards_type = ox_type_
				self.b_player[_guid].sort_cards = sort_cards_
			else
				self.b_player[_guid].cards_type = ox_type_
			end]]

			self.game_log.players[b_player.chair].cards_type = self.b_player[_guid].cards_type
			self.game_log.players[b_player.chair].cards_info = self.b_ret[_guid]
		else
			self.b_player[_guid] = nil
		end
	end

	--看到自己的牌
	local msg = {
		countdown = SHOWCARD_TIME,
		total_time = SHOWCARD_TIME,
	}
	for _guid, b_player in pairs(self.b_player) do
		msg.cards = b_player.cards
		msg.cards_type = b_player.cards_type

		local player = self:get_player(b_player.chair)
		if player then
			send2client_pb(player, "SC_ClassicsShowOwnCards", msg)
		end
	end

	self.b_status = STATUS_SHOW_CARD_END
	self.b_timer = get_second_time() + SHOWCARD_TIME
	self.b_total_time = SHOWCARD_TIME
end

--游戏结算
function classics_table:send_result()
	self.classics_player_record = {}
	self.b_total_time = 0
	for _guid, b_player in pairs(self.b_player) do

		local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
		log.info(str)
		redis_command(str)
		--tmp added for b_player errors
		if b_player.show_card == 0 and next(b_player.cards) ~= nil then

			local msg = {
				chair = b_player.chair,
				cards_type = b_player.cards_type,
			}

			if msg.cards_type > CLASSICS_CARD_TYPE_NONE and msg.cards_type < CLASSICS_CARD_TYPE_FOUR_KING then
				msg.flag = 1
				msg.cards = self.b_player[_guid].sort_cards and self.b_player[_guid].sort_cards or self.b_player[_guid].cards
			else
				msg.flag = 2
				msg.cards = self.b_player[_guid].cards
			end

			self:t_broadcast("SC_ClassicsShowCards", msg)
		end
	end

	-- 下注流水日志
	for _,player in pairs(self.b_player) do
		self:player_bet_flow_log(player,player.bet)
	end

	self.b_status = STATUS_SHOW_DOWN
	print("send_result......")
	local notify = {}
	notify.pb_table = {
		state = self.b_status,
		bottom_bet = self.b_bottom_bet,
	}
	notify.pb_player = {}

	local classics_result = self.b_ret[self.b_classics.guid]
	local banker_player = self:get_player(self.b_classics.chair)
	local banker_old_money = banker_player.money
	local player_bankruptcy_flag = {} --记录玩家是否破产标记
	player_bankruptcy_flag[banker_player.guid] = 1 --庄家默认不破产
	local player_result  = {} --玩家应该赢或输的钱
	local banker_win_lose_money = 0
	local banker_win_money = 0
	local banker_lose_money = 0
	for _guid, b_player in pairs(self.b_player) do
		-- 先算出应该 输胜金钱总数
		if _guid ~= self.b_classics.guid and b_player.cards then
			local l_player = self:get_player(b_player.chair)
			local win = compare_cards(self.b_ret[_guid], classics_result)
			local s_old_money = l_player.money
			player_bankruptcy_flag[l_player.guid] = 1 --默认玩家不破产
			if win == true then
				local win_times_ = get_cards_odds(self.b_ret[_guid].cards_times)
				local win_money_ = b_player.bet * win_times_

				-- 赢
				if s_old_money < win_money_ then
					win_money_ = s_old_money
				end
				player_result[l_player.guid] = win_money_
                banker_lose_money = banker_lose_money + win_money_
				banker_win_lose_money = banker_win_lose_money + win_money_ --大于0是庄家输了好多钱，小于0是庄家赢了好多钱
				log.info("1111player[%d] betmoney = [%d],win_money_ = [%d] banker_win_lose_money = [%d]",l_player.guid,b_player.bet,win_money_,banker_win_lose_money)
			else
				local lose_times_ = get_cards_odds(classics_result.cards_times)
				local lose_money_ = b_player.bet * lose_times_
				-- 输
				if s_old_money < lose_money_ then
					lose_money_ = s_old_money
					player_bankruptcy_flag[l_player.guid] = 2 --玩家不够赔，破产
				end
				player_result[l_player.guid] = lose_money_
				banker_win_money = banker_win_money + lose_money_
				banker_win_lose_money = banker_win_lose_money - lose_money_
				log.info("2222player[%d] betmoney = [%d],lose_money_ = [%d] banker_win_lose_money = [%d]",l_player.guid,b_player.bet,lose_money_,banker_win_lose_money)
			end
		end
	end

	local lose_coeff = 0.0  --庄家输的比例
	local win_coeff = 0.0   --庄家赢的比例
	if banker_win_lose_money > 0 and banker_win_lose_money > banker_old_money then  --庄家输
		lose_coeff = (banker_old_money + banker_win_money) / banker_lose_money
		player_bankruptcy_flag[banker_player.guid] = 2 --庄家不够赔,破产
	end
	if banker_win_lose_money < 0 and (-banker_win_lose_money) > banker_old_money then --庄家赢
		win_coeff = (banker_old_money + banker_lose_money) / banker_win_money
	end
	log.info("~~~~~~~~~~~~~~~~~~~~~~~~~~~lose_coeff = [%f] win_coeff = [%f]",lose_coeff,win_coeff)

	for _guid, b_player in pairs(self.b_player) do
		if _guid ~= self.b_classics.guid and b_player.cards then
			local l_player = self:get_player(b_player.chair)
			local pb_player = {}
			local s_type = 1  -- default loss ,2 win
			local s_old_money = l_player.money
			local win = compare_cards(self.b_ret[_guid], classics_result)
			local classic_ox_player_stdard_award = 0

			if win == true then  --闲家赢了
				s_type = 2
				--local win_times = get_cards_odds(self.b_ret[_guid].cards_times)
				--local win_money = b_player.bet * win_times
				local win_money = player_result[l_player.guid]

				log.info("3333win_money = [%d] banker_win_lose_money = [%d] banker_old_money = [%d]",win_money,banker_win_lose_money,banker_old_money)
				if banker_old_money < 2 then
					win_money = 0 			-- 异常情况 玩家作弊
					log.error("classics_ox:player [%d] Cheat" , _guid)
				else
					if banker_win_lose_money > 0 and banker_win_lose_money > banker_old_money then
					--  按比例获得 金币
						win_money =  math.floor(win_money * lose_coeff)
						log.info("4444classics_ox:guid[%d] win_money [%d] banker_old_money [%d] banker_win_lose_money [%d]",_guid,win_money ,banker_old_money ,banker_win_lose_money)
					end
				end

				if s_old_money < win_money then
					log.info("~~~~~~s_old_money = [%d] win_money = [%d]",s_old_money,win_money)
					win_money = s_old_money
					log.info("------s_old_money = [%d] win_money = [%d]",s_old_money,win_money)
				end

				log.info("55555player[%d] betmoney = [%d],win_money = [%d] banker_win_lose_money = [%d]",l_player.guid,b_player.bet,win_money,banker_win_lose_money)
				local pb_tax = win_money * self.b_tax
				if pb_tax < 1 then
					pb_tax = 0
				else
					pb_tax = math.floor(pb_tax + 0.5)
				end

				pb_player = {
					chair = b_player.chair,
					money = 0,
					tax = pb_tax,
					victory = 1,
					increment_money = win_money - pb_tax,
					bankruptcy = player_bankruptcy_flag[l_player.guid],--默认不破产
				}
				if self.room_.tax_show_ == 0 then --1显示税收，0不显示税收
					pb_player.tax = 0
				end

				if l_player then
					l_player:add_money(
						{{ money_type = ITEM_PRICE_TYPE_GOLD,
						money = pb_player.increment_money }},
						LOG_MONEY_OPT_TYPE_CLASSICS_OX
					)
					pb_player.money = l_player:get_money()

					if self:islog(l_player.guid) then
						self:player_money_log(l_player,s_type,s_old_money,pb_tax,pb_player.increment_money,self.table_game_id)
					end
				end

				self.b_pool = self.b_pool - win_money
				self.game_log.players[b_player.chair].tax = pb_tax
				classic_ox_player_stdard_award = pb_player.increment_money
				if classic_ox_player_stdard_award >= CLASSIC_OX_GRAND_PRICE_BASE and l_player.is_player ~= false then
					log.info("player guid[%d] nickname[%s]in classics ox game earn money[%d] upto [%d],broadcast to all players.",l_player.guid,l_player.nickname,classic_ox_player_stdard_award,CLASSIC_OX_GRAND_PRICE_BASE)
					classic_ox_player_stdard_award = classic_ox_player_stdard_award / 100
					broadcast_world_marquee(def_first_game_type,def_second_game_type,0,l_player.nickname,classic_ox_player_stdard_award)
				end
			else --lose --闲家输了
				s_type = 1
				--local lose_times = get_cards_odds(classics_result.cards_times)
				--local lose_money = b_player.bet * lose_times
				local lose_money = player_result[l_player.guid]
				log.info("~~~~~~~~~will lose lose_money = [%d] player money = [%d]",lose_money,s_old_money)
				if banker_win_lose_money < 0 and (-banker_win_lose_money) > banker_old_money then
				--  按比例获得 金币
					lose_money =  math.floor(lose_money * win_coeff)
					log.info("66666classics_ox:guid[%d] lose_money [%d] banker_old_money [%d] banker_win_lose_money [%d]",_guid,lose_money ,banker_old_money ,banker_win_lose_money)
				end

				if s_old_money < lose_money then
					log.info("~~~~~~s_old_money = [%d] lose_money = [%d]",s_old_money,lose_money)
					lose_money = s_old_money
					log.info("----->s_old_money = [%d] lose_money = [%d]",s_old_money,lose_money)
				end
				log.info("77777player[%d] betmoney = [%d],acturl lose_money = [%d] banker_win_lose_money = [%d]",l_player.guid,b_player.bet,lose_money,banker_win_lose_money)
				pb_player = {
					chair = b_player.chair,
					money = 0,
					tax = 0,
					victory = 2,
					increment_money = -lose_money,
					bankruptcy = player_bankruptcy_flag[l_player.guid],
				}
				if l_player then
					l_player:cost_money(
						{{money_type = ITEM_PRICE_TYPE_GOLD, money = -pb_player.increment_money}},
						LOG_MONEY_OPT_TYPE_CLASSICS_OX,true
					)
					pb_player.money = l_player:get_money()
					if self:islog(l_player.guid) then
						self:player_money_log(l_player,s_type,s_old_money,0,pb_player.increment_money,self.table_game_id)
					end
					self:save_player_collapse_log(l_player)
				end

				self.b_pool = self.b_pool - pb_player.increment_money	-- add increment_money

			end

			local player_record = {
				guid = l_player.guid,
				header_icon = l_player:get_header_icon(),
				nick_name = l_player.nickname,
				cards_type = b_player.cards_type,
				money_change = pb_player.increment_money,
			}
			log.info("record: player[%d] header_icon[%d] nickname[%s] cards_type[%d] money_change[%d]",player_record.guid,player_record.header_icon,player_record.nick_name,player_record.cards_type,player_record.money_change)
			table.insert(self.classics_player_record,player_record)
			table.insert(notify.pb_player, pb_player)
			self.game_log.players[b_player.chair].increment_money = pb_player.increment_money
			self.game_log.players[b_player.chair].money_new = pb_player.money
		end
	end

	local pb_classics = {
		chair = self.b_classics.chair,
		money = 0,
		tax = 0,
		victory = 0,
		increment_money = 0,
		bankruptcy = player_bankruptcy_flag[banker_player.guid], --默认不破产
	}

	--classics add or cost money
	local l_player = self:get_player(self.b_classics.chair)
	local s_type = 1  -- default loss ,2 win
	local s_old_money = l_player.money
	local classic_ox_banker_stdard_award = 0
	log.info("==================>b_pool = [%d] banker_win_lose_money = [%d]",self.b_pool,banker_win_lose_money)
	if self.b_pool > 0  and banker_win_lose_money < 0 then --庄家赢了
		log.info("88888b_pool = [%d] banker_win_lose_money = [%d]",self.b_pool,banker_win_lose_money)
		pb_classics.victory = 1
		s_type = 2
		pb_classics.tax = math.floor(self.b_pool *  self.b_tax + 0.5)
		pb_classics.increment_money = self.b_pool - pb_classics.tax
		log.info("99999player[%d] increment_money = [%d] tax = [%d]",l_player.guid,pb_classics.increment_money,pb_classics.tax)
		if pb_classics.increment_money > s_old_money then
			log.info("00000guid[%d] banker win_money [%d] s_old_money[%d]",l_player.guid,pb_classics.increment_money ,s_old_money)
			pb_classics.increment_money = s_old_money
		end
		log.info("aaaplayer[%d] increment_money = [%d] s_old_money = [%d]",l_player.guid,pb_classics.increment_money,s_old_money)
		if l_player then
			l_player:add_money(
				{{ money_type = ITEM_PRICE_TYPE_GOLD,
				money = pb_classics.increment_money }},
				LOG_MONEY_OPT_TYPE_CLASSICS_OX
			)
			pb_classics.money = l_player:get_money()
			if self:islog(l_player.guid) then
				self:player_money_log(l_player,s_type,s_old_money,pb_classics.tax,pb_classics.increment_money,self.table_game_id)
			end
		end

		self.game_log.players[self.b_classics.chair].tax = pb_classics.tax
		self.game_log.banker.tax = pb_classics.tax
		if self.room_.tax_show_ == 0 then
			pb_classics.tax = 0 --不显示
		end
		classic_ox_banker_stdard_award = pb_classics.increment_money
		if classic_ox_banker_stdard_award >= CLASSIC_OX_GRAND_PRICE_BASE and l_player.is_player ~= false then
			log.info("bbbplayer guid[%d] nickname[%s]in classics ox game earn money[%d] upto [%d],broadcast to all players.",l_player.guid,l_player.nickname,classic_ox_banker_stdard_award,CLASSIC_OX_GRAND_PRICE_BASE)
			classic_ox_banker_stdard_award = classic_ox_banker_stdard_award / 100
			broadcast_world_marquee(def_first_game_type,def_second_game_type,0,l_player.nickname,classic_ox_banker_stdard_award)
		end
	else
		pb_classics.victory = 2
		s_type = 1

		pb_classics.increment_money = self.b_pool
		local lose_money = -self.b_pool
		-- -pb_classics.increment_money -self.b_player[self.b_classics.guid].bet 庄家不下注
		log.info("ccccguid[%d] b_pool = [%d] pb_classics.increment_money = [%d] lose_money = [%d]",l_player.guid,self.b_pool,pb_classics.increment_money,lose_money)
			if DEBUG_MODE then
				print("||||| resut lost_money: ",lose_money)
				print("|||  pb_classics  |||")
				dump(pb_classics)
			end

		if l_player then
			pb_classics.money = l_player:get_money()
			if lose_money > pb_classics.money then
				lose_money = pb_classics.money
			end
			if lose_money ~= 0 then
				l_player:cost_money(
					{{money_type = ITEM_PRICE_TYPE_GOLD, money = lose_money}},
					LOG_MONEY_OPT_TYPE_CLASSICS_OX,true
				)
			end
			pb_classics.money = pb_classics.money - lose_money
			if self:islog(l_player.guid) then
				self:player_money_log(l_player,s_type,s_old_money,0,-lose_money,self.table_game_id)
			end
			self:save_player_collapse_log(l_player)
		end
	end

	local banker_record = {
		guid = l_player.guid,
		header_icon = l_player:get_header_icon(),
		nick_name = l_player.nickname,
		cards_type = self.b_player[l_player.guid].cards_type,
		money_change = pb_classics.increment_money,
	}
	log.info("record: banker[%d] header_icon[%d] nickname[%s] cards_type[%d] money_change[%d]",banker_record.guid,banker_record.header_icon,banker_record.nick_name,banker_record.cards_type,banker_record.money_change)
	table.insert(self.classics_player_record,banker_record)
	table.sort(self.classics_player_record, function (a, b)
		if a.money_change == b.money_change then
			return a.guid < b.guid
		else
			return a.money_change > b.money_change
		end
	end)
	table.insert(notify.pb_player, pb_classics)
	self.game_log.players[self.b_classics.chair].increment_money = pb_classics.increment_money
	self.game_log.players[self.b_classics.chair].money_new = pb_classics.money
	self.game_log.banker.increment_money = pb_classics.increment_money
	self.game_log.banker.money_new = pb_classics.money_new

	self:t_broadcast("SC_ClassicsGameEnd", notify)
	self.b_end_player = notify.pb_player

		if DEBUG_MODE then
			print("|||  send_resut()  |||")
			dump(notify)
		end


	--gameLog
	self.game_log.end_game_time = os.time()
	local s_log = json.encode(self.game_log)
	log.info(s_log)

	local is_save_log = true
	if self.robot_switch ~= 0 then
		if self.robot_islog == false then
			is_save_log = false
		end
	end
	if is_save_log then
		self:save_game_log(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)
	end
	log.info("game finish~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!")
	self:reset()
	self.b_status = STATUS_OVER
	self.b_timer = get_second_time() + END_TIME
	local room_limit = self.room_:get_room_limit()
	for i,player in pairs(self.players) do
		if player and player.classics_enterflag ~= true then
			player.ready = false
			player.enterTime = get_second_time()
			if  player.in_game == false then
				log.info("player [%d] is offline ",i)
				player:forced_exit()
				log.info("set player[%d] in_game false" ,player.guid)
				player.in_game = false
			else
				player:check_forced_exit(room_limit)
			end
		--else
		--	if player then
		--		self:playerReady(player)
		--	else
		--		log.info("v is nil:"..i)
		--	end
		end
	end
	self:check_single_game_is_maintain()
	self:check_robot_leave()
	log.info("game end ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!")
end

--闲家开始下注
function classics_table:begin_bet()
	local msg = {
		countdown = BET_TIME - 1,
		total_time = BET_TIME - 1,
	}
	self:t_broadcast("SC_ClassicsPlayerBeginToBet", msg)

	self.b_status = STATUS_BET_END
	self.b_timer = get_second_time() + BET_TIME
	self.b_total_time = BET_TIME
end
--开始抢庄
function classics_table:begin_to_contend()
	log.info("classics_table:begin_to_contend =========================")
	local msg = {
		countdown = CONTEND_CLASSICS_TIME - 1,
		total_time = CONTEND_CLASSICS_TIME - 1
	}
	self:t_broadcast("SC_ClassicsBeginToContend", msg)

	self.b_status = STATUS_CONTEND_END
	self.b_timer = get_second_time() + CONTEND_CLASSICS_TIME
	self.b_total_time = CONTEND_CLASSICS_TIME
end

--玩家下注
function classics_table:classics_bet(player, msg)
	if self.b_status ~= STATUS_BET_END then
		log.info("b_status[%f]",self.b_status)
		return
	end

	if player == nil then
		log.error("player ===============nil.")
		return
	end

	if self.b_player[player.guid] == nil then
		if player.is_player ~= false then
			log.error("b_player[%d] ===============nil.",player.guid)
		end
		return
	end

	if self.b_classics.guid == player.guid then
		log.warning("banker guid[%d] can't bet money.",player.guid)
		return
	end
--[[
	-- 算出实际下注金额
	msg.bet_money = self.b_bottom_bet * self.b_classics.ratio * msg.bet_times   --底注×抢庄庄家倍数（1）× 玩家下注倍数
	local bankerMoney = (self:get_player(self.b_classics.chair)):get_money() 	-- 庄家身上的钱
	local playerPayMoney = self.b_max_bet                                    	-- 每个玩家实际可下注金额

	log.info("bankerMoney [%s] playerPayMoney[%s] #self.b_player[%d] msg.bet_times [%s]",tostring(bankerMoney) ,tostring(playerPayMoney) , self.b_player_count, tostring(msg.bet_times))

	local l_money = player:get_money()  -- 玩家自己身上的钱
	local self_bet_max = l_money/MAX_TIMES

	if self_bet_max > playerPayMoney then
		self_bet_max = playerPayMoney				--取两个数值中 最小的一个
	end

	log.info("classics_table playerPayMoney [%s] l_money[%s] self_bet_max[%s] msg.bet_money[%s]",tostring(playerPayMoney) ,tostring(l_money) ,tostring(self_bet_max) ,tostring(msg.bet_money))

	if msg.bet_money > self_bet_max then
		log.info("old bet_money is  [%s] bet_times [%s] " , tostring(msg.bet_money) , tostring(msg.bet_times))
		local bet_times = 1
		msg.bet_money = self.b_bottom_bet * bet_times
		msg.bet_times  = bet_times
		log.info("new bet_money is  [%s] bet_times [%s] " , tostring(msg.bet_money) , tostring(msg.bet_times))
	end
--]]
	local cur_player_money = player:get_money()
	log.info("player guid[%d] bet_money = [%d] bet_times = [%d] cur_player_money = [%d] ,banker_times = [%d]",player.guid,msg.bet_money,msg.bet_times,cur_player_money,self.b_classics.ratio)
	local player_cur_max_times = bet_times_option[1]
	--下注金币 = 闲家下注倍数 × 底注 × 庄家抢庄倍数
	if msg.bet_times == player_cur_max_times then --玩家选择最低倍数始终可选不用判断
		msg.bet_money = msg.bet_times * self.b_bottom_bet * self.b_classics.ratio
	else
		--选择其他倍数时需要判断玩家实际最大可选倍数 < 玩家下注倍数时，则重置玩家下注倍数（置为该场次的实际最大可选倍数的前一个倍数）
		--举例：该场次基础倍数为[5,10,15,20],玩家下注倍数为20倍，但玩家的实际最大倍数为18倍,那么需重置玩家的倍数为15倍
		--最大可选倍数=携带金币/底注/庄家抢庄倍数/4
		local acturl_player_bet_max_times = math.floor(cur_player_money/self.b_bottom_bet/self.b_classics.ratio/4)
		log.info("player guid[%d] bet_times[%d] acturl_player_bet_max_times[%d]",player.guid, msg.bet_times,acturl_player_bet_max_times)
		if msg.bet_times > acturl_player_bet_max_times then
			for i=1,4 do
				if acturl_player_bet_max_times > bet_times_option[i] and acturl_player_bet_max_times < bet_times_option[i+1] then
					msg.bet_times = bet_times_option[i]
					break
				end
			end
		end
		if msg.bet_times ~= bet_times_option[1] and msg.bet_times ~= bet_times_option[2] and msg.bet_times ~= bet_times_option[3] and msg.bet_times ~= bet_times_option[4] then
			log.warning("player guid[%d] bet times[%d] error, will set lowest bet options[%d]",player.guid,msg.bet_times,bet_times_option[1])
			msg.bet_times = bet_times_option[1]
		end
		msg.bet_money = msg.bet_times * self.b_bottom_bet * self.b_classics.ratio
		log.info("player guid[%d] bet_money = [%d] acturl_bet_times = [%d] cur_player_money = [%d] ,banker_times = [%d], acturl_player_bet_max_times = [%d]",player.guid,msg.bet_money,msg.bet_times,cur_player_money,self.b_classics.ratio,acturl_player_bet_max_times)
	end

	self.b_player[player.guid].bet = msg.bet_money
	self.b_player[player.guid].bet_times = msg.bet_times
	local msg = {
		chair = player.chair_id,
		bet_money = msg.bet_money,
		bet_times = msg.bet_times
	}
	log.info("player guid[%d] bet_money = [%s] bet_times=[%s]",player.guid,tostring(msg.bet_money),tostring(msg.bet_times))
	self:t_broadcast("SC_ClassicsPlayerBet", msg)
	self.game_log.players[player.chair_id].bet = msg.bet_money
	self.game_log.players[player.chair_id].bet_times = msg.bet_times
	--self.b_bet_count = self.b_bet_count + 1
	self.b_bet_count[player.guid] = 1

	if getNum(self.b_bet_count) == self.b_player_count - 1 then
	--if self.b_bet_count == self.b_player_count - 1 then
		self.b_timer = get_second_time()
	end
end

--猜牌
function classics_table:classics_guess_cards(player)
	if player then --and next(self.b_player[player.guid]) ~= nil
		log.info("player guid = [%d] show cards cur_status = [%d]",player.guid,self.b_status)
		if self:isPlayer(player) and self.b_status >= STATUS_SHOW_CARD then
			local msg = {
				chair = player.chair_id,
				cards = self.b_player[player.guid].cards,
				cards_type = self.b_player[player.guid].cards_type,
			}

			if msg.cards_type > CLASSICS_CARD_TYPE_NONE and msg.cards_type < CLASSICS_CARD_TYPE_FOUR_KING then
				msg.flag = 1
				msg.cards = self.b_player[player.guid].sort_cards and self.b_player[player.guid].sort_cards or self.b_player[player.guid].cards
			else
				msg.flag = 2
				msg.cards = self.b_player[player.guid].cards
			end

				if DEBUG_MODE then
					print("|||||   classics_guess_cards()  |||||")
					dump(msg)
				end

			if not self.b_guess_count[player.guid] then
				self:t_broadcast("SC_ClassicsShowCards", msg)
			end
			self.b_player[player.guid].show_card = 1
			self.b_guess_count[player.guid] = 1
			if getNum(self.b_guess_count) == self.b_player_count then
				self.b_timer = get_second_time()
			end
		end
	end
end

function classics_table:isPlayer( player )
	-- body
	if player then
		for i,v in pairs(self.b_player) do
			if i == player.guid then
				return true
			end
		end
	end
	return false
end

--玩家抢庄
function classics_table:classics_contend(player, ratio)
    if player and player.guid then
		log.info("classics_table:banker_contend ========== player [%d] ratio[%d]" , player.guid, ratio)
	end
	if self.b_status ~= STATUS_CONTEND_END then
		log.info("============status = [%d] status error,return" ,self.b_status)
		return
	end
	if not self:isPlayer(player) then
		if player then
			log.info("classics_contend player is not in game guid[%d]" , player.guid)
		else
			log.info("classics_contend player is nil")
		end
		return
	end
	if ratio < 0 then
		ratio = 0
	end
	if self.b_player[player.guid].ratio ~= -1 then
		log.info("classics_contend player ratio is not nil guid[%d] ratio[%d]" , player.guid , self.b_player[player.guid].ratio)
		return
	end
	local player_curMoney = player:get_money()
	--最大可抢倍数校验
	local cur_max_ratio = math.floor(player_curMoney/self.b_bottom_bet/25)
	log.info("classics_table:banker_contend ========== player [%d] ratio[%d] curMoney = [%d] cur_max_ratio = [%d]" , player.guid, ratio,player_curMoney,cur_max_ratio)
	if ratio > cur_max_ratio then
		ratio = cur_max_ratio
	end
	--抢庄倍数异常时，默认为1
	if ratio > 4 then
		log.warning("classics_table:player guid[%d] classics contend expection ratio[%d] will be set ratio = 1" , player.guid, ratio)
		ratio = 1
	end

	self.b_player[player.guid].ratio = ratio
	local msg = {
		chair = player.chair_id,
		ratio = ratio
	}
	local b_contend_data = {
		guid = player.guid,
		ratio = ratio,
		chair = player.chair_id,
	}
	if ratio ~= 0 then
		table.insert(self.b_contend_count, b_contend_data)
	end
	self.player_contend_count[player.guid] = 1 --统计抢庄发话人数,若等于所有在玩玩家人数时，直接进入下个阶段倒计时
	-- self.b_contend_count = self.b_contend_count + 1
	self:t_broadcast("SC_ClassicsPlayerContend", msg)
	self.game_log.classics_contend[player.chair_id] = ratio
	log.info("-----------self.b_contend_count = [%d] player_contend_count[%d]" ,getNum(self.b_contend_count), getNum(self.player_contend_count))
	if getNum(self.b_contend_count) == self.b_player_count  or getNum(self.player_contend_count) == self.b_player_count then
		self.b_timer = get_second_time()
	end
end


function classics_table:reconnect(player)
	print("---------- reconnect~~~~~~~~~!",player.chair_id,player.guid)
	if self.b_status == STATUS_WAITING then
		return
	end

	player.table_id = self.table_id_
	player.room_id = self.room_.id
	self.b_recoonect[player.guid] = 1
	--send2client_pb(player, "SC_ClassicsReconnectInfo", notify)
	return
end

function classics_table:reconnect(player)
	log.info("player[%d] reconnect",player.guid)
	local notify = {}
	notify.pb_table = {
		state = math.floor(self.b_status),
		bottom_bet = self.b_bottom_bet,
		chair = player.chair_id
	}
	notify.pb_player = {}

	if next(self.b_end_player) == nil then
		for _guid, b_player in pairs(self.b_player) do
			local l_player = self:get_player(b_player.chair)
			local pb_player = {
				guid = _guid,
				chair = b_player.chair,
				name = l_player.nickname,
				icon =  l_player:get_header_icon(),
				money = l_player:get_money(),
				ratio = b_player.ratio,
				position = _guid == self.b_classics.guid and 1 or -1,
				bet_money = b_player.bet,
				ip_area = l_player.ip_area,
				bet_times = b_player.bet_times
			}

			if _guid == player.guid and next(b_player.cards) ~= nil then
				if self.b_status < STATUS_SHOW_CARD then
					pb_player.cards = {}
					for i=1,5 do
						--pb_player.cards[i] = b_player.cards[i]
						pb_player.cards[i] = -1
					end
					--pb_player.cards[5] = -1
				else
					pb_player.cards = self.b_player[l_player.guid].cards
				end
			end

			table.insert(notify.pb_player, pb_player)
		end
	else
		for _key, b_player in pairs(self.b_end_player) do
			notify.pb_player = b_player
			local l_player = self:get_player(b_player.chair)
			notify.pb_player.guid = l_player.guid
			notify.pb_player.name = l_player.nickname
			notify.pb_player.icon =  l_player:get_header_icon()
			notify.pb_player.ratio = self.b_player[l_player.guid].ratio
			notify.pb_player.position = l_player.guid == self.b_classics.guid and 1 or -1
			notify.pb_player.bet_money = self.b_player[l_player.guid].bet
			notify.pb_player.ip_area = l_player.ip_area
			notify.pb_player.bet_times = self.b_player[l_player.guid].bet_times
			if l_player.guid == player.guid and next(b_player.cards) ~= nil then
				if self.b_status < STATUS_SHOW_CARD then
					notify.pb_player.cards = {}
					for i=1,5 do
						--notify.pb_player.cards[i] = self.b_player[l_player.guid].cards[i]
						notify.pb_player.cards[i] = -1
					end
					--notify.pb_player.cards[5] = -1
				else
					notify.pb_player.cards =self.b_player[l_player.guid].cards
				end
			end
		end
	end

	if self.b_status > STATUS_BET then
		for _key, b_player in ipairs(notify.pb_player) do
			if self.b_status < STATUS_SHOW_CARD then
				notify.pb_player[_key].cards = {}
				for i=1,5 do
					--notify.pb_player[_key].cards[i] = self.b_player[b_player.guid].cards[i]
					notify.pb_player[_key].cards[i] = -1
				end
				--notify.pb_player[_key].cards[5] = -1
			else
				notify.pb_player[_key].cards = self.b_player[b_player.guid].cards
				notify.pb_player[_key].cards_type = self.b_player[b_player.guid].cards_type and
				self.b_player[b_player.guid].cards_type or CLASSICS_CARD_TYPE_NONE
			end

			if notify.pb_player[_key].cards_type then
				if notify.pb_player[_key].cards_type > CLASSICS_CARD_TYPE_NONE and notify.pb_player[_key].cards_type < CLASSICS_CARD_TYPE_FOUR_KING then
					notify.pb_player[_key].flag = 1
				else
					notify.pb_player[_key].flag = 2
				end
			else
				notify.pb_player[_key].flag = 2
			end
		end
	end

	notify.total_time = self.b_total_time
	if notify.total_time > 0 then
		notify.countdown = math.floor(self.b_timer - get_second_time() + 0.5)
	else
		notify.countdown = 3
		if math.floor(self.b_status) == STATUS_SHOW_CARD then
			notify.total_time = 10
		else
			notify.total_time = 5
		end
	end

	if DEBUG_MODE then
		print("||||||   reconnect info  |||||||||")
		dump(notify)
	end

	if self.b_player[player.guid] then
		self.b_player[player.guid].onTable = true
	end
	notify.pb_Viewer = {}
	for _key, v in pairs(self.players) do
		if v and self.b_player[v.guid] == nil then
			-- 观众
			msg = {
				chair_id = v.chair_id,
				guid = v.guid,
				header_icon = v:get_header_icon(),
				money = v:get_money(),
				ip_area = v.ip_area,
			}
			table.insert(notify.pb_Viewer ,msg)
		end
	end
	notify.bet_options = bet_times_option
	send2client_pb(player, "SC_ClassicsReconnectInfo", notify)


	log.info("set player[%d] in_game true" ,player.guid)
	player.in_game = true
	return
end

--玩家坐下、初始化
function classics_table:player_sit_down(player, chair_id_)
	print("---------------classics_table player_sit_down  -----------------", chair_id_)
	for i,v in pairs(self.players) do
		if v == player then
			player:on_stand_up(self.table_id_, v.chair_id, GAME_SERVER_RESULT_SUCCESS)
			return
		end
	end

	player.table_id = self.table_id_
	player.chair_id = chair_id_
	player.room_id = self.room_.id
	self.players[chair_id_] = player

	if self.b_timer <= get_second_time() + 1 and self.b_status == STATUS_WAITING then
		self.b_timer = get_second_time() + 1
	end

	log.info(string.format("GameInOutLog,banker_table:player_sit_down, guid %s, room_id %s, table_id %s, chair_id %s",
	tostring(player.room_id),tostring(player.guid),tostring(player.table_id),tostring(player.chair_id)))
end


function classics_table:sit_on_chair(player, _chair_id)
	print ("get_sit_down-----------------  classics_table   ----------------")
	self:playerReady(player)
end

function classics_table:in_classics(player)
	-- body
	if self.b_player[player.guid] then
		return true
	end
	return false
end

function classics_table:playerReady( player )
	-- body
	if player then
		if player.ready == true and self.b_player[player.guid] then
			log.info("player already guid[%d] status[%f]" ,player.guid , self.b_status)
			return
		end
		log.info("playerReady guid[%d] status[%f]" ,player.guid , self.b_status)
		--if self.b_status ~= STATUS_WAITING then
		--	return
		--end
		if self.b_table_busy == 1 and player.classics_enterflag == nil and self.b_status ~= STATUS_WAITING then
			log.info("room[%d] table[%d] player[%d] in table but game in player , wait game end",self.room_.id, self.table_id_ , player.guid)
			player.classics_enterflag = true
			send2client_pb(player, "SC_ClassicsTableMatching", {})
			self:reconnect(player)
			return
		elseif self.b_table_busy == 1 and player.classics_enterflag == true and self.b_status ~= STATUS_WAITING then
			if player.is_player ~= false then
				log.error("playerReady error player classics_enterflag is true guid[%d]",player.guid)
			end
			player:forced_exit()
			return
		end
	else
		print("classics_table:playerReady player is nil")
		return
	end
	player.enterTime = nil
	log.info("classics_table:playerReady room[%d] table[%d] chair[%d] player[%d]",self.room_.id, self.table_id_ , player.chair_id, player.guid)
	self.b_player[player.guid] = {
		guid = player.guid,
		chair = player.chair_id,
		cards = {},
		status = PLAYER_STATUS_READY,
		position = POSITION_NORMAL,
		bet = 0,
		ratio = -1,
		show_card = 0,
		cards_type = CLASSICS_CARD_TYPE_NONE,
		onTable = true,
		bet_times = 1
	}
	player.classics_enterflag = nil
	send2client_pb(player, "SC_ClassicsTableMatching", {})
	--self.b_timer = get_second_time() + ACTION_INTERVAL_TIME
	self.b_player_count = self.b_player_count + 1
	if  self.b_player_count > 1 and self.b_player_count < 6 then
		--self.b_timer = get_second_time() + 5
		--if self.b_player_count >= 2 then
			local msg = {
				s_start_time = self.b_timer - get_second_time() - 1
			}

			send2client_pb(player,"SC_StartCountdown_Ox", msg)
			log.info("---------------------------------------------self.b_player_count:[%d]",self.b_player_count)
		--end
	else
		self.b_timer = get_second_time()
	end
	player.ready = true
	log.info("room[%d] table[%d] player_num[%d]",self.room_.id, self.table_id_ , self.b_player_count)


	if player.is_player ~= false  then
		for i, v in ipairs(self.players) do
			if v then
				if type(v) == "table" and v.is_player == false and not self.b_player[v.guid] then
					self:playerReady(v)
				end
			end
		end
	end
end

function classics_table:check_reEnter(player, chair_id)
	local room_limit = self.room_:get_room_limit()
	local l_money = player:get_money()
	player:check_forced_exit(room_limit)
	if  l_money < room_limit then
		local msg = {}
		msg.reason = "金币不足，请您充值后再继续"
		msg.num = room_limit
		send2client_pb(player, "SC_ClassicsForceToLeave", msg)
		player:forced_exit()

		if DEBUG_MODE then
			print ("-------forced to leave ------------")
			dump(msg)
		end
	else
		for i, v in ipairs(self.players) do
			if v then
				if type(v) == "table" and v.is_player == false and not self.b_player[v.guid] then
					self:playerReady(v)
				end
			end
		end
		self:playerReady(player)
	end
end

--玩家站起离开房间
function classics_table:player_stand_up(player, is_offline)
	log.info(string.format("GameInOutLog,classics_table:player_stand_up, guid %s, table_id %s, chair_id %s, is_offline %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id),tostring(is_offline)))

	log.info("!!!!!-----------STAND_UPPPP --------------guid[%d] chair[%d] isoffline[%s] status[%s]" ,player.guid, player.chair_id, tostring(is_offline),tostring(self.b_status))


	local notify = {
		table_id = player.table_id,
		chair_id = player.chair_id,
		guid = player.guid,
	}
    if self.b_status == STATUS_WAITING or self.b_status == STATUS_OVER or self.b_player[player.guid] == nil then
		if base_table.player_stand_up(self,player,is_offline) then

--			local notify = {
--					room_id = player.room_id,
--					guid = player.guid,
--			}
--			--self.room_:player_exit_room(player)
--			self.room_:foreach_by_player(function (p)
--				if p and p.guid ~= player.guid then
--					p:on_notify_exit_room(notify)
--				end
--			end)

--			tb:foreach(function (p)
--				p:on_notify_stand_up(notify)
--			end)

			self:robot_leave(player)
			if self.b_player[player.guid]  then
				self.b_player[player.guid] = nil
				self.b_player_count = self.b_player_count - 1
				if self.b_player_count < 1 then
					self:reset()
				end
				if (self.b_status == STATUS_WAITING or self.b_status == STATUS_OVER) and self.b_table_busy == 1 and self.b_player_count < 2 then
					log.info("roomid[%d] ,table_id[%s], chair_id [%s] ,status[%s], player_count[%d]" ,tostring(player.room_id), tostring(player.table_id) , tostring(player.chair_id), tostring(self.b_status) ,self.b_player_count)
					self.b_table_busy = 0
						self:t_broadcast("SC_StartCountdown_Ox", nil)
				end
				print("self.b_player[player.guid]   is  true")
			else
				print("self.b_player[player.guid]   is  false")
			end
			return true
		else
			log.info("player [%d] can not standup",player.guid)
			return false
		end
	else
		-- 掉线
		log.info("set player[%d] in_game false" ,player.guid)
		player.is_offline = true
		player.in_game = false
		self.b_player[player.guid].onTable = false
		return false
	end
end
--玩家掉线处理
function  classics_table:player_offline( player )
	log.info("classics_table:player_offline")
	player.isTrusteeship = false
	player.in_game = false

	log.info("player is offline true [%d]",player.guid)
	player.is_offline = true
end
function classics_table:check_cancel_ready(player, is_offline)
	base_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if self.b_status > STATUS_WAITING and self.b_status < STATUS_OVER  and self.b_player[player.guid] ~= nil then
		--掉线
		if  is_offline then
			--掉线处理
			self:player_offline(player)
		end
		return false
	end
	--退出
	return true
end


function classics_table:player_leave(player)
	print ("player_leave-----------------  texase   ----------------")
	if self.b_status > STATUS_WAITING and self.b_status < STATUS_OVER then
		log.warning("player [%s] player_leave status[%f] return " , tostring(player.guid), self.b_status)
		return
	end
	local notify = {
			table_id = player.table_id,
			chair_id = player.chair_id,
			guid = player.guid,
			is_offline = false,
	}
	base_table.player_stand_up(self,player,false)
	self:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)
	self.room_:player_exit_room(player)


	self:robot_leave(player)
	if self.b_player[player.guid]  then
		self.b_player[player.guid] = nil
		self.b_player_count = self.b_player_count - 1
		if self.b_player_count < 1 then
			self:reset()
		end
		if (self.b_status == STATUS_WAITING or self.b_status == STATUS_OVER) and self.b_table_busy == 1 and self.b_player_count < 2 then
			log.info("roomid[%d] ,table_id[%s], chair_id [%s] ,status[%s], player_count[%d]" ,tostring(player.room_id), tostring(player.table_id) , tostring(player.chair_id), tostring(self.b_status) ,self.b_player_count)
			self.b_table_busy = 0
		end
		print("self.b_player[player.guid]   is  true")
	else
		print("self.b_player[player.guid]   is  false")
	end
end


function classics_table:t_broadcast(ProtoName, msg)
	for _guid, player in pairs(self.players) do
		if player and not player.is_offline then
			print("t_broadcast",ProtoName)
			send2client_pb(player, ProtoName, msg)
		end
	end
end


-- 判断是否游戏中
function  classics_table:is_play( )
	-- body
	if self.b_status > STATUS_WAITING then
		print("is_play  return true")
		return true
	else
		return false
	end
end


function classics_table:player_quest_last_record(player)
 	-- body
 	local msg = {
		pb_record ={}
	}
	local flag = 0
	for i, v in pairs(self.last_score_record) do
		if v and v.guid == player.guid then
			flag = 1
			break
		end
	end
	if flag == 1 then
		for i, v in pairs(self.last_score_record) do
			if v then
				table.insert(msg.pb_record,v)
			end
		end
		send2client_pb(player,"SC_ClassicsLastRecord",msg)
	else
		send2client_pb(player,"SC_ClassicsLastRecord",{})
	end
 end


--黑名单处理
function classics_table:check_black_user()
	--检查概率
	if self.black_rate < random.boost_integer(1,100) then
		return
	end

	--log.error("start exchange black player cards.........................")
	--for _guid, b_player in pairs(self.b_player) do
	--	local player = self:get_player(b_player.chair)
	--	if player then
	--		log.info("player guid[%d] chair_id[%d]",player.guid,player.chair_id)
	--		log.info(table.concat(self.b_player[player.guid].cards, ',')
	--	end
	--end
	--获取最大牌型
	-- local max_chair_id = 0
	-- local max_cards_type = {}
	-- local max_player_cards_guid = 0
--
	-- for _guid, _player in pairs(self.b_player) do
	-- 	if _player then
	-- 		local ox_type_,value_list_,color_, extro_num_, sort_cards_ = get_cards_type(self.b_player[_guid].cards)
	-- 		local times = get_type_times(ox_type_,extro_num_)
	-- 		local cur_cards_type = {ox_type = ox_type_,val_list = value_list_, color = color_,cards_times = times }
	-- 		if max_chair_id == 0 then
	-- 			max_chair_id = _player.chair
	-- 			max_cards_type = cur_cards_type
	-- 			max_player_cards_guid = _guid
	-- 		elseif compare_cards(cur_cards_type, max_cards_type) then
	-- 			max_chair_id = _player.chair
	-- 			max_cards_type = cur_cards_type
	-- 			max_player_cards_guid = _guid
	-- 		end
	-- 	end
	-- end
--
	-- if max_player_cards_guid == 0 or not self.b_player[max_player_cards_guid].cards then
	-- 	log.error("get max_player_cards_guid or max cards error.")
	-- 	return
	-- end
--
	-- log.info("max_player_cards_guid--------->[%d] chair_id = [%d]", max_player_cards_guid,max_chair_id)
	-- log.info(table.concat(self.b_player[max_player_cards_guid].cards, ',')
--
	-- local white_players = {}
	-- for _guid, _player in pairs(self.b_player) do
	-- 	local player = self:get_player(_player.chair)
	-- 	if player and self:check_blacklist_player(player.guid) == false then
	-- 		table.insert(white_players,player)
	-- 		if max_chair_id == player.chair_id then
	-- 			--最大牌已经在非黑名单玩家手里
	-- 			log.info("max cards belong to while player guid[%d] chair_id[%d]",player.guid,player.chair_id)
	-- 			return
	-- 		end
	-- 	end
	-- end
	-- --不存在白名单玩家
	-- if #white_players == 0 then
	-- 	log.info("this game is not white player, all are black list players.")
	-- 	return
	-- end
--
	-- 	--随机一个白名单玩家
	-- local player_info  = white_players[random.boost_integer(1,#white_players)]
	-- if not player_info then
	-- 	return
	-- end
	-- log.info("exchange white players guid[%d] chair_id[%d]", player_info.guid, player_info.chair_id)
	-- log.info(table.concat(self.b_player[player_info.guid].cards, ',')
--
--
	-- local swap_player_info_cards = {}
	-- swap_player_info_cards = deepcopy_table(self.b_player[player_info.guid].cards)
	-- self.b_player[player_info.guid].cards = {}
	-- self.b_player[player_info.guid].cards = deepcopy_table(self.b_player[max_player_cards_guid].cards)
	-- self.game_log.players[player_info.chair_id].cards = self.b_player[player_info.guid].cards
	-- log.info("white players guid[%d] chair_id[%d]", player_info.guid, player_info.chair_id)
	-- log.info(table.concat(self.b_player[player_info.guid].cards, ',')
--
--
	-- self.b_player[max_player_cards_guid].cards = {}
	-- self.b_player[max_player_cards_guid].cards = deepcopy_table(swap_player_info_cards)
	-- self.game_log.players[max_chair_id].cards = self.b_player[max_player_cards_guid].cards
	-- log.info("black list players guid[%d] chair_id[%d]", max_player_cards_guid, max_chair_id)
	-- log.info(table.concat(self.b_player[max_player_cards_guid].cards, ',')

--	log.error("after exchange black player cards.........................")
--	for _guid, b_player in pairs(self.b_player) do
--		local player = self:get_player(b_player.chair)
--		if player then
--			log.info("player guid[%d] chair_id[%d]",player.guid,player.chair_id)
--			log.info(table.concat(self.b_player[player.guid].cards, ',')
--		end
--	end

    --计算机器人是否为最大牌型
	local max_cards_in_black_player = false
	local min_cards_in_white_player = false

	--运算所有玩家牌类型
	self:run_cards_type()
	local max_chair_id, min_chair_id = self:robot_start_game()
	local player_white_list_temp = {}
	local player_black_list_temp = {}
	local max_cards_player_info = {
		chair_id = max_chair_id,
		guid = nil
	}
	local min_cards_player_info = {
		chair_id = min_chair_id,
		guid = nil
	}

	for k,v in pairs(self.b_player) do
		if v then
			if self:check_blacklist_player(v.guid) == false then
				table.insert(player_white_list_temp,v)
				if v.chair == min_chair_id then
					min_cards_in_white_player = true
					min_cards_player_info.guid = v.guid
				end
			else
				table.insert(player_black_list_temp,v)
				if v.chair == max_chair_id then
					max_cards_in_black_player = true
					max_cards_player_info.guid = v.guid
				end
			end
		end
	end

	if #player_white_list_temp == 0 or #player_black_list_temp == 0 then
		print("-----------------------------------------------2 ",#player_white_list_temp,#player_black_list_temp)
		return
	end

	log.info(string.format("max_cards_in_black_player [%s] min_cards_in_white_player[%s] max_chair_id[%d] max_guid[%s] min_chair_id[%d] min_guid[%s]"
		,tostring(max_cards_in_black_player),tostring(min_cards_in_white_player),max_cards_player_info.chair_id,tostring(max_cards_player_info.guid),min_cards_player_info.chair_id,tostring(min_cards_player_info.guid)))
	print("player_white_list_temp")
	for _,v in pairs(player_white_list_temp) do
		print(v.guid,v.chair)
	end
	print("player_black_list_temp")
	for _,v in pairs(player_black_list_temp) do
		print(v.guid,v.chair)
	end
	--换牌
	if max_cards_in_black_player and min_cards_in_white_player then
		-- 最大牌在黑名单玩家手中 最小牌在白名单玩家手中

		local swap_player_info_cards = {}
		local player_info = {
			guid = min_cards_player_info.guid,
			chair_id = min_cards_player_info.chair_id,
		}
		swap_player_info_cards = deepcopy_table(self.b_player[player_info.guid].cards)
		self.b_player[player_info.guid].cards = {}
		self.b_player[player_info.guid].cards = deepcopy_table(self.b_player[max_cards_player_info.guid].cards)
		self.game_log.players[player_info.chair_id].cards = self.b_player[player_info.guid].cards
		log.info("white players guid[%d] chair_id[%d]", player_info.guid, player_info.chair_id)
		log.info(table.concat(self.b_player[player_info.guid].cards, ','))


		self.b_player[max_cards_player_info.guid].cards = {}
		self.b_player[max_cards_player_info.guid].cards = deepcopy_table(swap_player_info_cards)
		self.game_log.players[max_cards_player_info.chair_id].cards = self.b_player[max_cards_player_info.guid].cards
		log.info("black list players guid[%d] chair_id[%d]", max_cards_player_info.guid, max_cards_player_info.chair_id)
		log.info(table.concat(self.b_player[max_cards_player_info.guid].cards, ','))

	elseif max_cards_in_black_player then
		-- 最大牌在黑名单玩家手中
		local swap_player_info_cards = {}
		local player_temp = player_white_list_temp[random.boost_integer(1,#player_white_list_temp)]
		local player_info = {
			guid = player_temp.guid,
			chair_id = player_temp.chair,
		}
		swap_player_info_cards = deepcopy_table(self.b_player[player_info.guid].cards)
		self.b_player[player_info.guid].cards = {}
		self.b_player[player_info.guid].cards = deepcopy_table(self.b_player[max_cards_player_info.guid].cards)
		self.game_log.players[player_info.chair_id].cards = self.b_player[player_info.guid].cards
		log.info("white players guid[%d] chair_id[%d]", player_info.guid, player_info.chair_id)
		log.info(table.concat(self.b_player[player_info.guid].cards, ','))


		self.b_player[max_cards_player_info.guid].cards = {}
		self.b_player[max_cards_player_info.guid].cards = deepcopy_table(swap_player_info_cards)
		self.game_log.players[max_cards_player_info.chair_id].cards = self.b_player[max_cards_player_info.guid].cards
		log.info("black list players guid[%d] chair_id[%d]", max_cards_player_info.guid, max_cards_player_info.chair_id)
		log.info(table.concat(self.b_player[max_cards_player_info.guid].cards, ','))

	elseif min_cards_in_white_player then
		-- 最小牌在白名单玩家手中
		local swap_player_info_cards = {}
		local player_temp = player_black_list_temp[random.boost_integer(1,#player_black_list_temp)]
		local player_info = {
			guid = player_temp.guid,
			chair_id = player_temp.chair,
		}
		swap_player_info_cards = deepcopy_table(self.b_player[player_info.guid].cards)
		self.b_player[player_info.guid].cards = {}
		self.b_player[player_info.guid].cards = deepcopy_table(self.b_player[min_cards_player_info.guid].cards)
		self.game_log.players[player_info.chair_id].cards = self.b_player[player_info.guid].cards
		log.info("white players guid[%d] chair_id[%d]", player_info.guid, player_info.chair_id)
		log.info(table.concat(self.b_player[player_info.guid].cards, ','))


		self.b_player[min_cards_player_info.guid].cards = {}
		self.b_player[min_cards_player_info.guid].cards = deepcopy_table(swap_player_info_cards)
		self.game_log.players[min_cards_player_info.chair_id].cards = self.b_player[min_cards_player_info.guid].cards
		log.info("black list players guid[%d] chair_id[%d]", min_cards_player_info.guid, min_cards_player_info.chair_id)
		log.info(table.concat(self.b_player[min_cards_player_info.guid].cards, ','))
	end
end


 function deepcopy_table(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then

            return lookup_table[object]
        end  -- if
        local new_table = {}
        lookup_table[object] = new_table


        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end


--AI
--陪玩机器人初始化
function classics_table:init_robot_random( )
	self.robot_strategy = {--机器人抢桩策略
	good_cards = {
	[0] = 20,
	[1] = 20,
	[2] = 20,
	[3] = 20,
	[4] = 20
	},
	bad_cards = {
	[0] = 20,
	[1] = 20,
	[2] = 20,
	[3] = 20,
	[4] = 20}
	}
	self.robot_bet = {
	good_cards = {
	[1] = 25,
	[2] = 25,
	[3] = 25,
	[4] = 25
	},
	bad_cards = {
	[1] = 25,
	[2] = 25,
	[3] = 25,
	[4] = 25}
	}
end
function classics_table:robot_init()
	self.robot_enter_time = 0 --进入时间
	self.robot_info = {} --机器人
	self.robot_islog = false --是否记录机器人产生的日志
	self.robot_switch = 0 --机器人开关
	self:init_robot_random()
	self:run_rob_ramdom_value()
	self.robot_change_card = 50
end

function classics_table:run_rob_ramdom_value()
	local value = 0
 	for i = 0, 4 do
 		self.robot_strategy.good_cards[i] = value + self.robot_strategy.good_cards[i]
 		value = self.robot_strategy.good_cards[i]
 	end
 	value = 0
 	for i = 0, 4 do
 		self.robot_strategy.bad_cards[i] = value + self.robot_strategy.bad_cards[i]
 		value = self.robot_strategy.bad_cards[i]
 	end
 	value = 0
 	for i = 1, 4 do
 		self.robot_bet.good_cards[i] = value + self.robot_bet.good_cards[i]
 		value = self.robot_bet.good_cards[i]
 	end
 	value = 0
 	for i = 1, 4 do
 		self.robot_bet.bad_cards[i] = value + self.robot_bet.bad_cards[i]
 		value = self.robot_bet.bad_cards[i]
 	end
end

function classics_table:islog(guid)
	if guid > 0 then
		return true
	end
	print ("----------------------------------robot_islog",self.robot_islog)
	return self.robot_islog
end

--检查时否可以加入陪玩机器人
function classics_table:check_robot_enter()
	if self.robot_switch ~= 1 then
		return
	end
	local curtime = get_second_time()
	if self.robot_enter_time <= curtime or self:get_robot_num() < 2 then
		--每10秒检查一次
		self.robot_enter_time = get_second_time() + random.boost_integer(2,5) + 5
		if self:get_robot_num() < 3 and self:get_player_count() < 5 then
			--添加一个机器人
			local ap =  self:get_robot()
			if ap then
				for i,p in pairs(self.players) do
					if p == nil or p == false then
						ap:think_on_sit_down(self.room_.id, self.table_id_, i)
						--self:player_sit_down(ap,i)
						self:playerReady(ap)
						break
					end
				end
			end
		end
	end
end

--检查陪玩机器人离开
function classics_table:check_robot_leave()
	local leave ={}
	if self.robot_switch == 1 then
		for _,v in pairs(self.robot_info) do
			if v.is_use then
				v.android.cur = v.android.cur + 1
				log.info("self.room_:get_room_limit() %d v.android:get_money() %d  guid %d",self.room_:get_room_limit() , v.android:get_money() ,v.android.guid)
				if v.android.cur >= v.android.round or self.room_:get_room_limit() > v.android:get_money() then
					table.insert(leave,v.android)
				end
			end
		end
	else
		for _,v in pairs(self.robot_info) do
			if v.is_use then
				v.android.cur = v.android.cur + 1
				table.insert(leave,v.android)
			end
		end
	end
	for _,v in pairs(leave) do
		if v.table_id and v.chair_id then

			local notify = {
					table_id = v.table_id,
					chair_id = v.chair_id,
					guid = v.guid,
				}
			self:player_stand_up(v, false)
			self:foreach(function (p)
				p:on_notify_stand_up(notify)
			end)

			self.room_:player_exit_room(v)
			self.robot_enter_time = get_second_time() + 10
		end
	end
end

--获取陪玩机器人数量
function classics_table:get_robot_num()
	local num = 0
	for i, p in pairs(self.players) do
		if p and p.is_player == false then
			num = num + 1
		end
	end
	return num
end

--创建一个陪玩机器人
function classics_table:get_robot()
	if #self.robot_info < 3 then
		local guid = 0 - #self.robot_info - 1
		local android_player = classics_android:new()
		local account  =  "android_"..tostring(guid)
		local nickname =  "android_"..tostring(guid)
		android_player:init(self.room_.id, guid, account, nickname)
		android_player:set_table(self)
		local info = {}
		info.is_use = false
		info.android = android_player
		table.insert(self.robot_info,info)
		self:reset_robot(android_player)
	end
	for _,v in pairs(self.robot_info) do
		if v.is_use == false then
			self:reset_robot(v.android)
			v.is_use = true
			return v.android
		end
	end
	return nil
end

--重置机器人
function classics_table:reset_robot(android)
	if android.is_player then
		return
	end
	android.round = random.boost_integer(3,6)
	android.cur = 0
	android.money = self.room_:get_room_limit() * random.boost_integer(2,20)
	--if def_second_game_type == 1 then
	--	android.money = random.boost_integer(120,500) * 100 + random.boost_integer(0,100)
	--elseif def_second_game_type == 2 then
	--	android.money = random.boost_integer(120,500) * 100 + random.boost_integer(0,100)
	--elseif def_second_game_type == 3 then
	--	android.money = random.boost_integer(400,800) * 100 + random.boost_integer(0,100)
	--elseif def_second_game_type == 4 then
	--	android.money = random.boost_integer(1300,2900) * 100 + random.boost_integer(0,100)
	--elseif def_second_game_type == 5 then
	--	android.money = random.boost_integer(2300,3800) * 100 + random.boost_integer(0,100)
	--else
	--	android.money = self.room_:get_room_limit() * random.boost_integer(100,200)
	--end
	log.info("def_second_game_type %d , android.money [%d] " ,def_second_game_type , android.money)
	android:reset_show()
end

--释放机器人
function classics_table:robot_leave(android)
	if android.is_player then
		return
	end
	for _,v in pairs(self.robot_info) do
		if v.android.guid == android.guid then
			v.is_use = false
		end
	end
end

--计算机器人牌型大小
function classics_table:robot_start_game()
	local max_chair_id = 0
	local mix_chair_id = 0
	local temp = nil
	local temp_bplayer = nil
	for _guid, b_player in pairs(self.b_player) do
		if b_player.cards then
			if temp == nil then
				temp = self.b_ret[_guid]
				temp_bplayer = b_player
			else
				local win = compare_cards(self.b_ret[_guid], temp)
				if win == true then
					temp = self.b_ret[_guid]
					temp_bplayer = b_player
				end
			end
		end
	end
	if temp_bplayer ~= nil then
		max_chair_id = temp_bplayer.chair
	else
		log.error("robot_start_game error no max_bplayer")
	end

	for _,v in pairs(self.robot_info) do
		v.android:set_maxcards(false)
		if v.is_use and v.android.chair_id == max_chair_id then
			v.android:set_maxcards(true)
		end
	end

	--	计算最小牌型
	temp = nil
	temp_bplayer = nil
	for _guid, b_player in pairs(self.b_player) do
		if b_player.cards then
			if temp == nil then
				temp = self.b_ret[_guid]
				temp_bplayer = b_player
			else
				local win = compare_cards(self.b_ret[_guid], temp)
				if win == false then
					temp = self.b_ret[_guid]
					temp_bplayer = b_player
				end
			end
		end
	end
	if temp_bplayer ~= nil then
		mix_chair_id = temp_bplayer.chair
	else
		log.error("robot_start_game error no max_bplayer")
	end

	for _,v in pairs(self.robot_info) do
		v.android:set_mixcards(false)
		if v.is_use and v.android.chair_id == mix_chair_id then
			v.android:set_mixcards(true)
		end
	end

	self.robot_islog = false
	for _,v in pairs(self.players) do
		if v and v.is_player then
			self.robot_islog = true
			break
		end
	end
	return max_chair_id, mix_chair_id
end

-- 机器人抢桩
function classics_table:start_contend_timer(time,player)
	local function contend_func()
		local r = random.boost_integer(1,100)
		local ratio = 0
		if player:is_max() then
			--抢桩
			if r < self.robot_strategy.good_cards[0] then
				ratio = -1
			elseif r < self.robot_strategy.good_cards[1] then
				ratio = 1
			elseif r < self.robot_strategy.good_cards[2] then
				ratio = 2
			elseif r < self.robot_strategy.good_cards[3] then
				ratio = 3
			else
				ratio = 4
			end
		else
			--抢桩
			if r < self.robot_strategy.bad_cards[0] then
				ratio = -1
			elseif r < self.robot_strategy.bad_cards[1] then
				ratio = 1
			elseif r < self.robot_strategy.bad_cards[2] then
				ratio = 2
			elseif r < self.robot_strategy.bad_cards[3] then
				ratio = 3
			else
				ratio = 4
			end
		end
		self:classics_contend(player, ratio)
	end
	add_timer(time,contend_func)
end

-- 闲家下注
function classics_table:start_begin_to_bet_timer(time,player)
	--闲家下注
	if self.b_classics.chair == player.chair_id then
		return
	end
	local function begin_to_bet_func()
		local r = random.boost_integer(1,100)
		local bet_times = 1
		if player:is_max() then
			--下注
			if r < self.robot_bet.good_cards[1] then
				bet_times = bet_times_option[4]
			elseif r < self.robot_bet.good_cards[2] then
				bet_times = bet_times_option[3]
			elseif r < self.robot_bet.good_cards[3] then
				bet_times = bet_times_option[2]
			else
				bet_times = bet_times_option[1]
			end
		else
			--下注
			if r < self.robot_bet.bad_cards[1] then
				bet_times = bet_times_option[4]
			elseif r < self.robot_bet.bad_cards[2] then
				bet_times = bet_times_option[3]
			elseif r < self.robot_bet.bad_cards[3] then
				bet_times = bet_times_option[2]
			else
				bet_times = bet_times_option[1]
			end
		end
		local msg = {bet_money = 0, bet_times = bet_times}
		self:classics_bet(player, msg)
	end
	add_timer(time,begin_to_bet_func)
end

-- 猜牌
function classics_table:start_guess_cards_timer(time,player)
	local function begin_tguess_cards_func()
		self:classics_guess_cards(player)
	end
	add_timer(time,begin_tguess_cards_func)
end

return classics_table