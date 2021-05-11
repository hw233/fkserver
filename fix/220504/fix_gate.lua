local getupvalue = require "fix.getupvalue"
local dump = require "fix.dump"

local gateserver = require "gate.gateserver_ws"
local log = require "log"
local socketdriver = require "skynet.socketdriver"
local ws = require "websocket"
local skynet = require "skynet"

local socket_message = _P.socket.socket_message

dump(print,socket_message)

local upvals = getupvalue(gateserver.start)
local connection = upvals.connection
local wakeup = upvals.wakeup
local readfunc = upvals.readfunc
local writefunc = upvals.writefunc
local handler = upvals.handler

local function dispatch_msg(fd, msg)
	if connection[fd] then
		handler.message(fd, msg)
	else
		log.error("Drop message from fd (%d) : %c", fd, msg)
	end
end

local function ws_close(fd,code,reason)
	log.warning("websocket close,%d code:%s,reason:%s",fd,code,reason)
	socketdriver.close(fd)
end

local ws_frame_dispatch = {
	[ws.OPCODE_CLOSE] = function(fd,code,reason)
		ws_close(fd,code,reason)
	end,
	[ws.OPCODE_BINARY] = function(fd,msg,_)
		dispatch_msg(fd,msg)
	end,
	[ws.OPCODE_PING] = function(fd,msg,_)
		socketdriver.send(fd,ws.build_pong(msg))
	end,
	[ws.OPCODE_PONG] = function(fd,msg,_)

	end,
	[ws.OPCODE_TEXT] = function(fd,msg,_)
		return
	end,
}

local function ws_pick_msg(fd)
	local framecode,reason
	local msg = ""
	local final
	local partialmsg
	while true do
		framecode,final,partialmsg,reason = ws.parse_frame(readfunc(fd))
		if not framecode then
			msg = partialmsg
			break
		end

		if final then
			if framecode == ws.OPCODE_CLOSE then
				return framecode,partialmsg,reason
			end

			msg = msg..partialmsg
			break
		end

		msg = msg..partialmsg
	end
	
	return framecode,msg,reason
end

local function close_session(fd)
	log.warning("close_session,fd:%s",fd)
	socketdriver.close(fd)
	local c = connection[fd]
	if not c then 
		return 
	end

	connection[fd] = nil        
	if c.co then
		wakeup(c)
	end
	if handler.disconnect then
		handler.disconnect(fd)
	end
end

local function close(fd)
	log.warning("socket close %s",fd)
	if fd ~= socket then
		close_session(fd)
	else
		log.warning("listen fd: %s closed...",socket)
		socket = nil
	end
end

local function dispatch_queue(fd)
	local framecode,msg,reason = ws_pick_msg(fd)
	if not framecode then
		local c = connection[fd]
		if c then
			close(c.fd)
		end
		log.warning("websocket parse frame got nil framecode,maybe lost connection:%s",msg)
		return
	end

	if framecode ~= ws.OPCODE_CLOSE then
		skynet.fork(dispatch_queue,fd)
	end
	ws_frame_dispatch[framecode](fd,msg,reason)
end

local function open(_,fd,addr)
	log.info("got connection from %s",addr)
	local c = {
		fd = fd,
		addr = addr,
		buffer = socketdriver.buffer(),
	}

	connection[fd] = c

	gateserver.openclient(fd)

	local ok,_,header = ws.handshake({
		read = readfunc(fd),
		write = writefunc(fd),
	})
	
	if not ok then
		log.error("websocket handshake failed,fd:",fd,addr)
		gateserver.closeclient(fd)
		return
	end

	log.dump(header)

	local real_host = header['X-Real-Host'] or header["x-real-host"]
	if real_host then
		addr = string.match(real_host,"%d+%.%d+%.%d+%.%d+:%d+") or addr
		log.info("websocket redirect addr %s",addr)
	end

	local real_ip = header["X-Real-Ip"] or header["x-real-ip"]
	if real_ip then
		addr = real_ip .. ":" .. (header["x-real-port"] or header["X-Real-Port"] or "0")
		log.info("websocket redirect addr %s",addr)
	end

	handler.connect(fd,addr)

	skynet.fork(dispatch_queue,fd)
end

socket_message[4] = open

dump(print,socket_message)