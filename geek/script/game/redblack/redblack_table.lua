-- 红黑逻辑

local pb = require "pb_files"
require "data.land_data"
local robot_ip_area = robot_ip_area
require "game.redblack.gamelogic"
require "game.redblack.robot_name"
local base_table = require "game.lobby.base_table"
require "table_func"
require "game.lobby.base_bonus"
local random = require "random"
local many_redblack_room_config = many_redblack_room_config
require "timer"
local add_timer = add_timer
local json = require "cjson"
local log = require "log"


-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local LOG_MONEY_OPT_TYPE_REDBLACK = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_REDBLACK")
local LOG_MONEY_OPT_TYPE_REDBLACK_PRIZEPOOL = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_REDBLACK_PRIZEPOOL")

local STATE_BET = pb.enum("REDBLACK_STATE", "STATE_BET")
local STATE_GAMEOVER = pb.enum("REDBLACK_STATE", "STATE_GAMEOVER")
local STATE_WAIT = pb.enum("REDBLACK_STATE", "STATE_WAIT")

local BET_R = pb.enum("REDBLACK_BET_AREA", "BET_R")
local BET_B = pb.enum("REDBLACK_BET_AREA", "BET_B")
local BET_S = pb.enum("REDBLACK_BET_AREA", "BET_S")


local TIME_WAITE = 3
local TIME_BET = 12
local TIME_OVER = 10

--走势数量
local THREND_COUNT = 50


local redblack_table = base_table:new()

-- 初始化
function redblack_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.robot_bet = {0,0,0} --机器人下注
	self.broadcast_money = 200000
	self.broadcast_led = {} --led
	self.offline_user = {} --离线列表
	self.chips = {1,2,3,4,5,6} --筹码
	self.max_bet = 10000000 --最大下注总额
	self.cur_bet = 0 --当前总下注
	self.show_tax = false --是否显示税收
	self.sys_win_ra = 5 --系统必赢概率
	self.special_ra = 0 --特殊牌概率
	self.double_ra = 0 --对牌概率
	self.special_cards_ra = {
		baozi = 0, --豹子
		shunjin = 0, --顺金
		jinhua = 0, --金花
		shunzi = 0, --顺子
		double = 0, --对子
	}
	
	self.show_list = {} --玩家展示列表
	self.state = STATE_WAIT --游戏状态
	self.bet = {0,0,0} --下注区域
	self.bet_log = {} --下注回放
	self.player_bet_info = {} --玩家下注信息
	self.game_trend = {} --游戏走势
	self.gamelog = {
		id = 0, 
		time_start = 0,
		time_end = 0,
		ctrl = 0,--控制类型
		type = 0,--牌型
		money = 0, --系统收益
		tax = 0, --税收
		bet = {},--下注信息
		cards = {},--开牌信息
		user = {},--玩家信息
	} --游戏日志
	self.update_info_time = get_second_time()
	self.timer_start_time = get_second_time()
	self.timer_next_time = get_second_time() + TIME_WAITE
	
	--赢钱记录
	self.robot_win_record = {}
	self.player_win_record = {}
	
	self:prize_pool_init()
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

function redblack_table:load_lua_cfg()
	print ("--------------------load_lua_cfg", self.room_.room_cfg)
	log.info("redblack_table: game_maintain_is_open = [%s]",self.room_.game_switch_is_open)
	--local funtemp = load(self.room_.room_cfg)
	--local cfg = funtemp()
	local cfg = json.decode(self.room_.room_cfg)
	if cfg and cfg.broadcast_money then
		self.broadcast_money = cfg.broadcast_money
	end
	if cfg and cfg.max_bet then
		self.max_bet = cfg.max_bet
	end
	if cfg and cfg.sys_win_ra then
		self.sys_win_ra = cfg.sys_win_ra
	end
	if cfg and cfg.special_ra then
		self.special_ra = cfg.special_ra
	end
	if cfg and cfg.double_ra then
		self.double_ra = cfg.double_ra
	end
	if cfg and cfg.special_cards_ra and cfg.special_cards_ra.baozi then
		self.special_cards_ra.baozi = cfg.special_cards_ra.baozi
	end
	if cfg and cfg.special_cards_ra and cfg.special_cards_ra.shunjin then
		self.special_cards_ra.shunjin = cfg.special_cards_ra.shunjin
	end
	if cfg and cfg.special_cards_ra and cfg.special_cards_ra.jinhua then
		self.special_cards_ra.jinhua = cfg.special_cards_ra.jinhua
	end
	if cfg and cfg.special_cards_ra and cfg.special_cards_ra.shunzi then
		self.special_cards_ra.shunzi = cfg.special_cards_ra.shunzi
	end
	if cfg and cfg.special_cards_ra and cfg.special_cards_ra.double then
		self.special_cards_ra.double = cfg.special_cards_ra.double
	end
	if cfg and cfg.chips then
		self.chips = deepcopy(cfg.chips)
	end
	if self.room_.tax_show_ == 1 then
		self.show_tax = true
	else
		self.show_tax = false
	end
	
	for k,v in pairs(self.prizepool_cfg) do
		if k and cfg and cfg.prizepool and cfg.prizepool[k] then
			self.prizepool_cfg[k] = tonumber(cfg.prizepool[k])
		end
	end
