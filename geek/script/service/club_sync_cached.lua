local skynet = require "skynet"
local bc = require "broadcast"
local timermgr = require "timermgr"

local tinsert = table.insert

local MAX_COUNT_PER_ONCE = 50
local INTERVAL  = 0.3

local club_cache = {}

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

skynet.start(function()
	skynet.dispatch("lua", function (_, _, club_id,msg)
		club_cache[club_id] = club_cache[club_id] or {
			time = skynet.time(),
			msgs = {},
		}
		tinsert(club_cache[club_id].msgs,msg)
	end)

	timermgr:new_timer(INTERVAL,guard)
end)




