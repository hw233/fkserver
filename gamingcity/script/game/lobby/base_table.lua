-- 桌子基类

local pb = require "pb"

require "game.net_func"
local get_msg_id_str = get_msg_id_str
local send2client_pb_str = send2client_pb_str
local send2client_pb = send2client_pb
local def_game_id = def_game_id
local def_game_name = def_game_name
local redis_cmd_query = redis_cmd_query
require "table_func"
local base_player = require "game.lobby.base_player"

local base_prize_pool = require "game.lobby.base_prize_pool"
-- 奖池
global_prize_pool = global_prize_pool or base_prize_pool:new()

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_IN_GAME = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
local GAME_SERVER_RESULT_IN_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER")
local GAME_SERVER_RESULT_PLAYER_NO_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_NO_CHAIR")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")

-- enum GAME_READY_MODE
local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")

local LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM")

local get_db_status = get_db_status

base_table = {}
-- 创建
function base_table:new()
    local o = {}
    setmetatable(o, {__index = self})

    return o
end

-- 获取当前游戏ID
function base_table:get_now_game_id()
	local guid = string.format([[%03d%03d%04d%s%07d]], def_game_id, self.room_.id, self.table_id_, self.ID_date_,self.table_gameid)
	print(guid)
	return guid
end
-- 刷新游戏ID到下一个
function base_table:next_game()
	self.ID_date_ = os.date("%y%m%d%H%M")
	self.table_gameid = self.table_gameid + 1
end
function base_table:start_save_info()
	-- body
	log.info("===============start_save_info")
	for _,v in ipairs(self.player_list_) do
		-- 添加游戏场次
		--log.info("===============startsaveInfo1")
		v:inc_play_times()
		-- 记录对手
		--log.info("===============startsaveInfo2")
		v:set_player_ip_control(self.player_list_)
		--log.info("===============startsaveInfo3")
	end
	log.info("===============start_save_info end")
end
function base_table:can_enter(player)
	-- body
	print("base_table:can_enter")
	return true
end
-- 初始化
function base_table:init(room, table_id, chair_count)
	self.table_gameid = 1
	self.room_ = room
	self.table_id_ = table_id
	self.def_game_name = def_game_name
	self.def_game_id = def_game_id
	self.game_end_event = {}
	self.player_list_ = {}
	self.player_guid_list_ = {}
	self.ID_date_ = os.date("%y%m%d%H%M")
	self.configid_ = room.configid_
	global_prize_pool:set_table_player_list(room.id , table_id , self.player_list_)
	self.tax_show_ = room.tax_show_ -- 是否显示税收信息
	self.tax_open_ = room.tax_open_ -- 是否开启税收
	self.tax_ = room.tax_

	self.room_limit_ = room.room_limit_ -- 房间分限制
	self.cell_score_ = room.cell_score_ -- 底注
	self.game_switch_is_open = room.game_switch_is_open

	for i = 1, chair_count do
		--print(string.format("set player_list_[%d] is false",i))
		self.player_list_[i] = false
	end
	if room:get_ready_mode() ~= GAME_READY_MODE_NONE then
		self.ready_list_ = {}
		for i = 1, chair_count do
			self.ready_list_[i] = false
		end
	end

	self.notify_msg = {}
	if self.tax_show_ == 1 then
		self.notify_msg.flag = 3
	else
		self.notify_msg.flag = 4
	end
end

function base_table:is_play( ... )
	print("base_table:is_play")
	-- body
	return false
end

function base_table:load_lua_cfg( ... )
	print("base_table:load_lua_cfg")
	-- body
	return false
end

-- 得到玩家
function base_table:get_player(chair_id)
	if not chair_id then
		return nil
	end
	return self.player_list_[chair_id]
end

-- 设置玩家
function base_table:set_player(chair_id, player)
	self.player_list_[chair_id] = player
	if player then
		self.player_guid_list_[chair_id] = player.guid
	else
		self.player_guid_list_[chair_id] = false
	end
end

-- 得到玩家列表
function base_table:get_player_list()
	return self.player_list_
end

--用户数量
function base_table:get_player_count()
	local count = 0
	for k,chair in pairs(self.player_list_) do
		if chair then
			count = count + 1
		end
	end
	return count
end

-- 遍历桌子
function base_table:foreach(func)
	for i, p in pairs(self.player_list_) do
		if p then
			func(p)
		end
	end
end
function base_table:foreach_except(except, func)
	for i, p in pairs(self.player_list_) do
		if p and i ~= except then
			func(p)
		end
	end
