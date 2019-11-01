local boot = {
    node = {
        id = 1,
        name = "test",
        host = "127.0.0.1",
        port = 7791,
    },
    service = {
        id = 2,
        type = 2,
        name = "config",
        conf = {
            db = {
                name = "config",
                database = "config",
                host = "127.0.0.1",
                port = 3306,
                user = "root",
                password = "123456",
                pool = 8
            },
        },
    },
    enable_log = true,
}

return boot