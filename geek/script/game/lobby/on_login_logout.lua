-- 登陆，退出，切换服务器消息处理

local pb = require "pb_files"

require "data.login_award_table"
local login_award_table = login_award_table

require "game.net_func"
local send2db_pb = send2db_pb
local send2client_pb = send2client_pb

local base_player = require "game.lobby.base_player"
local base_players = require "game.lobby.base_players"
local base_emails = require "game.lobby.base_emails"

require "game.lobby.base_android"
local base_active_android = base_active_android
local base_passive_android = base_passive_android

local channel = require "channel"
local android_manager = require "game.lobby.android_manager"
local log = require "log"
local redisopt = require "redisopt"
local json = require "cjson"
local onlineguid = require "netguidopt"
local base_clubs = require "game.club.base_clubs"
local serviceconf = require "serviceconf"
local base_private_table = require "game.lobby.base_private_table"
local table_template = require "game.lobby.table_template"
local enum = require "pb_enums"
require "functions"
local def_save_db_time = 60 -- 1分钟存次档
local timer = require "timer"

local reddb = redisopt.default

--local base_room = require "game.lobby.base_room"

local def_register_money = get_register_money()
local def_private_room_bank = get_private_room_bank()

require "table_func"


-- 登陆验证框相关
local validatebox_ch = {}
for i=243,432 do
	table.insert(validatebox_ch, i)
end

local function get_validatebox_ch()
	local ch ={}
	local count = #validatebox_ch
	for _=1,4 do
		local r = math.random(count)
		table.insert(ch, validatebox_ch[r])
		if r ~= count then
			validatebox_ch[r], validatebox_ch[count] = validatebox_ch[count], validatebox_ch[r]
		end
		count = count-1
	end
	return ch
end

function on_ls_AlipayEdit(msg)
	local  notify = {
		guid = msg.guid,
		alipay_name = msg.alipay_name,
		alipay_name_y = msg.alipay_name_y,
		alipay_account = msg.alipay_account,
		alipay_account_y = msg.alipay_account_y,
	}
	local player = base_players[msg.guid]
	if player  then
		player.alipay_account = msg.alipay_account
		player.alipay_name = msg.alipay_name		
	end
	send2client_pb(player,  "SC_AlipayEdit" , notify)
end

--普通消息，不需要客户端组装消息内容
function on_new_notice(msg)
	if msg then
		base_players:update_notice_everyone(msg)
	end
end

--游戏中奖公告，需要客户端组装消息内容
function on_game_notice(msg)
	if msg then
		base_player:update_game_notice_everyone(msg)
	end
end

function  on_ls_DelMessage(msg)
	if msg then
		base_players:delete_notice_everyone(msg)
	end
end

-- 玩家登录通知 验证账号成功后会收到
function on_ls_login_notify(guid,reconnect)
	log.info("on_ls_login_notify game_id = %d,guid:%s,recconect:%s", def_game_id,guid, reconnect)
	onlineguid[guid] = nil
	local s = onlineguid[guid]

	local player = base_players[guid]
	if not player then
		log.error("on_ls_login_notify game_id = %s,no player,guid:%d",def_game_id,guid)
		return
	end

	log.info("set player.online = true,guid:%d",guid)
	player.online = true
	player.risk = player.risk or 0
	player.inviter_guid = player.inviter_guid or player.inviter_guid or 0
	player.invite_code = player.invite_code or player.invite_code or "0"
	if reconnect then
		-- 重连
		-- local s = onlineguid[guid]
		player.table_id = s.table
		player.chair_id = s.chair
		log.info("login step reconnect game->LC_Login,account=%s", player.account)
		return
	end

	log.info("ip_area =%s",player.ip_area)
	log.info("player[%s] has_bank_password[%s] bankpwd[%s] platform_id[%s]",player.guid,player.has_bank_password,player.bank_password,player.platform_id)
	log.info("player[%s] bank_card_name[%s] bank_card_num[%s] change_bankcard_num[%s] bank_name[%s] bank_province[%s] bank_city[%s] bank_branch[%s]",
		player.guid, player.bank_card_name , player.bank_card_num, player.change_bankcard_num,player.bank_name,
		player.bank_province,player.bank_city,player.bank_branch)
	
	-- math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	-- -- 是否需要弹出验证框
	-- if info.using_login_validatebox == 1 or 
	-- 	(using_login_validatebox and player.is_guest and 
	-- 	player.login_time ~= 0 and to_days(player.login_time) ~= cur_to_days()) then
	-- 	local ch = get_validatebox_ch()
	-- 	local r1 = math.random(4)
	-- 	local r2 = math.random(4)
	-- 	if r1 == r2 then
	-- 		r2 = r2%4+1
	-- 	end
	-- 	player.login_validate_answer = {ch[r1], ch[r2]}
	-- 	notify.is_validatebox = true
	-- 	notify.pb_validatebox = {
	-- 		question = ch,
	-- 		answer = player.login_validate_answer,
	-- 	}
	-- end
	
	log.info("login step game->LC_Login,account=%s", player.account)

	-- 定时存档
	local guid = player.guid
	local function save_db_timer()
		local p = base_players[guid]
		if not p then
			return
		end

		if p ~= player then
			return
		end

		p:save()

		timer.add_timer(def_save_db_time, save_db_timer)
	end
	save_db_timer()

	reddb:hmset("player:online:guid:"..tostring(player.guid),{
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		server = def_game_id,
	})

	reddb:incr(string.format("player:online:count:%s:%d:%d",def_game_name,def_first_game_type,def_second_game_type))
	reddb:incr(string.format("player:online:count:%s:%d:%d:%d",def_game_name,def_first_game_type,def_second_game_type,def_game_id))
	reddb:incr("player:online:count")

	log.info("test .................. on_les_login_notify %s", player.h_bank_password)
end

-- 登录验证框
function on_cs_login_validatebox(player, msg)
	if msg and msg.answer and #msg.answer == 2 and player.login_validate_answer and #player.login_validate_answer == 2  and 
		((msg.answer[1] == player.login_validate_answer[1] and msg.answer[2] == player.login_validate_answer[2]) or
		(msg.answer[1] == player.login_validate_answer[2] and msg.answer[2] == player.login_validate_answer[1])) then

		send2client_pb(player,  "SC_LoginValidatebox", {
			result = LOGIN_RESULT_SUCCESS,
			})

		reddb.del("login_validate_error_count:"..tostring(player.guid))
		return
	end

	local count = reddb:incr("login_validate_error_count:"..tostring(guid))
	count = tonumber(count)
	if count > 2 then
		log.info("login_validate_error_count guid[%d] count[%d]",player.guid, count)
		send2db_pb("SD_ValidateboxFengIp", {
			ip = player.ip,
		})
	end

	-- 验证失败
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		local ch = get_validatebox_ch()
		local r1 = math.random(4)
		local r2 = math.random(4)
		if r1 == r2 then
			r2 = r2%4+1
		end
		player.login_validate_answer = {ch[r1], ch[r2]}
		local notify = {
			question = ch,
			answer = player.login_validate_answer,
		}
		
		local msg = {result = enum.LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL,pb_validatebox = notify}
		send2client_pb(player,  "SC_LoginValidatebox",msg)		
end

-- 玩家退出 
function logout(guid,offline)
	log.info("===========logout %s,offline:%s",guid,offline)
	local player = base_players[guid]
	if not player then
		log.error("logout,guid[%s] not find in game= %s", guid, def_game_id)
		return
	end

	player.logout_time = os.time()
	if g_room:exit_server(player,offline) then
		log.info("logout offlined...")
		return true -- 掉线处理
	end

	-- local old_online_award_time = player.online_award_time
	-- player.online_award_time = player.online_award_time + player.logout_time - player.online_award_start_time

	if old_online_award_time ~= player.online_award_time then
		--player.flag_base_info = true
	end
	
	log.info("set player.online = false")
	player.online = nil
	player:save()
	
	--- 把下面这段提出来，有还没有请求base_info客户端就退出，导致现在玩家数据没有清理
	-- 给db退出消息
	send2db_pb("S_Logout", {
		account = player.account,
		guid = guid,
		login_time = player.login_time,
		logout_time = player.logout_time,
		phone = player.phone,
		phone_type = player.phone_type,
		version = player.version,
		channel_id = player.channel_id,
		package_name = player.package_name,
		imei = player.imei,
		ip = player.ip,
	})

	reddb:del("player:online:guid:"..tostring(player.guid))
	reddb:decr(string.format("player:online:count:%s:%d:%d",def_game_name,def_first_game_type,def_second_game_type))
	reddb:decr(string.format("player:online:count:%s:%d:%d:%d",def_game_name,def_first_game_type,def_second_game_type,def_game_id))
	reddb:decr("player:online:count")

	-- 删除玩家
	base_players[guid] = nil
	onlineguid[guid] = nil

	return false
