local skynet = require "skynet"
local msgopt = require "msg_opt"

local gameserver = {}

function gameserver.error(fd, msg)
    
end

function gameserver.message(fd, msg, sz)
    msgopt.on_server(fd,skynet.tostring(msg,sz))
end


function gameserver.connect(fd,msg)
    pcall(skynet.call,"forward","lua","connect",fd)
end

function gameserver.disconnect(fd)
    pcall(skynet.call,"forward","lua","disconnect",fd)
end

function gameserver.warning(fd,size)

end

return gameserver