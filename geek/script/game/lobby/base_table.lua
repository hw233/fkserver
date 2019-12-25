-- 桌子基类

local pb = require "pb_files"

require "game.net_func"
local log = require "log"
require "table_func"
local enum = require "pb_enums"
require "msgopt"
local base_players = require "game.lobby.base_players"
local base_private_table = require "game.lobby.base_private_table"
local redisopt = require "redisopt"
local club_table = require "game.club.club_table"
local base_clubs = require "game.club.base_clubs"
local timer_manager = require "game.timer_manager"
local onlineguid = require "netguidopt"

local reddb = redisopt.default

local dismiss_timeout = 30

-- local base_prize_pool = require "game.lobby.base_prize_pool"
-- 奖池
-- global_prize_pool = global_prize_pool or base_prize_pool:new()

local base_table = {}
-- 创建
function base_table:new()
    local o = {}
    setmetatable(o, {__index = self})

    return o
end

-- 获取当前游戏ID
function base_table:get_now_game_id()
	local guid = string.format([[%03d%03d%04d%s%07d]], def_game_id, self.room_.id, self.table_id_, self.ID_date_,self.table_gameid)
	log.info(guid)
	return guid
end

-- 刷新游戏ID到下一个
function base_table:next_game()
	self.ID_date_ = os.date("%y%m%d%H%M")
	self.table_gameid = self.table_gameid + 1
end

function base_table:start_save_info()
	log.info("===============start_save_info")
	for _,v in ipairs(self.players) do
		-- 添加游戏场次
		v:inc_play_times()
		-- 记录对手
		v:set_player_ip_control(self.players)
	end
	log.info("===============start_save_info end")
end

function base_table:can_enter(player)
	log.info("base_table:can_enter")
	return true
end

function base_table:clear()
	self:clear_private()
	self:clear_ready()
end

-- 初始化
function base_table:init(room, table_id, chair_count)
	self.table_gameid = 1
	self.room_ = room
	self.table_id_ = table_id
	self.chair_count = chair_count
	self.def_game_name = def_game_name
	self.def_game_id = def_game_id
	self.game_end_event = {}
	self.players = {}
	self.ID_date_ = os.date("%y%m%d%H%M")
	self.config_id = room.config_id
	self.tax_show_ = room.tax_show -- 是否显示税收信息
	self.tax_open_ = room.tax_open -- 是否开启税收
	self.tax_ = room.tax

	self.room_limit = room.room_limit -- 房间分限制
	self.cell_score = room.cell_score -- 底注
	self.game_switch_is_open = room.game_switch_is_open
	self.ready_list = {}

	self.notify_msg = {}
	if self.tax_show_ == 1 then
		self.notify_msg.flag = 3
	else
		self.notify_msg.flag = 4
	end
end

function base_table:is_play( ... )
	log.info("base_table:is_play")
	return false
end

function base_table:load_lua_cfg( ... )
	log.info("base_table:load_lua_cfg")
	return false
end

function base_table:get_chair_count()
	return self.chair_count
end

function base_table:get_free_chair_id()
	if table.nums(self.players) >= self.chair_count then
		return nil
	end

	return #self.players + 1
end

function base_table:request_dismiss(player)
	local timer = timer_manager:new_timer(dismiss_timeout,function()
		self:foreach(function(p)
			self:commit_dismiss(p,false)
		end)
	end)
	self.dismiss_request = {
		commissions = {},
		requester = player,
		datetime = os.time(),
		timer = timer,
	}

	self.dismiss_request.commissions[player.chair_id] = true

	self:broadcast2client("SC_DismissTableReq",{
		result = enum.ERROR_NONE,
		request_guid = player.guid,
		request_chair_id = player.chair_id,
		datetime = os.time(),
		timeout = dismiss_timeout,
	})

	self:broadcast2client("SC_DismissTableCommit",{
		result = enum.ERROR_NONE,
		chair_id = player.chair_id,
		guid = player.guid,
		agree = true,
	})

	return enum.ERROR_NONE
end

