local openssl = require "openssl"
require "functions"
local pkey = openssl.pkey

-- local rsakey = pkey.new('rsa',1024,3)

-- local kp = rsakey:parse()
-- dump(kp)
-- local tt = kp.rsa:parse()
-- dump(tt)
-- local k1 = pkey.get_public(rsakey)
-- local t = k1:parse ()
-- dump(t)
-- t = t.rsa:parse()
-- t.alg = 'rsa'
-- dump(t)
-- local r2 = pkey.new(t)
-- local msg = openssl.random(128-11)
-- local out = pkey.encrypt(r2,msg)
-- local raw = pkey.decrypt(rsakey,out)


local rsa = {}

function rsa.gen_key(t)
    if not t then
        return pkey.new('rsa',1024,3)
    end

    return pkey.new(t)
end

function rsa.public_key(k)
    return pkey.get_public(k)
end

function rsa.encrypt(kpub,data)
    return pkey.encrypt(kpub,data)
end

function rsa.decrypt(kpri,data)
    return pkey.decrypt(kpri,data)
end

function rsa.parse(k)
    local kp = k:parse()
    return kp.rsa:parse()
end

-- local kpri = rsa.parse(rsakey)
-- dump(kpri)

-- local crypt = require "client.crypt"
-- local base64kpri = crypt.base64encode(tostring(kpri.n))
-- dump(base64kpri)

return rsa