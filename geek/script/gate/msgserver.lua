local skynet = require "skynetproto"
local assert = assert
local log = require "log"
local netmsgopt = require "netmsgopt"

local protocol = protocol
local gateserver
local logind

local server = {}

local user_online = {}
local connection = {}

function server.logout(guid)
	local u = user_online[guid]
	
	if not u then return end

	user_online[guid] = nil
	
	if not u.fd then return end

	local c = connection[u.fd]
	if c then
		c.guid = nil
		c.version = nil
		c.conf = nil
	end
end

function server.close(fd)
	connection[fd] = nil
	gateserver.closeclient(fd)
end

function server.login(fd,guid,conf)
	local c = connection[fd]
	if c then
		c.guid = guid
	end
	user_online[guid] = {
		conf = conf,
		version = 0,
		index = 0,
		guid = guid,
		fd = fd,
		ip = c and c.ip or nil,
		port = c and c.port or nil,
	}
end

function server.ip(guid_or_fd)
	local u = user_online[guid_or_fd] or connection[guid_or_fd]
	if u and u.fd then
		return u.ip
	end
end

function server.guid(fd)
	local c = connection[fd]
	if not c then
		return nil
	end

	return c.guid
end

function server.register_logind(s)
	logind = s
end

function server.start(conf)
	gateserver = require(protocol == "ws" and "gate.gateserver_ws" or "gate.gateserver")

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
		local ip,port = addr:match("([^:]+)%s*:%s*(%d+)")
		port = tonumber(port)
		connection[fd] = {
			fd = fd,
			ip = ip,
			port = port,
			expired = false,
			open_time = os.time(),
		}
	end

	function handler.disconnect(fd)
		local c = connection[fd]
		if c then
			if c.guid and conf.disconnect_handler then
				conf.disconnect_handler(c)
			end
			connection[fd] = nil
		end
	end

	handler.error = handler.disconnect
	local request_handler = assert(conf.request_handler)

	local function do_request(fd,msgstr)
		local ok, err = pcall(request_handler, msgstr,connection[fd])
		-- not atomic, may yield
		if not ok then
			log.error("Invalid package %s : %s", err, msgstr)
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end

	local function do_auth(fd,msgstr)
		skynet.send(logind,"client",msgstr,connection[fd])
	end

	function handler.message(fd, msgstr)
		local c = connection[fd]
		if not c then
			log.error("request arrive,but connection closed,%d",fd)
			return
		end

		if not c.guid then
			log.info("do_auth %s,%s",fd,#msgstr)
			return do_auth(fd,msgstr)
		end
		
		return do_request(fd,msgstr)
	end

	return gateserver.start(handler)
end

return server
