local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local ws = require "websocket"
local log = require "log"

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = skynet.unpack,
    pack = skynet.pack,
}

local gateserver = {}

local socket	-- listen socket
local maxclient	-- max client
local client_number = 0
local buffer_pool = {}
local CMD = setmetatable({}, { __gc = function() socketdriver.clear(buffer_pool) end })
local nodelay

local connection = {}

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
		-- read some bytes
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

function gateserver.openclient(fd)
	if connection[fd] then
		socketdriver.start(fd)
	end
end

function gateserver.closeclient(fd)
	local c = connection[fd]
	if c then
        socketdriver.close(fd)
        connection[fd] = nil
	end
end

function gateserver.start(handler)
	assert(handler.message)
	assert(handler.connect)

	function CMD.open( source, conf )
		assert(not socket)
		local address = conf.address or "0.0.0.0"
		local port = assert(conf.port)
		maxclient = conf.maxclient or 1024
		nodelay = conf.nodelay
		log.info("Listen on %s:%d", address, port)
		socket = socketdriver.listen(address, port)
		socketdriver.start(socket)
		if handler.open then
			return handler.open(source, conf)
		end
	end

	function CMD.close()
		assert(socket)
		socketdriver.close(socket)
    end

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

    local function close_fd(fd)
		local c = connection[fd]
        if c then
            log.warning("close_fd,fd:%d,addr:%s",fd,c.addr)
            if c.co then
                wakeup(c)
            end
			connection[fd] = nil
			client_number = client_number - 1
		end
	end

    local function close(fd)
        if fd ~= socket then
			if handler.disconnect then
				handler.disconnect(fd)
            end
            log.info("%s closed",fd)
			close_fd(fd)
        else
            log.warning("listen fd: %d closed...",socket)
			socket = nil
		end
    end

    local function error(fd,msg)
        if fd == socket then
			socketdriver.close(fd)
			log.error("gateserver_ws close listen socket, accpet error:",msg)
        else
			if handler.error then
				handler.error(fd, msg)
			end
			close_fd(fd)
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
			-- log.warning("drop message from fd (%s) : %s", fd, msg)
		end
	end
	
	local function read_msg(fd)
		local c = connection[fd]
		if not c then
			return
		end

        local szstr = read(fd,2)
        if not szstr then
            return
        end

        local len = string.unpack("<H",szstr)
        local msg = read(fd,len - 2)
        return msg or ""
	end
    
    local function dispatch_queue(fd)
        local msg = read_msg(fd)
        if not msg and not connection[fd] then
            return
        end
        dispatch_msg(fd,msg)
        skynet.fork(dispatch_queue,fd)
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

	skynet.start(function()
		skynet.dispatch("lua", function (_, address, cmd, ...)
			local f = CMD[cmd]
			if f then
				skynet.ret(skynet.pack(f(address, ...)))
			else
				skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
			end
		end)
	end)
end

return gateserver
