
local skynet = require "skynet"
local agent = require "gm.agent"
local gmd = require "gm.gmd"
local channel = require "channel"
local json = require "cjson"
local error = require "gm.errorcode"
local md5 = require "md5.core"
require "functions"

local protocol = ...
protocol = protocol or "http"

local appkey = nil

local function check_sign_code(sign,data)
    local keys = table.keys(data)
    table.sort(keys)
    local source = {}
    for _,k in ipairs(keys) do
        local v = data[k]
        if type(v) == "number" then v = string.format("%d",v) end
        table.insert(source,k.."="..v)
    end
    table.insert(source,"appkey="..appkey)
    local s = table.concat(source,"&")
    return sign:upper() == md5.sumhexa(s):upper()
end

skynet.start(function()
    appkey = channel.call("config.?","msg","query_php_sign")
    assert(appkey)

    agent.start(protocol,function(request,response)
        dump(request)
        if not request.url then
            response:write(404,nil,json.encode({
                errcode = error.REQUEST_INVALID
            }))
            return
        end

        local cmd = request.url:sub(2)
        local f = gmd[cmd]
        if not f then
            response:write(404,nil,json.encode({
                errcode = error.REQUEST_INVALID
            }))
            return
        end

        local body = request.body
        if not body or body == "" then 
            body = "{}"
        end

        local ok,data = pcall(json.decode,body)
        if not ok or not data then
            response:write(404,nil,json.encode({
                errcode = error.DATA_ERROR,
            }))
            return
        end

        local sign = request.header.sign
        if not sign then
            response:write(404,nil,json.encode({
                errcode = error.SIGNATURE_ERROR,
            }))
            return
        end

        dump(sign)
        dump(data)

        if not check_sign_code(sign,data) then
            response:write(404,nil,json.encode({
                errcode = error.SIGNATURE_ERROR,
            }))
            return
        end

        local rep = gmd[cmd](data)
        response:write(200,nil,json.encode(rep or {
            errcode = error.SUCCESS
        }))
        response:close()
    end)
end)