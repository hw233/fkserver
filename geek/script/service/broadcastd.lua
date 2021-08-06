
local skynet = require "skynet"
local log = require "log"

local agentcount = ...

agentcount = tonumber(agentcount) or 16

local senderservice = {}

skynet.start(function()
	require "skynet.manager"
	local handle = skynet.localname ".broadcastd"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".broadcastd"

	for _ = 1,agentcount do
		local s = skynet.newservice("broadcastsender",skynet.self())
		table.insert(senderservice,s)
	end

	skynet.dispatch("lua", function (_, _, cmd, ...)
		if cmd == "SENDER" then
			skynet.retpack(senderservice)
			return
		end
	end)
end)