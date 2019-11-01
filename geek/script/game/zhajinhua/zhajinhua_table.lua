-- 炸金花逻辑

local pb = require "pb_files"
local log = require "log"

require "data.zhajinhua_data"
local broadcast_money = broadcast_money

local base_table = require "game.lobby.base_table"
local random = require("random")

require "timer"
local add_timer = add_timer

require "game.zhajinhua.zhajinhua_robot"
local zhj_android = zhj_android

local redisopt = require "redisopt"

local reddb = redisopt.default

-- enum ZHAJINHUA_CARD_TYPE
local ZHAJINHUA_CARD_TYPE_SPECIAL = pb.enum("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SPECIAL")
local ZHAJINHUA_CARD_TYPE_SINGLE = pb.enum("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SINGLE")
local ZHAJINHUA_CARD_TYPE_DOUBLE = pb.enum("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_DOUBLE")
local ZHAJINHUA_CARD_TYPE_SHUN_ZI = pb.enum("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_ZI")
local ZHAJINHUA_CARD_TYPE_JIN_HUA = pb.enum("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_JIN_HUA")
local ZHAJINHUA_CARD_TYPE_SHUN_JIN = pb.enum("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_JIN")
local ZHAJINHUA_CARD_TYPE_BAO_ZI = pb.enum("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_BAO_ZI")
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_MAINTAIN = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
local LOG_MONEY_OPT_TYPE_ZHAJINHUA = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_ZHAJINHUA")

local PLAYER_STAND = -1         -- 观战
local PLAYER_FREE = 0           -- 空闲
local PLAYER_READY = 1          -- 准备
local PLAYER_WAIT = 2           -- 等待下注
local PLAYER_CONTROL = 3        -- 准备操作
local PLAYER_LOOK = 4           -- 看牌
local PLAYER_COMPARE = 5        -- 比牌
local PLAYER_DROP = 6           -- 弃牌
local PLAYER_LOSE = 7           -- 淘汰
local PLAYER_EXIT = 8           -- 离开

local zhajinhua_prize_pool = g_prize_pool

-- enum ITEM_PRICE_TYPE
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

--游戏准备时间
local ZHAJINHUA_TIMER_READY = 11

-- 等待开始
local ZHAJINHUA_STATUS_FREE = 1
-- 游戏准备开始
local ZHAJINHUA_STATUS_READY =  2
-- 游戏进行
local ZHAJINHUA_STATUS_PLAY = 3


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

-- 得到牌大小
local function get_value(card)
	return math.floor(card / 4)
end

-- 得到牌花色
local function get_color(card)
	return card % 4
end
-- 0：方块2，1：梅花2，2：红桃2，3：黑桃2 …… 48：方块A，49：梅花A，50：红桃A，51：黑桃A



local zhajinhua_table = base_table:new()
--错误
function XXXX_XXXXX()
	print("XXXXXXXXXXXXXXXXXX")
	for i, v in ipairs(t) do
	end
end
-- 初始化
function zhajinhua_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.status = ZHAJINHUA_STATUS_FREE
	self.is_compare_card_flag = false
    self.chair_count = chair_count
	self.cards = {}
	self.add_score_ = {}
	self.player_online = {}
	self.Round = 1
	self.Round_Times = 1
    self.dead_count_ = 0
	self.is_dead_ = {} -- 放弃或比牌输了
	self.max_add_score_ = 0
	self.allready = false
	self.ready_count_down = 12
	self.show_card_list = {}
	self.basic_config_coeff = {}
	self.last_record = {} --上局回放
	self.black_rate = 0 --黑名单换牌概率
	--添加筹码值
	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		elseif def_second_game_type == 99 then
			print("private room is develop................")
		else
			log.error("zhajinhua_table:init def_second_game_type[%d] ", def_second_game_type)
			return
		end
	end
	--basic_config_coeff: 1 基础概率; 2 浮动概率; 3 对子概率; 4 顺子概率; 5 金花概率; 6 顺金概率,7 豹子概率;
	if zhajinhua_room_score[6] ~= nil then
		self.basic_config_coeff = zhajinhua_room_score[6]
		log.info("zhajinhua_table:basic_config_coeff[%d][%d][%d][%d][%d][%d][%d] ", self.basic_config_coeff[1],self.basic_config_coeff[2],self.basic_config_coeff[3],self.basic_config_coeff[4],self.basic_config_coeff[5],self.basic_config_coeff[6],self.basic_config_coeff[7])
		BASIC_COEFF = self.basic_config_coeff[1]
		FLOAT_COEFF = self.basic_config_coeff[2]
		DUIZI_COEFF = self.basic_config_coeff[3]
		SHUNZI_COEFF = self.basic_config_coeff[4]
		JINHUA_COEFF = self.basic_config_coeff[5]
		SHUNJIN_COEFF = self.basic_config_coeff[6]
		BAOZI_COEFF = self.basic_config_coeff[7]
	end

	for i,v in pairs(self.add_score_) do
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end

	self.player_status = {}

	for i = 1, chair_count do
		self.player_status[i] = PLAYER_FREE
		self.player_online[i] = false
		self.show_card_list[i] = {}
		for j = 1, chair_count do
			self.show_card_list[i][j] = false
		end
	end
	for i = 1, 52 do
		self.cards[i] = i - 1
	end

	--[[--test code
	for k=1,10 do
		local test_num = 0
		for i = 1 ,100000 do
			local test_ = {}
			test_ = self:handle_cards()
			local flag = self:check_spec_cards(test_)
			if flag == true then
				test_num = test_num + 1
				--log.info("[%d] check_spec_cards ok.",i)
			end
			if test_num == 100000 then
				log.info("~~~~~~~~~~~~~~times[%d]:[%d] check_spec_cards ok.",k,test_num)
			end
		end
	end
	--]]

	reddb:del(string.format("player:%s_%d_%d",def_game_name,def_first_game_type,def_second_game_type))
	self:robot_init()
end
-- 检查是否可准备
function zhajinhua_table:check_ready(player)
	if self.status ~= ZHAJINHUA_STATUS_FREE and   self.status ~= ZHAJINHUA_STATUS_READY then
		return false
	end
	return true
end
function zhajinhua_table:isDead(player)
	-- body
	if not player then
		return true
	end
	return self.is_dead_[player.chair_id]
end

function zhajinhua_table:can_enter(player)

	if self.status == ZHAJINHUA_STATUS_READY then
		local curtime = get_second_time()
		--最后3秒不准进入，来不及准备
		if (curtime - self.ready_time) >= (self.ready_count_down - 3) or self.allready then
			return false
		end
	end

	if player.vip == 100 then
		return true
	end

	for _,v in ipairs(self.players) do
		if v then
			print("===========judge_play_times")
			if player:judge_ip(v) then
				if not player.ipControlflag then
					print("zhajinhua_table:can_enter ipcontorl change false")
					return false
				else
					-- 执行一次后 重置
					print("zhajinhua_table:can_enter ipcontorl change true")
					return true
				end
			end
		end
	end

	return true
end

-- 检查是否可取消准备
function zhajinhua_table:check_cancel_ready(player, is_offline)
	log.info("check_cancel_ready guid [%d] status [%d] is_offline[%s] isDead[%s]",player.guid and player.guid or 0,self.status,tostring(is_offline),tostring(self.is_dead_[player.chair_id]))
	base_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if self.status == ZHAJINHUA_STATUS_FREE or self.status == ZHAJINHUA_STATUS_READY or
		self.status == ZHAJINHUA_STATUS_PLAY and self.is_dead_[player.chair_id]
		then
		--退出
		print("============true")
		return true
	end
	if is_offline then
		--掉线处理
		self:player_offline(player)
	end
	print("============false")
	return false
end

function zhajinhua_table:all_compare()
	log.info("game_id[%s]------->all compare cards",self.gamelog.table_game_id)
	local player = nil
	local oldcur = self.cur_turn
	local next_player_cur = nil
	for i = 1, self.player_count_, 1 do
		oldcur = self.cur_turn
		player = self.players[self.cur_turn]
		self:next_turn()
		next_player_cur = self.cur_turn
		self.cur_turn = oldcur
		log.info("compare_card:table_id[%d] player guid[%d]",self.table_id_,player.guid)
		local bRet = self:compare_card(player, next_player_cur, true)
		--print("all compare------- bRet:", bRet)
		if bRet == false then
			self:next_turn()
			--self:next_round()
		end
		if self.status ~= ZHAJINHUA_STATUS_PLAY then
			return
		end
	end
