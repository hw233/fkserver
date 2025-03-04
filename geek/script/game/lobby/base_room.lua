
local base_table = require "game.lobby.base_table"
local enum = require "pb_enums"
local player_context = require "game.lobby.player_context"
local player_data = require "game.lobby.player_data"
local onlineguid = require "netguidopt"
local channel = require "channel"
local common = require "game.common"
local game_util = require "game.util"
local club_utils = require "game.club.club_utils"
local club_money = require "game.club.club_money"
local allonlineguid = require "allonlineguid"
local player_club = require "game.lobby.player_club"
local base_private_table = require "game.lobby.base_private_table"
local mutex = require "mutex"

require "game.net_func"

local log = require "log"
local redisopt = require "redisopt"

local reddb = redisopt.default

local string = string
local table = table
local strfmt = string.format

-- 房间
local base_room = {}


local function check_conf(conf)
	assert(conf.money_limit)
	assert(conf.tax)
	assert(conf.tax_show)
	assert(conf.tax_open)
	assert(conf.cell_money)
	local tbconf = conf.table
	if tbconf then
		assert(tbconf.chair_count)
	end
end

function base_room:new()
	local o = {}
	setmetatable(o,{__index = base_room,})
	return o
end

-- 初始化房间
function base_room:init(conf)
	check_conf(conf)

	self.id = 1
	self.conf = conf
	local tbconf = conf.table
	if tbconf then
		self.chair_count = tbconf.chair_count
		self.min_gamer_count = tbconf.min_gamer_count or tbconf.chair_count
	end
	
	self.tax_show = conf.tax_show -- 是否显示税收信息
	self.tax_open = conf.tax_open -- 是否开启税收
	self.tax = conf.tax * 0.01
	self.room_limit = conf.money_limit or 0 -- 房间分限制
	self.cell_score = conf.cell_money or 0 -- 底注
	self.tables = {}

	self.players = {}
end

function base_room:get_chair_count()
	return self.chair_count
end

function base_room:get_min_gamer_count()
	return self.min_gamer_count or self.chair_count
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
	return self.tax
end

function base_room:get_private_fee(rule)
	return self.conf.private_conf.fee[(rule.round.option or 0) + 1]
end

-- 得到房间分限制
function base_room:get_room_limit()
	return self.room_limit
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
		log.info("get_table_players_status player is Freeaz force_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end

	if player.table_id or player.chair_id then
		log.info("player tableid is [%d] chairid is [%d] guid[%d]",player.table_id,player.chair_id,player.guid)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	log.info("base_room:enter_room_and_sit_down: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d]",def_game_name,def_game_id,self.game_switch_is_open)
	log.info("player guid[%d], player vip = [%d]",player.guid, player.vip)
	if self.game_switch_is_open == 1 then --游戏进入维护阶段
		if player and player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = enum.GAME_SERVER_RESULT_MAINTAIN,
					})
			player:async_force_exit()
			log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
			return 14
		end
	end

	local ret = enum.GAME_SERVER_RESULT_NOT_FIND_ROOM
	if not player:check_money_limit(self:get_room_limit()) then
		ret = enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		local tb,k,j = self:get_suitable_table(self,player,false)
		if tb then
			self:player_enter_room(player)
			ret = tb:player_sit_down(player, k)
			return ret, j, k, tb
		end
	end

	return ret
end

-- 站起并离开房间
function base_room:stand_up_and_exit_room(player,reason)
	local guid = player.guid
	if common.is_in_lobby() then
		log.error("base_room:stand_up_and_exit_room in lobby,%s",guid)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	-- double check
	if not player.online then
		log.error("base_room:stand_up_and_exit_room double check failed,%s",guid)
		return enum.ERROR_NONE
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

	return tb:lockcall(function()
		local tableid = player.table_id
		local chairid = player.chair_id
		local result = tb:player_stand_up(player, reason)
		if result ~= enum.ERROR_NONE then
			log.info("base_room:stand_up_and_exit_room player_stand_up guid %s, table_id %s,chair %s,reason %s,%s,failed",
				chair.guid,tableid, chairid,reason,result)
			return result
		end

		local roomid = player.room_id
		self:player_exit_room(player)
		return enum.GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
	end)
end

