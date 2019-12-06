
local pb = require "pb_files"

local base_table = require "game.lobby.base_table"
local base_prize_pool = require "game.lobby.base_prize_pool"
local base_bonus = require "game.lobby.base_bonus"
local json = require "cjson"
local enum = require "pb_enums"
local base_players = require "game.lobby.base_players"
local base_private_table = require "game.lobby.base_private_table"
local onlineguid = require "netguidopt"
local channel = require "channel"
local serviceconf = require "serviceconf"
local nameservice = require "nameservice"

require "game.net_func"
require "table_func"
require "game.timer_manager"

require "msgopt"
local log = require "log"
local redisopt = require "redisopt"

local reddb = redisopt.default

local table_expire_seconds = 60 * 60 * 5

require "timer"
local add_timer = add_timer

-- 房间
local base_room = {}

-- 奖池
-- global_prize_pool = global_prize_pool or base_prize_pool:new()


local function check_conf(conf)
	assert(conf.table_count)
	assert(conf.player_limit)
	assert(conf.money_limit)
	assert(conf.tax)
	assert(conf.tax_show)
	assert(conf.tax_open)
	assert(conf.cell_money)
	assert(conf.room_cfg)
end

local function find_default_lobby()
	local services = channel.list()
    for sid,_ in pairs(services) do
        local id = sid:match("service%.(%d+)")
        if id then
            id = tonumber(id)
            local conf = serviceconf[id]
            if conf and (conf.name == nameservice.TNGAME or conf.type == nameservice.TIDGAME) then
                local gameconf = conf.conf
                if gameconf and gameconf.first_game_type and gameconf.first_game_type == 1 then
                    return tonumber(sid:match("service%.(%d+)"))
                end
            end
        end
    end
end

function base_room:new()
	local o = {}
	setmetatable(o,{__index = base_room,})
	return o
end

-- 初始化房间
function base_room:init(conf,chair_count,ready_mode)
	check_conf(conf)

	self.id = 1
	self.conf = conf
	self.chair_count = chair_count

	local table_count = conf.table_count

	self.tax_show = conf.tax_show -- 是否显示税收信息
	self.tax_open = conf.tax_open -- 是否开启税收
	self.tax = conf.tax * 0.01
	self.ready_mode = ready_mode -- 准备模式
	self.room_limit = conf.money_limit or 0 -- 房间分限制
	self.cell_score = conf.cell_money or 0 -- 底注
	self.player_count_limit = conf.table_count * chair_count -- 房间人数总限制
	self.tables = {}
	self.room_cfg = conf.room_cfg
	self.game_switch_is_open = conf.game_switch_is_open

	log.info("base_room:init:self.game_switch_is_open = [%s]~~~~~~~~~~~~~~~~~:",self.game_switch_is_open)

	for i = 1, table_count do
		local t = self:create_table()
		t:init(self, i, chair_count)
		if self.room_cfg ~= nil then
			t:load_lua_cfg()
		end
		self.tables[i] = t
	end

	self.players = {}
	self.cur_player_count_ = 0 -- 当前玩家人数

	reddb:del(string.format("game:%s.%d.%d",def_game_name,def_first_game_type,def_second_game_type))
	reddb:del(string.format("game:%s.%d.%d:player_num",def_game_name,def_first_game_type,def_second_game_type))
	reddb:del(string.format("game:%s.%d.%d:player_count",def_game_name,def_first_game_type,def_second_game_type))

	self.blacklist_player = setmetatable({},{
		__index = function(t,guid)
			local is = reddb:hget("player:black",guid)
			if not is then
				return false
			end

			t[guid] = (is and is == "true") and true or false
			return true
		end,
	})

	timer_manager:new_timer(2,function()
		base_bonus.load_activity()
	end)

	timer_manager:new_timer(1,function()
		base_bonus.tick()
	end,"global_bonus_update_timer",true)
end

