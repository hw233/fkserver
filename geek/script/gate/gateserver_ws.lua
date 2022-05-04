local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local ws = require "websocket"
local log = require "log"
local timermgr = require "timermgr"

local gateserver = {}

local socket	-- listen socket
local client_number = 0
local buffer_pool = {}
local handshake_timeout = 5

local connection = setmetatable({}, { __gc = function() socketdriver.clear(buffer_pool) end })

local function is_socket_close(fd)
    return not connection[fd]
end

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

local function openclient(fd)
    log.info("openclient %d",fd)
	if connection[fd] then
		socketdriver.start(fd)
	end
end

function gateserver.openclient(fd)
    openclient(fd)
end

local function closeclient(fd)
    log.warning("closeclient %d",fd)
	local c = connection[fd]
    if c then
        log.warning("positive close socket %d",fd)
        socketdriver.close(fd)
        connection[fd] = nil
	end
end

function gateserver.closeclient(fd)
    closeclient(fd)
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

    local function dispatch(fd, msg)
		if connection[fd] then
			handler.message(fd, msg)
		else
			log.error("Drop message from fd (%d) : %c", fd, msg)
		end
    end

    local MAX_FRAME_SIZE = 256 * 1024 -- max frame is 256K
    local function recv(fd)
        local recv_count = 0
        local recv_buf = {}
        local first_op
        while true do
            local c = connection[fd]
            if not c then
                break
            end

            local op, fin , payload_data = ws.parse_frame(readfunc(fd))
            if not op or op == ws.OPCODE_CLOSE then
                socketdriver.send(fd,ws.build_close())
                close(fd)
                break
            end

            if op == ws.OPCODE_PING then
                socketdriver.send(fd,ws.build_pong())
            elseif op == ws.OPCODE_PONG then
                
            else
                if fin and #recv_buf == 0 then
                    dispatch(fd,payload_data)
                else
                    table.insert(recv_buf,payload_data)
                    recv_count = recv_count + #payload_data
                    if recv_count > MAX_FRAME_SIZE then
                        log.error("payload_len is too large")
                    end
                    first_op = first_op or op
                    if fin then
                        local s = table.concat(recv_buf)
                        dispatch(fd,s)
                        recv_buf = {}  -- clear recv_buf
                        recv_count = 0
                        first_op = nil
                    end
                end
            end
        end
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

        c.handshaking = true

        local timer = timermgr:calllater(handshake_timeout,function() 
            log.warning("handshake timeout %s",fd)
            if c.handshaking then
                closeclient(fd)
            end
        end)

        local ok,err,header = xpcall(ws.handshake,debug.traceback,{
            read = readfunc(fd),
            write = writefunc(fd),
        })
        
        if not ok then
            log.error("websocket handshake failed,%s,%s,%s",fd,addr,err)
            if not is_socket_close(fd) then 
                closeclient(fd)
            end
            timer:kill()
            return
        end

        c.handshaking = nil

        timer:kill()

        log.dump(header)
        
        local real_host = header['X-Real-Host'] or header["x-real-host"]
        local real_ip = header["X-Real-Ip"] or header["x-real-ip"]
        if real_host then
            addr = string.match(real_host,"%d+%.%d+%.%d+%.%d+:%d+") or addr
            log.info("websocket real-host redirect addr %s",addr)
        elseif real_ip then
            addr = real_ip .. ":" .. (header["x-real-port"] or header["X-Real-Port"] or "0")
            log.info("websocket real-ip redirect addr %s",addr)
        end

        handler.connect(fd,addr)

        local ok,err = xpcall(recv,debug.traceback,fd)
        local connecting = connection[fd]
        if not ok then
            if connecting then
                close(fd)
            end

            log.error("websocket recv got error:%s",err)
        end
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