function base_room:check_entry_table_limit(player,rule,club)
	if not rule or not rule.union or not club then
		return true
	end

	local money_id = club_money[club.id]

	return player:get_money(money_id) >= rule.union.entry_score
end

function base_room:is_table_exists(table_id)
	return self.tables[table_id] ~= nil
end

function base_room:force_dismiss_table(table_id,reason)
	local tb = self:find_table(table_id)
	if not tb then
		return enum.ERROR_TABLE_NOT_EXISTS
	end

	local result = tb:wait_force_dismiss(enum.STANDUP_REASON_ADMIN_DISMISS_FORCE)
	
	return result or enum.ERROR_NONE
end

function base_room:request_dismiss_private_table(requester)
	local tb = self:find_table_by_player(requester)
	if not tb then
		return enum.ERROR_PLAYER_NOT_IN_GAME
	end

	return tb:request_dismiss(requester)
end

function base_room:commit_dismiss_private_table(player,agree)
	local tb = self:find_table_by_player(player)
	if not tb then
		return enum.ERROR_PLAYER_NOT_IN_GAME
	end

	return tb:commit_dismiss(player,agree)
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

function base_room:new_table(id,chair_count)
	local t = self:create_table()
	t:init(self, id, chair_count)
	self.tables[id] = t
	return t
end

function base_room:del_table(id)
	self.tables[id] = nil
end

function base_room:play_once_again(player)
	if player.trustee then
		return enum.ERROR_OPERATION_INVALID
	end

	if not player.table_id or not player.chair_id then
		return enum.ERROR_PLAYER_NOT_IN_GAME
	end

	local tb = self:find_table_by_player(player)
	if not tb then
		return enum.ERROR_TABLE_NOT_EXISTS
	end

	return tb:play_once_again(player),tb:hold_ext_game_id()
end

-- 创建私人房间
function base_room:create_private_table(player,chair_count,round, rule,club)
	if player.table_id or player.chair_id then
		log.info("player already in table, table_id is [%s] chair_id is [%s] guid[%s]",player.table_id,player.chair_id,player.guid)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	local room_fee_result = self:check_room_fee(rule,club,player)
	if room_fee_result ~= enum.ERROR_NONE then
		return room_fee_result
	end

	local global_tid
	local tableid_same_times=0
	local ok = mutex("table:create",function()
		for _ = 1,10000 do
			global_tid = math.random(100000,999999)
			local exists = reddb:sismember("table:all",global_tid)
			if not exists then 
				break 
			else
				tableid_same_times=tableid_same_times+1
			end
		end
		log.info("has same table id count:%d",tableid_same_times )
		reddb:sadd("table:all",global_tid)
	end)

	local table_id = global_tid
	local tb = self:new_table(table_id,chair_count)

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

	tb.private_id = global_tid
	tb.max_round = round
	tb.owner = player
	tb.owner_guid = player.guid
	tb.owner_chair_id = chair_id
	tb.rule = rule
	tb.club = club
	tb.club_id = club and club.id or nil

	return tb:lockcall(function()
		local result = tb:player_sit_down(player, chair_id)
		if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
			log.info("base_room:create_private_table player_sit_down,%s,%s,%s,failed",player.guid,chair_id,result)
			tb:private_clear()
			self:del_table(table_id)
			reddb:srem("table:all",global_tid)
			return result
		end

		self:player_enter_room(player)

		reddb:hmset("table:info:"..tostring(global_tid),{
			room_id = def_game_id,
			table_id = global_tid,
			real_table_id = table_id,
			owner = player.guid,
			rule = rule,
			game_type = def_first_game_type,
			create_time = os.time(),
		})

		reddb:hset("player:online:guid:"..tostring(player.guid),"global_table",global_tid)

		return enum.GAME_SERVER_RESULT_SUCCESS,global_tid,tb
	end)
end

function base_room:reconnect(player,table_id,chair_id)
	local tb = self.tables[table_id]
	if not tb then
		log.warning("base_room:reconnect table %s not found,guid:%s,chair_id:%s",table_id,player.guid,chair_id)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	return tb:lockcall(function()
		local result = tb:player_sit_down(player, chair_id,true)
		if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
			log.warning("base_room:reconnect table %s,guid:%s,chair_id:%s,result:%s,failed",
				table_id,player.guid,chair_id,result)
			return result
		end

		return tb:reconnect(player)
	end)