end
function  base_table:save_game_log(s_playid,s_playType,s_log,s_starttime,s_endtime)
	-- body
	print("==============================base_table:save_game_log")
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
		new_money = player.pb_base_info.money,
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
		money = player.pb_base_info.money
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
		new_money = player.pb_base_info.money,
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
	print("==============================base_table:robot_money_log")
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
function base_table:ChannelInviteTaxes(channel_id_p,guid_p,guid_invite_p,tax_p)
	print("ChannelInviteTaxes channel_id:" .. channel_id_p .. " guid:" .. guid_p .. " guid_invite:" .. tostring(guid_invite_p) .. " tax:" .. tax_p)
	if tax_p == 0 or guid_invite_p == nil or guid_invite_p == 0 then
		return
	end
	local cfg = channel_invite_cfg(channel_id_p)
	if cfg and cfg.is_invite_open == 1 then
		print("ChannelInviteTaxes step 2--------------------------------")
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
function base_table:broadcast2client(msg_name, pb)
	--print("send msg :"..msg_name)
	local id, msg = get_msg_id_str(msg_name, pb)
	for i, p in pairs(self.player_list_) do
		if p and type(p) == "table" and (p.is_android or not p.is_player) then
			send2client_pb(p,msg_name,pb)
		end
		if not p or p.is_android == true or p.noready == true then
			--print("no need broadcast2client:"..i)
		else
			if p.online and p.in_game then
				send2client_pb_str(p, id, msg)
			else
				if p.is_player == false then --非玩家(机器人)
					-- do nothing
				else
					print("p offline :"..p.chair_id)
				end
			end
		end
	end
end
function base_table:broadcast2client_except(except, msg_name, pb)
	local id, msg = get_msg_id_str(msg_name, pb)
	for i, p in ipairs(self.player_list_) do
		if p and i ~= except then
			send2client_pb_str(p, id, msg)
		end
	end
end

