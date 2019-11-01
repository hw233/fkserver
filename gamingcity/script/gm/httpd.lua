local skynet = require "skynet"
local httpd = require "http.httpd"
local socket = require "skynet.socket"
local log = require "log"

local listend

function httpd.start(dispatch)
    local CMD = {}

    function CMD.open(conf)
        listend = socket.listen(conf.host,conf.port,conf.backlog)
        skynet.error(string.format("Listen web port %d",conf.port))
        socket.start(listend,dispatch)
    end

    function CMD.close()
        socket.close(listend)
    end

    skynet.start(function()
		skynet.dispatch("lua", function (_, address, cmd, ...)
			local f = CMD[cmd]
			if f then
				skynet.ret(skynet.pack(f(address, ...)))
			else
				log.error("invalid cmd:%s",cmd)
			end
		end)
	end)
end

return httpd