end
-- 下一个
function zhajinhua_table:next_turn()
	print("---------------------------------next_turn", #self.ready_list_)
	local old = self.cur_turn
	repeat
		self.cur_turn = self.cur_turn + 1
		if self.cur_turn > #self.ready_list_ then
			self.cur_turn = 1
		end
		if old == self.cur_turn then

			for i = 1, #self.ready_list_ do
				log.error("gameid[%s] self.ready_list_[i] :",self.gamelog.table_game_id, self.ready_list_[i] )
			end

			for i = 1, #self.is_dead_ do
				log.error("gameid[%s] self.is_dead_[i] :",self.gamelog.table_game_id, self.is_dead_[i] )
			end

			log.error("turn error gameid[%s] old is %d  #self.ready_list_ is %d" ,self.gamelog.table_game_id, old, #self.ready_list_)
			log.error("%s",debug.traceback())
			log.error("turn error gameid[%s]",self.gamelog.table_game_id)
			return
		end
	until(self.ready_list_[self.cur_turn] and (not self.is_dead_[self.cur_turn]))
	print("-----------------------------------next_turn end", old, "turn", self.cur_turn )

	--断线运算
	if( (self.status == ZHAJINHUA_STATUS_PLAY ) and (self.player_online[self.cur_turn] == false)) then
		--player = self.players[self.cur_turn]
		--print ("lc  online   check_start-----------------AAAAAAAAAAA")
		--self:give_up(player)
		--self:next_turn()
		--self:next_round()
	end

end

function zhajinhua_table:next_round()
	--运算回合
	if self.status == ZHAJINHUA_STATUS_PLAY and self.Round <= 20 then
		self.Round_Times = self.Round_Times + 1
		--print ("self.Round_Times :", self.Round_Times - 1)
		--print ("self.Round_Times + 1:", self.Round_Times)
		if self.Round_Times > self.Live_Player then
			self.Round = self.Round + 1

			local notify = {
				round = self.Round,
			}

			--超过上限轮数处理
			if self.Round > 20 then
				self:all_compare()
			end
			self.Round_Times = self.dead_count_ + 1

			self:broadcast2client("SC_ZhaJinHuaRound", notify)
		end
	end
end


function zhajinhua_table:check_start(part)
	print ("check_start-----------------AAAAAAAAAAA")
	local n = 0
	local k = 0
	for i, v in ipairs(self.players) do
		if v then
			k = k + 1
			if type(v) == "table" and v.is_player == false then
				self.ready_list_[i] = true
			end
			if self.ready_list_[i] then
				n = n+1
				if self.status ~= ZHAJINHUA_STATUS_PLAY and self.player_status[i] ~= PLAYER_READY then
					self.player_status[i] = PLAYER_READY
				end
			end
		end
	end

	if n == k and n >= 2 and self.status  ~= ZHAJINHUA_STATUS_PLAY then
		print ("--------------------------------allready")
		self.allready = true
	end
	--[[if n >= 2 and self.status == ZHAJINHUA_STATUS_FREE then
		self.status = ZHAJINHUA_STATUS_READY
		self.ready_time = get_second_time()
		if not self.allready  then
			local msg = {
			time = ZHAJINHUA_TIMER_READY,
			}
			self:broadcast2client("SC_ZhaJinHuaStart", msg)
		end
	end]]
	return
end
--
-- 进入房间并坐下
function zhajinhua_table:get_en_and_sit_down(player, room_id_, table_id_, chair_id_, result_, tb)
		print("zhajinhua_table:get_en_and_sit_down =========================1")
		local notify = {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
		}
		print("zhajinhua_table:get_en_and_sit_down =========================2")
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				--money = p:get_money(),
				money = self:get_player_money(p),
				header_icon = p:get_header_icon(),
				ip_area = p.ip_area,
			}
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		print("zhajinhua_table:get_en_and_sit_down =========================3")
		send2client_pb(player, "SC_ZhaJinHuaGetSitDown", notify)
end

function zhajinhua_table:get_sit_down(player)
	log.info("table_id[%d]: player guid[%d]------------->get_sit_down",self.table_id_,player.guid)
	self.player_online[player.chair_id] = true
	player.isTrusteeship = true
	self:set_trusteeship(player,false)
	print ("player.room_id_, player.table_id_, player.chair_id",self.room_.id, self.table_id_, player.chair_id)
	self:get_en_and_sit_down(player, self.room_.id, self.table_id_, player.chair_id, GAME_SERVER_RESULT_SUCCESS, self)
end

-- 重新上线
function zhajinhua_table:reconnect(player)
	if self.gamelog and self.gamelog.table_game_id then
		log.info("zhajinhua_table:game_id[%s] reconnect---------->guid[%d],chair_id[%d]",self.gamelog.table_game_id,player.guid,player.chair_id)
	else
		log.info("zhajinhua_table:reconnect---------->guid[%d],chair_id[%d]",player.guid,player.chair_id)
	end

		for i,v in ipairs(self.players) do
			if v then
				print (v.chair_id)
				print (v, player)
				if v == player then
					local msg = {
					isseecard = true,
					}
					print("send reconnect~~~~~~~~~!")
					send2client_pb(player, "SC_ZhaJinHuaReConnect", msg)
					player.table_id = self.table_id_
					player.room_id = self.room_.id

					local offline = {
					chair_id = player.chair_id,
					turn = self.Round,
					reconnect = true,
					}
					table.insert(self.gamelog.offlinePlayers, offline)
					return
				end
			end
		end
		local msg = {
		isseecard = false,
		}

		send2client_pb(player, "SC_ZhaJinHuaReConnect", msg)
		return
end

--重载注码配置
function zhajinhua_table:require_zhangjinhua_db()
 	package.loaded["data/zhajinhua_data"] = nil
	require "data.zhajinhua_data"

	--添加筹码值
	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		else
			log.error("zhajinhua_table:init def_second_game_type[%d] ", def_second_game_type)
			return
		end
	end
	--basic_config_coeff: 1 基础概率; 2 浮动概率; 3 对子概率; 4 顺子概率; 5 金花概率; 6 顺金概率,7 豹子概率;
	if zhajinhua_room_score[6] ~= nil then
		self.basic_config_coeff = zhajinhua_room_score[6]
		log.info("zhajinhua_table:basic_config_coeff[%d][%d][%d][%d][%d][%d][%d] ", self.basic_config_coeff[1],self.basic_config_coeff[2],self.basic_config_coeff[3],self.basic_config_coeff[4],self.basic_config_coeff[5],self.basic_config_coeff[6],self.basic_config_coeff[7])
		BASIC_COEFF = self.basic_config_coeff[1]
		FLOAT_COEFF = self.basic_config_coeff[2]
		DUIZI_COEFF = self.basic_config_coeff[3]
		SHUNZI_COEFF = self.basic_config_coeff[4]
		JINHUA_COEFF = self.basic_config_coeff[5]
		SHUNJIN_COEFF = self.basic_config_coeff[6]
		BAOZI_COEFF = self.basic_config_coeff[7]
	end
	for i,v in pairs(self.add_score_) do
			print(v)
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end
end
function zhajinhua_table:load_lua_cfg()
	print ("--------------------load_lua_cfg", self.room_.room_cfg)
	log.info("zhajinhua_table:game_switch_is_open ---------------------------->[%s]",self.room_.game_switch_is_open)
	local funtemp = load(self.room_.room_cfg)
	local zhajinhua_room_score,broadcast_money_,robot_switch,black_rate = funtemp()

	if robot_switch ~= nil then
		self.robot_switch = robot_switch
	end

	if black_rate ~= nil then
		self.black_rate = black_rate
	end
	log.info("robot_switch = [%d] black_rate = [%d]", self.robot_switch,self.black_rate)
	broadcast_money = broadcast_money_

	--添加筹码值
	--print (self.room_.room_cfg, zhajinhua_room_score)
	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		elseif def_second_game_type == 99 then
			print("private room is develop................")
		else
			log.error("zhajinhua_table:init def_second_game_type[%d] ", def_second_game_type)
			return
		end
	end
	--basic_config_coeff: 1 基础概率; 2 浮动概率; 3 对子概率; 4 顺子概率; 5 金花概率; 6 顺金概率,7 豹子概率;
	if zhajinhua_room_score[6] ~= nil then
		self.basic_config_coeff = zhajinhua_room_score[6]
		log.info("zhajinhua_table:basic_config_coeff[%d][%d][%d][%d][%d][%d][%d] ", self.basic_config_coeff[1],self.basic_config_coeff[2],self.basic_config_coeff[3],self.basic_config_coeff[4],self.basic_config_coeff[5],self.basic_config_coeff[6],self.basic_config_coeff[7])
		BASIC_COEFF = self.basic_config_coeff[1]
		FLOAT_COEFF = self.basic_config_coeff[2]
		DUIZI_COEFF = self.basic_config_coeff[3]
		SHUNZI_COEFF = self.basic_config_coeff[4]
		JINHUA_COEFF = self.basic_config_coeff[5]
		SHUNJIN_COEFF = self.basic_config_coeff[6]
		BAOZI_COEFF = self.basic_config_coeff[7]
	end
	for i,v in pairs(self.add_score_) do
			print(v)
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end
end


--玩家游戲結束后亮牌給所有玩家
function zhajinhua_table:show_cards_to_all(player,info)
	if info.cards ~= nil then
		local msg = {
			whichplayer = player.guid,
			cards = info.cards
		}
		for i,v in ipairs(self.players) do
			if v and v.guid ~= player.guid then
				send2client_pb(v, "SC_ZhaJinHuaShowCardsToAll",msg)
			end
		end

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

function zhajinhua_table:get_total_bonus_pool(player,msg)
	local total_bonus_ = zhajinhua_prize_pool:get_total_bonus()
	send2client_pb(player, "SC_ZhaJinHuaBonusPool", {
			total_bonus = total_bonus_,
		})
end

-- 做牌
function zhajinhua_table:handle_cards()
	local sp_cards = {}
	local ct_type = {}
	local spnum = random.boost_integer(1,2) + 2 --每一把洗2~3个特殊牌型
	--local spnum = 5
	--好牌碰撞概率
	local baozi_prob = BAOZI_COEFF
	local shunjin_prob = baozi_prob + SHUNJIN_COEFF
	local jinhua_prob = shunjin_prob + JINHUA_COEFF
	local shunzi_prob = jinhua_prob + SHUIZI_COEFF
	for i = 1,spnum do
		local rand_num = random.boost_integer(1,SYSTEM_COEFF)
		local cardtype = ZHAJINHUA_CARD_TYPE_DOUBLE --最低对子

		if rand_num <= baozi_prob then --豹子
			cardtype = ZHAJINHUA_CARD_TYPE_BAO_ZI
		elseif rand_num <= shunjin_prob then --顺金
			cardtype = ZHAJINHUA_CARD_TYPE_SHUN_JIN
		elseif rand_num <= jinhua_prob then --金花
			cardtype = ZHAJINHUA_CARD_TYPE_JIN_HUA
		elseif rand_num <= shunzi_prob then --順子
			cardtype = ZHAJINHUA_CARD_TYPE_SHUN_ZI
		else --對子
			cardtype = ZHAJINHUA_CARD_TYPE_DOUBLE
		end
		ct_type[i] = cardtype
		--print("--------------ct_type:", i, ct_type[i])
	end

	local k = #self.cards
	for j=1,spnum do
		local tempcards = {}
		local isok = false
		local sp_key = random.boost(k) --随机抽取一张牌
		tempcards[1] = self.cards[sp_key]
		if sp_key ~= k then
			self.cards[sp_key], self.cards[k] = self.cards[k], self.cards[sp_key]
		end
		k = k-1
		local first_card = get_value(tempcards[1])
		local first_card_color = get_color(tempcards[1])
		local flag_this_card = 1
		if first_card < 11 then --顺子第一张牌在K以下走正常流程
			flag_this_card = 1
		elseif first_card == 11 then --大于等于K时流程
			flag_this_card = 2
		end

		if ct_type[j] == ZHAJINHUA_CARD_TYPE_DOUBLE then --对子
			local i_index=1
			while ( i_index < k and isok == false) do
				if get_value(tempcards[1]) == get_value(self.cards[i_index]) and get_color(tempcards[1]) ~= get_color(self.cards[i_index]) then
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
				local lastindex = random.boost(k)
				tempcards[3] = self.cards[lastindex]
				if lastindex ~= k then
					self.cards[lastindex], self.cards[k] = self.cards[k], self.cards[lastindex]
				end
				k = k-1
			end
		elseif ct_type[j] == ZHAJINHUA_CARD_TYPE_SHUN_ZI then --顺子
			local n = 2
			if flag_this_card == 1 then
				local i_index=1
				while ( i_index < k and isok == false) do
					if first_card+1 == get_value(self.cards[i_index]) then
						tempcards[n] = self.cards[i_index]
						first_card = get_value(self.cards[i_index])
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
					if first_card-1 == get_value(self.cards[i_index]) then
						tempcards[n] = self.cards[i_index]
						first_card = get_value(self.cards[i_index])
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


		elseif ct_type[j] == ZHAJINHUA_CARD_TYPE_JIN_HUA then --金花
			local m = 2
			local i_index=1
			while ( i_index < k and isok == false) do
				if get_color(tempcards[1]) == get_color(self.cards[i_index]) then
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
		elseif ct_type[j] == ZHAJINHUA_CARD_TYPE_SHUN_JIN then --顺金
			local n = 2
			if flag_this_card == 1 then
				local i_index=1
				while( i_index < k and isok == false ) do
					if first_card+1 == get_value(self.cards[i_index]) and first_card_color == get_color(self.cards[i_index]) then
						tempcards[n] = self.cards[i_index]
						first_card = get_value(self.cards[i_index])
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
					if first_card-1 == get_value(self.cards[i_index]) and first_card_color == get_color(self.cards[i_index]) then
						tempcards[n] = self.cards[i_index]
						first_card = get_value(self.cards[i_index])
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
		elseif ct_type[j] == ZHAJINHUA_CARD_TYPE_BAO_ZI then --豹子
			local m = 2
			local i_index=1
			local check_index = 1
			while( i_index < k and isok == false ) do
				if get_value(tempcards[1]) == get_value(self.cards[i_index]) and  get_color(tempcards[check_index]) ~= get_color(self.cards[i_index]) then
					check_index = check_index + 1
					tempcards[m] = self.cards[i_index]
					if i_index ~= k then
						self.cards[i_index], self.cards[k] = self.cards[k], self.cards[i_index]
					end
					k = k-1
					if m == 3 then
				--[[		if check_index > 2 and get_color(tempcards[1]) ~=  get_color(self.cards[i_index]) then
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
				local in_dex = random.boost(k)
				tempcards[n] = self.cards[in_dex]
				if in_dex ~= k then
					self.cards[in_dex], self.cards[k] = self.cards[k], self.cards[in_dex]
				end
				k = k-1
			end
		end
		table.insert(sp_cards,tempcards)
		--local type, v1, v2, v3 = self:get_cards_type(cards)
	end
	--每局总共做随机2~3首好牌,剩下2首随机洗牌
	local remainder_num = 5 - spnum
	for i=1,remainder_num do
		local remain_cards = {}
		-- 洗牌
		for j=1,3 do
			local r = random.boost(k)
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
		local x = random.boost_integer(1,len)
		local y = random.boost_integer(1,len)
		if x ~= y then
			sp_cards[x], sp_cards[y] = sp_cards[y], sp_cards[x]
		end
		len = len - 1
	end

	return sp_cards
end

-- 0：方块2，1：梅花2，2：红桃2，3：黑桃2 …… 48：方块A，49：梅花A，50：红桃A，51：黑桃A

--校验抽出来的牌型
function zhajinhua_table:check_spec_cards(cards)
	local this_cards = {}
	for i,v in ipairs(cards) do
		for _,z in ipairs(v) do
			table.insert(this_cards,z)
		end
	end
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


-- 开始游戏
function zhajinhua_table:start(player_count)
	for i=1,player_count do
		local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
		log.info(str)
		redis_command(str)
	end
	print("old----", self.tax_show_ , self.tax_open_ ,self.tax_,self.room_limit_, self.cell_score_)
	local bRet = base_table.start(self,player_count)
	if bRet == nil then
		self:clear_ready()
		return
	end
	print (bRet)
	print("new----", self.tax_show_ , self.tax_open_ ,self.tax_,self.room_limit_, self.cell_score_)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.player_count_ = player_count
	self.player_cards_ = {} -- 玩家手里的牌
	self.player_cards_type_ = {}
	self.is_look_card_ = {} -- 是否看过牌
	self.is_dead_ = {} -- 放弃或比牌输了
	self.player_score = {}
	local cell_score = self.cell_score_
	self.last_score = cell_score   --当前单注
	self.player_money = {}
	self.all_money = 0  --总金币
	self.max_score_ = cell_score * 200 --最大筹码
    self.ball_score_ = {}  --是否全压
	self.cur_turn = 1
	self.Round = 1 -- 当前回合
	self.Live_Player = player_count
	self.Round_Times = 1
	self.player_online = {}
	self.ready_time = 0
    self.randomA = random.boost(self.player_count_)
    self.player_status = {}
    self.ball_begin = false     -- 是否开始全压
    self.dead_count_ = 0
    self.player_oldmoney = {}
    self.betscore = {}
    self.betscore_count_ = 1
    self.gamer_player = {}
	self.allready = false
	self.ready_count_down = 12
	self.show_card_list = {}

	self.gamelog = {
		room_id = self.room_.id,
		table_id = self.table_id_,
        start_game_time = get_second_time(),
        end_game_time = 0,
        table_game_id = self:get_now_game_id(),
        win_chair = 0,
        tax = 0,
        banker = 0,
        add_score = {},	--加油
        look_chair = {},  --看牌
        compare = {},   --比牌
        give_up = {}, --弃牌
        playInfo = {},
        offlinePlayers = {},
        cards = {},
        finisgameInfo = {},
        cell_score = self.cell_score_,
        all_money = 0,
    }

    print("cell_score:", cell_score, " self.max_score_:",self.max_score_)

	for i = 1, self.chair_count  do
		self.player_status[i] = PLAYER_FREE
		self.is_look_card_[i] = false
		self.player_online[i] = false
		if self.ready_list_[i] then
			self.is_dead_[i] = false
		else
			self.is_dead_[i] = true
		end
		self.player_money[i] = 0
		self.player_score[i] = 0
		self.player_oldmoney[i] = 0
		self.show_card_list[i] = {}
		for j = 1,  self.chair_count  do
			self.show_card_list[i][j] = false
		end
	end

	for i = 1, self.chair_count  do
		print (self.is_dead_[i], self.ready_list_[i])
	end

	local itemp = 2
	repeat
		self:next_turn()
		itemp = itemp + 1
	until(itemp > self.randomA)

	self.gamelog.banker = self.cur_turn


	-- 发牌
	self.log_guid = ""
	local k = #self.cards
	local chari_list_tp_ = {}
	local guid_list_tp_ = {}
	local spec_cards_flag = false
	local spec_cards = {}
	--log.info("zhajinhua_table:basic_config_coeff[%d][%d][%d][%d][%d][%d] ", self.basic_config_coeff[1],self.basic_config_coeff[2],self.basic_config_coeff[3],self.basic_config_coeff[4],self.basic_config_coeff[5],self.basic_config_coeff[6])
	local good_cards_coeff = random.boost_integer(1,SYSTEM_COEFF)
	if FLOAT_COEFF == nil then
		FLOAT_COEFF = 2
	end
	local float_coeff = random.boost_integer(0,FLOAT_COEFF)
	local this_time_coeff = BASIC_COEFF + float_coeff
	if good_cards_coeff <  this_time_coeff then --满足概率，随机做几副好牌
		spec_cards = self:handle_cards()
		if spec_cards ~= nil  and self:check_spec_cards(spec_cards) ==  true then
			spec_cards_flag = true
		end
	end
	for i,v in ipairs(self.players) do
		if v then
			local cards = {}
			if spec_cards_flag == true then
				cards = spec_cards[i]
			else
				-- 洗牌
				for j=1,3 do
					local r = random.boost(k)
					cards[j] = self.cards[r]
					if r ~= k then
						self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
					end
					k = k-1
				end
			end

			self.player_cards_[i] = cards
			log.info("game_id[%s]:player guid[%d] --------------> cards:[%d,%d,%d]",self.gamelog.table_game_id,v.guid,tonumber(cards[1]),tonumber(cards[2]),tonumber(cards[3]))
			--print ("AAAAAcards1:",cards[1],"cards2:",cards[2],"cards3:",cards[3])
			local type, v1, v2, v3 = self:get_cards_type(cards)
			local item = {cards_type = type}
			print ("AAAAAV1:",v1,"V2:",v2,"V3:",v3)
			if v1 then
				item[1] = v1
			end
			if v2 then
				item[2] = v2
			end
			if v3 then
				item[3] = v3
			end
			self.player_cards_type_[i] = item
			self.player_online[i] = true
			self.ball_score_ [i] = false
			self.player_status[i] = PLAYER_WAIT
			self.log_guid = self.log_guid ..v.guid..":"
			self.gamelog.cards[v.chair_id] =
			{
				chair_id = v.chair_id,
				card = cards,
			}
			v.is_offline = false
			table.insert(chari_list_tp_, v.chair_id)
			table.insert(guid_list_tp_, v.guid)
    		self.gamer_player[v.chair_id] =
    		{
				chair_id = v.chair_id,
				card = cards,
				guid = v.guid,
				phone_type = v.phone_type,
				new_money = v.money,
				ip = v.ip,
				player = v,
				channel_id =  v.create_channel_id,
				money = 0,
				platform_id = v.platform_id,
    		}
			self.gamelog.playInfo[v.chair_id] = {
				chair_id = v.chair_id,
				guid = v.guid,
				old_money = v.money,
				new_money = v.money,
				tax = 0,
				all_score = 0,
				ip_area = v.ip_area,
			}
			self.show_card_list[v.chair_id][v.chair_id] = true
			-- 底注
			--self.player_oldmoney[i] = v:get_money()
			self.player_oldmoney[i] = self:get_player_money(v)
			--v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cell_score}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
			self:cost_player_money(v,cell_score)

			self.betscore[self.betscore_count_] = cell_score
			self.betscore_count_ = self.betscore_count_ + 1

			self.player_money[i] = cell_score
			self.all_money = self.all_money+cell_score
			--local money_ = v:get_money()
			local money_ = self:get_player_money(v)
			if not self.max_score_ or self.max_score_ > money_ then
				self.max_score_ = money_
				print ("self.max_score_ :", self.max_score_)
			end
		end
	end
	--检查黑名单
	self:check_black_user()
	--计算机器人是否为最大牌型
	self:robot_start_game()

	self.status = ZHAJINHUA_STATUS_PLAY
	local msg = {
		banker_chair_id = self.cur_turn,
		chair_id = chari_list_tp_,
		guid = guid_list_tp_,
	}
	self:broadcast2client("SC_ZhaJinHuaStart", msg)
    print("cell_score:", cell_score, " self.max_score_:",self.max_score_)
	log.info("game start ID =%s   guid=%s   timeis:%s", self.gamelog.table_game_id, self.log_guid, os.date("%y%m%d%H%M%S"))
	self.time0_ = get_second_time()
end

-- 加注
function zhajinhua_table:add_score(player, score_)
	log.info("game_id[%s] player guid[%d]--------> add score[%d]",self.gamelog.table_game_id,player.guid,score_)
	local b_all_score_ = false

	--print("self.add_score_[score_]", self.add_score_[score_])
	--全压
	if (not self.add_score_[score_])then
		if(score_ ~= 1 ) then
			log.warning("zhajinhua_table:game_id[%s] add_score guid[%d] status error", self.gamelog.table_game_id,player.guid)
			return
		end
		--第一个全压的人
		if self.ball_begin == false then
			--获取玩家数量
			local playernum = 0
			local otherplayer = 0
			for i,v in ipairs(self.players) do
				if v and (not self.is_dead_[i]) then
					playernum = playernum + 1
					--获取另一玩家
					if i ~= player.chair_id then
						otherplayer = i
					end
				end
			end
			if playernum == 2 then
				--local all_add_score = (21 - self.Round) * self.max_add_score_
				local all_add_score = (21 - self.Round) * self.room_.cell_score_ * 20

				--local player_money_temp1 = all_add_score
				--local player_money_temp2 = all_add_score

				--if self.is_look_card_[player.chair_id] then
				--	player_money_temp1 = all_add_score * 2
				--end

				--if self.is_look_card_[self.players[otherplayer].chair_id] then
				--	player_money_temp2 = all_add_score * 2
				--end

				--if player_money_temp1 > self:get_player_money(player) then
				--	player_money_temp1 = self:get_player_money(player)
				--end
				--if player_money_temp2 > self:get_player_money(self.players[otherplayer]) then
				--	player_money_temp2 = self:get_player_money(self.players[otherplayer])
				--end

				--print(self:get_player_money(player), self:get_player_money(self.players[otherplayer]))
				--print(player_money_temp1, player_money_temp2)

				--if player_money_temp1 > player_money_temp2 then
				--	if self.is_look_card_[self.players[otherplayer].chair_id] then
				--		all_add_score =  player_money_temp2 / 2
				--	else
				--		all_add_score =  player_money_temp2
				--	end
				--else
				--	if self.is_look_card_[player.chair_id] then
				--		all_add_score =  player_money_temp1 / 2
				--	else
				--		all_add_score =  player_money_temp1
				--	end
				--end

				--取钱最少玩家身上的钱
				if all_add_score > self:get_player_money(player) then
					all_add_score = self:get_player_money(player)
				end

				if all_add_score > self:get_player_money(self.players[otherplayer]) then
					all_add_score = self:get_player_money(self.players[otherplayer])
				end


				self.max_score_ = all_add_score
				score_ = self.max_score_

				log.info("game_id [%s]: guid[%d] add_score self.max_score_[%d]:", self.gamelog.table_game_id,player.guid,self.max_score_)
			else
				log.warning("game_id[%s]: add_score guid[%d] status error",self.gamelog.table_game_id, player.guid)
				return
			end
		else
			score_ = self.max_score_
		end
		b_all_score_ = true
	end

	if self.ball_score_[player.chair_id] then
			log.warning("game_id[%s]: add_score guid[%d] status error  is all_score_  true", self.gamelog.table_game_id, player.guid)
			return
	end
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		log.warning("game_id[%s]: add_score guid[%d] status error", self.gamelog.table_game_id,player.guid)
		return
	end

	if player.chair_id ~= self.cur_turn then
		log.warning("game_id[%s]:add_score guid[%d] turn[%d] error, cur[%d]",self.gamelog.table_game_id, player.guid, player.chair_id, self.cur_turn)
		return
	end

	if self.is_dead_[player.chair_id] then
		log.error("game_id[%s]:add_score guid[%d] is dead", self.gamelog.table_game_id,player.guid)
		return
	end

	if score_ < self.last_score and not b_all_score_ then
		log.error("game_id[%s]:add_score guid[%d] score[%d] < last[%d]",self.gamelog.table_game_id, player.guid, score_, self.last_score)
		return
	end

	local money_ = score_
	if money_ > self.max_score_ then
		log.error("game_id[%s]:add_score guid[%d] score[%d] > max[%d]",self.gamelog.table_game_id, player.guid, money_, self.max_score_)
		return
	end

	--非全压看牌押注翻倍
	if not b_all_score_ and self.is_look_card_[player.chair_id] then
		money_ = score_ * 2
	end

	log.info("game_id[%s]: player guid[%d]----->socre[%d],money[%d].",self.gamelog.table_game_id,player.guid,score_, money_)

	money_ = math.ceil(money_)

	if money_ <= 0 or self:get_player_money(player) < money_ then
		log.error("game_id[%s]:add_score guid[%d] money[%d] > player_money[%d]",self.gamelog.table_game_id, player.guid, money_, self:get_player_money(player))
		return false
	end

	--player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
	self:cost_player_money(player,money_)

	self.betscore[self.betscore_count_] = score_
	self.betscore_count_ = self.betscore_count_ + 1

	self.last_score = score_
	self.player_score[player.chair_id] = score_
	local playermoney = self.player_money[player.chair_id] + money_
	self.player_money[player.chair_id] = playermoney
	self.all_money = self.all_money+money_

	--日志处理
	local process = {
	chair_id = player.chair_id,
	score = score_, -- 注码
	money = money_,
	turn = self.Round,
	isallscore = b_all_score_ ,  --是否全压
	isallcom = false, --是否为全比
	}
	table.insert(self.gamelog.add_score, process)

	--处理全押

	self:next_turn()
	local istemp = 0
	if b_all_score_ then
		istemp = 2
	else
		istemp = 3
	end
	local notify = {
		add_score_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
		score = score_,
		money = money_,
		is_all = istemp,
	}
	print("-------------------is_all:",notify.is_all )
	self:broadcast2client("SC_ZhaJinHuaAddScore", notify)
	self:next_round()

	print("b_all_score_:",b_all_score_)
	if b_all_score_ == true then
		log.info("game_id[%s]:player guid[%d]--------->all score money score[%d]", self.gamelog.table_game_id,player.guid,score_)
		self.ball_score_[player.chair_id] = true

		if self.ball_score_[self.cur_turn]  == true then
			self:compare_card(self.players[self.cur_turn], player.chair_id, true, true)
		end
		self.ball_begin = true
	end

	self.time0_ = get_second_time()
end

-- 放弃跟注
function zhajinhua_table:give_up(player)
	log.info("game_id[%s]:player guid[%d]------> give_up", self.gamelog.table_game_id,player.guid)
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		log.warning("game_id[%s]:give_up guid[%d] status error",self.gamelog.table_game_id, player.guid)
		return
	end

	if self.is_dead_[player.chair_id] then
		log.error("game_id[%s]:add_score guid[%d] is dead", self.gamelog.table_game_id,player.guid)
		return
	end

	if self.ball_begin and self.cur_turn ~= player.chair_id then
		log.error("game_id[%s]:give_up is ball_begin guid[%d] can not giveup charid [%d] cur_turn[%d]",self.gamelog.table_game_id, player.guid, player.charid , self.cur_turn)
	end

	self.is_dead_[player.chair_id] = true
	self.player_status[player.chair_id] = PLAYER_DROP
    self.dead_count_ = self.dead_count_  + 1

	if self.cur_turn > player.chair_id then
		self.Round_Times = self.Round_Times + 1  --去掉该玩家出手序列
	end

	local notify = {
		giveup_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
	}

	--日志处理
	local giveup = {
		chair_id = player.chair_id,
		turn = self.Round,
		now_chair = self.cur_turn,
	}
	table.insert(self.gamelog.give_up, giveup)

	-- 下注流水日志
	self:player_bet_flow_log(player,self.moeny_cost_info[player.guid])

	if self:check_end("SC_ZhaJinHuaGiveUp", notify) then -- 结束
		return
	end



	if(player.chair_id == self.cur_turn) then
		self:next_turn()
		self:next_round()
		self.time0_ = get_second_time()
	end
	notify.cur_chair_id = self.cur_turn
	self:broadcast2client("SC_ZhaJinHuaGiveUp", notify)
end

-- 看牌
function zhajinhua_table:look_card(player)
	log.info("game_id[%s]:player guid[%d]-------------->look cards",self.gamelog.table_game_id,player.guid)
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		log.warning("game_id[%s]:look_card guid[%d] status error", self.gamelog.table_game_id,player.guid)
		return
	end
	if self.Round <= 1 then
		return
	end
	if player.chair_id ~= self.cur_turn then
		log.warning("game_id[%s]:look_card guid[%d] turn[%d] error, curturn[%d]", self.gamelog.table_game_id, player.guid, player.chair_id, self.cur_turn)
		return
	end
--	if self.is_look_card_[player.chair_id] then
--		log.error("zhajinhua_table:look_card guid[%d] has look", player.guid)
--		return
--	end

	--全压已经取了钱最少玩家的所有钱，不受看牌×2规则影响，所以可以看牌
	--if self.ball_begin and self:get_player_money(player) < (self.max_score_  * 2)  then
	--	log.error("zhajinhua_table:look_card guid[%d] player_money[%d] max_money[%d] ball_begin and player money error", player.guid,self:get_player_money(player),self.max_score_)
	--	return
	--end

	self.is_look_card_[player.chair_id] = true

	send2client_pb(player, "SC_ZhaJinHuaLookCard", {
		lookcard_chair_id = player.chair_id,
		cards = self.player_cards_[player.chair_id],
	})

	local notify = {
		lookcard_chair_id = player.chair_id,
	}
	self:broadcast2client_except(player.guid, "SC_ZhaJinHuaNotifyLookCard", notify)


	--日志处理
	local look = {
		chair_id = player.chair_id,
		turn = self.Round,
	}
	table.insert(self.gamelog.look_chair, look)

	--self.time0_ = get_second_time()
end

-- 终
 -- 比牌
function zhajinhua_table:compare_card(player, compare_chair_id, allcompare, nosendflag)
	log.info("game_id[%s]:player guid[%d] chair_id[%d]-------------->compare_chair_id[%d] COMPARE_CARD",self.gamelog.table_game_id,player.guid,player.chair_id,compare_chair_id)
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		log.warning("game_id[%s]:compare_card guid[%d] status error", self.gamelog.table_game_id,player.guid)
		return
	end

	if player.chair_id ~= self.cur_turn then
		log.warning("game_id[%s]:compare_card guid[%d] turn[%d] error, cur[%d]",self.gamelog.table_game_id, player.guid, player.chair_id, self.cur_turn)
		return
	end

 	local target = self.players[compare_chair_id]
 	if not target then
		log.error("game_id[%s]:compare_card guid[%d] compare[%d] error",self.gamelog.table_game_id, player.guid, compare_chair_id)
 		return
 	end

	if self.is_dead_[player.chair_id] then
		log.error("game_id[%s]:compare_card error guid[%d] is dead",self.gamelog.table_game_id, player.guid)
		return
	end

	if self.is_dead_[compare_chair_id] then
		log.error("game_id[%s]:compare_card error guid[%d] is dead",self.gamelog.table_game_id, target.guid)
		return
	end

	local bRetAllCompare = false   --是否金钱不足开始全比

	local money_ = 0
	if not allcompare  then


		if self.ball_begin then
			money_ = self.last_score
		else
			money_ = self.last_score

			if self.is_look_card_[player.chair_id]  then
				money_ = money_ * 2
			end
		end
		-- print("compare_card------------------------------ball_begin-----6 ", self.last_score, money_)
		log.info("game_id[%s]: player guid[%d] compare card must cost money[%d]",self.gamelog.table_game_id,player.guid,money_)
		if money_ > self:get_player_money(player) then
			--money_ = player:get_money()
			money_ = self:get_player_money(player)
			bRetAllCompare = true
			log.info("game_id[%s]: player guid[%d] do not have enough money[%d]",self.gamelog.table_game_id,player.guid,money_)
		end
		money_ = math.ceil(money_)
		log.info("game_id[%s]: player guid[%d] last_score is [%d] cost_money[%d]",self.gamelog.table_game_id,player.guid,self.last_score,money_)

		if money_ <= 0 or  self:get_player_money(player) < money_  then
			log.error("game_id[%s]:add_score guid[%d] money[%d] > player_money[%d]",self.gamelog.table_game_id, player.guid, money_, self:get_player_money(player))
			return
		end
		--player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
		self:cost_player_money(player,money_)

		local playermoney = self.player_money[player.chair_id] + money_
		self.player_money[player.chair_id] = playermoney
		self.all_money = self.all_money+money_

	end

	-- 比牌
	card_temp1 = self.player_cards_[player.chair_id]
	for i = 1, 3 do
		print("A  color:", get_color(card_temp1[i]), "  value:",  get_value(card_temp1[i]))
	end

	card_temp2 = self.player_cards_[compare_chair_id]
	for i = 1, 3 do
		print("B  color:", get_color(card_temp2[i]), "  value:",  get_value(card_temp2[i]))
	end
	local ret = self:compare_cards(self.player_cards_type_[player.chair_id], self.player_cards_type_[compare_chair_id])

	--修改双方结束时对方牌可见
	self.show_card_list[player.chair_id][compare_chair_id] = true
	self.show_card_list[compare_chair_id][player.chair_id] = true

	if ret then
		log.info("game_id[%s]:player guid[%d],target guid[%d]---------->first is win.",self.gamelog.table_game_id,player.guid,target.guid)
	else
		log.info("game_id[%s]:player guid[%d],target guid[%d]---------->second is win.",self.gamelog.table_game_id,player.guid,target.guid)
	end

	local loser,winner
	if ret then
		self.is_dead_[compare_chair_id] = true
		self.player_status[compare_chair_id] = PLAYER_LOSE
		if compare_chair_id > player.chair_id then
			self.Round_Times = self.Round_Times + 1  --去掉该玩家出手序列
		end

		loser = self.players[compare_chair_id]
		winner = player
	else
		loser = player
		winner = self.players[compare_chair_id]

		self.is_dead_[player.chair_id] = true
		self.player_status[player.chair_id] = PLAYER_LOSE
	end

	self:player_bet_flow_log(loser,self.moeny_cost_info[loser.guid])

    self.dead_count_ = self.dead_count_  + 1

	local notify = {
		cur_chair_id = self.cur_turn,
	}
	local loster_msg = {}
	local loster = target
	if ret then
		--loster_msg.win_cards = self.player_cards_[player.chair_id]
		--loster_msg.loster_cards = self.player_cards_[compare_chair_id]
		notify.win_chair_id = player.chair_id
		notify.lost_chair_id = compare_chair_id
	else
		--loster_msg.win_cards = self.player_cards_[compare_chair_id]
		--loster_msg.loster_cards = self.player_cards_[player.chair_id]
		notify.win_chair_id = compare_chair_id
		notify.lost_chair_id = player.chair_id
		loster = player
	end

	--send2client_pb(loster, "SC_ZhaJinHuaLostCards", loster_msg)
	if allcompare and not nosendflag then
		notify.is_all = 3
	else
		notify.is_all = 4
	end

	--日志处理
	local compare = {
		chair_id = player.chair_id,
		turn = self.Round,
		otherplayer = compare_chair_id,		--被比牌玩家
		money = money_,		--比牌花费
		win = ret,		--是否获胜
	}
	log.info("game_id[%s]: player guid[%d] charid[%d] , target guid[%d] ,turn [%d] , otherplayer [%d] money[%d] win [%s]" ,self.gamelog.table_game_id,player.guid,compare.chair_id,target.guid,compare.turn,compare.otherplayer,compare.money,tostring(compare.win))
	table.insert(self.gamelog.compare, compare)

	if self:check_end("SC_ZhaJinHuaCompareCard", notify) then -- 结束
		self:player_bet_flow_log(winner,self.moeny_cost_info[winner.guid])
		log.info("game_id[%s]:------------->This Game Is  Over!",self.gamelog.table_game_id)
		return true
	end

	if not allcompare then
		self.is_compare_card_flag = true
	end

	self:next_turn()
	notify.cur_chair_id = self.cur_turn
	self:broadcast2client("SC_ZhaJinHuaCompareCard", notify)
	self:next_round()


	if bRetAllCompare then
		self:all_compare()
	end

	self.time0_ = get_second_time()

	return false
end

function deepcopy(object)
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

function zhajinhua_table:check_get_bonus_pool_money(card_type)
	if card_type == ZHAJINHUA_CARD_TYPE_BAO_ZI then
		return self.room_.cell_score_ * 50
	end
	if card_type == ZHAJINHUA_CARD_TYPE_SHUN_JIN then
		return self.room_.cell_score_ * 10
	end

	return 0
end

-- 检查结束
function zhajinhua_table:check_end(sendname, fmsg)
	local win = nil
	for i,v in ipairs(self.players) do
		if v and (not self.is_dead_[i]) then
			if win then
				return false
			else
				win = i
			end
		end
	end

	if win then
		log.info("game_id[%s]: check_end---->Game is Over !!",self.gamelog.table_game_id)
		self:cost_money_real()

		for i=1,self.player_count_ do
			local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
			log.info(str)
			redis_command(str)
		end
		self.status = ZHAJINHUA_STATUS_FREE

		local notify = {
			win_chair_id = win,
			pb_conclude = {},
			tax = 0,
			extra_prize = 0,
	        total_bonus = 0,
			cards_type  = 0
		}
		--记录每个玩家得到奖池的钱
		local players_extra_money = {}

		for i,v in pairs(self.gamer_player) do
			if v then
				local item = {
					chair_id = i,
					cards = self.player_cards_[i],
					guid = self.gamer_player[i].guid,
					header_icon = v.player:get_header_icon(),
					ip_area = v.player.ip_area,
					status = self.player_status[v.chair_id]
				}
				local money_tax = 0
				local money_temp = 0 --给赢家加的钱（包含自己下注的钱）
				local money_change = 0 --这一把赢的钱
				local money_type = 1

				--根据牌型得到奖池的钱
				local card_type = 0
				if self.player_cards_type_[v.player.chair_id] then
					card_type = self.player_cards_type_[v.player.chair_id].cards_type
				end
				local bonus_money = self:check_get_bonus_pool_money(card_type)

				--进入奖池的钱
				local to_bonus_pool_money = 0

				if i == win then
					local win_money = self.all_money - self.player_money[i]
					--税收运算
					if self.tax_open_ == 1 then

						money_tax = win_money * self.tax_
						if money_tax < 1 then
							money_tax = 0
						end
						money_tax = math.ceil(money_tax)

						if money_tax < 1 then
							money_temp = self.all_money
							money_tax = 0
						else
							money_temp = self.all_money - money_tax
						end
					end

					--计算进入奖池的钱
					to_bonus_pool_money = win_money * BONUS_POOL_RATE
					if to_bonus_pool_money < 1 then
						to_bonus_pool_money = 0
					end
					to_bonus_pool_money = math.ceil(to_bonus_pool_money)
					money_temp = money_temp - to_bonus_pool_money
					log.info("guid[%d] to_bonus_pool_money[%d]",v.player.guid,to_bonus_pool_money)
					if to_bonus_pool_money > 0 then
						to_bonus_pool_money = zhajinhua_prize_pool:add_money(to_bonus_pool_money)
					end

					--得到奖池的钱
					if bonus_money > 0 then
						local bonus_money_full = bonus_money
						--奖池钱不够就得到剩余所有的钱
						bonus_money = zhajinhua_prize_pool:remove_money(bonus_money)
						players_extra_money[v.player.chair_id] = bonus_money
						money_temp = money_temp + bonus_money
						log.info("winner guid[%d] extra_prize[%d]",v.player.guid,bonus_money)
						--得到全额奖金才广播
						if bonus_money_full == bonus_money then
							local bonus_money_str = string.format("%.02f",bonus_money/100)
							if v.player.guid > 0 and card_type >= ZHAJINHUA_CARD_TYPE_BAO_ZI then
								broadcast_world_marquee(def_first_game_type,def_second_game_type,1,v.player.nickname,bonus_money_str,card_type)
							end
						end
					end


					notify.tax = money_tax
					--赢的钱不包含拿到奖池的钱
					item.score = money_temp - bonus_money
					log.info("game_id[%s]: guid[%d]------> tax[%d] add money[%d]",self.gamelog.table_game_id,v.player.guid,money_tax,money_temp)
					self:ChannelInviteTaxes(v.player.channel_id,v.player.guid,v.player.inviter_guid,money_tax)
					v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_temp}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
					money_change = self.all_money - self.player_money[i] - money_tax - to_bonus_pool_money + bonus_money
					money_type = 2

					self.gamelog.win_chair = v.chair_id
					self.gamelog.tax = money_tax

					v.money =  v.player.money
					item.money = v.money
					item.bet_money = self.player_money[i] or 0
					log.info("game_id[%s]: guid[%d]------> bet money[%d] change money[%d] now money[%d]",self.gamelog.table_game_id,item.guid,item.bet_money,money_change,item.money)
					--跑马灯游戏公告
					if money_change >= broadcast_money then
						local money_change_str = string.format("%.02f",money_change/100)
						if v.player.guid > 0 then
							broadcast_world_marquee(def_first_game_type,def_second_game_type,0,v.player.nickname,money_change_str)
						end
					end
				else
					--输家也可以得到奖池的钱
					if bonus_money > 0 then
						local bonus_money_full = bonus_money
						--奖池钱不够就得到剩余所有的钱
						bonus_money = zhajinhua_prize_pool:remove_money(bonus_money)
						players_extra_money[v.player.chair_id] = bonus_money
						v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = bonus_money}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
						log.info("loser guid[%d] extra_prize[%d]",v.player.guid,bonus_money)
						--得到全额奖金才广播
						if bonus_money_full == bonus_money then
							local bonus_money_str = string.format("%.02f",bonus_money/100)
							if v.player.guid > 0 then
								broadcast_world_marquee(def_first_game_type,def_second_game_type,1,v.player.nickname,bonus_money_str,card_type)
							end
						end
					end
					--输的钱不包含拿到奖池的钱
					item.score = -(self.player_money[i] or 0)
					money_change =  -(self.player_money[i] or 0) + bonus_money
					v.money = self.player_oldmoney[v.chair_id] -(self.player_money[i] or 0) + bonus_money
					item.money = v.money
					item.bet_money = self.player_money[i] or 0
				end
				notify.total_bonus = zhajinhua_prize_pool:get_total_bonus()

				if self:islog(v.player.guid) then
					self:do_player_money_log(v, money_type, self.player_oldmoney[v.chair_id], money_tax, money_change, self:get_now_game_id(),bonus_money,to_bonus_pool_money)
				end
				log.info("game_id[%s]:guid[%d]:chair_id = [%d] status[%d] bet_money = [%d] now_money = [%d], score = [%d] ip_area = [%s] get_bonus_money[%d] to_bonus_money[%d]",self.gamelog.table_game_id,item.guid,item.chair_id,item.status,item.bet_money,item.money,item.score,item.ip_area,bonus_money,to_bonus_pool_money)
				if self.players[i] then
					send2client_pb(v.player,"SC_Gamefinish",{
						money = v.player.money
					})
				end
				self.gamelog.playInfo[v.chair_id].new_money = self.player_oldmoney[v.chair_id] +  money_change


				local game_end_player_info = deepcopy(item)
				--增加日志记录得到奖池的钱和进入奖池的钱
				item.get_bonus_money = bonus_money
				item.to_bonus_money  = to_bonus_pool_money

				table.insert(self.gamelog.finisgameInfo, item)

				table.insert(notify.pb_conclude, game_end_player_info)
			end
		end
		self.gamelog.all_money = self.all_money

		if fmsg.cur_chair_id then
			fmsg.cur_chair_id = win
		end
		self:broadcast2client(sendname, fmsg)

		self.last_record = {}

		for i, p in ipairs(self.players) do
			if p then
				if p.online and p.in_game then
					local pb = deepcopy(notify)

					for j,v in pairs(self.gamer_player) do
						if v then
							if self.show_card_list[p.chair_id][j] == false then
								for x,y in ipairs(pb.pb_conclude) do
									if y.chair_id == j then
										y.cards = {-1,-1,-1}
									end
								end
							end
						end
					end
					if self.player_cards_type_[p.chair_id] then
						--自己的牌型和得到的奖池奖励
						pb.cards_type  = self.player_cards_type_[p.chair_id].cards_type
						pb.extra_prize = players_extra_money[p.chair_id] or 0
					end

					send2client_pb(p, "SC_ZhaJinHuaEnd", pb)

					self.last_record[p.guid] = pb

					local xmsg = {
						time = 23,
					}
					send2client_pb(p, "SC_ZhaJinHuaClientReadyTime", xmsg)
				else
					if p.is_player == false then --非玩家(机器人)
						-- do nothing
					else
						print("p offline :"..p.chair_id)
					end
				end
			end
		end

		--self:broadcast2client("SC_ZhaJinHuaEnd", notify)
		self:clear_ready()
		self:check_single_game_is_maintain()
		self:check_robot_leave()
		return true
	end

	return false
