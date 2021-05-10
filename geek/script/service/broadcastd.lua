
local skynet = require "skynet"
local log = require "log"
local club_member = require "game.club.club_member"
local onlineguid = require "netguidopt"
local channel = require "channel"
local allonlineguid = require "allonlineguid"

local table = table
local string = string
local tinsert = table.insert
local strfmt = string.format

local CMD = {}

local function broadcast2guids(guids,msgname,msg,fn)
	local guid_session = table.map(guids,function(guid)
		local session = onlineguid[guid]
		if not fn or fn(session) then
			return guid,session and session.gate or nil
		end
	end)

	local gateguids = {}
    for guid,gate in pairs(guid_session) do
		gateguids[gate] = gateguids[gate] or {}
		tinsert(gateguids[gate],guid)
    end

    for gate,guids in pairs(gateguids) do
        channel.publish("gate."..gate,"client",guids,"broadcast",msgname,msg)
    end
end

function CMD.broadcast2club(club,msgname,msg)
	local guids = club_member[club]
	guids = table.series(guids,function(_,guid) return tonumber(guid) end)
	broadcast2guids(guids,msgname,msg or {})
end

function CMD.broadcast2online(msgname,msg)
	local all = allonlineguid["*"]
	local guids = table.keys(all)
	broadcast2guids(guids,msgname,msg or {})
end

function CMD.broadcast2partial(guids,msgname,msg)
	broadcast2guids(guids,msgname,msg or {})
end

function CMD.broadcast2not_gaming(guids,msgname,msg)
	broadcast2guids(guids,msgname,msg or {},function(s) 
		return not s.table and not s.chair
	end)
end

function CMD.broadcast2club_not_gaming(club,msgname,msg)
	local guids = club_member[club]
	guids = table.series(guids,function(_,guid) return tonumber(guid) end)
	CMD.broadcast2not_gaming(guids,msgname,msg)
end

skynet.start(function()
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else
			log.error("unknown cmd:"..cmd)
			skynet.retpack(nil)
		end
	end)

	require "skynet.manager"
	local handle = skynet.localname ".broadcastd"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".broadcastd"
end)