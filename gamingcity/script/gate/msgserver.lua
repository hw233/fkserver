local skynet = require "skynet"
local assert = assert
local log = require "log"
local protocol = skynet.getenv("conn.protocol")
local gateserver = require(protocol == "ws" and "gate.gateserver_ws" or "gate.gateserver")


local server = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local user_online = {}
local connection = {}

function server.logout(guid)
	local u = user_online[guid]
	user_online[guid] = nil
	if u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(fd,guid,conf)
	assert(user_online[guid] == nil)
	local c = assert(connection[fd])
	c.guid = guid
	user_online[guid] = {
		conf = conf,
		version = 0,
		index = 0,
		guid = guid,
		fd = fd,
		ip = c.ip,
	}
end

function server.ip(guid_or_fd)
	local u = user_online[guid_or_fd] or connection[guid_or_fd]
	if u and u.fd then
		return u.ip
	end
end

function server.start(conf)
	local expired_number = conf.expired_number or 128

	local handler = {}

	function handler.command(cmd, source, ...)
		local f = assert(conf[cmd])
		return f(...)
	end

	function handler.open(source, gateconf)

	end

	function handler.connect(fd, addr)
		gateserver.openclient(fd)
		connection[fd] = {
			fd = fd,
			ip = addr,
			expired = false,
			open_time = os.time(),
		}
	end

	function handler.disconnect(fd)
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if conf.disconnect_handler then
				conf.disconnect_handler(c)
			end
		end
	end

	handler.error = handler.disconnect
	local request_handler = assert(conf.request_handler)

	local function do_request(fd, msgstr)
		local ok, err = pcall(request_handler, fd, msgstr)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s : %s", err, msgstr))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end

	function handler.message(fd, msgstr)
		if not connection[fd] then
			log.error("request arrive,but connection closed,%d",fd)
			return
		end
			
		do_request(fd,msgstr)
	end

	return gateserver.start(handler)
end

return server
