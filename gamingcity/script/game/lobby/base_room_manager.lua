-- game room

local pb = require "pb"
local log = require "log"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_room"
local base_table = require "game.lobby.base_table"
-- local base_player = require "game.lobby.base_player"
local base_prize_pool = require "game.lobby.base_prize_pool"

require "table_func"

require "game.timer_manager"
local _,base_bonus_activity_manager = require "game.lobby.base_bonus"

local redisopt = require "redisopt"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_IN_GAME = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
local GAME_SERVER_RESULT_IN_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
local GAME_SERVER_RESULT_FREEZEACCOUNT = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
local GAME_SERVER_RESULT_PLAYER_ON_CHAIR = pb.enum("GAME_SERVER_RESULT" , "GAME_SERVER_RESULT_PLAYER_ON_CHAIR")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER")
local GAME_SERVER_RESULT_PLAYER_NO_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_NO_CHAIR")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")
local GAME_SERVER_RESULT_MAINTAIN = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
-- enum GAME_READY_MODE
local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")


local def_game_id = def_game_id
local def_game_name = def_game_name
local get_db_status = get_db_status

require "timer"
local add_timer = add_timer
local redis_cmd_query = redis_cmd_query

-- 房间
base_room = base_room or {}

-- 奖池
global_prize_pool = global_prize_pool or base_prize_pool:new()

function base_room  
    local o = {}  
    setmetatable(o, {__index = self})  
    return o 
end

-- 初始化房间
function base_room:init(tb, chair_count, ready_mode, room_lua_cfg)
	self.time0_ = get_second_time()
	self.chair_count_ = chair_count
	self.ready_mode_ = ready_mode
	self.room_list_ = {}
	self.blacklist_player = {}

	for i,v in ipairs(tb) do
		local r = self:create_room()
		r.id = i
		r:init(self, v.table_count, chair_count, ready_mode, v.money_limit, v.cell_money, v, room_lua_cfg)
		self.room_list_[i] = r
	end

	add_timer(30*1, function()
		self:read_blacklist_player()
	end)

	timer_manager:new_timer(2,function()
		base_bonus_activity_manager:load_activity()
	end)

	timer_manager:new_timer(1,function() 
		base_bonus_activity_manager:tick()
	end,"global_bonus_update_timer",true)
end

-- gm重新更新配置, room_lua_cfg
function base_room:gm_update_cfg(tb, room_lua_cfg)
	local old_count = #self.room_list_
	for i,v in ipairs(tb) do
		if i <= old_count then
			print("change----gm_update_cfg", v.table_count, self.chair_count_, v.money_limit, v.cell_money,v.game_switch_is_open)
			self.room_list_[i]:gm_update_cfg(self,v.table_count, self.chair_count_, v.money_limit, v.cell_money, v, room_lua_cfg)
		else
			local r = self:create_room()
			print("Init----gm_update_cfg", v.table_count, self.chair_count_, v.money_limit, v.cell_money)
			r:init(self, v.table_count, self.chair_count_, self.ready_mode_, v.money_limit, v.cell_money, v, room_lua_cfg)
			self.room_list_[i] = r
		end
	end
end

-- 创建房间
function base_room:create_room()
	return base_room
end

-- 创建桌子
function base_room:create_table()
	return base_table:new()
end

-- 找到房间
function base_room:find_room(room_id)
	return self.room_list_[room_id]
end

-- 通过玩家找房间
function base_room:find_room_by_player(player)
	if not player.room_id then
		log.warning(string.format("guid[%d] not find in room", player.guid))
		return nil
	end

	local room = self:find_room(player.room_id)
	if not room then
		log.warning(string.format("room_id[%d] not find in room", player.room_id))
		return nil
	end

	return room
end

-- 通过玩家找桌子
function base_room:find_table_by_player(player)
	local room = self:find_room_by_player(player)
	if room then
		return room:find_table_by_player(player)
	end
	return nil
end

-- 遍历房间所有玩家
function base_room:foreach_by_player(func)
	for i,v in ipairs(self.room_list_) do
		v:foreach_by_player(func)
	end
end

-- 广播房间中所有人消息
function base_room:broadcast2client_by_player(msg_name, pb)
	for i,v in ipairs(self.room_list_) do
		v:broadcast2client_by_player(msg_name, pb)
	end
end

function base_room:get_table_players_status( player )
	-- body
	print("--------get_table_player_status-------------")
end

