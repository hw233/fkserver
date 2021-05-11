local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local tremove = table.remove

local synccache = require "game.club.club_sync_cache"
local timermgr = require "timermgr"
local tupvals = getupvalue(timermgr.tick)
local timers = tupvals.timers

local supvals = getupvalue(synccache.sync)
local syncqueue = supvals.syncqueue
local tinsert = table.insert


local skynet = require "skynet"
local MAX_COUNT_PER_ONCE = 200
local bc = require "broadcast"

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

for _,t in pairs(timers) do
	if t.repeated and t.interval == 0.2 then
		dump(print,t)
		t.callback = do_broadcast
		dump(print,t)
	end
end