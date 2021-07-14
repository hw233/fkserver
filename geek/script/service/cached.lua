local skynet = require "skynet"
local table = table

local agentcount = ...
agentcount = agentcount and tonumber(agentcount) or 16

local agentservice = {}
local redisd

skynet.start(function()
	require "skynet.manager"
	local handle = skynet.localname ".cached"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".cached"

	redisd = skynet.uniqueservice("redisd")

	skynet.dispatch("lua",function(_,_,cmd)
		if cmd == "AGENT" then
			skynet.retpack(agentservice)
			return
		end

		if cmd == "REDIS" then
			skynet.retpack(redisd)
			return
		end
	end)

	for _ = 1,agentcount do
		local id = skynet.newservice("cache_redisd",skynet.self())
		table.insert(agentservice,id)
	end
end)