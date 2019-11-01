-- 老虎机逻辑
local pb = require "pb_files"

local random = require "random"
local log = require "log"

require "data.slotma_data"
local slotma_col_num = slotma_col_num
local slotma_row_num = slotma_row_num
local slotma_lines   = slotma_lines
local slotma_items   = slotma_items
local slotma_room_config   = slotma_room_config
local slotma_results = {slotma_results_line1,slotma_results_line2,slotma_results_line3,slotma_results_line4,slotma_results_line5,slotma_results_line6,slotma_results_line7,slotma_results_line8,slotma_results_line9}
local slotma_times   = {slotma_times_line1,slotma_times_line2,slotma_times_line3,slotma_times_line4,slotma_times_line5,slotma_times_line6,slotma_times_line7,slotma_times_line8,slotma_times_line9}


local base_table = require "game.lobby.base_table"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.slotma.slotma_line"
local slotma_line = slotma_line

require "game.slotma.slotma_item"
local slotma_item = slotma_item


local LOG_MONEY_OPT_TYPE_SLOTMA = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_SLOTMA")

local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

-- enum LAND_CARD_TYPE
local SLOTMA_TYPE_SUCESS = pb.enum("SLOTMA_TYPE", "SLOTMA_TYPE_SUCESS")					--成功
local SLOTMA_TYPE_ERRORID = pb.enum("SLOTMA_TYPE", "SLOTMA_TYPE_ERRORID")				--chairid错误
local SLOTMA_TYPE_NOMONEY = pb.enum("SLOTMA_TYPE", "SLOTMA_TYPE_NOMONEY")				--金钱不足
local SLOTMA_TYPE_LINERROR = pb.enum("SLOTMA_TYPE", "SLOTMA_TYPE_LINERROR")				--线型错误
local SLOTMA_TYPE_NOLINE = pb.enum("SLOTMA_TYPE", "SLOTMA_TYPE_NOLINE")					--未选择线型

local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type

-- 老虎机中奖池的图标id
local SLOTMA_BONUS_SYMBOL = 9
--老虎机奖池开关
local SLOTMA_BONUS_OPEN   = 1

--赢钱金额的百分比进入奖池
local BONUS_POOL_RATE = 0.01

--中奖公告标准,超过该标准全服公告
local SLOTMA_GRAND_PRICE_BASE = 1000

--黑名单修改机率
local black_rate = 0

local slotma_prize_pool = g_prize_pool

local slotma_table = base_table:new()
-- 初始化
function slotma_table:init(room, table_id, chair_count)

	--
	base_table.init(self, room, table_id, chair_count)
	self.slotma_line_list = {}
	self.slotma_item_list = {}
	self.playerlinelist_ = {}
	self.cell_times_ = 1

	self.last_game_time_ = 0

	--self:load_lua_cfg()

	for i,v in ipairs(slotma_lines) do
		local t = slotma_line:new()
		t:init(v,slotma_col_num)
		self.slotma_line_list[t.lineID_] = t

	end

	for _,v in ipairs(slotma_items) do
		local t = slotma_item:new()
		t:init(v)
		self.slotma_item_list[t.itemID_] = t
	end

end


-- 检查是否可准备
function slotma_table:check_ready(player)
	return true
end

-- 检查是否可取消准备
function slotma_table:check_cancel_ready(player, is_offline)
	--老虎机没有断线重连，随时可以退出
	return true
end


function  slotma_table:respones(player, n )	
	local notify = {
		status = n
	}
	send2client_pb(player, "SC_SimpleRespons", notify)
end
--选线
function slotma_table:select_line(player,msg)
	--判断线型
	local playerlinelist = {}
	for i,v in ipairs(msg.lines) do
		if self.slotma_line_list[v] ~= nil then
			--log.info("select line",v)
			playerlinelist[i] = self.slotma_line_list[v]
		else
			log.info("error line->%d",v)
			self:respones(player,SLOTMA_TYPE_LINERROR)
		end
	end
	return playerlinelist
end

function  slotma_table:Calculation(items)
	-- body
	local winline = {}
	local timesSum = 0
	for _,v in ipairs(self.playerlinelist_) do
		local getLineResult = v:getResult(items)
		for i,n in pairs(getLineResult) do
			if self.slotma_item_list[i] then
				local times_ = self.slotma_item_list[i]:getTimes(n)
				if times_ > 0 then
					timesSum = timesSum + times_
					tempTab = {
						lineid = v.lineID_,
						itemid = i,
						itemNum = n,
						times = times_,
					}
					log.info("reward lineid->",tempTab.lineid,"itemid->",tempTab.itemid,"itemNum->",n,"times->",tempTab.times)
					table.insert(winline,tempTab)
				end
			end
		end		
	end
	return timesSum,winline
