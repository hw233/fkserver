-- 梭哈逻辑
local pb = require "pb_files"
local base_table = require "game.lobby.base_table"
require "game.lobby.base_player"

local showhand_cardmake = require("game/showhand/showhand_cardmake")

local FSM_E = {
	UPDATE          = 0,	--time update
	ADD_SCORE 		= 1,
	PASS 			= 2,
	GIVE_UP 		= 3,
	GIVE_UP_EIXT	= 4,
}
local FSM_S = {
    PER_BEGIN       		= 0,	--预开始
    XI_PAI		    		= 1,    --洗牌 
	GAME_ROUND				= 2,	--游戏回合	

	GAME_BALANCE			= 15,	--结算
	GAME_CLOSE				= 16,	--关闭游戏
	GAME_ERR				= 17,	--发生错误
	GAME_IDLE_HEAD			= 0x1000, --用于客户端播放动画延迟				
}
local Card_Type = {
	Card_Type_TongHu_Shun 	= 9,			--同花顺
	Card_Type_SiTiao		= 8,			--四条
	Card_Type_HuLu			= 7,			--葫芦 33322
	Card_Type_TongHu		= 6,			--同花
	Card_Type_Shun			= 5,			--顺子
	Card_Type_SanTiao		= 4,			--三条
	Card_Type_LiangDui		= 3,			--两对
	Card_Type_YiDui			= 2,			--一对
	Card_Type_Normal		= 1,			--散牌
}
local ACTION_TIME_OUT = 15
local LOG_MONEY_OPT_TYPE_SHOWHAND = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_SHOWHAND")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local redis_command = redis_command

local A_is_7 = 0

local function arrayClone(arraySrc)
	local arrayDes = {}
	for k,v in pairs(arraySrc) do
		arrayDes[k] = v
	end
	return arrayDes
end
local function tableCloneSimple(ori_tab)
    if (type(ori_tab) ~= "table") then
        return ori_tab;
    end
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = mj_util.tableCloneSimple(v);
        elseif (vtyp == "thread") then
            new_tab[i] = v;
        elseif (vtyp == "userdata") then
            new_tab[i] = v;
        else
            new_tab[i] = v;
        end
    end
    return new_tab;
end
-- 得到牌大小
local function get_point(card)
	return math.floor((card-1) / 4)
end
-- 得到牌花色
local function get_color(card)
	return (card-1) % 4
end
local function is_tonghua(c_list)
	local last_color = nil
	for k,v in pairs(c_list) do
		if not last_color then last_color = v.color end
		if last_color ~= v.color then return false end
	end
	return true
end
local function is_sun(c_list)
	local last_point = nil
	for k,v in pairs(c_list) do
		if last_point and (last_point - 1) ~= v.point then 
			return false
		end
		last_point = v.point
	end
	return true
end


