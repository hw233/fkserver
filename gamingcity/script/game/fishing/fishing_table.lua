local base_table = require "game.lobby.base_table"
require "game.lobby.base_player"
require "game.lobby.base_room"
require "functions"

require "game.fishing.config"
local pathmanager = require "game.fishing.logic.pathmanager"
local fish = require "game.fishing.logic.fish"
local obj = require "game.fishing.logic.object"

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local redis_command = redis_command

local pb = require "pb"

local LOG_MONEY_OPT_TYPE_BUYU = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_BUYU")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

local MAX_PROBABILITY = 1000
local SWITCH_SCENE_END = 8

fishing_table = class("fishing_table",base_table)

function fishing_table:ctor( ... )
	self.user_win_score = {}
	self.chair_player = {}
	self.distribution_fish_time = {}
	self.can_lock_list = {}
	self.special_fish_count = 0
	self.pause_time = 0
	self.allow_fire = false
	self.bullet_manager = {}
	self.fish_manager = {}
	self.cur_scene = {
		trooped = {},
		distribute = {},
		conf = {},
	}
	self.scene_time = 0
	self.last_tick_time = 0
end

function fishing_table:on_game_start()
	self.cur_scene.conf = scene[1]
	self.secen_time = 0
	self.last_tick_time = 0
end

function fishing_table:reset_scene_distruction()
	
end

function fishing_table:send_allow_fire(guid,is)
	self:send2client(guid,"SC_AllowFire",{
		allow_fire = self.allow_fire,
	})
end

function fishing_table:switch_scene()
	if not self.cur_scene then
		self.cur_scene = {
			distribute = {},
			trooped = {},
			conf = scene[1],
		}
	else
		self.cur_scene = {
			conf = scene[self.cur_scene.conf.next],
			distribute = {},
			trooped = {}
		}
	end
	
	for _,p in pairs(self.player_list_) do
		p.locking = false
		p.lock_fish_id = 0
		p.bullets = {}
		self:send2client(p.guid,"SC_LockFish",{
			chair_id = 0,
			lock_id = 0,
		})
		self.allow_fire = false
	end

	self:broadcast("SC_AllowFire",{
		allow_fire = false,
	})

	self:broadcast("SC_SwitchScene",{
		nst = self.cur_scene.conf.id,
		switching = 1,
	})

	self.fish_manager = {}
	self.scene_time = 0
end

function fishing_table:send_fish(guid,fish)
	local move = fish.component[obj.ECF_MOVE]
	local bufmgr = fish.component[obj.ECF_BUFFERMGR]

	local msg = {
		fish_id = fish.id,
		type_id = fish.category,
		create_tick = fish.create_tick,
		fis_type = fish.fish_type,
		refersh_id = fish.refresh_id,
		server_tick = os.clock(),
	}

	if move then
		msg.path_id = move.path_id
		if move.type == obj.EMCT_DIRECTION then
			msg.offest_x = move.pos.x
			msg.offest_y = move.pos.y
		else
			msg.offest_x = move.offset.x
			msg.offest_y = move.offset.y
		end

		msg.dir = move.dir
		msg.delay = move.delay
		msg.fish_speed = move.speed
		msg.troop = move.troop
	end

	if bufmgr and bufmgr[obj.EBT_ADDMUL_BYHIT] then
		event.post("FishMulChange", fish)
	end

	send2client(guid,"SC_SendFish", msg)
end

function fishing_table:add_buffer(type_id,param,life)
	self:broadcast("SC_AddBuffer",{
		buffer_type = type_id,
		buffer_param = param,
		buffer_time = life,
	})

	for _,fish in pairs(self.fish_manager) do
		fish.component[obj.ECF_BUFFERMGR]:add(type_id,param,life)
	end
end