end

function zhajinhua_table:clear_ready( ... )
	self.gamelog.end_game_time = get_second_time()
	local s_log = json.encode(self.gamelog)
	if self.robot_islog then
		print(s_log)
		self:save_game_log(self.gamelog.table_game_id, self.def_game_name, s_log, self.gamelog.start_game_time, self.gamelog.end_game_time)
	end
	log.info("game end ID =%s   guid=%s   timeis:%s", self.gamelog.table_game_id, self.log_guid, os.date("%y%m%d%H%M%S"))

	base_table.clear_ready(self)
	print("self.chair_count ", self.chair_count )
	for i = 1, self.chair_count  do
		self.player_status[i] = PLAYER_FREE
		self.is_look_card_[i] = false
		self.is_dead_[i] = false
		self.player_money[i] = 0
		self.player_online[i] = false
		if self.players[i] then
			local player = 	self.players[i]
			print(i, self.players[i].is_offline)
			if self.players[i].is_offline == true or self.players[i].in_game == false or player.isTrusteeship then
				print("offline exit----------------------!", self.players[i].is_offline )
				player:forced_exit()
				-- logout(player.guid)
			else
			--检查T人
				print("check_money-----------------------!")
				player:check_forced_exit(self.room_:get_room_limit())
				if  player.disable == 1 then
					player:forced_exit()
				end
			end
		end
	end
	self.all_money = 0
	self.last_score = 0
	self.Round = 1
	self.betscore = {}
	self.allready  = false
	self.is_compare_card_flag = false
	self:next_game()
	self:check_sit_player_num(true)

