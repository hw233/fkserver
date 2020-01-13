local base_table = require "game.lobby.base_table"
local base_players = require "game.lobby.base_players"
local base_player = require "game.lobby.base_player"
require "game.net_func"
require "functions"
require "table_func"
require "game.timer_manager"
local log = require "log"
local pb = require "pb_files"
local json = require "cjson"


local send2db_pb = send2db_pb
local send2client_pb = send2client_pb
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type

local LOG_MONEY_OPT_TYPE_BONUS_HONGBAO = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_BONUS_HONGBAO")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")


local base_bonus_activity = class("base_bonus_activity")

function base_bonus_activity:ctor(id,start_time,end_time,platform_id,cfg)
	self.id = id
	self.start_time = start_time
	self.end_time = end_time
	self.cfg = json.decode(cfg)
	self.platform_id = platform_id
	self.broadcast_when_start = false
	self.broadcast_when_end = false
	self.broadcast_when_totally_end = false
end

function base_bonus_activity:is_open()
	return #self.cfg.game_types > 0
end

function base_bonus_activity:is_active()
	local cur_time = os.time()
	return cur_time >= self.start_time and cur_time < self.end_time and self:is_open()
end

function base_bonus_activity:is_elasped()
	return os.time() >= self.end_time or (not self:is_open())
end

function base_bonus_activity:is_totally_elasped()
	return os.time() > (self.end_time + self.cfg.bonus.valid_time) or (not self:is_open())
end

function base_bonus_activity:format_client_msg()
	local cfg = {game_types = self.cfg.game_types,valid_time = self.cfg.bonus.valid_time}

	return 	{
			activity_id = self.id,
			start_time = self.start_time,
			end_time = self.end_time,
			platform_id = tonumber(self.platform_id),
			cfg = json.encode(cfg)
		}
end

function base_bonus_activity:tick()
	if self:is_elasped() and not self.broadcast_when_end then
		if def_first_game_type == 1 and def_second_game_type == 1 then
			broadcast_platform_marquee(tostring(self.platform_id),1,1,4)
			self.broadcast_when_end = true
		end
	end

	if self:is_active() and not self.broadcast_when_start then
		if def_first_game_type == 1 and def_second_game_type == 1 then
			broadcast_platform_marquee(tostring(self.platform_id),1,1,3)
			self.broadcast_when_start = true
			
			if self:is_totally_elasped() or not self:is_open() then return end

			local msg = {
				pb_activities = {self:format_client_msg()}
			}
			base_players:foreach(function(p)
				if tonumber(p.platform_id) == self.platform_id then
					send2client_pb(p,"SC_BonusActivity",msg)
				end
			end)
		end
	end

	if self:is_totally_elasped() and not self.broadcast_when_totally_end then
		log.info("base_bonus_activity:tick bonus [%d] end",self.id)
		self.broadcast_when_totally_end = true
		base_players:foreach(function(p)
			if tonumber(p.platform_id) == self.platform_id then
				send2client_pb(p,"SC_BonusActivity",{
					pb_activities = {}
				})
			end
		end)
	
	end
end

local active_bonus_activities = {}

local function load_activity(id)
	send2db_pb("SD_ReqQueryBonusActivity",{id = id})
end

local function filter_by_platform(platform_id)
	if not platform_id or platform_id < 0 then return active_bonus_activities end
	local activities = {}
	for id,activity in pairs(active_bonus_activities) do
		if activity.platform_id == platform_id then
			activities[id] = activity
		end
	end

	return activities
end

local function new_activity(id,start_time,end_time,platform_id,cfg)
	active_bonus_activities[id] = base_bonus_activity.new(id,start_time,end_time,platform_id,cfg)
end

local function latest_activity(platform_id)
	local latest_activity = nil
	for _,activity in pairs(active_bonus_activities) do
		if	not activity:is_totally_elasped() and 
			#activity.cfg.game_types > 0 and 
			(not platform_id or activity.platform_id == platform_id) and
			(not latest_activity or activity.start_time > latest_activity.start_time) 
		then 
			latest_activity = activity
		end
	end

	return latest_activity
