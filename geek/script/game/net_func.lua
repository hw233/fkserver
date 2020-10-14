local pb = require "pb_files"
local skynet = require "skynetproto"
local netguidopt = require "netguidopt"
local channel = require "channel"
local log = require "log"

--先写死只播一次
function broadcast_world_marquee(first_game_type_,second_game_type_,notice_type_,...)
	local param = {...}
	local p1 = param[1] or ""
	local p2 = param[2] or ""
	local p3 = param[3] or ""
	local p4 = param[4] or ""
	local p5 = param[5] or ""

	local game_notice = {
		first_game_type = first_game_type_,
		second_game_type = second_game_type_,
		number = 1,
		interval_time = 0,
		start_time =  skynet.time(),
		notice_type = notice_type_,
		param1 = p1,
		param2 = p2,
		param3 = p3,
		param4 = p4,
		param5 = p5,
	}

	channel.publish("login.?","msg","SL_GameNotice",{pb_game_notice = game_notice})
end

function broadcast_platform_marquee(platform_id,first_game_type_,second_game_type_,notice_type_,...)
	local param = {...}
	local p1 = param[1] or ""
	local p2 = param[2] or ""
	local p3 = param[3] or ""
	local p4 = param[4] or ""
	local p5 = param[5] or ""

	local game_notice = {
		first_game_type = first_game_type_,
		second_game_type = second_game_type_,
		number = 1,
		interval_time = 0,
		start_time =  os.time(),
		notice_type = notice_type_,
		param1 = p1,
		param2 = p2,
		param3 = p3,
		param4 = p4,
		param5 = p5,
	}

	channel.publish("login.?","msg","SL_GameNotice",{pb_game_notice = game_notice,platform_id = tostring(platform_id)})
end


function send2client_pb(player_or_guid, msgname, msg)
	local guid = type(player_or_guid) == "table" and player_or_guid.guid or player_or_guid
	netguidopt.send(guid,msgname,msg)
end