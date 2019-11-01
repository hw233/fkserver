local skynet = require "skynet"

local utild

local util = {}

function util.rsa_decrypt(s)
    return skynet.call(utild,"lua","rsa_decrypt",s)
end

function util.get_rsa_public_key()
    return skynet.call(utild,"lua","get_rsa_public_key")
end

function util.request_sms(who)
    return skynet.call(utild,"lua","request_sms",who)
end

function util.verify_sms(who,telephone,sms)
    return skynet.call(utild,"lua","verify_sms",who,telephone,sms)
end

function util.geo_lookup(ip)
    return skynet.call(utild,"lua","query_geo",ip)
end

skynet.start(function()
    require "skynet.manager"

    utild = skynet.uniqueservice("gate.service.utild")
end)

return util