-- gm重新更新配置, room_lua_cfg
function base_room:gm_update_cfg(tb, room_lua_cfg)
	local old_count = #self.room_list_
	for i,v in ipairs(tb) do
		if i <= old_count then
			print("change----gm_update_cfg", v.table_count, self.chair_count, v.money_limit, v.cell_money,v.game_switch_is_open)
			self.room_list_[i]:gm_update_cfg(self,v.table_count, self.chair_count, v.money_limit, v.cell_money, v, room_lua_cfg)
		else
			local r = self:create_room()
			print("Init----gm_update_cfg", v.table_count, self.chair_count, v.money_limit, v.cell_money)
			r:init(self, v.table_count, self.chair_count, self.ready_mode, v.money_limit, v.cell_money, v, room_lua_cfg)
			self.room_list_[i] = r
		end
	end
end

-- 创建桌子
function base_room:create_table()
	return base_table:new()
end

-- 通过玩家找桌子
function base_room:find_table_by_player(player)
	return self.tables[player.table_id]
end

-- 遍历房间所有玩家
function base_room:foreach_by_player(func)
	for _, p in pairs(self.players) do
		func(p)
	end
end


function base_room:get_room_cell_money()
	return self.cell_score
end

function base_room:get_room_tax()
	-- body
	return self.tax
end
-- 得到准备模式
function base_room:get_ready_mode()
	return self.ready_mode
end

-- 得到房间分限制
function base_room:get_room_limit()
	return self.room_limit
end

-- 找到房间中玩家
function base_room:find_player_list()
	return self.players
end

-- 得到玩家
function base_room:get_player(chair_id)
	return self.players[chair_id]
end

-- 得到桌子列表
function base_room:get_table_list()
	return self.tables
end

function base_room:find_table(table_id)
	if not table_id then
		return nil
	end
	return self.tables[table_id]
end

-- 广播房间中所有人消息
function base_room:broadcast2client_by_player(msg_name, pb)
	for _,p in pairs(self.players) do
		send2client_pb(p,msg_name,pb)
	end
end

function base_room:get_table_players_status( player )
	print("--------get_table_player_status-------------")
end

-- 进入房间并坐下
function base_room:enter_room_and_sit_down(player)
	log.info("player guid is : %d",player.guid)
	if player.disable == 1 then
		log.info("get_table_players_status player is Freeaz forced_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end

	if player.table_id or player.chair_id then
		log.info("player tableid is [%d] chairid is [%d] guid[%d]",player.table_id,player.chair_id,player.guid)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	log.info("base_room:enter_room_and_sit_down: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d] get_db_status[%d]",def_game_name,def_game_id,self.game_switch_is_open,get_db_status())
	log.info("player guid[%d], player vip = [%d]",player.guid, player.vip)
	if self.game_switch_is_open == 1 then --游戏进入维护阶段
		if player and player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = enum.GAME_SERVER_RESULT_MAINTAIN,
					})
			player:forced_exit()
			log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
			return 14
		end
	end

	local ret = enum.GAME_SERVER_RESULT_NOT_FIND_ROOM
	if not player:check_room_limit(self:get_room_limit()) and self.cur_player_count_ < self.player_count_limit then
		ret = enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		local tb,k,j = self:get_suitable_table(self,player,false)
		if tb then
			self:player_enter_room(player)
			-- 通知消息
			local notify = {
				table_id = j,
				pb_visual_info = {
					chair_id = k,
					guid = player.guid,
					account = player.account,
					nickname = player.nickname,
					level = player:get_level(),
					money = player:get_money(),
					header_icon = player:get_header_icon(),
					ip_area = player.ip_area,
				}
			}
			print("ip_area--------------------A",  player.ip_area)
			print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
			tb:foreach(function (p)
				p:on_notify_sit_down(notify)
			end)
			tb:player_sit_down(player, k)
			return enum.GAME_SERVER_RESULT_SUCCESS, j, k, tb
		end
	end

	return ret
end