end

local function tick()
	for _,activity in pairs(active_bonus_activities) do
		activity:tick()
		if activity:is_totally_elasped() then
			active_bonus_activities[activity.id] = nil
		end
	end
end


local base_bonus = class("base_bonus")

function base_bonus:ctor(guid,activity_or_id,index,money,is_pick,valid_time_until)
	self.guid = guid
	self.activity_id = type(activity_or_id) == "table" and activity_or_id.id or activity_or_id
	self.index = index
	self.money = money
	self.valid_time_until = valid_time_until
	self.is_pick = is_pick
end

function base_bonus:pick()
	if os.time() >= self.valid_time_until or self.is_pick == true then
		send2client_pb(self.guid,"SC_PickBonusResult",{
			guid = self.guid,
			bonus_activity_id = self.bonus_activity_id,
			index = self.index,
			success = false
		})
		return
	end

	send2db_pb("SD_ReqPickPlayerBonus",{guid = self.guid,bonus_activity_id = self.activity_id,bonus_index = self.index})
	self.is_pick = false
end


function base_player:increase_play_info(money)
	local platform_id = tonumber(self.platform_id)
	self.bonus = self.bonus or {}

	for _,activity in pairs(active_bonus_activities) do
		if not activity:is_active() then return end

		self.bonus[activity.id] = self.bonus[activity.id] or {}
		self.bonus[activity.id][platform_id] = self.bonus[activity.id][platform_id] or {}
		self.bonus[activity.id][platform_id].total_play_count = (self.bonus[activity.id][platform_id].total_play_count or 0) + 1
		self.bonus[activity.id][platform_id].total_play_money = (self.bonus[activity.id][platform_id].total_play_money or 0) + money
	end
end

function base_player:send_unelasped_activities()
	local activities = {}
	for _,activity in pairs(active_bonus_activities) do
		if activity:is_totally_elasped() or #activity.cfg.game_types == 0 or tonumber(self.platform_id) ~= activity.platform_id then 
			return 
		end

		dump(activity)

		table.push_back(activities,activity:format_client_msg())
	end

	send2client_pb(self,"SC_BonusActivity",{
				pb_activities = activities
			})
end

function base_player:send_bonuses()
	local latest_activity = latest_activity(tonumber(self.platform_id))
	if not latest_activity then 
		send2client_pb(self,"SC_Bonuses",{pb_bonuses = {}})
		return
	else
		if not self.bonus or not self.bonus[latest_activity.id] or  not self.bonus[latest_activity.id].hongbao then
			send2client_pb(self,"SC_Bonuses",{pb_bonuses = {}})
			return
		end

		local hongbaos = {}
		for i,bonus in pairs(self.bonus[latest_activity.id].hongbao) do
			table.push_back(hongbaos,{
				bonus_activity_id = latest_activity.id,
				guid = self.guid,
				index = i,
				money = bonus.money,
				get_time = bonus.get_time,
				is_pick = bonus.is_pick,
				valid_time_until = latest_activity.end_time + latest_activity.cfg.bonus.valid_time
			})
		end

		dump(hongbaos)
		send2client_pb(self,"SC_Bonuses",{
			pb_bonuses = hongbaos
		})
	end
end