-- 进入房间并坐下
function base_room:enter_room_and_sit_down(player)
	log.info(string.format("player guid is : %d",player.guid))
	if player.disable == 1 then
		log.info("get_table_players_status player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if player.room_id then
		log.info(string.format("player room_id is :%d ",player.room_id))
		return GAME_SERVER_RESULT_IN_ROOM
	end

	if player.table_id or player.chair_id then
		log.info(string.format("player tableid is [%d] chairid is [%d] guid[%d]",player.table_id,player.chair_id,player.guid))
		return GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	log.info(string.format("base_room:enter_room_and_sit_down: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d] get_db_status[%d]",def_game_name,def_game_id,self.room_list_[1].game_switch_is_open,get_db_status()))
	log.info(string.format("player guid[%d], player vip = [%d]",player.guid, player.vip))
	if  self.room_list_[1].game_switch_is_open == 1 or get_db_status() == 0 then --游戏进入维护阶段
		if player and player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = GAME_SERVER_RESULT_MAINTAIN,
					})
			player:forced_exit()
			log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
			return 14
		end	
	end

	local ret = GAME_SERVER_RESULT_NOT_FIND_ROOM

	for i,room in ipairs(self.room_list_) do
		if not player:check_room_limit(room:get_room_limit()) and room.cur_player_count_ < room.player_count_limit_ then
			ret = GAME_SERVER_RESULT_NOT_FIND_TABLE
			local tb,k,j = self:get_suitable_table(room,player,false)
			if tb then
				room:player_enter_room(player, i)
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
				return GAME_SERVER_RESULT_SUCCESS, i, j, k, tb
			end
		end
	end

	return ret
end

-- 站起并离开房间
function base_room:stand_up_and_exit_room(player)
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	if tb:is_play(player) then
		return GAME_SERVER_RESULT_IN_GAME
	end
	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end
	if chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end
	local tableid = player.table_id
	local chairid = player.chair_id
	tb:player_stand_up(player, false)
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
	room:player_exit_room(player)
	return GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
end

-- 创建私人房间
function base_room:create_private_room(player, chair_count, score_type)
	if player.room_id then
		print("player room_id is :"..player.room_id)
		return GAME_SERVER_RESULT_IN_ROOM
	end

	if player.table_id or player.chair_id then
		print(string.format("player tableid is [%d] chairid is [%d] guid[%d]",player.table_id,player.chair_id,player.guid))
		return GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	local ret = GAME_SERVER_RESULT_NOT_FIND_ROOM

	for i,room in ipairs(self.room_list_) do
		if not player:check_room_limit(room:get_room_limit()) and room.cur_player_count_ < room.player_count_limit_ then
			ret = GAME_SERVER_RESULT_NOT_FIND_TABLE
			local tb,k,j = self:get_private_table(room,player, chair_count, score_type)
			if tb then
				room:player_enter_room(player, i)
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
				tb:player_sit_down(player, k)
				return GAME_SERVER_RESULT_SUCCESS, i, j, k, tb
			end
		end
	end

	return ret
end

-- 加入私人房间
function base_room:join_private_room(player, owner_guid)
	if player.room_id then
		print("player room_id is :"..player.room_id)
		return GAME_SERVER_RESULT_IN_ROOM
	end

	if player.table_id or player.chair_id then
		print(string.format("player tableid is [%d] chairid is [%d]",player.table_id,player.chair_id))
		return GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	local ret = GAME_SERVER_RESULT_NOT_FIND_ROOM

	for i,room in ipairs(self.room_list_) do
		if not player:check_room_limit(room:get_room_limit()) and room.cur_player_count_ < room.player_count_limit_ then
			ret = GAME_SERVER_RESULT_NOT_FIND_TABLE
			local tb,k,j = self:get_join_private_table(room,owner_guid)
			if tb then
				room:player_enter_room(player, i)
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
				tb:player_sit_down(player, k)
				return GAME_SERVER_RESULT_SUCCESS, i, j, k, tb
			end
		end
	end

	return ret
end

