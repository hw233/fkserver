
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
local queue = require "skynet.queue"
local common = require "game.common"


require "game.net_func"
local timer_manager = require "game.timer_manager"

require "msgopt"
local log = require "log"
local redisopt = require "redisopt"

local reddb = redisopt.default

local table_expire_seconds = 60 * 60 * 5

local timer = require "timer"

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

	self.lock = queue()
end

function base_room:lockcall(fn,...)
	return self.lock(fn,...)
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
	if not player:check_money_limit(self:get_room_limit()) and self.cur_player_count_ < self.player_count_limit then
		ret = enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		local tb,k,j = self:get_suitable_table(self,player,false)
		if tb then
			self:player_enter_room(player)
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

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return enum.GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end

	local tableid = player.table_id
	local chairid = player.chair_id
	local succ = tb:lockcall(function() return tb:player_stand_up(player, reason) end)
	if not succ then
		return enum.GAME_SERVER_RESULT_IN_GAME
	end

	local roomid = player.room_id
	self:player_exit_room(player)
	player:on_exit_room(enum.GAME_SERVER_RESULT_SUCCESS)
	return enum.GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
end

function base_room:check_entry_table_limit(player,rule,club)
	if not rule or not rule.union or not club then
		return true
	end

	local money_id = club_money[club.id]

	return player:get_money(money_id) >= rule.union.entry_score
end

function base_room:save_private_table(owner,table_id,chair_id)
	
end

function base_room:force_dismiss_table(table_id,reason)
	local tb = self:find_table(table_id)
	if not tb then
		return enum.ERROR_TABLE_NOT_EXISTS
	end

	tb:force_dismiss(enum.STANDUP_REASON_ADMIN_DISMISS_FORCE)
	
	return enum.ERROR_NONE
end

function base_room:request_dismiss_private_table(requester)
	local tb = self:find_table_by_player(requester)
	if not tb then
		return enum.ERROR_PLAYER_NOT_IN_GAME
	end

	return tb:lockcall(function() return tb:request_dismiss(requester) end)
end

function base_room:commit_dismiss_private_table(player,agree)
	local tb = self:find_table_by_player(player)
	if not tb then
		return enum.ERROR_PLAYER_NOT_IN_GAME
	end

	return tb:lockcall(function() return tb:commit_dismiss(player,agree) end)
end

function base_room:find_empty_table()
	for j,tb in ipairs(self.tables) do
		local player_count = tb:get_player_count()
		if 0 == player_count then
			return tb,j
		end
	end
	return nil,nil
end

-- 创建私人房间
function base_room:create_private_table(player,chair_count,round, rule,club)
	if player.table_id or player.chair_id then
		log.info("player already in table, table_id is [%d] chair_id is [%d] guid[%d]",player.table_id,player.chair_id,player.guid)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	if self.cur_player_count_ >= self.player_count_limit then
		log.warning("room player is full,%s,%d",def_game_name,def_game_id)
		return enum.GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb,table_id = self:find_empty_table()
	if not tb then
		log.info("create private table:%s,%d no found table",def_game_name,def_game_id,player.guid)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local global_tid = math.random(100000,999999)
	for _ = 1,1000 do
		if not base_private_table[global_tid] then break end
		global_tid = math.random(100000,999999)
	end

	local chair_id = 1
	tb:private_init(global_tid,rule,{
		round = round,
		chair_count = chair_count,
		owner = player,
		owner_guid = player.guid,
		owner_chair_id = chair_id,
		rule = rule,
		club = club,
	})

	reddb:hmset("table:info:"..tostring(global_tid),{
		room_id = def_game_id,
		table_id = global_tid,
		real_table_id = table_id,
		owner = player.guid,
		rule = rule,
		game_type = def_first_game_type,
		create_time = os.time(),
	})

	reddb:sadd("player:table:"..tostring(player.guid),global_tid)

	self:player_enter_room(player)
	
	local result = tb:lockcall(function() return tb:player_sit_down(player, chair_id) end)
	if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
		tb:private_clear()
		reddb:del("table:info:"..tostring(global_tid))
		reddb:srem("player:table:"..tostring(player.guid),global_tid)
		self:player_exit_room(player)
		return result
	end

	reddb:hset("player:online:guid:"..tostring(player.guid),"global_table",global_tid)

	return enum.GAME_SERVER_RESULT_SUCCESS,global_tid,tb
end

function base_room:reconnect(player,table_id,chair_id)
	local tb = self.tables[table_id]
	if not tb then
		log.warning("base_room:reconnect table %d not found,guid:%d,chair_id:%d",table_id,player.guid,chair_id)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	tb:player_sit_down(player, chair_id,true)

	return tb:reconnect(player)
end