function base_player:check_and_switch_to_next_bonus(activity_id)
	local activity = active_bonus_activities[activity_id]
	if not activity then 
		log.error("base_player:check_and_switch_to_next_bonus not find activity id [%d]",activity_id)
		return 
	end

	local bonus_cfg = activity.cfg.bonus
	local bonus_trigger = bonus_cfg.trigger
	local platform_id = tonumber(self.platform_id)
	self.bonus[activity_id][platform_id] = self.bonus[activity_id][platform_id] or {}
	local cur_activity_bonus_data = self.bonus[activity_id][platform_id]
	cur_activity_bonus_data.cur_bonus_index = cur_activity_bonus_data.cur_bonus_index or 1
	if not cur_activity_bonus_data.cur_bonus_play_count or not cur_activity_bonus_data.cur_bonus_play_count.min or 
		not cur_activity_bonus_data.cur_bonus_play_count.max then
		cur_activity_bonus_data.cur_bonus_play_count = cur_activity_bonus_data.cur_bonus_play_count or {}
		cur_activity_bonus_data.cur_bonus_play_count.min = bonus_trigger.play_count[1]
		cur_activity_bonus_data.cur_bonus_play_count.max = bonus_trigger.play_count[2]
		send2db_pb("SD_UpdatePlayerCurrentBonusLimitInfo",{
			guid = self.guid,
			activity_id = activity_id,
			bonus_index = cur_activity_bonus_data.cur_bonus_index,
			play_count_min = cur_activity_bonus_data.cur_bonus_play_count.min,
			play_count_max = cur_activity_bonus_data.cur_bonus_play_count.max,
			money = bonus_trigger.money * cur_activity_bonus_data.cur_bonus_index
		})
	end

	dump(cur_activity_bonus_data)
	dump(bonus_trigger)

	cur_activity_bonus_data.total_play_count = cur_activity_bonus_data.total_play_count or 0
	cur_activity_bonus_data.total_play_money = cur_activity_bonus_data.total_play_money or 0
	if cur_activity_bonus_data.total_play_count > cur_activity_bonus_data.cur_bonus_play_count.max then
		cur_activity_bonus_data.cur_bonus_index = cur_activity_bonus_data.cur_bonus_index + 1
		local cur_bonus_play_count_min = cur_activity_bonus_data.cur_bonus_play_count.max
		cur_activity_bonus_data.cur_bonus_play_count.max = cur_activity_bonus_data.cur_bonus_play_count.max + bonus_trigger.play_count[2]
		cur_activity_bonus_data.cur_bonus_play_count.min = cur_bonus_play_count_min + bonus_trigger.play_count[1]

		send2db_pb("SD_UpdatePlayerCurrentBonusLimitInfo",{
			guid = self.guid,
			activity_id = activity_id,
			bonus_index = cur_activity_bonus_data.cur_bonus_index,
			play_count_min = cur_activity_bonus_data.cur_bonus_play_count.min,
			play_count_max = cur_activity_bonus_data.cur_bonus_play_count.max,
			money = bonus_trigger.money * cur_activity_bonus_data.cur_bonus_index
		})
	end
end

