-- 骰宝逻辑

local pb = require "pb"
require "data.land_data"
require "game.shaibao.gamelogic"
require "game.shaibao.robot_name"
local base_table = require "game.lobby.base_table"
require "table_func"
require "functions"

local random = require "random"
local many_shaibao_room_config = many_shaibao_room_config
require "timer"
local add_timer = add_timer

require "game.shaibao.shaibao_robot"
require "game.lobby.base_bonus"
local shaibao_android = shaibao_android

-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local LOG_MONEY_OPT_TYPE_SHAIBAO = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_SHAIBAO")
local LOG_MONEY_OPT_TYPE_SHAIBAO_PRIZEPOOL = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_SHAIBAO_PRIZEPOOL")

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query
local redis_cmd_do = redis_cmd_do
local get_second_time = get_second_time

local STATE_BET = pb.enum("SHAIBAO_STATE", "STATE_BET")
local STATE_GAMEOVER = pb.enum("SHAIBAO_STATE", "STATE_GAMEOVER")
local STATE_WAIT = pb.enum("SHAIBAO_STATE", "STATE_WAIT")

local BET_XIAO    = pb.enum("SHAIBAO_BET_AREA", "BET_XIAO")
local BET_DA      = pb.enum("SHAIBAO_BET_AREA", "BET_DA")
local BET_ZD_WS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_1")
local BET_ZD_WS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_2")
local BET_ZD_WS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_3")
local BET_ZD_WS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_4")
local BET_ZD_WS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_5")
local BET_ZD_WS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_6")
local BET_RY_WS   = pb.enum("SHAIBAO_BET_AREA", "BET_RY_WS")
local BET_ZD_DS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_1")
local BET_ZD_DS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_2")
local BET_ZD_DS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_3")
local BET_ZD_DS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_4")
local BET_ZD_DS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_5")
local BET_ZD_DS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_6")
local BET_ZD_SS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_1")
local BET_ZD_SS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_2")
local BET_ZD_SS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_3")
local BET_ZD_SS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_4")
local BET_ZD_SS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_5")
local BET_ZD_SS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_6")
local BET_DH_4    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_4")
local BET_DH_5    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_5")
local BET_DH_6    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_6")
local BET_DH_7    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_7")
local BET_DH_8    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_8")
local BET_DH_9    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_9")
local BET_DH_10   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_10")
local BET_DH_11   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_11")
local BET_DH_12   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_12")
local BET_DH_13   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_13")
local BET_DH_14   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_14")
local BET_DH_15   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_15")
local BET_DH_16   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_16")
local BET_DH_17   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_17")


local TIME_WAITE = 3
local TIME_BET = 15
local TIME_OVER = 15

--走势数量
local THREND_COUNT = 20


shaibao_table = base_table:new()

-- 初始化
function shaibao_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.robot_bet = {} --机器人下注
	for i=BET_XIAO,BET_DH_17 do
		table.insert(self.robot_bet,0)
	end
	self.broadcast_money = 200000
	self.broadcast_led = {} --led
	self.offline_user = {} --离线列表
	self.chips = {1,2,3,4,5,6} --筹码
	self.max_bet = 10000000 --最大下注总额
	self.cur_bet = 0 --当前总下注
	self.show_tax = false --是否显示税收

	self.show_list = {} --玩家展示列表
	self.state = STATE_WAIT --游戏状态
	self.bet = {} --下注区域
	for i=BET_XIAO,BET_DH_17 do
		table.insert(self.bet,0)
	end
	self.bet_log = {} --下注回放
	self.player_bet_info = {} --玩家下注信息
	self.game_trend = {} --游戏走势
	self.gamelog = {
		money = 0, --系统收益
		tax = 0, --税收
		bet = {},--下注信息
		result = {},--开牌信息
		user = {},--玩家信息
	} --游戏日志
	self.update_info_time = get_second_time()
	self.timer_start_time = get_second_time()
	self.timer_next_time = get_second_time() + TIME_WAITE + table_id
	self.robot_cur_bet = 0
		
	--控制概率
	self.sys_ra = 10 --系统必杀概率
	self.normal_ra = 80 --普通开牌概率
	self.equal_ra = 10 --平局开牌概率
	self.normal = {}
	self.normal.kill = 10 
	self.normal.baozi = 2
	self.kill_money = 10000000 --强制杀分

	self:prize_pool_init()
 
	--测试
	--[[add_timer(10,function ()
		for i=1,3 do
			--添加一个机器人
			local guid = -1000 - i
			local android_player = shaibao_android:new()
			local account  =  "android_"..tostring(guid)
			local nickname =  "android_"..tostring(guid)
			android_player:init(self.room_.id, guid, account, nickname)
			android_player:set_table(self)
			android_player:set_action(i)
			for i,p in pairs(self.player_list_) do
				if p == nil or p == false then	
					android_player:think_on_sit_down(self.room_.id, self.table_id_, i)
					--self:player_sit_down(ap,i)
					self.ready_list_[i] = true
					break
				end
			end
		end
	end)--]]
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