end


-- 判断是否游戏中
function  redblack_table:is_play( player )
	if player and self.player_bet_info[player.guid] and self.player_bet_info[player.guid].bet > 0 then
		return true
	end
	return false
end

-- 检查是否可取消准备
function redblack_table:check_cancel_ready(player, is_offline)
	if player and self.player_bet_info[player.guid] and self.player_bet_info[player.guid].bet > 0 then
		if is_offline then
			self.offline_user[player.guid] = true
			print("offline",player.guid)
		end
		return false
	end
	--退出
	return true
end

-- 心跳
function redblack_table:tick()
	self:update_info(false)
	if get_second_time() >= self.timer_next_time and self.state == STATE_WAIT then
		self:game_start()
		self.timer_next_time = get_second_time() + TIME_BET
	elseif get_second_time() >= self.timer_next_time and self.state == STATE_BET then
		self:game_over()
		self.timer_next_time = get_second_time() + TIME_OVER
	elseif get_second_time() >= self.timer_next_time and self.state == STATE_GAMEOVER then
		self:game_wait()
		self.timer_next_time = get_second_time() + TIME_WAITE
	end
	self:prize_pool_show()
end

--下注
function redblack_table:add_score(player,msg)
	if msg == nil or msg.area == nil or msg.money == nil or msg.money <= 0 or player:get_money() <= 0 then
		return
	end
	if self.player_bet_info[player.guid] == nil then
		self.player_bet_info[player.guid] = {bet = 0 ,area = {0,0,0},player = player,money = 0,tax = 0}
	end
	local errno = 10086
	if self.cur_bet + self.robot_cur_bet + msg.money <= self.max_bet then
		errno = nil
		local v = msg
		if self:player_can_bet(player,v.area) and player:get_money() - self.player_bet_info[player.guid].bet >= v.money then
			self.bet[v.area] = self.bet[v.area] + v.money
			self.player_bet_info[player.guid].area[v.area] = self.player_bet_info[player.guid].area[v.area] + v.money
			self.player_bet_info[player.guid].bet = self.player_bet_info[player.guid].bet + v.money
			self.cur_bet = self.cur_bet + v.money
			table.insert(self.bet_log,{guid = player.guid,area = v.area,money = v.money})
			if player.guid == self.lucky_guid then
				self.lucky_area[v.area] = self.lucky_area[v.area]
			end
		else
			return
		end
	end
	local money = player:get_money() - self.player_bet_info[player.guid].bet
	local sc = {
		money = money,
		pb_areas = {
			{area = BET_R,money = self:get_area_bet(BET_R)},
			{area = BET_B,money = self:get_area_bet(BET_B)},
			{area = BET_S,money = self:get_area_bet(BET_S)},
		},
		pb_scores = {
			{area = BET_R,money = self.player_bet_info[player.guid].area[BET_R]},
			{area = BET_B,money = self.player_bet_info[player.guid].area[BET_B]},
			{area = BET_S,money = self.player_bet_info[player.guid].area[BET_S]},
		},
		errno = errno
	}
	send2client_pb(player, "SC_RedblackBetResult", sc)
end

--检查玩家下注区域
function redblack_table:player_can_bet(player,area)
	if self.state ~= STATE_BET then
		return false
	end
	if self.player_bet_info[player.guid] then
		if area == BET_R and self.player_bet_info[player.guid].area[BET_B] > 0 then
			return false
		end
		if area == BET_B and self.player_bet_info[player.guid].area[BET_R] > 0 then
			return false
		end
	end
	return true
end

