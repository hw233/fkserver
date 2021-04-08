local skynet = require "skynet"
require "functions"
local log = require "log"

clusterid = tonumber(...)

if not clusterid then
    log.error("cluster id is %s",clusterid)
    return
end

require "bootloader"

skynet.start(function() 
    skynet.newservice("debug_console", 8008)
end)