-- 站起并离开房间
function base_room:stand_up_and_exit_room(player,reason)
	if not player.table_id then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	
	if not player.chair_id then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local tb = self.tables[player.table_id]
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if tb:is_play(player) then
		return enum.GAME_SERVER_RESULT_IN_GAME
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return enum.GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end

	local tableid = player.table_id
	local chairid = player.chair_id
	tb:player_stand_up(player, reason)
	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)
	tb:check_start(true)

	local roomid = player.room_id
	self:player_exit_room(player)
	return enum.GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
end

function base_room:check_private_limit(player,chair_count,conf)
	local pay_option = conf.pay.option
	local money_type = conf.pay.money_type
	
	if pay_option == enum.PAY_OPTION_AA then
		local player_limit = math.ceil(self.room_limit / chair_count)
		
		return not player:check_room_limit(player_limit,money_type)
	end

	if pay_option == enum.PAY_OPTION_BOSS then
		return not player:check_room_limit(self.room_limit,money_type)
	end

	return false
end

function base_room:save_private_table(owner,table_id,chair_id)
	
end

function base_room:request_dismiss_private_table(requester)
	local tb = self:find_table_by_player(requester)
	if not tb then
		return enum.ERROR_PLAYER_NOT_IN_ROOM
	end

	return tb:request_dismiss(requester)
end

function base_room:commit_dismiss_private_table(player,agree)
	local tb = self:find_table_by_player(player)
	if not tb then
		return enum.ERROR_PLAYER_NOT_IN_ROOM
	end

	return tb:commit_dismiss(player,agree)
end

function base_room:dismiss_private_table(global_table_id)
	local private_table_conf = base_private_table[global_table_id]
	local table_id = private_table_conf.real_table_id
	local tb = self.tables[table_id]
	if not tb then
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
	end

	tb:dismiss()
	reddb:hdel("table:info:"..tostring(global_table_id))
	reddb:srem("player:table:"..tostring(private_table_conf.owner),global_table_id)
end

-- 创建私人房间
function base_room:create_private_table(player,chair_count,round, conf)
	if player.table_id or player.chair_id then
		log.info("player table_id is [%d] chair_id is [%d] guid[%d]",player.table_id,player.chair_id,player.guid)
		return enum.GAME_SERVER_RESULT_IN_GAME
	end

	if self:check_private_limit(player,chair_count,conf) and self.cur_player_count_ < self.player_count_limit 
	then
		local tb,chair_id,table_id = self:get_private_table(player, chair_count,round,conf)
		if not tb then
			return enum.GAME_SERVER_RESULT_NOT_FIND_ROOM
		end

		local global_tid = math.random(100000,999999)
		for _ = 1,1000 do
			if not base_private_table[global_tid] then break end
			global_tid = math.random(100000,999999)
		end

		reddb:hmset("table:info:"..tostring(global_tid),{
			room_id = def_game_id,
			table_id = global_tid,
			real_table_id = table_id,
			owner = player.guid,
			rule = json.encode(conf),
			game_type = def_first_game_type,
		})
		reddb:expire("table:info:"..tostring(global_tid),table_expire_seconds)
		reddb:sadd("player:table:"..tostring(player.guid),global_tid)
		reddb:expire("player:table:"..tostring(player.guid),table_expire_seconds)

		tb.private_id = global_tid

		self:player_enter_room(player)
		
		tb:player_sit_down(player, chair_id)

		tb:foreach(function(p)
			p:on_notify_sit_down({
				room_id = def_game_id,
				table_id = tb.table_id_,
				pb_visual_info = player,
			})
		end)

		reddb:hset("player:online:guid:"..tostring(player.guid),"global_table",global_tid)

		return enum.GAME_SERVER_RESULT_SUCCESS,global_tid,tb
	end

	return enum.GAME_SERVER_RESULT_NOT_FIND_ROOM
end

