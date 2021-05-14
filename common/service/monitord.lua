local skynet = require "skynet"
local channel = require "channel"
local log = require "log"

local string = string
local strfmt = string.format

LOG_NAME = "monitord"

local servicewatcher = {}

local CMD = {}

function CMD.start(_,servicename,...)

end

function CMD.kill(_,servicename)

end

function CMD.reload(_,servicename)

end

function CMD.watch(watcher,servicename)
	local w = servicewatcher[servicename]
	if not w then
		if w == false then
			skynet.retpack(false)
			return
		end
		w = {}
		servicewatcher[servicename] = w
	end
	w[watcher] = true
	skynet.retpack(true)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,	-- PTYPE_CLIENT = 3
	unpack = function() end,
	dispatch = function(_, address)
		local w = servicewatcher[address]
		if w then
			for watcher in pairs(w) do
				skynet.redirect(watcher, address, "error", 0, "")
			end
			servicewatcher[address] = false
		end
	end
}

skynet.register_protocol {
	name = "system",
	id = skynet.PTYPE_SYSTEM,
	unpack = function() end,
	dispatch = function()
		log.info('terminal')
	end
}

skynet.start(function()
	require "skynet.manager"
    local handle = skynet.localname ".montord"
	if handle then
		skynet.exit()
		return
	end

	skynet.register ".montord"

	skynet.dispatch("lua",function(_,source,cmd,...)
		local f = CMD[cmd]
		if not f then
			skynet.error(strfmt("invalid cmd %s",cmd))
			return
		end

		skynet.retpack(f(source,...))
	end)

	local monitorname = "monitor." .. math.floor(skynet.time() * 1000) .. math.random(1,10000)
	channel.subscribe(monitorname,skynet.self())
end)