-- 切换座位
function base_room:change_chair(player)
	if player.disable == 1 then
		print("stand_up_and_exit_room player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end

	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tableid = player.table_id
	local chairid = player.chair_id
	local targettb = nil
	local targetid = nil

	for i,v in ipairs(room:get_table_list()) do
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
		for i,v in ipairs(room:get_table_list()) do
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
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	-- 旧桌子站起
	tb:player_stand_up(player, false)

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

	return GAME_SERVER_RESULT_SUCCESS, targettb.table_id_, targetid, targettb
end

-- 快速进入房间
function base_room:auto_enter_room(player)
	if player.disable == 1 then
		print("auto_enter_room player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if player.room_id then
		return GAME_SERVER_RESULT_IN_ROOM
	end

	log.info(string.format("base_room:auto_enter_room: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d] get_db_status[%d]",def_game_name,def_game_id,self.room_list_[1].game_switch_is_open,get_db_status()))
	if  self.room_list_[1].game_switch_is_open == 1 or get_db_status() == 0 then --游戏进入维护阶段
		if player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = GAME_SERVER_RESULT_MAINTAIN,
					})
			log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
			return 14
		end	
	end
	for i,room in ipairs(self.room_list_) do
		if not player:check_room_limit(room:get_room_limit()) and room.cur_player_count_ < room.player_count_limit_ then
			-- 通知消息
			local notify = {
				room_id = i,
				guid = player.guid,
			}
			if player.is_player then
				room:foreach_by_player(function (p)
					p:on_notify_enter_room(notify)
				end)
			end

			room:player_enter_room(player, i)
			return GAME_SERVER_RESULT_SUCCESS, i
		end
	end

	return GAME_SERVER_RESULT_NOT_FIND_ROOM
end

-- 进入房间
function base_room:enter_room(player, room_id_)
	if player.disable == 1 then
		print("enter_room player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end

	local room = self

	log.info(string.format("base_room:enter_room: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d] get_db_status[%d]",def_game_name,def_game_id,self.room_list_[1].game_switch_is_open,get_db_status()))
	if  self.room_list_[1].game_switch_is_open == 1 then --游戏进入维护阶段
		if player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = GAME_SERVER_RESULT_MAINTAIN,
					})
			log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
			return 14
		end	
	end

	if player:check_room_limit(room:get_room_limit()) then
		log.warning(string.format("guid[%d] check money limit fail,limit[%d],self[%d]", player.guid, room:get_room_limit(), player.pb_base_info.money))
		return GAME_SERVER_RESULT_ROOM_LIMIT
	end

	-- 通知消息
	local notify = {
		room_id = self.id,
		guid = player.guid,
	}
	if player.is_player then
		room:foreach_by_player(function (p)
			if p then
				p:on_notify_enter_room(notify)
			end
		end)
	end

	room:player_enter_room(player, room_id_)

	return GAME_SERVER_RESULT_SUCCESS
end
function base_room:cs_trusteeship(player)
	-- body
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	tb:set_trusteeship(player,true)
end
-- 离开房间
function base_room:exit_room(player,is_logout)
	print("base_room:exit_room")
	if not player.room_id then
		print("GAME_SERVER_RESULT_OUT_ROOM")
		return GAME_SERVER_RESULT_OUT_ROOM
	end

	--if not player.table_id then
	--	return GAME_SERVER_RESULT_NOT_FIND_TABLE
	--end

	--if not player.chair_id then
	--	return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	--end

	local roomid = player.room_id
	log.info(string.format("player[%d] out room [%d]",player.guid,tostring(roomid)))
	local room = self:find_room(roomid)
	if not room then
		print("GAME_SERVER_RESULT_NOT_FIND_ROOM")
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	room:player_exit_room(player,is_logout)
	
	local notify = {
			room_id = roomid,
			guid = player.guid,
		}

	--room:foreach_by_player(function (p)
	--	if p then
	--		p:on_notify_exit_room(notify)
	--	end
	--end)

	return GAME_SERVER_RESULT_SUCCESS, roomid
end

-- 玩家掉线
function base_room:player_offline(player)
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end

	local tableid, chairid = player.table_id, player.chair_id

	if tb:player_stand_up(player, true) then
		local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
		tb:foreach(function (p)
			p:on_notify_stand_up(notify)
		end)

		tb:check_start(true)

		return GAME_SERVER_RESULT_SUCCESS, false
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

	return GAME_SERVER_RESULT_SUCCESS, true
end
function base_room:is_play(player)
	print("=========base_room:is_play")
	-- body
	if player.room_id and player.table_id and player.chair_id then
		local room = self:find_room(player.room_id)
		if not room then
			print("=========base_room:is_play not room")
			return false
		end
		local tb = room:find_table(player.table_id)
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

		local room = self:find_room(player.room_id)
		if not room then
			return GAME_SERVER_RESULT_NOT_FIND_ROOM
		end
		player:on_enter_room(player.room_id, GAME_SERVER_RESULT_SUCCESS)

		local tb = room:find_table(player.table_id)
		if not tb then
			return GAME_SERVER_RESULT_NOT_FIND_TABLE
		end
		
		local chair = tb:get_player(player.chair_id)
		if not chair then
			return GAME_SERVER_RESULT_NOT_FIND_CHAIR
		end

		if chair.guid ~= player.guid then
			player.table_id = nil
			player.chair_id = nil
			return GAME_SERVER_RESULT_OHTER_ON_CHAIR
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

		return GAME_SERVER_RESULT_SUCCESS
	end