end


-- 得到牌类型
function zhajinhua_table:get_cards_type(cards)

	print ("cards1:",cards[1],"cards2:",cards[2],"cards3:",cards[3])

	local v = {
		get_value(cards[1]),
		get_value(cards[2]),
		get_value(cards[3]),
	}

	-- 豹子
	if v[1] == v[2] and v[2] == v[3] then
		return ZHAJINHUA_CARD_TYPE_BAO_ZI, v[1]
	end

	-- 对子
	if v[1] == v[2] then
		return ZHAJINHUA_CARD_TYPE_DOUBLE, v[1], v[3]
	elseif v[1] == v[3] then
		return ZHAJINHUA_CARD_TYPE_DOUBLE, v[1], v[2]
	elseif v[2] == v[3] then
		return ZHAJINHUA_CARD_TYPE_DOUBLE, v[2], v[1]
	end

	print ("1111111V1:",v[1],"V2:",v[2],"V3:",v[3])
	table.sort(v)

	print ("222222222V1:",v[1],"V2:",v[2],"V3:",v[3])
	local val = nil
	local is_shun_zi = false
	if v[1]+1 == v[2] and v[2]+1 == v[3] then
		is_shun_zi = true
		val = v[3]
	elseif v[1] == 0 and v[2] == 1 and v[3] == 12 then
		is_shun_zi = true
		val = 1
	end

	print ("33333333333V1:",v[1],"V2:",v[2],"V3:",v[3])
	local c1 = get_color(cards[1])
	local c2 = get_color(cards[2])
	local c3 = get_color(cards[3])
	if c1 == c2 and c2 == c3 then
		if is_shun_zi then
			-- 顺金
			return ZHAJINHUA_CARD_TYPE_SHUN_JIN, val
		else
			-- 金花
			return ZHAJINHUA_CARD_TYPE_JIN_HUA, v[3], v[2], v[1]
		end
	elseif is_shun_zi then
		-- 顺子
		return ZHAJINHUA_CARD_TYPE_SHUN_ZI, val
	end

	print ("4444444444444V1:",v[1],"V2:",v[2],"V3:",v[3])
	--去掉特殊牌型
	--if v[1] == 0 and v[2] == 1 and v[3] == 3 then
		--return ZHAJINHUA_CARD_TYPE_SPECIAL
	--end

	print ("55555555555555V1:",v[1],"V2:",v[2],"V3:",v[3])
	return ZHAJINHUA_CARD_TYPE_SINGLE, v[3], v[2], v[1]
