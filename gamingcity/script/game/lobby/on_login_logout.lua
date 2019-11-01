-- 登陆，退出，切换服务器消息处理

local pb = require "pb"

require "data.login_award_table"
local login_award_table = login_award_table

require "game.net_func"
local send2db_pb = send2db_pb
local send2client_pb = send2client_pb
local send2client_login = send2client_login
local send2cfg_pb = send2cfg_pb

local base_player = require "game.lobby.base_player"
local base_players = require "game.lobby.base_players"

require "game.lobby.base_android"
local base_active_android = base_active_android
local base_passive_android = base_passive_android

local android_manager = require "game.lobby.android_manager"
local android_manager = android_manager
local log = require "log"
local onlineguid = require "netguidopt"
local redisopt = require "redisopt"
local channel = require "channel"

local reddb = redisopt.default

require "timer"
local add_timer = add_timer
local def_save_db_time = 60 -- 1分钟存次档

-- enum LAND_CARD_TYPE
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
-- enum LOG_MONEY_OPT_TYPE
local LOG_MONEY_OPT_TYPE_RESET_ACCOUNT = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_RESET_ACCOUNT")

local LOG_MONEY_OPT_TYPE_INVITE = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_INVITE")
local LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM")


--local base_room = require "game.lobby.base_room"
local room = g_room

-- enum LOGIN_RESULT
local LOGIN_RESULT_SUCCESS = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_SUCCESS")
local LOGIN_RESULT_SMS_REPEATED = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_SMS_REPEATED")
local LOGIN_RESULT_RESET_ACCOUNT_FAILED = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_RESET_ACCOUNT_FAILED")
local LOGIN_RESULT_TEL_ERR = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_TEL_ERR")
local LOGIN_RESULT_SMS_FAILED = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_SMS_FAILED")
local LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL = pb.enum("LOGIN_RESULT", "LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL")
local ChangMoney_NotEnoughMoney = pb.enum("ChangeMoneyRecode", "ChangMoney_NotEnoughMoney")

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_NO_GAME_SERVER = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NO_GAME_SERVER")
local GAME_SERVER_RESULT_MAINTAIN = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
local GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR")
local GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_ALL = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_ALL")
local GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_BANK = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_BANK")
local GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_MONEY = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_MONEY")
local GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_ALL = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_ALL")
local GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_BANK = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_BANK")
local GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_MONEY = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_JOIN_PRIVATE_ROOM_MONEY")
local GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND")

-- enum GM_ANDROID_OPT
local GM_ANDROID_ADD_ACTIVE = pb.enum("GM_ANDROID_OPT", "GM_ANDROID_ADD_ACTIVE")
local GM_ANDROID_SUB_ACTIVE = pb.enum("GM_ANDROID_OPT", "GM_ANDROID_SUB_ACTIVE")
local GM_ANDROID_ADD_PASSIVE = pb.enum("GM_ANDROID_OPT", "GM_ANDROID_ADD_PASSIVE")
local GM_ANDROID_SUB_PASSIVE = pb.enum("GM_ANDROID_OPT", "GM_ANDROID_SUB_PASSIVE")
local GM_ANDROID_CLEAR = pb.enum("GM_ANDROID_OPT", "GM_ANDROID_CLEAR")

local GAME_BAND_ALIPAY_SUCCESS = pb.enum("GAME_BAND_ALIPAY", "GAME_BAND_ALIPAY_SUCCESS")
local GAME_BAND_ALIPAY_CHECK_ERROR = pb.enum("GAME_BAND_ALIPAY", "GAME_BAND_ALIPAY_CHECK_ERROR")

local LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY")
local LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY")
local LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY")
local LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY")


local ChangMoney_Success = pb.enum("ChangeMoneyRecode", "ChangMoney_Success")
local ChangMoney_NotEnoughMoney = pb.enum("ChangeMoneyRecode", "ChangMoney_NotEnoughMoney")

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local using_login_validatebox = using_login_validatebox
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
	for i=1,4 do
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
	-- body
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
function on_new_nitice(msg)
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

--function on_UpdateMsg(msg)
--	-- body
--	if msg then		
--		local player = base_players[msg.guid]
--		player:UpdateMsg()
--	end
--end

-- 玩家登录通知 验证账号成功后会收到
function on_ls_login_notify(msg)
	local info = msg.player_login_info
	log.info(string.format("on_ls_login_notify game_id = %d %s", def_game_id, tostring(info.is_reconnect)))
	if info.is_reconnect then
		-- 重连
		local player = base_players[info.guid]
		if player then
			print("set player.online = true")
			player.online = true
			player.phone = info.phone
			player.phone_type = info.phone_type
			player.version = info.version
			player.channel_id = info.channel_id
			player.package_name = info.package_name
			player.imei = info.imei
			player.ip = info.ip
			player.risk = info.risk or 0
			player.ip_area = info.ip_area
			player.create_channel_id = info.create_channel_id
			player.enable_transfer = info.enable_transfer
			player.inviter_guid = info.inviter_guid or player.inviter_guid or 0
			player.invite_code = info.invite_code or player.invite_code or "0"			
			player.deprecated_imei = info.deprecated_imei
			player.platform_id = info.platform_id
			log.info(string.format("session_id is [%d] gate_id is [%d] ip_area =%s",info.session_id,info.gate_id,info.ip_area))
			log.info(string.format("login step reconnect game->LC_Login,account=%s", info.account))

			-- 更新在线信息
			channel.publish("db.?","SD_OnlineAccount", {
				guid = player.guid,
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				gamer_id = def_game_id,
				})


			return {
					guid = info.guid,
					account = info.account,
					game_id = def_game_id,
					nickname = info.nickname,
					is_guest = info.is_guest,
					password = msg.password,
					alipay_account = info.alipay_account,
					alipay_name = info.alipay_name,
					change_alipay_num = info.change_alipay_num,
					ip_area = info.ip_area,
					enable_transfer = info.enable_transfer,
					has_bank_password = info.h_bank_password,
					imei = info.imei,
					deprecated_imei = info.deprecated_imei,
					platform_id = info.platform_id,
					bank_card_name = replace_bankcard_name_or_num_str(1,info.bank_card_name),
					bank_card_num = replace_bankcard_name_or_num_str(2,info.bank_card_num),
					change_bankcard_num = info.change_bankcard_num,
					bank_name = info.bank_name,
				}
		end

	end

	local player = base_player:new()
	player:init(info.guid, info.account, info.nickname)

	player.session_id = info.session_id
	player.gate_id = info.gate_id
	player.vip = info.vip
	player.login_time = info.login_time
	player.logout_time = info.logout_time
	player.has_bank_password = info.h_bank_password
	player.bank_password = info.bank_password
	player.is_guest = info.is_guest
	player.bank_login = false
	player.online_award_start_time = 0
	print("info.alipay_account~~~~AAAA:",info.alipay_account)
	player.alipay_account = info.alipay_account
	player.alipay_name = info.alipay_name
	player.change_alipay_num = info.change_alipay_num
	player.phone = info.phone
	player.phone_type = info.phone_type
	player.version = info.version
	player.channel_id = info.channel_id
	player.package_name = info.package_name
	player.imei = info.imei
	player.ip = info.ip
	player.risk = info.risk or 0
	player.ip_area = info.ip_area
	player.create_channel_id = info.create_channel_id
	player.enable_transfer = info.enable_transfer
	player.inviter_guid = info.inviter_guid or player.inviter_guid or 0
	player.invite_code = info.invite_code or player.invite_code or "0"
	player.deprecated_imei = info.deprecated_imei
	player.platform_id = info.platform_id
	player.bank_card_name = info.bank_card_name
	player.bank_card_num = info.bank_card_num
	player.change_bankcard_num = info.change_bankcard_num
	player.bank_name = info.bank_name
	player.bank_province = info.bank_province
	player.bank_city = info.bank_city
	player.bank_branch = info.bank_branch

	log.info(string.format("ip_area =%s", info.ip_area))
	log.info(string.format("player[%d] has_bank_password[%s] bankpwd[%s] platform_id[%s]",player.guid,tostring(player.has_bank_password),tostring(player.bank_password),player.platform_id))

	log.info(string.format("player[%d] bank_card_name[%s] bank_card_num[%s] change_bankcard_num[%s] bank_name[%s] bank_province[%s] bank_city[%s] bank_branch[%s]",
		player.guid, player.bank_card_name , player.bank_card_num, tostring(player.change_bankcard_num),player.bank_name,player.bank_province,player.bank_city,player.bank_branch))
	--log.error(string.format("invite_code =%s inviter_guid = %d", player.invite_code, player.inviter_guid))
	--log.error(tostring(player))
	
	local notify = {
		guid = info.guid,
		account = info.account,
		game_id = def_game_id,
		nickname = info.nickname,
		is_guest = info.is_guest,
		password = msg.password,
		alipay_account = info.alipay_account,
		alipay_name = info.alipay_name,
		change_alipay_num = info.change_alipay_num,
		ip_area = info.ip_area,
		enable_transfer = info.enable_transfer,
		is_first = info.is_first,
		has_bank_password = info.h_bank_password,
		imei = info.imei,
		deprecated_imei = info.deprecated_imei,
		platform_id = info.platform_id,
		bank_card_name = replace_bankcard_name_or_num_str(1,info.bank_card_name),
		bank_card_num = replace_bankcard_name_or_num_str(2,info.bank_card_num),
		change_bankcard_num = info.change_bankcard_num,
		bank_name = info.bank_name,
	}
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	-- 是否需要弹出验证框
	if info.using_login_validatebox == 1 or (using_login_validatebox and player.is_guest and player.login_time ~= 0 and to_days(player.login_time) ~= cur_to_days()) then
		local ch = get_validatebox_ch()
		local r1 = math.random(4)
		local r2 = math.random(4)
		if r1 == r2 then
			r2 = r2%4+1
		end
		player.login_validate_answer = {ch[r1], ch[r2]}
		notify.is_validatebox = true
		notify.pb_validatebox = {
			question = ch,
			answer = player.login_validate_answer,
		}
	end
	
	log.info(string.format("login step game->LC_Login,session_id = %d ,gate_id = %d,account=%s", info.session_id, info.gate_id, info.account))

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

		add_timer(def_save_db_time, save_db_timer)
	end
	save_db_timer()

	-- 更新在线信息
	send2db_pb("SD_OnlineAccount", {
		guid = player.guid,
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		gamer_id = def_game_id,
		})

	print ("test .................. on_les_login_notify", info.h_bank_password)

	return notify