end

function on_s_logout(msg)
	log.info ("test .................. on_s_logout")
	logout(msg.guid)
end

-- 跨天了
local function next_day(player)
	local next_login_award_day = player.login_award_day + 1
	if login_award_table[next_login_award_day] then
		player.login_award_day = next_login_award_day
	end
	
	player.online_award_time = 0
	player.online_award_num = 0
	player.relief_payment_count = 0

	player.flag_base_info = true

	player.online_award_start_time = os.time()
end

-- 加载玩家数据
local function load_player_data_complete(player)
	if to_days(player.logout_time) ~= cur_to_days() then
		next_day(player)
	end

	log.info("player [%d] account [%s] SC_ReplyPlayerInfoComplete" , player.guid,player.account)
	player.login_time = os.time()
	player.online_award_start_time = player.login_time
	
	if player.is_offline then
		log.info("-------------------------1")
	end
	
	if g_room:is_play(player) then
		log.info("-------------------------2")
	end

	if player.is_offline and g_room:is_play(player) then
		log.info("=====================================send SC_ReplyPlayerInfoComplete")
		local notify = {
			pb_gmMessage = {
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				room_id = player.room_id,
				table_id = player.table_id,
				chair_id = player.chair_id,
			}
		}

		log.info("player [%d] account [%s] SC_ReplyPlayerInfoComplete send have data gate_id[%d]" , player.guid,player.account,player.gate_id)
		send2client_pb(player,"SC_ReplyPlayerInfoComplete", notify)
		return
	end

	log.info("player [%d] account [%s] SC_ReplyPlayerInfoComplete send data is nill gate_id[%d]" , player.guid,player.account,player.gate_id)
	send2client_pb(player,"SC_ReplyPlayerInfoComplete", nil)

	--邀请码的奖励
	send2db_pb("SD_QueryPlayerInviteReward", {
			guid = player.guid,
		})
end

local channel_cfg = {}
function channel_invite_cfg(channel_id)
	if channel_cfg then
		for k,v in pairs(channel_cfg) do
			if v.channel_id == channel_id then
				return v
			end
		end
	end
	return nil
end


function on_ds_load_channel_invite_cfg(msg)
	if not msg then
		return
	end

	channel_cfg = msg.cfg or {}	
end