end

-- 加入私人房间
function base_room:join_private_table(player,private_table,chair_count)
	if player.table_id or player.chair_id then
		log.warning("player tableid is [%s] chairid is [%s]",player.table_id,player.chair_id)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	local table_id = private_table.real_table_id
	local tb = self.tables[table_id]
	if not tb then
		log.info("join private table:%s,%s not found",private_table.table_id,table_id)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	
	local chair_id = tb:get_free_chair_id()
	if not chair_id then
		log.info("join private table:%s,%s without free chair",private_table.table_id,table_id)
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NO_FREE_CHAIR
	end

	return tb:lockcall(function()
		local result = tb:player_sit_down(player, chair_id)
		if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
			log.info("join private table:%s,%s,result:%s",private_table.table_id,table_id,result)
			return result
		end

		self:player_enter_room(player)

		reddb:hset("player:online:guid:"..tostring(player.guid),"global_table",private_table.table_id)

		return enum.GAME_SERVER_RESULT_SUCCESS,tb
	end)
end

function base_room:fast_join_private_table(tb,player,chair_id)
	return tb:lockcall(function()
		local table_id = tb:id()
		local result = tb:player_sit_down(player, chair_id)
		if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
			log.info("join private table:%s,%s,result:%s",table_id,chair_id,result)
			return result
		end
		
		self:player_enter_room(player)

		reddb:hset("player:online:guid:"..tostring(player.guid),"global_table",table_id)
		return enum.ERROR_NONE
	end)
end

-- 切换座位
function base_room:change_chair(player)
	if player.disable == 1 then
		print("stand_up_and_exit_room player is Freeaz force_exit")
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

	targettb:player_sit_down(player, targetid)

	return enum.GAME_SERVER_RESULT_SUCCESS, targettb.table_id_, targetid, targettb
end

-- 快速进入房间
function base_room:auto_enter_room(player)
	if player.disable == 1 then
		print("auto_enter_room player is Freeaz force_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end

	log.info("base_room:auto_enter_room: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d]",def_game_name,def_game_id,self.game_switch_is_open)
	if  self.game_switch_is_open == 1 then --游戏进入维护阶段
		if player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = enum.GAME_SERVER_RESULT_MAINTAIN,
					})
			log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
			return 14
		end
	end
	
	if not player:check_money_limit(self:get_room_limit()) then
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
function base_room:enter_room(player,reconnect)
	local guid = player.guid
	if player.disable == 1 then
		print("enter_room player is Freeaz force_exit")
		return enum.GAME_SERVER_RESULT_FREEZEACCOUNT
	end

	log.info("base_room:enter_room,game_name = [%s],game_id =[%s],guid:%s,reconnect:%s,online:%s",
		def_game_name,def_game_id,guid,reconnect,player.online)

	if reconnect then
		local s = onlineguid[guid]
		log.info("base_room:enter_room %s,game_id:%s,reconnect:%s,table:%s,chair:%s",
			guid,def_game_id,reconnect,s.table,s.chair)
		
		reddb:hmset("player:online:guid:"..tostring(guid),{
			first_game_type = def_first_game_type,
			second_game_type = def_second_game_type,
			server = def_game_id,
		})

		player.table_id = s.table
		player.chair_id = s.chair
		player.active = true
		player.online = true
	else
		self:player_login_server(player)
	end

	return enum.GAME_SERVER_RESULT_SUCCESS
end

function base_room:enter_server(player,reconnect)
	local guid = player.guid
	log.info("base_room:enter_server game_id:%s server:%s,guid:%s,reconnect:%s,online:%s",
		def_first_game_type,def_game_id,guid,reconnect,player.online)
	return self:enter_room(player,reconnect)
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

