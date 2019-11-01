local base_table = require "game.lobby.base_table"
local base_player = require "game.lobby.base_player"
local base_room = require "game.lobby.base_room"
require "functions"
local log = require "log"

require "game.jc_fishing.config"

local redisopt = require "redisopt"

local reddb = redisopt.default

local pb = require "pb_files"

local LOG_MONEY_OPT_TYPE_BUYU = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_BUYU")
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")


local fishing_table = class("fishing_table",base_table)

function fishing_table:ctor( ... )
	
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
    -- log.info("fishing_table:load_lua_cfg")

	return true
end

function fishing_table:is_play( ... )
	log.info("fishing_table:is_play")
	return false
end

function fishing_table:player_sit_down(player, chair_id_)
	log.info("fishing_table:player_sit_down,[%d]",player.guid)
	fishing_table.super.player_sit_down(self,player,chair_id_)

    local str = string.format("incr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	reddb:incr(string.format("%s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type))

	player.old_money = player:get_money()
	player.start_game_time = get_second_time()

	if self:get_player_count() == 1 then
		log.info("fishing_table:player_sit_down,start game")
		self.cpp_table:OnEventGameStart()
	end

	log.info("cpp_table:OnActionUserSitDown")
	self.cpp_table:OnActionUserSitDown(chair_id_,player)
end

function fishing_table:player_sit_down_finished(player)
	log.info("cpp_table:OnEventSendGameScene,guid:[%d],chair_id:[%d]",player.guid,player.chair_id)
	self.cpp_table:OnEventSendGameScene(player.guid,player.chair_id,100,false)
	self:init_game_log(player)
end


function fishing_table:player_stand_up(player, is_offline)
	log.info("fishing_table:player_stand_up")
	local chair_id = player.chair_id
	local guid = player.guid
	self.cpp_table:OnActionUserStandUp(guid,chair_id,is_offline)

    --reduce player count
	local str = string.format("decr %s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	reddb:decr(string.format("%s_%d_%d_players",def_game_name,def_first_game_type,def_second_game_type))

	--记录游戏日志
	self:write_game_log(player)
    --破产统计
    self:save_player_collapse_log(player)

    local ret = fishing_table.super.player_stand_up(self,player,is_offline)

	if self:get_player_count() == 0 then
		log.info("self.cpp_table:OnEventGameConclude(player,is_offline)")
		self.cpp_table:OnEventGameConclude(guid,chair_id,0)
	end

	return ret
end


function fishing_table:ready(player)
	fishing_table.super.ready(self,player)
	self.cpp_table:OnReady(player.chair_id)	
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
		log.error("fishing updateFireLog log not find guid->[%d]",player.guid)
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
		log.error("fishing subtract_fire_log  log not find guid->[%d]",player.guid)
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
		log.error("fishing log not find guid->[%d]",player.guid)
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
		log.error("fishing log not find guid->[%d]",player.guid)
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
		log.error("fishing log has been writed guid->[%d]",player.guid)
		return
	end

-- dump(self.userGameLog[player.guid])

    if self.userGameLog[player.guid].fire_cost == 0 then
--     log.info("write_game_log fire_cost == 0,donnot write!!")
        return
    end

	local game_id = self:get_now_game_id()
	local start_game_time = player.start_game_time
	local end_game_time = get_second_time()

	local gameLog = self.userGameLog[player.guid]

	-- 下注流水
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
    log.info("change_player_money,guid [%d],change money[%d],old money[%d]",player.guid,change_money,player.old_money)
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
    log.info("player_money_log,guid:[%d],old money[%d], change money[%d]",player.guid,old_money,change_money)
	self:player_money_log(player,s_type,old_money,0,change_money,game_id)
end

return fishing_table