local nameservice = require "nameservice"

local servicepath = {
    [nameservice.TIDDB] = "db.main",
    [nameservice.TIDCONFIG] = "config.main",
    [nameservice.TIDLOGIN] = "login.main",
    [nameservice.TIDGM] = "gm.main",
    [nameservice.TIDGATE] = "gate.main",
    [nameservice.TIDGAME] = "game.main",
    [nameservice.TIDSTATISTICS] = "statistics.main",
    [nameservice.TIBROKER] = "broker.main",

    [nameservice.TNDB] = "db.main",
    [nameservice.TNCONFIG] = "config.main",
    [nameservice.TNLOGIN] = "login.main",
    [nameservice.TNGM] = "gm.main",
    [nameservice.TNGATE] = "gate.main",
    [nameservice.TNGAME] = "game.main",
    [nameservice.TNSTATISTICS] = "statistics.main",
    [nameservice.TNBROKER] = "broker.main",
}

return servicepath