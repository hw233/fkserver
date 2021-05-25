local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local ws = require "websocket"
local log = require "log"


local gateserver = {}

local socket	-- listen socket
local maxclient	-- max client
local client_number = 0
local buffer_pool = {}
local nodelay

local connection = setmetatable({}, { __gc = function() socketdriver.clear(buffer_pool) end })

local function wakeup(c)
    local co = c.co
    if co then
        c.co = nil
        skynet.wakeup(co)
    end
end

local function suspend(c)
    assert(not c.co)
    c.co = coroutine.running()
    skynet.wait(c.co)
    -- wakeup closing corouting every time suspend,
    -- because socket.close() will wait last socket buffer operation before clear the buffer.
    if not connection[c.fd] then
        skynet.wakeup(c.closing)
    end
end

local function read(fd,sz)
    local c = connection[fd]
    if not c then
        log.warning("socket closed when read,fd:%d,size:%d",fd,sz)
        return nil
    end

	if sz == nil then
		local ret = socketdriver.readall(c.buffer, buffer_pool)
		if ret ~= "" then
			return ret
		end

		if not connection[fd] then
			return nil, ret
        end

		assert(not c.read_required)
        c.read_required = 0
		suspend(c)
		ret = socketdriver.readall(c.buffer, buffer_pool)
		if ret ~= "" then
			return ret
        end

		return nil, ret
	end

	local ret = socketdriver.pop(c.buffer, buffer_pool, sz)
	if ret then
		return ret
    end

	if not connection[fd] then
		return nil, socketdriver.readall(c.buffer, buffer_pool)
	end

	assert(not c.read_required)
    c.read_required = sz
	suspend(c)
	ret = socketdriver.pop(c.buffer, buffer_pool, sz)
    if ret then
		return ret
	end

    return nil, socketdriver.readall(c.buffer, buffer_pool)
end

local function readfunc(fd)
    return function(sz)
        return read(fd,sz)
    end
end

local function writefunc(fd)
    return function(data)
        return socketdriver.send(fd,data)
    end
end

function gateserver.openclient(fd)
    log.info("openclient %d",fd)
	if connection[fd] then
		socketdriver.start(fd)
	end
end

function gateserver.closeclient(fd)
    log.warning("closeclient %d",fd)
	local c = connection[fd]
    if c then
        log.warning("positive close socket %d",fd)
        socketdriver.close(fd)
        connection[fd] = nil
	end
end

local handler 

function gateserver.open(conf)
    assert(not socket)
    local address = conf.address or "0.0.0.0"
    local port = assert(conf.port)
    maxclient = conf.maxclient or 1024
    nodelay = conf.nodelay
    log.info("Listen on %s:%d", address, port)
    socket = socketdriver.listen(address, port)
    socketdriver.start(socket)
    if handler.open then
        return handler.open(conf)
    end
end

function gateserver.close()
    assert(socket)
    socketdriver.close(socket)
end

function gateserver.start(conf)
	assert(conf.message)
    assert(conf.connect)
    
    handler = conf

    local function data(fd,size,msg) 
        local c = connection[fd]
        if c == nil then
            log.error("no connection when data arrive, drop package from " .. fd)
            socketdriver.drop(msg, size)
            return
        end

        local sz = socketdriver.push(c.buffer, buffer_pool, msg, size)
        if c.read_required and sz >= c.read_required then
            c.read_required = nil
            wakeup(c)
        end
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

        client_number = client_number - 1
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

    local function error(fd,msg)
        log.error("socket error,%s,%s",fd,msg)
        if fd == socket then
			socketdriver.close(fd)
			log.error("gateserver_ws close listen socket, accpet error:",msg)
        else
			if handler.error then
				handler.error(fd, msg)
			end
			close(fd)
		end
    end

    local function warning(fd,size)
        if handler.warning then
			handler.warning(fd, size)
		end
    end

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

        skynet.fork(dispatch_queue,fd)
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
        client_number = client_number + 1

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

        handler.connect(fd,addr)

        skynet.fork(dispatch_queue,fd)
    end

    local socket_message = {
        -- SKYNET_SOCKET_TYPE_DATA = 1
        [1] = data,
        -- SKYNET_SOCKET_TYPE_CONNECT = 2
        [2] = function(fd, _ , addr) end,
        -- SKYNET_SOCKET_TYPE_CLOSE = 3
        [3] = close,
        -- SKYNET_SOCKET_TYPE_ACCEPT = 4
        [4] = open,
        -- SKYNET_SOCKET_TYPE_ERROR = 5
        [5] = error,
        -- SKYNET_SOCKET_TYPE_UDP = 6
        [6] = function(fd, size, data, address) end,
        -- SKYNET_SOCKET_TYPE_WARNING
        [7] = warning,
    }

    skynet.register_protocol {
        name = "socket",
        id = skynet.PTYPE_SOCKET,	-- PTYPE_SOCKET = 6
        unpack = socketdriver.unpack,
        dispatch = function (_, _, t, ...)
            socket_message[t](...)
        end
    }
end

return gateserver