-- 玩家坐下
function base_table:player_sit_down(player, chair_id_)
	player.table_id = self.table_id_
	player.chair_id = chair_id_
	self.player_list_[chair_id_] = player
	global_prize_pool:into_game(player )
	log.info(string.format("GameInOutLog,base_table:player_sit_down, guid %s, table_id %s, chair_id %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id)))
	if player.is_player then
		for i, p in ipairs(self.player_list_) do
			if p == false then
				-- 主动机器人坐下
				player:on_notify_android_sit_down(player.room_id, self.table_id_, i)
			end
		end
	end
end

function base_table:player_sit_down_finished(player)
	return
end

--处理掉线玩家
function base_table:player_offline(player)
	-- body
	print("base_table:player_offline")
	log.info(string.format("set player[%d] in_game false" ,player.guid))
	player.in_game = false
end
-- 玩家站起
function base_table:player_stand_up(player, is_offline)
	log.info(string.format("GameInOutLog,base_table:player_stand_up, guid %s, table_id %s, chair_id %s, is_offline %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id),tostring(is_offline)))

	print("base_table:player_stand_up")
	if is_offline then
		print ("is_offline is true")
	else
		print ("is_offline is false")
	end
	if self:check_cancel_ready(player, is_offline) then
		log.info("base_table:player_stand_up set nil ")
		local chairid = player.chair_id
		local list_guid = -1
		if type(self.player_list_[chairid]) == "table" then
			if self.player_list_[chairid].guid then
				list_guid = self.player_list_[chairid].guid
			end
		end
		log.info(string.format("set guid[%s] table_id[%s] player_list_[%d] is false [ player_list is %s , player_list.guid [%s]]",tostring(player.guid),tostring(player.table_id),chairid , tostring(self.player_list_[chairid]), tostring(list_guid)))
		self.player_list_[chairid] = false

		-- player:on_stand_up(player.table_id,player.chair_id,GAME_SERVER_RESULT_SUCCESS)

		player.table_id = nil
		player.chair_id = nil
		if self.ready_list_[chairid] then
			self.ready_list_[chairid] = false
			local notify = {
				ready_chair_id = chairid,
				is_ready = false,
			}
			self:broadcast2client("SC_Ready", notify)
		end

		return true
	end
	log.info(string.format("guid %s,is_offline %s",	tostring(player.guid),tostring(is_offline)))
	if is_offline then
		print("set player is_offline true")
		player.is_offline = true -- 掉线了
	end
	-- player:on_stand_up(player.table_id,player.chair_id,GAME_SERVER_RESULT_IN_GAME)
	return false
end
function base_table:set_trusteeship(player)
	print("====================base_table:set_trusteeship")
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

	if not player.room_id then
		log.warning(string.format("guid[%d] not find in room", player.guid))
		return
	end
	if not player.table_id then
		log.warning(string.format("guid[%d] not find in table", player.guid))
		return
	end
	if not player.chair_id then
		log.warning(string.format("guid[%d] not find in chair_id", player.guid))
		return
	end

	local ready_mode = self.room_:get_ready_mode()
	if ready_mode == GAME_READY_MODE_NONE then
		log.warning(string.format("guid[%d] mode=GAME_READY_MODE_NONE", player.guid))
		return
	end
	if self.ready_list_[player.chair_id] ~= false then
		log.warning(string.format("chair_id[%d] ready error,guid[%d]", player.chair_id,player.guid))
		print(self.ready_list_[player.chair_id])
		return
	end

	print(string.format("set tableid [%d] chair_id[%d]  ready_list is true ",self.table_id_,player.chair_id))
	self.ready_list_[player.chair_id] = true

	-- 机器人准备
	self:foreach(function(p)
		if p.is_android and (not self.ready_list_[p.chair_id]) then
			self.ready_list_[p.chair_id] = true

			local notify = {
				ready_chair_id = p.chair_id,
				is_ready = true,
				}
			self:broadcast2client("SC_Ready", notify)
		end
	end)
	print("set Dropped false")
	player.Dropped = false
	-- 通知自己准备
	local notify = {
		ready_chair_id = player.chair_id,
		is_ready = true,
		}
	self:broadcast2client("SC_Ready", notify)

	self:check_start(false)
end
function base_table:reconnection_play_msg(player)
	-- 重新上线
	print("---------base_table:reconnection_play_msg-----------")
	print("set Dropped is false")
	player.Dropped = false
	print("set online is true")
	player.online = true
	log.info(string.format("set player[%d] in_game true" ,player.guid))
	player.in_game = true
end
-- 检查是否可准备
function base_table:check_ready(player)
	return true
end

-- 检查是否可取消准备
function base_table:check_cancel_ready(player, is_offline)
	if is_offline then
		--掉线 用于结算
		print("set Dropped true")
		player.Dropped = true
	end
	return self.room_:get_ready_mode() ~= GAME_READY_MODE_NONE
end

-- 检查开始
function base_table:check_start(part)
	local ready_mode = self.room_:get_ready_mode()
	if ready_mode == GAME_READY_MODE_PART then
		local n = 0
		for i, v in ipairs(self.player_list_) do
			if v then
				if self.ready_list_[i] then
					n = n+1
				end
			end
		end
		if n >= 2 then
			self:start(n)
		end
	end
	if part then
		return
	end

	if ready_mode == GAME_READY_MODE_ALL then
		local n =0
		for i,v in ipairs(self.ready_list_) do
			if not v then
				return
			end
			n = n +1
		end
		self:start(n)
	end
end
function base_table:send_playerinfo(player)
	return true
end
-- 开始游戏
function base_table:start(player_count)
	--print("================================base_table:start")
	local result_ = self:check_single_game_is_maintain()
	if result_ == true then
		log.info(string.format("game is maintain cant start roomid[%d] tableid[%d]" ,self.room_.id, self.table_id_))
		return nil
	end

	local bRet = false
	if self.configid_ ~= self.room_.configid_ then
		print ("-------------configid:",self.configid_ ,self.room_.configid_)
		print (self.room_.tax_show_, self.room_.tax_open_ , self.room_.tax_)
		self.tax_show_ = self.room_.tax_show_ -- 是否显示税收信息
		self.tax_open_ = self.room_.tax_open_ -- 是否开启税收
		self.tax_ = self.room_.tax_
		self.room_limit_ = self.room_.room_limit_ -- 房间分限制
		self.cell_score_ = self.room_.cell_score_ -- 底注
		self.game_switch_is_open = self.room_.game_switch_is_open

		if self.tax_show_ == 1 then
			self.notify_msg.flag = 3
		else
			self.notify_msg.flag = 4
		end

		self.configid_ = self.room_.configid_

		bRet = true
		print ("self.room_.room_cfg --------" ,self.room_.room_cfg )
		if self.room_.room_cfg ~= nil then
			self:load_lua_cfg()
		end
	end

	self:broadcast2client("SC_ShowTax", self.notify_msg)
	return bRet
end

-- 检查是否维护
function base_table:check_game_maintain()
	local iRet = false
	if game_switch == 1 then--游戏将进入维护阶段
		log.warning(string.format("All Game will maintain..game_switch=[%d].....................",game_switch))
		for i,v in pairs (self.player_list_) do
			if  v and v.is_player == true and v.vip ~= 100 then
				send2client_pb(v, "SC_GameMaintain", {
				result = GAME_SERVER_RESULT_MAINTAIN,
				})
				v:forced_exit()
			end
		end
		iRet = true
	end
	return iRet
end

--准备玩家通知维护
function base_table:on_notify_ready_player_maintain(player)
	local iRet = false
	if game_switch == 1 and player.vip ~= 100 then--游戏将进入维护阶段
		send2client_pb(player, "SC_GameMaintain", {
		result = GAME_SERVER_RESULT_MAINTAIN,
		})
		player:forced_exit()
		iRet = true
	end
	return iRet
end

-- 重新上线
function base_table:reconnect(player)
end

-- 清除准备
function base_table:clear_ready()
	for i,v in ipairs(self.ready_list_) do
		self.ready_list_[i] = false
	end
end

-- 心跳
function base_table:tick()
end

function base_table:private_init()
end

function base_table:destroy_private_room(b)
	if b and self.private_room then
		local player = base_players[self.private_room_owner_guid]
		if player  then
			player:change_money(self.private_room_chair_count * self.private_room_score_type, LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM)
		end
	end
	self.private_room = false
end


-- 检查单个游戏维护
function base_table:check_single_game_is_maintain()
	self:game_end()
	local iRet = false
	self.def_game_name = def_game_name
	self.def_game_id = def_game_id
	if self.room_.game_switch_is_open == 1 or get_db_status() == 0 or game_switch == 1 then--游戏将进入维护阶段
		log.warning(string.format("game_name = [%s] gameid = [%d] game_switch_is_open[%d] get_db_status[%d] game_switch[%d] will maintain.....................",self.def_game_name,self.def_game_id,self.room_.game_switch_is_open,get_db_status(),game_switch))
		iRet = self:send_maintain_player()
		log.warning(string.format("game_name = [%s] gameid = [%d] game_switch_is_open[%d] get_db_status[%d] game_switch[%d] will maintain ret(%s).....................",self.def_game_name,self.def_game_id,self.room_.game_switch_is_open,get_db_status(),game_switch,tostring(iRet)))
	end
	return iRet
end

function base_table:send_maintain_player()
	local iRet = false
	for i,v in pairs (self.player_list_) do
		if  v and v.is_player == true and v.vip ~= 100 then
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
	redis_cmd_query(string.format("GET %s",var_platform), function (reply)
		if type(reply) == "string" then
			local result = false
			local collapse_value = tostring(reply)
			if player_money < tonumber(collapse_value) then
				result = true
			end

			func(result)
		else
			--log.error(string.format("GET [%s] error from redis.",tostring(var_platform)))
			func(false)
		end
	end)
end
--玩家破产日志
function  base_table:save_player_collapse_log(player)
	-- body
	if not player then
		return
	end
	local player_money = player:get_money()
	local player_bank_money = player:get_bank_money()
	local platform_info = "collapse_value_platform_id_"..tostring(player.platform_id)
	log.info(string.format("save_player_collapse_log: player guid[%d],cur_money[%d] cur_bank[%d],player.channel_id[%s],player.platform_id[%s] platform_info[%s]",player.guid,player_money,player_bank_money,player.channel_id,player.platform_id,platform_info))

	--先判断身上的钱加上银行的钱是否小于该平台配置的默认值，若是则记录日志
	local player_money_total = player_money + player_bank_money

	check_player_is_collapse(platform_info,player_money_total,function (result)
		if result == true  then
			log.info(string.format("player guid[%d] is collapse, player_money_total[%d] channel_id[%s] platform_id[%s]",player.guid,player_money_total,player.channel_id,player.platform_id))
			local nmsg = {
				guid = player.guid,
				channel_id = player.channel_id ,
				platform_id = player.platform_id,
			}
			send2db_pb("SD_SaveCollapseLog",nmsg)
		end
	end)
end

--检查玩家是否是黑名单列表玩家，若是则返回true，否则返回false
function base_table:check_blacklist_player( player_guid )
	-- body
	return self.room_.room_manager_:check_player_is_in_blacklist(player_guid)

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
	-- body
	if not self.logLevel then
		print(str)
	elseif self.logLevel >= level then
		if number == nil then
			log.info(string.format("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline))
		else
			log.info(string.format("%s [%s][%s][%s]" , str , debug.getinfo(number).short_src , debug.getinfo(number).name , debug.getinfo(number).currentline))
		end
	else
		print(str)
	end
end

function base_table:log_important(str)
	-- body
	if not self.logLevel then
		log.info(string.format("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline))
	else
		self:log(str,self.logLevel,3)
	end
end

function base_table:log_error_msg(str)
	-- body
	log.error(string.format("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline))
end

function base_table:log_msg(str)
	-- body
	self:log(str, 1 ,3)
end