end
function  slotma_table:Check_Result(items)

	local timesSum,winline = self:Calculation(items)

	local money = timesSum * self.room_.cell_score_ * self.cell_times_
	local tax = money * self.room_:get_room_tax()

	local tax_show_ = self.room_.tax_show_
	--不小于1才收税 并且四舍五入
	if tax >= 1 then
		tax = math.floor(tax + 0.5)
	else
		tax = 0
		tax_show_ = 0
	end
	
	local  notify = {
		items = items,
		money = money,
		tax = tax,
		tax_show = tax_show_,
		pb_winline = winline,
	}
	
	return notify,timesSum
end

function  slotma_table:Check_Bonus_Result(items,times)
	local money = times * self.room_.cell_score_ * self.cell_times_
	local tax = money * self.room_:get_room_tax()

	local tax_show_ = self.room_.tax_show_
	   --不小于1才收税 并且四舍五入
	if tax >= 1 then
		tax = math.floor(tax + 0.5)
	else
		tax = 0
		tax_show_ = 0
	end

	local notify = {
		items = items,
		money = money,
		tax = tax,
		tax_show = tax_show_,
		pb_winline = {},
	}
	return notify,times
end

function slotma_table:load_lua_cfg()
	-- log.info("slotma_table: game_maintain_is_open = [%s]",self.room_.game_switch_is_open)
	local funtemp = load(self.room_.room_cfg)
	slotma_room_config = funtemp()
	if slotma_room_config.black_rate ~= nil then
		black_rate = slotma_room_config.black_rate
	end
	
end

--玩家进入游戏或者断线重连
function slotma_table:PlayerConnectionSlotmaGame(player)
	log.info("playerr[%d] coming slotma game",player.guid)
end

-- 玩家离开游戏
function slotma_table:playerLeaveSlotmaGame(player)
	log.info("player[%d]  leave slotma game",player.guid)
end


--碰撞检测：lineId线 times倍数 addition概率加成
function slotma_table:check_hit(lineId,times,addition)
	if times == 0 then
		return false
	end

	local hit_rate = lineId/(times*9)+lineId*addition/9
	local hit_num =  random.boost_01()
	if hit_num < hit_rate then
		return true
	end

	return false
end

--低倍碰撞
function slotma_table:get_low_times(lineNum)
	--2-8随机倍碰撞
	local times = random.boost_integer(2,8)
	if slotma_results[lineNum][times] ~= nil and self:check_hit(lineNum,times,0) then
		return times
	end

	return 0
end


