local skynet = require "skynet"

local math = math
local random = math.random

local broadcast = {}

local broadcastd
local sender

local function choose_sender()
	sender = sender or skynet.call(broadcastd,"lua","SENDER")
	assert(sender and type(sender) == "table")
	return sender[random(1,#sender)]
end

function broadcast.broadcast2partial(guids,msgname,msg)
	skynet.send(choose_sender(),"lua","broadcast2partial",guids,msgname,msg)
end

function broadcast.broadcast2club(club,msgname,msg)
	skynet.send(choose_sender(),"lua","broadcast2club",club,msgname,msg)
end

function broadcast.broadcast2online(msgname,msg)
	skynet.send(choose_sender(),"lua","broadcast2online",msgname,msg)
end

function broadcast.broadcast2not_gaming(club,msgname,msg)
	skynet.send(choose_sender(),"lua","broadcast2not_gaming",club,msgname,msg)
end

function broadcast.broadcast2club_not_gaming(club,msgname,msg)
	skynet.send(choose_sender(),"lua","broadcast2club_not_gaming",club,msgname,msg)
end

skynet.init(function()
	broadcastd = skynet.uniqueservice("broadcastd")
end)

return broadcast