end

-- 比较牌 first 申请比牌的
function zhajinhua_table:compare_cards(first, second)
	log.info("game_id[%s]:------------->COMPARE_CARDS!",self.gamelog.table_game_id)
	if first.cards_type ~= second.cards_type then
		-- 特殊
		if first.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI and second.cards_type == ZHAJINHUA_CARD_TYPE_SPECIAL then
			return false
		elseif second.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI and first.cards_type == ZHAJINHUA_CARD_TYPE_SPECIAL then
		 	return true
		end
		return first.cards_type > second.cards_type
	end

	if first.cards_type == ZHAJINHUA_CARD_TYPE_SHUN_ZI or first.cards_type == ZHAJINHUA_CARD_TYPE_SHUN_JIN or first.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI then
		return first[1] > second[1]
	end

	if first.cards_type == ZHAJINHUA_CARD_TYPE_DOUBLE then
		if first[1] > second[1] then
			return true
		elseif first[1] == second[1] then
			return first[2] > second[2]
		end
		return false
	end

	if first[1] > second[1] then
		return true
	elseif first[1] == second[1] then
		if first[2] > second[2] then
			return true
		elseif first[2] == second[2] then
			return first[3] > second[3]
		end
	end
	return false
end


function zhajinhua_table:check_sit_player_num(bRet)
	print("-----------------------------self.allready ", self.allready )
	local n = 0
	for i,v in pairs(self.players) do
		if v then
			n = n + 1
		else
			print("-------------Null player clear:", i)
			self.players[i] = false
		end
	end
	if n >= 2 and self.status == ZHAJINHUA_STATUS_FREE then
		if bRet then
			self.ready_count_down = 23
		end
		if not self.allready  then
			local msg = {
			time = self.ready_count_down,
			}
			self:broadcast2client("SC_ZhaJinHuaReadyTime", msg)
		end
		self.ready_time = get_second_time()
		print ("-----------------Game  Ready :", n)
		self.status = ZHAJINHUA_STATUS_READY
	end
