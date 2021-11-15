local skynet = require "skynet"
local table = table

local agentcount = ...
agentcount = agentcount and tonumber(agentcount) or 64

local agentservice = {}

skynet.start(function()
	require "skynet.manager"
	local handle = skynet.localname ".cached"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".cached"

	skynet.dispatch("lua",function(_,_,cmd)
		if cmd == "AGENT" then
			skynet.retpack(agentservice)
			return
		end
	end)

	for _ = 1,agentcount do
		local id = skynet.newservice("cache_redisd",skynet.self())
		table.insert(agentservice,id)
	end
end)