
local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local log = require "log"
local gateserver = require "gate.gateserver_ws"
local socketdriver = require "skynet.socketdriver"
local skynet = require "skynet"

local upvals = getupvalue(gateserver.closeclient)

local connection = upvals.connection

if not connection then
	local cupvals = getupvalue(upvals.closeclient)
	dump(print,cupvals)
	connection = cupvals.connection
end

assert(connection)

function gateserver.closeclient(fd)
    log.warning("closeclient %d",fd)
	local c = connection[fd]
    if c then
        log.warning("positive close socket %d",fd)
        socketdriver.close(fd)
        connection[fd] = nil
		if c.co then
			c.co = nil
			skynet.wakeup(c.co)
		end
	end
end