local pb = require "pb"

local msgopt = require "msgopt"


--先写死只播一次
function broadcast_world_marquee(first_game_type_,second_game_type_,notice_type_,param1_,param2_,param3_,param4_,param5_)
	local p1 = param1_ or ""
	local p2 = param2_ or ""
	local p3 = param3_ or ""
	local p4 = param4_ or ""
	local p5 = param5_ or ""

	local game_notice = {
		first_game_type = first_game_type_,
		second_game_type = second_game_type_,
		number = 1,
		interval_time = 0,
		start_time =  get_second_time(),
		notice_type = notice_type_,
		param1 = p1,
		param2 = p2,
		param3 = p3,
		param4 = p4,
		param5 = p5,
	}

	send2login_pb("SL_GameNotice",{pb_game_notice = game_notice})
end

function broadcast_platform_marquee(platform_id,first_game_type_,second_game_type_,notice_type_,param1_,param2_,param3_,param4_,param5_)
	local p1 = param1_ or ""
	local p2 = param2_ or ""
	local p3 = param3_ or ""
	local p4 = param4_ or ""
	local p5 = param5_ or ""

	local game_notice = {
		first_game_type = first_game_type_,
		second_game_type = second_game_type_,
		number = 1,
		interval_time = 0,
		start_time =  get_second_time(),
		notice_type = notice_type_,
		param1 = p1,
		param2 = p2,
		param3 = p3,
		param4 = p4,
		param5 = p5,
	}

	send2login_pb("SL_GameNotice",{pb_game_notice = game_notice,platform_id = tostring(platform_id)})
end

function send2db_pb(msgname, msg)
	return msgopt.call("db.?",msgname,msg)
end

function send2cfg_pb(msgname, msg)
	return msgopt.send("config.?",msgname,msg)
end

function get_msg_id_str(msgname, msg)
	local id = pb.enum(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))

	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end

	return id, stringbuffer
end

function send2client_pb_str(player_or_guid, msgid, msg_str)
	local player = player_or_guid
	if type(player) ~= "table" then
		player = base_players[player_or_guid]
		if not player then
			log.warning("game[send2client_pb] not find player:" .. player_or_guid)
			return
		end
	end

	if player.is_android or not player.is_player then
		log.info("----player is robot,send2client_pb return")
		return
	end

	if not player.online then
		log.info(string.format("game[send2client_pb] offline, guid:%d  msgid:%d",player.guid,msgid))
		return
	end
	send2client(player.guid, player.gate_id, msgid, msg_str)
end

function send2client_pb(player_or_guid, msgname, msg)
	--print(msgname)
	--log.info(string.format("game[send2client_pb] msg:%s",msgname))
	local player = player_or_guid
	if type(player) ~= "table" then
		player = base_players[player_or_guid]
		if not player then
			log.warning("game[send2client_pb] not find player:" .. player_or_guid)
			print("------------send2client_pb return")
			return
		end
	end

	if player.is_android or not player.is_player then
		--print("----player is robot,send2client_pb return")
		if def_first_game_type ~= 8 then
			player:dispatch_msg(msgname,msg)
		end
		return
	end

	if not player.online then
		log.info(string.format("game[send2client_pb] offline, guid:%d  msg:%s",player.guid,msgname))
		print("------------send2client_pb return")
		return
	end

	local id = pb.enum(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))

	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	--print("send: "..msgname)
	send2client(player.guid, player.gate_id, id, stringbuffer)
end

function send2client_login(session_id, gate_id, msgname, msg)
	local id = pb.enum(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))

	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end

	send2client(session_id, gate_id, id, stringbuffer)
end

function send2login_pb(msgname, msg)
	local id = pb.enum(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))

	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end

	send2login(id, stringbuffer)
end


function send2loginid_pb(server_id, msgname, msg)
	local id = pb.enum(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))

	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end

	send2login_id(server_id, id, stringbuffer)
end