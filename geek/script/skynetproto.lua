local skynet = require "skynet"

skynet.PTYPE_MSG = 13
skynet.PTYPE_CONTROL = 14
skynet.PTYPE_PROXY = 15

skynet.register_protocol {
    id = skynet.PTYPE_MSG,
    name = "msg",
    pack = skynet.pack,
    unpack = skynet.unpack,
}

skynet.register_protocol {
    id = skynet.PTYPE_CONTROL,
    name = "control",
    pack = skynet.pack,
    unpack = skynet.unpack,
}

skynet.register_protocol {
    id = skynet.PTYPE_PROXY,
    name = "forward",
    pack = skynet.pack,
    unpack = skynet.unpack,
}

return skynet