function base_table:commit_dismiss(player,agree)
	if not self.dismiss_request then
		log.error("commit dismiss but not dismiss request,guid:%d,agree:%s",player.guid,agree)
		return
	end

	local commissions = self.dismiss_request.commissions
	agree = agree and agree == true or false

	if not agree then
		self:broadcast2client("SC_DismissTable",{success = false,})
		return enum.ERROR_NONE
	end

	commissions[player.chair_id] = agree and agree == true or false

	self:broadcast2client("SC_DismissTableCommit",{
		chair_id = player.chair_id,
		guid = player.guid,
		agree = agree and agree == true,
	})

	if table.logic_and(self.players,function(p) return not p.online or commissions[p.chair_id] ~= nil end)
	then
		self.dismiss_request.timer:kill()
		self.dismiss_request.timer = nil
		self.dismiss_request = nil
	end

	if not table.logic_and(self.players,function(p) return commissions[p.chair_id] end)
	then
		return enum.ERROR_NONE
	end

	local result = self:dismiss()
	if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
		return result
	end

	self:foreach(function(p)
		p:forced_exit()
	end)

	return enum.ERROR_NONE
end

function base_table:on_game_over()
	self:check_game_maintain()
end

-- 得到玩家
function base_table:get_player(chair_id)
	if not chair_id then
		return nil
	end
	return self.players[chair_id]
end

-- 设置玩家
function base_table:set_player(chair_id, player)
	self.players[chair_id] = player
end

-- 得到玩家列表
function base_table:get_player_list()
	return self.players
end

--用户数量
function base_table:get_player_count()
	local count = 0
	for _,_ in pairs(self.players) do
		count = count + 1
	end
	return count
end

-- 遍历桌子
function base_table:foreach(func)
	for _, p in pairs(self.players) do
		func(p)
	end
end

function base_table:foreach_except(except, func)
	for i, p in pairs(self.players) do
		if i ~= except then
			func(p)
		end
	end
end

function  base_table:save_game_log(s_playid,s_playType,s_log,s_starttime,s_endtime)
	log.info("==============================base_table:save_game_log")
	local nMsg = {
		playid = s_playid,
		type = s_playType,
		log = s_log,
		starttime = s_starttime,
		endtime = s_endtime,
	}
	send2db_pb("SL_Log_Game",nMsg)
end

function base_table:player_money_log(player,s_type,s_old_money,s_tax,s_change_money,s_id,get_bonus_money_,to_bonus_money_)
	local nMsg = {
		guid = player.guid,
		type = s_type,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		phone_type = player.phone_type,
		old_money = s_old_money,
		new_money = player.money,
		tax = s_tax,
		change_money = s_change_money,
		ip = player.ip,
		id = s_id,
		channel_id = player.create_channel_id,
		platform_id = player.platform_id,
		get_bonus_money = get_bonus_money_ or 0,
		to_bonus_money = to_bonus_money_ or 0,
		seniorpromoter = player.seniorpromoter,
	}
	send2db_pb("SL_Log_Money",nMsg)
	send2client_pb(player,"SC_Gamefinish",{
		money = player.money
	})
end

function base_table:player_bet_flow_log(player,money)
	if not player.is_player then return end

	if money <= 0 then return end

	local msg = {
		guid = player.guid,
		account = player.account,
		money = money
	}

	send2db_pb("SD_LogBetFlow",msg)
end

function base_table:player_money_log_when_gaming(player,s_type,s_old_money,s_tax,s_change_money,s_id,get_bonus_money_,to_bonus_money_)
	local nMsg = {
		guid = player.guid,
		type = s_type,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		phone_type = player.phone_type,
		old_money = s_old_money,
		new_money = player.money,
		tax = s_tax,
		change_money = s_change_money,
		ip = player.ip,
		id = s_id,
		channel_id = player.create_channel_id,
		platform_id = player.platform_id,
		get_bonus_money = get_bonus_money_ or 0,
		to_bonus_money = to_bonus_money_ or 0,
		seniorpromoter = player.seniorpromoter,
	}
	send2db_pb("SL_Log_Money",nMsg)
end

function base_table:do_player_money_log(player, s_type,s_old_money,s_tax,s_change_money,s_id,get_bonus_money_,to_bonus_money_)
	local nMsg = {
		guid = player.guid,
		type = s_type,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		phone_type = player.phone_type,
		old_money = s_old_money,
		new_money = player.money,
		tax = s_tax,
		change_money = s_change_money,
		ip = player.ip,
		id = s_id,
		channel_id = player.channel_id,
		platform_id = player.platform_id,
		get_bonus_money = get_bonus_money_,
		to_bonus_money = to_bonus_money_,
		seniorpromoter = player.seniorpromoter,
	}
	send2db_pb("SL_Log_Money",nMsg)
end