--游戏开始
function redblack_table:game_start()
	self:start()
	--检查奖池是否关闭
	if self:prize_pool_is_open() == false then
		if  self.prizepool_cfg.time_end < get_second_time() or not self.prizepool_cfg.is_open then
			self:prize_pool_init()
		end
		self:broadcast2client("SC_RedblackPrizePool",{money = 0})
	end
	--初始化日志
	self:next_game()
	self.gamelog.id = self:get_now_game_id()
	self.gamelog.time_start = get_second_time()
	self.gamelog.money = 0
	self.gamelog.tax = 0
	self.gamelog.bet = {}
	self.gamelog.cards = {}
	self.gamelog.user = {}
	self.robot_bet = {0,0,0}
	self.robot_cur_bet = 0
	self.robot_bet_info = {}
	self.lucky_area = {}
	--开始游戏
	--print(self.gamelog.id,"==>","game_start")
	self.state = STATE_BET
	local show = {}
	for k,v in pairs(self.players) do				
		if v then
			table.insert(show,{guid = v.guid,money = v:get_money(),header = v:get_header_icon(),area = v.ip_area})
			if self.player_win_record[v.guid] == nil then
				self.player_win_record[v.guid] = {count = 0,money = 0}
			end
			local sc = {
				money = v:get_money(),
				pb_areas = {
					{area = BET_R,money = 0},
					{area = BET_B,money = 0},
					{area = BET_S,money = 0},
				},
				pb_scores = {
					{area = BET_R,money = 0},
					{area = BET_B,money = 0},
					{area = BET_S,money = 0},
				},
				chips = self.chips,
			}
			send2client_pb(v, "SC_RedblackBetResult", sc)
		end				
	end
	--添加显示机器人
	if self.robot_show == nil then
		self.robot_show = {}
		for i = 1,10 do
			table.insert(self.robot_show,{guid = -i,money = random.boost_integer(30000,200000),header = random.boost_integer(1,10),area = robot_ip_area[random.boost_integer(1,#robot_ip_area)]})
			self.robot_win_record[-i] = {count = 0,money = 0}
		end
	end
	for _,v in pairs(self.robot_show) do
		if v.money < 30000 or random.boost_integer(1,100) < 10 then
			v.money = random.boost_integer(30000,200000)
			v.header = random.boost_integer(1,10)
			v.area = robot_ip_area[random.boost_integer(1,#robot_ip_area)]
			self.robot_win_record[v.guid] = {count = 1,money = 0}
		end
		table.insert(show,v)
		self.robot_bet_info[v.guid] = {bet = 0,area = {0,0,0}}
	end
	
	if #show >= 2 then
		table.sort(show, function (a, b)
			return a.money > b.money
		end)
	end
	
	self.show_list = {}
	local msg = {}
	msg.state = STATE_BET
	msg.time = TIME_BET
	for _,v in pairs(show) do
		if #self.show_list < 8 then
			table.insert(self.show_list,deepcopy(v))
		else
			break
		end
	end
	--添加幸运星
	local lucky_user = {guid = 0, count = 0, money = 0}
	for k,v in pairs(self.player_win_record) do
		for _,player in pairs(self.players) do
			if player and player.guid == k and (v.count > lucky_user.count or (v.count == lucky_user.count and v.money > lucky_user.money) ) and k ~= show[1].guid then
				lucky_user.guid = k
				lucky_user.count = v.count
				lucky_user.money = v.money
			end
		end
	end
	for k,v in pairs(self.robot_win_record) do
		if (v.count > lucky_user.count or (v.count == lucky_user.count and v.money > lucky_user.money) ) and k ~= show[1].guid then
			lucky_user.guid = k
			lucky_user.count = v.count
			lucky_user.money = v.money
		end
	end
	local lucky_find = false
	for _,v in pairs(self.show_list) do
		if v.guid == lucky_user.guid then
			v.lucky = true
			lucky_find = true
		end
	end
	if lucky_find == false then
		for _,v in pairs(show) do
			if v.guid == lucky_user.guid then
				lucky_find = true
				local user = deepcopy(v)
				user.lucky = true
				table.insert(self.show_list,user)
			end
		end
	end
	
	self.lucky_guid = lucky_user.guid
	
	--如果不存在幸运星，显示列表中随机产生一个
	if lucky_find == false then
		local v = self.show_list[random.boost_integer(1,#self.show_list)]
		v.lucky = true
		self.lucky_guid = v.guid
	end

	print("lucky_user ==>",self.lucky_guid)
	
	msg.pb_users = self.show_list
	msg.pb_trends = self.game_trend
	self:broadcast2client("SC_RedblackStart", msg)
	self.timer_start_time = get_second_time()
	
end

--生成牌
function redblack_table:rand_cards()
	local red,black = gamelogic.RandCards()
	local redinfo = gamelogic.BuildCardsInfo(red)
	local blackinfo = gamelogic.BuildCardsInfo(black)
	local ra = random.boost_integer(1,100)
	self.gamelog.ctrl = 0
	--必杀
	if self.sys_win_ra > 0 and self.sys_win_ra >= ra then
		self.gamelog.ctrl = 1
		while true do
			if redinfo.cards_type == REDBLACK_CARD_TYPE_SINGLE and blackinfo.cards_type == REDBLACK_CARD_TYPE_SINGLE then
				if self.bet[BET_R] > self.bet[BET_B] then
					if gamelogic.CompareCards(redinfo,blackinfo) then
						--红黑换牌
						return blackinfo,redinfo
					end
					return redinfo,blackinfo
				else
					if gamelogic.CompareCards(redinfo,blackinfo) == false then
						--红黑换牌
						return blackinfo,redinfo
					end
					return redinfo,blackinfo
				end
			end
			red,black = gamelogic.RandCards()
			redinfo = gamelogic.BuildCardsInfo(red)
			blackinfo = gamelogic.BuildCardsInfo(black)
		end
	--特殊
	elseif self.special_ra > 0 and self.special_ra + self.sys_win_ra >= ra then
		self.gamelog.ctrl = 2
		local ra_sp = random.boost_integer(1,100)
		--豹子
		if self.special_cards_ra.baozi >= ra_sp then
			red,black = gamelogic.RandCardsType(REDBLACK_CARD_TYPE_BAO_ZI)
			redinfo = gamelogic.BuildCardsInfo(red)
			blackinfo = gamelogic.BuildCardsInfo(black)
			return redinfo,blackinfo
		--顺金
		elseif self.special_cards_ra.shunjin > 0 and self.special_cards_ra.shunjin + self.special_cards_ra.baozi >= ra_sp then
			red,black = gamelogic.RandCardsType(REDBLACK_CARD_TYPE_SHUN_JIN)
			redinfo = gamelogic.BuildCardsInfo(red)
			blackinfo = gamelogic.BuildCardsInfo(black)
			return redinfo,blackinfo
		--金花
		elseif self.special_cards_ra.jinhua > 0 and self.special_cards_ra.jinhua + self.special_cards_ra.shunjin + self.special_cards_ra.baozi >= ra_sp then
			red,black = gamelogic.RandCardsType(REDBLACK_CARD_TYPE_JIN_HUA)
			redinfo = gamelogic.BuildCardsInfo(red)
			blackinfo = gamelogic.BuildCardsInfo(black)
			return redinfo,blackinfo
		--顺子
		elseif self.special_cards_ra.shunzi > 0 and self.special_cards_ra.shunzi + self.special_cards_ra.jinhua + self.special_cards_ra.shunjin + self.special_cards_ra.baozi >= ra_sp then
			red,black = gamelogic.RandCardsType(REDBLACK_CARD_TYPE_SHUN_ZI)
			redinfo = gamelogic.BuildCardsInfo(red)
			blackinfo = gamelogic.BuildCardsInfo(black)
			return redinfo,blackinfo
		end
	--对牌
	elseif self.double_ra > 0 and self.double_ra + self.special_ra + self.sys_win_ra >= ra then
		self.gamelog.ctrl = 3
		local ra_db = random.boost_integer(1,100)
		if self.special_cards_ra.double > 0 and self.special_cards_ra.double >= ra_db then
			red,black = gamelogic.RandCardsType(REDBLACK_CARD_TYPE_DOUBLE)
			redinfo = gamelogic.BuildCardsInfo(red)
			blackinfo = gamelogic.BuildCardsInfo(black)
			return redinfo,blackinfo
		end
	end
	--普通
	while true do
		if redinfo.cards_type == REDBLACK_CARD_TYPE_SINGLE and blackinfo.cards_type == REDBLACK_CARD_TYPE_SINGLE then
			break
		end
		red,black = gamelogic.RandCards()
		redinfo = gamelogic.BuildCardsInfo(red)
		blackinfo = gamelogic.BuildCardsInfo(black)
	end
	return redinfo,blackinfo
end

--游戏结算
function redblack_table:game_over()
	--print(self.gamelog.id,"==>","game_over")
	self:update_info(true)
	self.state = STATE_GAMEOVER
	--计算输赢
	self.wininfo = {}
	self.redinfo,self.blackinfo = self:rand_cards()
	print_cards(self.redinfo.cards,self.gamelog.id)
	print_cards(self.blackinfo.cards,self.gamelog.id)
	local result = gamelogic.CompareCards(self.redinfo,self.blackinfo)
	if result then
		self.wininfo = self.redinfo
		self.winarea = BET_R
	else
		self.wininfo = self.blackinfo
		self.winarea = BET_B
	end
	
	
	--日志
	self.gamelog.type = self.wininfo.cards_type
	self.gamelog.cards.red = {cards = self.redinfo.cards,type = self.redinfo.cards_type}
	self.gamelog.cards.black = {cards = self.blackinfo.cards,type = self.blackinfo.cards_type}
	self.gamelog.cards.special = gamelogic.GetCardsTimes(self.wininfo)
	self.gamelog.bet = {red = self.bet[BET_R],black = self.bet[BET_B],special = self.bet[BET_S]}
	self.gamelog.time_end = get_second_time()
	
	local msg = {}
	msg.state = STATE_GAMEOVER
	msg.time = TIME_OVER
	msg.pb_game = {}
	msg.pb_game.redcards = self.redinfo.cards
	msg.pb_game.blackcards = self.blackinfo.cards
	msg.pb_game.redtype = self.redinfo.cards_type
	msg.pb_game.blacktype = self.blackinfo.cards_type
	msg.pb_game.redlight = gamelogic.GetCardsTimes(self.redinfo)
	msg.pb_game.blacklight = gamelogic.GetCardsTimes(self.blackinfo)
	msg.pb_game.winarea = self.winarea
	msg.pb_game.special = gamelogic.GetCardsTimes(self.wininfo)
	msg.pb_trends = deepcopy(self.game_trend)
	
	table.insert(self.game_trend,1,{area = self.winarea,type = self.wininfo.cards_type,light = gamelogic.GetCardsTimes(self.wininfo),})
	local count = #self.game_trend
	if count >= THREND_COUNT  then
		self.game_trend[count] = nil
	end

	--记录结算消息
	local endmsg = {}
	--大赢家
	local bigwin = {area = '',money = 0,header = 0}
	
	--通知下注玩家
	--self.player_bet_info[player.guid] = {bet = 0 ,area = {0,0,0},player = player}
	for guid,v in pairs(self.player_bet_info) do
		if v.player then
			-- 下注流水
			self:player_bet_flow_log(v.player,v.bet)

			local user = {guid = guid,red = v.area[BET_R],black = v.area[BET_B],special = v.area[BET_S],money = 0,tax = 0,smoney = v.player:get_money(),emoney = 0}
			msg.money = 0
			local money = 0
			if v.area[BET_R] > 0 and self.winarea == BET_R then
				money = money + v.area[BET_R] * 2
			end
			if v.area[BET_B] > 0 and self.winarea == BET_B then
				money = money + v.area[BET_B] * 2
			end
			if v.area[BET_S] > 0 and gamelogic.GetCardsTimes(self.wininfo) > 0 then
				money = money + v.area[BET_S] * (gamelogic.GetCardsTimes(self.wininfo))
			end
			money = money - v.bet
			if money > 0 then
				--收5%的税收
				user.tax = money
				money = math.ceil(money * (1 - self.room_.tax))
				user.tax = user.tax - money
				v.tax = user.tax
				msg.money = money
				v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money}}, LOG_MONEY_OPT_TYPE_REDBLACK)
				if money >= self.broadcast_money and v.player.is_player then
					table.insert(self.broadcast_led,{nickname = v.player.nickname,money = money / 100})
				end
				if money >= bigwin.money then
					bigwin.area = v.player.ip_area
					bigwin.money = money
					bigwin.header = v.player:get_header_icon()
				end
				--记录输赢数据
				if self.player_win_record[guid] == nil then
					self.player_win_record[guid] = {count = 0,money = 0}
				end
				self.player_win_record[guid].count = self.player_win_record[guid].count + 1
				self.player_win_record[guid].money = self.player_win_record[guid].money + money
			elseif money < 0 then
				msg.money = money
				v.player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -money}}, LOG_MONEY_OPT_TYPE_REDBLACK)
			end
			v.money = msg.money
			user.money = v.money
			msg.cur_money = v.player:get_money()
			if self.show_tax then
				msg.tax = v.tax
			else
				msg.tax = nil
			end
			--print("game_over score",v.bet,"==>",v.money)
			--send2client_pb(v.player,"SC_RedblackEnd",msg)
			table.insert(endmsg,{player = v.player,msg = deepcopy(msg)})
			--日志
			if v.bet > 0 then
				user.emoney = v.player:get_money()
				table.insert(self.gamelog.user,user)
				self.gamelog.tax = self.gamelog.tax + user.tax
				self.gamelog.money = self.gamelog.money - user.money
				if user.money >= 0 then
					self:player_money_log(v.player,2,user.smoney,user.tax,user.money,self.gamelog.id)
				else
					self:player_money_log(v.player,1,user.smoney,user.tax,user.money,self.gamelog.id)
				end

				v.player:check_and_create_bonus()
			end
		end
	end

	--计算机器人收益
	for guid,v in pairs(self.robot_bet_info) do
		local money = 0
		if v.area[BET_R] > 0 and self.winarea == BET_R then
			money = money + v.area[BET_R] * 2
		end
		if v.area[BET_B] > 0 and self.winarea == BET_B then
			money = money + v.area[BET_B] * 2
		end
		if v.area[BET_S] > 0 and gamelogic.GetCardsTimes(self.wininfo) > 0 then
			money = money + v.area[BET_S] * (gamelogic.GetCardsTimes(self.wininfo))
		end
		money = money - v.bet
		if money > 0 then
			--收5%的税收
			money = math.ceil(money * (1 - self.room_.tax))
			if money >= bigwin.money then
				for _,robot in pairs(self.robot_show) do
					if robot.guid == guid then
						bigwin.area = robot.area
						bigwin.money = money
						bigwin.header = robot.header
						robot.money = robot.money + money
						--记录输赢数据
						self.robot_win_record[guid].count = self.robot_win_record[guid].count + 1
						self.robot_win_record[guid].money = self.robot_win_record[guid].money + money
					end
				end
			end
		end
	end
	--增加大赢家
	if bigwin.money >= 100000 then
		for _,v in pairs(endmsg) do
			v.msg.pb_bigwin = {header = bigwin.header,money = bigwin.money,area = bigwin.area}
		end
		msg.pb_bigwin = {header = bigwin.header,money = bigwin.money,area = bigwin.area}
	end
	
	--奖池
	local join_users = self:prize_pool_players()
	local lucky_users = self:prize_pool_game(join_users,self.gamelog.money)

	--通知下注玩家
	for _,v in pairs(endmsg) do
		--增加奖池奖励
		if v.player and v.player.guid and lucky_users[v.player.guid] then
			local smoney = v.player:get_money()
			local money = lucky_users[v.player.guid]
			if money > 100 then
				v.msg.prize_money = money
				v.msg.prize_join = 1
				v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money}}, LOG_MONEY_OPT_TYPE_REDBLACK_PRIZEPOOL)
				self:player_money_log(v.player,2,smoney,0,money,self.gamelog.id)
				v.msg.cur_money = v.player:get_money()
				table.insert(self.prizepool_led,{nickname = v.player.nickname,money = money / 100})
			end
		elseif v.player and v.player.guid and join_users[v.player.guid] then
			v.msg.prize_join = 1
		end
		send2client_pb(v.player,"SC_RedblackEnd",v.msg)
	end	
	
	--通知围观者
	msg.money = 0
	if self.show_tax then
		msg.tax = 0
	else
		msg.tax = nil
	end
	for _,v in pairs(self.players) do
		if v and self.player_bet_info[v.guid] == nil then
			msg.cur_money = v:get_money()
			send2client_pb(v,"SC_RedblackEnd",msg)
		end
	end

	if self.gamelog.bet.red > 0 or self.gamelog.bet.black > 0 or self.gamelog.bet.special > 0 then
		--写日志
		local s_log = json.encode(self.gamelog)
		print(s_log)
		self:save_game_log(self.gamelog.id, self.def_game_name, s_log, self.gamelog.time_start, self.gamelog.time_end)
	end

	--清除输赢统计
	for guid,v in pairs(self.player_win_record) do
		if self.player_bet_info[guid] == nil or self.player_bet_info[guid].bet == 0 then
			print("clean player win record ==>",guid)
			self.player_win_record[guid] = {count = 0,money = 0}
		end
	end

	self.timer_start_time = get_second_time()

