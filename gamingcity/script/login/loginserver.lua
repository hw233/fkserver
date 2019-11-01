local skynet = require "skynet"
local msgopt = require "msg_opt"
local netopt = require "net_opt"
local connector = require "connector"

local loginserver = {}

function loginserver.error(fd, msg)
    skynet.sleep(3)
    connector.reconnect(fd)
end

function loginserver.message(fd, msg, sz)
    msgopt.on_server(fd,skynet.tostring(msg,sz))
end


function loginserver.connect(fd,msg)
    
end

function loginserver.disconnect(fd)
    
end

function loginserver.warning(fd,size)

end

return loginserver