function base_table:robot_money_log(robot,banker_flag,winorlose,old_money,tax,money_change,table_id)
	log.info("==============================base_table:robot_money_log")
	local nMsg = {
		guid = robot.guid,
		isbanker = banker_flag,
		winorlose = winorlose,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		old_money = old_money,
		new_money = robot.money,
		tax = tax,
		money_change = money_change,
		id = table_id,
	}
	send2db_pb("SL_Log_Robot_Money",nMsg)
end

--渠道税收分成
function base_table:channel_invite_taxes(channel_id_p,guid_p,guid_invite_p,tax_p)
	log.info("ChannelInviteTaxes channel_id:" .. channel_id_p .. " guid:" .. guid_p .. " guid_invite:" .. tostring(guid_invite_p) .. " tax:" .. tax_p)
	if tax_p == 0 or guid_invite_p == nil or guid_invite_p == 0 then
		return
	end
	local cfg = channel_invite_cfg(channel_id_p)
	if cfg and cfg.is_invite_open == 1 then
		log.info("ChannelInviteTaxes step 2--------------------------------")
		local nMsg = {
			channel_id = channel_id_p,
			guid = guid_p,--贡献者
			guid_invite = guid_invite_p,--受益者
			val = math.floor(tax_p*cfg.tax_rate/100)
		}
		send2db_pb("SL_Channel_Invite_Tax",nMsg)
	end
end


-- 广播桌子中所有人消息
function base_table:broadcast2client(msg_name, msg)
	self:foreach(function(p) 
		if p.online and p.in_game then
			send2client_pb(p, msg_name, msg)
		end
	end)
end

function base_table:broadcast2client_except(except, msg_name, msg)
	self:foreach_except(except,function(p)
		send2client_pb(p, msg_name, msg)
	end)
end

-- 玩家坐下
function base_table:player_sit_down(player, chair_id)
	player.table_id = self.table_id_
	player.chair_id = chair_id
	self.players[chair_id] = player
	log.info("base_table:player_sit_down, guid %s, table_id %s, chair_id %s",
			player.guid,player.table_id,player.chair_id)
	if player.is_player then
		for i, p in ipairs(self.players) do
			if p == false then
				-- 主动机器人坐下
				player:on_notify_android_sit_down(def_game_id, self.table_id_, i)
			end
		end
	end

	reddb:hmset("player:online:guid:"..tostring(player.guid),{
		table = self.table_id_,
		chair = chair_id,
	})

	if self.private_id then
		local priv_tb = base_private_table[self.private_id]
		if priv_tb and priv_tb.club_id then
			local club = base_clubs[priv_tb.club_id]
			if club then
				club:broadcast("S2C_SYNC_TABLES_RES",{
					club_id = club.id,
					room_info = self:global_status_info(),
					sync_table_id = self.private_id,
					sync_type = enum.SYNC_UPDATE,
				})
			end
		end
	end

	onlineguid[player.guid] = nil
end

function base_table:player_sit_down_finished(player)
	return
end

--处理掉线玩家
function base_table:player_offline(player)
	log.info("base_table:player_offline set player[%d] in_game false" ,player.guid)
	player.in_game = false
end

function base_table:dismiss()
	if not self.conf or not self.private_id then
		log.warning("dismiss non-private table,real_table_id:%s",self.table_id)
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
	end

	log.info("base_table:dismiss %s,%s",self.private_id,self.table_id_)
	local private_table_conf = base_private_table[self.private_id]
	dump(private_table_conf)
	local club_id = private_table_conf.club_id
	local private_table_id = private_table_conf.table_id
	local private_table_owner = private_table_conf.owner
	reddb:del("table:info:"..private_table_id)
	reddb:del("player:table:"..private_table_owner)
	if club_id then
		reddb:srem("club:table:"..club_id,private_table_id)
		club_table[club_id][private_table_id] = nil
		local club = base_clubs[club_id]
		if club then
			club:broadcast("S2C_SYNC_TABLES_RES",{
				club_id = club_id,
				sync_type = enum.SYNC_DEL,
				sync_table_id = private_table_id,
			})
		else
			log.warning("dismiss table %s,club %s not exists.",private_table_id,club_id)
		end
	end

	base_private_table[self.private_id] = nil
	self:broadcast2client("SC_DismissTable",{success = true,})
	self:clear()

	self.private_id = nil
	self.conf = nil

	return enum.GAME_SERVER_RESULT_SUCCESS
end

