
def_db_id = table.unpack({...})

local skynet = require "skynet"
local msgopt = require "msgopt"
local dbopt = require "dbopt"
require "table_func"
local json = require "json"

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

-- print = function (...) end

local log = require "log"
require "hotfix"

local function get_db_cfg(db_id)
    local data = dbopt.config:query("SELECT * FROM t_db_server_cfg WHERE id = %d;",def_db_id)
    if not data or #data == 0 then
        return
    end

    dump(data)

    local cfg = data[1]
    if cfg.config then
        cfg.config = json.decode(cfg.config)
    end
    return cfg
end

skynet.start(function() 
    db_cfg = get_db_cfg(def_db_id)

    dump(db_cfg)

    require "db.register"

    skynet.dispatch("lua",function(_,source,cmd,...)
        skynet.retpack(msgopt.on_msg(source,cmd,...))
    end)
end)
