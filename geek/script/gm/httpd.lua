local httpd = require "http.httpd"
local socket = require "skynet.socket"
local log = require "log"

local listend

function httpd.open(conf,dispatch)
    local host = conf.host
    local port = conf.port
    if not conf.port then
        host,port = host:match("([^:]+):(%d+)")
    end

    listend = socket.listen(host,port,conf.backlog)
    log.info("Listen web host: %s,port:%d",host,port)
    socket.start(listend,dispatch)
end

function httpd.close()
    socket.close(listend)
end

return httpd