function on_ds_load_player_invite_reward(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("on_ds_load_player_invite_reward guid[%d] not find in game", msg.guid)
		return
	end
	if msg.reward and msg.reward > 0 then player:change_money(msg.reward,LOG_MONEY_OPT_TYPE_INVITE) end
end

local function check_load_complete(player)
	load_player_data_complete(player)
end

-- 请求玩家信息
function on_cs_request_player_info(msg,guid)
	log.info("player[%s] request_player_info gameid[%d] first_game_type[%d] second_game_type[%d]",guid , def_game_id , def_first_game_type ,def_second_game_type)
	local player = base_players[guid]
	if not player then
		return nil
	end

	log.info("player guid[%d] in request_player_info" , guid)

	local emailid = reddb:smembers("email:"..tostring(guid))
	local emails = {}
	for _,eid in ipairs(emailid) do
		local email = base_emails[eid]
		if email then
			table.insert(emails,email)
		end
	end

	local info = {}
	info.guid = guid
	info.pb_base_info = player
	info.pb_emails = emails

	onlineguid.send(guid,"SC_ReplyPlayerInfo",info)

	log.info("test .................. on_cs_request_player_info")
end


function on_ds_notifyclientbankchange(msg)
	log.info("guid = [%d], old_bank = [%d], new_bank = [%d] change_bank = [%d] log_type = [%d]",
		msg.guid,msg.old_bank,msg.new_bank,msg.change_bank,msg.log_type)
	local player = base_players[msg.guid]
	if not player then
		log.warning("guid[%d] not find in game", msg.guid)
		return
	end

	send2client_pb(player,"SC_NotifyBank",{
		opt_type = msg.log_type,
		bank = msg.new_bank,
		change_bank = msg.change_bank,
	})
end

function  on_ds_player_append_info(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("on_ds_player_append_info guid[%d] not find in game" , msg.guid)
		return
	end

	log.info(
		"on_ds_player_append_info guid[%d] seniorpromoter [%s] identity_type [%s] identity_param [%s] risk[%d] risk_show_proxy[%s] create_time[%s]"
		, msg.guid
		, msg.seniorpromoter
		, msg.identity_type
		, msg.identity_param
		, msg.risk
		, msg.risk_show_proxy
		, msg.create_time
		 )
	send2client_pb(player,  "SC_Player_Identiy", {
		guid = msg.guid,						            -- 玩家ID
		identity_type = tonumber(msg.identity_type),		-- 所属玩家身份 0 默认身份
		identity_param = tonumber(msg.identity_param),   	-- 所属身份附加参数
	})

	send2client_pb(player,  "SC_Player_SeniorPromoter", {
		guid = msg.guid,						            -- 玩家ID
		seniorpromoter = tonumber(msg.seniorpromoter),		-- 所属推广员
	})

	send2client_pb(player,  "SC_Player_Append_Info", {
		guid = msg.guid,						            -- 玩家ID
		risk = msg.risk,						            -- 玩家危险等级
		risk_show_proxy = msg.risk_show_proxy,				-- 危险等级对应显示代理商策略概率
		create_time = msg.create_time,						-- 创建时间
	})

	player.risk = msg.risk
	player.seniorpromoter = msg.seniorpromoter
	player.identity_type = msg.identity_type
	player.identity_param = msg.identity_param
end


function  on_update_risk(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("on_ls_player_identiy guid[%d] not find in game" , msg.guid)
		return
	end

	log.info(
		"on_update_risk guid[%d] risk [%d] "
		, msg.guid
		, msg.risk
		 )
	send2client_pb(player,  "SC_Player_Risk", {
		guid = msg.guid,						            -- 玩家ID
		risk = tonumber(msg.risk),		            -- 玩家危险等级
	})
	player.risk = msg.risk
end

function  on_ls_player_identiy(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("on_ls_player_identiy guid[%d] not find in game" , msg.guid)
		return
	end

	log.info(
		"on_ls_player_identiy guid[%d] identity_type [%s] identity_param [%s]"
		, msg.guid
		, msg.identity_type
		, msg.identity_param
		 )
	send2client_pb(player,  "SC_Player_Identiy", {
		guid = msg.guid,						            -- 玩家ID
		identity_type = tonumber(msg.identity_type),		-- 所属玩家身份 0 默认身份
		identity_param = tonumber(msg.identity_param),   	-- 所属身份附加参数
	})
	player.identity_type = msg.identity_type
	player.identity_param = msg.identity_param
end


function  on_ls_player_seniorpromoter(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("on_ls_player_seniorpromoter guid[%d] not find in game" , msg.guid)
		return
	end

	log.info(
		"on_ls_player_seniorpromoter guid[%d] seniorpromoter [%s] "
		, msg.guid
		, msg.seniorpromoter
		 )
	send2client_pb(player,  "SC_Player_SeniorPromoter", {
		guid = msg.guid,						            -- 玩家ID
		seniorpromoter = tonumber(msg.seniorpromoter),		-- 所属推广员
	})
	player.seniorpromoter = msg.seniorpromoter
end


function on_ds_charge_rate(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("on_ds_charge_rate guid[%d] not find in game" , msg.guid)
		return
	end

	log.info(string.format(
		"guid[%d] charge_num [%s] agent_num [%s] charge_success_num [%s] agent_success_num [%s] agent_rate_def [%s] charge_max [%s] charge_time [%s] charge_times [%s] charge_moneys [%s] agent_rate_other [%s] agent_rate_add [%s] agent_close_times[%s] agent_rate_decr [%s] charge_money [%s] agent_money [%s]"
		, msg.guid
		, msg.charge_num
		, msg.agent_num
		, msg.charge_success_num
		, msg.agent_success_num
		, msg.agent_rate_def
		, msg.charge_max
		, msg.charge_time
		, msg.charge_times
		, msg.charge_moneys
		, msg.agent_rate_other
		, msg.agent_rate_add
		, msg.agent_close_times
		, msg.agent_rate_decr
		, msg.charge_money
		, msg.agent_money
		 ))

	send2client_pb(player,"SC_Charge_Rate", {
		guid = msg.guid,					                -- 玩家ID
		charge_num = msg.charge_num,		                -- 成功充值次数
		agent_num = msg.agent_num,		                    -- 代理商成功充值次数
		charge_success_num = msg.charge_success_num,   		-- 充值成功限制
		agent_success_num = msg.agent_success_num,			-- 代理充值成功限制
		agent_rate_def = msg.agent_rate_def,				-- 默认显示代理充值机率
		charge_max = msg.charge_max,						-- 显示充值时 单笔最大限制
		charge_time = msg.charge_time,						-- 充值时间限制
		charge_times = msg.charge_times,					-- 充值成功超过次数
		charge_moneys = msg.charge_moneys,					-- 充值成功超过金额
		agent_rate_other = msg.agent_rate_other,			-- charge_times与charge_moneys 达标后 代理显示机率
		agent_rate_add = msg.agent_rate_add,				-- 成功一次后增加机率
		agent_close_times = msg.agent_close_times,			-- 关闭次数
		agent_rate_decr = msg.agent_rate_decr,				-- 每次减少机率
		charge_money = msg.charge_money,
		agent_money = msg.agent_money
	})

end

-- 加载玩家数据
function on_ds_load_player_data(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("guid[%d] not find in game", msg.guid)
		return
	end

	if msg.info_type == 1 then
		if #msg.pb_base_info > 0 then
			local data = pb.decode(msg.pb_base_info[1], msg.pb_base_info[2])

			data.money = data.money or 0
			data.bank = data.bank or 0
			data.slotma_addition = data.slotma_addition or 0

			player.pb_base_info = data
			
			send2client_pb(player, "SC_ReplyPlayerInfo", {
				pb_base_info = data,
			})
		else
			player.pb_base_info = {}
		end

		check_load_complete(player)
	end
	
	log.info ("test .................. on_ds_load_player_data")
end

function on_S_ReplyPrivateRoomConfig(msg)
	g_PrivateRoomConfig = {}
	for i,v in ipairs(msg.info_list.info) do
		local t = {game_id = v.game_id, first_game_type = v.first_game_type}
		if v.first_game_type == 6 then
			t.room_cfg = {}
			local cfg = eval(v.room_lua_cfg)
			for j,u in ipairs(cfg) do
				table.insert(t.room_cfg, {cell_money = u.score[1], money_limit = u.money_limit})
			end
		end

		table.insert(g_PrivateRoomConfig, t)
	end
end

-- 计算进入私人房间需要
local function calc_private_table_need_money(first_game_type, second_game_type, chair_count)
	for i,v in ipairs(g_PrivateRoomConfig) do
		if v.first_game_type == first_game_type then
			local cfg = v.room_cfg[second_game_type]
			if not cfg then
				break
			end

			local money = cfg.money_limit
			if chair_count then
				money = money + cfg.cell_money * chair_count
			end
			return money
		end
	end
	return nil
end

-- 开房间费
local function getCreatePrivateRoomNeedMoney(first_game_type, second_game_type, chair_count)
	for i,v in ipairs(g_PrivateRoomConfig) do
		if v.first_game_type == first_game_type then
			local cfg = v.room_cfg[second_game_type]
			if not cfg then
				break
			end

			if chair_count then
				return cfg.cell_money * chair_count
			end
		end
	end
	return 0
end

-- 检查私人房间椅子
local function check_private_table_chair(first_game_type, chair_count)
	local room = g_room
	if not room.conf.private then
		return false
	end

	if not room.conf.chair_opt then
		return false
	end

	for _,c in pairs(room.conf.chair_opt) do
		if c == chair_count then
			return true
		end
	end

	return false
end

function on_cs_instructor_weixin(msg,guid)
	send2db_pb("SD_Get_Instructor_Weixin", {guid = guid,})
end

function on_ds_instructor_weixin( msg )	
	local player = base_players[msg.guid]
	if not player then
		log.warning("guid[%d] not find in game", msg.guid)
		return
	end
	send2client_pb(player, "SC_Get_Instructor_Weixin", {
		instructor_weixin = msg.instructor_weixin,
		})
end

-- 切换游戏服务器
function on_cs_change_game(msg,guid)
	local player = base_players[guid]
	if not player then
		return
	end

	local room = g_room
	if player.disable == 1 then	
		-- 踢用户下线 封停所有功能
		log.info("on_cs_change_game =======================disable == 1")
		if not room:is_play(player) then
			log.info("on_cs_change_game.....................player not in play forced_exit")
			-- 强行T下线
			player:forced_exit();
		end
		return
	end

	log.info("game_switch [%d] player.guid[%d] player.vip[%d]",game_switch,player.guid,player.vip)
	if  game_switch == 1 then --游戏进入维护阶段
		if player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
				result = enum.GAME_SERVER_RESULT_MAINTAIN,
			})
			player:forced_exit()
			log.warning("GameServer will maintain,exit")
			return
		end
	end

	if msg.private_room_opt == 1 and not check_private_table_chair(msg.private_room_chair_count) then
		send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = enum.GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
			})
		return
	end

	if msg.private_room_opt == 1 then
		local needmoney = calc_private_table_need_money(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
		if not needmoney then
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = enum.GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
			})
			return
		end

		local money = player.money or 0
		if money < needmoney then
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = enum.GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_MONEY,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
				balance_money = needmoney-money,
			})
			return
		end
	end

	if msg.first_game_type == def_first_game_type and msg.second_game_type == def_second_game_type then
		-- 已经在这个服务器中了
		log.info("on_cs_change_game: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d]",def_game_name,def_game_id,room.game_switch_is_open)
		if g_room.game_switch_is_open == 1 then --游戏进入维护阶段
			if player.vip ~= 100 then	
				send2client_pb(player, "SC_GameMaintain", {
						result = enum.GAME_SERVER_RESULT_MAINTAIN,
						})
				player:forced_exit()
				log.warning("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id)
				return
			end
		end

		local b_private_room = true
		local result_, table_id_, chair_id_, tb
		if msg.private_room_opt == 1 then
			result_, table_id_, chair_id_, tb = room:create_private_table(player, msg.private_room_chair_count, msg.private_room_score_type)
			if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
				-- 开房费
				local money = getCreatePrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
				if money > 0 then
					player:change_money(-money, enum.LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM)
				end
			end
		elseif msg.private_room_opt == 2 then
			result_, table_id_, chair_id_, tb = room:join_private_table(player, msg.owner_guid)
		else
			result_, table_id_, chair_id_, tb = room:enter_room_and_sit_down(player)
			b_private_room = false
		end

		if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
			local notify = {
				room_id = def_game_id,
				table_id = table_id_,
				chair_id = chair_id_,
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room = b_private_room,
				private_room_score_type = msg.private_room_score_type,
			}
			tb:foreach_except(chair_id_, function (p)
				if p.chair_id then
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
					if msg.first_game_type == 8 then --百人牛牛特殊处理，只发送前8位玩家信息
						if #notify.pb_visual_info < 9 then
							table.insert(notify.pb_visual_info, v)
						end	
					else
						table.insert(notify.pb_visual_info, v)
					end
				else
					log.warning("on_cs_change_game  guid=[%s] table_id=[%s] table_id_[%d]",tostring(p.guid),tostring(p.table_id),table_id_)
				end
			end)
			
			send2client_pb(player, "SC_EnterRoomAndSitDown", notify)

			tb:player_sit_down_finished(player)

			player.noready = nil 
			tb:send_playerinfo(player)

			reddb:hmset("player:online:guid:"..tostring(player.guid),{
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				server = def_game_id,
				room_id = def_game_id,
			})

			log.info("change step this ok,account=%s", player.account)
		else
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
				})

			log.info("change step this err,account=%s,result [%d]", player.account,result_)
		end
	else
		log.info("player[%d] has_bank_password[%s] bankpwd[%s] ",player.guid,tostring(player.has_bank_password),tostring(player.bank_password))
		log.info("player[%d] bank_card_name[%s] bank_card_num[%s] change_bankcard_num[%s] bank_name[%s] bank_province[%s] bank_city[%s] bank_branch[%s]",
			player.guid, player.bank_card_name , player.bank_card_num, player.change_bankcard_num,
			player.bank_name,player.bank_province,player.bank_city,player.bank_branch)

		log.info("change step ask login,account=%s", player.account)
	end
end

