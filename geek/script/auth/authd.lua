local httpc = require "http.httpc"
local log = require "log"
local json = require "cjson"
local conf = require "conf.auth"

local MSG = {}

local function formaturl(conf,code)
    
end

function MSG.wx_getuserinfo(body)
    local context = json.decode(body)
    
end

function MSG.xl_getuserinfo(body)
    local context = json.decode(body)
end

MSG["wx/getuserinfo"] = MSG.wx_getuserinfo
MSG["xl/getuserinfo"] = MSG.wx_getuserinfo


return MSG