function base_table:transfer_owner()
	log.info("transfer owner:%s,%s",self.conf.private_id,self.conf.owner)
	if not self.conf or not self.private_id then
		log.warning("dismiss non-private table,real_table_id:%s",self.table_id)
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
	end

	local function next_player(owner)
		local chair_id = owner.chair_id
		local chair_count = self.chair_count
		for i = chair_id,chair_id + chair_count - 2 do
			local p = self.players[i % chair_count + 1]
			if p then
				return p
			end
		end

		return nil
	end

	local private_conf = self.conf
	local private_table_id = self.private_id
	local old_owner = private_conf.owner
	local new_owner = next_player(old_owner)
	if not new_owner then
		log.warning("base_table:transfer_owner %s,%s,old:%s, new owner not found",self.private_id,self.table_id_,old_owner.guid)
		return enum.GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR
	end

	log.info("base_table:transfer_owner %s,%s,old:%s,new:%s",self.private_id,self.table_id_,old_owner.guid,new_owner.guid)
	reddb:srem("player:table:"..old_owner.guid,private_table_id)
	reddb:hset("table:info:"..private_table_id,"owner",new_owner.guid)
	reddb:sadd("player:table:"..new_owner.guid,private_table_id)
	reddb:expire("player:table:"..new_owner.guid,dismiss_timeout)
	base_private_table[self.private_id] = nil

	self:broadcast2client("S2C_TRANSFER_ROOM_OWNER_RES",{
		table_id = self.private_id,
		old_owner = old_owner.guid,
		new_owner = new_owner.guid,
	})

	return enum.GAME_SERVER_RESULT_SUCCESS
end

-- 玩家站起
function base_table:player_stand_up(player, reason)
	log.info("GameInOutLog,base_table:player_stand_up, guid %s, table_id %s, chair_id %s, reason %s",
			player.guid,player.table_id,player.chair_id,reason)

	if reason == enum.STANDUP_REASON_OFFLINE then
		log.info ("is_offline is true")
	else
		log.info ("is_offline is false")
	end

	if self:check_cancel_ready(player, reason) then
		log.info("base_table:player_stand_up set true")
		local chairid = player.chair_id
		local p = self.players[chairid]
		local list_guid = p and p.guid or -1
		log.info("set guid[%s] table_id[%s] players[%d] is false [ player_list is %s , player_list.guid [%s]]",
			player.guid,player.table_id,chairid , self.players[chairid], list_guid)

		if self.ready_list[chairid] then
			self.ready_list[chairid] = nil
			self:broadcast2client("SC_Ready", {
				ready_chair_id = chairid,
				is_ready = false,
			})
		end

		if self.private_id and player == self.conf.owner then
			self:transfer_owner()
		end

		self.players[chairid] = nil
		player.table_id = nil
		player.chair_id = nil

		if self.private_id then
			local priv_tb = base_private_table[self.private_id]
			if priv_tb and priv_tb.club_id then
				local club = base_clubs[priv_tb.club_id]
				if club then
					club:broadcast("S2C_SYNC_TABLES_RES",{
						club_id = club.id,
						room_info = self:global_status_info(),
						sync_table_id = self.private_id,
						sync_type = enum.SYNC_UPDATE,
					})
				end
			end
		end

		if self.private_id and table.nums(self.players) == 0 then
			self:dismiss()
		end

		reddb:hdel("player:online:guid:"..tostring(player.guid),"table")
		reddb:hdel("player:online:guid:"..tostring(player.guid),"chair")
		onlineguid[player.guid] = nil
		return true
	end

	log.info("guid %s,reason %s",player.guid,reason)
	if reason == enum.STANDUP_REASON_OFFLINE then
		log.info("set player is_offline true")
		player.is_offline = true -- 掉线了
	end
	return false
end

function base_table:set_trusteeship(player)
	log.info("====================base_table:set_trusteeship")
end

-- 准备开始
function base_table:ready(player)
	if player.disable == 1 then
		--当玩家处理冻结状态时
		player:forced_exit()
		return
	end

	if not self:check_ready(player) then
		return
	end

	if not player.table_id then
		log.warning("guid[%d] not find in table", player.guid)
		return
	end

	if not player.chair_id then
		log.warning("guid[%d] not find in chair_id", player.guid)
		return
	end

	local ready_mode = self.room_:get_ready_mode()
	if ready_mode == enum.GAME_READY_MODE_NONE then
		log.warning("guid[%d] mode=GAME_READY_MODE_NONE", player.guid)
		return
	end

	if self.ready_list[player.chair_id] then
		log.warning("chair_id[%d] ready error,guid[%d]", player.chair_id,player.guid)
		return
	end

	log.info("set tableid [%d] chair_id[%d]  ready_list is %s ",self.table_id_,player.chair_id,player.guid)
	self.ready_list[player.chair_id] = player

	-- 机器人准备
	self:foreach(function(p)
		if p.is_android and (not self.ready_list[p.chair_id]) then
			self.ready_list[p.chair_id] = p

			local notify = {
				ready_chair_id = p.chair_id,
				is_ready = true,
				}
			self:broadcast2client("SC_Ready", notify)
		end
	end)

	log.info("set droped false")
	player.droped = false
	-- 通知自己准备
	local notify = {
		ready_chair_id = player.chair_id,
		is_ready = true,
		}
	self:broadcast2client("SC_Ready", notify)

	self:check_start(false)
