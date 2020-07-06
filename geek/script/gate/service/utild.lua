local skynet = require "skynet"
local httpc = require "http.httpc"
-- local rsa = require "rsa"
local datacenter = require "skynet.datacenter"
local mmdb = require "mmdb"
local log = require "log"
require "functions"

-- local rsa_pri_key = rsa.gen_key()
-- local rsa_public_key = rsa.public_key(rsa_pri_key)
local geodb
local geodb_path = "./geek/script/data/GeoLite2-City.mmdb"

local CMD = {}

function CMD.request_sms(guid_or_session)
    
end

function CMD.get_rsa_public_key()
    -- return rsa.parse(rsa_public_key).n
end

function CMD.rsa_decrypt(s)
    -- return rsa.decrypt(rsa_pri_key,s)
end

function CMD.request_sms(who)
    
end

function CMD.verify_sms(who,telephone,sms)

end

function CMD.geo_lookup(ip)
    if not geodb then
        geodb = mmdb.read(geodb_path)
    end
    local area = geodb:search_ipv4(ip)
    return area
end

skynet.start(function()
    geodb = mmdb.read(geodb_path)
    skynet.dispatch("lua",function(_,_,cmd,...) 
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            log.error("unknown cmd:%s in utild,",cmd)
            skynet.retpack(nil)
        end
    end)

    require "skynet.manager"

    local handle = skynet.localname ".utild"
    if handle then
        skynet.exit()
        return handle
    end

    skynet.register(".utild")
end)