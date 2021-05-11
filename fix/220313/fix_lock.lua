
local log = require "log"
local base_players = require "game.lobby.base_players"
local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local table_template = require "game.lobby.table_template"
local game_util = require "game.util"
local club_utils = require "game.club.club_utils"
local common = require "game.common"
local channel = require "channel"
local club_money_type = require "game.club.club_money_type"
local json = require "json"
local base_rule = require "game.lobby.base_rule"
local base_private_table = require "game.lobby.base_private_table"

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

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


local function on_cs_fast_join_room(msg,guid)
	local club_id = msg.club_id
	local template_id = msg.template_id
	local game_id = msg.game_id

	log.info("on_cs_fast_join_room %s,%s,%s,%s",guid,club_id,template_id,game_id)
	local player = base_players[guid]
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

	club_utils.lock_action(club_id,guid,function()
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


local function on_cs_create_private_room(msg,guid,game_id)
	log.info("on_cs_create_private_room guid:%s,from:%s",guid,game_id)
	local game_type = msg.game_type
    local club_id = msg.club_id
	local rule = msg.rule
	local template_id = msg.template_id
	local player = base_players[guid]

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
	if result ~= enum.ERROR_NONE  then
		onlineguid.send(guid,"SC_CreateRoom",{
			result = result,
			game_type = game_type,
		})
		return
	end

	local global_table_id,tb = enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND,nil
	if pay_option == enum.PAY_OPTION_BOSS then
		if not club then
			onlineguid.send(guid,"SC_CreateRoom",{
				result = enum.ERROR_CLUB_NOT_FOUND,
			})
			return
		end

		log.dump(template)
		
		club_utils.lock_action(club_id,guid,function()
			result,global_table_id,tb = on_club_create_table(club,player,chair_count,round,rule,template)
		end)
	elseif pay_option == enum.PAY_OPTION_AA then
		result,global_table_id,tb = g_room:create_private_table(player,chair_count,round,rule,club)
	elseif pay_option == enum.PAY_OPTION_ROOM_OWNER then
		result,global_table_id,tb = g_room:create_private_table(player,chair_count,round,rule,club)
	else
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



local function on_cs_join_private_room(msg,guid,game_id)
	log.info("on_cs_join_private_room guid:%s,from:%s",guid,game_id)
	local player = base_players[guid]

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
		club_utils.lock_action(club_id,guid,function() 
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

local msgopt = _P.msg.msgopt

dump(print,msgopt)

msgopt.CS_FastJoinRoom = on_cs_fast_join_room
msgopt.CS_CreateRoom = on_cs_create_private_room
msgopt.CS_JoinRoom = on_cs_join_private_room

dump(print,msgopt)