end

--游戏等待
function redblack_table:game_wait()
	--print(self.gamelog.id,"==>","game_wait")
	--led
	for _,v in pairs(self.broadcast_led) do
		broadcast_world_marquee(def_first_game_type,def_second_game_type,0,v.nickname,v.money)
	end
	for _,v in pairs(self.prizepool_led) do
		broadcast_world_marquee(def_first_game_type,def_second_game_type,1,v.nickname,v.money)
	end
	self.broadcast_led = {}
	self.prizepool_led = {}
	self.state = STATE_WAIT
	self.cur_bet = 0
	self.bet = {0,0,0}
	self.bet_log = {}
	self.player_bet_info = {}

	--处理掉线
	for _,v in pairs(self.players) do
		if v then
			if self.offline_user[v.guid] then
				print("forced_exit",v.guid)
				v:forced_exit()
			end
			send2client_pb(v,"SC_Gamefinish",{
				money = v:get_money()
			})
		end
	end
	self.offline_user = {}
	self:check_single_game_is_maintain()
	local msg = {}
	msg.state = STATE_WAIT
	msg.time = TIME_WAITE
	msg.pb_trends = self.game_trend
	self:broadcast2client("SC_RedblackWait", msg)
	self.timer_start_time = get_second_time()
	--add_timer(TIME_WAITE,function ()
	--	self:game_start()
	--end)
