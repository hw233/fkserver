require "functions"
local base_table = require "game.lobby.base_table"
require "game.lobby.base_player"
require "game.sanshui.config"
local logic = require("game/sanshui/logic/logic")
local define = require("game/sanshui/logic/define")
local log = require "log"

local TableStatus = define.TABLE_STATUS
local PlayerStatus = define.PLAYER_STATUS

local pb = require "pb_files"
local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local LOG_MONEY_OPT_TYPE_THIRTEEN_WATER = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_THIRTEEN_WATER")

local select_cards_elasped_time = 15
local wait_to_start_elasped_time = 5
local wait_bipai_elasped_time = 40

local sanshui_table = class("sanshui_table",base_table)

--  2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,14,   --方块 2 - A
--  17,18,19,20,21,22,23,24,25,26,27,28,29,   --梅花 2 - A
--  32,33,34,35,36,37,38,39,40,41,42,43,44,   --红桃 2 - A
--  47,48,49,50,51,52,53,54,55,56,57,58,59,   --黑桃 2 - A
function sanshui_table:ctor()

end

function cards_array_str(cards)
    local cards_str = "["
    for _,v in pairs(cards) do cards_str = cards_str..string.format("%d,",v) end
    cards_str = cards_str.."]"
    return cards_str
end

function sanshui_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)

    self.status = TableStatus.IDLE
    self.cards = {}
    self.scores = nil
	for i = 0,3 do
        for j = 2,14 do self.cards[#self.cards + 1] = i * 15 + j end
	end

    math.randomseed(tostring(os.time()):reverse():sub(1, 6))

--    for i = 1,10 do
--        print(math.random(1,1))
--    end

    --洗牌
    for i = #self.cards,1,-1 do
        local j = math.random(i)
        if i ~= j then self.cards[j],self.cards[i] = self.cards[i],self.cards[j] end
    end
	
    self.s_cell = self.room_:get_room_cell_money()
    self.s_tax = self.room_:get_room_tax()
    self.game_log = {players = {},
            game_server_id = def_game_id,
            first_game_type = def_first_game_type,
            second_game_type = def_second_game_type,
            game_name = def_game_name}
    self.balances = {}
    self.balance_animate_time = wait_bipai_elasped_time
    self.last_start_time = os.clock()
end

function sanshui_table:is_play()
    return self.status ~= TableStatus.IDLE
end

function sanshui_table:foreach_and_operation_result(func)
	for i, p in pairs(self.player_list_) do
		if p then
			if func(p) == false then return false end
		end
	end

    return true
end

function sanshui_table:foreach_not_ready(func)
    return self:foreach_condition_oper(function(p) return not self.ready_list_[p.chair_id] end,func)
end

function sanshui_table:foreach_ready(func)
    return self:foreach_condition_oper(function(p) return self.ready_list_[p.chair_id] end,func)
end

function sanshui_table:foreach_not_standby(func)
    return self:foreach_condition_oper(function(p) return not p.standby end,func)
end

function sanshui_table:foreach_condition_oper(func_cond,func_op)
    for i,p in pairs(self.player_list_) do
        if p and func_cond(p) then
            func_op(p)
        end
    end
end

function sanshui_table:get_online_player_count()
    local online_player_count = 0
    for _,p in pairs(self.player_list_) do
        if p and not p.trusteeship then
            online_player_count = online_player_count + 1
        end
    end

    return online_player_count
end

function sanshui_table:load_lua_cfg(...)
--    log.warning("sanshui_table:load_lua_cfg,%s",self.room_.room_cfg)
--    local cfg = json.decode(self.room_.room_cfg)

--    if not cfg then return end

--    if cfg.broadcast_cfg then broadcast_cfg = cfg.broadcast_cfg end

--    if cfg.peipai_cfg then peipai_cfg = cfg.peipai_cfg end
end

function sanshui_table:check_start(part)
	local ready_mode = self.room_:get_ready_mode()
    print("sanshui_table:check_start",ready_mode)

    if self:is_play() then return end

    print("sanshui_table:check_start 111111")
    local n = 0
    self:foreach_condition_oper(function(p) return self.ready_list_[p.chair_id] end,function(p) n = n + 1 end)
	if n >= 2 then
        if not self:start(n) then return end
    end
end

function sanshui_table:start(player_count)
    print("sanshui_table:start")

	if base_table.start(self,player_count) == nil then return false end

    self.balances = {}
    self.status = TableStatus.READY_START
    self.balance_animate_time = wait_bipai_elasped_time
    self.last_start_time = os.clock()
    self:broadcast2client("SC_ReadyStart",{wait_time = wait_to_start_elasped_time,is_stop = 0})

	return true
end

function sanshui_table:can_enter(player)
    if player.vip == 100 then
		return true
	end
	
	-- body
	for _,v in pairs(self.player_list_) do
        if v and v.guid ~= player.guid then
		    print("===========judge_play_times")
		    if player:judge_ip(v) then
			    if not player.ipControlflag then
				    print("sanshui_table:can_enter ipcontorl change false")
				    return false
			    else
				    -- 执行一次后 重置
				    print("sanshui_table:can_enter ipcontorl change true")
				    return true
			    end
		    end
        end
	end

    local time_to_start = wait_to_start_elasped_time - (os.clock() - self.last_start_time)
    if  time_to_start >= 0 and time_to_start <= 1 then
        return false
    end
    
	print("sanshui_table:can_enter true")
	return true
end

-- 玩家坐下
function sanshui_table:player_sit_down(player, chair_id_)
    print("sanshui_table:player_sit_down",player.guid,chair_id_)
	self.super.player_sit_down(self,player,chair_id_)
    player.cards = {}
    player.selected_cards = {}
    player.status = PlayerStatus.IDLE
    player.standby = true
    player.trusteeship = false
    player.is_offline = false
    player.time_elaspe = os.clock()
    
    local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)
