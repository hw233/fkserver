local skynet = require "skynetproto"
local assert = assert
local log = require "log"
local queue = require "skynet.queue"

local gateserver

local server = {}

local connection = {}

local queues = setmetatable({},{
	__index = function(t,fd)
		local q = queue()
		t[fd] = q
		return q
	end,
})

function server.closeclient(fd)
	local u = connection[fd]

	connection[fd] = nil
	queues[fd] = nil

	gateserver.closeclient(fd)
end

function server.ip(fd)
	local u = connection[fd]
	if u and u.fd then
		return u.ip
	end
end

function server.start(conf)
	local protocol = conf.protocol
	gateserver = require(protocol == "ws" and "gate.gateserver_ws" or "gate.gateserver")

	local expired_number = conf.expired_number or 128

	local handler = {
		conf = conf,
	}

	function handler.open(source, gateconf)
		
	end

	function handler.connect(fd, addr)
		local ip,port = addr:match("([^:]+)%s*:%s*(%d+)")
		port = tonumber(port)
		connection[fd] = {
			fd = fd,
			ip = ip,
			port = port,
			expired = false,
			open_time = os.time(),
		}

		if conf.connect_handler then
			conf.connect_handler(fd,addr)
		end
	end

	function handler.disconnect(fd)
		local c = connection[fd]
		if c then
			if conf.disconnect_handler then
				conf.disconnect_handler(c)
			end
			connection[fd] = nil
			queues[fd] = nil
		else
			log.warning("msgserver.disconnect got nil session,%s",fd)
		end
	end

	handler.error = handler.disconnect
	local request_handler = assert(conf.request_handler)

	local function do_request(c,msgstr)
		local ok, err = pcall(request_handler, msgstr,c)
		-- not atomic, may yield
		if not ok then
			log.error("Invalid package %s : %s", err, msgstr)
			local fd = c.fd
			if connection[fd] then
				gateserver.closeclient(fd)
				connection[fd] = nil
				queues[fd] = nil
			end
		end
	end

	function handler.message(fd, msgstr)
		local c = connection[fd]
		if not c then
			log.error("request arrive,got nil connection,maybe closed,%d",fd)
			return
		end
		
		local lock = queues[fd]
		return lock(function()
			-- double check
			c = connection[fd]
			if not c then
				log.error("request arrive double check got nil connection,maybe closed:%s",fd)
				return
			end

			return do_request(c,msgstr)
		end)
	end

	gateserver.start(handler)
	gateserver.open(conf)
end

return server