end

function on_ls_login_notify_again(msg)
	local player = base_players[msg.guid]
	if player then
		log.info(string.format("player[%d] has_bank_password[%s] bankpwd[%s]",player.guid,tostring(player.has_bank_password),tostring(player.bank_password)))
		local notify = {
			guid = player.guid,
			account = player.account,
			game_id = def_game_id,
			nickname = player.nickname,
			is_guest = player.is_guest,
			password = msg.password,
			alipay_account = player.alipay_account,
			alipay_name = player.alipay_name,
			change_alipay_num = player.change_alipay_num,
			has_bank_password = player.has_bank_password,
			imei = player.imei,
			deprecated_imei = player.deprecated_imei,
			platform_id = player.platform_id,
			bank_card_name = replace_bankcard_name_or_num_str(1,player.bank_card_name),
			bank_card_num = replace_bankcard_name_or_num_str(2,player.bank_card_num),
			change_bankcard_num = player.change_bankcard_num,
			bank_name = player.bank_name,
		}
		math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		-- 是否需要弹出验证框
		if using_login_validatebox and player.is_guest and player.login_time ~= 0 and to_days(player.login_time) ~= cur_to_days() then
			local ch = get_validatebox_ch()
			local r1 = math.random(4)
			local r2 = math.random(4)
			if r1 == r2 then
				r2 = r2%4+1
			end
			player.login_validate_answer = {ch[r1], ch[r2]}
			notify.is_validatebox = true
			notify.pb_validatebox = {
				question = ch,
				answer = player.login_validate_answer,
			}
		end
		send2client_login(player.session_id, player.gate_id, "LC_Login", notify)

		log.info(string.format("login step again game->LC_Login,account=%s", player.account))
	else
		log.error(string.format("login step again game,guid=%d", msg.guid))
	end
	print ("test .................. on_ls_login_notify_again")
end

-- 登录验证框
function on_cs_login_validatebox(player, msg)
	if msg and msg.answer and #msg.answer == 2 and player.login_validate_answer and #player.login_validate_answer == 2  and 
		((msg.answer[1] == player.login_validate_answer[1] and msg.answer[2] == player.login_validate_answer[2]) or
		(msg.answer[1] == player.login_validate_answer[2] and msg.answer[2] == player.login_validate_answer[1])) then

		send2client_pb(player,  "SC_LoginValidatebox", {
			result = LOGIN_RESULT_SUCCESS,
			})

		redis_command(string.format("HDEL login_validate_error_count %d", player.guid))
		return
	end

	redis_cmd_query(string.format("HGET login_validate_error_count %d", player.guid), function (reply)
		local count = 1
		if type(reply) == "string" or type(reply) == "number" then
			count = tonumber(reply) + 1
		end

		local str = string.format("HSET login_validate_error_count %d %d",player.guid, count)
		redis_command(str)

		if count > 2 then
			log.info(string.format("login_validate_error_count guid[%d] count[%d]",player.guid, count))
			send2db_pb("SD_ValidateboxFengIp", {
				ip = player.ip,
			})
		end

	end)

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
		
		local msg = {result = LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL,pb_validatebox = notify}
		send2client_pb(player,  "SC_LoginValidatebox",msg)
	--[[send2client_pb(player,  "SC_LoginValidatebox", {
		result = LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL,
		})--]]
		
end

