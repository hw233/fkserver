
local skynet = require "skynet"
local agent = require "gm.agent"
local gmd = require "gm.gmd"
local channel = require "channel"
local json = require "cjson"

local protocol = ...
protocol = protocol or "http"

global_sign = nil

local function get_php_sign()
    global_sign = channel.call("config.?","msg","query_php_sign")
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