-- 加入私人房间
function base_room:join_private_table(player,private_table,chair_count)
	if player.table_id or player.chair_id then
		log.warning("player tableid is [%d] chairid is [%d]",player.table_id,player.chair_id)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	local table_id = private_table.real_table_id
	local tb = self.tables[table_id]
	if not tb then
		log.info("join private table:%d,%d not found",private_table.table_id,table_id)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	-- if not self:check_private_limit(player,chair_count,private_table.rule) then
	-- 	log.info("join private table:%d,%d money limit:%d",private_table.table_id,table_id,player.guid)
	-- 	return enum.GAME_SERVER_RESULT_ROOM_LIMIT
	-- end

	if self.cur_player_count_ > self.player_count_limit then
		log.warning("join private table,room is full,%s:%d",def_game_name,def_game_id)
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
	end

	local chair_id = tb:get_free_chair_id()
	if not chair_id then
		log.info("join private table:%d,%d without free chair",private_table.table_id,table_id)
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NO_FREE_CHAIR
	end

	local result = tb:lockcall(function() return tb:player_sit_down(player, chair_id) end)
	if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
		return result
	end

	self:player_enter_room(player)

	reddb:hset("player:online:guid:"..tostring(player.guid),"global_table",private_table.table_id)

	return enum.GAME_SERVER_RESULT_SUCCESS,tb
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
	tb:lockcall(function() tb:player_stand_up(player, enum.STANDUP_REASON_NORMAL) end)
	tb:lockcall(function() tb:check_start(true) end)

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
	
	if not player:check_money_limit(self:get_room_limit()) and self.cur_player_count_ < self.player_count_limit then
		-- 通知消息
		local notify = {
			room_id = self.id,
			guid = player.guid,
		}
		if not player:is_android() then
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

	log.info("base_room:enter_room: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%s]",
		def_game_name,def_game_id,self.game_switch_is_open)
	if  self.game_switch_is_open == 1 then --游戏进入维护阶段
		if player.vip ~= 100 then
			send2client_pb(player, "SC_GameMaintain", {
					result = enum.GAME_SERVER_RESULT_MAINTAIN,
					})
			log.warning("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id)
			return 14
		end
	end

	if player:check_money_limit(self:get_room_limit()) then
		log.warning("guid[%d] check money limit fail,limit[%d],self[%s]",
			player.guid, self:get_room_limit(), player.money)
		return GAME_SERVER_RESULT_ROOM_LIMIT
	end

	-- 通知消息
	local notify = {
		room_id = self.id,
		guid = player.guid,
	}
	if not player:is_android() then
		self:foreach_by_player(function (p)
			if p then
				p:on_notify_enter_room(notify)
			end
		end)
	end

	self:player_enter_room(player)

	return enum.GAME_SERVER_RESULT_SUCCESS
end

function base_room:cs_trusteeship(player,is_trustee)
	local tb = self:find_table(player.table_id)
	if not tb then
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	tb:set_trusteeship(player,is_trustee)
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

-- 退出服务器
function base_room:exit_server(player,offline,reason)
	reason = reason or enum.STANDUP_REASON_NORMAL
	log.info("base_room:exit_server guid[%d],offline:%s,reason:%s",player.guid,offline,reason)
	if not player.table_id or not player.chair_id then
		log.warning("base_room:exit_server,player:%s table_id or chair_id is nil,exit.",player.guid)
		self:logout_game(player,offline)
		-- player:on_exit_room(enum.GAME_SERVER_RESULT_SUCCESS)
		return enum.GAME_SERVER_RESULT_SUCCESS
	end

	local tb = self:find_table_by_player(player)
	if not tb then
		log.warning("base_room:exit_server not found table:%s,guid:%s",player.table_id,player.guid)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local can_exit = tb:lockcall(function() return tb:player_stand_up(player,offline and enum.STANDUP_REASON_OFFLINE or reason) end)
	log.info("base_room:exit_server,guid[%d] player_stand_up,table_id:%s,can_leave[%s] reason[%s]",player.guid,player.table_id,can_exit,reason)
	if not can_exit then
		return enum.GAME_SERVER_RESULT_IN_GAME
	end

	self:player_exit_room(player,offline)
	-- player:on_exit_room(enum.GAME_SERVER_RESULT_SUCCESS)

	return enum.GAME_SERVER_RESULT_SUCCESS
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
	print("ip_area--------------------A",  player.ip_area)
	print("ip_area--------------------B",  player.ip_area)
	tb:player_sit_down(player, chair_id_)

	return enum.GAME_SERVER_RESULT_SUCCESS, table_id_, chair_id_
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
			elseif not chair:is_android() then
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

function base_room:get_player_num()
	return self.cur_player_count_
end

-- 玩家进入房间
function base_room:player_enter_room(player)
	log.info("set player[%s] in_game true this room have player count is [%s] [%s]" ,
		player.guid , self.cur_player_count_ , self:get_player_num())
	self.players[player.guid] = player
	self.cur_player_count_ = self.cur_player_count_ + 1

	log.info("base_room:player_enter_room, guid %s, room_id %s",player.guid,def_game_id)

	local online_key = string.format("player:online:guid:%d",player.guid)
	reddb:hmset(online_key,{
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		server = def_game_id,
	})

	onlineguid[player.guid] = nil
end

-- 玩家退出房间
function base_room:player_exit_room(player,offline)
	log.info("base_room:player_exit_room, guid %s, room_id %s",player.guid,def_game_id)
	local guid = player.guid
	base_players[guid] = nil
	self.players[guid] = nil
	self.cur_player_count_ = self.cur_player_count_ - 1
	if offline then
		log.info("player_exit_room set guid[%d] onlineinfo",guid)
		local online_key = string.format("player:online:guid:%d",guid)
		reddb:hdel(online_key,"first_game_type")
		reddb:hdel(online_key,"second_game_type")
	else
		log.info("player_exit_room not set guid[%d] onlineinfo",guid)
		local room_id = common.find_best_room(1)
		common.switch_room(guid,room_id)
	end

	onlineguid[guid] = nil
end

function base_room:logout_game(player)
	log.info("base_room:logout_game, guid %s, room_id %s",player.guid,def_game_id)
	local guid = player.guid
	base_players[guid] = nil
	self.players[guid] = nil
	self.cur_player_count_ = self.cur_player_count_ - 1
	log.info("logout_game set guid[%d] onlineinfo",guid)
	local online_key = string.format("player:online:guid:%d",guid)
	reddb:hdel(online_key,"first_game_type")
	reddb:hdel(online_key,"second_game_type")
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
			print("ip_area--------------------A",  player.ip_area)
			print("ip_area--------------------B",  player.ip_area)
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