function base_room:kickout_room(player,reason)
	return player:lockcall(function()
		local guid = player.guid
		if not player.online then
			log.error("base_room:kickout_room guid[%d],reason:%s double check failed.",
				guid,reason)
			return enum.GAME_SERVER_RESULT_SUCCESS
		end

		if common.is_in_lobby() then
			self:player_logout_server(player)
			return enum.GAME_SERVER_RESULT_SUCCESS
		end

		local table_id = player.table_id
		local chair_id = player.chair_id
		log.info("base_room:kickout_room guid[%d],table_id:%s,chair_id:%s,reason:%s",
			guid,table_id,chair_id,reason)
		-- double check,检查玩家已经退出了，还在执行kickout
		if not table_id or not chair_id then
			log.warning("base_room:kickout_room,player:%s table_id:%s or chair_id:%s is nil,exit.",guid,table_id,chair_id)
			return enum.GAME_SERVER_RESULT_SUCCESS
		end

		local tb = self:find_table_by_player(player)
		if not tb then
			log.warning("base_room:kickout_room not found table:%s,guid:%s",table_id,guid)
			self:player_kickout_room(player)
			return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		end

		return tb:lockcall(function()
			reason = reason or enum.STANDUP_REASON_NORMAL
			local result = tb:player_stand_up(player,reason)
			log.info("base_room:kickout_room,guid[%d] player_stand_up,table_id:%s,can_leave[%s] reason[%s]",guid,table_id,result,reason)
			if result ~= enum.ERROR_NONE then
				return result
			end

			self:player_kickout_room(player)

			return enum.GAME_SERVER_RESULT_SUCCESS
		end)
	end)
end

function base_room:kickout_server(player,reason)
	local guid = player.guid
	-- double check
	if not player.online then
		log.error("base_room:kickout_server %s double check failed.",guid)
		return enum.GAME_SERVER_RESULT_SUCCESS
	end

	if common.is_in_lobby() then
		self:player_kickout_server(player)
		return enum.GAME_SERVER_RESULT_SUCCESS
	end

	local table_id = player.table_id
	local chair_id = player.chair_id
	log.info("base_room:kickout_server guid[%d],table_id:%s,chair_id:%s,reason:%s",
			guid,table_id,chair_id,reason)
	-- double check,检查已经退出了还在执行kickout
	if not table_id or not chair_id then
		log.warning("base_room:kickout_server,player:%s table_id:%s or chair_id:%s is nil,exit.",guid,table_id,chair_id)
		return enum.GAME_SERVER_RESULT_SUCCESS
	end

	local tb = self:find_table_by_player(player)
	if not tb then
		log.warning("base_room:kickout_server not found table:%s,guid:%s",table_id,guid)
		self:player_kickout_server(player)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	return tb:lockcall(function()
		reason = reason or enum.STANDUP_REASON_NORMAL
		local result = tb:player_stand_up(player,reason)
		log.info("base_room:kickout_server,guid[%d] player_stand_up,table_id:%s,reason[%s],result[%s]",guid,table_id,reason,result)
		if result ~= enum.ERROR_NONE then
			return result
		end

		self:player_kickout_server(player)

		return enum.GAME_SERVER_RESULT_SUCCESS
	end)
end

function base_room:exit_room(player,reason)
	local guid = player.guid
	local online = player.online

	-- double check
	if not online then
		log.error("base_room:exit_room double check failed,%s",guid)
		return enum.ERROR_NONE
	end

	if common.is_in_lobby() then
		self:player_logout_server(player)
		return enum.ERROR_NONE
	end

	local table_id = player.table_id
	local chair_id = player.chair_id
	log.info("base_room:exit_room guid[%d],table_id:%s,chair_id:%s,reason:%s",
		guid,table_id,chair_id,reason)
	if not table_id or not chair_id then
		log.warning("base_room:exit_room,player:%s table_id:%s or chair_id:%s is nil,exit.",guid,table_id,chair_id)
		return enum.GAME_SERVER_RESULT_SUCCESS
	end

	local tb = self:find_table_by_player(player)
	if not tb then
		log.warning("base_room:exit_room not found table:%s,guid:%s",table_id,guid)
		self:player_exit_room(player)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	return tb:lockcall(function()
		reason = reason or enum.STANDUP_REASON_NORMAL
		local result = tb:player_stand_up(player,reason)
		log.info("base_room:exit_room,guid[%d] player_stand_up,table_id:%s,reason[%s],result %s,",
			guid,table_id,reason,result)
		if result ~= enum.ERROR_NONE then
			return result
		end

		self:player_exit_room(player)

		return enum.GAME_SERVER_RESULT_SUCCESS
	end)
end