end

-- 退出服务器
function base_room:exit_server(player,is_logout)
	log.info(string.format("base_room:exit_server guid[%d]",player.guid))
	if player.room_id and player.table_id and player.chair_id then
		--self:stand_up(player)
		local result_, is_offline_ = self:player_offline(player)

		log.info(string.format("guid[%d] player_offline return [%d] is_offline[%s]",player.guid,result_,tostring(is_offline_)))
		if result_ == GAME_SERVER_RESULT_SUCCESS then
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
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	for i,tb in ipairs(room:get_table_list()) do
		for j,chair in ipairs(tb:get_player_list()) do
			if chair == false then
				return self:sit_down(player, i, j)
			end
		end
	end

	return GAME_SERVER_RESULT_NOT_FIND_TABLE
end

-- 坐下
function base_room:sit_down(player, table_id_, chair_id_)
	if player.disable == 1 then
		print("sit_down player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	
	if player.table_id or player.chair_id then
		log.info(string.format("base_room:sit_down error guid [%d] GAME_SERVER_RESULT_PLAYER_ON_CHAIR",player.guid))
		return GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end
	
	local tb = room:find_table(table_id_)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	
	local chair = tb:get_player(chair_id_)
	if chair then
		return GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER
	elseif chair == nil then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
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

	return GAME_SERVER_RESULT_SUCCESS, table_id_, chair_id_
end


-- 站起
function base_room:stand_up_new(player)
	log.info(string.format("base_room:stand_up_new player guid[%d]",player.guid))
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end

	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end
	
	local tableid = player.table_id
	local chairid = player.chair_id
	local ret =  tb:player_stand_up(player, false)
	if ret == false then
		log.warning(string.format("player guid[%d] stand_up failed, return GAME_SERVER_RESULT_IN_GAME",player.guid))
		return GAME_SERVER_RESULT_IN_GAME
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

	return GAME_SERVER_RESULT_SUCCESS, tableid, chairid
end


-- 站起
function base_room:stand_up(player)
	print("base_room:stand_up")
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end

	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end
	
	local tableid = player.table_id
	local chairid = player.chair_id
	tb:player_stand_up(player, false)

	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)

	tb:check_start(true)

	return GAME_SERVER_RESULT_SUCCESS, tableid, chairid
end

-- 找一个被动机器人位置
function base_room:find_android_pos(room_id)
	local room = self:find_room(room_id)
	if not room then
		return nil
	end

	local isplayer = false
	local tableid, chairid
	for i,tb in ipairs(room:get_table_list()) do
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
	for i,v in ipairs(self.room_list_) do
		for _,tb in ipairs(v:get_table_list()) do
			tb:tick()

			if global_prize_pool and global_prize_pool.tick then
				global_prize_pool:tick(v.id , tb.table_id_)
			end
		end
	end
end
function base_room:get_private_table(room,player, chair_count, score_type)
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(room:get_table_list()) do
		if 0 == tb:get_player_count() then
			for k,chair in ipairs(tb:get_player_list()) do
				if chair == false then
					suitable_table = tb
					chair_id = k
					table_id = j
					tb.private_room = true
					tb.private_room_chair_count = chair_count
					tb.private_room_score_type = score_type
					tb.private_room_owner_guid = player.guid
					tb.private_room_owner_chair_id = k
					tb.private_room_id = player.guid				-- 私人房间号暂时先用创建的guid
					--初始化私房
					tb:private_init()
					return suitable_table,chair_id,table_id
				end
			end
		end
	end	
	return suitable_table,chair_id,table_id
end
function base_room:get_join_private_table(room,owner_guid)
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	local kk = nil
	local r = false
	for j,tb in ipairs(room:get_table_list()) do
		if tb.private_room then
			for k,chair in ipairs(tb:get_player_list()) do
				if chair == false then
					kk = k
					if r then
						break
					end
				elseif chair.guid == owner_guid then
					r = true
					if kk then
						break
					end
				end
			end
			if r then
				if tb:can_enter() then
					suitable_table = tb
					chair_id = kk
					table_id = j
				end
				break
			end
		end
	end	

	return suitable_table,chair_id,table_id
