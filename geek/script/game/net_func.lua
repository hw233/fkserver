local netguidopt = require "netguidopt"


function send2client_pb(player, msgname, msg)
	local guid = type(player) == "table" and player.guid or player
	netguidopt.send(guid,msgname,msg)
end

function broadcast2client(guids,msgname,msg)
	local uniform_guids = table.series(guids,function(p)
		return type(p) == "table" and p.guid or p
	end)
	netguidopt.broadcast(uniform_guids,msgname,msg)
end