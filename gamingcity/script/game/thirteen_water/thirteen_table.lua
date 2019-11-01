-- 13水table
-- 0：方块2，1：梅花2，2：红桃2，3：黑桃2 …… 48：方块A，49：梅花A，50：红桃A，51：黑桃A

local pb = require "pb"
local base_table = require "game.lobby.base_table"
require "game.lobby.base_player"

require "game.thirteen_water.thirteen_cards_recommender"
local thirteen_cards_recommender = thirteen_cards_recommender

local LOG_MONEY_OPT_TYPE_THIRTEEN_WATER = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_THIRTEEN_WATER")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

--游戏状态
local THIRTEEN_GAME_INIT    = pb.enum("THIRTEEN_GAME_STATE", "THIRTEEN_GAME_INIT")
local THIRTEEN_GAME_WAITING = pb.enum("THIRTEEN_GAME_STATE", "THIRTEEN_GAME_WAITING")
local THIRTEEN_GAME_SORTING = pb.enum("THIRTEEN_GAME_STATE", "THIRTEEN_GAME_SORTING")
local THIRTEEN_GAME_COMPARE = pb.enum("THIRTEEN_GAME_STATE", "THIRTEEN_GAME_COMPARE")

--玩家状态
local THIRTEEN_PLAYER_WAITING = pb.enum("THIRTEEN_PLAYER_STATE", "THIRTEEN_PLAYER_WAITING")
local THIRTEEN_PLAYER_SORTING = pb.enum("THIRTEEN_PLAYER_STATE", "THIRTEEN_PLAYER_SORTING")
local THIRTEEN_PLAYER_SORTED  = pb.enum("THIRTEEN_PLAYER_STATE", "THIRTEEN_PLAYER_SORTED")
local THIRTEEN_PLAYER_COMPARE = pb.enum("THIRTEEN_PLAYER_STATE", "THIRTEEN_PLAYER_COMPARE")

--返回类型
local THIRTEEN_TYPE_SUCESS      = pb.enum("THIRTEEN_RETURN_TYPE", "THIRTEEN_TYPE_SUCESS")
local THIRTEEN_TYPE_ERROR_CARDS = pb.enum("THIRTEEN_RETURN_TYPE", "THIRTEEN_TYPE_ERROR_CARDS")


local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local redis_command = redis_command

local Waiting_Time = 5  --等待时间
local Arrange_Time = 30 --整理时间
local COMPARE_Time = 10 --比牌时间


local is_test = true


thirteen_table = base_table:new()


function thirteen_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)

	self.state = THIRTEEN_GAME_INIT

	self.cards = {}
	for i = 1, 52 do
		self.cards[i] = i - 1
	end
	self.player_cards_recommender = {}
	for i = 1, chair_count do
		self.player_cards_recommender[i] = thirteen_cards_recommender:new()
	end

	thirteen_cards_recommender.test()
	--[[
	if is_test then
		for i = 1, 2 do
			self.player_list_[i] = {guid = i,chair_id = i,pb_base_info = {money = 9999999}}
		end
		self:start(2)
	end
	--]]
end

function thirteen_table:load_lua_cfg()
	local funtemp = load(self.room_.room_cfg)
	local thirteen_config = funtemp()
end

function thirteen_table:can_enter(player)
	if player.vip == 100 then
		return true
	end
	
	-- body
	for _,v in ipairs(self.player_list_) do		
		if v then
			print("===========judge_play_times")
			if player:judge_ip(v) then
				if not player.ipControlflag then
					print("thirteen_table:can_enter ipcontorl change false")
					return false
				else
					-- 执行一次后 重置
					print("thirteen_table:can_enter ipcontorl change true")
					return true
				end
			end
		end
	end
	print("thirteen_table:can_enter true")
	return true
end

function increase_player()
	-- body
	local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)
end

function reduce_player()
	-- body
	local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)
end

-- 玩家坐下
function thirteen_table:player_sit_down(player, chair_id_)
	base_table.player_sit_down(self,player, chair_id_)
	increase_player()

	--在整理或者比牌中只能观看
	if self.state == THIRTEEN_GAME_SORTING or self.state == THIRTEEN_GAME_SORTING then
		player.is_audience = true
		self:send_play_info()
	end
end

-- 玩家站起
function thirteen_table:player_stand_up(player, is_offline)
	local success = base_table.player_stand_up(self,player,is_offline) 
	if success then
		reduce_player()
	end
	return success
end

-- 检查是否可取消准备
function thirteen_table:check_cancel_ready(player, is_offline)
	return not self:is_play(player, is_offline)
end

function thirteen_table:is_play( ... )
	if self.state == THIRTEEN_GAME_INIT or self.state == THIRTEEN_GAME_WAITING then
		return false
	end
	return true
end