-- 检查是否从Redis中加载完成
local function check_change_complete(player, msg)
	local b_private_room = true
	local result_, room_id_, table_id_, chair_id_, tb
	if msg.private_room_opt == 1 then
		result_, room_id_, table_id_, chair_id_, tb = room:create_private_table(player, msg.private_room_chair_count, msg.private_room_score_type)
		if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
			-- 开房费
			local money = getCreatePrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
			if money > 0 then
				player:change_money(-money, enum.LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM)
			end
		end
	elseif msg.private_room_opt == 2 then
		result_, room_id_, table_id_, chair_id_, tb = room:join_private_table(player, msg.owner_guid)
	else
		result_, room_id_, table_id_, chair_id_, tb = room:enter_room_and_sit_down(player)
		b_private_room = false
	end

	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		local notify = {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room = b_private_room,
			private_room_score_type = msg.private_room_score_type,
		}

		tb:foreach_except(chair_id_, function (p)
			if p.chair_id then
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
			else
				log.warning("check_change_complete  guid=[%s] table_id=[%s] table_id_[%d]",tostring(p.guid),tostring(p.table_id),table_id_)
			end
		end)
		
		send2client_pb(player, "SC_EnterRoomAndSitDown", notify)

		tb:player_sit_down_finished(player)

		log.info("change step other ok,account=%s", player.account)
	else
		if result_ == 14 then --game maintain
			log.warning("check_change_complete:result_ = [%d], game_name = [%s],game_id =[%d], will maintain,exit",result_,def_game_name,def_game_id)
		end
		send2client_pb(player, "SC_EnterRoomAndSitDown", {
			result = result_,
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
		})

		log.warning("change step other error,account=%s", player.account)
	end
end

function on_ss_change_game(guid)
	local player = base_players[guid]
	player.online = true
	log.info("player[%d] bank_card_name[%s] bank_card_num[%s] change_bankcard_num[%s] bank_name[%s] bank_province[%s] bank_city[%s] bank_branch[%s",
		player.guid, player.bank_card_name , player.bank_card_num, player.change_bankcard_num,
		player.bank_name,player.bank_province,player.bank_city,player.bank_branch)

	log.info("player[%d] seniorpromoter[%s] identity_type[%s] identity_param[%s]",
		player.guid,player.seniorpromoter,player.identity_type,player.identity_param)
	log.info("player[%d] has_bank_password[%s] bankpwd[%s] platform_id[%s]",
		player.guid,player.has_bank_password,player.bank_password,player.platform_id)

	reddb:hmset("player:online:guid:"..tostring(player.guid),{
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		server = def_game_id,
	})

	reddb:incr(string.format("player:online:count:%s:%d:%d",def_game_name,def_first_game_type,def_second_game_type))
	reddb:incr(string.format("player:online:count:%s:%d:%d:%d",def_game_name,def_first_game_type,def_second_game_type,def_game_id))

	-----------
	onlineguid[player.guid] = nil
	onlineguid.control(player,"goserver",def_game_id)
	onlineguid[player.guid] = nil
	
	-- 定时存档
	local guid = player.guid
	local function save_db_timer()
		local p = base_players[guid]
		if not p then
			return
		end

		if p ~= player then
			return
		end

		p:save()

		timer.add_timer(def_save_db_time, save_db_timer)
	end
	save_db_timer()

	log.info("change step login notify,account=%s", player.account)
end

local function check_pay_option(option)
	local pay_option_all = {
		[enum.PAY_OPTION_BOSS] = true,
		[enum.PAY_OPTION_AA] = true,
		[enum.PAY_OPTION_ROOM_OWNER] = true,
	}

	return option ~= nil and pay_option_all[option]
end

local function check_money_type(money_type)
	local money_type_all = {
		[enum.ITEM_PRICE_TYPE_GOLD] = true,
		[enum.ITEM_PRICE_TYPE_ROOM_CARD] = true,
		[enum.ITEM_PRICE_TYPE_DIAMOND] = true,
	}

	return money_type ~= nil and money_type_all[money_type]
end


local function get_chair_count(option)
	local gameconf = serviceconf[def_game_id].conf
	return gameconf.private_conf.chair_count_option[option]
end

local function get_play_round(option)
	local gameconf = serviceconf[def_game_id].conf
	return gameconf.private_conf.round_count_option[option]
end

local function check_rule(rule)
	local chair_count = get_chair_count(rule.room.player_count_option + 1)
	if not chair_count then
		return enum.ERROR_CLUB_UNKONW
	end

	local play_round = get_play_round(rule.round.option + 1)
	if not play_round then
		return enum.ERROR_CLUB_UNKONW
	end

	local pay_option = rule.pay.option
	if not check_pay_option(pay_option) then
		return enum.ERROR_CLUB_UNKONW
	end

	local money_type = rule.pay.money_type
	if not check_money_type(money_type) then
		return enum.ERROR_CLUB_UNKONW
	end

	return enum.ERROR_NONE,play_round,chair_count,pay_option,money_type
end

local function get_room_player_count(room_id)
	return channel.call("game."..tostring(room_id),"lua","get_player_count")
end

local function find_best_room(first_game_type,second_game_type)
	local room_id 
	local cur_player_count
	for id,_ in pairs(channel.query()) do
		id = tonumber(id:match("game%.(%d+)"))
		if id then
			local gameconf = serviceconf[id].conf
			if 	gameconf.first_game_type == first_game_type 
				and (not second_game_type or second_game_type == gameconf.second_game_type) then
				local player_count = get_room_player_count(id)
				if player_count < gameconf.player_limit and (not cur_player_count or player_count < gameconf.player_limit)   then
					room_id = id
					cur_player_count = player_count
				end
			end
		end
	end

	return room_id
end

function on_cs_create_private_room(msg,guid)
	local game_type = msg.game_type
    local club_id = msg.club_id
	local rule_str = msg.rule
	local template_id = msg.template_id

	dump(msg)

	local player = base_players[guid]

	if player.table_id then
		send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
			result = enum.GAME_SERVER_RESULT_IN_ROOM,
		})
		return
	end

	if player.chair_id then
		send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
			result = enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR,
		})
		return
	end

	if not rule_str and not template_id then
		send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
			result = enum.ERORR_PARAMETER_ERROR,
		})
		return
	end

	local room_cfg = serviceconf[def_game_id].conf
	if room_cfg.first_game_type ~= game_type then
		local room_id = find_best_room(game_type)
		if not room_id then
			log.warning("on_cs_create_private_room did not find room,game_type:%s,room_id:%s",game_type,room_id)
			send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
				result = enum.GAME_SERVER_RESULT_NO_GAME_SERVER,
				game_type = game_type,
			})
			return
		end

		channel.call("game."..tostring(room_id),"msg","SS_ChangeGame",guid)
		reddb:decr(string.format("player:online:count:%s:%d:%d",def_game_name,def_first_game_type,def_second_game_type))
		reddb:decr(string.format("player:online:count:%s:%d:%d:%d",def_game_name,def_first_game_type,def_second_game_type,def_game_id))
		onlineguid[guid] = nil
		channel.publish("game."..tostring(room_id),"msg","C2S_ROOM_CREATE_REQ",msg,guid)
		return
	end

	if template_id and template_id ~= 0 then
		local template = table_template[template_id]
		club_id = template.club_id
		rule_str = template.rule
		game_type = template.game_id
	end

	local ok,rule = pcall(json.decode,rule_str)
	if not ok then
		send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
			result = enum.ERORR_PARAMETER_ERROR,
		})
		return
	end

	local result,round,chair_count,pay_option,_ = check_rule(rule)
	if result ~= enum.ERROR_NONE  then
		send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
			result = result,
			game_type = game_type,
		})
		return
	end

	local result,global_table_id,tb = enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND,nil,nil

	local club = club_id and base_clubs[club_id] or nil
	if pay_option == enum.PAY_OPTION_BOSS then
		if not club then
			send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
				result = enum.ERROR_CLUB_NOT_FOUND,
				game_type = game_type,
			})
			return
		end

		result,global_table_id,tb = on_club_create_table(club,player,chair_count,round,rule)
	elseif pay_option == enum.PAY_OPTION_AA then
		if club then
			result,global_table_id,tb = on_club_create_table(club,player,chair_count,round,rule)
		else
			result,global_table_id,tb = g_room:create_private_table(player,chair_count,round,rule)
		end
	elseif pay_option == enum.PAY_OPTION_ROOM_OWNER then
		
	end

	if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
		send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
			result = result,
		})
		return
	end

	send2client_pb(guid,"S2C_ROOM_CREATE_RES",{
		result = result,
		info = {
			game_type = game_type,
			club_id = club_id,
			table_id = global_table_id,
			rule = msg.rule,
			owner = guid,
		},
		seat_list = {{
			chair_id = player.chair_id,
			open_id_icon = player.open_id_icon,
			guid = player.guid,
			nickname = player.nickname,
			sex = player.sex,
			ready = tb.ready_list[player.chair_id] and true or false,
		}},
	})
end