function base_player:check_and_create_bonus()
	if self.is_guest == true then return false end
	local platform_id = tonumber(self.platform_id)

	local have_bonus = false
	for _,activity in pairs(active_bonus_activities) do
		if not activity:is_active() then return  end

		if platform_id ~= activity.platform_id then  return  end

		if not table.logic_or(activity.cfg.game_types,function(first_game_type) 
			return first_game_type == def_first_game_type
		end) then
			log.info("check_and_create_bonus can not match first_game_type [%d]",def_first_game_type)
			return
		end
	
		local activity_id = activity.id
		if not self.bonus or not self.bonus[activity_id] or not self.bonus[activity_id][platform_id]  then 
			return
		end

		self:check_and_switch_to_next_bonus(activity_id)
		
		local bonus_cfg = activity.cfg.bonus
		local bonus_trigger = bonus_cfg.trigger
		local cur_activity_bonus_data = self.bonus[activity_id][platform_id]
		local cur_bonus_index = cur_activity_bonus_data.cur_bonus_index or 1

		dump(activity.cfg)
		dump(cur_activity_bonus_data)
		if cur_bonus_index > bonus_cfg.total_count then return end

		dump(self.bonus[activity_id].hongbao)
		if	(cur_activity_bonus_data.total_play_count >= cur_activity_bonus_data.cur_bonus_play_count.min) and
			(cur_activity_bonus_data.total_play_money   <= -bonus_trigger.money * cur_bonus_index)  and 
			(math.random(10000) < math.random(bonus_trigger.probability[1],bonus_trigger.probability[2])) and
			(not self.bonus[activity_id].hongbao or not self.bonus[activity_id].hongbao[cur_bonus_index])
		then
			local total_count = bonus_cfg.total_count
			local total_money = bonus_cfg.total_money
			local money_increment = (bonus_cfg.money_increment  + bonus_cfg.money_percent_per_bonus[2])/ 10000
			--?????? ????? x???? x * (1 + (n - 1) * b),?????(n * (n - 1)) * b / 2 * x + n * x = ???,????x?
			local x = total_money / (total_count * (total_count - 1) * money_increment / 2 + total_count)
			local real_money_increment = bonus_cfg.money_increment / 10000
			local float_money_increment = math.random(bonus_cfg.money_percent_per_bonus[1], bonus_cfg.money_percent_per_bonus[2]) / 10000
			local hongbao_money = math.floor((1 + real_money_increment * (cur_bonus_index - 1) + float_money_increment) * x)
			log.warning("get bonus guid [%d] money [%d] activity_id[%d] index[%d]",self.guid,hongbao_money,activity.id,cur_bonus_index)
			send2db_pb("SD_ReqCreatePlayerBonus",{pb_bonuses = {
				{
					guid = self.guid,
					bonus_activity_id = activity.id,
					bonus_index = cur_bonus_index,
					money = hongbao_money,
					get_in_game_id = def_game_id,
					valid_time_until = bonus_cfg.valid_time + activity.end_time,
					is_pick = false
				}
			}})

			send2client_pb(self,"SC_WinBonusNotify",{
				guid = self.guid,
				bonus_activity_id = activity.id,
				index = cur_bonus_index
			})

			self.bonus[activity_id].hongbao = self.bonus[activity_id].hongbao or {}
			self.bonus[activity_id].hongbao[cur_bonus_index] = base_bonus.new(self.guid,activity,cur_bonus_index,hongbao_money,false,bonus_cfg.valid_time + activity.end_time)
			have_bonus = true
		end
	end

	return have_bonus
end

function base_player:load_bonus_hongbao(activity_or_id,is_pick)
	local msg = {guid = self.guid}
	if activity_or_id then 
		msg.bonus_activity_id = (type(activity_or_id) == "table" and activity_or_id.id or activity_or_id)
	end

	if is_pick then
		msg.is_pick = is_pick
	end

	dump(msg)
	send2db_pb("SD_ReqQueryPlayerBonus",msg)
end


function base_player:load_bonus_game_statisticss(activity_or_id)
	local msg = {guid = self.guid,platform_id = tonumber(self.platform_id)}
	if activity_or_id then
		local activity = type(activity_or_id) == "table" and activity_or_id or base_bonus_activity_manager:find(activity_or_id)
		msg.pb_game_types = activity.cfg.game_types
		msg.bonus_activity_id = activity.id
	end

	dump(msg)
	send2db_pb("SD_ReqPlayerBonusGameStatistics",msg)
end

function base_player:load_bonus_activity_limit_info(activity_or_id)
	local msg = {guid = self.guid}
	if activity_or_id then
		local activity_id = type(activity_or_id) == "number" and activity_or_id or activity_or_id.id
		msg.activity_id = activity_id
	else
		local activity = base_bonus_activity_manager:latest_activity(tonumber(self.platform_id))
		if not activity then return end
		msg.activity_id = activity.id
	end

	send2db_pb("SD_QueryPlayerCurrentBonusLimitInfo",msg)
end

function base_player:on_ds_load_game_statistics(statistic)
	self.bonus = self.bonus or {}
	self.bonus[statistic.bonus_activity_id] = self.bonus[statistic.bonus_activity_id] or {}
	self.bonus[statistic.bonus_activity_id][statistic.platform_id] = self.bonus[statistic.bonus_activity_id][statistic.platform_id] or {}
	local bonus = self.bonus[statistic.bonus_activity_id][statistic.platform_id]
	bonus.total_play_count = statistic.times + (bonus.total_play_count or 0)
	bonus.total_play_money = statistic.money + (bonus.total_play_money or 0)