end

function sanshui_table:player_sit_down_finished(player)
    print("sanshui_table:player_sit_down_finished",player.guid)
    self:broadcast2client("SC_PlayerInfo",{
        guid = player.guid,
        chair_id = player.chair_id, 
        status  = player.status,
        pb_cards = {}
    })
	
    self:foreach_except(player.chair_id,function(v) 
        send2client_pb(player,"SC_PlayerInfo",{
                guid = v.guid,
                chair_id = v.chair_id, 
                status  = v.status,
                pb_cards = nil
            })
    end)

    send2client_pb(player,"SC_TableInfo",{status = self.status})
end

function sanshui_table:player_stand_up(player, is_offline)
	if player.standby == true or self.status <= TableStatus.READY_START then
        log.warning("sanshui_table:player_stand_up normal")

		if self:get_player_count() <= 2 then
			self.status = TableStatus.IDLE
            self:broadcast2client("SC_ReadyStart",{wait_time = wait_to_start_elasped_time,is_stop = 1})
		end
		
        --reduce player count
	    local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	    log.info(str)
	    redis_command(str)

        return self.super.player_stand_up(self,player,is_offline)
    end

    print("sanshui_table:player_stand_up trusteeship")
    player.trusteeship = true
    player.is_offline = is_offline
	return false
end

function sanshui_table:ready(player)
    print("sanshui_table:ready")
    player.status = PlayerStatus.READY
    player.selected_cards = {}
    player.cards = {}
    player.trusteeship = false
    player.standby = true
    base_table.ready(self,player)

    if self.status == TableStatus.READY_START then 
        send2client_pb(player,"SC_ReadyStart",{wait_time = wait_to_start_elasped_time - os.clock() + self.last_start_time,is_stop = 0})
    end
end

function sanshui_table:player_offline(player)
	print("sanshui_table:player_offline")
    if self.status ~= TableStatus.IDLE then player.trusteeship = true end	
    base_table.player_offline(self,player)
end

function sanshui_table:selected_cards(player,msg)
    local function array_counts(array,kv_func,max_key)
        local function inc_field(tb,field,v) tb[field] = tb[field] + 1 end

        local counts = {}
        for i = 1,max_key do counts[i] = 0 end
    
        for k,v in pairs(array) do  
            local k1,v1 = kv_func(k,v)
            if k1 and k1 > 0 and v1 then inc_field(counts,k1,v1) end
        end

        return counts
    end

    local function check_cards(player,selected_cards) 
        local card_counts = array_counts(player.cards,function(k,v) return v,1 end,60)
        for _,v in pairs(selected_cards) do
            for _,c in pairs(v.cards) do if card_counts[c] == 0 then return false end end
        end
        
        return true
    end

