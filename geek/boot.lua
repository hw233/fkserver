include "path.lua"

-- preload = "./examples/preload.lua"	-- run preload.lua before every lua service run
thread = 40
logger = "service.logd"
logservice = "snlua"
harbor = 0
-- address = "127.0.0.1:2526"
-- master = "127.0.0.1:2013"
start = "main"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap
-- standalone = "0.0.0.0:2013"
-- snax_interface_g = "snax_g"
cpath = root.."cservice/?.so"
-- daemon = "./skynet.pid"
lualoader = "./common/loader.lua"
