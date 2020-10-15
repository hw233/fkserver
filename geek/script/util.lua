local json = require "cjson"
local httpc = require "http.httpc"
local log = require "log"
local md5 = require "md5.core"
local crypt = require "skynet.crypt"

require "functions"

local util = {}

local function object2net(obj)
    local _,v = pcall(json.encode,obj)
    return v
end

function util.format_sync_info(type,id,obj)
    id.type = type
    return {
        id = object2net(id),
        data = object2net(obj),
    }
end

function util.http_get(url,params)
    if params then
        if string.sub(url,#url) ~= "?" then
            url = url .. "?"
        end

        local paramstrs = table.series(params,function(v,k)
            return string.format("%s=%s",string.urlencode(tostring(k)),string.urlencode(tostring(v))) 
        end)
        url = url .. table.concat(paramstrs,"&")
    end
    log.info("http.get,%s",url)
    local host,path = string.match(url,"([h|H][t|T][t|T][p|P][s|S]?://[^/]+)(.+)")
    return httpc.get(host,path)
end

function util.sha1(text)
	local c = crypt.sha1(text)
	return crypt.hexencode(c)
end

function util.hmac_sha1(key, text)
	local c = crypt.hmac_sha1(key, text)
	return crypt.hexencode(c)
end

function util.md5(s)
    return md5(s)
end

return util