
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

local h2b = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["a"] = 10,
    ["b"] = 11,
    ["c"] = 12,
    ["d"] = 13,
    ["e"] = 14,
    ["f"] = 15,
}

local function f_hex2bin( hexstr )
    local s = string.gsub(hexstr, "(.)(.)", function ( h, l )
         return string.char(h2b[h]*16+h2b[l])
    end)
    return s
end

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
    md5.crypt(s,appkey)
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

        local data = json.decode(body)
        if not data then
            response:write(404,nil,json.encode({
                errcode = error.DATA_ERROR,
            }))
        end

        if not check_sign_code(data) then
            response:write(404,nil,json.encode({
                errcode = error.SIGNATURE_ERROR,
            }))
            return
        end

        local rep = gmd[cmd](json.decode(body))
        response:write(200,nil,json.encode(rep or {errcode = error.SUCCESS}))
        response:close()
    end)
end)