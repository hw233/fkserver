local skynet = require "skynet"
local msgopt = require "msgopt"
local netopt = require "netopt"

local configserver = {}

function configserver.error(fd, msg)
    
end

function configserver.message(fd, msg, sz)
    msgopt.on_msg(fd,skynet.tostring(msg,sz))
end


function configserver.connect(fd,msg)
    
end

function configserver.disconnect(fd)
    
end

function configserver.warning(fd,size)

end

return configserver