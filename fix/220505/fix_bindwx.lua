local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"
require "functions"
local log = require "log"
local msgopt = _P.msg.msgopt

dump(print,msgopt)

msgopt.CS_RequestBindWx = function () log.info("fix CS_RequestBindWx") end

dump(print,msgopt)