local function get_card_type(cards)
	local c_list = {}
	local c_switch_list = {} -- A转换为7
	local c_point_list = {}
	local has_A = false
	local c_count = 0
	for k,v in pairs(cards) do
		local c = {
			point = get_point(v),
			color = get_color(v),
			val = v
		}
		table.insert(c_list,c)
		c_point_list[c.point] = c_point_list[c.point] or 0
		c_point_list[c.point] = c_point_list[c.point] + 1

		if v > 48 then
			v = v - (52 - 24)
			has_A = true
		end
		local c_switch = {
			point = get_point(v),
			color = get_color(v),
			val = v
		}
		table.insert(c_switch_list,c_switch)
		c_count = c_count + 1
	end

	-- 大牌在前
	table.sort(c_list,function (f,s) 
		return f.val > s.val
	end)
	table.sort(c_switch_list,function (f,s) 
		return f.val > s.val
	end)
	
	local c_is_shun = is_sun(c_list) 
	if A_is_7 == 1 then
		c_is_shun = c_is_shun or is_sun(c_switch_list)
	end

	local c_is_tonghua = is_tonghua(c_list)
	if c_count == 1 or c_count == 2 then
		c_is_shun = false
		c_is_tonghua = false
	end
	if c_count == 3 then
		c_is_shun = false
	end

	if c_is_shun and c_is_tonghua then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			value_tmp[#value_tmp + 1] = v.val
		end
		return {type = Card_Type.Card_Type_TongHu_Shun,value = value_tmp}
	end
	for k,v in pairs(c_point_list) do
		if v == 4 then
			return {type = Card_Type.Card_Type_SiTiao,value = {k}}
		end
	end
	local san_tong_point = nil
	local dui_zi_list = {}
	for k,v in pairs(c_point_list) do
		if v == 3 then
			san_tong_point = k
		elseif v == 2 then
			table.insert(dui_zi_list,k)
		end
	end
	if san_tong_point and #dui_zi_list > 0 then
		return {type = Card_Type.Card_Type_HuLu,value = {san_tong_point}}
	end
	if c_is_tonghua then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			table.insert(value_tmp,v.val)
		end
		return {type = Card_Type.Card_Type_TongHu,value = value_tmp}
	end
	if c_is_shun then
		local value_tmp = {}
		for k,v in pairs(c_list) do
			table.insert(value_tmp,v.val)
		end
		return {type = Card_Type.Card_Type_Shun,value = value_tmp}
	end
	if san_tong_point then
		return {type = Card_Type.Card_Type_SanTiao,value = {san_tong_point}}
	end
	if #dui_zi_list > 1 then
		local danpai = 0
		local value_tmp = {}
		for k,v in pairs(c_list) do
			if v.point == dui_zi_list[1] or v.point == dui_zi_list[2] then
				table.insert(value_tmp,v.val)
			else
				danpai = v.val
			end
		end
		table.sort(value_tmp,function (f,s) 
			return f > s
		end)
		if danpai ~= 0 then value_tmp[#value_tmp + 1] = danpai end
		return {type = Card_Type.Card_Type_LiangDui,value = value_tmp}
	end
	if #dui_zi_list == 1 then
		local danpai_list = {}
		local value_tmp = {}
		for k,v in pairs(c_list) do
			if v.point == dui_zi_list[1] then
				table.insert(value_tmp,v.val)
			else
				table.insert(danpai_list,v.val)
			end
		end
		table.sort(danpai_list,function (f,s) 
			return f > s
		end)
		for k,v in pairs(danpai_list) do
			table.insert(value_tmp,v)
		end

		return {type = Card_Type.Card_Type_YiDui,value = value_tmp}
	end
	local value_tmp = {}
	for k,v in pairs(c_list) do
		table.insert(value_tmp,v.val)
	end
	return {type = Card_Type.Card_Type_Normal,value = value_tmp}
end

--返回给客户端的牌型
local function get_card_type_client(cards)
	local card_count_err = {type=0,value={}} --张数不对

	if #cards < 5 then
		return card_count_err
	end

	for i,v in ipairs(cards) do
		--暗牌
		if v == 255 then
			return card_count_err
		end
	end

	return get_card_type(cards)
end

local function compare_cards(cardsL,cardsR,round)
	local cardsL_tmp = {}
	local cardsR_tmp = {}
	if round < 4 then
		for i=2,round+1 do
			table.insert(cardsL_tmp,cardsL[i])
			table.insert(cardsR_tmp,cardsR[i])
		end
	else
		cardsL_tmp = arrayClone(cardsL)
		cardsR_tmp = arrayClone(cardsR)
	end
	local card_TypeL = get_card_type(cardsL_tmp)
	local card_TypeR = get_card_type(cardsR_tmp)
	if card_TypeL.type ~= card_TypeR.type then
		return card_TypeL.type > card_TypeR.type
	end
	local valueL = card_TypeL.value
	local valueR = card_TypeR.value
	if card_TypeL.type == Card_Type.Card_Type_TongHu_Shun then
		if valueL[2] then
			local pointL01 = get_point(valueL[1])
			local pointL02 = get_point(valueL[2])
			local pointR01 = get_point(valueR[1])
			local pointR02 = get_point(valueR[2])
			if pointL01 ~= pointR01 then
				return pointL01 > pointR01
			elseif pointL02 ~= pointR02 then
				return pointL02 > pointR02
			else
				return valueL[1] > valueR[1]
			end
		else
			return valueL[1] > valueR[1]
		end
	end
	
	if card_TypeL.type == Card_Type.Card_Type_SiTiao or 
	   card_TypeL.type == Card_Type.Card_Type_HuLu or 
	   card_TypeL.type == Card_Type.Card_Type_SanTiao 
	then
		return valueL[1] > valueR[1] 
	end
	if card_TypeL.type == Card_Type.Card_Type_TongHu then
		for k,v in pairs(valueL) do
			if get_point(v) ~= get_point(valueR[k]) then
				return get_point(v) > get_point(valueR[k])
			end
		end
		return valueL[1] > valueR[1]
	end
	if card_TypeL.type == Card_Type.Card_Type_Shun then
		for k,v in pairs(valueL) do
			if get_point(v) ~= get_point(valueR[k]) then
				return get_point(v) > get_point(valueR[k])
			end
		end
		return valueL[1] > valueR[1]
	end
	if card_TypeL.type == Card_Type.Card_Type_LiangDui or
	   card_TypeL.type == Card_Type.Card_Type_YiDui or 
	   card_TypeL.type == Card_Type.Card_Type_Normal then
		for k,v in pairs(valueL) do
			if get_point(v) ~= get_point(valueR[k]) then
				return get_point(v) >get_point(valueR[k])
			end
		end
		return valueL[1] > valueR[1]
	end
end

function send2client_pb_sh(player,op_name,msg)
    send2client_pb(player,op_name,msg)
    if msg then
        print("send2client_pb : " .. op_name)
    end
end


local showhand_table = base_table:new()

function showhand_table:broadcast2client_sh(op_name,msg)
    self:broadcast2client(op_name,msg)
    if msg then
        print("broadcast2client : " .. op_name)
    end
end

local total_make_count = 0
local total_make_success_count = 0
local total_card_count = {}

function showhand_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	
	self.cards = {}
	for i = 25, 52 do
		self.cards[#self.cards + 1] = i
	end
	showhand_cardmake.init_cards(self.cards)

	--test做牌
	--[[
	for i=1,9 do
		total_card_count[i] = 0
	end
	for i=1,10 do
		self:test()
	end
	

	print("total make count------------------------>",total_make_count)
	print("total make success count---------------->",total_make_success_count)
	local card_name = {"sanpai","yidui","liangdui","santiao","shunzi","tonghua","hulu","sitiao","tonghuashun"}
	for i=1,9 do
		print(card_name[i],"total count->",total_card_count[i],"average->",total_card_count[i]/10)
	end
	--]]
	
	-- test 
	--[[
	if table_id == 1 then
		for i = 1, 2 do
			self.player_list_[i] = {guid = i,chair_id = i,money = 9999999}
		end
		self:start(2,true)
	end
		]]
	

	--[[
	--if table_id == 1 then
		local player = base_player:new()
		player:init(10000, "android", "android")
		player.session_id = 10000 + table_id
		player.is_android = true
		player.chair_id = 1
		player.guid = 1
		player.room_id = 1
		player.table_id = table_id
		player.pb_base_info = {money = 9999999,}
		self.player_list_[1] = player
		self:ready(player)
	--end  
	]]
	-- test --
end


function showhand_table:test()
	-- body
	local make_count = 0
	local make_success_count = 0
	local card_count = {}
	for i=1,9 do
		card_count[i] = 0
	end

	local player_count = 2

	for i=1,10000 do
		local is_make_card = showhand_cardmake.need_make_card()

		if is_make_card then

			make_count = make_count + 1

			local make_success,cards_by_make = showhand_cardmake.make_cards(2)
			if make_success then
				make_success_count = make_success_count + 1

				local cardsL_tmp = {}
				local cardsR_tmp = {}

				local cards = {cardsL_tmp,cardsR_tmp}

				local card_index = 1
				for i=1,player_count do
					for j=1,5 do
						cards[i][j] = cards_by_make[card_index]
						card_index = card_index+1
					end	
				end

				local card_TypeL = get_card_type(cardsL_tmp)
				local card_TypeR = get_card_type(cardsR_tmp)

				card_count[card_TypeL.type] = card_count[card_TypeL.type] + 1
				card_count[card_TypeR.type] = card_count[card_TypeR.type] + 1
			end
		end
		
	end

	print("make count------------------------>",make_count)
	print("make success count---------------->",make_success_count)
	local card_name = {"sanpai","yidui","liangdui","santiao","shunzi","tonghua","hulu","sitiao","tonghuashun"}
	for i=1,9 do
		print(card_name[i],card_count[i])

		total_card_count[i] = total_card_count[i] + card_count[i]
	end

	total_make_count = total_make_count + make_count
	total_make_success_count = total_make_success_count + make_success_count
	
end



function showhand_table:load_lua_cfg()
	local funtemp = load(self.room_.room_cfg)
	local showhand_config ,card_rate = funtemp()
	self.max_call = showhand_config.max_call --加注最高限制为max_call倍底注
	A_is_7   = showhand_config.A_is_7 --A是否可以当作7组合顺子

	showhand_cardmake.set_card_rate(card_rate)--设置做牌概率
	--test--
--[[
	if self.max_call == 64 then
		local player = base_player:new()
		player:init(10000, "android", "android")
		player.session_id = 10000 + 1
		player.is_android = true
		player.chair_id = 1
		player.guid = 1
		player.room_id = 1
		player.table_id = 1
		player.pb_base_info = {money = 9999999,}
		self.player_list_[1] = player
		self:ready(player)
	end
]]
	--test--
end

function showhand_table:can_enter(player)
	if player.vip == 100 then
		return true
	end
	
	-- body
	for _,v in ipairs(self.player_list_) do		
		if v then
			print("===========judge_play_times")
			if player:judge_ip(v) then
				if not player.ipControlflag then
					print("showhand_table:can_enter ipcontorl change false")
					return false
				else
					-- 执行一次后 重置
					print("showhand_table:can_enter ipcontorl change true")
					return true
				end
			end
		end
	end
	print("showhand_table:can_enter true")
	return true
end


-- 检查是否可取消准备
function showhand_table:check_cancel_ready(player, is_offline)
	return not self:is_play(player, is_offline)
end
function showhand_table:is_play( ... )
	if self.do_logic_update then
		return true
	end
	return false
end

-- 玩家站起
function showhand_table:player_stand_up(player, is_offline)
	--扣除未扣的钱
	self:cost_player_money_real(player)
	return base_table.player_stand_up(self,player,is_offline) 
end

--替换玩家cost_money方法，先缓存，稍后一起扣钱
function showhand_table:cost_player_money(player,money_cost)

	local money = self:get_player_money(player)

	if money_cost <= 0 or money < money_cost then
		log.error("=====cost_player_money==============="..money.."=="..money_cost)		
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
	player:notify_money(LOG_MONEY_OPT_TYPE_SHOWHAND,new_money,-money_cost)

	return true
end

--真实扣除所有玩家待扣除的钱
function showhand_table:cost_money_real()
	-- body
	for k,v in pairs(self.player_list_) do
		if v then
			self:cost_player_money_real(v)
		end
	end
end

function showhand_table:cost_player_money_real(player)
	-- body
	local cost =  self:get_player_money_cost(player)
	if cost > 0 then
		player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cost}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
		self:set_player_money_cost(player,0)
	end
end

--获取玩家待扣除的钱
function showhand_table:get_player_money_cost(player)
	-- body
	if self.moeny_cost_info ~= nil and self.moeny_cost_info[player.guid] ~= nil  then
		return self.moeny_cost_info[player.guid]
	end
	return 0
end

function showhand_table:set_player_money_cost(player,cost)
	-- body
	if self.moeny_cost_info ~= nil and self.moeny_cost_info[player.guid] ~= nil  then
		self.moeny_cost_info[player.guid] = cost
	end
end

--替换玩家get_money方法
function showhand_table:get_player_money(player)
	-- body
	return player:get_money() - self:get_player_money_cost(player)
end

function showhand_table:broadcast_next_turn(left_time)
	local player = self.player_list_[self.cur_turn]

	local all_is_same = true
	local tmp_last = -1
	local cur_round_add_max = false --已经有人加到最大注
	local can_add_money = true --判断自己和对方的金钱是否可以加注
	for k,v in pairs(self.player_list_) do
		if v and not v.is_dead then
			if tmp_last == -1 then tmp_last = v.cur_round_add end
			if tmp_last ~= v.cur_round_add then all_is_same = false end
			if v.cur_round_add >= self.max_call*self.room_.cell_score_ then cur_round_add_max = true end
			
			if v.guid ~= player.guid then
				--玩家自己的钱不够不能加注
				if (self:get_player_money(player)+player.cur_round_add) <= v.cur_round_add then
					can_add_money = false
				end
			end
			
		end
	end
	local type = 0
	if not self.is_allin_state and not cur_round_add_max  and  can_add_money == true then
		type = type + 1 --加注
	end
	if self.cur_game_round > 1 then
		type = type + 2 --allin
	end
	if not all_is_same then
		type = type + 4 --跟注
	else 
		type = type + 8 --让牌
	end
	type = type + 16 --弃牌

	
	local allin_money = 0
	if self.cur_game_round > 1 then
		if not self.is_allin_state then
			-- 没有allin，找到当前轮次最大下注值
			allin_money = self.room_.cell_score_*self.max_call*(5-self.cur_game_round)
			--allin_money不能超过玩家所有的钱
			for k,v in pairs(self.player_list_) do
				if v and not v.is_dead then
					if (self:get_player_money(v) + v.cur_round_add) < allin_money then
						allin_money = self:get_player_money(v)+ v.cur_round_add
					end
				end
			end
			--allin_money = allin_money - player.cur_round_add
		else
			-- 已经allin了，找到最大的下注值
			for k,v in pairs(self.player_list_) do
				if v and not v.is_dead then
					if v.cur_round_add > allin_money then
						allin_money = v.cur_round_add
					end
				end
			end
			--allin_money = allin_money - player.cur_round_add
		end
	else
		--第一个轮次，allin_money为钱最少玩家所有的钱
		allin_money = self.max_call*self.room_.cell_score_
		for k,v in pairs(self.player_list_) do
			if v and not v.is_dead then
				if (self:get_player_money(v) + v.cur_round_add) < allin_money then
					allin_money = self:get_player_money(v) + v.cur_round_add
				end
			end
		end
		--allin_money = allin_money - player.cur_round_add
	end
	assert(allin_money > 0)
	print("allin_money--------->",allin_money)
	--allin_money = allin_money + player.cur_round_add

	self:broadcast2client_sh("SC_ShowHand_NextTurn",{chair_id = self.cur_turn,type = type,max_add = allin_money,act_left_time = left_time})
end
function showhand_table:next_turn()
	local old = self.cur_turn
	repeat
		self.cur_turn = self.cur_turn + 1
		if self.cur_turn > #self.ready_list_ then
			self.cur_turn = 1
		end
		if old == self.cur_turn then
			log.error("turn error")
			return
		end
	until(self.player_list_[self.cur_turn] and (not self.player_list_[self.cur_turn].is_dead))
	self:broadcast_next_turn(ACTION_TIME_OUT)
end

-- 开始游戏
function showhand_table:start(player_count,is_test)
	self.player_count = player_count
	self.timer = {}
	self.cur_state_FSM   = FSM_S.PER_BEGIN
	self.last_action_change_time_stamp = os.time() --上次状态 更新的 时间戳
	self.zhuang = self.zhuang or math.random(1,player_count)
	self.is_allin_state = false
	self.allin_money = 0
	self.cur_game_round = 0
	for k,v in pairs(self.player_list_) do
		if v then
			v.is_dead = false
			v.declare_this_round = false
			v.need_eixt = false
			v.cards = {}
			v.add_total = 0
			v.cur_round_add = 0
			v.last_round_add = 0
			--v.old_money = v:get_money()
			v.old_money = self:get_player_money(v)
		end
	end
	self:update_state(FSM_S.PER_BEGIN)
	self.do_logic_update = true
	self.is_test = is_test
	if not is_test then
		self.table_game_id = self:get_now_game_id()
	end
    self:next_game()
	self.game_log = {
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        zhuang = self.zhuang,
        max_call = self.max_call,
        action_table = {},
        players = {},
    }
	for k,v in pairs(self.player_list_) do
		if v then
			local tmp_p = {account = v.account,nickname = v.nickname,ip_area = v.ip_area,
			guid = v.guid,chair_id = v.chair_id,money_old = self:get_player_money(v)}
			self.game_log.players[v.chair_id] = tmp_p

			local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
			log.info(str)
			redis_command(str)
		end
	end
end

-- 心跳
function showhand_table:tick()
	-- test --
    self.old_player_count = self.old_player_count or 1 
	local tmp_player_count = self:get_player_count()
	if self.old_player_count ~= tmp_player_count then
		if tmp_player_count ~= 0 then 
			-- print("player count", tmp_player_count) 
		end
        self.old_player_count = tmp_player_count
	end
    -- test --
	if self.do_logic_update then
		self:safe_event({type = FSM_E.UPDATE})
		if self.cur_state_FSM == FSM_S.GAME_ROUND then
			local cur_turn_player = self.player_list_[self.cur_turn]
			self.android_try_time = self.android_try_time or os.time()
			if cur_turn_player.is_android and (os.time() - self.android_try_time > 1)then
				self.android_try_time = os.time()
				local act = math.random(1,100)
				if act < 50 then
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.ADD_SCORE,
					target = cur_turn_player.add_total + self.room_.cell_score_ * math.random(1,20) })
				elseif act < 60 then
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.ADD_SCORE,
					target = -1 })
				elseif act < 70 then
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.ADD_SCORE,
					target = -2 })
				elseif act < 73 then
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.GIVE_UP})
				else
					self:safe_event({chair_id = cur_turn_player.chair_id,type = FSM_E.PASS})
				end
			end
		end
        local dead_list = {}
        for k,v in pairs(self.timer) do
            if os.time() > v.dead_line then
                v.execute()
                dead_list[#dead_list + 1] = k
            end
        end
        for k,v in pairs(dead_list) do
            self.timer[v] = nil
        end
    else
    	--[[
        self.Maintain_time = self.Maintain_time or get_second_time()
        if get_second_time() - self.Maintain_time > 5 then
            self.Maintain_time = get_second_time()
            for _,v in ipairs(self.player_list_) do
                if v then
                    --维护时将准备阶段正在匹配的玩家踢出
                    local iRet = base_table:on_notify_ready_player_maintain(v)--检查游戏是否维护
                end
            end
        end
        --]]
	end
end
function showhand_table:safe_event(...)
    -- test --
    self:FSM_event(...)
   --[[
    local ok = xpcall(showhand_table.FSM_event,function() print(debug.traceback()) end,self,...)
    if not ok then
        print("safe_event error") 
        self:update_state(FSM_S.GAME_ERR)
    end
    ]]
end
function showhand_table:send_left_cards()
	repeat 
		self.cur_game_round = self.cur_game_round + 1
		for k,player in pairs(self.player_list_) do
			local msg = {pb_players = {},
				current_round = self.cur_game_round
			}
			for k1,v in pairs(self.player_list_) do
				if v then
					local tplayer = {}
					tplayer.chair_id = v.chair_id
					tplayer.tiles = self:get_cur_round_cards(v,v.chair_id == player.chair_id)
					tplayer.add_total = v.add_total
					tplayer.cur_round_add = v.cur_round_add
					if v.is_android then
						tplayer.nick = "robot"
						tplayer.icon = 1
						tplayer.gold = 999999
					else
						tplayer.nick = v.ip_area
						tplayer.icon = v:get_header_icon()
						--tplayer.gold = v:get_money()
						tplayer.gold = self:get_player_money(v)
					end
					table.insert(msg.pb_players,tplayer)
				end
			end
			send2client_pb_sh(player,"SC_ShowHand_Next_Round",msg)
		end
	until (self.cur_game_round >= 4)
end
function showhand_table:update_state(new_state)
    self.cur_state_FSM = new_state
    self.last_action_change_time_stamp = os.time()
    self:broad_cast_desk_state()
	if new_state == FSM_S.GAME_ROUND then
		self.cur_game_round = self.cur_game_round + 1
		table.insert(self.game_log.action_table,{act = "GAME_ROUND",round = self.cur_game_round})
		local big_player = nil
		for k,v in pairs(self.player_list_) do
			if v and not v.is_dead then
				if not big_player or compare_cards(v.cards,big_player.cards,self.cur_game_round) then
					big_player = v
				end
				v.last_round_add = v.cur_round_add
				v.cur_round_add = 0
				v.declare_this_round = false
			end
		end
		self.cur_turn = big_player.chair_id
		
		for k,player in pairs(self.player_list_) do
			local msg = {pb_players = {},
				current_round = self.cur_game_round
			}
			for k1,v in pairs(self.player_list_) do
				if v then
					local tplayer = {}
					tplayer.chair_id = v.chair_id
					tplayer.tiles = self:get_cur_round_cards(v,v.chair_id == player.chair_id)
					tplayer.add_total = v.add_total
					tplayer.cur_round_add = v.cur_round_add
					if v.is_android then
						tplayer.nick = "robot"
						tplayer.icon = 1
						tplayer.gold = 999999
					else
						tplayer.nick = v.ip_area
						tplayer.icon = v:get_header_icon()
						--tplayer.gold = v:get_money()
						tplayer.gold = self:get_player_money(v)
					end
					table.insert(msg.pb_players,tplayer)
				end
			end
			send2client_pb_sh(player,"SC_ShowHand_Next_Round",msg)
		end
		self:broadcast_next_turn(ACTION_TIME_OUT)
		self:reset_action_time()
	elseif new_state == FSM_S.GAME_BALANCE then
		if self:live_count() > 1 then 
			self:send_left_cards()
		end
		table.insert(self.game_log.action_table,{act = "GAME_BALANCE"})
	end
end

function showhand_table:update_state_delay(new_state,delay_seconds)
	--[[self:update_state(new_state)]]
	
    self.cur_state_FSM = new_state + FSM_S.GAME_IDLE_HEAD

    local act = {}
    act.dead_line = os.time() + delay_seconds
    act.execute = function()
        self:update_state(self.cur_state_FSM - FSM_S.GAME_IDLE_HEAD)
    end
    self.timer[#self.timer + 1] = act
	
end
function showhand_table:is_action_time_out()
    --return false
	local tmp_act_time = ACTION_TIME_OUT
	if self.cur_state_FSM == FSM_S.GAME_ROUND then
		--客户端动画播放时间
		if self.cur_game_round == 1 then tmp_act_time = tmp_act_time + 2 end
		if self.cur_game_round > 1 then tmp_act_time = tmp_act_time + 1 end
	end
	local time_out = (os.time() - self.last_action_change_time_stamp) >= ACTION_TIME_OUT 
    return time_out
end
function showhand_table:reset_action_time()
   self.last_action_change_time_stamp = os.time()
end
function showhand_table:broad_cast_desk_state()
    if self.cur_state_FSM == FSM_S.PER_BEGIN or self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
        return
    end
    self:broadcast2client_sh("SC_ShowHand_Desk_State",{state = self.cur_state_FSM})
end

--[[
function showhand_table:notify_offline(player)
    if self.do_logic_update then
		player.deposit = true
    else
        self.room_:player_exit_room(player)
    end
end
function showhand_table:reconnect(player)
    player.deposit = false
end
--]]

--请求玩家数据
function showhand_table:reconnect(player)
	log.info("player Reconnection : ".. player.chair_id)
	base_table.reconnect(self,player)
    self:send_data_to_enter_player(player,true)
end
function showhand_table:get_cur_round_cards(player,is_self)
	--游戏结束发送所有的牌
	if self.cur_game_round >= 4 then
		local cards = arrayClone(player.cards)
		--弃牌就不显示对方第一张牌
		if player.is_dead and not is_self then
			cards[1] = 255
		end
		return cards
	end
	local cur_round_cards = {}
	for k,v in pairs(player.cards) do
		if is_self and k <= (self.cur_game_round + 1) then
			table.insert(cur_round_cards,v)
		elseif k <= (self.cur_game_round + 1) then
			if k==1 then table.insert(cur_round_cards,255) else table.insert(cur_round_cards,v) end
		end
	end
	return cur_round_cards
end
function showhand_table:send_data_to_enter_player(player,is_reconnect)
    local msg = {}
    msg.state = self.cur_state_FSM
    msg.zhuang = self.zhuang
    msg.self_chair_id = player.chair_id
    msg.act_time_limit = ACTION_TIME_OUT
    msg.is_reconnect = is_reconnect
	msg.base_score = self.room_.cell_score_
	msg.max_call = self.max_call
    msg.pb_players = {}
    for k,v in pairs(self.player_list_) do
        if v then
            local tplayer = {}
            tplayer.chair_id = v.chair_id
			tplayer.guid = v.guid
            tplayer.tiles = self:get_cur_round_cards(v,v.chair_id == player.chair_id)
			tplayer.add_total = v.add_total
    		tplayer.cur_round_add = v.cur_round_add
			if v.is_android then
				tplayer.nick = "robot"
				tplayer.icon = 1
				tplayer.gold = 999999
			else
				tplayer.nick = v.ip_area
				tplayer.icon = v:get_header_icon()
				--tplayer.gold = v:get_money()
				tplayer.gold = self:get_player_money(v)
			end
            table.insert(msg.pb_players,tplayer)
        end
    end
    if is_reconnect then
        msg.pb_rec_data = {}
        msg.pb_rec_data.act_left_time = self.last_action_change_time_stamp + ACTION_TIME_OUT - os.time()   
        if msg.pb_rec_data.act_left_time < 0 then msg.pb_rec_data.act_left_time = 0 end 
         msg.pb_rec_data.current_round = self.cur_game_round
    end
    send2client_pb_sh(player,"SC_ShowHand_Desk_Enter",msg)
	if is_reconnect then
		local left_time  = self.last_action_change_time_stamp + ACTION_TIME_OUT - os.time()
		self:broadcast_next_turn(left_time)
	end

	if self.cur_state_FSM == FSM_S.GAME_BALANCE or self.cur_state_FSM == FSM_S.GAME_CLOSE or 
	self.cur_state_FSM == (FSM_S.GAME_BALANCE+FSM_S.GAME_IDLE_HEAD) or self.cur_state_FSM == (FSM_S.GAME_CLOSE+FSM_S.GAME_IDLE_HEAD) then
		self:send_finish_msg_to_player(player,is_reconnect)
	end
end
function showhand_table:send_finish_msg_to_player(player,is_reconnect)
	local msg = {pb_players = {},
		tax_show = self.room_.tax_show_
	}
	for k,v in pairs(self.player_list_) do
		if v then
			local tplayer = {}
			tplayer.chair_id = v.chair_id
			tplayer.tiles = self:get_cur_round_cards(v,v.chair_id == player.chair_id)
			tplayer.is_win 		= v.chair_id == self.win_player_chair_id
			tplayer.is_give_up = v.is_dead
			tplayer.card_type = get_card_type_client(tplayer.tiles).type
			
			if v.is_android then
				tplayer.nick = "robot"
				tplayer.icon = 1
				tplayer.gold = 999999
			else
				tplayer.nick = v.ip_area
				tplayer.icon = v:get_header_icon()
				--tplayer.gold = v:get_money()
				tplayer.gold = self:get_player_money(v)
			end

			if tplayer.is_win then
				tplayer.win_money = self.win_money
				tplayer.taxes = self.win_taxes
				tplayer.gold = tplayer.gold + self.win_money + v.add_total
				print("winner gold---------------->",tplayer.gold)
			end

			table.insert(msg.pb_players,tplayer)
		end
	end
	send2client_pb_sh(player,"SC_ShowHand_Game_Finish",msg)
end

-- 加注
function showhand_table:add_score(player, msg)
	if msg then
		if msg.round_index == self.cur_game_round then
			self:safe_event({chair_id = player.chair_id,type = FSM_E.ADD_SCORE,target = msg.target})
		else
			log.info("add_score error round->%d cur_game_round->%d",msg.round_index,self.cur_game_round)
		end
    end
end
-- 弃牌
function showhand_table:give_up(player, msg)
	self:safe_event({chair_id = player.chair_id,type = FSM_E.GIVE_UP})
end
-- 让牌
function showhand_table:pass(player,msg)
	if msg then
		if msg.round_index == self.cur_game_round then
			self:safe_event({chair_id = player.chair_id,type = FSM_E.PASS})
		else
			log.info("pass error round->%d cur_game_round->%d",msg.round_index,self.cur_game_round)
		end
    end
end
--give_up_eixt
function showhand_table:give_up_eixt(player)
	self:safe_event({chair_id = player.chair_id,type = FSM_E.GIVE_UP_EIXT})
end

function showhand_table:can_next_round()
	local tmp_add_total = -1
	for k,v in pairs(self.player_list_) do
		if v and not v.is_dead then
			if not v.declare_this_round then return false end
			if tmp_add_total == -1 then tmp_add_total = v.add_total end
			if tmp_add_total ~= v.add_total then return false end
		end
	end
	return true
end
function showhand_table:live_count()
	local live_count = 0
	for k,v in pairs(self.player_list_) do
		if v and not v.is_dead then
			live_count = live_count + 1
		end
	end
	return live_count
end
function showhand_table:judge_after_action()
	local l_c = self:live_count()
	if l_c == 1 then 
		--避免弃牌后不能立即退出
		--self:update_state_delay(FSM_S.GAME_BALANCE,1)
		self:update_state(FSM_S.GAME_BALANCE)
	elseif self:can_next_round() then
		if self.cur_game_round < 4 and not self.is_allin_state then
			self:update_state_delay(FSM_S.GAME_ROUND,1)
		else
			--self:update_state_delay(FSM_S.GAME_BALANCE,1)
			self:update_state(FSM_S.GAME_BALANCE)
		end
	else
		self:next_turn()
	end
end
function showhand_table:do_pass(player)
	local can_pass = true
	for k,v in pairs(self.player_list_) do
		if v then
			if v.add_total > player.add_total then
				can_pass = false
			end
		end
	end
	if can_pass then
		player.declare_this_round = true
		self:broadcast2client_sh("SC_ShowHandPass",{chair_id = player.chair_id})
		self:judge_after_action()
		table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "PASS"})
		self:reset_action_time()
	end
