local skynet = require "skynet"
local log = require "log"
local websocket = require "http.websocket"
local socket = require "skynet.socket"
local gateserver = {}

local acceptor	-- listen socket

local address = {}

function gateserver.close(fd)
    log.warning("websocket close %s",fd)
    websocket.close(fd)
    address[fd] = nil
end

function gateserver.stop()
    if acceptor then
        socket.close(acceptor)
    end
    address = {}
end

function gateserver.start(conf)
	assert(conf.message)
    assert(conf.connect)

    local host = conf.host or "0.0.0.0"
    local port = assert(conf.port)

    local function try(method,...)
        local f = conf[method]
        if f then
            f(...)
        end
    end

    local handle = {
        close = function(id,code, reason)
            log.warning("websocket close %s",id)
            try("disconnect",id)
            address[id] = nil
        end,
        error = function(id)
            log.warning("websocket error %s",id)
            try("error",id)
            address[id] = nil
        end,
        handshake = function(id, header, url)
            local addr = assert(address[id])
           
            log.dump(header)

            local real_host = header['X-Real-Host'] or header["x-real-host"]
            local real_ip = header['X-Real-Ip'] or header["x-real-ip"]
            local x_real_port = header['x-real-port'] or header['X-Real-Port'] 
            -- assert(x_real_port)

            local x_forwarded_hot = nil

            -- 获取真实IP
            local x_for_ip = header['x-forwarded-for'] or header['X-Forwarded-For']

            -- 空判断
            if x_for_ip then
                -- x_for_ip
                local start_idx,end_idx = string.find(x_for_ip,',')
                log.warning("start_idx %s,%s",start_idx,end_idx)
                
                if start_idx then
                    local ip_list = string.split(x_for_ip,"[^,]+")
                    log.dump(ip_list)
                    x_for_ip = string.trim(ip_list[1])
                end


                x_forwarded_hot = (x_for_ip..":".. x_real_port) or real_host

                log.warning("x_forwarded_hot %s",x_forwarded_hot)

            end

            if x_forwarded_hot then
                addr = string.match(x_forwarded_hot,"%d+%.%d+%.%d+%.%d+:%d+") or real_host
                log.info("websocket x-forwarded-for redirect addr %s",addr)
            elseif real_host then
                addr = string.match(real_host,"%d+%.%d+%.%d+%.%d+:%d+") or addr
                log.info("websocket real-host redirect addr %s",addr)
            elseif real_ip then
                addr = real_ip .. ":" .. (header['X-Real-Port'] or header["x-real-port"] or 0)
                log.info("websocket real-ip redirect addr %s",addr)
            end

            log.warning("handshake %s,%s",id,addr)
            try("connect",id,addr)
        end,
        message = function(id, msg, op)
            try("message",id, msg)
        end
    }

    log.info("websocket listen on %s:%d", host, port)
    acceptor = socket.listen(host, port)
	socket.start(acceptor, function(fd, addr)
		log.info("accept client fd: %s addr:%s", fd, addr)
        address[fd] = addr
        local err,errs = websocket.accept(fd,handle,"ws",addr)
        log.info("accept client end,fd:%s %s",fd,err)
        if not err then
            try("disconnect",fd)
        end
	end)

    try("open",conf)
end

return gateserver
