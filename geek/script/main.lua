local skynet = require "skynet"
require "functions"
local log = require "log"


local args = require("argment")
if #args == 0 then
    return
end


local clusterid = tonumber(args[1])
if not clusterid then
    log.error("cluster id is nil")
    return
end

skynet.setenv("clusterid",tonumber(clusterid))


require "bootloader"

