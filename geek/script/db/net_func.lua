local channel = require "channel"

function send2game_pb(game_id, msgname, msg)
	channel.publish("game."..tostring(game_id),"msg",msgname,msg)
end

function send2login_pb(login_id, msgname, msg)
	channel.publish("logind."..tostring(login_id),"msg",msgname,msg)
end