end

-- 玩家坐下
function zhajinhua_table:player_sit_down(player, chair_id_)
	print("player_sit_down  AKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK", self.table_id_,chair_id_,player.nickname)

	for i,v in pairs(self.players) do
		if v == player then
			player.chari_id_ = v.chari_id_
			player:on_stand_up(self.table_id_, chari_id_, GAME_SERVER_RESULT_SUCCESS)
			return
		end
	end
	if self.status == ZHAJINHUA_STATUS_FREE or self.status == ZHAJINHUA_STATUS_READY then
		player.table_id = self.table_id_
		player.chair_id = chair_id_
		player.room_id = self.room_.id
		self:get_sit_down(player)
		self.players[chair_id_] = player

		self.player_status[player.chair_id] = PLAYER_FREE
		if player.is_player then
			for i, p in ipairs(self.players) do
				if p == false then
					-- 主动机器人坐下
					player:on_notify_android_sit_down(player.room_id, self.table_id_, i)
				end
			end
		end
		if  self.status == ZHAJINHUA_STATUS_READY then
			msg = {
				time = get_second_time() - self.ready_time,
			}
			send2client_pb(player, "SC_ZhaJinHuaReadyTime", msg)
		else
			self:check_sit_player_num()
		end
	else
		if self.players[chair_id_] then
			log.warning("zhajinhua_table:player_sit_down !ZHAJINHUA_STATUS_FREE guid[%d]", player.guid)
			return
		end
		player.table_id = self.table_id_
		player.chair_id = chair_id_
		player.room_id = self.room_.id
		self:get_sit_down(player)
		self.players[chair_id_] = player
		self.ready_list_[chair_id_] = false
		--观众坐下
		self.player_status[player.chair_id] = PLAYER_STAND
		--self:send2client_pb(player, "SC_ShowTax", self.notify_msg)
	end
	print ("chair = ", chair_id_, "player.chair_id = ", player.chair_id)
	log.info(string.format("GameInOutLog,zhajinhua_table:player_sit_down, guid %s, table_id %s, chair_id %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id)))
end

-- 获取玩家状态
function zhajinhua_table:get_play_Status(player)
	local ltime = 0
	if self.time0_ then
		ltime = get_second_time() - self.time0_
	end
	local notify = {
		isseecard = self.is_look_card_,
		banker_chair_id = self.cur_turn,
		room_status = self.status,
		totalmoney = self.all_money,
		score = self.last_score,
		round = self.Round,
		status = self.player_status,
		playermoney = self.player_money,
		allbet = self.betscore,
		time =  ltime,
	}
	send2client_pb(player, "SC_ZhaJinHuaWatch", notify)
	--玩家自己已看牌
	if self.is_look_card_ and self.is_look_card_[player.chair_id] then
		send2client_pb(player, "SC_ZhaJinHuaLookCard", {
			lookcard_chair_id = player.chair_id,
			cards = self.player_cards_[player.chair_id],
		})
	end
end
-- 判断是否游戏中
function  zhajinhua_table:is_play( ... )
	print("zhajinhua_table:is_play :"..self.status)
	-- body
	if self.status == ZHAJINHUA_STATUS_PLAY then
		print("is_play  return true")
		return true
	end
	return false
end

---------------------------------------------------------------新的扣钱start
-- 玩家站起
function zhajinhua_table:player_stand_up(player, is_offline)
	--扣除未扣的钱
	if self.gamelog and self.gamelog.table_game_id then
		log.info("game_id[%s]:player guid[%d]----------->stand up and cost money real.",self.gamelog.table_game_id,player.guid)
	else
		log.info("player guid[%d]----------->stand up and cost money real.",player.guid)
	end
	self:cost_player_money_real(player)
	self:robot_leave(player)
	return base_table.player_stand_up(self,player,is_offline)
end

--替换玩家cost_money方法，先缓存，稍后一起扣钱
function zhajinhua_table:cost_player_money(player,money_cost)

	local money = self:get_player_money(player)
	if self.gamelog and self.gamelog.table_game_id then
		log.info("game_id[%s]: player guid[%d] cur money[%d],money_cost[%d].",self.gamelog.table_game_id,player.guid,money,money_cost)
	else
		log.info("player guid[%d] cur money[%d],money_cost[%d].",player.guid,money,money_cost)
	end

	if money_cost <= 0 or money < money_cost then
		log.error("game_id[%s]:guid[%d] cost_player_money error.curmoney[%d], must cost money[%d]",self.gamelog.table_game_id,player.guid,money,money_cost)
		return false
	end

	-- body
	if self.moeny_cost_info == nil then
		self.moeny_cost_info = {}
	end

	if self.moeny_cost_info[player.guid] == nil then
		self.moeny_cost_info[player.guid] = 0
	end

	self.moeny_cost_info[player.guid]  = self.moeny_cost_info[player.guid] + money_cost

	--notify money
	local new_money = self:get_player_money(player)
	if self.gamelog and self.gamelog.table_game_id then
		log.info("game_id[%s]: player guid[%d] new_money[%d],money_cost[%d].",self.gamelog.table_game_id,player.guid,new_money,money_cost)
	else
		log.info("player guid[%d] new_money[%d],money_cost[%d].",player.guid,new_money,money_cost)
	end

	player:notify_money(LOG_MONEY_OPT_TYPE_ZHAJINHUA,new_money,-money_cost)

	return true
end

--真实扣除所有玩家待扣除的钱
function zhajinhua_table:cost_money_real()
	-- body
	for k,v in pairs(self.players) do
		if v then
			self:cost_player_money_real(v)
		end
	end
end

function zhajinhua_table:cost_player_money_real(player)
	-- body
	local cost =  self:get_player_money_cost(player)
	if self.gamelog and self.gamelog.table_game_id then
		log.info("game_id[%s]: player guid[%d] must cost money[%d]",self.gamelog.table_game_id,player.guid,cost)
	else
		log.info("player guid[%d] must cost money[%d]",player.guid,cost)
	end

	if cost > 0 then
		player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cost}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
		self:save_player_collapse_log(player)
		self:set_player_money_cost(player,0)
	end
end

--获取玩家待扣除的钱
function zhajinhua_table:get_player_money_cost(player)
	-- body
	if self.moeny_cost_info ~= nil and self.moeny_cost_info[player.guid] ~= nil  then
		return self.moeny_cost_info[player.guid]
	end
	return 0
end

function zhajinhua_table:set_player_money_cost(player,cost)
	-- body
	if self.moeny_cost_info ~= nil and self.moeny_cost_info[player.guid] ~= nil  then
		self.moeny_cost_info[player.guid] = cost
	end
end

--替换玩家get_money方法
function zhajinhua_table:get_player_money(player)
	-- body
	return player:get_money() - self:get_player_money_cost(player)
end
---------------------------------------------------------------新的扣钱end

function zhajinhua_table:set_trusteeship(player,flag)
	-- body
	player.isTrusteeship = not player.isTrusteeship
	log.info("chair_id:"..player.chair_id)
	if player.isTrusteeship then
		log.info("**************isTrusteeship:true")
		if flag == true then
			log.info("**************flag:true")
			player.finishOutGame = true
		end
	else
		log.info("**************isTrusteeship::false")
		player.finishOutGame = false
	end
end
-- 玩家站起
--function zhajinhua_table:player_stand_up(player, is_offline)
--	return base_table.player_stand_up(self,player,is_offline)
	--if true then
	--	return
	--end
	--log.info(string.format("GameInOutLog,zhajinhua_table:player_stand_up, guid %s, table_id %s, chair_id %s, is_offline %s",
	--tostring(player.guid),tostring(player.table_id),tostring(player.chair_id),tostring(is_offline)))
    --
	--print("STAND_UPPPP AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!" ,player.chair_id, is_offline)
	--print("base_table.player_stand_up(self,player,is_offline)")
    --print(player.table_id,player.chair_id,player.guid)
    --
    --
	--if self.status == ZHAJINHUA_STATUS_READY then
	--	--[[if self.ready_list_[player.chair_id] then
	--		self.ready_list_[player.chair_id] = false
	--		local n = 0
	--		for i, v in ipairs(self.players) do
	--			if v then
	--				if self.ready_list_[i] then
	--					n = n+1
	--				end
	--			end
	--		end
	--		if n < 2 then
	--			self.status = ZHAJINHUA_STATUS_FREE
	--		end
	--	end]]
    --
	--print("S====================================================== 1")
	--	local n = 0
	--	for i,v in pairs(self.players) do
	--		n = n + 1
	--	end
    --
	--	if n < 2 then
	--		self.status = ZHAJINHUA_STATUS_FREE
	--	end
	--	--player:forced_exit()
	--	--logout(player.guid)
	--elseif self.status == ZHAJINHUA_STATUS_PLAY and not is_offline  and not self.is_dead_[player.chair_id] then
	--	print("S====================================================== 2")
	--	self:give_up(player)
	--	return
    --
	--elseif self.status == ZHAJINHUA_STATUS_PLAY and is_offline  and not self.is_dead_[player.chair_id] then
	--	print("S====================================================== 3")
	--		local offline = {
	--		chair_id = player.chair_id,
	--		turn = self.Round,
	--		reconnect = false,
	--		}
    --
	--		table.insert(self.gamelog.offlinePlayers, offline)
	--end
	--	print("S====================================================== 4")
	--if not is_offline and self.player_online[player.chair_id] == false then
	--	print("S====================================================== 5")
	--	local notify = {
	--		table_id = player.table_id,
	--		chair_id = player.chair_id,
	--		guid = player.guid,
	--	}
	--	print (player.table_id,player.chair_id,player.guid)
	--	self:broadcast2client("SC_NotifyStandUp",notify)
	--end
    --
	--	print("S====================================================== 6")
	--if self.status ~= ZHAJINHUA_STATUS_PLAY and is_offline then
	--	print("S====================================================== 7")
	--	base_table.player_stand_up(self,player,is_offline)
	--	self.room_:player_exit_room(player)
	--else
	--	print("S====================================================== 8")
	--	local bRet = false
	--	print("-------------------------------------------C",self.player_status[player.chair_id] , player.chair_id, PLAYER_STAND)
	--	if self.player_status[player.chair_id] ~= PLAYER_STAND and self.player_status[player.chair_id] ~= PLAYER_READY then
    --
	--	print("S====================================================== 9")
	--		bRet = true
	--	end
    --
	--	-- self:give_up(player)
	--	base_table.player_stand_up(self,player,is_offline)
	--	--if bRet and not is_offline then
	--	--print("S====================================================== 10")
	--	--	send2client_pb(player,"SC_Gamefinish",{
	--	--			money = player.money
	--	--		})
	--	--	self.room_:player_exit_room(player)
	--	--end
	--end
--end

function zhajinhua_table:is_compare_card()
	return self.is_compare_card_flag
end

-- 心跳
function zhajinhua_table:tick()

	self:check_robot_enter()

	if self.status == ZHAJINHUA_STATUS_PLAY then
		local curtime = get_second_time()

		if  self.is_compare_card_flag == true then
			if (curtime - self.time0_) >= COMPARE_CARD_TIME then
				self.is_compare_card_flag = false
				self.time0_ = curtime
			end
			return
		end

		if curtime - self.time0_ >= 17 then
			-- 超时
			print("Time_out Cur_turn is : ", self.cur_turn)
			local player = self.players[self.cur_turn]
			if player then
				log.info("Time out give_up  guid[%d]",player.guid)
				self.player_online[player.chair_id] = false
				--self:player_stand_up(player, false)
				self:give_up(player)
			end
			self.time0_ = curtime
		end
	end

	--准备开始状态
	if self.status == ZHAJINHUA_STATUS_READY then
		local curtime = get_second_time()
		if curtime - self.ready_time >= self.ready_count_down  or self.allready then
			-- 达到准备时间
			local n = 0
			for i, p in pairs(self.players) do
				if p then
					print("self.players",i)
					print("self.players chair",p.chair_id)
					if self.ready_list_[p.chair_id] ~= true then
						print("stand up  :" , p.chair_id)
						self.player_online[p.chair_id] = false
						self:player_stand_up(p, false)
						self.room_:player_exit_room(p)
					else
						n = n + 1
					end
				else
					print(string.format("i[%d] p is nil",i))
				end
			end

			if n >= 2 then
				print("Ready start   AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!")
				self:start(n)
			else
				print("Ready start no  AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!")
				self.status = ZHAJINHUA_STATUS_FREE
				self.allready  = false
			end
		end
	end
end

--陪玩机器人初始化
function zhajinhua_table:robot_init()
	self.robot_enter_time = 0 --进入时间
	self.robot_info = {} --机器人
	self.robot_islog = false --是否记录机器人产生的日志
	self.robot_switch = 0 --机器人开关
end

function zhajinhua_table:islog(guid)
	if guid > 0 then
		return true
	end
	return self.robot_islog
end

--检查时否可以加入陪玩机器人
function zhajinhua_table:check_robot_enter()
	if self.robot_switch ~= 1 then
		return
	end
	local curtime = get_second_time()
	if self.robot_enter_time <= curtime then
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
						self.ready_list_[i] = true
						break
					end
				end
			end
		end
	end
end

--检查陪玩机器人离开
function zhajinhua_table:check_robot_leave()
	local leave ={}
	if self.robot_switch == 1 then
		for _,v in pairs(self.robot_info) do
			if v.is_use then
				v.android.cur = v.android.cur + 1
				if v.android.cur >= v.android.round or self.room_:get_room_limit() > v.android:get_money() then
					table.insert(leave,v.android)
				end
			end
		end
		for _,v in pairs(leave) do
			if v.table_id and v.chair_id then
				self:player_stand_up(v, false)
				self.room_:player_exit_room(v)
				self.robot_enter_time = get_second_time() + 10
			end
		end
	else
		for _,v in pairs(self.robot_info) do
			if v.is_use then
				v.android.cur = v.android.cur + 1
				table.insert(leave,v.android)
			end
		end
		for _,v in pairs(leave) do
			log.info("guid[%s] tableid[%s] chairid[%s]",tostring(v.guid),tostring(v.table_id),tostring(v.chair_id))
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
end

--获取陪玩机器人数量
function zhajinhua_table:get_robot_num()
	local num = 0
	for i, p in pairs(self.players) do
		if p and p.is_player == false then
			num = num + 1
		end
	end
	return num
end

--创建一个陪玩机器人
function zhajinhua_table:get_robot()
	if #self.robot_info < 3 then
		local guid = 0 - #self.robot_info - 1
		local android_player = zhj_android:new()
		local account  =  "android_"..tostring(guid)
		local nickname =  "android_"..tostring(guid)
		android_player:init(guid, account, nickname)
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
function zhajinhua_table:reset_robot(android)
	if android.is_player then
		return
	end
	android.round = random.boost_integer(2,5)
	android.cur = 0
	if def_second_game_type == 1 then
		android.money = random.boost_integer(120,500) * 100 + random.boost_integer(0,100)
	elseif def_second_game_type == 2 then
		android.money = random.boost_integer(120,500) * 100 + random.boost_integer(0,100)
	elseif def_second_game_type == 3 then
		android.money = random.boost_integer(400,800) * 100 + random.boost_integer(0,100)
	elseif def_second_game_type == 4 then
		android.money = random.boost_integer(1300,2900) * 100 + random.boost_integer(0,100)
	elseif def_second_game_type == 5 then
		android.money = random.boost_integer(2300,3800) * 100 + random.boost_integer(0,100)
	end
	android:reset_show()
end

--释放机器人
function zhajinhua_table:robot_leave(android)
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
function zhajinhua_table:robot_start_game()
	local max_chair_id = 0
	local max_cards_type = 0
	for k,v in pairs(self.player_cards_type_) do
		if v.cards_type > max_cards_type then
			max_chair_id = k
			max_cards_type = v.cards_type
		elseif v.cards_type == max_cards_type then
			local ret = self:compare_cards(self.player_cards_type_[k], self.player_cards_type_[max_chair_id])
			if ret then
				max_chair_id = k
				max_cards_type = v.cards_type
			end
		end

	end
	for _,v in pairs(self.robot_info) do
		v.android:set_maxcards(false)
		if v.is_use and v.android.chair_id == max_chair_id then
			v.android:set_maxcards(true)
		end
	end
	self.robot_islog = false
	for _,v in pairs(self.players) do
		if v and v.is_player then
			self.robot_islog = true
			break
		end
	end
end

function zhajinhua_table:start_add_score_timer(time,player)
	local function add_score_timer_func()
		local score = self.last_score
		if self.Round > 1 then
			local r = random.boost_integer(1,100)
			if player:is_max() then
				if r < 70 and self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					add_timer(random.boost_integer(2,4),add_score_timer_func)
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
							add_timer(random.boost_integer(2,4),add_score_timer_func)
						else
							score = 1
						end
					end
				end
			else
				if r < 90 and self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					add_timer(random.boost_integer(2,4),add_score_timer_func)
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
							add_timer(random.boost_integer(2,4),add_score_timer_func)
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
					add_timer(random.boost_integer(2,4),add_score_timer_func)
				else
					score = 1
				end
			else
				--弃牌
				if self.is_look_card_[player.chair_id] == false then
					--看牌
					self:look_card(player)
					add_timer(random.boost_integer(2,4),add_score_timer_func)
				else
					self:give_up(player)
				end
			end
		end
		if self:is_compare_card() then
			log.error("is compare card guid[%d]", player.guid)
			return
		end
		if score and self:check_com_cards(player) == false then
			self:add_score(player, score)
		else
			log.error("guid[%d] add score No score", player.guid)
		end
	end
	add_timer(time,add_score_timer_func)
end

--全比
function zhajinhua_table:check_com_cards(player)
	local cout = 0
	for k,v in pairs(self.is_dead_) do
		if v == false then
			cout = cout + 1
		end
	end
	local last_score = self.last_score
	if self.is_look_card_[player.chair_id] then
		last_score = self.last_score * 2
	end
	local player_score = self:get_player_money(player)
	if player_score < last_score and self.is_dead_[player.chair_id] == false and cout >= 3 then
		--触发全比
		local money_ = player_score
		score_ = money_
		self:cost_player_money(player,money_)
		self.betscore[self.betscore_count_] = score_
		self.betscore_count_ = self.betscore_count_ + 1
		--self.last_score = score_
		self.player_score[player.chair_id] = score_
		local playermoney = self.player_money[player.chair_id] + money_
		self.player_money[player.chair_id] = playermoney
		self.all_money = self.all_money + money_

		--日志处理
		local process = {
			chair_id = player.chair_id,
			score = player_score, -- 注码
			money = player_score,
			turn = self.Round,
			isallscore = false ,  --是否全压
			isallcom = true, --是否为全比
		}
		table.insert(self.gamelog.add_score, process)

		local notify = {
			add_score_chair_id = player.chair_id,
			cur_chair_id = self.cur_turn,
			score = score_,
			money = money_,
			is_all = false,
		}

		self:broadcast2client("SC_ZhaJinHuaAddScore", notify)

		local max_chair_id = 0
		local max_cards_type = 0
		for k,v in pairs(self.player_cards_type_) do
			if self.is_dead_[k] == false then
				if v.cards_type > max_cards_type then
					max_chair_id = k
					max_cards_type = v.cards_type
				elseif v.cards_type == max_cards_type then
					local ret = self:compare_cards(self.player_cards_type_[k], self.player_cards_type_[max_chair_id])
					if ret then
						max_chair_id = k
						max_cards_type = v.cards_type
					end
				end
			end
		end
		if max_chair_id == player.chair_id then
			--胜，结算游戏
			self:all_compare()
			print("check_com_cards =====> win")
		else
			--负，继续游戏
			self.is_dead_[player.chair_id] = true
			self.player_status[player.chair_id] = PLAYER_LOSE
			self.dead_count_ = self.dead_count_  + 1

			if self.cur_turn > player.chair_id then
				self.Round_Times = self.Round_Times + 1
			end

			local notify = {
				lose_chair_id = player.chair_id,
				cur_chair_id = self.cur_turn,
			}
			if(player.chair_id == self.cur_turn) then
				self:next_turn()
				self:next_round()
				self.time0_ = get_second_time()
			end
			notify.cur_chair_id = self.cur_turn
			self:broadcast2client("SC_ZhaJinHuaAllComCards", notify)
			print("check_com_cards =====> lose")
		end
		return true
	end
	return false
end

--黑名单处理
function zhajinhua_table:check_black_user()
	--检查概率
	if self.black_rate < random.boost_integer(1,100) then
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
			local ret = self:compare_cards(self.player_cards_type_[k], self.player_cards_type_[max_chair_id])
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
	local swap_chair_id = white[random.boost_integer(1,#white)].chair_id
	self.player_cards_type_[max_chair_id] = deepcopy(self.player_cards_type_[swap_chair_id])
	self.player_cards_type_[swap_chair_id] = deepcopy(max_cards_type)
	--------------------------------------------------------
	local max_cards = deepcopy(self.gamer_player[max_chair_id].card)
	self.gamer_player[max_chair_id].card = deepcopy(self.gamer_player[swap_chair_id].card)
	self.gamer_player[swap_chair_id].card = deepcopy(max_cards)
	--------------------------------------------------------
	self.player_cards_[max_chair_id] = deepcopy(self.player_cards_[swap_chair_id])
	self.player_cards_[swap_chair_id] = deepcopy(max_cards)

	--更新日志记录
	self.gamelog.cards[max_chair_id].card = deepcopy(self.gamelog.cards[swap_chair_id].card)
	self.gamelog.cards[swap_chair_id].card = deepcopy(max_cards)
	-------------
	print("----------------------------------------------------------------------------------------------------------")
	print(self.players[max_chair_id].guid,"===>",self.players[swap_chair_id].guid)
	print("----------------------------------------------------------------------------------------------------------")
end

return zhajinhua_table