function shaibao_table:load_lua_cfg()
	print ("--------------------load_lua_cfg", self.room_.room_cfg)
	log.info(string.format("shaibao_table: game_maintain_is_open = [%d]",self.room_.game_switch_is_open))
	--local funtemp = load(self.room_.room_cfg)
	--local cfg = funtemp()
	local cfg = json.decode(self.room_.room_cfg)
	if cfg and cfg.broadcast_money then
		self.broadcast_money = cfg.broadcast_money
	end
	if cfg and cfg.max_bet then
		self.max_bet = cfg.max_bet
	end
	if cfg and cfg.kill_money then
		self.kill_money = cfg.kill_money
	end
	if cfg and cfg.sys_ra then
		self.sys_ra = cfg.sys_ra
	end
	if cfg and cfg.normal_ra then
		self.normal_ra = cfg.normal_ra
	end
	if cfg and cfg.equal_ra then
		self.equal_ra = cfg.equal_ra
	end
	if cfg and cfg.normal and cfg.normal.kill then
		self.normal.kill = cfg.normal.kill
	end
	if cfg and cfg.normal and cfg.normal.baozi then
		self.normal.baozi = cfg.normal.baozi
	end
	
	if cfg and cfg.chips then
		self.chips = deepcopy(cfg.chips)
	end
	if self.room_.tax_show_ == 1 then
		self.show_tax = true
	else
		self.show_tax = false
	end
	
	dump(cfg)
	for k,v in pairs(self.prizepool_cfg) do
		if k and cfg and cfg.prizepool and cfg.prizepool[k] then
			self.prizepool_cfg[k] = tonumber(cfg.prizepool[k])
		end
	end

	dump(self.prizepool_cfg)
end


-- 判断是否游戏中
function  shaibao_table:is_play( player )
	if player and self.player_bet_info[player.guid] and self.player_bet_info[player.guid].bet > 0 then
		return true
	end
	return false
end

-- 检查是否可取消准备
function shaibao_table:check_cancel_ready(player, is_offline)
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
function shaibao_table:tick()
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
function shaibao_table:add_score(player,msg)
	if msg == nil or msg.area == nil or msg.money == nil or msg.money <= 0 or player:get_money() <= 0 then
		return
	end
	if self.player_bet_info[player.guid] == nil then
		local inf = {bet=0,area={},player=player,money=0,tax=0}
		for i=BET_XIAO,BET_DH_17 do
			table.insert(inf.area,0)
		end
		self.player_bet_info[player.guid] = inf
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
		else
			return
		end
	end
	local money = player:get_money() - self.player_bet_info[player.guid].bet
	local sc = {
		money = money,
		pb_areas = {},
		pb_scores = {},
		errno = errno
	}
	for i=BET_XIAO,BET_DH_17 do
		table.insert(sc.pb_areas,{area = i,money = self:get_area_bet(i)})
		table.insert(sc.pb_scores,{area = i,money = self.player_bet_info[player.guid].area[i]})
	end
	send2client_pb(player, "SC_ShaiBaoBetResult", sc)
end

--检查玩家下注区域
function shaibao_table:player_can_bet(player,area)
	if self.state ~= STATE_BET then
		return false
	end
	return true
end

