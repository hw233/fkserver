local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"


local CMD = _P.lua.CMD

local upvals = getupvalue(CMD.do_transaction)

local dbpools = upvals.dbpools

local log = dbpools.log

log.__free = clone(log.__all)

log:wakeup()

dump(print,#log.__free,1)
