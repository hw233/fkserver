local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"


local CMD = _P.lua.CMD

dump(print,CMD)

function CMD.D(guid)

end

dump(print,CMD)