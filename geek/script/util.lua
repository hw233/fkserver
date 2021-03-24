local json = require "json"
local httpc = require "http.httpc"
local log = require "log"
local md5 = require "md5.core"
local crypt = require "skynet.crypt"
local channel = require "channel"
local url = require "url"
local serviceconf = require "serviceconf"

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

function util.request_share_params(sid)
    if not sid or sid == "" then 
        return
    end

    local ok
    ok,sid = pcall(function() 
        return crypt.base64decode(url.unescape(sid))
    end)

    if not ok then
        return
    end

    local sharerance = channel.call("db.?","msg","SD_RequestShareParam",sid)
    log.dump(sharerance)
    if not sharerance or not sharerance.param or sharerance.param == "" then 
        return
    end

    local _,param = pcall(json.decode,sharerance.param)
    return param
end

function util.alive_game_ids()
    return table.series(channel.query(),function(_,item)
		local id = string.match(item,"game.(%d+)")
		if not id then return end
		id = tonumber(id)
		local sconf = serviceconf[id]
		if not sconf.conf or not sconf.conf.private_conf then return end
		return sconf.conf.first_game_type
	end)
end

function util.timestamp_date(time)
    local d = os.date("*t",time or os.time())
    return os.time({
        year = d.year,
        month = d.month,
        day = d.day,
        hour = 0,
        min = 0,
        sec = 0,
    })
end

function util.day_seconds()
    return 24 * 60 * 60
end

return util