--    dump(msg)

    print("sanshui_table:selected_cards",player.guid)
	if player.status ~= PlayerStatus.SELECT_CARDS or player.standby == true then
		return
	end

    if not check_cards(player,msg.pb_cards) then return end
	
    player.status = PlayerStatus.SELECT_CARDS_END
    player.selected_cards = {}
    for _,v in ipairs(msg.pb_cards) do push_back(player.selected_cards,v.cards) end
    
    self:broadcast2client("SC_PlayerInfo",{
        guid = player.guid,
        chair_id = player.chair_id, 
        status  = player.status,
        pb_cards = msg.pb_cards
        })

    if not self:foreach_and_operation_result(function(p) return (p.status == PlayerStatus.SELECT_CARDS_END and p.standby == false) or p.standby == true  end) then
        return 
    end

    print("sanshui_table:selected_cards all end")
    if not self.scores then self:balance() end

    --结算计算
    local total_real_win_money = 0
    local total_real_lose_money = 0
    local player_balances = self.balances
    table.walk(self.scores,function(val,k)
        local player = self:get_player(val.chair_id)

        -- 下注流水
        self:player_bet_flow_log(player,self.s_cell)

        local old_money = player:get_money()
        local diff_money = val.score * self.s_cell
        local real_diff_money = math.abs(diff_money) > old_money and (diff_money >0 and old_money or -old_money) or diff_money
        if not player_balances[val.chair_id] then player_balances[val.chair_id] = {} end
        player_balances[val.chair_id].cur_money = old_money
        player_balances[val.chair_id].score = val.score
        player_balances[val.chair_id].org_diff_money = diff_money
        player_balances[val.chair_id].real_diff_money = real_diff_money

        if real_diff_money > 0 then total_real_win_money = total_real_win_money + real_diff_money
        else total_real_lose_money = total_real_lose_money + math.abs(real_diff_money) end
    end)

    local remain_lose = 0
    local remain_win = 0
    for i = 1,1 do
        if total_real_lose_money == total_real_win_money then break end

        if total_real_lose_money > total_real_win_money then
            table.walk(player_balances,function(balance,k)
                if not balance or not k then return end
                if balance.real_diff_money < 0 then 
                    balance.real_diff_money = balance.real_diff_money * total_real_win_money / total_real_lose_money
                    if math.abs(balance.real_diff_money) % 1 > 0 then
                        remain_win = remain_win + math.abs(balance.real_diff_money) % 1
                        balance.real_diff_money = math.ceil(balance.real_diff_money)
                    end
                end
            end)
        else
            table.walk(player_balances,function(balance,k)
                if not balance or not k then return end
                if balance.real_diff_money > 0 then
                    balance.real_diff_money = balance.real_diff_money * total_real_lose_money / total_real_win_money
                    if math.abs(balance.real_diff_money) % 1 > 0 then
                        remain_lose = remain_lose + math.abs(balance.real_diff_money) % 1
                        balance.real_diff_money = math.floor(balance.real_diff_money)
                    end
                end
            end)
        end
    end

    if remain_lose ~= 0 then
        local min_loser = nil
        for _,val in pairs(player_balances) do  if val and (not min_loser or val.real_diff_money < min_loser.real_diff_money) then min_loser = val end end
        min_loser.real_diff_money = min_loser.real_diff_money + math.ceil(remain_lose)
    end

    if remain_win ~= 0 then
        local max_winner = nil
        for _,val in pairs(player_balances) do if val and (not max_winner or val.real_diff_money > max_winner.real_diff_money) then max_winner = val end end
        max_winner.real_diff_money = max_winner.real_diff_money - math.ceil(remain_win)
    end

    local notify = {pb_balances = {},table_status = TableStatus.IDLE}

    --change money
    table.walk(player_balances,function(val,chair_id)
        if not chair_id or not val then return end

        local player = self:get_player(chair_id)
        if not player then return end

        
        
        local old_money = player:get_money()
        local diff_money = val.real_diff_money
        local l_tax = 0
        if diff_money > 0 then
            l_tax = diff_money * self.s_tax
            l_tax = l_tax < 1 and 0 or math.floor(l_tax + 0.5)
            diff_money = diff_money - l_tax
			notify.pb_balances [#notify.pb_balances + 1] = {tax = l_tax,chair_id = player.chair_id,increment_money = diff_money,score = val.score}
        elseif diff_money < 0 then
			notify.pb_balances [#notify.pb_balances + 1] = {tax = 0,chair_id = player.chair_id,increment_money = diff_money,score = val.score}
        elseif diff_money == 0 then
            notify.pb_balances [#notify.pb_balances + 1] = {tax = 0,chair_id = player.chair_id,increment_money = diff_money,score = val.score}
        end
    end)

    dump(notify)
    self:broadcast2client("SC_Balance",notify)

    self:foreach_not_standby(function(player)
        player.status = PlayerStatus.BI_PAI
        player.time_elaspe = os.clock()
        local cards = {}
        for _,v in ipairs(player.selected_cards) do push_back(cards,{cards = v}) end

        self:broadcast2client("SC_PlayerInfo",{
            guid = player.guid,
            chair_id = player.chair_id, 
            status  = player.status,
            pb_cards = cards
        })
     end)

	self.status = TableStatus.WAIT_BI_PAI
end

function sanshui_table:balance()
    local player_cards = {}
    self:foreach_not_standby(function(v)  
        table.push_back(player_cards,{chair_id = v.chair_id,cards = v.selected_cards}) 
    end)
--	player_cards[1] = {chair_id = 1,cards = {{39,25,44},{32,19,23,27,57},{3,5,8,10,13}}}
--	player_cards[2] = {chair_id = 2,cards = {{7,26,42},{17,33,34,28,43},{48,50,52,54,59}}}
--	player_cards[3] = {chair_id = 3,cards = {{6,51,12},{14,47,18,49,35},{37,38,24,55,11}}}
--	player_cards[4] = {chair_id = 4,cards = {{56,58,29},{2,4,20,21,36},{22,53,9,40,41}}}

	local results = logic.new():balance_scores(player_cards)

	table.walk(results,function(v,k) dump(v) end)

    local scores = table.agg(results,{},function(last_scores,v,k)
        local score = table.agg(v,0,function(last_p_s,v1,k_c)
			local s = table.agg(v1.normal,0,function(last_dao_s,p_s,k_p) return last_dao_s + p_s.win + p_s.extra  end)
			if v1.shoot ~= 0 then  s = s * math.abs(v1.shoot) end
			if v1.qld ~= 0 then s = s * math.abs(v1.qld) end
			s = s + table.agg(v1.special,0,function(last_dao_s,p_s,k_p) return last_dao_s + p_s.win + p_s.extra  end)
			return last_p_s + s
		end)
		
        last_scores[k] = {score = score,chair_id = k}
		return last_scores
    end)

	dump(scores)

	local BIPAI_SHOWTIME = 0.8
	local BIPAI_END_WAIT_TIME = 3
	local BIPAI_SHOW_SCORE_TIME = 0.3

--	local function calcEndTime(data)
----		—- 开牌动画时间
--		local time = 1.5

--		if normal_player_count == 0 then
----			— 全部特殊牌型
--			time = time + special_player_count * (2.2 + BIPAI_SHOWTIME * 2)
----			— 收分
--			time = time + BIPAI_END_WAIT_TIME + BIPAI_SHOWTIME * 3 + 0.1
--		elseif normal_player_count == 1 then
----			—普通牌型只有一副
--			time = time + BIPAI_SHOWTIME * 2
----			—全部特殊牌型
--			time = time + special_player_count * (2.2 + BIPAI_SHOWTIME * 2)
----			— 收分
--			time = time + BIPAI_END_WAIT_TIME + BIPAI_SHOWTIME * 3 + 0.1
--		elseif normal_player_count > 1 then
--			time = time + normal_player_count * BIPAI_SHOWTIME * 3

----			—自己不是特殊牌型就要显示
--			time = time + BIPAI_SHOW_SCORE_TIME * 5
--			local count = 2
--			for k, v in pairs(data.shoot) do
--				count = count + table.nums(v) * 1.5
--				if table.nums(v) == 3 then
--					count = count + 2
--				end
--			end
--			time = time + count

----			— 全部特殊牌型
--			time = time + special_player_count * (2.2 + BIPAI_SHOWTIME * 2)
----			— 收分
--			time = time + BIPAI_END_WAIT_TIME + BIPAI_SHOWTIME * 3 + 0.1
--		end

--		return math.ceil(time) + 2
--	end
	
	local normal_count = 0
	local special_count = 0
	local shoot_count = 0
	local qld_count = 0
	table.walk(results,function(v,k)
		normal_count = normal_count + table.agg(v,0,function(last_normal_count,v1,k1) return last_normal_count + (#v1.normal > 0 and 1 or 0)  end) / 2
		special_count = special_count + table.agg(v,0,function(last_special_count,v1,k1) return last_special_count + (#v1.special > 0 and 1 or 0) end) / 2
		shoot_count = shoot_count + table.agg(v,0,function(last_shoot_count,v1,k1)  return last_shoot_count + (v1.shoot ~= 0 and 1 or 0) end) / 2
		qld_count = qld_count + table.agg(v,0,function(last_qld_count,v1,k1)  return last_qld_count + (v1.qld ~= 0 and 1 or 0) end) / 2
	end)

	local balance_wait_time =  2 + 1.5 + BIPAI_END_WAIT_TIME + BIPAI_SHOWTIME * 3 + 
			(qld_count > 0 and 2 or 0) + ((normal_count / 2 + 1) * BIPAI_SHOWTIME * 3) + ((special_count / 2  + 1) * 3.2) + (shoot_count * 1.5)

	dump(scores)
	dump(balance_wait_time)
	self.scores = scores
	self.balance_animate_time = balance_wait_time
   	return scores,balance_wait_time
end

function sanshui_table:bi_pai_accomplish(player,msg)
    print("sanshui_table:bi_pai_accomplish",player.guid)

	if player.status ~= PlayerStatus.BI_PAI and player.standby == false then return end

    if not player.standby then  player.status = PlayerStatus.BI_PAI_END end

    self:foreach_condition_oper(function(p) 
        return p.trusteeship and not p.standby and p.status < PlayerStatus.BI_PAI_END and p.status > PlayerStatus.SELECT_CARDS_END 
    end,function(p)
            self:bi_pai_accomplish(p,{})
    end)

    if not self:foreach_and_operation_result(function(p) return (p.status == PlayerStatus.BI_PAI_END and not p.standby) or p.standby  end) then
        return 
    end

    local player_money_infos = {}
    local game_log_players = self.game_log.players
    local player_balances = self.balances
    table.walk(player_balances,function(val,chair_id)
        if not chair_id or not val then return end

        local player = self:get_player(chair_id)
        if not player then return end

        local old_money = player:get_money()

        game_log_players[player.chair_id].score = val.score
        game_log_players[player.chair_id].cards = player.cards
        game_log_players[player.chair_id].guid = player.guid
        game_log_players[player.chair_id].chair_id = player.chair_id
        game_log_players[player.chair_id].selected_cards = player.selected_cards
        local diff_money = val.real_diff_money
        local l_tax = 0
        if diff_money > 0 then
            l_tax = diff_money * self.s_tax
            l_tax = l_tax < 1 and 0 or math.floor(l_tax + 0.5)

            diff_money = diff_money - l_tax
            player:add_money(
                {{ money_type = ITEM_PRICE_TYPE_GOLD, 
                money = diff_money }}, 
                LOG_MONEY_OPT_TYPE_THIRTEEN_WATER
            )


            push_back(player_money_infos,{chair_id = player.chair_id,guid = player.guid,money = player:get_money()})

            game_log_players[player.chair_id].tax = l_tax
            game_log_players[player.chair_id].diff_money = diff_money
            --广播获取limit以上分数玩家
            if diff_money >= broadcast_cfg.money then
                local money_str = string.format("%.02f",diff_money / 100)
                broadcast_world_marquee(def_first_game_type,def_second_game_type,0,player.nickname,money_str)
            end
        elseif diff_money < 0 then
            player:cost_money(
                {{money_type = ITEM_PRICE_TYPE_GOLD, money = -diff_money}}, 
                LOG_MONEY_OPT_TYPE_THIRTEEN_WATER
            )
				
            push_back(player_money_infos,{chair_id = player.chair_id,guid = player.guid,money = player:get_money()})
            game_log_players[player.chair_id].tax = 0
            game_log_players[player.chair_id].diff_money = diff_money
        elseif diff_money == 0 then
            game_log_players[player.chair_id].tax = 0
            game_log_players[player.chair_id].diff_money = 0
            push_back(player_money_infos,{chair_id = player.chair_id,guid = player.guid,money = player:get_money()})
        end

        log.warning("player change money [%d] [%d] [%d] [%d]",player.guid,chair_id,diff_money,l_tax)

        if diff_money ~= 0 then
            local s_type =  diff_money > 0 and 2 or 1
            self:player_money_log(player,s_type,old_money,l_tax,diff_money,self:get_now_game_id())
        end
    end)

    self:broadcast2client("SC_NotifyGameOver",{pb_moneies = player_money_infos})

	self:clear_ready()

    self.balances = {}
    self.status = TableStatus.IDLE
	self:broadcast2client("SC_TableInfo",{status = self.status})
    self:foreach(function(v)
        v.status = PlayerStatus.IDLE
        v.standby = true
		v.selected_cards = {}
		v.cards = {}
		v.is_offline = false

        --破产统计
        self:save_player_collapse_log(v)
        v:check_forced_exit(self.room_:get_room_limit())
    end)

    ----ip_area--------------------A----------------A-------
    local end_game_time = get_second_time()
    local s_log = json.encode(self.game_log)
    log.warning(s_log)
    local game_id = self:get_now_game_id()
    self:save_game_log(game_id,def_game_name,s_log,self.game_start_time,get_second_time())
    self:next_game()

    self.last_start_time = os.clock()
    
    self:check_single_game_is_maintain()
end


function sanshui_table:cs_get_player_infos(player,msg)
    local infos = {}
    self:foreach(function(p) 
            if p.status >= PlayerStatus.SELECT_CARDS_END then
                local cards = {}
                for _,v in pairs(p.selected_cards) do push_back(cards,{cards = v}) end
                push_back(infos, {
                    guid = p.guid,
                    chair_id = p.chair_id, 
                    status  = p.status,
                    pb_cards = cards
                })
            else
				local info = {
                    guid = p.guid,
                    chair_id = p.chair_id, 
                    status  = p.status,
                    pb_cards = nil
                }
				
				info.pb_cards =  (p == player) and {{cards = p.cards}} or nil
                push_back(infos,info)
            end
    end)
    dump(infos)
    send2client_pb(player,"SC_PlayerInfos",{pb_playerinfos = infos,table_status = self.status})
end


function sanshui_table:reconnect(player)
    print("sanshui_table:reconnect")
	player.trusteeship = false
    player.is_offline = false
	base_table.reconnect(self,player)

    self:foreach(function(p)
	    -- 通知消息
	    local notify = {
		    table_id = p.table_id,
		    pb_visual_info = {
			    chair_id = p.chair_id,
			    guid = p.guid,
			    account = p.account,
			    nickname = p.nickname,
			    level = p:get_level(),
			    money = p:get_money(),
			    header_icon = p:get_header_icon(),				
			    ip_area = p.ip_area,
		    },
		    is_onfline = true,
	    }

	    print("ip_area--------------------A",  p.ip_area)
	    print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
	    player:on_notify_sit_down(notify)
    end)

    local infos = {}
    self:foreach(function(v) 
        local time_remain = os.clock() - v.time_elaspe
        if v.status >= PlayerStatus.SELECT_CARDS_END then
            local sel_cards = {}
            for _,c in ipairs(v.selected_cards) do push_back(sel_cards,{cards = c}) end
            push_back(infos,{
				guid = v.guid,
				chair_id = v.chair_id, 
				status  = v.status,
				pb_cards = sel_cards,
                op_elasped = 0
			})
        else
            push_back(infos,{
                guid = v.guid,
                chair_id = v.chair_id, 
                status  = v.status,
                pb_cards = (v == player and {{cards = v.cards}} or {}),
                op_elasped = select_cards_elasped_time < time_remain and 0 or (select_cards_elasped_time - time_remain)
            })
        end
     end)

--     dump(infos)

    send2client_pb(player,"SC_PlayerInfos",{pb_playerinfos = infos,table_status = self.status})
end

function sanshui_table:deal_one_card_by_conidtion(k,func)
    for j = 1,k do
        if func(self.cards[j]) then  
            local card = self.cards[j]
            if j ~= k then self.cards[j], self.cards[k] = self.cards[k], self.cards[j] end
            return card
        end
    end

    return 0
end

function sanshui_table:deal_one_random_card(k)
--    assert(k > 0,"lkdsioajdalkfodajifdjaiodjfdsafjidoajfd")
    local j = math.random(k)
    local card = self.cards[j]
    if j ~= k then self.cards[j], self.cards[k] = self.cards[k], self.cards[j] end
    return card
end

function sanshui_table:peipai(end_pos)
    local function random_unoverlapped_nums_by_condition(count,begin,ending,func)
        local numbers = {}
        while true do
            local is_overlapped = false
            local num = math.random(begin,ending)
            if not func(num) then
                is_overlapped = true
            else
                for _,v in pairs(numbers) do if v == num then is_overlapped = true break end end
            end

            if not is_overlapped then  push_back(numbers,num) end
            if #numbers == count then break end
        end

        return numbers
    end

    local function random_unoverlapped_nums(count,begin,ending)
        return random_unoverlapped_nums_by_condition(count,begin,ending,function(num) return true end)
    end

    local peipai_create_cards_funcs = {
        qinglong = function(k) 
            local peipai_cards = {}
            local color = math.random(0,3)
            local card = color * 15 + 2

            for i = 0,12 do 
                local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c == card + i end)
                push_back(peipai_cards,card + i)
                k = k - 1
            end

            return peipai_cards
        end,
        yitiaolong = function(k) 
            local peipai_cards = {}
            for i = 0,12 do 
                local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 ==  2 + i end)
                push_back(peipai_cards,cur_card)
                k = k - 1
            end
            return  peipai_cards
        end,
        shierhuangzu = function(k) 
            local peipai_cards = {}
            for i = 1,13 do 
                local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 > 10 end)
                push_back(peipai_cards,cur_card)
                k = k - 1
            end

            return peipai_cards
        end,
        santonghuashun = function(k) 
            local peipai_cards = {}
            while true do
                local dao_cards = {}
                local rand_color = math.random(0,3)
                local number_3_start = math.random(2,12)
                for i = number_3_start,number_3_start + 2 do
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == i and math.floor(c / 15) == rand_color end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end
                if #dao_cards == 3 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end
                k = k + #dao_cards
            end

            for j = 1,2 do
                while true do
                    local dao_cards = {}
                    local rand_color = math.random(0,3)
                    local number_5_start = math.random(2,10)
                    for i = number_5_start,number_5_start + 4 do
                        local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == i and math.floor(c / 15) == rand_color end)
                        if cur_card ~= 0 then  
                            push_back(dao_cards,cur_card) 
                            k = k - 1 
                        end
                    end
                    if #dao_cards == 5 then
                        for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                        break
                    end
                    k = k + #dao_cards
                end
            end

            return peipai_cards    
        end,
        sanfentianxia = function(k) 
            local peipai_cards = {}
            local santiaos = random_unoverlapped_nums(3,2,14)
            for _,v in pairs(santiaos) do 
                for i = 1,4 do
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == v end)
                    push_back(peipai_cards,cur_card)
                    k = k - 1
                end
            end

            push_back(peipai_cards,self.cards[math.random(1,k)])
            return peipai_cards
        end,
        quanda = function(k)
            local peipai_cards = {}
            for i = 1,13 do 
                local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 >= 8 end)
                push_back(peipai_cards,cur_card)
                k = k - 1
            end
            return peipai_cards
        end,
        quanxiao = function(k) 
            local peipai_cards = {}
            for i = 1,13 do 
                local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 <= 8 end)
                push_back(peipai_cards,cur_card)
                k = k - 1
            end

            return peipai_cards
        end,
        couyise = function(k) 
            local peipai_cards = {}
            local rand_color = math.random(0,3)
            local colors = random_unoverlapped_nums_by_condition(2,0,3,function(num) return num % 2 == rand_color % 2 end)

            for i = 1,13 do 
                local cur_card = self:deal_one_card_by_conidtion(k,function(c) return math.floor(c / 15) == colors[1] or math.floor(c / 15) == colors[2] end)
                push_back(peipai_cards,cur_card)
                k = k - 1
            end

            return peipai_cards
        end,
        sitaosantiao = function(k) 
            local peipai_cards = {}
            local santiaos = random_unoverlapped_nums(4,2,14)
            for _,v in pairs(santiaos) do 
                for i = 1,3 do
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == v end)
                    push_back(peipai_cards,cur_card)
                    k = k - 1
                end
            end

            push_back(peipai_cards,self.cards[math.random(k)])
            return peipai_cards
        end,
        wuduisantiao = function(k) 
            local peipai_cards = {}
            local liuduis = {}

            for j = 1,6 do 
                while true do 
                    local dao_cards = {}
                    local rand_num = math.random(2,14)
                    for i = 1,2 do 
                        local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == rand_num end)
                        if cur_card ~= 0 then  
                            push_back(dao_cards,cur_card) 
                            k = k - 1 
                        end
                    end

                    if #dao_cards == 2 then
                        push_back(liuduis,dao_cards[1] % 15)
                        for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                        break
                    end

                    k = k + #dao_cards
                end
            end

            for _,v in pairs(liuduis) do
                local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == v end)
                if cur_card ~= 0 then
                    push_back(peipai_cards,cur_card)
                    k = k - 1
                    break
                end
            end

            return peipai_cards
        end,
        liuduiban = function(k) 
            local peipai_cards = {}

            for j = 1,6 do 
                while true do 
                    local dao_cards = {}
                    local rand_num = math.random(2,14)
                    for i = 1,2 do 
                        local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == rand_num end)
                        if cur_card ~= 0 then  
                            push_back(dao_cards,cur_card) 
                            k = k - 1 
                        end
                    end

                    if #dao_cards == 2 then
                        for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                        break
                    end

                    k = k + #dao_cards
                end
            end

            local cur_card = self:deal_one_random_card(k)
            push_back(peipai_cards,cur_card)
            k = k - 1
            return peipai_cards
        end,
        sanshunzi = function(k) 
            local peipai_cards = {}
            while true do
                local dao_cards = {}
                local number_3_start = math.random(2,12)
                for i = number_3_start,number_3_start + 2 do
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == i end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end
                if #dao_cards == 3 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end
                k = k + #dao_cards
            end

            for j = 1,2 do
                while true do
                    local dao_cards = {}
                    local number_5_start = math.random(2,10)
                    for i = number_5_start,number_5_start + 4 do
                        local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == i end)
                        if cur_card ~= 0 then  
                            push_back(dao_cards,cur_card) 
                            k = k - 1 
                        end
                    end
                    if #dao_cards == 5 then
                        for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                        break
                    end
                    k = k + #dao_cards
                end
            end

            return peipai_cards    
        end,
        santonghua = function(k) 
            local peipai_cards = {}
            while true do
                local dao_cards = {}
                local rand_color = math.random(0,3)
                local number_3_start = math.random(2,12)
                for i = 1,3 do
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return math.floor(c / 15) == rand_color end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end
                if #dao_cards == 3 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end
                k = k + #dao_cards
            end

            for j = 1,2 do
                while true do
                    local dao_cards = {}
                    local rand_color = math.random(0,3)
                    local number_5_start = math.random(2,10)
                    for i = 1,5 do
                        local cur_card = self:deal_one_card_by_conidtion(k,function(c) return math.floor(c / 15) == rand_color end)
                        if cur_card ~= 0 then  
                            push_back(dao_cards,cur_card) 
                            k = k - 1 
                        end
                    end
                    if #dao_cards == 5 then
                        for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                        break
                    end
                    k = k + #dao_cards
                end
            end

            return peipai_cards    
        end,
        tonghuashun = function(k,count) 
            local peipai_cards = {}
            while true do
                local dao_cards = {}
                local rand_color = math.random(0,3)
                local number_5_start = math.random(2,10)
                for i = number_5_start,number_5_start + 4 do
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == i and math.floor(c / 15) == rand_color end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end
                if #dao_cards == 5 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end

                k = k + #dao_cards
            end

            return peipai_cards    
        end,
        tiezhi = function(k,count) 
            local peipai_cards = {}
            while true do 
                local dao_cards = {}
                local rand_num = math.random(2,14)
                for i = 1,4 do 
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == rand_num end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end

                if #dao_cards == 4 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end

                k = k + #dao_cards
            end

            local cur_card = self:deal_one_random_card(k)
            push_back(peipai_cards,cur_card) 

            return peipai_cards  
        end,
        hulu = function(k,count) 
            local peipai_cards = {}

            while true do 
                local dao_cards = {}
                local rand_num = math.random(2,14)
                for i = 1,3 do 
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == rand_num end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end

                if #dao_cards == 3 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end
                k = k + #dao_cards
            end
            
            while true do 
                local dao_cards = {}
                local rand_num = math.random(2,14)
                for i = 1,2 do 
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == rand_num end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end

                if #dao_cards == 2 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end
                k = k + #dao_cards
            end

            return peipai_cards  
        end,
        tonghua = function(k,count)
            local peipai_cards = {}
            local rand_color = math.random(0,3)
            for i = 1,count do 
                local cur_card = self:deal_one_card_by_conidtion(k,function(c) return math.floor(c / 15) == rand_color end)
                if cur_card ~= 0 then  
                    push_back(peipai_cards,cur_card) 
                    k = k - 1 
                end
            end
            return peipai_cards
        end,
        santiao = function(k,count)
            local peipai_cards = {}

            while true do 
                local dao_cards = {}
                local rand_num = math.random(2,14)
                for i = 1,3 do 
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == rand_num end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end

                if #dao_cards == 3 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end
                k = k + #dao_cards
            end

            if count > 3 then
                for i = 1,2 do 
                    local cur_card = self:deal_one_random_card(k)
                    if cur_card ~= 0 then  
                        push_back(peipai_cards,cur_card) 
                        k = k - 1 
                    end
                end
            end

            return peipai_cards  
        end,
        duizi = function(k,count)
            local peipai_cards = {}
            while true do 
                local dao_cards = {}
                local rand_num = math.random(2,14)
                for i = 1,2 do 
                    local cur_card = self:deal_one_card_by_conidtion(k,function(c) return c % 15 == rand_num end)
                    if cur_card ~= 0 then  
                        push_back(dao_cards,cur_card) 
                        k = k - 1 
                    end
                end

                if #dao_cards == 2 then
                    for _,v in pairs(dao_cards) do push_back(peipai_cards,v) end
                    break
                end
                k = k + #dao_cards
            end

            if count == 3 then
                local cur_card = self:deal_one_random_card(k)
                if cur_card ~= 0 then  
                    push_back(peipai_cards,cur_card) 
                    k = k - 1 
                end
            elseif count == 5 then
                for i = 1,3 do
                    local cur_card = self:deal_one_random_card(k)
                    if cur_card ~= 0 then  
                        push_back(peipai_cards,cur_card) 
                        k = k - 1 
                    end
                end
            end

            return peipai_cards  
        end,
        wulong = function(k,count) 
            local peipai_cards = {}
            for i = 1,count do
                local cur_card = self:deal_one_random_card(k)
                push_back(peipai_cards,cur_card) 
                k = k - 1 
            end
            return peipai_cards
        end,
    }

    local peipai_cards = {}
    local k = end_pos

    local rand = math.random(0,10000)
    if rand < peipai_cfg.special_prob then
        local rand_special = math.random(1,10000)
        local special_cfg = peipai_cfg.special
        local cur_sum = 0
        for _,v in ipairs(special_cfg) do
            if rand_special > cur_sum and rand_special <= cur_sum + v.prob then
                return peipai_create_cards_funcs[v.name](k)
            end
            cur_sum = cur_sum + v.prob
        end

        local last_prob_v = special_cfg[#special_cfg]
        dump(last_prob_v)
        return peipai_create_cards_funcs[last_prob_v.name](k)
    end

    local common_cfg = peipai_cfg.common
    for i = 3,1,-1 do
        local rand_common_x = math.random(1,10000)
        cur_sum = 0
        for _,v in pairs(common_cfg[i]) do 
            if rand_common_x > cur_sum and rand_common_x <= cur_sum + v.prob then
                dump(v.name)
                local dao_cards = peipai_create_cards_funcs[v.name](k,i == 1 and 3 or 5)
                for _,c in pairs(dao_cards) do push_back(peipai_cards,c) end
                k = k - #dao_cards
                break
            end
            cur_sum = cur_sum + v.prob
        end
    end

    return peipai_cards
end

function sanshui_table:deal_cards_start_game()
    print("sanshui_table:deal_cards_start_game")
    self.game_log.players = {}
    self.game_start_time = get_second_time()

    self.status = TableStatus.WAIT_SELECT_CARDS
    self.scores = nil

	self:foreach_ready(function(v) 
        v.status = PlayerStatus.SELECT_CARDS 
        v.trusteeship = false
        v.standby = false
        v.selected_cards = {}
		v.is_offline = false
        v.cards = {}
        v.time_elaspe = os.clock()
        self.game_log.players[v.chair_id] = {}
    end)

    local infos = {}
    self:foreach(function(v)  
        push_back(infos,{
            guid = v.guid,
            chair_id = v.chair_id, 
            status  = v.status,
            pb_cards = nil,
            op_elasped = -1
        })
     end)

    local peipai_chair_id = 0
    local peipai_cards = {}
    local k = #self.cards
    if math.random(10000) < peipai_cfg.total_prob then
        peipai_cards = self:peipai(#self.cards)
        k = #self.cards - #peipai_cards
        while true do
            peipai_chair_id = math.random(4)
            if self.player_list_[peipai_chair_id] then break end
        end
    end

	self:foreach_ready(function(v) 
		local cards = {}
        if peipai_chair_id > 0 and v.chair_id == peipai_chair_id then
            cards = peipai_cards
        else
		    for j=1,13 do 
                cards[#cards + 1] = self:deal_one_random_card(k) 
                k = k - 1
            end
        end
			
--        if v.chair_id == 1 then
--            cards = {39,24,48,9,21,33,32,19,51,20,35,28,53}
--        elseif v.chair_id == 2 then
--            cards = {12,42,57,27,37,10,55,40,25,5,44,14,47}
--        elseif v.chair_id == 3 then
--            cards = {59,6,18,23,58,26,38,36,29,13,8,7,3}
--        elseif v.chair_id == 4 then
--            cards = {50,52,43,34,17,2,41,11,54,22,49,4,56}
--        end
        
        log.info("deal_cards,guid:%d,cards:%s",v.guid,cards_array_str(cards))
        dump(cards)
        send2client_pb(v,"SC_DealCards",{pb_cards = {{cards = cards}},next_op_seconds_time = select_cards_elasped_time,pb_players = infos})
        v.cards = cards
	end)



     self:foreach_not_ready(function(p)
          send2client_pb(p,"SC_PlayerInfos",{pb_playerinfos = infos,table_status = self.status}) 
     end)
end

function sanshui_table:tick()
    if self.status == TableStatus.READY_START then
        local wait_start_time = os.clock() - self.last_start_time
        if  wait_start_time > wait_to_start_elasped_time  then
            self:foreach_not_ready(function(p) p:forced_exit() end)
            if self:get_player_count() < 2 then 
                self.status = TableStatus.IDLE
                self:broadcast2client("SC_ReadyStart",{wait_time = wait_to_start_elasped_time,is_stop = 1})
            else
                self:deal_cards_start_game()
            end
        end
    elseif self.status == TableStatus.WAIT_SELECT_CARDS then
        self:foreach(function(v) 
            if v.status == PlayerStatus.SELECT_CARDS and ((os.clock() - v.time_elaspe) >= select_cards_elasped_time  + 3 or v.trusteeship == true) then
	            local l = logic:new()
                log.info("tick,splite_cards,guid:%d,cards:%s",v.guid,cards_array_str(v.cards))
	            local types = l:split_state_card(v.cards)

                local pb_cards = {}
                if #types == 0 then
                    local cards = {}
                    for i = 1,3 do push_back(cards,v.cards[i]) end
                    push_back(pb_cards,{cards = cards})

                    cards = {}
                    for i = 4,8 do push_back(cards,v.cards[i]) end
                    push_back(pb_cards,{cards = cards})

                    cards = {}
                    for i = 9,13 do push_back(cards,v.cards[i]) end
                    push_back(pb_cards,{cards = cards})

                    log.error("tick,splite_cards failed,guid:%d,cards:%s",v.guid,cards_array_str(v.cards))
                else
                    dump(types[1])
                    if #types[1] == 3 then 
                        push_back(pb_cards,{cards = types[1][3].cards})
                        push_back(pb_cards,{cards = types[1][2].cards})
                        push_back(pb_cards,{cards = types[1][1].cards})
                    else
                        push_back(pb_cards,{cards = types[1][1].cards})
                    end
                end

                dump(pb_cards)
				
                v.time_elaspe = os.clock()

	            self:selected_cards(v,{pb_cards = pb_cards})
            end
        end)
    elseif self.status == TableStatus.WAIT_BI_PAI then
        local online_player_count = self:get_online_player_count()
        self:foreach(function(v) 
            if v.status == PlayerStatus.BI_PAI and 
                ((os.clock() - v.time_elaspe) >= (self.balance_animate_time > 0 and self.balance_animate_time or wait_bipai_elasped_time) or
				(v.trusteeship and online_player_count == 0)) then
                log.warning("wait bipai elasped:%d,bi_pai_accomplish",v.guid)
                self:bi_pai_accomplish(v,{})
            end
        end)
    elseif self.status == TableStatus.IDLE then
        self:foreach(function(v) 
            if v.trusteeship == true then
                 if v.chair_id ~= 0 then v:forced_exit() end
		    end
        end)
    end
end

function test()
	sanshui_table:new():balance()
end

return sanshui_table