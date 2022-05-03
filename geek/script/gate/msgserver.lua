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

	gateserver.close(fd)
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

	local function try(method,...)
		local f = conf[method]
		if f then
			f(...)
		end
	end
	
	local handler = {
		host = conf.address,
		port = conf.port,
	}

	function handler.open()
		
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

		try("connect_handler",fd,addr)
	end

	function handler.disconnect(fd)
		local c = connection[fd]
		if c then
			try("disconnect_handler",c)
			connection[fd] = nil
			queues[fd] = nil
			return
		end

		log.warning("msgserver.disconnect got nil session,%s",fd)
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
end

return server