function on_cs_reconnect(guid)
	local player = base_players[guid]
	local onlineinfo = onlineguid[guid]
	if not onlineinfo then
		send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
			result = enum.GAME_SERVER_RESULT_RECONNECT_NOT_ONLINE,
		})
		return
	end

	if not onlineinfo.table or not onlineinfo.chair then
		send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
			result = enum.GAME_SERVER_RESULT_PLAYER_NO_CHAIR,
		})
		return
	end

	local table_id = onlineinfo.table
	local chair_id = onlineinfo.chair
	local private_table = base_private_table[onlineinfo.global_table]
	if not private_table then
		send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
			result = enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND,
		})
		return
	end

	local tb = g_room.tables[table_id]
	local seats = {}
	tb:foreach(function(p)
		table.insert(seats,{
			chair_id = p.chair_id,
			open_id_icon = p.open_id_icon,
			guid = p.guid,
			nickname = p.nickname,
			sex = p.sex,
			ready = tb.ready_list[p.chair_id] and true or false,
		})
	end)

	send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
		result = enum.ERROR_NONE,
		info = {
			game_type = private_table.game_type,
			club_id = private_table.club_id,
			table_id = private_table.table_id,
			rule = json.encode(private_table.rule),
			owner = private_table.owner,
		},
		seat_list = seats,
	})

	g_room:reconnect(player,table_id,chair_id)
end

-- 加入私人房间
function on_cs_join_private_room(msg,guid)
	local player = base_players[guid]
	local reconnect = msg.reconnect
	local global_table_id = msg.table_id
	if reconnect and reconnect ~= 0 then
		local onlineinfo = onlineguid[guid]
		if not onlineinfo then
			send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
				result = enum.GAME_SERVER_RESULT_RECONNECT_NOT_ONLINE,
			})
			return
		end
		global_table_id = onlineinfo.global_table
	end

	if not global_table_id then
		send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
			result = enum.ERROR_JOIN_ROOM_NO,
		})
		return
	end

	local private_table = base_private_table[global_table_id]
	if not private_table then
		send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
			result = enum.ERROR_JOIN_ROOM_NO,
		})
		return
	end

	local game_type = private_table.game_type
	if not game_type then
		send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
			result = enum.ERROR_JOIN_ROOM_NO,
		})
	end

	local room_cfg = serviceconf[def_game_id].conf
	if room_cfg.first_game_type ~= game_type then
		onlineguid[guid] = nil
		local room_id = find_best_room(game_type)
		if not room_id then 
			send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
				result = enum.ERROR_JOIN_ROOM_NO,
			})
			return 
		end

		log.info("ss_changegame to %s,%s",guid,room_id)
		channel.call("game."..tostring(room_id),"msg","SS_ChangeGame",guid)
		reddb:decr(string.format("player:online:count:%s:%d:%d",def_game_name,def_first_game_type,def_second_game_type))
		reddb:decr(string.format("player:online:count:%s:%d:%d:%d",def_game_name,def_first_game_type,def_second_game_type,def_game_id))
		channel.publish("game."..tostring(room_id),"msg","C2S_JOIN_ROOM_REQ",msg,guid)
		return
	end

	if reconnect and reconnect ~= 0 then
		on_cs_reconnect(guid)
		return
	end

	local rule = private_table.rule or {
		round = {
			option = 0,
		},
		pay = {
			money_type = 0,
			option = 0,
		},
		room = {
			player_count_option = 0,
		},
		play = {}
	}

	local result,_,chair_count,pay_option,_ = check_rule(rule)
	if result ~= enum.ERROR_NONE  then
		send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
			result = result,
		})
		return
	end

	local tb
	local club_id = private_table.club_id
	local club = club_id and base_clubs[club_id] or nil
	if pay_option == enum.PAY_OPTION_BOSS then
		if not club then
			send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
				result = enum.ERROR_CLUB_NOT_FOUND,
			})
			return
		end

		result,tb = club:join_table(player,private_table,chair_count)
	elseif pay_option == enum.PAY_OPTION_AA then
		if club then
			result,tb = club:join_table(player,private_table,chair_count)
		else
			result,tb = g_room:join_private_table(player,private_table,chair_count)
		end
	elseif pay_option == enum.PAY_OPTION_ROOM_OWNER then
		
	end

	local seats = {}
	if result == enum.GAME_SERVER_RESULT_SUCCESS then
		tb:foreach(function(p) 
			table.insert(seats,{
				chair_id = p.chair_id,
				open_id_icon = p.open_id_icon,
				guid = p.guid,
				nickname = p.nickname,
				sex = p.sex,
				ready = tb.ready_list[p.chair_id] and true or false,
			})
		end)
	else
		log.warning("on_cs_join_private_room faild!guid:%s,%s",guid,result)
	end

	send2client_pb(guid,"S2C_JOIN_ROOM_RES",{
		result = result,
		info = {
			game_type = private_table.game_type,
			club_id = private_table.club_id,
			table_id = private_table.table_id,
			rule = json.encode(private_table.rule),
			owner = private_table.owner,
		},
		seat_list = seats,
	})
end


function on_ss_join_private_room(msg)
	local player = base_players[msg.guid]
	if not player then
		log.error("guid[%d] not find in game", msg.guid)
		return
	end

	if msg.table_id then
		local needmoney = calcPrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type)
		if not needmoney then
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
			})
			return
		end

		local money = player.money or 0
		local bank = player.bank or 0
		
		if money + bank < needmoney + def_private_room_bank then
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_ALL,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
			})
			return
		end

		if bank < def_private_room_bank then
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_BANK,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
				balance_money = def_private_room_bank-bank,
			})
			return
		end

		if money < needmoney then
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_MONEY,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
				balance_money = needmoney-money,
			})
			return
		end

		on_cs_change_game(player, {
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				private_room_opt = 2,
				owner_guid = msg.owner_guid,
				private_room_score_type = msg.private_room_score_type,
			})
	else
		send2client_pb(player, "SC_JoinPrivateRoomFailed", {
			owner_guid = msg.owner_guid,
			result = GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND,
		})
	end
end

-- 私人房间信息
function on_CS_PrivateRoomInfo(player, msg)
	local t = {}
	for i,v in ipairs(g_PrivateRoomConfig) do
		local cm = {}
		for j,u in ipairs(v.room_cfg) do
			cm[j] = u.cell_money
		end

		local tb = nil
		if v.first_game_type == 5 then
			tb = {3}
		elseif v.first_game_type == 6 then
			tb = {2,3,4,5}
		end

		table.insert(t, {first_game_type = v.first_game_type, table_count = tb, cell_money = cm})
	end

	send2client_pb(player, "SC_PrivateRoomInfo", {pb_info = t})
end

-- 完善账号
function on_cs_reset_account(player, msg)
	if (not player.is_guest) and (not player.flag_wait_reset_account) then
		send2client_pb(player,  "SC_ResetAccount", {
			result = LOGIN_RESULT_RESET_ACCOUNT_FAILED,
			account = msg.account,
			nickname = msg.nickname,
		})

		log.warning("reset account error isguest[%d], %d", (player.is_guest and 1 or 0), (player.flag_wait_reset_account and 1 or 0))
		return
	end

	if  string.find(msg.account,"170") == 1 or string.find(msg.account,"171") == 1 then
		send2client_pb(player,  "SC_ResetAccount", {
			result = LOGIN_RESULT_TEL_ERR,
			account = msg.account,
			nickname = msg.nickname,
		})
		log.warning("reset account error player.guid[%d], account[%s] start with 170 or 171",player.guid,msg.account)
		return
	end
		
	player.flag_wait_reset_account = true

	send2db_pb("SD_ResetAccount", {
		guid = player.guid,
		account = msg.account,
		password = msg.password,
		nickname = msg.nickname,
		platform_id = player.platform_id,
	})

	log.info "on_cs_reset_account ..........................."
end

function do_on_ds_reset_account(msg, register_money)
	local player = base_players[msg.guid]
	if not player then
		log.warning("guid[%d] not find in game", msg.guid)
		return
	end

	if msg.ret == LOGIN_RESULT_SUCCESS then
		player.is_guest = false

		player:add_money({{money_type = enum.ITEM_PRICE_TYPE_GOLD, money = register_money}}, LOG_MONEY_OPT_TYPE_RESET_ACCOUNT)

		local account_key = get_account_key(player.account,player.platform_id)
		-- redis数据修改
		redis_cmd_query(string.format("HGET player:login_info %s", account_key), function (reply)
			if type(reply) == "string" then
				local info = pb.decode("PlayerLoginInfo", from_hex(reply))
				info.account = msg.account
				info.nickname = msg.nickname
				redis_command(string.format("HDEL player:login:info %s", account_key))
				redis_command(string.format("HDEL player:login:info:guid %d", player.guid))
				redis_command(string.format("HSET player:login:info %s %s", account_key, to_hex(pb.encode("PlayerLoginInfo", info))))
				redis_command(string.format("HSET player:login:info:guid %d %s", player.guid, to_hex(pb.encode("PlayerLoginInfo", info))))
			end
		end)

		-- 修改lua数据
		player:reset_account(msg.account, msg.nickname)
	--else
	--	log.warning("guid[%d] reset account sql error", msg.guid)
	end
	player.flag_wait_reset_account = nil

	send2client_pb(player,  "SC_ResetAccount", {
		result = msg.ret,
		account = msg.account,
		nickname = msg.nickname,
	})

	log.info "on_ds_reset_account ..........................."