-- 玩家退出 
function logout(guid_, bfishing)
	print("===========logout")
	local player = base_players[guid_]
	if not player then
		log.warning(string.format("guid[%d] not find in game= %d", guid_, def_game_id))
		return
	end

	--if(bfishing ~= true) and (def_game_name == "fishing") then
	--	return
	--end
	local account_key = get_account_key(player.account,player.platform_id)

	redis_command(string.format("HDEL player:login:info %s", account_key))
	redis_command(string.format("HDEL player:login:info:guid %d", guid_))
	player.logout_time = get_second_time()
	if player.pb_base_info then
		if room:exit_server(player,true) then
			return true -- 掉线处理
		end

		local old_online_award_time = player.pb_base_info.online_award_time
		player.pb_base_info.online_award_time = player.pb_base_info.online_award_time + player.logout_time - player.online_award_start_time

		if old_online_award_time ~= player.pb_base_info.online_award_time then
			--player.flag_base_info = true
		end
		
		print("set player.online = false")
		player.online = false

		--player:save2redis()
		player:save()

	end
	
	--- 把下面这段提出来，有还没有请求base_info客户端就退出，导致现在玩家数据没有清理
		-- 给db退出消息
		send2db_pb("S_Logout", {
			account = player.account,
			guid = guid_,
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
	--- end

	redis_command(string.format("HDEL player_online_gameid %d", player.guid))
	redis_command(string.format("HDEL player_session_gate %d@%d", player.session_id, player.gate_id))
	
	-- 删除玩家
	player:del()

	return false
end

--login发送过来
function on_s_logout(msg)
	print ("test .................. on_s_logout")
	logout(msg.guid)

	if msg.user_data > 0 then
		send2login_pb("L_KickClient", {
			reply_account = player.account,
			user_data = msg.user_data,
		})
	end
end

-- 跨天了
local function next_day(player)
	local next_login_award_day = player.pb_base_info.login_award_day + 1
	if login_award_table[next_login_award_day] then
		player.pb_base_info.login_award_day = next_login_award_day
	end
	
	player.pb_base_info.online_award_time = 0
	player.pb_base_info.online_award_num = 0
	player.pb_base_info.relief_payment_count = 0

	player.flag_base_info = true

	player.online_award_start_time = get_second_time()
end

function lua_string_split(str, split_char)      
    local sub_str_tab = {}
   
    while (true) do
        local pos = string.find(str, split_char)  
        if (not pos) then        
            table.insert(sub_str_tab,str)  
            break
        end  
    
        local sub_str = string.sub(str, 1, pos - 1)
        table.insert(sub_str_tab,sub_str)
        local t = string.len(str)
        str = string.sub(str, pos + 1, t)
        print(str)
    end      
    return sub_str_tab
end
-- 加载玩家数据
local function load_player_data_complete(player)
	if to_days(player.logout_time) ~= cur_to_days() then
		next_day(player)
	end
	log.info(string.format("player [%d] account [%s] SC_ReplyPlayerInfoComplete" , player.guid,player.account))
	player.login_time = get_second_time()
	player.online_award_start_time = player.login_time
	
	if player.is_offline then
		print("-------------------------1")
	end
	if room:is_play(player) then
		print("-------------------------2")
	end
	if player.is_offline and room:is_play(player) then
		print("=====================================send SC_ReplyPlayerInfoComplete")
		local notify = {
			pb_gmMessage = {
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				room_id = player.room_id,
				table_id = player.table_id,
				chair_id = player.chair_id,
			}
		}

		reddb:hset("player:online:"..tostring(player.guid),"server",def_game_id)

		log.info(string.format("player [%d] account [%s] SC_ReplyPlayerInfoComplete send have data gate_id[%d]" , player.guid,player.account,player.gate_id))
		send2client_pb(player,  "SC_ReplyPlayerInfoComplete", notify)
		room:player_online(player)
		return
	end
	log.info(string.format("player [%d] account [%s] SC_ReplyPlayerInfoComplete send data is nill gate_id[%d]" , player.guid,player.account,player.gate_id))
	send2client_pb(player,  "SC_ReplyPlayerInfoComplete", nil)

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
	--[[for k,v in pairs(channel_cfg) do
		for k1,v1 in pairs(v) do
			log.error(tostring(k1))
			log.error(tostring(v1))
		end
		end
	]]
end
function on_ds_load_player_invite_reward(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("on_ds_load_player_invite_reward guid[%d] not find in game", msg.guid))
		return
	end
	if msg.reward and msg.reward > 0 then player:change_money(msg.reward,LOG_MONEY_OPT_TYPE_INVITE) end
end

-- 检查是否从Redis中加载完成
local function check_load_complete(player)
	--if player.flag_load_base_info and player.flag_load_item_bag and player.flag_load_mail_list then
	--	player.flag_load_base_info = nil
	--	player.flag_load_item_bag = nil
	--	player.flag_load_mail_list = nil
		
		load_player_data_complete(player)
		
		player.flag__request_player_info = nil
	--end
end

-- 请求玩家信息
function on_cs_request_player_info(player, msg)
	log.info(string.format("player[%d] request_player_info gameid[%d] first_game_type[%d] second_game_type[%d]",player.guid , def_game_id , def_first_game_type ,def_second_game_type))
	local guid = player.guid
	if player.flag__request_player_info then
		log.warning(string.format("guid[%d] request_player_info repeated", guid))
		return
	end
	player.flag__request_player_info = true

	log.info(string.format("player guid[%d] in request_player_info" , guid))

	--[[redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
		if reply:is_string() then
			local player = base_players[guid]
			if not player then
				log.warning(string.format("guid[%d] not find in game", guid))
				return
			end
			-- 基本数据
			player.pb_base_info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
			
			send2client_pb(player, "SC_ReplyPlayerInfo", {
				pb_base_info = player.pb_base_info,
			})

			--player.flag_load_base_info = true
			check_load_complete(player)
			
			-- 背包数据
			--[[redis_cmd_query(string.format("HGET player_bag_info %d", guid), function (reply)
				local player = base_players[guid]
				if not player then
					log.warning(string.format("guid[%d] not find in game", guid))
					return
				end

				if reply:is_string() then
					local data = pb.decode("ItemBagInfo", from_hex(reply:get_string()))
					for i, item in ipairs(data.pb_items) do
						data.pb_items[i] = pb.decode(item[1], item[2])
					end

					player.pb_item_bag = data

					send2client_pb(player, "SC_ReplyPlayerInfo", {
						pb_item_bag = data,
					})
				end

				player.flag_load_item_bag = true -- flag
				check_load_complete(player)
			end)]]

			-- 邮件数据
			--[[redis_cmd_query(string.format("HGET player_mail_info %d", guid), function (reply)
				local player = base_players[guid]
				if not player then
					log.warning(string.format("guid[%d] not find in game", guid))
					return
				end

				if reply:is_string() then
					local data = pb.decode("MailListInfo", from_hex(reply:get_string()))
					for i, item in ipairs(data.pb_mails) do
						data.pb_mails[i] = pb.decode(item[1], item[2])
						for j, item in ipairs(data.mails[i].pb_attachment) do
							data.mails[i].pb_attachment[j] = pb.decode(item[1], item[2])
						end
					end

					player.pb_mail_list = data

					send2client_pb(player, "SC_ReplyPlayerInfo", {
						pb_mail_list = data,
					})
				end
				
				player.flag_load_mail_list = true -- flag
				check_load_complete(player)
			end)]]

			---- 公告及消息
			--redis_cmd_query(string.format("HGET player_Msg_info %d",guid),function (reply)
			--	-- body
			--	local player = base_players[guid]
			--	if not player then
			--		log.warning(string.format("guid[%d] not find in game", guid))
			--		return
			--	end
			--	if reply:is_string() then
			--		local data = pb.decode("Msg_Data", from_hex(reply:get_string()))
			--		player.msg_data_info = data.pb_msg_data_info
			--		send2client_pb(player,"SC_QueryPlayerMsgData",{
			--			pb_msg_data = data.pb_msg_data_info
			--		})
			--	end
			--end)
		--[[else
			send2db_pb("SD_QueryPlayerData", {
				guid = player.guid,
				account = player.account,
				nickname = player.nickname,
			})
		end
		send2db_pb("SD_QueryPlayerMsgData", {
			guid = player.guid,
		})
		send2db_pb("SD_QueryPlayerMarquee", {
			guid = player.guid,
		})
	end)--]]

		send2db_pb("SD_QueryPlayerData", {
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
			is_guest = player.is_guest,
			platform_id = player.platform_id,
		})
		send2db_pb("SD_QueryPlayerMsgData", {
			guid = player.guid,
			platform_id = player.platform_id,
		})
		send2db_pb("SD_QueryPlayerMarquee", {
			guid = player.guid,
			platform_id = player.platform_id,
		})

	on_CS_QueryRechargeAndCashSwitch(player)	
	print ("test .................. on_ce_request_player_info")
end


function on_ds_notifyclientbankchange(msg)
	log.info(string.format("guid = [%d], old_bank = [%d], new_bank = [%d] change_bank = [%d] log_type = [%d]",msg.guid,msg.old_bank,msg.new_bank,msg.change_bank,msg.log_type))
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end

	send2client_pb(player, "SC_NotifyBank", {
		opt_type = msg.log_type,
		bank = msg.new_bank,
		change_bank = msg.change_bank,
		})
end
function  on_ds_player_append_info(msg)
	-- body
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("on_ds_player_append_info guid[%d] not find in game" , msg.guid))
		return
	end

	log.info(string.format(
		"on_ds_player_append_info guid[%d] seniorpromoter [%s] identity_type [%s] identity_param [%s] risk[%d] risk_show_proxy[%s] create_time[%s]"
		, msg.guid
		, msg.seniorpromoter
		, msg.identity_type
		, msg.identity_param
		, msg.risk
		, msg.risk_show_proxy
		, msg.create_time
		 ))
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
	-- body
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("on_ls_player_identiy guid[%d] not find in game" , msg.guid))
		return
	end

	log.info(string.format(
		"on_update_risk guid[%d] risk [%d] "
		, msg.guid
		, msg.risk
		 ))
	send2client_pb(player,  "SC_Player_Risk", {
		guid = msg.guid,						            -- 玩家ID
		risk = tonumber(msg.risk),		            -- 玩家危险等级
	})
	player.risk = msg.risk
end

function  on_ls_player_identiy(msg)
	-- body
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("on_ls_player_identiy guid[%d] not find in game" , msg.guid))
		return
	end

	log.info(string.format(
		"on_ls_player_identiy guid[%d] identity_type [%s] identity_param [%s]"
		, msg.guid
		, msg.identity_type
		, msg.identity_param
		 ))
	send2client_pb(player,  "SC_Player_Identiy", {
		guid = msg.guid,						            -- 玩家ID
		identity_type = tonumber(msg.identity_type),		-- 所属玩家身份 0 默认身份
		identity_param = tonumber(msg.identity_param),   	-- 所属身份附加参数
	})
	player.identity_type = msg.identity_type
	player.identity_param = msg.identity_param
end


function  on_ls_player_seniorpromoter(msg)
	-- body
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("on_ls_player_seniorpromoter guid[%d] not find in game" , msg.guid))
		return
	end

	log.info(string.format(
		"on_ls_player_seniorpromoter guid[%d] seniorpromoter [%s] "
		, msg.guid
		, msg.seniorpromoter
		 ))
	send2client_pb(player,  "SC_Player_SeniorPromoter", {
		guid = msg.guid,						            -- 玩家ID
		seniorpromoter = tonumber(msg.seniorpromoter),		-- 所属推广员
	})
	player.seniorpromoter = msg.seniorpromoter
end