function base_room:reconnect(player,table_id,chair_id)
	local tb = self.tables[table_id]
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	tb:player_sit_down(player, chair_id)

	local notify = {
		room_id = def_game_id,
		table_id = player.table_id,
		pb_visual_info = player,
		is_online = true,
	}

	tb:foreach_except(chair_id,function (p)
		p:on_notify_sit_down(notify)
	end)

	return tb:reconnect(player)
end

-- 加入私人房间
function base_room:join_private_table(player,private_table_conf,chair_count)
	if player.table_id or player.chair_id then
		log.warning("player tableid is [%d] chairid is [%d]",player.table_id,player.chair_id)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	local table_id = private_table_conf.real_table_id
	local tb = self.tables[table_id]
	if not tb then
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
	end

	if self:check_private_limit(player,chair_count,private_table_conf.rule)
		and self.cur_player_count_ < self.player_count_limit then
		local chair_id = tb:get_free_chair_id()
		if not chair_id then
			return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
		end

		self:player_enter_room(player)

		tb:player_sit_down(player, chair_id)

		local notify = {
			room_id = def_game_id,
			table_id = private_table_conf.table_id,
			pb_visual_info = player,
		}

		tb:foreach_except(chair_id,function (p)
			p:on_notify_sit_down(notify)
		end)

		reddb:hset("player:online:guid:"..tostring(player.guid),"global_table",private_table_conf.table_id)

		return enum.GAME_SERVER_RESULT_SUCCESS,tb
	else
		return enum.GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_ALL
	end
end

-- 切换座位
function base_room:change_chair(player)
	if player.disable == 1 then
		print("stand_up_and_exit_room player is Freeaz forced_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end

	if not player.table_id then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end


	local tb = self.tables[player.table_id]
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return enum.GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end
	
	local tableid = player.table_id
	local chairid = player.chair_id
	local targettb = nil
	local targetid = nil

	for i,v in ipairs(self.tables) do
		if i > tableid then
			for k,chair in ipairs(v:get_player_list()) do
				if chair == false then
					targettb = v
					targetid = k
				end
			end
		end
	end

	if targetid == nil then
		for i,v in ipairs(self.tables) do
			if i < tableid then
				for k,chair in ipairs(v:get_player_list()) do
					if chair == false then
						targettb = v
						targetid = k
					end
				end
			end
		end
	end

	if targetid == nil then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	-- 旧桌子站起
	tb:player_stand_up(player, enum.STANDUP_REASON_NORMAL)

	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}

	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)

	tb:check_start(true)

	-- 通知消息
	local notify = {
		table_id = targettb.table_id_,
		pb_visual_info = {
			chair_id = targetid,
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
			level = player:get_level(),
			money = player:get_money(),
			header_icon = player:get_header_icon(),
			ip_area = player.ip_area,
		}
	}
	print("ip_area--------------------A",  player.ip_area)
	print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
	targettb:foreach(function (p)
		p:on_notify_sit_down(notify)
	end)

	targettb:player_sit_down(player, targetid)

	return enum.GAME_SERVER_RESULT_SUCCESS, targettb.table_id_, targetid, targettb
end

-- 快速进入房间
function base_room:auto_enter_room(player)
	if player.disable == 1 then
		print("auto_enter_room player is Freeaz forced_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end

	log.info("base_room:auto_enter_room: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d] get_db_status[%d]",def_game_name,def_game_id,self.game_switch_is_open,get_db_status())
	if  self.game_switch_is_open == 1 or get_db_status() == 0 then --游戏进入维护阶段
		if player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = enum.GAME_SERVER_RESULT_MAINTAIN,
					})
			log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
			return 14
		end
	end
	
	if not player:check_room_limit(self:get_room_limit()) and self.cur_player_count_ < self.player_count_limit then
		-- 通知消息
		local notify = {
			room_id = self.id,
			guid = player.guid,
		}
		if player.is_player then
			self:foreach_by_player(function (p)
				p:on_notify_enter_room(notify)
			end)
		end

		self:player_enter_room(player)
		return enum.GAME_SERVER_RESULT_SUCCESS
	end

	return enum.GAME_SERVER_RESULT_NOT_FIND_ROOM