end
function base_room:get_suitable_table(room,player,bool_change_table)
	local player_count = -1
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(room:get_table_list()) do
		if tb.private_room and 0 == tb:get_player_count() then
			tb.private_room = false
		end
		if (not tb.private_room) and (suitable_table == nil or (suitable_table ~= nil and suitable_table:get_player_count() < tb:get_player_count())) then
			for k,chair in ipairs(tb:get_player_list()) do
				--log.info(string.format("get_suitable_table step 1 roomid[%d] tableid[%d] guid[%d]",room.id, tb.table_id_,player.guid))
				if (bool_change_table and player.table_id ~= tb.table_id_) or (not bool_change_table) then
					--log.info(string.format("get_suitable_table step 2 roomid[%d] tableid[%d] guid[%d]",room.id, tb.table_id_,player.guid))
					if chair == false and tb:can_enter(player) then
						log.info(string.format("get_suitable_table step 3 roomid[%d] tableid[%d] guid[%d]",room.id, tb.table_id_,player.guid))
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
			--log.warning(string.format("table pcount %d, table_id is %d",tb:get_player_count(),j))
		end
	end	
	
	--log.warning(string.format("final, room pcount %d,suitable_table table_id is %d, chair_id is %d,player_count is %d",
	--room.cur_player_count_,table_id,chair_id,suitable_table:get_player_count()))
	return suitable_table,chair_id,table_id
end
function base_room:change_table_new( player )
 	-- body
 	if not player then
 		log.warning("player is null.")
 		return
 	end

 	log.info(string.format("player guid[%d] change_table_new start..........",player.guid))
 	if player.disable == 1 then
		print("change_table_new player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	local tb = self:find_table_by_player(player)
	if tb then		
		if tb:is_play(player) then
			log.warning(string.format("player guid[%d] is playing",player.guid))
			return
		end
		local room = self:find_room_by_player(player)
		if room then	
			local tb,k,j = self:get_suitable_table(room,player,true)
			if tb then
				--离开当前桌子
				--local result_, table_id_, chair_id_  = self:stand_up(player)
				local result_, table_id_, chair_id_  = self:stand_up_new(player)
				if result_ ~= GAME_SERVER_RESULT_SUCCESS then
					log.warning(string.format("player guid[%d] stand_up_new failed.",player.guid))
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
				player:change_table(player.room_id, j, k, GAME_SERVER_RESULT_SUCCESS, tb)
				self:get_table_players_status(player)
				return
			end	
		else
			log.warning("not in room")
		end
	else
		log.warning("no find tb")
	end

 end 

function base_room:change_table(player)
	print("======================base_room:change_table")
	-- body
	if player.disable == 1 then
		print("change_table player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	local tb = self:find_table_by_player(player)
	if tb then
		local room = self:find_room_by_player(player)
		if room then	
			local tb,k,j = self:get_suitable_table(room,player,true)
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
				player:change_table(player.room_id, j, k, GAME_SERVER_RESULT_SUCCESS, tb)
				self:get_table_players_status(player)
				return
			end	
		else
			print("not in room")
		end
	else
		print("no find tb")
	end
end


function base_room:change_tax(tax, tax_show, tax_open)
	print("======================base_room:change_tax")
	tax_ = tax * 0.01
	for i , v in pairs (self.room_list_) do		
		print (tax_, tax_show, tax_open)
		v.tax_show_ = tax_show -- 是否显示税收信息
		v.tax_open_ = tax_open -- 是否开启税收
		v.tax_ = tax_
	end
end


function base_room:read_blacklist_player()
	log.info("start read blacklist players...........................")
	self.blacklist_player = {}
	local reply = redisopt.default:SMEMBERS("black_user_guid")
	if type(reply) == "table" then	
		log.info(string.format("blacklist size-------->[%d]",#reply))
		for _,v in pairs(reply) do
			local  key = tonumber(v)
			self.blacklist_player[key] = true
		end
	else
		print("========================is array error")
	end
	add_timer(60*5+1, function()
		self:read_blacklist_player()
	end)	
end


--检查玩家是否是黑名单列表玩家，若是则返回true，否则返回false
function base_room:check_player_is_in_blacklist( player_guid )
	-- body
	if player_guid < 0 then
		return false
	end

	if not self.blacklist_player[player_guid]  then
		return false
	elseif  self.blacklist_player[player_guid] and self.blacklist_player[player_guid] == true then
		log.warning(string.format("find  blacklist_player------->guid[%d]",player_guid))
		return true
	else
		return false
	end

end