function thirteen_table:execute_delay(func,delay_seconds)

    local act = {}
    act.dead_line = os.time() + delay_seconds
    act.execute = function(obj)
        func(obj)
    end
    self.timer[#self.timer + 1] = act
	
end

function thirteen_table:timer_update()
	-- body
	local dead_list = {}
    for k,v in pairs(self.timer) do
		
        if v and os.time() > v.dead_line then
            v.execute(self)
            dead_list[#dead_list + 1] = k
         end
    end

    for k,v in pairs(dead_list) do
        self.timer[v] = nil
    end
end

-- 心跳
function thirteen_table:tick()
	if self.do_logic_update then
		self:timer_update()
	end
end


-- 开始游戏
function thirteen_table:start(player_count)
	print("start------------------->")
	self:update_state(THIRTEEN_GAME_WAITING)
end

function thirteen_table:update_state(new_state)
	-- body
	if new_state == THIRTEEN_GAME_WAITING then
		self.state = new_state
		self:set_waiting()

	elseif new_state == THIRTEEN_GAME_SORTING then
		self.state = new_state
		self:set_sorting()

	elseif new_state == THIRTEEN_GAME_COMPARE then
		self.state = new_state
		self:set_compare()

	end
end

function thirteen_table:set_waiting()
	-- body
	self.do_logic_update = true
	self.timer = {}

	self:foreach(function (p)
    	--不是观众
		p.is_audience = false 
		p.state = THIRTEEN_PLAYER_WAITING
   	end)

	self:execute_delay(thirteen_table.send_cards,Waiting_Time)
end

-- 洗牌
function thirteen_table:shuffle()
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	local card_len = #self.cards
	local left_cards_len = card_len
	for i = 1, card_len-1 do
		local index = math.random(left_cards_len)
		
		if index ~= left_cards_len then
			self.cards[index], self.cards[left_cards_len] = self.cards[left_cards_len], self.cards[index]
		end
		left_cards_len =  left_cards_len - 1
	end
end

--给玩家发牌
function thirteen_table:send_cards()
	-- body
	--等待过程中有人离开
	if #self.player_list_ < 2 or self.state ~= THIRTEEN_GAME_WAITING then
		print("player leave or state change----------------->>>")
		return
	end
	print("send_cards------------------->")

	self:shuffle()

	--给所有玩家发牌
	local card_index = 1
	self:foreach(function (p)
    	 p.state = THIRTEEN_PLAYER_SORTING

		-- 发13张牌
		local cards_ = {}
		for j=1,13 do
			cards_[j] = self.cards[card_index]
			--local value = math.floor(cards_[j] / 4)
			--local color = cards_[j] % 4
			--print("value->",value+2,"color->",color)
			card_index = card_index+1
		end
		self.player_cards_recommender[p.chair_id]:init(cards_)
		local recommend_cards = self.player_cards_recommender[p.chair_id]:get_recommend_cards()

		local notify = {
			sort_times = Arrange_Time,
			pb_recommend_cards = recommend_cards
		}
		
		send2client_pb(p, "SC_ThirteenStart", notify)
   	end)

	
	self:update_state(THIRTEEN_GAME_SORTING)
end

function thirteen_table:set_sorting()
	-- body
	self:execute_delay(thirteen_table.send_compare_info,Arrange_Time)
end

function thirteen_table:set_player_cards(player, msg)
	-- body
	local success = true

	if success then
		player.state = THIRTEEN_PLAYER_SORTED

		send2client_pb(player,"SC_Player_SetCards",{ret = THIRTEEN_TYPE_SUCESS})
		self:broadcast2client_except(player.guid, "SC_Player_SetOk", {guid = player.guid})
	else
		send2client_pb(player,"SC_Player_SetCards",{ret = THIRTEEN_TYPE_ERROR_CARDS})
	end

	
end

--发送比牌信息
function thirteen_table:send_compare_info()
	-- body
	--给所有玩家发比牌信息
	local notify = {
		pb_compare_infos = {}
	}

	self:foreach(function (p)
    	p.state = THIRTEEN_PLAYER_COMPARE

    	local cards_Info = {
			cards = self.player_cards_recommender[p.chair_id].cards_,
			is_special = false,
			card_type = {0}
		}

		local player_Compare_Info = {
			score_change = 0,
			money_change = 0,
			pb_player_cards = cards_Info,
			shoot_chair_ids = {},
			is_shoot_all = false
		}
		
		table.insert(notify.pb_compare_infos,player_Compare_Info)
   	end)

   	self:broadcast2client("SC_CompareCards",notify)

   	self:update_state(THIRTEEN_GAME_COMPARE)

end

function thirteen_table:set_compare()
	-- body
	self:execute_delay(thirteen_table.compare_end,COMPARE_Time)
end

function thirteen_table:compare_end()
	-- body
	self.state = THIRTEEN_GAME_INIT
	self.do_logic_update = false


	--踢出不在游戏中和钱不够的玩家
	local room_limit = self.room_:get_room_limit()
	self:foreach(function (p)
    	p.state = THIRTEEN_PLAYER_WAITING

    	if p.in_game == false then
    		p:forced_exit()  
    	else
            p:check_forced_exit(room_limit)
        end
   	end)

	--自动开始下一局
   	if #self.player_list_ >= 2 then
		self:update_state(THIRTEEN_GAME_WAITING)
	end 
end


function thirteen_table:send_play_info(player)
	-- 游戏信息
	local notify = {
		game_state = self.state,
		pb_players_info = {}
	}

	self:foreach(function (p)
    	 
    	local player_Play_Info = {
    	 	is_audience = p.is_audience,
    	 	player_state = p.state,
			pb_compare_info = {}
		}
		
		--在比牌阶段就发送比牌信息
		if self.state == THIRTEEN_GAME_COMPARE then

			local cards_Info = {
				cards = self.player_cards_recommender[p.chair_id].cards_,
				is_special = false,
				card_type = {0}
			}

			player_Play_Info.pb_compare_info = {
				score_change = 0,
				money_change = 0,
				pb_player_cards = cards_Info,
				shoot_chair_ids = {},
				is_shoot_all = false
			}
		end
		
		table.insert(notify.pb_players_info,player_Play_Info)
   	end)

	send2client_pb(player, "SC_Thirteen_PlayInfo", notify)
end

--请求玩家数据
function thirteen_table:reconnection_play_msg(player)
	log.info("player Reconnection : ".. player.chair_id)
	base_table.reconnection_play_msg(self,player)

	--发送其他玩家基础信息给重连玩家
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

	--发送游戏信息
	self:send_play_info(player)
end