--从有效倍数中随机N次,如果不中，9线直接给2-8倍，其余低倍随机
function slotma_table:RandomEffectiveTimes(user_random_count,lineNum,min,max)
	--获取所有当前线数的结果
	local current_slotma_results = slotma_results[lineNum]
	--获取线倍数集
	local current_slotma_times = slotma_times[lineNum]

	local max_random_count = 9

	local times_between = {}

	for _,v in ipairs(current_slotma_times) do
		if v >= min and v <= max then
			table.insert(times_between,v)
		end
	end

    --没有有效倍数
	if #times_between == 0 then
		log.info("no right times")
		return self:get_low_times(lineNum)
	end
	-- 5 + 0
	local random_count = slotma_room_config.random_count + user_random_count

	if random_count > max_random_count then
		random_count = max_random_count
	end
	log.info("RandomEffectiveTimes random_count->%d",random_count)

	for i=1,random_count do
		local timesIndex = random.boost_integer(1,#times_between)
		local times = times_between[timesIndex]

		if current_slotma_results[times] ~= nil and self:check_hit(lineNum,times,0) then
			return times
		end
	end

	--9线直接给2-8倍
	if lineNum == 9 then
		return math.random(2,8)
	end

	return self:get_low_times(lineNum)
end

--返回倍数，通过位数获得Items(物品)
function slotma_table:RandomResult(user_random_count,lineNum, is_in_blacklist)
	--2-max_times有效倍数随机
	local times = self:RandomEffectiveTimes(user_random_count,lineNum,2,slotma_room_config.max_times);
	--黑名单判断 机率修改倍数
	if is_in_blacklist and times >= lineNum then
		local temp = random.boost_integer(0,100)
		if temp < black_rate then
			if lineNum < 3 then
				times = 0
			else
				times = random.boost_integer(2, lineNum - 1)
			end
		end
	end

	--判断拿奖池的钱
	local get_bonus_money = false
	local bonus_times = 0
	if SLOTMA_BONUS_OPEN == 1 and times < 9 then
		--是否够100倍底注
		local bonus_limit = 100 * self.room_.cell_score_ * self.cell_times_
		if slotma_prize_pool:get_total_bonus() >= bonus_limit then
			bonus_times = random.boost_integer(50,100)
			if self:check_hit(lineNum,bonus_times,0) then
				get_bonus_money = true
			end
		end
	end

	local items_index = random.boost_integer(1,#slotma_results[lineNum][times])
	return get_bonus_money, slotma_results[lineNum][times][items_index], times, bonus_times
--[[
	if get_bonus_money == true then
		--从9线0倍中找到一个结果
		local items_index = random.boost_integer(1,#slotma_results[9][0])
		local no_prize_result = slotma_results[9][0][items_index]

		local bonus_result = {}
		for i,v in ipairs(no_prize_result) do
			table.insert(bonus_result,v)
		end

		if #bonus_result > 1 then
			local bonus_symbol_index = random.boost_integer(1,#bonus_result)
			bonus_result[bonus_symbol_index] = SLOTMA_BONUS_SYMBOL
		end

		return get_bonus_money, bonus_result, bonus_times

	else
		local items_index = random.boost_integer(1,#slotma_results[lineNum][times])
		return get_bonus_money, slotma_results[lineNum][times][items_index], times
	end
	]]
end


function slotma_table:player_sit_down(player, chair_id_)
	 base_table.player_sit_down(self,player, chair_id_)
	 self.last_game_time_ = 0
end

-- 开始游戏
function slotma_table:slotma_start(player,msg)
	local bRet = base_table.start(self,0)
	--维护开关
	if self.room_.game_switch_is_open == 1 then
		if player and player.vip ~= 100 then
			send2client_pb(player, "SC_GameMaintain", {
				result = GAME_SERVER_RESULT_MAINTAIN,
			})
			log.warning("slotma_table: game_switch_is_open[%d],game will maintain ,exit server.",self.room_.game_switch_is_open)
			return
		end
	end
	--入房条件金钱是否足够
	if player:check_room_limit(self.room_:get_room_limit()) then
		log.warning("slotma_table:check_room_limit guid[%d] chairid[%d]", player.guid, player.chair_id)
		self:respones(player,SLOTMA_TYPE_NOMONEY)
		return
	end	

	log.info("player slotma_start---------> [%d]",player.guid)

	--开始时间
	local start_game_time = get_second_time()

	if msg.cell_times <= 0 then
		log.warning("slotma_table:check_room_limit guid[%d] chairid[%d]", player.guid, player.chair_id)
		self:respones(player,SLOTMA_TYPE_NOMONEY)
		return
	end
	self.cell_times_ = msg.cell_times

	--判断选线
	self.playerlinelist_ = self:select_line(player,msg)

	--选线数量
	local lineNum = #self.playerlinelist_
	log.info("lineNum-> %d",lineNum)

	--判断线数
	if lineNum < 1 or lineNum > 9 then
		log.info("error line-> %d",lineNum)
		self:respones(player,SLOTMA_TYPE_LINERROR)
		return
	end
	
	local cost = lineNum * self.room_.cell_score_ * self.cell_times_
	if cost <= 0 then
		log.warning("slotma_table:check_room_limit guid[%d] chairid[%d]", player.guid, player.chair_id)
		self:respones(player,SLOTMA_TYPE_NOMONEY)
		return
	end

	local old_money = player:get_money()

	--判断线数花费
	if player:get_money() < cost then
		log.warning("slotma_table:select_line guid[%d] chairid[%d] error, Money shortage", player.guid, player.chair_id)
		self:respones(player,SLOTMA_TYPE_NOMONEY)
		return
	end	

	-- 下注流水日志
	self:player_bet_flow_log(player,cost)

	--扣钱
	player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cost}}, LOG_MONEY_OPT_TYPE_SLOTMA)
	self:save_player_collapse_log(player)
	
	local user_random_count = player.slotma_addition
	
	--是否中奖池，奖品，线倍数
	local get_bonus_money,items,times,bonus_times = self:RandomResult(user_random_count,lineNum,self:check_blacklist_player(player.guid))

	local notify,times_sum
	--运算倍数
	notify,times_sum = self:Check_Result(items)
	notify.extra_prize = 0
	notify.total_bonus = slotma_prize_pool:get_total_bonus()
	local to_bonus_money_ = 0
	local get_bonus_money_ = 0


	--开宝箱，拿奖池的钱
	if get_bonus_money == true then
		local bonus_money = bonus_times * self.room_.cell_score_ * self.cell_times_
		bonus_money = slotma_prize_pool:remove_money(bonus_money)
		log.info("guid[%d] bonus_money[%d] times[%d], cell_times_[%d]",player.guid, bonus_money, bonus_times,self.cell_times_)
		notify.money = notify.money + bonus_money
		notify.extra_prize = bonus_money
		notify.total_bonus = slotma_prize_pool:get_total_bonus()
		get_bonus_money_ = bonus_money
		if bonus_money >= SLOTMA_GRAND_PRICE_BASE  then	
			local money_change_str = string.format("%.02f",bonus_money/100)
			broadcast_world_marquee(def_first_game_type, def_second_game_type, 1, player.nickname, money_change_str, bonus_times)	
		end
	else
		--系统赢钱的1%进入奖池
		local sys_earn = cost - notify.money
		if SLOTMA_BONUS_OPEN == 1 and sys_earn > 0 then

			--计算进入奖池的钱
			local to_bonus_pool_money = sys_earn * BONUS_POOL_RATE
			if to_bonus_pool_money < 1 then
				to_bonus_pool_money = 0
			end
			to_bonus_pool_money = math.ceil(to_bonus_pool_money)
			log.info("guid[%d] to_bonus_pool_money[%d]",player.guid,to_bonus_pool_money)
			if to_bonus_pool_money > 0 then
				to_bonus_money_ = slotma_prize_pool:add_money(to_bonus_pool_money)
--				to_bonus_money_ = to_bonus_pool_money
			end
		end
	end
	--加钱
	if notify.money > 0 then
		player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.money-notify.tax}}, LOG_MONEY_OPT_TYPE_SLOTMA)
	end
	send2client_pb(player, "SC_Slotma_Start", notify)

	--log start-----------------------
	--距离上次游戏的时间间隔
	local time_span_ = start_game_time - self.last_game_time_ - 2
	if time_span_ > 7 then
		time_span_ = 7
	elseif time_span_ <= 0 then
		time_span_ = 1
	end
	--估算游戏结束时间
	local end_game_time = start_game_time + time_span_
	local change_money = notify.money-notify.tax-cost

	local bonus_times_ = 0
	if get_bonus_money == true then
		bonus_times_ = times_sum
	end

	local gamelog = {
	    room_id = self.room_.id,
        table_id = self.table_id_,        
        select_line_num = lineNum,
        cell_times = self.cell_times_,
        cell_score = self.room_.cell_score_,
        result_items = items,
        money_cost = cost,
        tax = notify.tax,
        money_prize = notify.money-notify.tax,
        money_earn  = change_money,
        player_money_end = player:get_money(),
        line_stake = self.room_.cell_score_ * self.cell_times_,
        bonus_times = bonus_times_,
        winline = {},
		get_bonus_money = get_bonus_money_,
		to_bonus_money  = to_bonus_money_
    }

	for _,v in ipairs(notify.pb_winline) do
		if v.times > 0 then
			local line_ret = {
				line_id = v.lineid,
				times = v.times,
				prize = v.times * self.room_.cell_score_ * self.cell_times_
			}
			table.insert(gamelog.winline,line_ret)
		end
	end

 	local game_id = self:get_now_game_id()

    local s_log = json.encode(gamelog)
    self:save_game_log(game_id, self.def_game_name, s_log, start_game_time, end_game_time)


    local s_type = 1
    if change_money > 0 then
    	s_type = 2
    end

	self:player_money_log(player,s_type,old_money,notify.tax,change_money,game_id,get_bonus_money_,to_bonus_money_)
	--log end--------------------------

	if times_sum > slotma_room_config.broadcast_times then
		broadcast_world_marquee(def_first_game_type,def_second_game_type,0,player.nickname,times_sum,notify.money/100)
	end
	self.last_game_time_ = start_game_time
	self:clear()
end

function slotma_table:clear( ... )
	-- body
	self.playerlinelist_ = {}
	self.cell_times_ = 1
	self:next_game()
end

-- 重新上线
function slotma_table:reconnect(player)
	log.info("slotma_table:reconnect--------------------->guid[%d] charid[%d]",player.guid,player.chair_id)
end

-- 心跳
function slotma_table:tick()
end

-- 用户查询奖池
function slotma_table:slotma_bonus(player)
	local notify = {}
	notify.total_bonus = slotma_prize_pool:get_total_bonus()
	send2client_pb(player, "SC_SLOTMABonusPool", notify)
end

return slotma_table