function fishing_table:distibution_fish(delta_time)
	if self.pause_time > 0 then
		self.pause_time = self.pause_time - delta_time
		return
	end

	self.scene_time = self.scene_time + delta_time

	if not self.cur_scene or not self.cur_scene.conf then
		return
	end

	local scene_conf = self.cur_scene.conf

	if self.scene_time > scene_conf.start_time then
		self:switch_scene()
		return
	end

	local function choice_by_weight(weights)
		local nw = math.random(0, table.sum(weights))
		for i,w in ipairs(weights) do
			if nw < w then
				return i
			end

			nw = nw - w
		end

		return nil
	end

	local function distribute_troop(troop_conf)
		if (self.scene_time < troop_conf.begin_time) and (self.scene_time > troop_conf.end_time) then
			return
		end

		local fish_type = nil
		--获取总步数
		for i,shape in ipairs(troop_conf.shape) do
			--获取鱼类型列表和权重列表最小值
			for ni = 0,shape.count - 1 do
				if not fish_type or ~shape.same then
					local index = choice_by_weight(shape.weight_list)
					fish_type = shape.type_list[index]
				end
				
				local fish_conf = fish_set[fish_type]
				if fish_conf then
					local f = fish.create(fish_conf,shape.pos,0,ni * shape.interval,shape.speed,shape.path_id)
					table.insert(self.fishmanager,f)
					self:send_fish(f)
				end
			end
		end
	end

	local function send_troop_desctiption(troop_conf)
		--给所有鱼加速度BUFF
		self:add_buffer(obj.EBT_CHANGESPEED, 5, 60)
		--配置刷新时间开始时间 为 2秒
		self:broadcast("SC_SendDes",{
			des = table.slice(troop_conf.describe_text,1,4),
		})
	end

	local function distribute_fish(dist_conf)
		local dist_count = math.random(dist_conf.count.min, dist_conf.count.max)
		for i = 1,dist_count do
			local index = choice_by_weight(dist_conf.weight_list)
			local fish_type = dist_conf.type_list[index or 1]
			local path = table.choice(pathmanager.normalpath)
			local fish_conf = fish_set[fish_type]
			if fish_conf then
				local fish_category = obj.ESFT_NORMAL
				local offset = {
					x = math.random(-dist_conf.offset.x,dist_conf.offset.x),
					y = math.random(-dist_conf.offset.y,dist_conf.offset.y),
				}
				local delay = math.random(0, dist_conf.offset_time)
				if dist_conf.refresh_type == obj.ERT_LINE then
					offset = dist_conf.offset
					delay = dist_conf.offset_time * (nCount - nct)
				elseif dist_conf.refresh_type == obj.ERT_NORMAL then --特殊鱼
					local try_category = nil
					local special_fish_set = {
						[obj.ESFT_KING] = fish_king,
						[obj.ESFT_KINGANDQUAN] = fish_king,
						[obj.ESFT_SANYUAN] = fish_sanyuan,
						[obj.ESFT_SIXI] = fish_sixi,
					}

					local nrand = math.random(10000) % 100
					for category,prob in ipairs(system_set.special.probability) do
						if nrand < prob then
							try_category = category
							break
						end

						nrand = nrand - prob
					end

					local fish_category_conf = special_fish_set[try_category]
					if fish_category_conf then
						if math.random(0, MAX_PROBABILITY) < fish_category_conf.probability then
							fish_category = try_category
						end
					end
				end

				local fish = fish.create(fish_conf,fish_category,{x = xOffset,y = yOffset},0,delay,fish_conf.speed,pid,false)
				fish.refresh_id = obj.gen_id()
				table.insert(self.fish_manager,fish)
				self:send_fish(fish)
			end
		end
	end

	local function switch_next_distribute()
		local dist = self.cur_scene.distribute
		if not dist then
			dist.id = 1
			local dist_time = self.cur_scene.conf.distrub_fish[dist.id].time
			dist.start_time = self.scene_time
			dist.end_time = dist.start_time + dist_time
			self.cur_scene.distribute = dist
			return dist
		end

		dist.id = dist.id + 1
		if dist.id > #self.cur_scenen.conf.distrub_fish then
			dist.id = 1
		end

		dist.start_time = self.scene_time
		dist.end_time = self.scene_time + self.cur_scene.conf.distrub_fish[dist.id].time
		self.cur_scene.distribute = dist
		return dist
	end

	--获取当前场景的鱼群时间
	for id,troop_conf in ipairs(scene_conf.troop_set) do
		if ~self:has_real_player() then
			if self.scene_time >= troop_conf.begin_time and self.scene_time <= troop_conf.end_time then
				self.scene_time = troop_conf.end_time + delta_time
			end
		end

		--当场景时间　是否为刷鱼时间　
		if (self.scene_time >= troop_conf.begin_time) and (self.scene_time <= troop_conf.end_time) then
			if not self.cur_scene.trooped.is then
				if not self.cur_scene.trooped.des then
					send_troop_desctiption(troop_conf)
					self.cur_scene.trooped.des = true
				elseif not self.cur_scene.trooped.send then--如果没有发送过鱼群且 场景时间 大于 刷新时间加描述滚动时间
					self.cur_scene.trooped.send = true
					local troop = pathmanager.troops[id]
					if not troop then
						self.scene_time = self.scene_time + scene_conf.time
						return
					end
					
					distribute_troop(troop_conf)

					self.cur_scene.trooped.is = true
				end
			end
			return
		end
	end

	if self.scene_time > SWITCH_SCENE_END then
		local dist = self.cur_scene.distribute
		if dist.end_time < self.scene_time then
			dist = switch_next_distribute()
		end

		local dist_conf = self.cur_scene.conf.distrub_fish[dist.id]
		if not dist_conf then
			return
		end

		if not self:has_real_player() then
			return
		end

		distribute_fish(dist_conf)
	end
