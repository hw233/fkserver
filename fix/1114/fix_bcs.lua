
local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local timermgr = require "timermgr"

local tick = timermgr.tick

local upvals = getupvalue(tick)
local timers = upvals.timers


local club_cache

for _,timer in pairs(timers) do
	local fn = timer.callback
	local fnupvals = getupvalue(fn)
	club_cache = fnupvals.club_cache
	timer.callback = function(...) end
	break
end

local skynet = require "skynet"
local bc = require "broadcast"

local MAX_COUNT_PER_ONCE = 300
local INTERVAL  = 1

local function guard()
	for club_id,cache in pairs(club_cache) do
		if skynet.time() - cache.time >= INTERVAL or #cache.msgs >= MAX_COUNT_PER_ONCE then
			bc.broadcast2club_not_gaming(club_id,"SC_CLUB_SYNC_TABLES",{
				club_id = club_id,
				syncs = cache.msgs,
			})

			club_cache[club_id] = {
				time = skynet.time(),
				msgs = {},
			}
		end
	end
	timermgr:new_timer(INTERVAL,guard)
end


timermgr:new_timer(INTERVAL,guard)

dump(print,upvals)