function on_ds_charge_rate(msg)
	-- body
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("on_ds_charge_rate guid[%d] not find in game" , msg.guid))
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

	send2client_pb(player,  "SC_Charge_Rate", {
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
		log.warning(string.format("guid[%d] not find in game", msg.guid))
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

		--player.flag_load_base_info = true -- flag
		check_load_complete(player)
	--[[elseif msg.info_type == 2 then
		if #msg.pb_item_bag > 0 then
			local data = pb.decode(msg.item_bag[1], msg.item_bag[2])
			for i, item in ipairs(data.items) do
				data.items[i] = pb.decode(item[1], item[2])
			end
			
			player.pb_item_bag = data
			
			send2client_pb(player, "SC_ReplyPlayerInfo", {
				pb_item_bag = data,
			})
		end

		player.flag_load_item_bag = true -- flag
		check_load_complete(player)
	elseif msg.info_type == 3 then
		if #msg.pb_mail_list > 0 then
			local data = pb.decode(msg.pb_mail_list[1], msg.pb_mail_list[2])
			for i, item in ipairs(data.pb_mails) do
				data.pb_mails[i] = pb.decode(item[1], item[2])
				for j, item in ipairs(data.pb_mails[i].pb_attachment) do
					data.pb_mails[i].pb_attachment[j] = pb.decode(item[1], item[2])
				end
			end
			
			player.pb_mail_list = player.pb_mail_list or {}
			for i, v in ipairs(data.pb_mails) do
				player.pb_mail_list[v.mail_id] = v
			end
			
			send2client_pb(player, "SC_ReplyPlayerInfo", {
				pb_mail_list = data,
			})
		end

		player.flag_load_mail_list = true -- flag
		check_load_complete(player)]]--
	end
	
	print ("test .................. on_ds_load_player_data")
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
local function calcPrivateRoomNeedMoney(first_game_type, second_game_type, chair_count)
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
local function checkPrivateRoomChair(first_game_type, chair_count)
	if first_game_type == 5 and chair_count == 3 then
		return true
	elseif first_game_type == 6 and chair_count >= 2 and chair_count <= 5 then
		return true
	end
	return false
end

function on_cs_instructor_weixin(player, msg)
	send2db_pb("SD_Get_Instructor_Weixin", {guid = player.guid,	})
end
function on_ds_instructor_weixin( msg )	
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end
	send2client_pb(player, "SC_Get_Instructor_Weixin", {
						instructor_weixin = msg.instructor_weixin,
						})
end

-- 切换游戏服务器
function on_cs_change_game(player, msg)
	if player.disable == 1 then		
		-- 踢用户下线 封停所有功能
		print("on_cs_change_game =======================disable == 1")
		if not room:is_play(player) then
			print("on_cs_change_game.....................player not in play forced_exit")
			-- 强行T下线
			player:forced_exit();
		end
		return
	end
	log.info(string.format("game_switch [%d] player.guid[%d] player.vip[%d]",game_switch,player.guid,player.vip))
	if  game_switch == 1 then --游戏进入维护阶段
		if player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = GAME_SERVER_RESULT_MAINTAIN,
					})
			player:forced_exit()
			log.warning(string.format("GameServer will maintain,exit"))	
			return
		end	
	
	end
	if msg.private_room_opt == 1 and not checkPrivateRoomChair(msg.first_game_type, msg.private_room_chair_count) then
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

	if msg.private_room_opt == 1 then
		local needmoney = calcPrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
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

		local money = player.pb_base_info.money or 0
		--[[local bank = player.pb_base_info.bank or 0
		if money + bank < needmoney + def_private_room_bank then
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
			result = GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_ALL,
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
			result = GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_BANK,
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			ip_area = player.ip_area,
			private_room_score_type = msg.private_room_score_type,
			balance_money = def_private_room_bank-bank,
			})
			return
		end]]

		if money < needmoney then
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
			result = GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_MONEY,
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
		--[[send2client_pb(player,  "SC_EnterRoomAndSitDown", {
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			result = GAME_SERVER_RESULT_SUCCESS,
		})]]
		log.info(string.format("on_cs_change_game: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d]",def_game_name,def_game_id,room.room_list_[1].game_switch_is_open))
		if  room.room_list_[1].game_switch_is_open == 1 then --游戏进入维护阶段
			if player.vip ~= 100 then	
				send2client_pb(player, "SC_GameMaintain", {
						result = GAME_SERVER_RESULT_MAINTAIN,
						})
				player:forced_exit()
				log.warning(string.format("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id))	
				return
			end	
		end


		local b_private_room = true
		local result_, room_id_, table_id_, chair_id_, tb
		if msg.private_room_opt == 1 then
			result_, room_id_, table_id_, chair_id_, tb = room:create_private_room(player, msg.private_room_chair_count, msg.private_room_score_type)
			if result_ == GAME_SERVER_RESULT_SUCCESS then
				-- 开房费
				local money = getCreatePrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
				if money > 0 then
					player:change_money(-money, LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM)
				end
			end
		elseif msg.private_room_opt == 2 then
			result_, room_id_, table_id_, chair_id_, tb = room:join_private_room(player, msg.owner_guid)
		else
			result_, room_id_, table_id_, chair_id_, tb = room:enter_room_and_sit_down(player)
			b_private_room = false
		end
		if result_ == GAME_SERVER_RESULT_SUCCESS then
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
					if msg.first_game_type == 8 then --百人牛牛特殊处理，只发送前8位玩家信息
						if #notify.pb_visual_info < 9 then
							table.insert(notify.pb_visual_info, v)
						end	
					else
						table.insert(notify.pb_visual_info, v)
					end
				else
					log.warning(string.format("on_cs_change_game  guid=[%s] table_id=[%s] table_id_[%d]",tostring(p.guid),tostring(p.table_id),table_id_))
				end
			end)
			
			send2client_pb(player, "SC_EnterRoomAndSitDown", notify)

			tb:player_sit_down_finished(player)

			player.noready = nil 
			tb:send_playerinfo(player)
			-- 更新在线信息
			send2db_pb("SD_OnlineAccount", {
				guid = player.guid,
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				gamer_id = def_game_id,
				in_game = 1,
				})

			log.info(string.format("change step this ok,account=%s", player.account))
		else
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
				})

			log.info(string.format("change step this err,account=%s,result [%d]", player.account,result_))
		end
	else
		--room:exit_server(player)
		--player:save2redis()
		
		send2login_pb("SS_ChangeGame", {
			guid = player.guid,
			session_id = player.session_id,
			gate_id = player.gate_id,
			account = player.account,
			nickname = player.nickname,
			vip = player.vip,
			login_time = player.login_time,
			logout_time = player.logout_time,
			h_bank_password = player.has_bank_password,
			bank_login = player.bank_login,
			is_guest = player.is_guest,
			online_award_start_time = player.online_award_start_time,
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			phone = player.phone,
			phone_type = player.phone_type,
			version = player.version,
			channel_id = player.channel_id,
			package_name = player.package_name,
			imei = player.imei,
			ip = player.ip,
			ip_area = player.ip_area,
			risk = player.risk,
			create_channel_id = player.create_channel_id,
			enable_transfer = player.enable_transfer,
			inviter_guid = player.inviter_guid,
			invite_code = player.invite_code,
			pb_base_info = player.pb_base_info,
			private_room_opt = msg.private_room_opt,
			owner_guid = msg.owner_guid,
			private_room_chair_count = msg.private_room_chair_count,
			private_room_score_type = msg.private_room_score_type,
			alipay_account = player.alipay_account,
			alipay_name = player.alipay_name,
			change_alipay_num = player.change_alipay_num,
			bank_password = player.bank_password,
			deprecated_imei = player.deprecated_imei,
			platform_id = player.platform_id,
			bank_card_name = player.bank_card_name,
			bank_card_num = player.bank_card_num,
			change_bankcard_num = player.change_bankcard_num,
			bank_name = player.bank_name,
			bank_province = player.bank_province,
			bank_city = player.bank_city,
			bank_branch = player.bank_branch,
			seniorpromoter = player.seniorpromoter,
			identity_type = player.identity_type,
			identity_param = player.identity_param,
		})
		log.info(string.format("player[%d] has_bank_password[%s] bankpwd[%s] ",player.guid,tostring(player.has_bank_password),tostring(player.bank_password)))
		log.info(string.format("player[%d] bank_card_name[%s] bank_card_num[%s] change_bankcard_num[%s] bank_name[%s] bank_province[%s] bank_city[%s] bank_branch[%s]",
			player.guid, player.bank_card_name , player.bank_card_num, tostring(player.change_bankcard_num),player.bank_name,player.bank_province,player.bank_city,player.bank_branch))
		--send2db_pb("SD_Delonline_player", {
		--guid = player.guid,
		--game_id = def_game_id,
		--})
		
		--player:del()

		log.info(string.format("change step ask login,account=%s", player.account))
	end
end

function on_LS_ChangeGameResult(msg)
	if msg.success then
		local player = base_players[msg.guid]
		if not player then
			log.warning(string.format("==guid[%d] not find in game=%d", msg.guid, def_game_id))
			return
		end

		--避免玩家数据丢失
		if #msg.change_msg > 0 then
			msg.change_msg = pb.decode(msg.change_msg[1], msg.change_msg[2])
			msg.change_msg.pb_base_info = player.pb_base_info
			log.info(string.format("player[%d] has_bank_password[%s] bankpwd[%s]",msg.change_msg.guid,tostring(msg.change_msg.h_bank_password),tostring(msg.change_msg.bank_password)))
		end

		room:exit_server(player)
		player:save()
		--player:save2redis()

		send2db_pb("SD_Delonline_player", {
		guid = player.guid,
		game_id = def_game_id,
		})
	
			player:del()
		
		send2login_pb("SL_ChangeGameResult", msg)
		
		log.info(string.format("change step complete,account=%s", player.account))
	end

	print ("on_LS_ChangeGameResult................................", msg.success)
end

-- 检查是否从Redis中加载完成
local function check_change_complete(player, msg)
	--if player.flag_load_base_info and player.flag_load_item_bag and player.flag_load_mail_list then
	--	player.flag_load_base_info = nil
	--	player.flag_load_item_bag = nil
	--	player.flag_load_mail_list = nil

		local b_private_room = true
		local result_, room_id_, table_id_, chair_id_, tb
		if msg.private_room_opt == 1 then
			result_, room_id_, table_id_, chair_id_, tb = room:create_private_room(player, msg.private_room_chair_count, msg.private_room_score_type)
			if result_ == GAME_SERVER_RESULT_SUCCESS then
				-- 开房费
				local money = getCreatePrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
				if money > 0 then
					player:change_money(-money, LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM)
				end
			end
		elseif msg.private_room_opt == 2 then
			result_, room_id_, table_id_, chair_id_, tb = room:join_private_room(player, msg.owner_guid)
		else
			result_, room_id_, table_id_, chair_id_, tb = room:enter_room_and_sit_down(player)
			b_private_room = false
		end

		

		if result_ == GAME_SERVER_RESULT_SUCCESS then
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
					log.warning(string.format("check_change_complete  guid=[%s] table_id=[%s] table_id_[%d]",tostring(p.guid),tostring(p.table_id),table_id_))
				end
			end)
			
			send2client_pb(player, "SC_EnterRoomAndSitDown", notify)

			tb:player_sit_down_finished(player)

			log.info(string.format("change step other ok,account=%s", player.account))
		else
			if result_ == 14 then --game maintain
				log.warning(string.format("check_change_complete:result_ = [%d], game_name = [%s],game_id =[%d], will maintain,exit",result_,def_game_name,def_game_id))	
			end
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
				})

			log.warning(string.format("change step other error,account=%s", player.account))
		end
	--end
end

function on_ss_change_game(msg)
	local player = base_players[msg.guid]
	if player then
		room:exit_server(player)
		player:del()
		log.warning(string.format("guid[%d] find in game=%d", msg.guid, def_game_id))		
	end
	
	local player = base_player:new()
	player:init(msg.guid, msg.account, msg.nickname)
	
	player.session_id = msg.session_id
	player.gate_id = msg.gate_id
	player.vip = msg.vip
	player.login_time = msg.login_time
	player.logout_time = msg.logout_time
	player.has_bank_password = msg.h_bank_password
	player.bank_password = msg.bank_password