-- 退出服务器
function base_room:exit_server(player,offline)
	local guid = player.guid
	local online = player.online
	
	-- double check
	if not online then
		log.error("base_room:exit_server double check failed,%s",guid)
		return enum.ERROR_NONE
	end

	if common.is_in_lobby() then
		self:player_logout_server(player)
		return enum.GAME_SERVER_RESULT_SUCCESS
	end

	local table_id = player.table_id
	local chair_id = player.chair_id
	log.info("base_room:exit_server guid[%d],table_id:%s,chair_id:%s,offline:%s",
		guid,table_id,chair_id,offline)
	
	if not table_id or not chair_id then
		log.warning("base_room:exit_server,player:%s table_id:%s or chair_id:%s is nil,exit.",guid,table_id,chair_id)
		return enum.GAME_SERVER_RESULT_SUCCESS
	end

	local tb = self:find_table_by_player(player)
	if not tb then
		log.warning("base_room:exit_server not found table:%s,guid:%s",table_id,guid)
		self:player_exit_room(player,offline)
		return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	return tb:lockcall(function()
		local reason = offline and enum.STANDUP_REASON_OFFLINE or enum.STANDUP_REASON_NORMAL
		local result = tb:player_stand_up(player,reason)
		log.info("base_room:exit_server,guid[%d] player_stand_up,table_id:%s,reason[%s],result [%s]",
			guid,table_id,reason,result)
		if result ~= enum.ERROR_NONE then
			return result
		end

		if offline then
			self:player_logout_server(player)
		else
			self:player_exit_room(player,offline)
		end

		return enum.GAME_SERVER_RESULT_SUCCESS
	end)
end

-- 快速坐下
function base_room:auto_sit_down(player)
	if player.disable == 1 then
		print("auto_sit_down player is Freeaz force_exit")
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
		print("sit_down player is Freeaz force_exit")
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

-- 玩家进入房间
function base_room:player_enter_room(player)
	self.players[player.guid] = player
	log.info("base_room:player_enter_room, guid %s,game_id %s,room_id %s",
	player.guid,def_first_game_type,def_game_id)

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
	local guid = player.guid
	-- double check
	if not player.online then
		log.error("base_room:player_exit_room guid %s,game_id %s,room_id %s nil session.",
			guid,def_first_game_type,def_game_id)
		return
	end
	
	log.info("base_room:player_exit_room, guid %s, room_id %s,online:%s",guid,def_game_id,player.online)
	if not player.active or offline then
		self:player_logout_server(player)
		return
	end

	if common.is_player_in_lobby(guid) then
		log.info("base_room:player_exit_room, already in lobby guid %s, room_id %s,online:%s",
			guid,def_game_id,player.online)
		return true
	end

	common.switch_to_lobby(guid)

	log.info("base_room:player_exit_room  %s,%s,%s.",guid,def_first_game_type,def_game_id)
	player_context[guid] = nil
	onlineguid[guid] = nil
	self.players[guid] = nil
end

function base_room:player_kickout_room(player)
	local guid = player.guid
	-- double check
	if not player.online then
		log.error("base_room:player_kickout_room guid %s,game_id %s,room_id %s nil session.",
			guid,def_first_game_type,def_game_id)
		return
	end
	
	log.info("base_room:player_kickout_room, guid %s, room_id %s,active:%s",guid,def_game_id,player.active)
	if player.active and not common.is_in_lobby() then
		if common.is_player_in_lobby(guid) then
			log.info("base_room:player_kickout_room, already in lobby guid %s, room_id %s,active:%s",
				guid,def_game_id,player.active)
			return true
		end

		common.switch_to_lobby(guid)

		log.info("base_room:player_kickout_room  %s,%s,%s.",guid,def_first_game_type,def_game_id)
		self.players[guid] = nil
		player_context[guid] = nil
		onlineguid[guid] = nil
	else
		self:player_exit_room(player)
	end
end

function base_room:player_login_server(player)
	local guid = player.guid
	player.online = true
	player.active = true
	reddb:hmset("player:online:guid:"..tostring(guid),{
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		server = def_game_id,
	})

	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		1,def_game_id)
	reddb:incr("player:online:count")

	local clubs = table.merge(player_club[guid][enum.CT_UNION],player_club[guid][0])
	for club_id in pairs(clubs) do
		reddb:sadd(string.format("club:member:online:guid:%s",club_id),guid)
		reddb:incr(string.format("club:member:online:count:%s",club_id))
	end

	self.players[guid] = player

	log.info("base_room:player_login_server  %s,%s.",def_first_game_type,def_game_id)
