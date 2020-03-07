local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local log = require "log"

local agent = {}

local protocol = "http"

local SSLCTX_SERVER = nil
local function gen_interface(protocol, fd)
	if protocol == "http" then
		return {
			init = nil,
			close = nil,
			read = sockethelper.readfunc(fd),
			write = sockethelper.writefunc(fd),
		}
	elseif protocol == "https" then
		local tls = require "http.tlshelper"
		if not SSLCTX_SERVER then
			SSLCTX_SERVER = tls.newctx()
			-- gen cert and key
			-- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
			local certfile = skynet.getenv("certfile") or "./server-cert.pem"
			local keyfile = skynet.getenv("keyfile") or "./server-key.pem"
			log.info("%s,%s",certfile, keyfile)
			SSLCTX_SERVER:set_cert(certfile, keyfile)
		end
		local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
		return {
			init = tls.init_responsefunc(fd, tls_ctx),
			close = tls.closefunc(tls_ctx),
			read = tls.readfunc(fd, tls_ctx),
			write = tls.writefunc(fd, tls_ctx),
		}
	else
		error(string.format("Invalid protocol: %s", protocol))
	end
end

local response = {}

local function new_response(fd)
    return setmetatable({fd = fd,},{
        __index = response,
    })
end

function response:close()
    socket.close(self.fd)
end

function response:write(status,header,body)
    local interface = gen_interface(protocol,self.fd)
    httpd.write_response(interface.write,status,body,header)
end

function agent.start(proto,handle)
    protocol = proto
    skynet.dispatch("lua",function(_,_,fd,addr)
        log.info("gm request:%d,%s",fd,addr)
        socket.start(fd)
        local interface = gen_interface(protocol, fd)
        if interface.init then
            interface.init()
        end
    
        local code, url, method, header, body = httpd.read_request(interface.read)
        if not code then
            error("accept request error,%d",url)
            return
        end

        handle({
            addr = addr,
            code = code,
            url = url,
            method = method,
            header = header,
            body = body,
        },new_response(fd))
    end)
end

return agent