end
function showhand_table:do_give_up(player)
	-- 下注流水
	self:player_bet_flow_log(player, self.moeny_cost_info[player.guid])
	
	player.is_dead = true
	player.declare_this_round = true
	self:judge_after_action()
	self:broadcast2client_sh("SC_ShowHandGiveUp",{chair_id = player.chair_id})
	table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "GIVE_UP"})
	self:reset_action_time()
end
function showhand_table:do_add_score(player,target)
	if target == -1 and self.cur_game_round > 1 then --allin
		local allin_money = 0
		if not self.is_allin_state then
			allin_money = self.room_.cell_score_*self.max_call*(5-self.cur_game_round)
			for k,v in pairs(self.player_list_) do
				if v and not v.is_dead then
					if self:get_player_money(v) < allin_money then
						allin_money = self:get_player_money(v)
					end
				end
			end
		else
			for k,v in pairs(self.player_list_) do
				if v and not v.is_dead then
					if v.cur_round_add > (allin_money + player.cur_round_add) then
						allin_money = v.cur_round_add - player.cur_round_add
					end
				end
			end
		end
		assert(allin_money > 0)
		if (not self.is_test) and (not player.is_android) then 
			--player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = allin_money}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
			self:cost_player_money(player,allin_money)
		end
		player.add_total = player.add_total + allin_money
		player.declare_this_round = true
		player.cur_round_add = player.cur_round_add + allin_money
		self.is_allin_state = true
		if allin_money > 0 then self:broadcast2client_sh("SC_ShowHandAddScore",{target = target,chair_id = player.chair_id}) end 
		self:judge_after_action()
		table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "ALL_IN",money = allin_money})
		self:reset_action_time()
	elseif target == -2 then --跟注
		local gengzhu_val = 0
		for k,v in pairs(self.player_list_) do
			if v and not v.is_dead then
				if v.add_total - player.add_total > gengzhu_val then
					gengzhu_val = v.add_total - player.add_total
				end
			end
		end
		if gengzhu_val > 0 then
			if (not self.is_test) and (not player.is_android) then 
				--player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = gengzhu_val}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
				self:cost_player_money(player,gengzhu_val)
			end
			player.add_total = player.add_total + gengzhu_val
			player.declare_this_round = true
			player.cur_round_add = player.cur_round_add + gengzhu_val
			if self:get_player_money(player) == 0 then
				self.is_allin_state = true
			end
			if self.is_allin_state then
				self:broadcast2client_sh("SC_ShowHandAddScore",{target = -1,chair_id = player.chair_id})
			else
				self:broadcast2client_sh("SC_ShowHandAddScore",{target = target,chair_id = player.chair_id})
			end
			self:judge_after_action()
			table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "FOLLOW",money = gengzhu_val})
			self:reset_action_time()
		end
	elseif target > 0 and (target - player.cur_round_add > 0 ) then
		for k,v in pairs(self.player_list_) do
			if v and not v.is_dead then
				if (self:get_player_money(v) + v.cur_round_add) < target then
					target = self:get_player_money(v) + v.cur_round_add
				end
			end
		end
		local is_bigest = true
		for k,v in pairs(self.player_list_) do
			if v and not v.is_dead then
				if target < v.cur_round_add then
					is_bigest = false
				end
			end
		end
		if is_bigest then 
			local cur_add = target - player.cur_round_add
			if cur_add > 0 and (player.cur_round_add + cur_add) > self.max_call*self.room_.cell_score_ then
				cur_add = self.max_call*self.room_.cell_score_ - player.cur_round_add
			end
			if cur_add > 0 then
				if (not self.is_test) and (not player.is_android) then 
					--player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cur_add}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
					self:cost_player_money(player,cur_add)
				end
				player.add_total = player.add_total + cur_add
				player.declare_this_round = true
				player.cur_round_add = player.cur_round_add + cur_add
				if self:get_player_money(player) == 0 then
					self.is_allin_state = true
					self.allin_money = cur_add
				end
				if self.is_allin_state then
					self:broadcast2client_sh("SC_ShowHandAddScore",{target = -1,chair_id = player.chair_id})
				else
					self:broadcast2client_sh("SC_ShowHandAddScore",{target = player.cur_round_add,chair_id = player.chair_id})
				end
				self:judge_after_action()
				table.insert(self.game_log.action_table,{chair_id = player.chair_id,act = "ADD",money = cur_add})
				self:reset_action_time()
			end
		else
			if not self.is_test then log.error("client addscore erroe guid " .. player.guid) end
		end
	end