end

function base_player:on_ds_load_bonus(bonus)
	self.bonus = self.bonus or {}
	self.bonus[bonus.bonus_activity_id] = self.bonus[bonus.bonus_activity_id] or {}
	self.bonus[bonus.bonus_activity_id].hongbao = self.bonus[bonus.bonus_activity_id].hongbao or {}
	self.bonus[bonus.bonus_activity_id].hongbao[bonus.bonus_index] = 
				base_bonus.new(bonus.guid,bonus.bonus_activity_id,bonus.bonus_index,bonus.money,bonus.is_pick,bonus.valid_time_until)
end

function base_player:on_ds_pick_bonus(activity_id,bonus_index)
	if not self.bonus[activity_id] or not self.bonus[activity_id].hongbao[bonus_index] then 
		send2client_pb(self,"SC_PickBonusResult",{
			guid = self.guid,
			bonus_activity_id = activity_id,
			index = bonus_index,
			success = false
		})
		return
	end

	self.bonus[activity_id].hongbao[bonus_index].is_pick = true

	local bonus_money = self.bonus[activity_id].hongbao[bonus_index].money

	self:add_money(
		{{ money_type = ITEM_PRICE_TYPE_GOLD, money = bonus_money }}, LOG_MONEY_OPT_TYPE_BONUS_HONGBAO
	)

	send2client_pb(self,"SC_PickBonusResult",{
		guid = self.guid,
		bonus_activity_id = activity_id,
		index = bonus_index,
		success = true,
		money = bonus_money
	})
	
	local activiy = base_bonus_activity_manager:find(activity_id)
	if not activiy then
		log.warning("on_ds_pick_bonus,not find activiy guid[] activity_id[%d] index[%d]",self.guid,activity_id,bonus_index)
		return
	end

	broadcast_platform_marquee(tostring(activiy.platform_id),1,1,2,self.nickname,bonus_money / 100)
end

function base_player:on_ds_load_current_bonus_activity_limit_info(msg)
	local platform_id = tonumber(self.platform_id)
	local activity_id = msg.activity_id
	self.bonus = self.bonus or {}
	self.bonus[activity_id] = self.bonus[activity_id] or {}
	self.bonus[activity_id][platform_id] = self.bonus[activity_id][platform_id] or {}

	local cur_activity_bonus_data = self.bonus[activity_id][platform_id]

	cur_activity_bonus_data.cur_bonus_index = (not msg.bonus_index or msg.bonus_index <= 0) and  1 or msg.bonus_index

	cur_activity_bonus_data.cur_bonus_play_count = cur_activity_bonus_data.cur_bonus_play_count or {}

	if not msg.play_count_min  or msg.play_count_min == 0 then return end
	
	cur_activity_bonus_data.cur_bonus_play_count.min = msg.play_count_min
	cur_activity_bonus_data.cur_bonus_play_count.max = msg.play_count_max
end

--写日志
local old_player_money_log = base_table.player_money_log
function base_table:player_money_log(player,s_type,s_old_money,s_tax,s_change_money,s_id,get_bonus_money_,to_bonus_money_)
	dump("base_table:player_money_log")
	if not player:is_android()  then
		player:increase_play_info(s_change_money)
	end
	old_player_money_log(self,player,s_type,s_old_money,s_tax,s_change_money,s_id,get_bonus_money_,to_bonus_money_)
end


local player_money_log_when_gaming = base_table.player_money_log_when_gaming
function base_table:player_money_log_when_gaming(player,s_type,s_old_money,s_tax,s_change_money,s_id,get_bonus_money_,to_bonus_money_)
	dump("base_table:player_money_log_when_gaming")
	if not player:is_android() then
		player:increase_play_info(s_change_money)
	end

	player_money_log_when_gaming(self,player,s_type,s_old_money,s_tax,s_change_money,s_id,get_bonus_money_,to_bonus_money_)
end

return {
	load_activity = load_activity,
	tick = tick,
	new_activity = new_activity,
	latest_activity = latest_activity,
}