end

function on_ds_reset_account(msg)
	local money = reddb:get("player:registry_money")
	if money then
		register_money = tonumber(money)
		do_on_ds_reset_account(msg, register_money)
		return
	end
end

-- 绑定支付宝
function on_cs_bandalipay(msg,guid)
	local player = base_players[guid]
	log.info ("on_cs_bandalipay ........................... start:", player.change_alipay_num, alipay_account, alipay_name, player.is_guest)
	log.info (player.change_alipay_num > 0, player.alipay_account == "", player.alipay_name == "")
	if player.change_alipay_num > 0 and (player.alipay_account == "" and player.alipay_name == "")  then		
		log.info "on_cs_bandalipay ........................... to db"
		channel.call("db.?","SD_BandAlipay", {
			guid = player.guid,
			alipay_account = msg.alipay_account,
			alipay_name = msg.alipay_name,
			platform_id = player.platform_id,
		})
	else
		log.info "on_cs_bandalipay ........................... false"
		send2client_pb("SC_BandAlipay", {
			guid = guid,
			result = GAME_BAND_ALIPAY_CHECK_ERROR,
			alipay_account = "",
			alipay_name = "",
		})
	end
end

function on_ds_bandalipay(msg)	
	log.info ("on_ds_bandalipay ........................... ", msg.result )
	local player = base_players[msg.guid]
	if player then		
		if msg.result == GAME_BAND_ALIPAY_SUCCESS then
     		player.alipay_account = msg.alipay_account
     		player.alipay_name = msg.alipay_name
			send2client_pb(player, "SC_BandAlipay", {
				result = msg.result,
				alipay_account = msg.alipay_account,
				alipay_name = msg.alipay_name,
				})
		else
			send2client_pb(player, "SC_BandAlipay", {
				result = msg.result,
				alipay_account = "",
				alipay_name = "",
				})
		end
	end
end

function on_ds_bandalipaynum(msg)	
	log.info "on_ds_bandalipaynum ........................... "
	local player = base_players[msg.guid]
	if player then	
		player.change_alipay_num = msg.band_num
	end
end

-- 修改密码
function on_cs_set_password(player, msg)
	if player.is_guest then
		send2client_pb(player,  "SC_SetPassword", {
			result = LOGIN_RESULT_SET_PASSWORD_GUEST,
		})

		log.warning("set password error")
		return
	end

	send2db_pb("SD_SetPassword", {
		guid = player.guid,
		old_password = msg.old_password,
		password = msg.password,
	})
end