end
function showhand_table:FSM_event(event_table)
    if self.cur_state_FSM == FSM_S.PER_BEGIN then
        if event_table.type == FSM_E.UPDATE then
            self:update_state_delay(FSM_S.XI_PAI,1)
        else 
            log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type)
        end
    elseif self.cur_state_FSM == FSM_S.XI_PAI then
        if event_table.type == FSM_E.UPDATE then
			math.randomseed(tostring(os.time()):reverse():sub(1, 6))
			-- 发底牌
			local k = #self.cards
			
			--是否需要做牌
			local card_index = 1
			local is_make_card = showhand_cardmake.need_make_card()
			local make_success = false
			local cards_by_make = nil
			if is_make_card then
				make_success,cards_by_make = showhand_cardmake.make_cards(#self.player_list_)
			end
			
			for i,v in ipairs(self.player_list_) do
				if v then
					--做牌
					if is_make_card and make_success then
						for j=1,5 do
							v.cards[j] = cards_by_make[card_index]
							card_index = card_index+1
						end	
					else
						local cards = v.cards
						for j=1,5 do
							local r = math.random(k)
							cards[j] = self.cards[r]
							if r ~= k then
								self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
							end
							k = k-1
						end	
					end
					
					self.game_log.players[v.chair_id].cards = arrayClone(v.cards)
					self.game_log.players[v.chair_id].cards_type = get_card_type(v.cards).type
				end
			end
			--test--
			--1-4,>>>
			--  方块 草花 红桃 黑桃
			-- (x-2)*4 + color
			-- 8 	25 26 27 28
			-- 9	29 30 31 32
			-- 10   33 34 35 36	
			-- J 	37 38 39 40
			-- Q 	41 42 43 44
			-- K 	45 46 47 48
			-- A 	49 50 51 52
			--self.player_list_[1].cards = {25,29,33,37,49}
			--self.player_list_[2].cards = {46,37,33,27,26}
			--test--
            for k,v in pairs(self.player_list_) do
                if v then 
					v.add_total = v.add_total + self.room_.cell_score_
					if (not self.is_test) and (not v.is_android) then 
						--v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = self.room_.cell_score_}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
						self:cost_player_money(v,self.room_.cell_score_)
					end
				end 
            end
			for k,v in pairs(self.player_list_) do
                if v then 
					self:send_data_to_enter_player(v) 
				end 
            end
			self:update_state_delay(FSM_S.GAME_ROUND,2)
        else
            log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
	elseif self.cur_state_FSM == FSM_S.GAME_ROUND then
		local cur_turn_player = self.player_list_[self.cur_turn]
        if event_table.type == FSM_E.UPDATE then
			if self:is_action_time_out() then
				local can_pass = true
				for k,v in pairs(self.player_list_) do
					if v then
						if v.add_total > cur_turn_player.add_total then
							can_pass = false
						end
					end
				end
				if can_pass then 
					self:do_pass(cur_turn_player)
				else
					self:do_give_up(cur_turn_player)
				end
			end
		elseif event_table.type == FSM_E.ADD_SCORE then
			if event_table.chair_id == cur_turn_player.chair_id then
				self:do_add_score(cur_turn_player,event_table.target)
			end
		elseif event_table.type == FSM_E.PASS then
			if event_table.chair_id == cur_turn_player.chair_id then
				self:do_pass(cur_turn_player)
			end
		elseif event_table.type == FSM_E.GIVE_UP then
		 	if event_table.chair_id == cur_turn_player.chair_id then
				self:do_give_up(cur_turn_player)
			end
		elseif event_table.type == FSM_E.GIVE_UP_EIXT then
			local cur_player = self.player_list_[event_table.chair_id]
			cur_player.need_eixt = true
		 	self:do_give_up(cur_player)
        else
            log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
	elseif self.cur_state_FSM == FSM_S.GAME_BALANCE then
        if event_table.type == FSM_E.UPDATE then
			
        	--扣除所有未扣除的钱
        	self:cost_money_real()

			local win_player = nil
			local all_add_total = 0
			for k,v in pairs(self.player_list_) do
				if v and not v.is_dead then
					-- 下注流水
					self:player_bet_flow_log(v, self.moeny_cost_info[v.guid])

					if win_player then
						if compare_cards(v.cards,win_player.cards,4) then
							win_player = v
						end
					else
						win_player = v
					end
				end
				if v then all_add_total = all_add_total + v.add_total end
			end
			self.zhuang = win_player.chair_id
			self.win_taxes = math.ceil((all_add_total - win_player.add_total) * self.room_:get_room_tax())
			if self.win_taxes == 1 then self.win_taxes = 0 end -- 一分就不收税
			self.win_money = all_add_total - self.win_taxes - win_player.add_total
            self.win_player_chair_id = win_player.chair_id

			for k,v in pairs(self.player_list_) do
				if v then
					self:send_finish_msg_to_player(v,false)
				end
			end

			if (not self.is_test) and (not win_player.is_android) then 
				win_player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = self.win_money + win_player.add_total}}, LOG_MONEY_OPT_TYPE_SHOWHAND) 
			end
			print("winner gold after add---------------->",win_player:get_money())

			self.game_log.taxes = self.win_taxes
			self.game_log.win_money = self.win_money
			self.game_log.win_chair_id = win_player.chair_id
            self.game_log.end_game_time = os.time()
            

	        for k,v in pairs(self.player_list_) do

	        	--reduce player count
				local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
				log.info(str)
				redis_command(str)

				--moneylog-------
				if v then
					if self.win_player_chair_id == v.chair_id then
						self:player_money_log(v,2,v.old_money,self.win_taxes,self.win_money,self.game_log.table_game_id)
					else
						self:player_money_log(v,1,v.old_money,0,-v.add_total,self.game_log.table_game_id)
					end

					self.game_log.players[v.chair_id].increment_money = self:get_player_money(v) - v.old_money
				end
			end

			local s_log = json.encode(self.game_log)
	        log.info(s_log)
	        self:save_game_log(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)


            if self.is_test then
				self:update_state_delay(FSM_S.GAME_CLOSE,10)
			else
				self:update_state(FSM_S.GAME_CLOSE)
			end
        else
            log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.GAME_CLOSE then
        if event_table.type == FSM_E.UPDATE then
			self.do_logic_update = false
            self:clear_ready()

            local room_limit = self.room_:get_room_limit()
            for i,v in ipairs(self.player_list_) do
                if v then
                    if v.need_eixt or v.in_game == false then
                        v:forced_exit()
                    else
                        if not self.is_test then v:check_forced_exit(room_limit) end
                        if v.is_android then
                            self:ready(v)
                        end
                    end
                end
            end

            --[[
            for i,v in pairs (self.player_list_) do
                if game_switch == 1 then--游戏将进入维护阶段
                    if  v and v.is_player == true then 
                        send2client_pb(v, "SC_GameMaintain", {result = GAME_SERVER_RESULT_MAINTAIN,})
                        v:forced_exit()
                    end
                end
            end
            --]]
            
			-- test --
			if self.is_test then self:start(2,true) end
			-- test --
        else
            log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM == FSM_S.GAME_ERR then
        if event_table.type == FSM_E.UPDATE then  
            self:update_state(FSM_S.GAME_CLOSE)
        else
            log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
        end
    elseif self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
    end
    return true
end

return showhand_table