end

function fishing_table:init(room, table_id, chair_count)
	fishing_table.super.init(self,room, table_id, chair_count)
	self.userGameLog = {}
    self.last_check_maintain_time = os.clock()
end

function fishing_table:on_fish_dead(fish_id)
    for i,v in pairs(self.player_list_) do
        if v and v.is_android then
            v:on_fish_dead(fish_id)
        end
    end
end

function fishing_table:check_cancel_ready(player, is_offline)
	log.info("fishing_table:check_cancel_ready")
	fishing_table.super.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	return true
end

function fishing_table:load_lua_cfg( ... )
    log.info("fishing_table:load_lua_cfg")

	return true
end

function fishing_table:is_play( ... )
	log.info("fishing_table:is_play")
	return false
end

function fishing_table:player_sit_down(player, chair_id_)
	log.info(string.format("fishing_table:player_sit_down,[%d]",player.guid))
	fishing_table.super.player_sit_down(self,player,chair_id_)

    local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)

	player.old_money = player:get_money()
	player.start_game_time = get_second_time()

	if self:get_player_count() == 1 then
		log.info("fishing_table:player_sit_down,start game")
	end

	log.info("cpp_table:OnActionUserSitDown")
end

function fishing_table:player_sit_down_finished(player)
	log.info(string.format("cpp_table:OnEventSendGameScene,guid:[%d],chair_id:[%d]",player.guid,player.chair_id))
	self:init_game_log(player)
end


function fishing_table:player_stand_up(player, is_offline)
	log.info("fishing_table:player_stand_up")
	local chair_id = player.chair_id
	local guid = player.guid

    --reduce player count
	local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)

	--记录游戏日志
	self:write_game_log(player)
    --破产统计
    self:save_player_collapse_log(player)

    local ret = fishing_table.super.player_stand_up(self,player,is_offline)

	if self:get_player_count() == 0 then
		log.info("self.cpp_table:OnEventGameConclude(player,is_offline)")
	end

	return ret
end


function fishing_table:ready(player)
	fishing_table.super.ready(self,player)
end

--处理掉线玩家
function fishing_table:player_offline(player)
	fishing_table.super.player_offline(self,player)
end

-- 重新上线
function fishing_table:reconnect(player)
    
end

-- 心跳
function fishing_table:tick()
    if os.clock() - self.last_check_maintain_time > 60 then
        self.last_check_maintain_time = os.clock()
        self:check_single_game_is_maintain()
    end
end

function fishing_table:init_game_log(player)
	local gamelog = {
        guid = player.guid,
        chair_id = player.chair_id,
        nickname = player.nickname,
	    tableID = self.table_id_,
        game_id = def_game_id,
        first_game_type = def_first_game_type,
        second_game_type = def_second_game_type,
	    cell_money =  self.room_.cell_score_,
	    fire_count = 0,
	    fire_cost = 0,
	    fire_types = {},
	    catch_score = 0,
	    catch_fishes = {}
	}
	
	self.userGameLog[player.guid] =  gamelog
end

function fishing_table:add_fire_log(player,multiple,cost)
    local user_catch_log = self.userGameLog[player.guid]
	if not user_catch_log then
		log.error(string.format("fishing updateFireLog log not find guid->[%d]",player.guid))
		return
	end

	user_catch_log.fire_count = user_catch_log.fire_count + 1
	user_catch_log.fire_cost = user_catch_log.fire_cost + cost

    local mulstr = string.format("%d",multiple + 1)

	if not user_catch_log.fire_types[mulstr] then
		user_catch_log.fire_types[mulstr] = 0
	end

	user_catch_log.fire_types[mulstr]  = user_catch_log.fire_types[mulstr]  + 1
