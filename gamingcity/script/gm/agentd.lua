
local skynet = require "skynet"
local agent = require "gm.agent"
local gmd = require "gm.gmd"
local dbopt = require "dbopt"

local protocol = ...
protocol = protocol or "http"

local function get_php_sign()
    local data = dbopt.config:query("SELECT * FROM t_globle_string_cfg WHERE t_globle_string_cfg.key = 'php_sign_key';")
    if not data then
        return
    end

    -- dump(data)

    return data[1].value
end

skynet.start(function() 
    global_sign = get_php_sign()
    if not global_sign then
        return
    end

    agent.start(protocol,function(request,response) 
        if not request.header or not request.header["Content-Type"] then
            response:write(404,nil,"")
            return
        end

        local cmd = request.header["Content-Type"]
        local f = gmd[cmd]
        if f then
            response:write(404,nil,"{\"result\":1}")
            return
        end

        local body = gmd[cmd](json.decode(request.body))
        response:write(200,nil,body)
        response:close()
    end)
end)