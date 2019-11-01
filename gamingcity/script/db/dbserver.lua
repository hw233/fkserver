local skynet = require "skynet"


local dbserver = {}

function dbserver.error(fd, msg)
    
end

function dbserver.message(fd, msg, sz)
    on_server_dispatcher(fd,skynet.tostring(msg,sz))
end


function dbserver.connect(fd,msg)
    pcall(skynet.call,"forward","lua","connect",fd)
end

function dbserver.disconnect(fd)
    pcall(skynet.call,"forward","lua","disconnect",fd)
end

function dbserver.warning(fd,size)

end

return dbserver