end

function fishing_table:subtract_fire_log(player,multiple,cost)
    local user_catch_log = self.userGameLog[player.guid]
	if not user_catch_log then
		log.error(string.format("fishing subtract_fire_log  log not find guid->[%d]",player.guid))
		return
	end

	user_catch_log.fire_count = user_catch_log.fire_count - 1
	user_catch_log.fire_cost = user_catch_log.fire_cost - cost

    local mulstr = string.format("%d",multiple + 1)

	if not user_catch_log.fire_types[mulstr] then
		return
	end

	user_catch_log.fire_types[mulstr]  = user_catch_log.fire_types[mulstr]  - 1
end

function fishing_table:add_hit_log(player,fish_type,connon_score)
    local user_catch_log = self.userGameLog[player.guid]
	if not user_catch_log then
		log.error(string.format("fishing log not find guid->[%d]",player.guid))
		return
	end

    local fish_type_str = string.format("%d",fish_type)

    if not user_catch_log.catch_fishes[fish_type_str] then
        user_catch_log.catch_fishes[fish_type_str] = {0,0,0,0}
    end

    local catch_fish_info = user_catch_log.catch_fishes[fish_type_str]
    
    catch_fish_info[3] = catch_fish_info[3] + 1
    catch_fish_info[4] = catch_fish_info[4] + connon_score
end


function fishing_table:add_catch_log(player,fish_type,multi,money)
    local user_catch_log = self.userGameLog[player.guid]
	if not user_catch_log then
		log.error(string.format("fishing log not find guid->[%d]",player.guid))
		return
	end

    if money >= broadcast_cfg.money and multi >= broadcast_cfg.multiple then 
        local money_str = string.format("%.02f",money / 100)
        broadcast_world_marquee(def_first_game_type,def_second_game_type,0,player.nickname,multi,fish_set[fish_type].name,money_str)
    end

	user_catch_log.catch_score = user_catch_log.catch_score + money

    local fish_type_str = string.format("%d",fish_type)

    if not user_catch_log.catch_fishes[fish_type_str] then
        user_catch_log.catch_fishes[fish_type_str] = {0,0,0,0}
    end

    local catch_fish_info = user_catch_log.catch_fishes[fish_type_str]
    
    catch_fish_info[1] = catch_fish_info[1] + 1
    catch_fish_info[2] = catch_fish_info[2] + money
end


function fishing_table:write_game_log(player)
	if not self.userGameLog[player.guid] then
		log.error(string.format("fishing log has been writed guid->[%d]",player.guid))
		return
	end

-- dump(self.userGameLog[player.guid])

    if self.userGameLog[player.guid].fire_cost == 0 then
--     log.info("write_game_log fire_cost == 0,donnot write~")
        return
    end

	local game_id = self:get_now_game_id()
	local start_game_time = player.start_game_time
	local end_game_time = get_second_time()

	local gameLog = self.userGameLog[player.guid]


	-- 下注流水日志
	self:player_bet_flow_log(player,gameLog.fire_cost)

    local s_log = json.encode(gameLog)
    self:save_game_log(game_id, self.def_game_name, s_log, start_game_time, end_game_time)

    --清除日志
    self.userGameLog[player.guid] = nil

    --保证下次产生的game_id唯一
	self:next_game()
end

--修改玩家金钱并写入日志
function fishing_table:change_player_money(player,change_money)
    log.info(string.format("change_player_money,guid [%d],change money[%d],old money[%d]",player.guid,change_money,player.old_money))
	local old_money = player.old_money 
    local game_id = self:get_now_game_id()

    if self.userGameLog[player.guid].fire_cost == 0 then return end

    self.userGameLog[player.guid].change_money = change_money

    if change_money < 0 then
        player:cost_money(
		    {{money_type = ITEM_PRICE_TYPE_GOLD, money = -change_money}}, 
		    LOG_MONEY_OPT_TYPE_BUYU,true
	    )
    else
        player:add_money(
            {{money_type = ITEM_PRICE_TYPE_GOLD, money = change_money}}, 
		    LOG_MONEY_OPT_TYPE_BUYU,true
	    )
    end
	
    local s_type =  change_money > 0 and 2 or 1
    log.info(string.format("player_money_log,guid:[%d],old money[%d], change money[%d]",player.guid,old_money,change_money))
	self:player_money_log(player,s_type,old_money,0,change_money,game_id)
end