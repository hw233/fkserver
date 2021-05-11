local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"
require "functions"
local log = require "log"

local msgopt = _P.msg.msgopt

dump(print,msgopt)

local opfn = msgopt.C2S_CLUB_OP_REQ

local upvals = getupvalue(opfn)
local operator = upvals.operator

function on_cs_club_operation(msg,guid)
	local op = msg.op
	log.info("on_cs_club_operation %s,%s",guid,op)
	log.dump(msg)
    local f = operator[op]
    if f then
        f(msg,guid)
	else
		log.error("on_cs_club_operation %s,%s",guid,op)
    end
end

msgopt.C2S_CLUB_OP_REQ = on_cs_club_operation

dump(print,msgopt)