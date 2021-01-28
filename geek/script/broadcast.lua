local skynet = require "skynet"

local broadcast = {}

local broadcastd = ".broadcastd"

function broadcast.broadcast2partial(guids,msgname,msg)
	skynet.send(broadcastd,"lua","broadcast2partial",guids,msgname,msg)
end

function broadcast.broadcast2club(club,msgname,msg)
	skynet.send(broadcastd,"lua","broadcast2club",club,msgname,msg)
end

function broadcast.broadcast2online(msgname,msg)
	skynet.send(broadcastd,"lua","broadcast2online",msgname,msg)
end

skynet.start(function()
	broadcastd = skynet.uniqueservice("service.broadcastd")
end)

return broadcast