function on_ds_set_password(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("guid[%d] not find in game", msg.guid)
		return
	end

	send2client_pb(player, "SC_SetPassword", {
		result = msg.ret,
	})
end

function on_cs_set_password_by_sms(player, msg)
	if player.is_guest then
		send2client_pb(player,  "SC_SetPassword", {
			result = LOGIN_RESULT_SET_PASSWORD_GUEST,
		})

		log.warning("set password error");
	end

	send2db_pb("SD_SetPasswordBySms", {
		guid = player.guid,
		password = msg.password,
	})
end

-- 设置昵称
function on_cs_set_nickname(player, msg)
	send2db_pb("SD_SetNickname", {
		guid = player.guid,
		nickname = msg.nickname,
	})
end

function on_ds_set_nickname(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("guid[%d] not find in game", msg.guid)
		return
	end

	if msg.ret == LOGIN_RESULT_SUCCESS then
		local account_key = get_account_key(player.account,player.platform_id)
		reddb:hset("player:login:info:"..account_key,"nick_name",msg.nick_name)
		player.nickname = msg.nickname
	end

	send2client_pb(player,  "SC_SetNickname", {
		nickname = msg.nickname,
		result = msg.ret,
	})
end

-- 修改头像
function on_cs_change_header_icon(player, msg)
	local header_icon = player.header_icon or 0
	if msg.header_icon ~= header_icon then
		player.header_icon = msg.header_icon
		player.flag_base_info = true
	end

	send2client_pb(player,"SC_ChangeHeaderIcon", {
		header_icon = msg.header_icon,
	})
end

-- 添加机器人
local function add_android(opt_type, room_id, android_list)
	if opt_type == enum.GM_ANDROID_ADD_ACTIVE then
		for _, v in ipairs(android_list) do
			local a = base_active_android:new()
			a:init(room_id, v.guid, v.account, v.nickname)
		end
	elseif opt_type == enum.GM_ANDROID_ADD_PASSIVE then
		for _, v in ipairs(android_list) do
			local a = base_passive_android:new()
			a:init(room_id, v.guid, v.account, v.nickname)
		end
	end
end

-- gm命令操作回调
function on_gm_android_opt(opt_type_, roomid_, num_)
	log.info "on_gm_android_opt .........................."

	if not g_room:find_room(roomid_) then
		log.error("on_gm_android_opt room not find")
		return
	end

	if opt_type_ == enum.GM_ANDROID_ADD_ACTIVE or opt_type_ == enum.GM_ANDROID_ADD_PASSIVE then
		local a = android_manager:create_android(def_game_id, num_)
		local n = #a
		if n > 0 then
			add_android(opt_type_, roomid_, a)
		end

		if n ~= num_ then
			send2db_pb("SD_LoadAndroidData", {
				opt_type = opt_type_,
				room_id = roomid_,
				guid = android_manager:get_max_guid(),
				count = num_ - n,
				})
		end
	elseif opt_type_ == enum.GM_ANDROID_SUB_ACTIVE then
		base_active_android:sub_android(roomid_, num_)
	elseif opt_type_ == enum.GM_ANDROID_SUB_PASSIVE then
		base_passive_android:sub_android(roomid_, num_)
	end
end

-- 返回机器人数据
function on_ds_load_android_data(msg)
	log.info "on_ds_load_android_data .........................."

	if not msg then
		log.error("on_ds_load_android_data error")
		return
	end

	android_manager:load_from_db(msg.android_list)

	local a = android_manager:create_android(def_game_id, #msg.android_list)
	if #a <= 0 then
		return
	end
	
	add_android(msg.opt_type, msg.room_id, a)
end

function  on_ds_QueryPlayerMsgData(msg)
	local player = base_players[msg.guid]
	if player then
		if msg.pb_msg_data then
			send2client_pb(player,"SC_NewMsgData",{
				pb_msg_data = msg.pb_msg_data.pb_msg_data_info
			})
		else
			send2client_pb(player,"SC_QueryPlayerMsgData")
		end
	else
		log.info("on_ds_QueryPlayerMsgData not find player , guid :%d",msg.guid)
	end
end

function on_cs_QueryPlayerMsgData( player, msg )
	log.info ("on_ds_QueryPlayerMsgData .........................."..player.guid)
	channel.call("db.?","SD_QueryPlayerMsgData", {
		guid = player.guid,
		platform_id = player.platform_id,
	})
end

function on_ds_QueryPlayerMarquee(msg)
	log.info ("on_ds_QueryPlayerMarquee .........................."..msg.guid)

	local player = base_players[msg.guid]
	if player then
		if msg.pb_msg_data then
			--player.msg_data_info = msg.pb_msg_data.pb_msg_data_info
			if msg.first then
				send2client_pb(player,"SC_QueryPlayerMarquee",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			else
				send2client_pb(player,"SC_NewMarquee",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			end
		else
			send2client_pb(player,"SC_QueryPlayerMarquee")
		end
	else
		log.info("on_ds_QueryPlayerMarquee not find player , guid : " ..msg.guid)
	end
end

function on_cs_QueryPlayerMarquee( player, msg )
	log.info ("on_cs_QueryPlayerMarquee .........................."..player.guid)
	channel.call("db.?","SD_QueryPlayerMarquee", {
		guid = player.guid,
		platform_id = player.platform_id,
	})
end

function on_cs_SetMsgReadFlag( player, msg )
	log.info ("on_cs_SetMsgReadFlag .........................."..player.guid)
	channel.call("db.?","SD_SetMsgReadFlag", {
		guid = player.guid,
		id = msg.id,
		msg_type = msg.msg_type,
	})
end

function  on_ds_LoadOxConfigData(msg)
	--log.info("on_ds_LoadOxConfigData...................................test ")
	--ox_table:reload_many_ox_DB_config(msg)
end

-- 修改税率
function on_ls_set_tax(msg)
	log.info("on_ls_SetTax...................................on_ls_set_tax")
	log.info(msg.tax, msg.is_show, msg.is_enable)
	g_room:change_tax(msg.tax, msg.is_show, msg.is_enable)
	local nmsg = {
	webid = msg.webid,
	result = 1,
	}
	send2login_pb("SL_ChangeTax",nmsg)
end

function on_ls_FreezeAccount( msg )
	log.info("on_ls_FreezeAccount...................................start")
	local player = base_players[msg.guid]
	local notify = {
		guid = msg.guid,
		status = msg.status,
		retid = msg.retid,
		ret = 0,
		asyncid = msg.asyncid,
	}
	if not player then
		notify.ret = 1
		log.info(" not find player :",notify.ret)
		send2loginid_pb(msg.login_id,"SL_FreezeAccount",notify)
		return
	end	
	local notifyT = {
		guid = msg.guid,
		status = msg.status,
	}
	-- 通知客户端
	send2client_pb(player,  "SC_FreezeAccount", notifyT)
	-- 修改玩家数据
	player.disable = msg.status;
	if player.disable == 1 then
		-- 踢用户下线 封停所有功能
		log.info("=======================disable == 1")
		if not g_room:is_play(player) then
			log.info("on_ls_FreezeAccount.....................player not in play forced_exit")
			-- 强行T下线
			player:forced_exit();
		end
	end
	send2loginid_pb(msg.login_id,"SL_FreezeAccount",notify)
end
--修改玩家 bank 金币 retcode 0 成功 1 玩家未找到 2 扣减时玩家金币不够
function on_ls_cc_changemoney(msg)
	log.info("on_ls_cc_changemoney start : guid [%d] transfer_id[%s]",msg.player_guid,msg.transfer_id)
	local player = base_players[msg.player_guid]
	if not player then
		log.info("on_ls_cc_changemoney : guid [%d] transfer_id[%s] player not online",msg.player_guid,msg.transfer_id)
		return
	end

	local notify = {
		proxy_guid = msg.proxy_guid,
		player_guid = msg.player_guid,
		transfer_id = msg.transfer_id,
		transfer_type = msg.transfer_type,
		transfer_money = msg.transfer_money,
		transfer_status = 0,
		proxy_oldmoney = msg.proxy_oldmoney,
		proxy_newmoney = msg.proxy_newmoney,
		player_oldmoney = 0,
		player_newmoney = 0,
	}

	 --设置金钱记录日志类型
    local log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
    if tonumber(msg.transfer_type) == 0 then
        log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
    elseif tonumber(msg.transfer_type) == 1 then
        log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY
    elseif tonumber(msg.transfer_type) == 2 then
        log_money_type = LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY
    elseif tonumber(msg.transfer_type) == 3 then
        log_money_type = LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY
	end
	
    local retcode = 0
	if player then		
		retcode,notify.player_oldmoney,notify.player_newmoney = player:changeBankMoney(msg.transfer_money,log_money_type, true)
	else		
		log.info(string.format("on_ls_cc_changemoney : guid [%d] transfer_id[%s] player or player.pb_base_info is nil",msg.player_guid,msg.transfer_id))		
	end
	log.info("on_ls_cc_changemoney : guid [%d] transfer_id[%s]  retcode:[%d]",msg.player_guid,msg.transfer_id,retcode)

	if tonumber(retcode) == enum.ChangMoney_Success then -- success
		send2db_pb("LS_CC_ChangeMoney",notify)
		log.info(string.format("on_ls_cc_changemoney changeBankMoney success : proxy_guid [%d] player_guid [%d] transfer_id[%s] transfer_money[%d] retcode [%d] oldmoney[%s] newmoney[%s]",
			notify.proxy_guid,notify.player_guid,notify.transfer_id,notify.transfer_money,retcode,tostring(notify.player_oldmoney),tostring(notify.player_newmoney)))
	else
		log.error(string.format("on_ls_cc_changemoney changeBankMoney failed : proxy_guid [%d] player_guid [%d] transfer_id[%s] transfer_money[%d] retcode [%d] oldmoney[%s] newmoney[%s]",
			notify.proxy_guid,notify.player_guid,notify.transfer_id,notify.transfer_money,retcode,tostring(notify.player_oldmoney),tostring(notify.player_newmoney)))
	end
end

--修改游戏cfg
function on_fs_chang_config(msg)
	log.info("on_ds_chang_config...................................on_ds_chang_config")

	local nmsg = {
	webid = msg.webid,
	result = 1,
	pb_cfg = {
		game_id = def_game_id,
		second_game_type = def_second_game_type,
		first_game_type = def_first_game_type,
		game_name = def_game_name,
		table_count = 0,
		money_limit = 0,
		cell_money = 0,
		tax = 0,
		platform_id = "",
		title = "[]",
		},
	}
	local tb_l
	if msg.room_list ~= "" then	
		local tb = eval(msg.room_list)
		g_room:gm_update_cfg(tb, msg.room_lua_cfg)
		tb_l = tb
	else			
		log.error("on_ds_chang_config error")
		nmsg.result = 0
	end

	local table_count_l = 0
	local money_limit_l = 0
	local cell_money_l = 0
	local tax_l = 0
	local platform_id_l = ""
	local title_1 = "[]"
	for i,v in ipairs(tb_l) do
		 table_count_l = v.table_count
		 money_limit_l = v.money_limit
		 cell_money_l = v.cell_money
		 tax_l = v.tax * 0.01
		 platform_id_l = v.platform_id
		title_1 = v.title
	end

	nmsg.pb_cfg.table_count = table_count_l
	nmsg.pb_cfg.money_limit = money_limit_l
	nmsg.pb_cfg.cell_money = cell_money_l
	nmsg.pb_cfg.tax = tax_l
	nmsg.pb_cfg.platform_id = platform_id_l
	nmsg.pb_cfg.title = title_1
	
	send2cfg_pb("SF_ChangeGameCfg",nmsg)
end

--修改游戏cfg
function on_ds_server_config(msg)
	log.info("on_ds_server_config...................................on_ds_server_config")
	if msg.cfg.room_list ~= "" then	
		log.info(msg.cfg.room_list)
		local tb = json.decode(msg.cfg.room_list)
		g_room:gm_update_cfg(tb, msg.cfg.room_lua_cfg)
	else			
		log.error("on_ds_server_config error")
	end
end


function  on_lg_updatebankmoney( msg )
	local player = base_players[msg.guid]
	if not player  then
		log.info("on_lg_updatebankmoney error not find player guid [%d] , bankmoney [%d] " , msg.guid, msg.bankmoney)
		return
	end
	log.info("on_lg_updatebankmoney  guid[%d] bankmoney[%d]", player.guid, msg.bankmoney)
	player.bank = msg.bankmoney
end

function on_cs_change_maintain(msg)
	log.info("on_cs_change_maintain...................................on_cs_change_maintain")
	--msg.maintaintype  // 维护类型(1提现维护,2游戏维护,登录开关3)
	--msg.switchopen	// 开关(1维护中,0正常))
	log.info("-----------id value",msg.maintaintype,msg.switchopen)
	if msg.maintaintype == 1 then --提现
		cash_switch = msg.switchopen
	elseif msg.maintaintype == 2 then --游戏
		game_switch = msg.switchopen
		if game_switch == 1 then
			--[[room:broadcast2client_by_player("SC_GameMaintain", {
			result = GAME_SERVER_RESULT_MAINTAIN,
			}) --广播游戏维护状态--]]
			g_room:foreach_by_player(function (player) 
				if player and player.vip ~= 100 then --非系统玩家广播维护
					send2client_pb(player, "SC_GameMaintain", {
					result = 0,
					})
				end
			end)
		end

	else
		log.error("unknown msg maintaintype:",msg.maintaintype,msg.switchopen)
	end
end


function on_CS_RequestProxyConfig(player,msg)

	local platform_id_ = 0
	if msg and msg.platform_id then
		platform_id_ = msg.platform_id
	end

	redis_cmd_query(string.format("HGET platfrom_proxy_info %d", platform_id_), function (reply)
		if type(reply) == "string" then
			local info = pb.decode("PlatformProxyInfos", from_hex(reply))

			local notify = {
				result = 0,
				pb_platform_proxys = {},
			}

			--随机显示8个
			if #info.pb_proxy_list > 8 then
				notify.pb_platform_proxys.platform_id = info.platform_id
				notify.pb_platform_proxys.pb_proxy_list = {}

				local proxy_len = #info.pb_proxy_list
				for i=1,8 do
					local r = math.random(proxy_len)
					table.insert(notify.pb_platform_proxys.pb_proxy_list,info.pb_proxy_list[r])

					if r ~= proxy_len then
						info.pb_proxy_list[r],info.pb_proxy_list[proxy_len] = info.pb_proxy_list[proxy_len],info.pb_proxy_list[r]
					end
					proxy_len = proxy_len - 1
				end
			else
				notify.pb_platform_proxys = info
			end

			send2client_pb(player,  "SC_ReplyProxyConfig", notify)	
		else
			local notify = {
				result = 1,
			}
			send2client_pb(player,  "SC_ReplyProxyConfig", notify)
			log.error("on_CS_RequestProxyConfig error platform_id:%d", platform_id_)

			send2login_pb("SL_RequestProxyInfo",{platform_id = platform_id_})
		end
	end)
end

function on_CS_QueryRechargeAndCashSwitch( player )
	--先从redis读取平台总个数
	if not player then
		return
	end

	local recharge_switch = {}
	local recharge_platform = "platform:recharge:"..tostring(player.platform_id)
	log.info("recharge:recharge_platform = [%s]",recharge_platform)

	--查询当前玩家所属平台的充值开关
	local reply = reddb:get(recharge_platform)
	if not reply then
		log.error("get [%s] error from redis.",recharge_platform)
		return
	end

	local pay_switch_json = tostring(reply)
	log.info(pay_switch_json)
	send2client_pb(player,"SC_ReplyClientPaySwitch",{recharge_switch_json = pay_switch_json})

	--查询并发送当前玩家所属平台的兑换开关
	local all_cash_switch = {}
	local all_cash_switch_platform = "platform:all:cash:"..tostring(player.platform_id)
	log.info("all cash:all_cash_switch_platform = [%s]",all_cash_switch_platform)

	reply = reddb:get(all_cash_switch_platform)
	if not reply then
		log.error("get [%s] error from redis.",all_cash_switch_platform)
		return
	end

	local cash_switch_json = tostring(reply)
	log.info(cash_switch_json)
	send2client_pb(player,"SC_ReplyClientAllCashSwitch",{all_cash_switch_json = cash_switch_json})
end

function on_cs_change_recharge_switch(msg)
	log.info("on_cs_change_recharge_switch...................................platform_id[%d]",msg.platform_id)
	local cur_platform_id = msg.platform_id
	local player_num = 0
	local var_platform = "platform:recharge:"..tostring(msg.platform_id)
	log.info("~~~~~~~~~~~~~~~~recharge switch:update platform = [%s] and broadcast all players in this platform ",var_platform)

	local reply = reddb:get(var_platform)
	if not reply then
		log.error("get [%s] error from redis.",tostring(var_platform))
		return
	end

	local pay_switch_json = tostring(reply)
	log.info(pay_switch_json)
	
	base_players:foreach(function (player)
		if player and tonumber(cur_platform_id) == tonumber(player.platform_id) then --非系统玩家广播充值开关汇总
			log.info("send to player guid[%d] SC_ReplyClientPaySwitch......",player.guid)
			send2client_pb(player,"SC_ReplyClientPaySwitch",{recharge_switch_json = pay_switch_json})
		end
	end)
end

function on_cs_change_all_cash_switch(msg)
	log.info("on_cs_change_all_cash_switch...................................platform_id[%d]",msg.platform_id)
	local cur_platform_id = msg.platform_id
	local var_platform = "platform:all:cash:"..tostring(msg.platform_id)
	log.info("~~~~~~~~~~~~~~~~all cash switch:update platform = [%s] and broadcast all players in this platform ",var_platform)

	local reply = reddb:get(var_platform)
	if not reply then
		log.error("get [%s] error from redis.",tostring(var_platform))
		return
	end

	local cash_switch_json = tostring(reply)
	log.info(cash_switch_json)
	
	base_players:foreach(function (player) 
		if player and tonumber(cur_platform_id) == tonumber(player.platform_id) then --非系统玩家广播充值开关汇总
			log.info("send to player guid[%d] all_cash_switch_json......",player.guid)
			send2client_pb(player,"SC_ReplyClientAllCashSwitch",{all_cash_switch_json = cash_switch_json})
		end
	end)
end

-- 绑定银行卡
function on_cs_bandbankcard(msg,guid)
	local player = base_players[guid]
	log.info("player guid[%d] start band bankcard, bank_card_name[%s] bank_card_num[%s] bank_name[%s] bank_province[%s] bank_city[%s] bank_branch[%s] change_bankcard_num[%d]",
		player.guid, msg.bank_card_name , msg.bank_card_num , msg.bank_name , msg.bank_province , msg.bank_city , 
		msg.bank_branch , tonumber(player.change_bankcard_num))
	log.info("change_bankcard_num [%s] bank_card_name[%s] bank_card_num[%s] is_guest[%s]" , 
		tostring(player.change_bankcard_num) , tostring(player.bank_card_name) , tostring(player.bank_card_num) , tostring(player.is_guest))
	if player.change_bankcard_num > 0 and (player.bank_card_name == "**" and player.bank_card_num == "**") then
		log.info("player [%d] band_bank_cards~~~~~~~~~~~~~~~!" , player.guid)
		channel.call("db.?","SD_BandBankcard", {
			guid = player.guid,
			bank_card_name = msg.bank_card_name,
			bank_card_num = msg.bank_card_num,
			bank_name 	= msg.bank_name,
			bank_province = msg.bank_province,
			bank_city 	= msg.bank_city,
			bank_branch = msg.bank_branch,
			platform_id = player.platform_id,
		})
	else
		log.info("player [%d] band_bank_cards false~~~~~~~~~~~~~~~!" , player.guid)
		local  notify = {
			result = GAME_BAND_ALIPAY_CHECK_ERROR,
			bank_card_name = "**",
			bank_card_num = "**",
			bank_name = "",
			bank_province = "",
			bank_city = "",
			bank_branch = "",
		}
		if player.change_bankcard_num == 0 then
			notify.result = 4 --绑定已达到最大次数限制
		end
		send2client_pb(player, "SC_BandBankcard", notify)
	end
end

function on_ds_bandbankcard(msg)
	log.info ("on_ds_bandbankcard ........................... ", msg.result)
	local player = base_players[msg.guid]
	if player then
		if msg.result == GAME_BAND_ALIPAY_SUCCESS then
     		player.bank_card_name = msg.bank_card_name
     		player.bank_card_num = msg.bank_card_num
			player.bank_name = msg.bank_name
			player.bank_province = msg.bank_province
			player.bank_city = msg.bank_city
			player.bank_branch = msg.bank_branch

			send2client_pb(player, "SC_BandBankcard", {
				result = msg.result,
				bank_card_name = replace_bankcard_name_or_num_str(1,msg.bank_card_name),
				bank_card_num = replace_bankcard_name_or_num_str(2,msg.bank_card_num),
				bank_name = msg.bank_name,
				bank_province = msg.bank_province,
				bank_city = msg.bank_city,
				bank_branch = msg.bank_branch,
			})
		else
			send2client_pb(player, "SC_BandBankcard", {
				result = msg.result,
				bank_card_name = "**",
				bank_card_num = "**",
				bank_name = "",
				bank_province = "",
				bank_city = "",
				bank_branch = "",
			})
		end
	end
end


function on_ls_BankcardEdit(msg)
	local  notify = {
		guid = msg.guid,
		bank_card_name = msg.bank_card_name,
		bank_card_num = msg.bank_card_num,
		bank_name = msg.bank_name,
	}
	local player = base_players[msg.guid]
	if player  then
		player.bank_card_name = msg.bank_card_name
		player.bank_card_num = msg.bank_card_num
		player.bank_name = msg.bank_name
		player.bank_province = msg.bank_province
		player.bank_city = msg.bank_city
		player.bank_branch = msg.bank_branch
	end
	send2client_pb(player,  "SC_BankcardEdit" , notify)
end


function on_ds_bandbankcardnum(msg)	
	log.info("on_ds_bandbankcardnum-------------------->player guid[%d] change_bankcard_num[%d]",msg.guid,msg.band_card_num)
	local player = base_players[msg.guid]
	if player then	
		player.change_bankcard_num = msg.band_card_num
	end
end

function  replace_bankcard_name_or_num_str(input_type,input_str)
	local ret_value = '**'
	if not input_str or  input_str == '**' then
		return ret_value
	end

	if input_type == 1 then --bank card name
		local bankcard_name_len = #input_str
		if bankcard_name_len < 3 then
			ret_value = '**'
			log.error("bankcard_name_len -----------------------------> error.")
		else
			if bankcard_name_len <= 6 then --两个字
				ret_value = string.sub(input_str,0,3) .. '*'
			else --三个字及以上
				ret_value = string.sub(input_str,0,3) .. '*' .. string.sub(input_str,string.len(input_str)-2,-1)
			end
		end
	elseif input_type == 2 then --bank card num
		local bankcard_account_len = #input_str
		if bankcard_account_len < 8 then
			ret_value = '**'
			log.error("bankcard_account_len -----------------------------> error.")
		else
			ret_value = string.sub(input_str,0,4) .. ' **** **** ' .. string.sub(input_str,string.len(input_str)-3, -1)
		end
	else
		return ret_value
	end
	return ret_value
end