end

function base_table:reconnect(player)
	-- 重新上线
	log.info("---------base_table:reconnect,%s-----------",player.guid)
	log.info("set Dropped is false")
	player.droped = false
	log.info("set online is true")
	player.online = true
	log.info("set player[%d] in_game true" ,player.guid)
	player.in_game = true
end

-- 检查是否可准备
function base_table:check_ready(player)
	return true
end

-- 检查是否可取消准备
function base_table:check_cancel_ready(player, reason)
	if reason == enum.STANDUP_REASON_OFFLINE then
		--掉线 用于结算
		log.info("set Dropped true")
		player.droped = true
	end
	return self.room_:get_ready_mode() ~= enum.GAME_READY_MODE_NONE
end

-- 检查开始
function base_table:check_start(part)
	local ready_mode = self.room_:get_ready_mode()
	log.info("ready_mode %s,%s",ready_mode,part)
	if ready_mode == enum.GAME_READY_MODE_PART then
		local n = table.nums(self.ready_list)
		if n >= 2 then
			self:start(n)
		end
	end

	if part then
		return
	end

	if ready_mode == enum.GAME_READY_MODE_ALL then
		local n = table.nums(self.ready_list)
		if n ~= self.chair_count  then
			return
		end

		self:start(n)
	end
end

function base_table:send_playerinfo(player)
	return true
end

function base_table:send_info_to_player(player)
	
end

-- 开始游戏
function base_table:start(player_count)
	log.info("base_table:start %s,%s",self.chair_count,player_count)
	local result_ = self:check_single_game_is_maintain()
	if result_ == true then
		log.info("game is maintain cant start roomid[%d] tableid[%d]" ,self.room_.id, self.table_id_)
		return nil
	end

	local ret = false
	if self.config_id ~= self.room_.config_id then
		log.info ("-------------configid:",self.config_id ,self.room_.config_id)
		log.info (self.room_.tax_show_, self.room_.tax_open_ , self.room_.tax_)
		self.tax_show_ = self.room_.tax_show_ -- 是否显示税收信息
		self.tax_open_ = self.room_.tax_open_ -- 是否开启税收
		self.tax_ = self.room_.tax_
		self.room_limit = self.room_.room_limit -- 房间分限制
		self.cell_score = self.room_.cell_score -- 底注
		self.game_switch_is_open = self.room_.game_switch_is_open

		if self.tax_show_ == 1 then
			self.notify_msg.flag = 3
		else
			self.notify_msg.flag = 4
		end

		self.config_id = self.room_.config_id

		ret = true
		log.info ("self.room_.room_cfg --------" ,self.room_.room_cfg )
		if self.room_.room_cfg ~= nil then
			self:load_lua_cfg()
		end
	end

	self:broadcast2client("SC_ShowTax", self.notify_msg)
	return ret
end

function base_table:round_over()

end

-- 检查是否维护
function base_table:check_game_maintain()
	if game_switch == 1 then--游戏将进入维护阶段
		log.warning("All Game will maintain..game_switch=[%d].....................",game_switch)
		for i,v in pairs (self.players) do
			if v.is_player == true and v.vip ~= 100 then
				send2client_pb(v, "SC_GameMaintain", {
					result = enum.GAME_SERVER_RESULT_MAINTAIN,
				})
				v:forced_exit()
			end
		end
		return true
	end
	return false
end

--准备玩家通知维护
function base_table:on_notify_ready_player_maintain(player)
	if game_switch == 1 and player.vip ~= 100 then--游戏将进入维护阶段
		send2client_pb(player, "SC_GameMaintain", {
		result = enum.GAME_SERVER_RESULT_MAINTAIN,
		})
		player:forced_exit()
		return true
	end
	return false
end

-- 清除准备
function base_table:clear_ready()
	self.ready_list = {}
end

-- 心跳
function base_table:tick()

