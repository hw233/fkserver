-- demo消息处理

local pb = require "pb"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"



function on_cs_demo(player, msg)
	print (player.account, msg.test)
	
	send2client_pb(player, "SC_Demo", {
		test = "hello world"
	})
	
	print ("test .................. on_cs_demo")
end