--游戏开始
 function shaibao_table:game_start()
	self:start()
	--检查奖池是否关闭
	if self:prize_pool_is_open() == false then
		if  self.prizepool_cfg.time_end < get_second_time() or not self.prizepool_cfg.is_open then
			self:prize_pool_init()
		end
		self:broadcast2client("SC_ShaiBaoPrizePool",{money = 0})
	end

	--初始化日志
	self:next_game()
	self.game_id = self:get_now_game_id()
	--self.gamelog.time_start = get_second_time()
	self.game_start_time = get_second_time()
	self.gamelog.money = 0
	self.gamelog.tax = 0
	
	self.gamelog.result = {}
	self.gamelog.user = {}
	self.robot_cur_bet = 0
	self.robot_bet = {}
	self.robot_bet_info = {}
	for i=BET_XIAO,BET_DH_17 do
		table.insert(self.robot_bet,0)
	end
	
	--开始游戏
	print(self.game_id,"==>","game_start")
	self.state = STATE_BET
	local show = {}
	for k,v in pairs(self.player_list_) do				
		if v then
			table.insert(show,{guid = v.guid,money = v:get_money(),header = v:get_header_icon(),area = v.ip_area})
			local sc = {
				money = v:get_money(),
				pb_areas = {},
				pb_scores = {},
				chips = self.chips,
			}
			for i=BET_XIAO,BET_DH_17 do
				table.insert(sc.pb_areas,{area=i,money=0})
				table.insert(sc.pb_scores,{area=i,money=0})
			end
			send2client_pb(v, "SC_ShaiBaoBetResult", sc)
		end				
	end
	--添加显示机器人
	if self.robot_show == nil or random.boost_integer(1,100) <= 50 then
		self.robot_show = {}
		for i = 1,10 do
			table.insert(self.robot_show,{guid = -i,money = random.boost_integer(30000,200000),header = random.boost_integer(1,10),area = robot_ip_area[random.boost_integer(1,#robot_ip_area)]})
		end
	end
	for _,v in pairs(self.robot_show) do
		if v.money < 30000 then
			v.money = random.boost_integer(30000,200000)
		end
		table.insert(show,v)
		local inf = {bet = 0,area={}}
		for i=BET_XIAO,BET_DH_17 do
			table.insert(inf.area,0)
		end
		self.robot_bet_info[v.guid] = inf
	end
	
	
	--[[if #show >= 2 then
		table.sort(show, function (a, b)
			return a.money > b.money
		end)
	end--]]
	
	self.show_list = {}
	local msg = {}
	msg.state = STATE_BET
	msg.time = TIME_BET
	for _,v in pairs(show) do
		if #self.show_list < 60 then
			table.insert(self.show_list,v)
		else
			break
		end
	end
	msg.pb_users = self.show_list
	msg.pb_trends = self.game_trend
	self:broadcast2client("SC_ShaiBaoStart", msg)
	self.timer_start_time = get_second_time()
	--add_timer(TIME_BET,function ()
	--	self:game_over()
	--end)
end

function shaibao_table:rand_result(must_kill)
	self.gamelog.ctrl = 0
	local ra_type = random.boost_integer(1,100)
	--必杀,11必杀开
	if ra_type <= self.sys_ra or must_kill then
		self.gamelog.ctrl = 10
		if self.bet[BET_RY_WS] == 0 then
			local idx = random.boost_integer(0,5)
			for i=1,6 do
				local num = tonumber((i + idx) % 6)
				if num == 1 and self.bet[BET_ZD_WS_1] == 0 and self.bet[BET_ZD_DS_1] == 0 then
					self.gamelog.ctrl = self.gamelog.ctrl + 1
					return {num,num,num}
				elseif num == 2 and self.bet[BET_ZD_WS_2] == 0 and self.bet[BET_ZD_DS_2] == 0 and self.bet[BET_DH_6] == 0 then
					self.gamelog.ctrl = self.gamelog.ctrl + 1
					return {num,num,num}
				elseif num == 3 and self.bet[BET_ZD_WS_3] == 0 and self.bet[BET_ZD_DS_3] == 0 and self.bet[BET_DH_9] == 0 then
					self.gamelog.ctrl = self.gamelog.ctrl + 1
					return {num,num,num}
				elseif num == 4 and self.bet[BET_ZD_WS_4] == 0 and self.bet[BET_ZD_DS_4] == 0 and self.bet[BET_DH_12] == 0 then
					self.gamelog.ctrl = self.gamelog.ctrl + 1
					return {num,num,num}
				elseif num == 5 and self.bet[BET_ZD_WS_5] == 0 and self.bet[BET_ZD_DS_5] == 0 and self.bet[BET_DH_15] == 0 then
					self.gamelog.ctrl = self.gamelog.ctrl + 1
					return {num,num,num}
				elseif num == 6 and self.bet[BET_ZD_WS_6] == 0 and self.bet[BET_ZD_DS_6] == 0 then
					self.gamelog.ctrl = self.gamelog.ctrl + 1
					return {num,num,num}
				end
			end
		end
	end
	--平局,2平局开，12必杀平局开
	if ra_type <= self.equal_ra + self.sys_ra or must_kill then
		self.gamelog.ctrl = self.gamelog.ctrl + 2
		local tmp_result = {}
		for n=1,6 do
			for j=1,6 do
				for k=1,6 do
					if n ~= j or n ~= k or j ~= k then
						local cards = {n,j,k}
						local money = 0
						for i=BET_XIAO,BET_DH_17 do
							if self.bet[i] > 0 and gamelogic.GetCardsTimes(cards,i) > 0 then
								money = money + self.bet[i]*(gamelogic.GetCardsTimes(cards,i))
							end
						end
						table.insert(tmp_result,{money = money,result = cards})
					end
				end
			end
		end
		table.sort(tmp_result, function (a, b)
			return a.money < b.money
		end)
		local result = {}
		local min = tmp_result[1].money
		for _,v in pairs(tmp_result) do
			if v.money == min then
				table.insert(result,v.result)
			end
		end
		return result[random.boost_integer(1,#result)]
	end
	--普通豹子,3普通豹子，4普通大小
	if random.boost_integer(1,100) <= self.normal.baozi then
		self.gamelog.ctrl = 3
		local num = random.boost_integer(1,6)
		return {num,num,num}
	else
		self.gamelog.ctrl = 4
		local small = gamelogic.GetPointCards(4,10)
		local big = gamelogic.GetPointCards(11,17)
		local smoney = 0
		local bmoney = 0
		for i=BET_XIAO,BET_DH_17 do
			if self.bet[i] > 0 and gamelogic.GetCardsTimes(small,i) > 0 then
				smoney = smoney + self.bet[i]*(gamelogic.GetCardsTimes(small,i))
			end
			if self.bet[i] > 0 and gamelogic.GetCardsTimes(big,i) > 0 then
				bmoney = bmoney + self.bet[i]*(gamelogic.GetCardsTimes(big,i))
			end
		end
		if bmoney > smoney then
			if random.boost_integer(1,100) <= (50 - self.normal.kill) then
				return big
			else
				return small
			end
		else
			if random.boost_integer(1,100) <= (50 - self.normal.kill) then
				return small
			else
				return big
			end
		end
	end
	return {1,2,3}
end

--游戏结算
function shaibao_table:game_over()
	print(self.game_id,"==>","game_over")
	self:update_info(true)
	self.state = STATE_GAMEOVER
	--计算输赢
	self.result = self:rand_result(false)
	local result_money = 0
	for i=BET_XIAO,BET_DH_17 do
		if self.bet[i] > 0 and gamelogic.GetCardsTimes(self.result,i) > 0 then
			result_money = result_money + self.bet[i]*(gamelogic.GetCardsTimes(self.result,i))
		end
	end
	if result_money >= self.kill_money then
		self.gamelog.kill_money = result_money
		self.gamelog.kill_result = deepcopy(self.result)
		self.result = self:rand_result(true)
	end
	print_cards(self.result,self.game_id)
	
	
	--日志
	self.gamelog.result = self.result
	self.gamelog.bet = self.bet
	--self.gamelog.time_end = get_second_time()
	
	local msg = {}
	msg.state = STATE_GAMEOVER
	msg.time = TIME_OVER
	msg.pb_game = {sz1=self.result[1],sz2=self.result[2],sz3=self.result[3]}
	msg.pb_trends = deepcopy(self.game_trend)

	table.insert(self.game_trend,1,{sz1=self.result[1],sz2=self.result[2],sz3=self.result[3]})
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
			local user = {guid = guid,area = deepcopy(v.area),money = 0,tax = 0,smoney = v.player:get_money(),emoney = 0}
			msg.money = 0
			local money = 0
			for i=BET_XIAO,BET_DH_17 do
				if v.area[i] > 0 and gamelogic.GetCardsTimes(self.result,i) > 0 then
					money = money + v.area[i]*(gamelogic.GetCardsTimes(self.result,i) + 1)
				end
			end
			money = money - v.bet
			if money > 0 then
				--收5%的税收
				user.tax = money
				money = math.ceil(money * (1 - self.room_.tax_))
				user.tax = user.tax - money
				v.tax = user.tax
				msg.money = money
				v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money}}, LOG_MONEY_OPT_TYPE_SHAIBAO)
				if money >= self.broadcast_money and v.player.is_player then
					table.insert(self.broadcast_led,{nickname = v.player.nickname,money = money / 100})
				end
				if money >= bigwin.money then
					bigwin.area = v.player.ip_area
					bigwin.money = money
					bigwin.header = v.player:get_header_icon()
				end
			elseif money < 0 then
				msg.money = money
				v.player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -money}}, LOG_MONEY_OPT_TYPE_SHAIBAO)
			end
			v.money = msg.money
			user.money = v.money
			msg.cur_money = v.player:get_money()
			if self.show_tax then
				msg.tax = v.tax
			else
				msg.tax = nil
			end
			
			--send2client_pb(v.player,"SC_ShaiBaoEnd",msg)
			table.insert(endmsg,{player = v.player,msg = deepcopy(msg)})
			
			--日志
			if v.bet > 0 then
				user.emoney = v.player:get_money()
				table.insert(self.gamelog.user,user)
				self.gamelog.tax = self.gamelog.tax + user.tax
				self.gamelog.money = self.gamelog.money - user.money
				if user.money >= 0 then
					self:player_money_log(v.player,2,user.smoney,user.tax,user.money,self.game_id)
				else
					self:player_money_log(v.player,1,user.smoney,user.tax,user.money,self.game_id)
				end

				v.player:check_and_create_bonus()
			end
		end
	end
	--计算机器人收益
	for guid,v in pairs(self.robot_bet_info) do
		local money = 0
		for i=BET_XIAO,BET_DH_17 do
			if v.area[i] > 0 and gamelogic.GetCardsTimes(self.result,i) > 0 then
				money = money + v.area[i]*(gamelogic.GetCardsTimes(self.result,i) + 1)
			end
		end
		money = money - v.bet
		if money > 0 then
			--收5%的税收
			money = math.ceil(money * (1 - self.room_.tax_))
			if money >= self.broadcast_money then
				table.insert(self.broadcast_led,{nickname = robot_name[random.boost_integer(1,#robot_name)],money = money / 100})
			end
			if money >= bigwin.money then
				for _,robot in pairs(self.robot_show) do
					if robot.guid == guid then
						bigwin.area = robot.area
						bigwin.money = money
						bigwin.header = robot.header
						robot.money = robot.money + money
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



	if self.cur_bet > 0 then
		--写日志
		local s_log = json.encode(self.gamelog)
		print(s_log)
		self:save_game_log(self.game_id, self.def_game_name, s_log, self.game_start_time, get_second_time())
	end
	
	--通知下注玩家
	for _,v in pairs(endmsg) do
		--增加奖池奖励
		if v.player and v.player.guid and lucky_users[v.player.guid] then
			local smoney = v.player:get_money()
			local money = lucky_users[v.player.guid]
			if money > 100 then
				v.msg.prize_money = money
				v.msg.prize_join = 1
				v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money}}, LOG_MONEY_OPT_TYPE_SHAIBAO_PRIZEPOOL)
				self:player_money_log(v.player,2,smoney,0,money,self.gamelog.id)
				v.msg.cur_money = v.player:get_money()
				table.insert(self.prizepool_led,{nickname = v.player.nickname,money = money / 100})
			end
		elseif v.player and v.player.guid and join_users[v.player.guid] then
			v.msg.prize_join = 1
		end

		send2client_pb(v.player,"SC_ShaiBaoEnd",v.msg)
	end
	
	--通知围观者
	msg.money = 0
	if self.show_tax then
		msg.tax = 0
	else
		msg.tax = nil
	end
	for _,v in pairs(self.player_list_) do
		if v and self.player_bet_info[v.guid] == nil then
			msg.cur_money = v:get_money()
			send2client_pb(v,"SC_ShaiBaoEnd",msg)
		end
	end

	self.timer_start_time = get_second_time()

end

--游戏等待
function shaibao_table:game_wait()
	print(self.game_id,"==>","game_wait")
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
	for i=BET_XIAO,BET_DH_17 do
		self.bet[i] = 0
	end
	self.bet_log = {}
	self.player_bet_info = {}

	--处理掉线
	for _,v in pairs(self.player_list_) do
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
	self:broadcast2client("SC_ShaiBaoWait", msg)
	self.timer_start_time = get_second_time()
	--add_timer(TIME_WAITE,function ()
	--	self:game_start()
	--end)
end

function shaibao_table:player_money_log(player,s_type,s_old_money,s_tax,s_change_money,s_id)
	local nMsg = {
		guid = player.guid,
		type = s_type,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		phone_type = player.phone_type,
		old_money = s_old_money,
		new_money = player.pb_base_info.money,
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

--机器人下注
function shaibao_table:robot_add_score(robot,area,money)
	if robot.money >= money and self.cur_bet + self.robot_cur_bet + money <= self.max_bet then
		self.robot_bet[area] = self.robot_bet[area] + money
		table.insert(self.bet_log,{guid = robot.guid,area = area,money = money})
		robot.money = robot.money - money
		self.robot_bet_info[robot.guid].area[area] = self.robot_bet_info[robot.guid].area[area] + money
		self.robot_bet_info[robot.guid].bet = self.robot_bet_info[robot.guid].bet + money
		self.robot_cur_bet = self.robot_cur_bet + money
	end
end

--更新下注
function shaibao_table:update_info(over)
	if get_second_time() > self.update_info_time or over then
		--机器人下注
		if self.state == STATE_BET and self.timer_next_time - get_second_time() <= random.boost_integer(10,14) and self.timer_next_time - get_second_time() > 2 then
			local rnum = random.boost_integer(3,10)
			for i = 1,rnum do
				local robot = self.robot_show[random.boost_integer(1,#self.robot_show)]
				--指定豹子
				if random.boost_integer(1,100) <= 5 then
					local area = random.boost_integer(BET_ZD_WS_1,BET_ZD_WS_6)
					local money = self.chips[1]
					self:robot_add_score(robot,area,money)
				end
				--任一豹子
				if random.boost_integer(1,100) <= 5 then
					local area = BET_RY_WS
					local money = self.chips[random.boost_integer(1,2)]
					self:robot_add_score(robot,area,money)
				end
				--指定双骰
				if random.boost_integer(1,100) <= 5 then
					local area = random.boost_integer(BET_ZD_SS_1,BET_ZD_SS_6)
					local money = self.chips[random.boost_integer(1,3)]
					self:robot_add_score(robot,area,money)
				end
				--指定点
				if random.boost_integer(1,100) <= 15 then
					local area = random.boost_integer(BET_ZD_DS_1,BET_ZD_DS_6)
					local money = self.chips[random.boost_integer(1,4)]
					self:robot_add_score(robot,area,money)
				end
				--指定点和
				if random.boost_integer(1,100) <= 40 then
					local num = 1
					for i=1,num do
						local area = random.boost_integer(BET_DH_4,BET_DH_17)
						local money = self.chips[random.boost_integer(1,2)]
						self:robot_add_score(robot,area,money)
					end
				end
				--大小
				if random.boost_integer(1,100) <= 55 then
					local num = random.boost_integer(1,3)
					for i=1,num do
						local area = random.boost_integer(1,100) <= 50 and BET_XIAO or BET_DA
						local money = self.chips[random.boost_integer(1,4)]
						self:robot_add_score(robot,area,money)
					end
				end
			end
		end
		
		local msg = {
			pb_bets = {},
			pb_areas = {},
		}
		for i=BET_XIAO,BET_DH_17 do
			table.insert(msg.pb_areas,{area=i,money = self:get_area_bet(i)})
		end
		for _,v in pairs(self.bet_log) do
			table.insert(msg.pb_bets,v)
		end
		if #msg.pb_bets > 0 then
			self:broadcast2client("SC_ShaiBaoUpdate",msg)
		end
		self.bet_log = {}
		self.update_info_time = get_second_time() + 1
	end
end

function shaibao_table:get_area_bet(area)
	return self.bet[area] + self.robot_bet[area]
end

--玩家进入
function shaibao_table:player_enter(player)
	print("enter",player.guid)
	self.offline_user[player.guid] = false
	--同步下注信息
	if self.player_bet_info[player.guid] == nil then
		local inf = {bet=0,area={},player=player,money=0,tax=0}
		for i=BET_XIAO,BET_DH_17 do
			table.insert(inf.area,0)
		end
		self.player_bet_info[player.guid] = inf
	end
	local money = player:get_money() - self.player_bet_info[player.guid].bet
	if self.state == STATE_GAMEOVER then
		money = player:get_money()
	end
	local sc = {
		money = money,
		pb_areas = {},
		pb_scores = {},
		chips = self.chips,
	}
	for i=BET_XIAO,BET_DH_17 do
		table.insert(sc.pb_areas,{area=i,money=self:get_area_bet(i)})
		table.insert(sc.pb_scores,{area=i,money=self.player_bet_info[player.guid].area[i]})
	end
	send2client_pb(player, "SC_ShaiBaoBetResult", sc)

	if self:prize_pool_is_open() then
		send2client_pb(player, "SC_ShaiBaoPrizePool",{money = self.prizepool.show})
	end

	--同步当前状态
	if self.state == STATE_WAIT then
		local msg = {}
		msg.state = STATE_WAIT
		msg.time = self.timer_start_time - get_second_time() + TIME_WAITE
		msg.pb_trends = self.game_trend
		send2client_pb(player,"SC_ShaiBaoWait", msg)
	elseif self.state == STATE_BET then
		local msg = {}
		msg.state = STATE_BET
		msg.time = self.timer_start_time - get_second_time() + TIME_BET
		msg.pb_users = self.show_list
		msg.pb_trends = self.game_trend
		send2client_pb(player,"SC_ShaiBaoStart", msg)
	else
		local msg = {}
		msg.state = STATE_GAMEOVER
		msg.time = self.timer_start_time - get_second_time() + TIME_OVER
		msg.pb_game = {sz1=self.result[1],sz2=self.result[2],sz3=self.result[3]}
		msg.pb_trends = self.game_trend
		msg.money = self.player_bet_info[player.guid].money
		msg.cur_money = player:get_money()
		send2client_pb(player,"SC_ShaiBaoEnd",msg)
	end
end


--奖池系统
function shaibao_table:prize_pool_init()
	local str = '{"open":0,"time_start":0,"time_end":0,"pool_origin":1,"pool_prize":10,"pool_max":5,"pool_lucky":0.5,"bet_add":5,"prize_count":100,"prize_limit":47900,"showpool_add":70,"showpool_sub":30,"showpool_add_min":100,"showpool_add_max":5000,"showpool_sub_min":300,"showpool_sub_max":1000,"showpool_led":25}'
	self.prizepool = {pool = 0,show = 0,count = 0,prize = 0}
	self.prizepool_show_time = get_second_time() + 3
	self.prizepool_cfg = json.decode(str)
	self.prizepool.show = random.boost_integer(10000,100000)
	self.prizepool_led = {}
end

--是否开放
function shaibao_table:prize_pool_is_open()
	local now = get_second_time()
	if self.prizepool_cfg.open == 1 and self.prizepool_cfg.time_start < now and now < self.prizepool_cfg.time_end then
		return true
	end
	return false
end

--更新奖池
function shaibao_table:prize_pool_show()
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
	self:broadcast2client("SC_ShaiBaoPrizePool",{money = self.prizepool.show})
end

--计算参与的玩家
function shaibao_table:prize_pool_players()
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
function shaibao_table:prize_pool_game(users,money)
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