local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"


local upvals = getupvalue(_P.lua.CMD.S)

dump(print,upvals,1)

local queues = upvals.queues

dump(print,queues)

queues[581428] = nil
queues[682620] = nil

print("fix success")