end

function base_room:player_logout_server(player)
	local guid = player.guid
	-- double check
	if not player.online then
		log.error("base_room:player_logout_server guid %s,game_id %s,room_id %s nil session.",
			guid,def_first_game_type,def_game_id)
		return
	end

	self.players[guid] = nil

	log.info("base_room:player_logout_server guid %s,game_id %s,room_id %s.",
		guid,def_first_game_type,def_game_id)

	if not allonlineguid[guid] then
		log.info("base_room:player_logout_server guid %s,game_id %s,room_id %s,got nil online session",
			guid,def_first_game_type,def_game_id)
		player_context[guid] = nil
		onlineguid[guid] = nil
		return
	end

	reddb:srem("player:online:all",guid)
	reddb:del("player:online:guid:"..tostring(guid))
	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		-1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		-1,def_game_id)
	reddb:decr("player:online:count")

	reddb:hset(string.format("player:info:%d",guid),"logout_time",os.time())

	local clubs = table.merge(player_club[guid][enum.CT_UNION],player_club[guid][enum.CT_DEFAULT])
	for club_id in pairs(clubs) do
		reddb:srem(string.format("club:member:online:guid:%s",club_id),guid)
		reddb:decr(string.format("club:member:online:count:%s",club_id))
	end

	player_context[guid] = nil
	onlineguid[guid] = nil
	allonlineguid[guid] = nil

	channel.call("queue.?","lua","Quit",guid)
	
	channel.publish("db.?","msg","S_Logout", {
		account = player.account,
		guid = guid,
		login_time = player.login_time,
		logout_time = os.time(),
		phone = player.phone,
		phone_type = player.phone_type,
		version = player.version,
		channel_id = player.channel_id,
		package_name = player.package_name,
		imei = player.imei,
		ip = player.ip,
	})
end

function base_room:player_kickout_server(player)
	local guid = player.guid
	-- double check
	if not player.online then
		log.error("base_room:player_kickout_server guid %s,game_id %s,room_id %s double check failed.",
			guid,def_first_game_type,def_game_id)
		return
	end

	log.info("base_room:player_kickout_server, guid %s, room_id %s",guid,def_game_id)

	local os = onlineguid[guid]

	self:player_logout_server(player)

	if os and os.gate then
		channel.call("gate."..tostring(os.gate),"lua","kickout",guid)
	else
		log.warning("base_room:player_kickout_server got nil gate server,maybe offlined.")
	end
end

function base_room:find_free_tables(club_id,temp_id)
	return table.select(self.tables,function(tb,id)
		if club_id and tb.club_id ~= club_id then return end

		if tb.chair_count <= tb:get_player_count() then return end

		if temp_id then
			local ptb = base_private_table[tb:id()]
			if not ptb or ptb.template ~= temp_id then return end
		end
		return tb
	end,true)
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
		print("change_table player is Freeaz force_exit")
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

function base_room:check_room_fee(rule,club,player)
	if game_util.is_private_fee_free(club) then
		log.warning("check_create_table_limit room fee switch is closed.")
		return enum.ERROR_NONE
	end

	local payopt = rule.pay.option
	local roomfee = self:get_private_fee(rule)
	if payopt == enum.PAY_OPTION_AA or payopt == enum.PAY_OPTION_ROOM_OWNER then
		if player:check_money_limit(roomfee,0) then
			return enum.ERROR_LESS_ROOM_CARD
		end
	elseif payopt == enum.PAY_OPTION_BOSS then
		if not club then 
			return enum.ERROR_PARAMETER_ERROR
		end
		
		local root = club_utils.root(club)
		if not root then 
			return enum.ERROR_PARAMETER_ERROR
		end

		local boss = player_data[root.owner]
		if boss:check_money_limit(roomfee,0) then
			return enum.ERROR_LESS_ROOM_CARD
		end
	end

	return enum.ERROR_NONE
end

function base_room:reloadconf()
	local sconf = channel.call("config.?","msg","query_service_conf",def_game_id)
	self.conf = sconf.conf
end

return base_room