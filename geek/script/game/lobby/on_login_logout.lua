-- 登陆，退出，切换服务器消息处理
local common = require "game.common"
local allonlineguid = require "allonlineguid"
require "game.net_func"

local player_context = require "game.lobby.player_context"
local player_data = require "game.lobby.player_data"
local sessions = require "game.sessions"

require "game.lobby.base_android"

local channel = require "channel"
local log = require "log"
local redisopt = require "redisopt"
local json = require "json"
local onlineguid = require "netguidopt"
local base_clubs = require "game.club.base_clubs"
local base_private_table = require "game.lobby.base_private_table"
local table_template = require "game.lobby.table_template"
local enum = require "pb_enums"
local player_money = require "game.lobby.player_money"
local club_money_type = require "game.club.club_money_type"
require "functions"
local runtime_conf = require "game.runtime_conf"
local game_util = require "game.util"
local g_util = require "util"
local base_rule = require "game.lobby.base_rule"
local club_table = require "game.club.club_table"
local g_common = require "common"
local club_utils = require "game.club.club_utils"

local reddb = redisopt.default

local string = string
local strfmt = string.format
local table = table
local tinsert = table.insert
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

function on_cs_update_location_gps(msg,guid)
	local player = player_data[guid]
	if not player then
		send2client_pb(player,"SC_UpdateLocation",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

	local longitude = msg.longitude
	local latitude = msg.latitude

	if not longitude or not latitude then
		send2client_pb(player,"SC_UpdateLocation",{
			result = enum.PARAMETER_ERROR
		})
		return
	end

	log.info("on_cs_update_location_gps,guid:%s longitude:%s,latitude:%s",guid,longitude,latitude)

	reddb:hmset("player:info:"..tostring(player.guid),{
		gps_longitude = longitude,
		gps_latitude = latitude,
	})

	player.gps_latitude = latitude
	player.gps_longitude = longitude
end

-- 玩家登录通知 验证账号成功后会收到
function on_ls_login_notify(guid,reconnect,gate)
	log.info("on_ls_login_notify game_id = %d,guid:%s,reconnect:%s", def_game_id,guid, reconnect)
	onlineguid[guid] = nil

	local player = player_context[guid]
	if not player then
		log.error("on_ls_login_notify game_id = %s,no player,guid:%d",def_game_id,guid)
		return enum.ERROR_PLAYER_NOT_EXIST
	end

	local s = onlineguid[guid]
	log.info("set player.online = true,guid:%d",guid)
	player.online = true
	local repeat_login = s and s.server == def_game_id
	if reconnect or repeat_login then
		-- 重连/重复登陆
		log.info("on_ls_login_notify,guid=%s,game_id:%s,reconnect:%s,repeat:%s,table_id:%s,chair_id:%s", 
			guid,def_game_id,reconnect,repeat_login,s.table,s.chair)
		local table_id = s.table
		if table_id and g_room:is_table_exists(table_id) then
			return enum.ERROR_NONE,true
		end
		return enum.ERROR_NONE
	end
	
	if g_common.is_in_maintain() and (not player.vip or  player.vip == 0) then
		return enum.LOGIN_RESULT_MAINTAIN
	end

	log.info("ip_area =%s",player.ip_area)

	if s and s.server then
		log.error("on_ls_login_notify guid:%s,game_id:%s,server:%s,login but session not nil",
			guid,def_game_id,s.server)
	end
	
	log.info("on_ls_login_notify,account=%s", player.account)
	
	local now = os.time()
	reddb:hset(string.format("player:info:%d",guid),"login_time",now)

	player.login_time = now
	g_room:enter_server(player)
	return enum.ERROR_NONE
end

-- 登录验证框
function on_cs_login_validatebox(player, msg)
	local guid = player.guid
	if msg and msg.answer and #msg.answer == 2 and player.login_validate_answer and #player.login_validate_answer == 2  and 
		((msg.answer[1] == player.login_validate_answer[1] and msg.answer[2] == player.login_validate_answer[2]) or
		(msg.answer[1] == player.login_validate_answer[2] and msg.answer[2] == player.login_validate_answer[1])) then

		onlineguid.send(player,  "SC_LoginValidatebox", {
			result = enum.LOGIN_RESULT_SUCCESS,
			})

		reddb:del("login_validate_error_count:"..tostring(player.guid))
		return
	end

	local count = reddb:incr("login_validate_error_count:"..tostring(guid))
	count = tonumber(count)
	if count > 2 then
		log.info("login_validate_error_count guid[%d] count[%d]",player.guid, count)
		channel.publish("db.?","msg","SD_ValidateboxFengIp", {
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
		onlineguid.send(player,  "SC_LoginValidatebox",msg)		
end

-- 玩家退出 
function logout(guid,offline)
	log.info("logout %s,offline:%s",guid,offline)
	local os = onlineguid[guid]
	if not os then
		log.error("logout %s,offline:%s got nil onlinesession.",guid,offline)
		return
	end

	if not os.server then
		log.error("logout %s,offline:%s session server nil,server:%s",guid,offline,def_game_id)
		return
	end

	if os.server ~= def_game_id then
		log.error("logout %s,offline:%s session server %s ~= %s",guid,offline,os.server,def_game_id)
		return channel.call(strfmt("game.%d",os.server),"msg","S_Logout",guid,offline)
	end

	local player = player_context[guid]
	if not player then
		log.error("logout,guid[%s] not find in game= %s", guid, def_game_id)
		return
	end

	local result = g_room:exit_server(player,offline)
	if offline then
		player.active = nil
	end

	return result
end

function on_s_logout(guid,offline)
	log.info ("on_s_logout guid:%s,offline:%s",guid,offline)
	return logout(guid,offline)
end

function on_cs_logout(guid)
	guid = tonumber(guid)
	log.info("on_cs_logout %s",guid)
	local player = player_context[guid]
	if not player then
		log.warning("on_cs_logout got nil player.")
		return enum.ERROR_PLAYER_NOT_EXIST
	end

	return g_room:kickout_server(player,enum.STANDUP_REASON_NORMAL)
end

function kickout(guid,reason)
	log.info("kickout %s",guid)
	local player = player_context[guid]
	if not player then
		log.warning("kickout got nil player,%s",guid)
		return
	end
	g_room:kickout_server(player,reason)
end

-- 请求玩家信息
function on_cs_request_player_info(msg,guid)
	log.info("player[%s] request_player_info gameid[%d] first_game_type[%d] second_game_type[%d]",guid , def_game_id , def_first_game_type ,def_second_game_type)
	local player = player_data[guid]
	if not player then
		return nil
	end

	log.info("player guid[%d] in request_player_info" , guid)

	local info = {
		guid = guid,
		pb_base_info = {
			account       = player.account,
			gps_latitude  = player.gps_latitude,
			gps_longitude = player.gps_longitude,
			guid          = player.guid,
			icon          = player.icon,
			invite_code   = player.invite_code,
			inviter_guid  = player.inviter_guid,
			last_login_ip = player.last_login_ip,
			login_ip      = player.login_ip,
			login_time    = player.login_time,
			logout_time   = player.logout_time,
			nickname      = player.nickname,
			open_id       = player.open_id,
			package_name  = player.package_name,
			phone         = player.phone,
			phone_type    = player.phone_type,
			role          = player.role,
			sex           = player.sex,
			version       = player.version,
			money = {{
				money_id = 0,
				count = player_money[guid][0] or 0,
			}}
		}
	}

	onlineguid.send(guid,"SC_ReplyPlayerInfo",info)

	log.info("test .................. on_cs_request_player_info")
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

-- 切换游戏服务器
function on_cs_change_game(msg,guid)
	local player = player_context[guid]
	if not player then
		return
	end

	local room = g_room
	if player.disable == 1 then	
		-- 踢用户下线 封停所有功能
		log.info("on_cs_change_game =======================disable == 1")
		if not room:is_play(player) then
			log.info("on_cs_change_game.....................player not in play force_exit")
			-- 强行T下线
			player:async_force_exit()
		end
		return
	end

	-- log.info("game_switch [%d] player.guid[%d] player.vip[%d]",game_switch,player.guid,player.vip)
	-- if  game_switch == 1 then --游戏进入维护阶段
	-- 	if player.vip ~= 100 then	
	-- 		onlineguid.send(player, "SC_GameMaintain", {
	-- 			result = enum.GAME_SERVER_RESULT_MAINTAIN,
	-- 		})
	-- 		player:async_force_exit()
	-- 		log.warning("GameServer will maintain,exit")
	-- 		return
	-- 	end
	-- end

	if msg.private_room_opt == 1 and not check_private_table_chair(msg.private_room_chair_count) then
		onlineguid.send(player, "SC_EnterRoomAndSitDown", {
				result = enum.GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				private_room_score_type = msg.private_room_score_type,
			})
		return
	end

	-- if msg.private_room_opt == 1 then
	-- 	local needmoney = calc_private_table_need_money(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
	-- 	if not needmoney then
	-- 		onlineguid.send(player, "SC_EnterRoomAndSitDown", {
	-- 			result = enum.GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR,
	-- 			game_id = def_game_id,
	-- 			first_game_type = msg.first_game_type,
	-- 			second_game_type = msg.second_game_type,
	-- 			ip_area = player.ip_area,
	-- 			private_room_score_type = msg.private_room_score_type,
	-- 		})
	-- 		return
	-- 	end

	-- 	local money = player.money or 0
	-- 	if money < needmoney then
	-- 		onlineguid.send(player, "SC_EnterRoomAndSitDown", {
	-- 			result = enum.GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_MONEY,
	-- 			game_id = def_game_id,
	-- 			first_game_type = msg.first_game_type,
	-- 			second_game_type = msg.second_game_type,
	-- 			ip_area = player.ip_area,
	-- 			private_room_score_type = msg.private_room_score_type,
	-- 			balance_money = needmoney-money,
	-- 		})
	-- 		return
	-- 	end
	-- end

	if msg.first_game_type == def_first_game_type and msg.second_game_type == def_second_game_type then
		-- 已经在这个服务器中了
		log.info("on_cs_change_game: game_name = [%s],game_id =[%d], single_game_switch_is_open = [%d]",def_game_name,def_game_id,room.game_switch_is_open)
		if g_room.game_switch_is_open == 1 then --游戏进入维护阶段
			if player.vip ~= 100 then	
				onlineguid.send(player, "SC_GameMaintain", {
						result = enum.GAME_SERVER_RESULT_MAINTAIN,
						})
				player:async_force_exit()
				log.warning("GameServer game_name = [%s],game_id =[%d], will maintain,exit",def_game_name,def_game_id)
				return
			end
		end

		local b_private_room = true
		local result_, table_id_, chair_id_, tb
		if msg.private_room_opt == 1 then
			-- result_, table_id_, chair_id_, tb = room:create_private_table(player, msg.private_room_chair_count, msg.private_room_score_type)
			-- if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
				-- 开房费
				-- local money = getCreatePrivateRoomNeedMoney(msg.first_game_type, msg.private_room_score_type, msg.private_room_chair_count)
				-- if money > 0 then
				-- 	player:change_money(-money, enum.LOG_MONEY_OPT_TYPE_CREATE_PRIVATE_ROOM)
				-- end
			-- end
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
			
			onlineguid.send(player, "SC_EnterRoomAndSitDown", notify)

			tb:on_player_sit_downed(player)

			player.noready = nil 
			tb:send_playerinfo(player)

			reddb:hmset("player:online:guid:"..tostring(player.guid),{
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				server = def_game_id,
				room_id = def_game_id,
			})

			onlineguid[player.guid] = nil

			log.info("change step this ok,account=%s", player.account)
		else
			onlineguid.send(player, "SC_EnterRoomAndSitDown", {
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

function on_ss_change_game(guid)
	local player = player_context[guid]
	player.online = true
	player.active = true
	log.info("on_ss_change_game[%d] %s,%s,%s",player.guid,def_first_game_type,def_second_game_type,def_game_id)

	reddb:hmset(string.format("player:online:guid:%d",guid),{
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		server = def_game_id,
	})

	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		1,def_game_id)

	onlineguid[player.guid] = nil
	onlineguid.goserver(guid,def_game_id)
	onlineguid[player.guid] = nil

	log.info("on_ss_change_game change step login notify,guid=%s", player.guid)
end

function on_cs_create_private_room(msg,guid,game_id)
	log.info("on_cs_create_private_room guid:%s,from:%s",guid,game_id)
	local game_type = msg.game_type
    local club_id = msg.club_id
	local rule = msg.rule
	local template_id = msg.template_id
	local player = player_context[guid]

	if game_util.is_global_in_maintain() and not player:is_vip() then
		onlineguid.send(guid,"SC_CreateRoom",{
			result = enum.LOGIN_RESULT_MAINTAIN,
		})
		return
	end

	local os = onlineguid[guid]
	if os.table then
		onlineguid.send(guid,"SC_CreateRoom",{
			result = enum.GAME_SERVER_RESULT_IN_ROOM,
		})
		return
	end

	if player.table_id then
		onlineguid.send(guid,"SC_CreateRoom",{
			result = enum.GAME_SERVER_RESULT_IN_ROOM,
		})
		return
	end

	if player.chair_id then
		onlineguid.send(guid,"SC_CreateRoom",{
			result = enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR,
		})
		return
	end

	if not rule and not template_id then
		onlineguid.send(guid,"SC_CreateRoom",{
			result = enum.ERROR_PARAMETER_ERROR,
		})
		return
	end

	local template
	if template_id and template_id ~= 0 then
		template = table_template[template_id]
		if not template then
			onlineguid.send(guid,"SC_CreateRoom",{
				result = enum.ERROR_TEMPLATE_NOT_EXISTS
			})
			return
		end

		rule = template.rule
		game_type = template.game_id
	else
		local ok
		ok,rule = pcall(json.decode,rule)
		if not ok or not rule then 
			onlineguid.send(guid,"SC_CreateRoom",{
				result = enum.ERROR_PARAMETER_ERROR,
			})
			return
		end
	end

	local club
	if club_id and club_id ~= 0 then
		club = base_clubs[club_id]
		if not club then 
			onlineguid.send(guid,"SC_CreateRoom",{
				result = enum.ERROR_CLUB_NOT_FOUND,
			})
			return
		end
	end
	
	if def_first_game_type ~= game_type then
		local room_id = common.find_best_room(game_type)
		if not room_id then
			log.warning("on_cs_create_private_room did not find room,game_type:%s,room_id:%s",game_type,room_id)
			onlineguid.send(guid,"SC_CreateRoom",{
				result = enum.GAME_SERVER_RESULT_NO_GAME_SERVER,
				game_type = game_type,
			})
			return
		end

		channel.call("game."..tostring(room_id),"msg","CS_CreateRoom",msg,guid,def_game_id)
		return
	end

	if game_util.is_game_in_maintain() then
		onlineguid.send(guid,"SC_CreateRoom",{
			result = enum.GAME_SERVER_RESULT_MAINTAIN,
		})
		return
	end

	log.dump(rule)

	local result,round,chair_count,pay_option,_ = base_rule.check(rule)
	log.dump(result)
	if result ~= enum.ERROR_NONE  then
		
		onlineguid.send(guid,"SC_CreateRoom",{
			result = result,
			game_type = game_type,
		})
		return
	end
    log.dump(pay_option)
	local global_table_id,tb = enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND,nil
	if pay_option == enum.PAY_OPTION_BOSS then
		if not club then
			onlineguid.send(guid,"SC_CreateRoom",{
				result = enum.ERROR_CLUB_NOT_FOUND,
			})
			return
		end

		log.dump(template)
		
		club_utils.lock_action(club_id,{guid},function()
			result,global_table_id,tb = on_club_create_table(club,player,chair_count,round,rule,template)
		end)
	elseif pay_option == enum.PAY_OPTION_AA then
		result,global_table_id,tb = g_room:create_private_table(player,chair_count,round,rule,club)
	elseif pay_option == enum.PAY_OPTION_ROOM_OWNER then
		result,global_table_id,tb = g_room:create_private_table(player,chair_count,round,rule,club)
	else
		log.dump(pay_option)
		result = enum.ERROR_OPERATION_INVALID
	end

	if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
		onlineguid.send(guid,"SC_CreateRoom",{
			result = result,
		})
		return
	end

	player.active = true

	if game_id then
		common.switch_from(guid,game_id)
	end

	local money_id = club_id and club_money_type[club_id] or -1
	onlineguid.send(guid,"SC_CreateRoom",{
		result = result,
		info = {
			game_type = game_type,
			club_id = club_id,
			table_id = global_table_id,
			rule = json.encode(rule),
			owner = guid,
		},
		seat_list = {{
			chair_id = player.chair_id,
			player_info = {
				icon = player.icon,
				guid = player.guid,
				nickname = player.nickname,
				sex = player.sex,
			},
			longitude = player.gps_longitude,
			latitude = player.gps_latitude,
			ready = tb.ready_list[player.chair_id] and true or false,
			online = true,
			money = {
				money_id = money_id,
				count = player:get_money(money_id),
			},
		}},
		round_info = tb and {
			round_id = tb:hold_ext_game_id()
		} or nil,
	})

	tb:on_player_sit_downed(player)
end

function do_reconnect(guid,game_id)
	local player = player_context[guid]
	local onlineinfo = onlineguid[guid]
	if not onlineinfo then
		onlineguid.send(guid,"SC_ReconnectJoinRoom",{
			result = enum.GAME_SERVER_RESULT_RECONNECT_NOT_ONLINE
		})
		return
	end	

	if not onlineinfo.table then
		onlineguid.send(guid,"SC_ReconnectJoinRoom",{
			result = enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		})
		return
	end
	
	if not onlineinfo.chair then
		onlineguid.send(guid,"SC_ReconnectJoinRoom",{
			result = enum.GAME_SERVER_RESULT_PLAYER_NO_CHAIR
		})
		return
	end

	local table_id = onlineinfo.table
	local chair_id = onlineinfo.chair
	local private_table = base_private_table[onlineinfo.global_table]
	if not private_table then
		onlineguid.send(guid,"SC_ReconnectJoinRoom",{
			result = enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
		})
		return
	end

	local room_id = private_table.room_id
	if not room_id then
		onlineguid.send(guid,"SC_ReconnectJoinRoom",{
			result = enum.ERROR_TABLE_NOT_EXISTS
		})
		return
	end

	if def_game_id ~= room_id then
		channel.call("game."..tostring(room_id),"msg","CS_ReconnectJoinRoom",nil,guid,def_game_id)
		return
	end

	local club_id = private_table.club_id
	local money_id = club_id and club_money_type[club_id] or -1
	local tb = g_room:find_table(table_id)
	if not tb then
		onlineguid.send(guid,"SC_ReconnectJoinRoom",{
			result = enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
		})
		return
	end
	
	return tb:lockcall(function()
		-- double check
		if not tb:exists() then
			onlineguid.send(guid,"SC_ReconnectJoinRoom",{
				result = enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
			})
			return
		end

		local result = tb:player_sit_down(player, chair_id,true)
		if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
			log.warning("on_cs_reconnect table %s,guid:%s,chair_id:%s,result:%s,failed",
				table_id,guid,chair_id,result)
			onlineguid.send(guid,"SC_ReconnectJoinRoom",{
				result = result
			})
			return
		end

		player.active = true

		local seats = table.series(tb.players,function(p)
			return {
				chair_id = p.chair_id,
				player_info = {
					icon = p.icon,
					guid = p.guid,
					nickname = p.nickname,
					sex = p.sex,
				},
				ready = tb.ready_list[p.chair_id] and true or false,
				online = p.active and true or false,
				money = {
					money_id = money_id,
					count = p:get_money(money_id),
				},
				longitude = p.gps_longitude,
				latitude = p.gps_latitude,
				is_trustee = (p ~= player and p.trustee) and true or false,
			}
		end)

		onlineguid.send(guid,"SC_ReconnectJoinRoom",{
			result = enum.ERROR_NONE,
			info = {
				game_type = private_table.game_type,
				club_id = private_table.club_id,
				table_id = private_table.table_id,
				rule = json.encode(private_table.rule),
				owner = private_table.owner,
			},
			seat_list = seats,
			round_info = tb and {
				round_id = tb:hold_ext_game_id()
			} or nil,
		})

		tb:reconnect(player)
		tb:on_player_sit_downed(player,true)
	end)
end

function on_cs_reconnect_join_room(_,guid,game_id)
	do_reconnect(guid,game_id)
end

function on_cs_join_private_room(msg,guid,game_id)
	log.info("on_cs_join_private_room guid:%s,from:%s",guid,game_id)
	local player = player_context[guid]

	local reconnect = msg.reconnect and msg.reconnect ~= 0
	local table_id = msg.table_id
	local onlineinfo = onlineguid[guid]
	if reconnect then
		if not onlineinfo then
			return enum.GAME_SERVER_RESULT_RECONNECT_NOT_ONLINE
		end
		table_id = onlineinfo.global_table
	end

	if not table_id then
		onlineguid.send(guid,"SC_JoinRoom",{
			result = enum.ERROR_TABLE_NOT_EXISTS,
		})
		return
	end

	local private_table = base_private_table[table_id]
	if not private_table then
		onlineguid.send(guid,"SC_JoinRoom",{
			result = enum.ERROR_TABLE_NOT_EXISTS,
		})
		return
	end

	local room_id = private_table.room_id
	if not room_id then
		onlineguid.send(guid,"SC_JoinRoom",{
			result = enum.ERROR_TABLE_NOT_EXISTS,
		})
		return
	end

	if def_game_id ~= room_id then
		channel.call("game."..room_id,"msg","CS_JoinRoom",msg,guid,def_game_id)
		return
	end
	
	if onlineinfo and (onlineinfo.table or onlineinfo.chair) then
		onlineguid.send(guid,"SC_JoinRoom",{
			result = enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR,
		})
		return
	end

	if game_util.is_global_in_maintain() and not player:is_vip() then
		onlineguid.send(guid,"SC_JoinRoom",{
			result = enum.LOGIN_RESULT_MAINTAIN,
		})
		return
	end

	if game_util.is_game_in_maintain() then
		onlineguid.send(guid,"SC_JoinRoom",{
			result = enum.GAME_SERVER_RESULT_MAINTAIN,
		})
		return
	end

	if not private_table.rule then
		onlineguid.send(guid,"SC_JoinRoom",{
			result = enum.ERROR_TABLE_NOT_EXISTS,
		})
		return
	end

	local rule = private_table.rule
	local result,_,chair_count,pay_option,_ = base_rule.check(rule)
	if result ~= enum.ERROR_NONE  then
		onlineguid.send(guid,"SC_JoinRoom",{
			result = result,
		})
		return
	end

	local tb
	local club_id = private_table.club_id
	log.dump(private_table)
	local club = club_id and base_clubs[club_id] or nil
	if pay_option == enum.PAY_OPTION_BOSS then
		if not club then
			onlineguid.send(guid,"SC_JoinRoom",{
				result = enum.ERROR_CLUB_NOT_FOUND,
			})
			return
		end
		club_utils.lock_action(club_id,{guid},function() 
			result,tb = club:join_table(player,private_table,chair_count)
		end)
	elseif pay_option == enum.PAY_OPTION_AA then
		result,tb = g_room:join_private_table(player,private_table,chair_count)
	elseif pay_option == enum.PAY_OPTION_ROOM_OWNER then
		result,tb = g_room:join_private_table(player,private_table,chair_count)
	else
		result = enum.ERROR_PARAMETER_ERROR
	end

	local money_id = club_id and club_money_type[club_id] or -1
	if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
		log.warning("on_cs_join_private_room faild!guid:%s,%s",guid,result)
		onlineguid.send(guid,"SC_JoinRoom",{
			result = result,
		})
		return
	end

	player.active = true

	if game_id then
		common.switch_from(guid,game_id)
	end
	
	local seats = table.series(tb.players,function(p) 
		return {
			chair_id = p.chair_id,
			player_info = {
				icon = p.icon,
				guid = p.guid,
				nickname = p.nickname,
				sex = p.sex,
			},
			longitude = p.gps_longitude,
			latitude = p.gps_latitude,
			ready = tb.ready_list[p.chair_id] and true or false,
			online = p.active and true or false, 
			money = {
				money_id = money_id,
				count = p:get_money(money_id),
			},
			is_trustee = (p ~= player and p.trustee) and true or false,
		}
	end)

	log.dump(seats)

	onlineguid.send(guid,"SC_JoinRoom",{
		result = result,
		info = {
			game_type = private_table.game_type,
			club_id = private_table.club_id,
			table_id = private_table.table_id,
			rule = json.encode(private_table.rule),
			owner = private_table.owner,
		},
		seat_list = seats,
		round_info = tb and {
			round_id = tb:hold_ext_game_id(),
		} or nil,
	})
	tb:on_player_sit_downed(player)
end

function on_ss_fast_join_room(msg,guid,game_id)
	if game_util.is_game_in_maintain() then
		return enum.GAME_SERVER_RESULT_MAINTAIN
	end
	
	local player = player_context[guid]
	local club_id = msg.club_id
	local template_id = msg.template_id
	local club = base_clubs[club_id]

	local tbs = g_room:find_free_tables(club_id,template_id)
	table.sort(tbs,function(l,r) return l:get_player_count() > r:get_player_count() end)
	for _,tb in pairs(tbs) do
		repeat
			local table_id = tb:id()
			local ptb = base_private_table[table_id]
			if not ptb then break end
			local rule = ptb.rule
			local can = club:can_sit_down(rule,player)
			if can ~= enum.ERROR_NONE then break end

			can = club:is_block_gaming_with_others(tb,player)
			if can ~= enum.ERROR_NONE then break end

			local free_chair = tb:get_free_chair_id()
			if not free_chair then break end
			can = tb:can_sit_down(player,free_chair)
			if can ~= enum.ERROR_NONE then break end

			-- double check
			local og = onlineguid[guid]
			if og.table or og.chair then
				return enum.GAME_SERVER_RESULT_IN_ROOM
			end

			local result = g_room:fast_join_private_table(tb,player,free_chair)
			if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
				log.warning("on_ss_fast_join_room faild!guid:%s,%s",guid,result)
				return result
			end
			
			player.active = true
	
			if game_id then
				common.switch_from(guid,game_id)
			end
			
			local money_id = club_money_type[club_id]
			onlineguid.send(guid,"SC_FastJoinRoom",{
				result = result,
				info = {
					game_type = def_first_game_type,
					club_id = club_id,
					table_id = table_id,
					rule = json.encode(ptb.rule),
					owner = tb.owner_guid,
				},
				seat_list = table.series(tb.players,function(p) 
					return {
						chair_id = p.chair_id,
						player_info = {
							icon = p.icon,
							guid = p.guid,
							nickname = p.nickname,
							sex = p.sex,
						},
						longitude = p.gps_longitude,
						latitude = p.gps_latitude,
						ready = tb.ready_list[p.chair_id] and true or false,
						online = p.active and true or false, 
						money = {
							money_id = money_id,
							count = p:get_money(money_id),
						},
						is_trustee = (p ~= player and p.trustee) and true or false,
					}
				end),
				round_info = tb and {
					round_id = tb:hold_ext_game_id(),
				} or nil,
			})
			
			tb:on_player_sit_downed(player)

			return enum.ERROR_NONE
		until true
	end

	return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
end

function on_ss_fast_create_room(msg,guid,game_id)
	if game_util.is_game_in_maintain() then
		return enum.GAME_SERVER_RESULT_MAINTAIN
	end

	local player = player_context[guid]
	local club_id = msg.club_id
	local template_id = msg.template_id
	local club = base_clubs[club_id]

	local temp = table_template[template_id]
	local rule = temp.rule
	local can = club:can_sit_down(rule,player)
	if can ~= enum.ERROR_NONE then return can end

	local result,round,chair_count,pay_option,_ = base_rule.check(rule)
	if result ~= enum.ERROR_NONE  then
		return result
	end

	-- double check
	local og = onlineguid[guid]
	if og.table or og.chair then
		return enum.GAME_SERVER_RESULT_IN_ROOM
	end

	local result,table_id,tb = club:fast_create_table(player,chair_count,round,rule,temp)
	if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
		return result
	end

	player.active = true

	if game_id then
		common.switch_from(guid,game_id)
	end

	local money_id = club_id and club_money_type[club_id] or -1
	onlineguid.send(guid,"SC_FastJoinRoom",{
		result = result,
		info = {
			game_type = def_first_game_type,
			club_id = club_id,
			table_id = table_id,
			rule = json.encode(rule),
			owner = guid,
		},
		seat_list = {{
			chair_id = player.chair_id,
			player_info = {
				icon = player.icon,
				guid = player.guid,
				nickname = player.nickname,
				sex = player.sex,
			},
			longitude = player.gps_longitude,
			latitude = player.gps_latitude,
			ready = tb.ready_list[player.chair_id] and true or false,
			online = true,
			money = {
				money_id = money_id,
				count = player:get_money(money_id),
			},
		}},
		round_info = tb and {
			round_id = tb:hold_ext_game_id()
		} or nil,
	})

	tb:on_player_sit_downed(player)

	return enum.ERROR_NONE
end

local function fast_create_room(msg,guid,room_id)
	if room_id ~= def_game_id then
		return channel.call(string.format("game.%d",room_id),"msg","SS_FastCreateRoom",msg,guid,def_game_id)
	end

	return on_ss_fast_create_room(msg,guid,def_game_id)
end

local function fast_join_room(msg,guid,room_id)
	if room_id ~= def_game_id then
		return channel.call(string.format("game.%d",room_id),"msg","SS_FastJoinRoom",msg,guid,def_game_id)
	end

	return on_ss_fast_join_room(msg,guid,def_game_id)
end

function on_cs_fast_join_room(msg,guid)
	local club_id = msg.club_id
	local template_id = msg.template_id
	local game_id = msg.game_id

	log.info("on_cs_fast_join_room %s,%s,%s,%s",guid,club_id,template_id,game_id)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_fast_join_room nil player,%s",guid)
		onlineguid.send(guid,"SC_FastJoinRoom",{
			result = enum.ERROR_OPERATION_INVALID
		})

		return
	end

	if 	not club_id or
		club_id == 0 or
		(template_id == 0 and game_id == 0)
	then
		log.error("on_cs_fast_join_room invalid param")
		onlineguid.send(guid,"SC_FastJoinRoom",{
			result = enum.ERROR_OPERATION_INVALID
		})

		return
	end

	local club = base_clubs[club_id]
	if not club then
		log.error("on_cs_fast_join_room club not exists %s,%s",guid,club_id)
		onlineguid.send(guid,"SC_FastJoinRoom",{
			result = enum.ERROR_OPERATION_INVALID
		})

		return
	end

	local temp = table_template[template_id]
	if not temp then
		onlineguid.send(guid,"SC_FastJoinRoom",{
			result = enum.ERROR_OPERATION_INVALID
		})

		return
	end

	if game_util.is_global_in_maintain() and not player:is_vip() then
		onlineguid.send(guid,"SC_FastJoinRoom",{
			result = enum.LOGIN_RESULT_MAINTAIN,
		})
		return
	end

	club_utils.lock_action(club_id,{guid},function()
		-- double check
		local og = onlineguid[guid]
		if og and (og.table or og.chair) then
			onlineguid.send(guid,"SC_FastJoinRoom",{
				result = enum.GAME_SERVER_RESULT_IN_GAME,
			})
			return
		end
		
		local room_weights = common.all_game_server(temp.game_id)
		local rooms = table.series(room_weights,function(weight,roomid) 
			return { room_id = roomid,weight = weight,}
		end)
		table.sort(rooms,function(l,r) return l.weight > r.weight end)

		for _,v in pairs(rooms) do
			local room_id = v.room_id
			local result = fast_join_room(msg,guid,room_id)

			if 	result == enum.GAME_SERVER_RESULT_MAINTAIN or
				result == enum.GAME_SERVER_RESULT_IN_ROOM or
				result == enum.GAME_SERVER_RESULT_IN_GAME
			then
				onlineguid.send(guid,"SC_FastJoinRoom",{
					result = result,
				})
				return
			end

			if result == enum.ERROR_NONE then
				return
			end
		end

		local room_id = rooms[#rooms].room_id
		local result = fast_create_room(msg,guid,room_id)
		if result ~= enum.ERROR_NONE then
			onlineguid.send(guid,"SC_FastJoinRoom",{
				result = result,
			})
		end
	end)
end

-- 设置昵称
function on_cs_set_nickname(msg,guid)
	log.dump(msg)
	log.dump(guid)
	local nickname = msg.nickname
	if not nickname or nickname == "" then
		send2client_pb(guid,"SC_SetNickname",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end
	
	local player = player_data[guid]
	if not player then
		send2client_pb(guid,"SC_SetNickname",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

	reddb:hset(string.format("player:info:%d",guid),"nickname",nickname)
	player.nickname = nickname

	channel.publish("db.?","msg","SD_UpdatePlayerInfo",{
		nickname = player.nickname,
	},guid)

	send2client_pb(guid,"SC_SetNickname",{
		nickname = nickname,
		result = enum.ERROR_NONE,
	})
end

-- 修改头像
function on_cs_change_header_icon(player, msg)
	local header_icon = player.header_icon or 0
	if msg.header_icon ~= header_icon then
		player.header_icon = msg.header_icon
		player.flag_base_info = true
	end

	onlineguid.send(player,"SC_ChangeHeaderIcon", {
		header_icon = msg.header_icon,
	})
end

function on_cs_bind_account(msg,guid)
	local password = string.match(msg.password or "","^%s*(.+)%s*$")
	local phone = string.match(msg.phone_number or "","^%s*(.+)%s*$")
	
	if (not password or password == "") and (not phone or phone == "") then
		onlineguid.send(guid,"SC_RequestBindPhone",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	local player = player_data[guid]
	if not player then
		onlineguid.send(guid,"SC_RequestBindPhone",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

	-- if player.phone and player.phone ~= "" then
	-- 	onlineguid.send(guid,"SC_RequestBindPhone",{
	-- 		result = enum.ERROR_BIND_ALREADY
	-- 	})
	-- 	return
	-- end

	if phone and phone ~= "" then
		local phonelen = string.len(phone or "")
		if 	not phone or
			not string.match(phone,"^%d+$") or 
			phonelen < 7 or 
			phonelen > 18 then
			onlineguid.send(guid,"SC_RequestBindPhone",{
				result = enum.LOGIN_RESULT_TEL_ERR
			})
			return
		end

		local sms_verify_code = msg.sms_verify_no
		if sms_verify_code and sms_verify_code ~= "" then
			local code = reddb:get(string.format("sms:verify_code:guid:%s",guid))
			reddb:del(string.format("sms:verify_code:guid:%s",guid))
			if not code or code == "" then
				onlineguid.send(guid,"SC_RequestBindPhone",{
					result = enum.LOGIN_RESULT_SMS_FAILED
				})
				return
			end
	
			if string.lower(code) ~= string.lower(sms_verify_code) then
				onlineguid.send(guid,"SC_RequestBindPhone",{
					result = enum.LOGIN_RESULT_SMS_FAILED
				})
				return
			end
		end

		reddb:hset(string.format("player:info:%s",guid),"phone",phone)
		reddb:set(string.format("player:phone_uuid:%s",phone),player.open_id)
		player.phone = phone
		log.info("on_cs_bind_account guid:%d,phone=%s",guid,phone)
		channel.publish("db.?","msg","SD_BindPhone",{
			guid = guid,
			phone = phone,
		})
	end

	if password and password ~= "" then
		log.info("on_cs_bind_account guid:%d,password=%s",guid,password)
		reddb:set(string.format("player:password:%s",guid),password)
	end

	onlineguid.send(guid,"SC_RequestBindPhone",{
		result = enum.ERROR_NONE,
		phone_number = phone,
	})
end

function on_cs_request_sms_verify_code(msg,guid)
	local phone_num = msg.phone_number
	if not guid then
	    return enum.LOGIN_RESULT_SMS_FAILED
	end
    
	local verify_code = reddb:get(string.format("sms:verify_code:guid:%s",guid))
	if verify_code and verify_code ~= "" then
		local ttl = reddb:ttl(string.format("sms:verify_code:guid:%s",guid))
        ttl = tonumber(ttl)
		return enum.LOGIN_RESULT_SMS_REPEATED,ttl
	end
    
	log.info( "RequestSms session [%s] =================", guid )
	if not phone_num then
		log.error( "RequestSms session [%s] =================tel not find", guid)
		return enum.LOGIN_RESULT_TEL_ERR
	end
    
	log.info( "RequestSms =================tel[%s] platform_id[%s]",  phone_num, msg.platform_id)
	local phone_num_len = string.len(phone_num)
	if phone_num_len < 7 or phone_num_len > 18 then
		return enum.LOGIN_RESULT_TEL_LEN_ERR
	end
    
	local prefix = string.sub(phone_num,0, 3)
	-- if prefix == "170" or prefix == "171" then
	-- 	return enum.LOGIN_RESULT_TEL_ERR
	-- end
    
	if prefix == "999" then
	    local expire = math.floor(global_conf.sms_expire_time or 60)
	    local code =  string.sub(phone_num,phone_num_len - 4 + 1)
	    local rkey = string.format("sms:verify_code:guid:%s",guid)
	    reddb:set(rkey,code)
	    reddb:expire(rkey,expire)
		return enum.LOGIN_RESULT_SUCCESS,expire
	end
    
	if not string.match(phone_num,"^%d+$") then
	    return enum.LOGIN_RESULT_TEL_ERR
	end
    
	local expire = math.floor(global_conf.sms_expire_time or 60)
	local code = string.format("%4d",math.random(4001,9999))
	local rkey = string.format("sms:verify_code:guid:%s",guid)
	reddb:set(rkey,code)
	reddb:expire(rkey,expire)
	local reqid = channel.call("broker.?","msg","SB_PostSms",phone_num,string.format("【友愉互动】您的验证码为%s, 请在%s分钟内验证完毕.",code,math.floor(expire / 60)))
	onlineguid.send(guid,"SC_RequestSmsVerifyCode",{
		result = not reqid and enum.ERROR_REQUEST_SMS_FAILED or enum.ERROR_NONE,
		timeout = expire,
		phone_number = phone_num,
	})
end

function on_cs_game_server_cfg(msg,guid)
	local player = player_data[guid]
	if player then
		local alive_games = g_util.alive_game_ids()
        local alives = table.map(alive_games,function(gameid) return gameid,true end)
		local conf_games = runtime_conf.get_game_conf(player.channel_id,player.promoter)
		if conf_games and #conf_games > 0 then
			send2client_pb(guid,"SC_GameServerCfg",{
				game_sever_info  = table.series(conf_games,function(gameid) return alives[gameid] and gameid or nil end),
			})
			return true
        end
        
		send2client_pb(guid,"SC_GameServerCfg",{
			game_sever_info  = alive_games,
		})
	end

	return true
end

local function wx_auth(code)
    log.dump(code)
    return channel.call("broker.?","msg","SB_WxAuth",code)
end

function on_cs_request_bind_wx(msg,guid)
	local player = player_data[guid]
	if not player then
		onlineguid.send(guid,"SC_RequestBindWx",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

    local errcode,auth = wx_auth(msg.code)
	if errcode then
		onlineguid.send(guid,"SC_RequestBindWx",{
			result = enum.LOGIN_RESULT_AUTH_CHECK_ERROR
		})
        return
	end

	log.dump(auth)
	
	reddb:set(string.format("player:auth_id:%s",auth.unionid),player.open_id)

	player.nickname = auth.nickname
	player.icon = auth.headimgurl
	player.sex = auth.sex
	reddb:hmset(string.format("player:info:%s",guid),{
		nickname = auth.nickname,
		icon = auth.headimgurl,
		sex = auth.sex
	})

	local info = {
		guid = player.guid,
		account = player.open_id,
		nickname = player.nickname,
		open_id = player.open_id,
		sex = player.sex,
		icon = player.icon,
		version = player.version,
		login_ip = player.ip,
		level = 0,
		imei = "",
		is_guest = true,
		login_time = player.login_time,
		package_name = player.package_name,
		phone_type = player.phone_type,
		role = 0,
		ip = player.ip,
		promoter = player.promoter,
		channel_id = player.channel_id,
	}

	channel.publish("db.?","msg","SD_UpdatePlayerInfo",{
		nickname = player.nickname,
		head_url = player.icon,
		sex = player.sex,
	})
	onlineguid.send(guid,"SC_RequestBindWx",{
		result = enum.ERROR_NONE,
		pb_base_info = info,
	})
end

function on_cs_personal_id_bind(msg,guid)
	reddb:hmset(string.format("player:binding:id:%s",guid),msg)
	reddb:hset(string.format("player:info:%d",guid),"is_bind_personal_id",true)
	onlineguid.send(guid,"SC_PERSONAL_ID_BIND",{
		result = enum.ERROR_NONE,
	})
end

function on_cs_search_player(msg,guid)
	local player_guid = msg.guid
	if not player_guid or player_guid == 0 then
		onlineguid.send(guid,"SC_SearchPlayer",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	local player = player_data[player_guid]
	if not player then
		onlineguid.send(guid,"SC_SearchPlayer",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

	onlineguid.send(guid,"SC_SearchPlayer",{
		result = enum.ERROR_NONE,
		base_info = {
			guid = player.guid,
			nickname = player.nickname,
			icon = player.icon,
			sex = player.sex,
		}
	})
end

function on_cs_play_once_again(msg,guid)
	local player = player_context[guid]
	if not player then
		onlineguid.send(guid,"SC_PlayOnceAgain",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

	local result,round_id = g_room:play_once_again(player)
	onlineguid.send(guid,"SC_PlayOnceAgain",{
		result = result,
		round_info = {
			round_id = round_id,
		}
	})
end

local function kickout_player(guid,kicker)
	if not guid or guid == 0 then
		onlineguid.send(guid,"SC_ForceKickoutPlayer",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

	local player = player_context[guid]
	if not player then
		onlineguid.send(guid,"SC_ForceKickoutPlayer",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

	local kickee_table = g_room:find_table_by_player(player)
	if not kickee_table then
		onlineguid.send(kicker.guid,"SC_ForceKickoutPlayer",{
			result = enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		})
		return
	end
	
	local result = kickee_table:kickout_player(player,kicker)
	onlineguid.send(kicker.guid,"SC_ForceKickoutPlayer",{
		result = result
	})
end

function on_cs_force_kickout_player(msg,kicker_guid)
	local kicker = player_data[kicker_guid]
	if not kicker then
		onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local guid = msg.guid
	if not guid or guid == 0 then
		onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local player = player_data[guid]
	if not player then
		onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end
	
	local os = onlineguid[guid]
	if not os or not os.server then
		onlineguid.send(kicker_guid,"SC_ForceKickoutPlayer",{
			result = enum.GAME_SERVER_RESULT_OUT_ROOM
		})
		return
	end

	local server = os.server
	if server ~= def_game_id then
		channel.publish("service."..tostring(server),"msg","CS_ForceKickoutPlayer",msg,kicker_guid)
		return
	end

	local club_id = msg.club_id
	if club_id and club_id ~= 0 then
		on_cs_club_kickout_player(msg,kicker_guid)
		return
	end

	kickout_player(guid,kicker)
end

function on_bs_recharge(msg)
	local guid = msg.guid
	local amount = msg.amount
	local money_id = msg.money_id
	local operator = msg.operator
	local comment = msg.comment
	local money = msg.money

	local recharge_id = channel.call("db.?","msg","SD_LogRecharge",{
		source_id = 0,
		target_id = guid,
		type = 5,
		operator = operator,
		comment = comment,
		money = money,
	})

	local player = player_data[guid]
	player:incr_money({
        money_id = money_id,
        money = amount,
	},enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY,recharge_id)

	game_util.log_statistics_money(money_id,amount,enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)

	return enum.ERROR_NONE
end

function on_ss_change_to(guid,room_id)
	log.info("on_ss_change_to[%s],%s,%s,%s",guid,def_first_game_type,def_second_game_type,def_game_id)

	reddb:zincrby(string.format("player:online:count:%d",def_first_game_type),
		-1,def_game_id)
	reddb:zincrby(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),
		-1,def_game_id)

	allonlineguid[guid] = nil
	onlineguid[guid] = nil
	sessions.del(guid)

	log.info("on_ss_change_to change step login notify,guid=%s", guid)
end

function on_bs_bind_phone(msg)
	local guid = tonumber(msg.guid)
	local phone = string.match(msg.phone or "","^%s*(.+)%s*$")
	if not phone or phone == "" or not guid then
		return enum.ERROR_PARAMETER_ERROR
	end

	local player = player_data[guid]
	if not player then
		return enum.ERROR_PLAYER_NOT_EXIST
	end

	local phonelen = string.len(phone or "")
	if 	not phone or
		not string.match(phone,"^%d+$") or 
		phonelen < 7 or 
		phonelen > 18 then
		return enum.LOGIN_RESULT_TEL_ERR
	end

	-- local phone_uuid = reddb:get(string.format("player:phone_uuid:%s",phone))
	-- if phone_uuid and phone_uuid ~= "" and phone_uuid ~= player.open_id then
	-- 	return enum.ERROR_OPERATION_REPEATED
	-- end

	reddb:hset(string.format("player:info:%s",guid),"phone",phone)
	reddb:set(string.format("player:phone_uuid:%s",phone),player.open_id)
	player.phone = phone

	channel.publish("db.?","msg","SD_BindPhone",{
		guid = guid,
		phone = phone,
	})

	return enum.ERROR_NONE
end