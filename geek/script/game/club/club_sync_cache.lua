local skynet = require "skynet"

local synccached

local cache = {}

function cache.sync(club_id,msg)
	skynet.send(synccached,"lua",club_id,msg)
end

skynet.init(function()
    synccached = skynet.uniqueservice("service.club_sync_cached")
end)

return cache