end

function redblack_table:player_money_log(player,s_type,s_old_money,s_tax,s_change_money,s_id)
	local nMsg = {
		guid = player.guid,
		type = s_type,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		phone_type = player.phone_type,
		old_money = s_old_money,
		new_money = player.money,
		tax = s_tax,
		change_money = s_change_money,
		ip = player.ip,
		id = s_id,
		channel_id = player.create_channel_id,
		platform_id = player.platform_id,
		get_bonus_money = 0,
		to_bonus_money = 0,
		seniorpromoter = player.seniorpromoter,
	}
	send2db_pb("SL_Log_Money",nMsg)

	player:increase_play_info(s_change_money)
end

--更新下注
function redblack_table:update_info(over)
	if get_second_time() > self.update_info_time or over then
		--机器人下注
		if self.state == STATE_BET and self.timer_next_time - get_second_time() <= random.boost_integer(10,14) and self.timer_next_time - get_second_time() > 1 then
			local rnum = random.boost_integer(3,10)
			for i = 1,rnum do
				local robot = self.robot_show[random.boost_integer(1,#self.robot_show)]
				local num = random.boost_integer(2,5)
				for j = 1,num do
					local money = self.chips[random.boost_integer(1,5)]
					local ra = random.boost_integer(1,100)
					local area = BET_S
					if ra <= 45 then
						area = BET_R
					elseif ra <= 90 then
						area = BET_B
					end
					if area == BET_R and self.robot_bet_info[robot.guid].area[BET_B] > 0 then
					elseif area == BET_B and self.robot_bet_info[robot.guid].area[BET_R] > 0 then
					else
						if robot.money >= money and self.cur_bet + self.robot_cur_bet + money <= self.max_bet then
							self.robot_bet[area] = self.robot_bet[area] + money
							table.insert(self.bet_log,{guid = robot.guid,area = area,money = money})
							robot.money = robot.money - money
							self.robot_bet_info[robot.guid].area[area] = self.robot_bet_info[robot.guid].area[area] + money
							self.robot_bet_info[robot.guid].bet = self.robot_bet_info[robot.guid].bet + money
							self.robot_cur_bet = self.robot_cur_bet + money
							if robot.guid == self.lucky_guid then
								self.lucky_area[area] = area
							end
						end
					end
				end
			end
		end
		
		local msg = {
			pb_bets = {},
			pb_areas = {
				{area = BET_R,money = self:get_area_bet(BET_R)},
				{area = BET_B,money = self:get_area_bet(BET_B)},
				{area = BET_S,money = self:get_area_bet(BET_S)},
			},
		}
		for _,v in pairs(self.bet_log) do
			table.insert(msg.pb_bets,v)
		end
		if #msg.pb_bets > 0 then
			msg.lucky = self.lucky_area
			self:broadcast2client("SC_RedblackUpdate",msg)
		end
		self.bet_log = {}
		self.update_info_time = get_second_time() + 1
	end
end

function redblack_table:get_area_bet(area)
	return self.bet[area] + self.robot_bet[area]
end

--玩家进入
function redblack_table:player_enter(player)
	print("enter",player.guid)
	self.offline_user[player.guid] = false
	--同步下注信息
	if self.player_bet_info[player.guid] == nil then
		self.player_bet_info[player.guid] = {bet = 0 ,area = {0,0,0},player = player,money = 0,tax = 0}
	end
	local money = player:get_money() - self.player_bet_info[player.guid].bet
	if self.state == STATE_GAMEOVER then
		money = player:get_money()
	end
	local sc = {
		money = money,
		pb_areas = {
			{area = BET_R,money = self:get_area_bet(BET_R)},
			{area = BET_B,money = self:get_area_bet(BET_B)},
			{area = BET_S,money = self:get_area_bet(BET_S)},
		},
		pb_scores = {
			{area = BET_R,money = self.player_bet_info[player.guid].area[BET_R]},
			{area = BET_B,money = self.player_bet_info[player.guid].area[BET_B]},
			{area = BET_S,money = self.player_bet_info[player.guid].area[BET_S]},
		},
		chips = self.chips,
	}
	send2client_pb(player, "SC_RedblackBetResult", sc)
	
	if self:prize_pool_is_open() then
		send2client_pb(player, "SC_RedblackPrizePool",{money = self.prizepool.show})
	end
	
	--同步当前状态
	if self.state == STATE_WAIT then
		local msg = {}
		msg.state = STATE_WAIT
		msg.time = self.timer_start_time - get_second_time() + TIME_WAITE
		msg.pb_trends = self.game_trend
		send2client_pb(player,"SC_RedblackWait", msg)
	elseif self.state == STATE_BET then
		local msg = {}
		msg.state = STATE_BET
		msg.time = self.timer_start_time - get_second_time() + TIME_BET
		msg.pb_users = self.show_list
		msg.pb_trends = self.game_trend
		send2client_pb(player,"SC_RedblackStart", msg)
	else
		local msg = {}
		msg.state = STATE_GAMEOVER
		msg.time = self.timer_start_time - get_second_time() + TIME_OVER
		msg.pb_game = {}
		msg.pb_game.redcards = self.redinfo.cards
		msg.pb_game.blackcards = self.blackinfo.cards
		msg.pb_game.redtype = self.redinfo.cards_type
		msg.pb_game.blacktype = self.blackinfo.cards_type
		msg.pb_game.redlight = gamelogic.GetCardsTimes(self.redinfo)
		msg.pb_game.blacklight = gamelogic.GetCardsTimes(self.blackinfo)
		msg.pb_game.winarea = self.winarea
		msg.pb_game.special = gamelogic.GetCardsTimes(self.wininfo)
		msg.pb_trends = self.game_trend
		msg.money = self.player_bet_info[player.guid].money
		msg.cur_money = player:get_money()
		send2client_pb(player,"SC_RedblackEnd",msg)
	end
end


--奖池系统
function redblack_table:prize_pool_init()
	local str = '{"open":0,"time_start":0,"time_end":0,"pool_origin":1,"pool_prize":10,"pool_max":5,"pool_lucky":0.5,"bet_add":5,"prize_count":100,"prize_limit":47900,"showpool_add":70,"showpool_sub":30,"showpool_add_min":100,"showpool_add_max":5000,"showpool_sub_min":300,"showpool_sub_max":1000,"showpool_led":25}'
	self.prizepool = {pool = 0,show = 0,count = 0,prize = 0}
	self.prizepool_show_time = get_second_time() + 3
	self.prizepool_cfg = json.decode(str)
	self.prizepool.show = random.boost_integer(10000,100000)
	self.prizepool_led = {}
end

--是否开放
function redblack_table:prize_pool_is_open()
	local now = get_second_time()
	if self.prizepool_cfg.open == 1 and self.prizepool_cfg.time_start < now and now < self.prizepool_cfg.time_end then
		return true
	end
	return false
end

--更新奖池
function redblack_table:prize_pool_show()
	if self:prize_pool_is_open() == false then
		return
	end
	if get_second_time() < self.prizepool_show_time then
		return
	end
	self.prizepool_show_time = get_second_time() + 3
	local show_ra = random.boost_integer(1,100)
	if show_ra < self.prizepool_cfg.showpool_add and self.prizepool.show < 100000000 then
		self.prizepool.show = self.prizepool.show + random.boost_integer(self.prizepool_cfg.showpool_add_min,self.prizepool_cfg.showpool_add_max)
	elseif show_ra >= self.prizepool_cfg.showpool_add and show_ra < self.prizepool_cfg.showpool_sub + self.prizepool_cfg.showpool_add then
		self.prizepool.show = self.prizepool.show - random.boost_integer(self.prizepool_cfg.showpool_sub_min,self.prizepool_cfg.showpool_sub_max)
	end

	if self.prizepool.show < 0 then
		self.prizepool.show = 0
	end
	--通知更新奖池
	self:broadcast2client("SC_RedblackPrizePool",{money = self.prizepool.show})
end

--计算参与的玩家
function redblack_table:prize_pool_players()
	if self:prize_pool_is_open() == false then
		return {}
	end
	local users = {}
	for guid,v in pairs(self.player_bet_info) do
		if v.player and v.bet > 0 and v.player.is_guest == false then
			local ra = self.prizepool_cfg.bet_add * (v.bet / 100000)
			if ra > self.prizepool_cfg.bet_add then
				ra = self.prizepool_cfg.bet_add
			end
			ra = ra + self.prizepool_cfg.pool_lucky
			users[guid] = ra
		end
	end

	return users
end

--抽奖
function redblack_table:prize_pool_game(users,money)
	if self:prize_pool_is_open() == false then
		return {}
	end
	self.gamelog.prizepool = 0
	self.gamelog.prizemoney = 0
	self.gamelog.prizeusers = {}
	local luckyusers = {}
	--增加实际奖池
	if money > 0 and self.prizepool.pool + money < self.prizepool_cfg.pool_max * self.prizepool_cfg.prize_limit then
		self.prizepool.pool = self.prizepool.pool + math.ceil(money * self.prizepool_cfg.pool_origin / 100)
		if self.prizepool.pool > self.prizepool_cfg.pool_max * self.prizepool_cfg.prize_limit then
			self.prizepool.pool = self.prizepool_cfg.pool_max * self.prizepool_cfg.prize_limit
		end
	end
	--检查是否已达发奖上限
	if self.prizepool.prize >= self.prizepool_cfg.prize_limit then
		if random.boost_integer(1,100) < self.prizepool_cfg.showpool_led then
			--机器人中间LED
			local money = math.ceil(self.prizepool.pool * self.prizepool_cfg.pool_prize / 100)
			if money > 100 then
				table.insert(self.prizepool_led,{nickname = robot_name[random.boost_integer(1,#robot_name)],money = money / 100})
			end
		end
	else
		for k,v in pairs(users) do
			if random.boost_integer(1,100) < v and self.prizepool.prize < self.prizepool_cfg.prize_limit then
				local prize = math.ceil(self.prizepool.pool * self.prizepool_cfg.pool_prize / 100)
				self.prizepool.prize = self.prizepool.prize + prize
				self.prizepool.pool = self.prizepool.pool - prize
				--通知中奖玩家
				self.gamelog.prizeusers[tostring(k)] = prize
				self.gamelog.prizemoney = self.gamelog.prizemoney + prize
				luckyusers[k] = prize
			end
		end
	end
	self.prizepool.count = self.prizepool.count + 1
	if self.prizepool.count > self.prizepool_cfg.prize_count then
		self.prizepool.count = 0
		self.prizepool.prize = 0
	end
	self.gamelog.prizepool = self.prizepool.pool
	return luckyusers
end

return redblack_table