local skynet  = require "skynet"

local argstr = skynet.getenv("arg")
local arg = {}
for s in argstr:gmatch("[^%s]+") do
    table.insert(arg,s)
end

return arg