end

-- 进入房间
function base_room:enter_room(player)
	if player.disable == 1 then
		print("enter_room player is Freeaz forced_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end

	log.info(string.format("base_room:enter_room: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%s]",
		def_game_name,def_game_id,self.game_switch_is_open))
	if  self.game_switch_is_open == 1 then --游戏进入维护阶段
		if player.vip ~= 100 then
			send2client_pb(player, "SC_GameMaintain", {
					result = enum.GAME_SERVER_RESULT_MAINTAIN,
					})
			log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
			return 14
		end
	end

	if player:check_room_limit(self:get_room_limit()) then
		log.warning(string.format("guid[%d] check money limit fail,limit[%d],self[%s]",
			player.guid, self:get_room_limit(), player.money))
		return GAME_SERVER_RESULT_ROOM_LIMIT
	end

	-- 通知消息
	local notify = {
		room_id = self.id,
		guid = player.guid,
	}
	if player.is_player then
		self:foreach_by_player(function (p)
			if p then
				p:on_notify_enter_room(notify)
			end
		end)
	end

	self:player_enter_room(player)

	return enum.GAME_SERVER_RESULT_SUCCESS
end

function base_room:cs_trusteeship(player)
	local tb = self:find_table(player.table_id)
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	tb:set_trusteeship(player,true)
end

-- 离开房间
function base_room:exit_room(player,is_logout)
	log.info("base_room:exit_room %s,%s",player.guid,is_logout)
	
	self:player_exit_room(player,is_logout)
	
	local notify = {
			room_id = self.id,
			guid = player.guid,
		}

	return enum.GAME_SERVER_RESULT_SUCCESS, self.id
end

-- 玩家掉线
function base_room:player_offline(player)
	local tb = self:find_table(player.table_id)
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return enum.GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end

	local tableid, chairid = player.table_id, player.chair_id

	if tb:player_stand_up(player, enum.STANDUP_REASON_OFFLINE) then
		local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
		tb:foreach(function (p)
			p:on_notify_stand_up(notify)
		end)

		tb:check_start(true)

		return enum.GAME_SERVER_RESULT_SUCCESS, false
	end

	local notify = {
		table_id = tableid,
		chair_id = chairid,
		guid = player.guid,
		is_offline = true,
	}
	tb:foreach_except(chairid, function (p)
		p:on_notify_stand_up(notify)
	end)

	return enum.GAME_SERVER_RESULT_SUCCESS, true
end

function base_room:is_play(player)
	print("=========base_room:is_play")
	if player.room_id and player.table_id and player.chair_id then
		local tb = self:find_table(player.table_id)
		if not tb then
			print("=========base_room:is_play not tb")
			return false
		end
		return tb:is_play(player)
	end
	print("=========base_room:is_play false")
	return false
end

-- 玩家上线
function base_room:player_online(player)
	if player.room_id and player.table_id and player.chair_id then
		player:on_enter_room(player.room_id, enum.GAME_SERVER_RESULT_SUCCESS)

		local tb = self:find_table(player.table_id)
		if not tb then
			return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		end
		
		local chair = tb:get_player(player.chair_id)
		if not chair then
			return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
		end

		if chair.guid ~= player.guid then
			player.table_id = nil
			player.chair_id = nil
			return enum.GAME_SERVER_RESULT_OHTER_ON_CHAIR
		end

		player.is_offline = nil

		-- 通知消息
		local notify = {
			table_id = player.table_id,
			pb_visual_info = {
				chair_id = player.chair_id,
				guid = player.guid,
				account = player.account,
				nickname = player.nickname,
				level = player:get_level(),
				money = player:get_money(),
				header_icon = player:get_header_icon(),				
				ip_area = player.ip_area,
			},
			is_onfline = true,
		}

		print("ip_area--------------------A",  player.ip_area)
		print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
		tb:foreach_except(player.chair_id, function (p)
			p:on_notify_sit_down(notify)
		end)

		-- 重连
		tb:reconnect(player)

		return enum.GAME_SERVER_RESULT_SUCCESS
	end
end

-- 退出服务器
function base_room:exit_server(player,is_logout)
	log.info("base_room:exit_server guid[%d]",player.guid)
	if player.table_id and player.chair_id then
		local result_, is_offline_ = self:player_offline(player)

		log.info("guid[%d] player_offline return [%d] is_offline[%s]",player.guid,result_,is_offline_)
		if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
			if is_offline_ then
				return true
			end
			self:exit_room(player,is_logout)
		end
	end
	return false
end

-- 快速坐下
function base_room:auto_sit_down(player)
	if player.disable == 1 then
		print("auto_sit_down player is Freeaz forced_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return enum.GAME_SERVER_RESULT_OUT_ROOM
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return enum.GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	for i,tb in ipairs(self.tables) do
		for j,chair in ipairs(tb:get_player_list()) do
			if chair == false then
				return self:sit_down(player, i, j)
			end
		end
	end

	return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
end

-- 坐下
function base_room:sit_down(player, table_id_, chair_id_)
	if player.disable == 1 then
		print("sit_down player is Freeaz forced_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	
	if player.table_id or player.chair_id then
		log.info("base_room:sit_down error guid [%d] enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR",player.guid)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end
	
	local tb = self:find_table(table_id_)
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	
	local chair = tb:get_player(chair_id_)
	if chair then
		return enum.GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER
	elseif chair == nil then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end
	
	-- 通知消息
	local notify = {
		table_id = table_id_,
		pb_visual_info = {
			chair_id = chair_id_,
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
			level = player:get_level(),
			money = player:get_money(),
			header_icon = player:get_header_icon(),			
			ip_area = player.ip_area,
		},
	}

	print("ip_area--------------------A",  player.ip_area)
	print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
	tb:foreach(function (p)
		p:on_notify_sit_down(notify)
	end)

	tb:player_sit_down(player, chair_id_)

	return enum.GAME_SERVER_RESULT_SUCCESS, table_id_, chair_id_
end


-- 站起
function base_room:stand_up_new(player)
	log.info("base_room:stand_up_new player guid[%d]",player.guid)
	if not player.room_id then
		return enum.GAME_SERVER_RESULT_OUT_ROOM
	end

	if not player.table_id then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local room = self:find_room(player.room_id)
	if not room then
		return enum.GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return enum.GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end
	
	local tableid = player.table_id
	local chairid = player.chair_id
	local ret =  tb:player_stand_up(player, enum.STANDUP_REASON_NORMAL)
	if ret == false then
		log.warning("player guid[%d] stand_up failed, return enum.GAME_SERVER_RESULT_IN_GAME",player.guid)
		return enum.GAME_SERVER_RESULT_IN_GAME
	end

	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)

	tb:check_start(true)

	return enum.GAME_SERVER_RESULT_SUCCESS, tableid, chairid
end


-- 站起
function base_room:stand_up(player,reason)
	log.info("base_room:stand_up,guid:%s chair_id:%s reasion:%s",player.guid,player.chair_id,reason)
	if not player.table_id then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local tb = self:find_table(player.table_id)
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return enum.GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end
	
	local tableid = player.table_id
	local chairid = player.chair_id
	tb:player_stand_up(player, reason)

	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)

	tb:check_start(true)

	return enum.GAME_SERVER_RESULT_SUCCESS, tableid, chairid
end

-- 找一个被动机器人位置
function base_room:find_android_pos(room_id)
	local room = self:find_room(room_id)
	if not room then
		return nil
	end

	local isplayer = false
	local tableid, chairid
	for i,tb in ipairs(self.tables) do
		for j,chair in ipairs(tb:get_player_list()) do
			if chair == true then
				if isplayer then
					return i, j
				else
					isplayer = true
					tableid = i
					chairid = j
				end
			elseif chair.is_player then
				if tableid and chairid then
					return tableid, chairid
				end
				isplayer = true
			end
		end
	end

	return nil
end

-- 心跳
function base_room:tick()
	for _,tb in ipairs(self.tables) do
		tb:tick()
	end
end

function base_room:get_private_table(player,chair_count,round,conf)
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(self.tables) do
		local player_count = tb:get_player_count()
		if 0 == player_count then
			suitable_table = tb
			chair_id = player_count + 1
			table_id = j
			--初始化私房
			tb:private_init({
				round = round,
				chair_count = chair_count,
				money_type = conf.pay.money_type,
				pay_option = conf.pay.option,
				owner = player,
				owner_guid = player.guid,
				owner_chair_id = chair_id,
				rule = conf.play,
				conf = conf,
			})
			return suitable_table,chair_id,table_id
		end
	end
	return suitable_table,chair_id,table_id
end

function base_room:get_player_num()
	return self.cur_player_count_
end

-- 玩家进入房间
function base_room:player_enter_room(player)
	player.in_game = true
	log.info("set player[%s] in_game true this room have player count is [%s] [%s]" ,
		player.guid , self.cur_player_count_ , self:get_player_num())
	self.players[player.guid] = player
	self.cur_player_count_ = self.cur_player_count_ + 1

	reddb:incr(string.format("game:%s.%s.%s",def_game_name,def_first_game_type,def_second_game_type))
	reddb:incr(string.format("game:%s.%s.%s.%s:player_num",def_game_name,def_game_id,def_first_game_type,def_second_game_type))

	log.info("base_room:player_enter_room, guid %s, room_id %s",player.guid,def_game_id)

	local online_key = string.format("player:online:guid:%d",player.guid)
	reddb:hmset(online_key,{
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		server = def_game_id,
	})
end

-- 玩家退出房间
function base_room:player_exit_room(player,is_logout)
	log.info(string.format("GameInOutLog,base_room:player_exit_room, guid %s, room_id %s",
		player.guid,def_game_id))
	
	log.info("base_room:player_exit_room")	
	self.players[player.guid] = false
	self.cur_player_count_ = self.cur_player_count_ - 1

	local str = string.format("game:%s.%d.%d",def_game_name,def_first_game_type,def_second_game_type)
	reddb:decr(str)

	str = string.format("game:%s.%s.%s.%s:player_num",def_game_name,def_game_id,def_first_game_type,def_second_game_type)
	reddb:decr(str)

	str = string.format("game:%s.%s.%s.%s:player_count",def_game_name,def_game_id,def_first_game_type,def_second_game_type)
	reddb:decr(str)

	if not is_logout then
		log.info("player_exit_room set guid[%d] onlineinfo",player.guid)
		local online_key = string.format("player:online:guid:%d",player.guid)
		reddb:hdel(online_key,"first_game_type")
		reddb:hdel(online_key,"second_game_type")
	else
		log.info("player_exit_room not set guid[%d] onlineinfo",player.guid)
	end

	reddb:hdel("player:online:guid:"..tostring(player.guid),"server")
	
	player:on_exit_room(enum.GAME_SERVER_RESULT_SUCCESS)
	onlineguid[player.guid] = nil
	onlineguid.control(player.guid,"goserver",find_default_lobby())
end


function base_room:get_suitable_table(player,bool_change_table)
	local player_count = -1
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(self.tables) do
		if tb.private_room and 0 == tb:get_player_count() then
			tb.private_room = false
		end
		if (not tb.private_room) and (suitable_table == nil or (suitable_table ~= nil and suitable_table:get_player_count() < tb:get_player_count())) then
			for k,chair in ipairs(tb:get_player_list()) do
				if (bool_change_table and player.table_id ~= tb.table_id_) or (not bool_change_table) then
					if chair == false and tb:can_enter(player) then
						log.info("get_suitable_table step 3 roomid[%d] tableid[%d] guid[%d]",tb.table_id_,player.guid)
						local tmp_player_count = tb:get_player_count()
						if player_count < tmp_player_count then
							player_count = tmp_player_count
							suitable_table = tb
							chair_id = k
							table_id = j
							break
						end
					end
				end
			end
		end
		
		if tb:get_player_count() > 0 then
			--log.warning("table pcount %d, table_id is %d",tb:get_player_count(),j)
		end
	end	
	
	return suitable_table,chair_id,table_id
end

function base_room:change_table_new(player)
 	if not player then
 		log.warning("player is null.")
 		return
 	end

 	log.info("player guid[%d] change_table_new start..........",player.guid)
 	if player.disable == 1 then
		print("change_table_new player is Freeaz forced_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	local tb = self:find_table_by_player(player)
	if tb then		
		if tb:is_play(player) then
			log.warning("player guid[%d] is playing",player.guid)
			return
		end

		local tb,k,j = self:get_suitable_table(self,player,true)
		if tb then
			--离开当前桌子
			--local result_, table_id_, chair_id_  = self:stand_up(player)
			local result_, table_id_, chair_id_  = self:stand_up_new(player)
			if result_ ~= enum.GAME_SERVER_RESULT_SUCCESS then
				log.warning("player guid[%d] stand_up_new failed.",player.guid)
				return
			end
			player:on_stand_up(table_id_, chair_id_, result_)
			-- 通知消息
			local notify = {
				table_id = j,
				pb_visual_info = {
				chair_id = k,
				guid = player.guid,
				account = player.account,
				nickname = player.nickname,
				level = player:get_level(),
				money = player:get_money(),
				header_icon = player:get_header_icon(),
				ip_area = player.ip_area,
				}
			}
				
			tb:foreach(function (p)
				p:on_notify_sit_down(notify)
			end)
			--在新桌子坐下
			tb:player_sit_down(player,k)
			player:change_table(def_game_id, j, k, enum.GAME_SERVER_RESULT_SUCCESS, tb)
			self:get_table_players_status(player)
			return
		else
			log.warning("not in room")
		end
	else
		log.warning("no find tb")
	end
 end 

function base_room:change_table(player)
	print("======================base_room:change_table")
	if player.disable == 1 then
		print("change_table player is Freeaz forced_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	local tb = self:find_table_by_player(player)
	if tb then
		local tb,k,j = self:get_suitable_table(self,player,true)
		if tb then
			--离开当前桌子
			local result_, table_id_, chair_id_  = self:stand_up(player)
			player:on_stand_up(table_id_, chair_id_, result_)
			-- 通知消息
			local notify = {
				table_id = j,
				pb_visual_info = {
				chair_id = k,
				guid = player.guid,
				account = player.account,
				nickname = player.nickname,
				level = player:get_level(),
				money = player:get_money(),
				header_icon = player:get_header_icon(),
				ip_area = player.ip_area,
				}
			}
				
			print("ip_area--------------------A",  player.ip_area)
			print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
			tb:foreach(function (p)
				p:on_notify_sit_down(notify)
			end)
			--在新桌子坐下
			tb:player_sit_down(player,k)
			player:change_table(player.room_id, j, k, enum.GAME_SERVER_RESULT_SUCCESS, tb)
			self:get_table_players_status(player)
			return
		else
			print("not in room")
		end
	else
		print("no find tb")
	end
end


function base_room:change_tax(tax, tax_show, tax_open)
	print("======================base_room:change_tax")
	tax = tax * 0.01
	for i , v in pairs (self.room_list_) do		
		print (tax, tax_show, tax_open)
		v.tax_show = tax_show -- 是否显示税收信息
		v.tax_open = tax_open -- 是否开启税收
		v.tax = tax
	end
end

--检查玩家是否是黑名单列表玩家，若是则返回true，否则返回false
function base_room:check_player_is_in_blacklist( player_guid )
	if player_guid < 0 then
		return false
	end

	return self.blacklist_player[player_guid]
end

return base_room