end

function base_table:private_init(conf)
	self.rule = conf.rule
	self.chair_count = conf.chair_count
	self.money_type = conf.money_type
	self.conf = conf
end

function base_table:clear_private()
	self.rule = nil
	self.conf = nil
	self.private_id = nil
end

function base_table:destroy_private_room(b)
	if b and self.private_id then
		local player = base_players[self.private_room_owner_guid]
		if player  then
			player:change_money(self.private_room_chair_count * self.private_room_score_type, LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM)
		end
	end
	self.private_id = nil
end

-- 检查单个游戏维护
function base_table:check_single_game_is_maintain()
	self:game_end()
	local iRet = false
	self.def_game_name = def_game_name
	self.def_game_id = def_game_id
	if self.room_.game_switch_is_open == 1 or game_switch == 1 then--游戏将进入维护阶段
		log.warning("game_name = [%s] gameid = [%d] game_switch_is_open[%d] get_db_status[%d] game_switch[%d] will maintain.....................",self.def_game_name,self.def_game_id,self.room_.game_switch_is_open,get_db_status(),game_switch)
		iRet = self:send_maintain_player()
		log.warning("game_name = [%s] gameid = [%d] game_switch_is_open[%d] get_db_status[%d] game_switch[%d] will maintain ret(%s).....................",self.def_game_name,self.def_game_id,self.room_.game_switch_is_open,get_db_status(),game_switch,tostring(iRet))
	end
	return iRet
end

function base_table:send_maintain_player()
	local iRet = false
	for i,v in pairs (self.players) do
		if  v.is_player == true and v.vip ~= 100 then
			send2client_pb(v, "SC_GameMaintain", {
			result = GAME_SERVER_RESULT_MAINTAIN,
			})
			v:forced_exit()
			iRet = true
		end
	end
	return iRet
end

--检查玩家是否破产，是则返回ture，否则返回false
function check_player_is_collapse(var_platform,player_money,func)
	local reply = reddb:get(var_platform)
	if type(reply) == "string" then
		local result = false
		local collapse_value = tostring(reply)
		if player_money < tonumber(collapse_value) then
			result = true
		end

		func(result)
	else
		func(false)
	end
end
--玩家破产日志
function  base_table:save_player_collapse_log(player)
	if not player then
		return
	end
	local player_money = player:get_money()
	local player_bank_money = player:get_bank_money()
	log.info("save_player_collapse_log: player guid[%d],cur_money[%d] cur_bank[%d],player.channel_id[%s],player.platform_id[%s] platform_info[%s]",player.guid,player_money,player_bank_money,player.channel_id,player.platform_id,platform_info)

	--先判断身上的钱加上银行的钱是否小于该平台配置的默认值，若是则记录日志
	local player_money_total = player_money + player_bank_money
	local collapse_value = tonumber(reddb:get("platform:collapse_value:"..tostring(player.platform_id)))
	if collapse_value and player_money_total < collapse_value then
		log.info("player guid[%d] is collapse, player_money_total[%d] channel_id[%s] platform_id[%s]",player.guid,player_money_total,player.channel_id,player.platform_id)
		local nmsg = {
			guid = player.guid,
			channel_id = player.channel_id ,
			platform_id = player.platform_id,
		}
		send2db_pb("SD_SaveCollapseLog",nmsg)
	end
end

--检查玩家是否是黑名单列表玩家，若是则返回true，否则返回false
function base_table:check_blacklist_player( player_guid )
	return self.room_:check_player_is_in_blacklist(player_guid)
end

--游戏结算回调
function base_table:game_end()
	for _,guid in pairs(self.game_end_event) do
		local player = base_players[tonumber(guid)]
		if player then
			player:do_game_end_event()
		end
	end
	self.game_end_event = {}
end

function base_table:log( str , level , number)
	if not self.logLevel then
		log.info(str)
	elseif self.logLevel >= level then
		if number == nil then
			log.info("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline)
		else
			log.info("%s [%s][%s][%s]" , str , debug.getinfo(number).short_src , debug.getinfo(number).name , debug.getinfo(number).currentline)
		end
	else
		log.info(str)
	end
end

function base_table:log_important(str)
	if not self.logLevel then
		log.info("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline)
	else
		self:log(str,self.logLevel,3)
	end
end

function base_table:log_error_msg(str)
	log.error("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline)
end

function base_table:log_msg(str)
	self:log(str, 1 ,3)
end

function base_table:global_status_info(table_id)
	return {}
end

return base_table