--	log.info(string.format("bankPwdA[%s]",player.bank_password))
--	log.info(string.format("bankPwdA[%s]",msg.bank_password))
	player.bank_login = msg.bank_login ~= 0
	player.is_guest = msg.is_guest
	player.online_award_start_time = msg.online_award_start_time

	player.phone = msg.phone
	player.phone_type = msg.phone_type
	player.version = msg.version
	player.channel_id = msg.channel_id
	player.package_name = msg.package_name
	player.imei = msg.imei
	player.ip = msg.ip
	player.ip_area = msg.ip_area
	player.risk = msg.risk
	player.create_channel_id = msg.create_channel_id
	player.enable_transfer = msg.enable_transfer
	player.inviter_guid = msg.inviter_guid
	player.invite_code = msg.invite_code

	player.deprecated_imei = msg.deprecated_imei
	player.platform_id = msg.platform_id

	player.alipay_account = msg.alipay_account
	player.alipay_name = msg.alipay_name
	player.change_alipay_num = msg.change_alipay_num
	
	player.bank_card_name = msg.bank_card_name
	player.bank_card_num = msg.bank_card_num
	player.change_bankcard_num = msg.change_bankcard_num

	player.bank_name = msg.bank_name
	player.bank_province = msg.bank_province
	player.bank_city = msg.bank_city
	player.bank_branch = msg.bank_branch

	log.info(string.format("player[%d] bank_card_name[%s] bank_card_num[%s] change_bankcard_num[%s] bank_name[%s] bank_province[%s] bank_city[%s] bank_branch[%s]",
		player.guid, player.bank_card_name , player.bank_card_num, tostring(player.change_bankcard_num),player.bank_name,player.bank_province,player.bank_city,player.bank_branch))
	player.seniorpromoter	= msg.seniorpromoter
	player.identity_type	= msg.identity_type
	player.identity_param	= msg.identity_param

	log.info(string.format("player[%d] seniorpromoter[%s] identity_type[%s] identity_param[%s]",player.guid,tostring(player.seniorpromoter),tostring(player.identity_type),tostring(player.identity_param)))

	player.flag_load_base_info = nil
	player.flag_load_item_bag = nil
	player.flag_load_mail_list = nil
	log.info(string.format("player[%d] has_bank_password[%s] bankpwd[%s] platform_id[%s]",player.guid,tostring(player.has_bank_password),tostring(player.bank_password),player.platform_id))
	-- 更新在线信息
	send2db_pb("SD_OnlineAccount", {
		guid = player.guid,
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		gamer_id = def_game_id,
		in_game = 1,
		})

	redis_command(string.format("HSET player_online_gameid %d %d", player.guid, def_game_id))

	if #msg.pb_base_info > 0 then
		local data = pb.decode(msg.pb_base_info[1], msg.pb_base_info[2])

		data.money = data.money or 0
		data.bank = data.bank or 0
		player.pb_base_info = data
		
		check_change_complete(player, msg)
	end

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

		add_timer(def_save_db_time, save_db_timer)
	end
	save_db_timer()

	log.info(string.format("change step login notify,account=%s", player.account))

	--[[local guid = player.guid
	redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
		if reply:is_string() then
			local player = base_players[guid]
			if not player then
				log.warning(string.format("guid[%d] not find in game", guid))
				return
			end]]--

			-- 基本数据
	---		player.pb_base_info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
			
			--player.flag_load_base_info = true
	---		check_change_complete(player, msg)
			
			-- 背包数据
			--[[redis_cmd_query(string.format("HGET player_bag_info %d", guid), function (reply)
				local player = base_players[guid]
				if not player then
					log.warning(string.format("guid[%d] not find in game", guid))
					return
				end

				if reply:is_string() then
					local data = pb.decode("ItemBagInfo", from_hex(reply:get_string()))
					for i, item in ipairs(data.pb_items) do
						data.pb_items[i] = pb.decode(item[1], item[2])
					end

					player.pb_item_bag = data
				end

				player.flag_load_item_bag = true -- flag
				check_change_complete(player, msg)
			end)]]--

			-- 邮件数据
			--[[redis_cmd_query(string.format("HGET player_mail_info %d", guid), function (reply)
				local player = base_players[guid]
				if not player then
					log.warning(string.format("guid[%d] not find in game", guid))
					return
				end

				if reply:is_string() then
					local data = pb.decode("MailListInfo", from_hex(reply:get_string()))
					for i, item in ipairs(data.pb_mails) do
						data.pb_mails[i] = pb.decode(item[1], item[2])
						for j, item in ipairs(data.mails[i].pb_attachment) do
							data.mails[i].pb_attachment[j] = pb.decode(item[1], item[2])
						end
					end

					player.pb_mail_list = data
				end
				
				player.flag_load_mail_list = true -- flag
				check_change_complete(player, msg)
			end)]]--
	---	end
	---end)

	--[[send2db_pb("SD_QueryPlayerData", {
		guid = player.guid,
		account = player.account,
		nickname = player.nickname,
	})
	
	send2client_pb(player,  "SC_EnterRoomAndSitDown", {
		game_id = def_game_id,
		first_game_type = msg.first_game_type,
		second_game_type = msg.second_game_type,
		result = GAME_SERVER_RESULT_SUCCESS,
	})]]
end

-- 加入私人房间
function on_CS_JoinPrivateRoom(player, msg)
	send2cfg_pb("SS_JoinPrivateRoom", {
		owner_guid = msg.owner_guid,
		guid = player.guid,
		game_id = def_game_id,
	})
end

function on_SS_JoinPrivateRoom(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end


	if msg.owner_game_id > 0 then
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

		local money = player.pb_base_info.money or 0
		local bank = player.pb_base_info.bank or 0
		
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

	--[[
	send2client_pb(player, "SC_PrivateRoomInfo", {
		pb_info = {
		{first_game_type = 5, table_count = {3}, cell_money = {10,30,50,100}},
		{first_game_type = 6, table_count = {2,3,4,5}, cell_money = {10,100,500,1000,2000}},
		},
	})
	]]--
end

-- 完善账号
function on_cs_reset_account(player, msg)
	if (not player.is_guest) and (not player.flag_wait_reset_account) then
		send2client_pb(player,  "SC_ResetAccount", {
			result = LOGIN_RESULT_RESET_ACCOUNT_FAILED,
			account = msg.account,
			nickname = msg.nickname,
		})

		log.warning(string.format("reset account error isguest[%d], %d", (player.is_guest and 1 or 0), (player.flag_wait_reset_account and 1 or 0)))
		return
	end

	if  string.find(msg.account,"170") == 1 or string.find(msg.account,"171") == 1 then
		send2client_pb(player,  "SC_ResetAccount", {
			result = LOGIN_RESULT_TEL_ERR,
			account = msg.account,
			nickname = msg.nickname,
		})
		log.warning(string.format("reset account error player.guid[%d], account[%s] start with 170 or 171",player.guid,msg.account))
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

	print "on_cs_reset_account ..........................."
end

function do_on_ds_reset_account(msg, register_money)
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end

	if msg.ret == LOGIN_RESULT_SUCCESS then
		player.is_guest = false

		player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = register_money}}, LOG_MONEY_OPT_TYPE_RESET_ACCOUNT)

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
	--	log.warning(string.format("guid[%d] reset account sql error", msg.guid))
	end
	player.flag_wait_reset_account = nil

	send2client_pb(player,  "SC_ResetAccount", {
		result = msg.ret,
		account = msg.account,
		nickname = msg.nickname,
	})

	print "on_ds_reset_account ..........................."
end

function on_ds_reset_account (msg)

	redis_cmd_query(string.format("GET register_money"), function (reply)
		if type(reply) == "string" or type(reply) == "number" then
			local register_money = tonumber(reply)
			log.info(string.format("register_money = [%d]", register_money))
			if tonumber(msg.addflag) == 0 then
				register_money = 0
			end
			do_on_ds_reset_account(msg, register_money)
			
		else
			log.error(string.format("on_ds_reset_account get register_money error guid[%d]", msg.guid))
		end
	end)
end

-- 绑定支付宝
function on_cs_bandalipay(player, msg)
	print ("on_cs_bandalipay ........................... start:", player.change_alipay_num, alipay_account, alipay_name, player.is_guest)
	print (player.change_alipay_num > 0, player.alipay_account == "", player.alipay_name == "")
	if player.change_alipay_num > 0 and (player.alipay_account == "" and player.alipay_name == "")  then		
		print "on_cs_bandalipay ........................... to db"
		send2db_pb("SD_BandAlipay", {
			guid = player.guid,
			alipay_account = msg.alipay_account,
			alipay_name = msg.alipay_name,
			platform_id = player.platform_id,
		})
	else
		print "on_cs_bandalipay ........................... false"
		send2client_pb(player, "SC_BandAlipay", {
			result = GAME_BAND_ALIPAY_CHECK_ERROR,
			alipay_account = "",
			alipay_name = "",
			})
	end
end

function on_ds_bandalipay(msg)	
	print ("on_ds_bandalipay ........................... ", msg.result )
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
	print "on_ds_bandalipaynum ........................... "
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
		log.warning(string.format("guid[%d] not find in game", msg.guid))
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
		log.warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end

	if msg.ret == LOGIN_RESULT_SUCCESS then
		local account_key = get_account_key(player.account,player.platform_id)
		-- redis数据修改
		redis_cmd_query(string.format("HGET player:login:info %s", account_key), function (reply)
			if type(reply) == "string" then
				local info = pb.decode("PlayerLoginInfo", from_hex(reply))
				info.nickname = msg.nickname
				redis_command(string.format("HSET player:login:info %s %s", account_key, to_hex(pb.encode("PlayerLoginInfo", info))))
				redis_command(string.format("HSET player:login:info:guid %s %s", player.guid, to_hex(pb.encode("PlayerLoginInfo", info))))
			end
		end)

		player.nickname = msg.nickname
	end

	send2client_pb(player,  "SC_SetNickname", {
		nickname = msg.nickname,
		result = msg.ret,
	})
end

-- 修改头像
function on_cs_change_header_icon(player, msg)
	local header_icon = player.pb_base_info.header_icon or 0
	if msg.header_icon ~= header_icon then
		player.pb_base_info.header_icon = msg.header_icon
		player.flag_base_info = true
	end

	send2client_pb(player,  "SC_ChangeHeaderIcon", {
		header_icon = msg.header_icon,
	})
