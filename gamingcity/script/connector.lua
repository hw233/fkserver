local netopt = require "net_opt"
local socketdriver = require "skynet.socketdriver"

local connector = {}

function connector.open(conf)
    assert(conf.type and conf.server_id and conf.host and conf.port)

    local fd = socketdriver.connect(conf.host,conf.port)
    connector[fd] = conf
    netopt.on_connect(fd,conf)
    return fd
end

function connector.close(fd)
    local conf = connector[fd]
    if not conf then 
        return
    end

    connector[fd] = nil

    netopt.on_disconnect(fd)
end

function connector.reconnect(fd)
    local conf = connector[fd]
    if not conf then
        return nil
    end

    connector[fd] = nil
    fd = connector.open(conf)
    return fd
end

return connector