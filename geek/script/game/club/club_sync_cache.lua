local log = require "log"

local timermgr = require "timermgr"
local skynet = require "skynet"
local bc = require "broadcast"

local table = table
local tinsert = table.insert
local tremove = table.remove

local MAX_COUNT_PER_ONCE = 400
local INTERVAL  = 0.3

local syncqueue = {}
local cache = {}

function cache.sync(club_id,msg)
	tinsert(syncqueue,{
		time = skynet.time(),
		club = club_id,
		msg = msg,
	})
end

local function do_broadcast()
	local clubsync = {}
	local now = skynet.time()
	local i = MAX_COUNT_PER_ONCE
	while i > 0 do
		local c = syncqueue[1]
		if not c then break end
		local club = c.club
		clubsync[club] = clubsync[club] or {}
		tinsert(clubsync[club],c.msg)
		tremove(syncqueue,1)
		i = i - 1
	end

	for club_id,msgs in pairs(clubsync) do
		bc.broadcast2club_not_gaming(club_id,"SC_CLUB_SYNC_TABLES",{
			club_id = club_id,
			syncs = msgs,
		})
	end
end

timermgr:loop(0.2,do_broadcast)

return cache