end

-- 添加机器人
local function add_android(opt_type, room_id, android_list)
	if opt_type == GM_ANDROID_ADD_ACTIVE then
		for _, v in ipairs(android_list) do
			local a = base_active_android:new()
			a:init(room_id, v.guid, v.account, v.nickname)
		end
	elseif opt_type == GM_ANDROID_ADD_PASSIVE then
		for _, v in ipairs(android_list) do
			local a = base_passive_android:new()
			a:init(room_id, v.guid, v.account, v.nickname)
		end
	end
end

-- gm命令操作回调
function on_gm_android_opt(opt_type_, roomid_, num_)
	print "on_gm_android_opt .........................."

	if not room:find_room(roomid_) then
		log.error("on_gm_android_opt room not find")
		return
	end

	if opt_type_ == GM_ANDROID_ADD_ACTIVE or opt_type_ == GM_ANDROID_ADD_PASSIVE then
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
	elseif opt_type_ == GM_ANDROID_SUB_ACTIVE then
		base_active_android:sub_android(roomid_, num_)
	elseif opt_type_ == GM_ANDROID_SUB_PASSIVE then
		base_passive_android:sub_android(roomid_, num_)
	end
end

-- 返回机器人数据
function on_ds_load_android_data(msg)
	print "on_ds_load_android_data .........................."

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
	-- body
	local player = base_players[msg.guid]
	if player then
		if msg.pb_msg_data then
			--player.msg_data_info = msg.pb_msg_data.pb_msg_data_info
			--if msg.first then
				send2client_pb(player,"SC_NewMsgData",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			--else
			--	send2client_pb(player,"SC_QueryPlayerMsgData",{
			--		pb_msg_data = msg.pb_msg_data.pb_msg_data_info
			--	})
			--end
		else
			send2client_pb(player,"SC_QueryPlayerMsgData")
		end
	else
		log.info(string.format("on_ds_QueryPlayerMsgData not find player , guid :%d",msg.guid))
	end
end

function on_cs_QueryPlayerMsgData( player, msg )
	-- body
	print ("on_ds_QueryPlayerMsgData .........................."..player.guid)
	send2db_pb("SD_QueryPlayerMsgData", {
		guid = player.guid,
		platform_id = player.platform_id,
	})
end

function on_ds_QueryPlayerMarquee(msg)
	-- body
	print ("on_ds_QueryPlayerMarquee .........................."..msg.guid)

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
		print("on_ds_QueryPlayerMarquee not find player , guid : " ..msg.guid)
	end
end

function on_cs_QueryPlayerMarquee( player, msg )
	print ("on_cs_QueryPlayerMarquee .........................."..player.guid)
	send2db_pb("SD_QueryPlayerMarquee", {
		guid = player.guid,
		platform_id = player.platform_id,
	})
end

function on_cs_SetMsgReadFlag( player, msg )
	-- body
	print ("on_cs_SetMsgReadFlag .........................."..player.guid)
	send2db_pb("SD_SetMsgReadFlag", {
		guid = player.guid,
		id = msg.id,
		msg_type = msg.msg_type,
	})
end

function  on_ds_LoadOxConfigData(msg)
	--print("on_ds_LoadOxConfigData...................................test ")
	--ox_table:reload_many_ox_DB_config(msg)
end

-- 修改税率
function on_ls_set_tax(msg)
	print("on_ls_SetTax...................................on_ls_set_tax")
	print(msg.tax, msg.is_show, msg.is_enable)
	room:change_tax(msg.tax, msg.is_show, msg.is_enable)
	local nmsg = {
	webid = msg.webid,
	result = 1,
	}
	send2login_pb("SL_ChangeTax",nmsg)
end
function on_ls_FreezeAccount( msg )
	print("on_ls_FreezeAccount...................................start")
	-- body
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
		print(" not find player :",notify.ret)
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
		print("=======================disable == 1")
		if not room:is_play(player) then
			print("on_ls_FreezeAccount.....................player not in play forced_exit")
			-- 强行T下线
			player:forced_exit();
		end
	end
	send2loginid_pb(msg.login_id,"SL_FreezeAccount",notify)
end
--修改玩家 bank 金币 retcode 0 成功 1 玩家未找到 2 扣减时玩家金币不够
function on_ls_cc_changemoney(msg)
	log.info(string.format("on_ls_cc_changemoney start : guid [%d] transfer_id[%s]",msg.player_guid,msg.transfer_id))
	-- body
	local player = base_players[msg.player_guid]
	if not player then
		log.info(string.format("on_ls_cc_changemoney : guid [%d] transfer_id[%s] player not online",msg.player_guid,msg.transfer_id))
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
	if player and  player.pb_base_info then		
		retcode,notify.player_oldmoney,notify.player_newmoney = player:changeBankMoney(msg.transfer_money,log_money_type, true)
	else		
		log.info(string.format("on_ls_cc_changemoney : guid [%d] transfer_id[%s] player or player.pb_base_info is nil",msg.player_guid,msg.transfer_id))		
	end
	log.info(string.format("on_ls_cc_changemoney : guid [%d] transfer_id[%s]  retcode:[%d]",msg.player_guid,msg.transfer_id,retcode))

	if tonumber(retcode) == ChangMoney_Success then -- success
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
	print("on_ds_chang_config...................................on_ds_chang_config")

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
		local tb = eval(msg.room_list )
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
	print("on_ds_server_config...................................on_ds_server_config")
	if msg.cfg.room_list ~= "" then	
		print(msg.cfg.room_list)
		local tb = json.decode(msg.cfg.room_list)
		g_room:gm_update_cfg(tb, msg.cfg.room_lua_cfg)
	else			
		log.error("on_ds_server_config error")
	end
end


function  on_lg_updatebankmoney( msg )
	-- body
	local player = base_players[msg.guid]
	if not player  then
		log.info(string.format("on_lg_updatebankmoney error not find player guid [%d] , bankmoney [%d] " , msg.guid, msg.bankmoney))
		return
	end
	log.info(string.format("on_lg_updatebankmoney  guid[%d] bankmoney[%d]", player.guid, msg.bankmoney))
	player.pb_base_info.bank = msg.bankmoney
end
function on_cs_change_maintain(msg)
	print("on_cs_change_maintain...................................on_cs_change_maintain")
	--msg.maintaintype  // 维护类型(1提现维护,2游戏维护,登录开关3)
	--msg.switchopen	// 开关(1维护中,0正常))	
	print("-----------id value",msg.maintaintype,msg.switchopen)
	if msg.maintaintype == 1 then --提现
		cash_switch = msg.switchopen
	elseif msg.maintaintype == 2 then --游戏
		game_switch = msg.switchopen
		if game_switch == 1 then
			--[[room:broadcast2client_by_player("SC_GameMaintain", {
			result = GAME_SERVER_RESULT_MAINTAIN,
			}) --广播游戏维护状态--]]
			room:foreach_by_player(function (player) 
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
			log.error(string.format("on_CS_RequestProxyConfig error platform_id:%d", platform_id_))

			send2login_pb("SL_RequestProxyInfo",{platform_id = platform_id_})
		end
	end)
end


function on_CS_QueryRechargeAndCashSwitch( player )
	-- body
	--先从redis读取平台总个数
	if not player then
		return
	end

	local recharge_switch = {}
	local recharge_platform = "platform_recharge_"..tostring(player.platform_id)
	log.info(string.format("recharge:recharge_platform = [%s]",tostring(recharge_platform)))

	--查询当前玩家所属平台的充值开关
	redis_cmd_query(string.format("get %s",recharge_platform), function (reply)
		if type(reply) == "string" then	
			local pay_switch_json = tostring(reply)
			log.info(pay_switch_json)
			send2client_pb(player,"SC_ReplyClientPaySwitch",{recharge_switch_json = pay_switch_json})
		else
			log.error(string.format("get [%s] error from redis.",tostring(recharge_platform)))
			return
		end
	end)

	--查询并发送当前玩家所属平台的兑换开关
	local all_cash_switch = {}
	local all_cash_switch_platform = "platform_all_cash_"..tostring(player.platform_id)
	log.info(string.format("all cash:all_cash_switch_platform = [%s]",tostring(all_cash_switch_platform)))

	redis_cmd_query(string.format("get %s",all_cash_switch_platform), function (reply)
		if type(reply) == "string" then	
			local cash_switch_json = tostring(reply)
			log.info(cash_switch_json)
			--local test_str = json.decode(cash_switch_json)
			--if test_str then
			--	log.error(string.format("cash_switch[%s] agent_cash_switch[%s] banker_transfer_switch[%s] bank_card_cash_switch[%s] online_card_cash_switch[%s]", 
			--		tostring(test_str.cash_switch), tostring(test_str.agent_cash_switch), tostring(test_str.banker_transfer_switch), tostring(test_str.bank_card_cash_switch), tostring(test_str.online_card_cash_switch)))
			--	if test_str.cash_switch == true or test_str.cash_switch == false then
			--		log.error("111111111112222222222222233333333333333")
			--	end
			--end
			send2client_pb(player,"SC_ReplyClientAllCashSwitch",{all_cash_switch_json = cash_switch_json})
		else
			log.error(string.format("get [%s] error from redis.",tostring(all_cash_switch_platform)))
			return
		end
	end)



	--send_platform_all_switch(player)

	----查询当前玩家所属平台的提现开关
	--local cash_platform = "platform_cash_"..tostring(player.platform_id)
	--local cash_key = "cash_switch"
	--log.info(string.format("cash:cash_platform = [%s]",tostring(cash_platform)))
--
	--redis_cmd_query(string.format("HGET %s %s",cash_platform,cash_key), function (reply)
	--	if reply:is_string()then	
	--		local cash_switch_value = tostring(reply:get_string())
	--		log.info(cash_switch_value)
	--		if tostring(cash_switch_value) ~= "false" and tostring(cash_switch_value) ~= "true" then
	--			log.error(string.format("HGET [%s] [%s] error from redis.",tostring(cash_platform),cash_key))
	--			send2client_pb(player,"SC_ReplyClientCashSwitch",{cash_switch = false})
	--			return
	--		end
	--		local result = false
	--		if tostring(cash_switch_value) == "true" then
	--			result = true
	--		end
	--		log.info(string.format("send to player guid[%d] SC_ReplyClientCashSwitch......",player.guid))
	--		send2client_pb(player,"SC_ReplyClientCashSwitch",{cash_switch = result})
	--	else
	--		log.error(string.format("HGET [%s] error from redis.",tostring(cash_platform)))
	--		return
	--	end
	--end)
--
--
	----查询当前玩家所属平台玩家通过代理提现开关
	--local var_platform = "platform_PlayerToAgent_cash_"..tostring(player.platform_id)
	--local switch_key = "agent_cash_switch"
	--
	--log.info(string.format("playertoagentcash switch: var_platform = [%s]",tostring(var_platform)))
--
	--redis_cmd_query(string.format("HGET %s %s",var_platform,switch_key), function (reply)
	--	if reply:is_string()then	
	--		local playertoagent_cash_switch_value = tostring(reply:get_string())
	--		log.info(playertoagent_cash_switch_value)
	--		if tostring(playertoagent_cash_switch_value) ~= "false" and tostring(playertoagent_cash_switch_value) ~= "true" then
	--			log.error(string.format("HGET [%s] [%s] error from redis.",tostring(var_platform),switch_key))
	--			send2client_pb(player,"SC_ReplyClientPlayerToAgentCashSwitch",{agent_cash_switch = false})
	--			return
	--		end
	--		local result = false
	--		if tostring(playertoagent_cash_switch_value) == "true" then
	--			result = true
	--		end
	--		log.info(string.format("send to player guid[%d] SC_ReplyClientPlayerToAgentCashSwitch......result[%s]",player.guid,tostring(result)))
	--		send2client_pb(player,"SC_ReplyClientPlayerToAgentCashSwitch",{agent_cash_switch = result})
	--	else
	--		log.error(string.format("hget [%s] [%s]error from redis.",tostring(var_platform),switch_key))
	--		return
	--	end
	--end)	
--
--
	----查询当前玩家所属平台玩家转账开关
	--local var_platform = "platform_bankerTransfer_"..tostring(player.platform_id)
	--local switch_key = "banker_transfer_switch"
	--log.info(string.format("bankerTransfer switch: var_platform = [%s]",tostring(var_platform)))
	--redis_cmd_query(string.format("HGET %s %s",var_platform,switch_key), function (reply)
	--	if reply:is_string()then	
	--		local banker_transfer_switch_value = tostring(reply:get_string())
	--		log.info(banker_transfer_switch_value)
	--		if tostring(banker_transfer_switch_value) ~= "false" and tostring(banker_transfer_switch_value) ~= "true" then
	--			log.error(string.format("HGET [%s] [%s] error from redis.",tostring(var_platform),switch_key))
	--			send2client_pb(player,"SC_ReplyClientBankerTransferSwitch",{banker_transfer_switch = false})
	--			return
	--		end
	--		local result = false
	--		if tostring(banker_transfer_switch_value) == "true" then
	--			result = true
	--		end
	--		log.info(string.format("send to player guid[%d] SC_ReplyClientBankerTransferSwitch......result[%s]",player.guid,tostring(result)))
	--		send2client_pb(player,"SC_ReplyClientBankerTransferSwitch",{banker_transfer_switch = result})
	--	else
	--		log.error(string.format("hget [%s] [%s]error from redis.",tostring(var_platform),switch_key))
	--		return
	--	end
	--end)	

end

function on_cs_change_recharge_switch(msg)
	log.info(string.format("on_cs_change_recharge_switch...................................platform_id[%d]",msg.platform_id))
	local cur_platform_id = msg.platform_id
	local player_num = 0
	local var_platform = "platform_recharge_"..tostring(msg.platform_id)
	log.info(string.format("~~~~~~~~~~~~~~~~recharge switch:update platform = [%s] and broadcast all players in this platform ",tostring(var_platform)))

	redis_cmd_query(string.format("get %s",var_platform), function (reply)
		if type(reply) == "string" then	
			local pay_switch_json = tostring(reply)
			log.info(pay_switch_json)
			
			base_players:foreach(function (player) 
				if player and tonumber(cur_platform_id) == tonumber(player.platform_id) then --非系统玩家广播充值开关汇总
					log.info(string.format("send to player guid[%d] SC_ReplyClientPaySwitch......",player.guid))
					send2client_pb(player,"SC_ReplyClientPaySwitch",{recharge_switch_json = pay_switch_json})
				end
			end)	
		else
			log.error(string.format("get [%s] error from redis.",tostring(var_platform)))
			return
		end
	end)	
end

function on_cs_change_all_cash_switch(msg)
	log.info(string.format("on_cs_change_all_cash_switch...................................platform_id[%d]",msg.platform_id))
	local cur_platform_id = msg.platform_id
	local player_num = 0
	local var_platform = "platform_all_cash_"..tostring(msg.platform_id)
	log.info(string.format("~~~~~~~~~~~~~~~~all cash switch:update platform = [%s] and broadcast all players in this platform ",tostring(var_platform)))

	redis_cmd_query(string.format("get %s",var_platform), function (reply)
		if type(reply) == "string" then	
			local cash_switch_json = tostring(reply)
			log.info(cash_switch_json)
			
			base_players:foreach(function (player) 
				if player and tonumber(cur_platform_id) == tonumber(player.platform_id) then --非系统玩家广播充值开关汇总
					log.info(string.format("send to player guid[%d] all_cash_switch_json......",player.guid))
					send2client_pb(player,"SC_ReplyClientAllCashSwitch",{all_cash_switch_json = cash_switch_json})
				end
			end)	
		else
			log.error(string.format("get [%s] error from redis.",tostring(var_platform)))
			return
		end
	end)	
end


--function on_cs_change_cash_switch(msg)
--	log.info(string.format("on_cs_change_cash_switch...................................platform_id[%d]",msg.platform_id))
--	local cur_platform_id = msg.platform_id
--	local player_num = 0
--	local var_platform = "platform_cash_"..tostring(msg.platform_id)
--	local cash_key = "cash_switch"
--	local result = false
--	log.info(string.format("cash switch:update platform = [%s] and broadcast all players in this platform ",tostring(var_platform)))
--
--	redis_cmd_query(string.format("HGET %s %s",var_platform,cash_key), function (reply)
--		if reply:is_string()then	
--			local cash_switch_value = tostring(reply:get_string())
--			log.info(cash_switch_value)
--			if tostring(cash_switch_value) ~= "false" and tostring(cash_switch_value) ~= "true" then
--				log.error(string.format("HGET [%s] [%s] error from redis.",tostring(var_platform),cash_key))
--				cash_switch_value = "false"
--			end
--			
--			if tostring(cash_switch_value) == "true" then
--				result = true
--			end
--			base_players:foreach(function (player) 
--				if player and tonumber(cur_platform_id) == tonumber(player.platform_id) then --非系统玩家广播充值开关汇总
--					log.info(string.format("send to player guid[%d] SC_ReplyClientCashSwitch......",player.guid))
--					send2client_pb(player,"SC_ReplyClientCashSwitch",{cash_switch = result})
--				end
--			end)	
--		else
--			log.error(string.format("hget [%s] [%s]error from redis.",tostring(var_platform),cash_key))
--			return
--		end
--	end)	
--end
--
--
--function on_cs_change_playertoagent_cash_switch(msg)
--	log.info(string.format("on_cs_change_playertoagent_cash_switch...................................platform_id[%d]",msg.platform_id))
--	local cur_platform_id = msg.platform_id
--	local player_num = 0
--	local var_platform = "platform_PlayerToAgent_cash_"..tostring(msg.platform_id)
--	local switch_key = "agent_cash_switch"
--	local result = false
--	log.info(string.format("playertoagentcash switch:update platform = [%s] and broadcast all players in this platform ",tostring(var_platform)))
--
--	redis_cmd_query(string.format("HGET %s %s",var_platform,switch_key), function (reply)
--		if reply:is_string()then	
--			local playertoagent_cash_switch_value = tostring(reply:get_string())
--			log.info(playertoagent_cash_switch_value)
--			if tostring(playertoagent_cash_switch_value) ~= "false" and tostring(playertoagent_cash_switch_value) ~= "true" then
--				log.error(string.format("HGET [%s] [%s] error from redis.",tostring(var_platform),switch_key))
--				playertoagent_cash_switch_value = "false"
--			end
--			
--			if tostring(playertoagent_cash_switch_value) == "true" then
--				result = true
--			end
--			base_players:foreach(function (player) 
--				if player and tonumber(cur_platform_id) == tonumber(player.platform_id) then --非系统玩家广播充值开关汇总
--					log.info(string.format("send to player guid[%d] SC_ReplyClientPlayerToAgentCashSwitch......result[%s]",player.guid,tostring(result)))
--					send2client_pb(player,"SC_ReplyClientPlayerToAgentCashSwitch",{agent_cash_switch = result})
--				end
--			end)	
--		else
--			log.error(string.format("hget [%s] [%s]error from redis.",tostring(var_platform),switch_key))
--			return
--		end
--	end)	
--end
--
--
--
--function on_cs_change_banker_transfer_switch(msg)
--	log.info(string.format("on_cs_change_banker_transfer_switch...................................platform_id[%d]",msg.platform_id))
--	local cur_platform_id = msg.platform_id
--	local player_num = 0
--	local var_platform = "platform_bankerTransfer_"..tostring(msg.platform_id)
--	local switch_key = "banker_transfer_switch"
--	local result = false
--	log.info(string.format("banker_transfer_switch:update platform = [%s] and broadcast all players in this platform ",tostring(var_platform)))
--
--	redis_cmd_query(string.format("HGET %s %s",var_platform,switch_key), function (reply)
--		if reply:is_string()then	
--			local banker_transfer_switch_value = tostring(reply:get_string())
--			log.info(banker_transfer_switch_value)
--			if tostring(banker_transfer_switch_value) ~= "false" and tostring(banker_transfer_switch_value) ~= "true" then
--				log.error(string.format("HGET [%s] [%s] error from redis.",tostring(var_platform),switch_key))
--				banker_transfer_switch_value = "false"
--			end
--			
--			if tostring(banker_transfer_switch_value) == "true" then
--				result = true
--			end
--			base_players:foreach(function (player) 
--				if player and tonumber(cur_platform_id) == tonumber(player.platform_id) then --非系统玩家广播充值开关汇总
--					log.info(string.format("send to player guid[%d] SC_ReplyClientBankerTransferSwitch......result[%s]",player.guid,tostring(result)))
--					send2client_pb(player,"SC_ReplyClientBankerTransferSwitch",{banker_transfer_switch = result})
--				end
--			end)	
--		else
--			log.error(string.format("hget [%s] [%s]error from redis.",tostring(var_platform),switch_key))
--			return
--		end
--	end)	
--end


-- 绑定银行卡
function on_cs_bandbankcard(player, msg)
	log.info(string.format("player guid[%d] start band bankcard, bank_card_name[%s] bank_card_num[%s] bank_name[%s] bank_province[%s] bank_city[%s] bank_branch[%s] change_bankcard_num[%d]",
		player.guid, msg.bank_card_name , msg.bank_card_num , msg.bank_name , msg.bank_province , msg.bank_city , msg.bank_branch , tonumber(player.change_bankcard_num)))
	log.info(string.format("change_bankcard_num [%s] bank_card_name[%s] bank_card_num[%s] is_guest[%s]" , tostring(player.change_bankcard_num) , tostring(player.bank_card_name) , tostring(player.bank_card_num) , tostring(player.is_guest)))
	if player.change_bankcard_num > 0 and (player.bank_card_name == "**" and player.bank_card_num == "**") then
		log.info(string.format("player [%d] band_bank_cards~~~~~~~~~~~~~~~!" , player.guid))
		send2db_pb("SD_BandBankcard", {
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
		log.info(string.format("player [%d] band_bank_cards false~~~~~~~~~~~~~~~!" , player.guid))
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
	print ("on_ds_bandbankcard ........................... ", msg.result)
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
	-- body
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
	log.info(string.format("on_ds_bandbankcardnum-------------------->player guid[%d] change_bankcard_num[%d]",msg.guid,msg.band_card_num))
	local player = base_players[msg.guid]
	if player then	
		player.change_bankcard_num = msg.band_card_num
	end
end

function  replace_bankcard_name_or_num_str(input_type,input_str)
	-- body
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

--function on_ls_update_platform_switch_info( msg )
--	-- body
--	log.info(string.format("on_ls_update_platform_switch_info---------------->platform_id[%d] switch_type[%d] redis_key[%s] switch_key[%s]",msg.platform_id,msg.switch_type,msg.redis_key,msg.switch_key))
--
--	local cur_platform_id = msg.platform_id
--	local player_num = 0
--	local var_platform = msg.redis_key
--	local switch_key = msg.switch_key
--	local result = false
--	local notice_head = "SC_ReplyClientCashSwitch"
--	local temp_switch_type = msg.switch_type
--	
--	if temp_switch_type < 0 or temp_switch_type > 4 then
--		log.error("temp_switch_type error")
--		return
--	end
--
--
--	redis_cmd_query(string.format("HGET %s %s",var_platform,switch_key), function (reply)
--		if reply:is_string()then	
--			local switch_value = tostring(reply:get_string())
--			log.info(switch_value)
--			if tostring(switch_value) ~= "false" and tostring(switch_value) ~= "true" then
--				log.error(string.format("HGET [%s] [%s] error from redis.",tostring(var_platform),switch_key))
--				switch_value = "false"
--			end
--			
--			if tostring(switch_value) == "true" then
--				result = true
--			end
--			local notice_msg = {}
--			--开关类型(1:兑换开关;2:银行转账开关;3:代理兑换开关;4:银联卡兑换开关)
--			if temp_switch_type == 1 then
--				notice_head = "SC_ReplyClientCashSwitch"
--				notice_msg = {cash_switch = result} 
--			elseif temp_switch_type == 2 then
--				notice_head = "SC_ReplyClientBankerTransferSwitch"
--				notice_msg = {banker_transfer_switch = result} 
--			elseif temp_switch_type == 3 then
--				notice_head = "SC_ReplyClientPlayerToAgentCashSwitch"
--				notice_msg = {agent_cash_switch = result} 
--			elseif temp_switch_type == 4 then
--				notice_head = "SC_ReplyClientSwitchInfo"
--				notice_msg = {switch_type = 4,switch_status = result} 
--			else
--				return
--			end	
--
--			base_players:foreach(function (player) 
--				if player and tonumber(cur_platform_id) == tonumber(player.platform_id) then --非系统玩家广播充值开关汇总
--					log.info(string.format("send to player guid[%d] notice_head[%s] ------------->result[%s]",player.guid,notice_head,tostring(result)))
--					send2client_pb(player,notice_head,notice_msg)
--				end
--			end)	
--		else
--			log.error(string.format("hget [%s] [%s]error from redis.",tostring(var_platform),switch_key))
--			return
--		end
--	end)	
--end
--
--function check_all_switch_info(var_platform,switch_key,func)
--	log.info(string.format("var_platform---->[%s] switch_key------->[%s]",var_platform,switch_key))
--	redis_cmd_query(string.format("HGET %s %s",var_platform,switch_key), function (reply)
--		if reply:is_string()then	
--			local result = false
--			local switch_value = tostring(reply:get_string())
--			
--			if tostring(switch_value) == "true" then
--				result = true
--			end
--			func(result)
--		else
--			log.error(string.format("hget [%s] [%s]error from redis.",tostring(var_platform),switch_key))
--			func(false)
--		end
--	end)	
--end
--
--
--function send_platform_all_switch(player)
--	-- body
--
--	--开关类型(1:兑换开关;2:银行转账开关;3:代理兑换开关;4:银联卡兑换开关)
--	for i=1,4 do
--		if i == 1 then
--			local  notice_head_1 = "SC_ReplyClientCashSwitch"
--			local redis_key_1 = "platform_cash_"..tostring(player.platform_id)
--			local switch_key_1 = "cash_switch"
--			check_all_switch_info(redis_key_1,switch_key_1,function (switch_value_1)
--				local notice_msg_1 = {cash_switch = switch_value_1} 
--				log.info(string.format("player guid[%d] notice_head = [%s] switch_value = [%s]", player.guid, notice_head_1, switch_value_1))
--				send2client_pb(player,notice_head_1,notice_msg_1)
--			end)
--		elseif i==2 then
--			local redis_key_2 = "platform_bankerTransfer_"..tostring(player.platform_id)
--	 		local switch_key_2 = "banker_transfer_switch"
--			local notice_head_2 = "SC_ReplyClientBankerTransferSwitch"
--			check_all_switch_info(redis_key_2,switch_key_2,function (switch_value_2)
--				local notice_msg_2 = {banker_transfer_switch = switch_value_2} 
--				log.info(string.format("player guid[%d] notice_head = [%s] switch_value = [%s]", player.guid, notice_head_2, switch_value_2))
--				send2client_pb(player,notice_head_2,notice_msg_2)
--			end)
--		elseif i == 3 then
--			local redis_key_3 = "platform_PlayerToAgent_cash_"..tostring(player.platform_id)
--	 		local switch_key_3 = "agent_cash_switch"
--			local notice_head_3 = "SC_ReplyClientPlayerToAgentCashSwitch"
--			check_all_switch_info(redis_key_3,switch_key_3,function (switch_value_3)
--				local notice_msg_3 = {agent_cash_switch = switch_value_3} 
--				log.info(string.format("player guid[%d] notice_head = [%s] switch_value = [%s]", player.guid, notice_head_3, switch_value_3))
--				send2client_pb(player,notice_head_3,notice_msg_3)
--			end)
--		elseif i == 4 then
--		 	local redis_key_4 = "platform_bankcardswitch_"..tostring(player.platform_id)
--	 		local switch_key_4 = "bank_card_cash_switch"
--			local notice_head_4 = "SC_ReplyClientSwitchInfo"
--			check_all_switch_info(redis_key_4,switch_key_4,function (switch_value_4)
--				local notice_msg_4 = {switch_type = 4,switch_status = switch_value_4} 
--				log.info(string.format("player guid[%d] notice_head = [%s] switch_value = [%s]", player.guid, notice_head_4, switch_value_4))
--				send2client_pb(player,notice_head_4,notice_msg_4)
--			end)
--		else
--			return
--		end
--
--	end
--
--end