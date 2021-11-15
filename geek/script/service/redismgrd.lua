local skynet = require "skynet"

local table = table

local redisd_count = ...
redisd_count = redisd_count and tonumber(redisd_count) or 4

local redisds = {}

skynet.start(function()
	require "skynet.manager"
	local handle = skynet.localname ".redismgrd"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register(".redismgrd")

	for _ = 1,redisd_count do
		table.insert(redisds,skynet.newservice("redisd",skynet.self()))
	end

	skynet.dispatch("lua", function (_, _, cmd, ...)
		if cmd == "service" then
			skynet.retpack(redisds)
		end
	end)
end)