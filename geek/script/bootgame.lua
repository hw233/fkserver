local skynet = require "skynetproto"
require "functions"
require "skynet.manager"
local channel = require "channel"
local cluster = require "cluster"
local bootconf = require "conf.boot"
local nameservice = require "nameservice"
local log = require "log"

local clusterid,debug = ...
clusterid = tonumber(clusterid)

local servicepath = {
    [nameservice.TIDDB] = "db.main",
    [nameservice.TIDCONFIG] = "config.main",
    [nameservice.TIDLOGIN] = "login.main",
    [nameservice.TIDGM] = "gm.main",
    [nameservice.TIDGATE] = "gate.main",
    [nameservice.TIDGAME] = "game.main",
    [nameservice.TIDSTATISTICS] = "statistics.main",
    [nameservice.TIBROKER] = "broker.main",
    [nameservice.TIQUEUE] = "queue.main",
    [nameservice.TIMUTEX] = "mutex.main",
    [nameservice.TNINIT] = "init.main",

    [nameservice.TNDB] = "db.main",
    [nameservice.TNCONFIG] = "config.main",
    [nameservice.TNLOGIN] = "login.main",
    [nameservice.TNGM] = "gm.main",
    [nameservice.TNGATE] = "gate.main",
    [nameservice.TNGAME] = "game.main",
    [nameservice.TNSTATISTICS] = "statistics.main",
    [nameservice.TNBROKER] = "broker.main",
    [nameservice.TNQUEUE] = "queue.main",
    [nameservice.TNMUTEX] = "mutex.main",
    [nameservice.TIINIT] = "init.main",
}

local function cluster_name(conf)
    return conf.name .. "." .. conf.id
end

local function cluster_hostaddr(conf)
    return conf.port and conf.host .. ":" .. conf.port or conf.host
end

local function service_id(conf)
    return conf.name .. "." .. conf.id
end

local function is_selfcluster(id)
    return clusterid == id
end

local function is_bootcluster()
    return bootconf.node.id == clusterid
end

local function launchservice(conf)
    if not servicepath[conf.type or conf.name] then
        log.warning("unsupport service %s",conf.name)
        return
    end
    local id = conf.name .. "." .. tostring(conf.id)
    local servicename = servicepath[conf.type] or servicepath[conf.name]
    local ok,handle = pcall(skynet.newservice,servicename,conf.id)
    if not ok then return end
    log.info("new service,id:%s,handle:%s",id,handle)
    skynet.call(handle,"lua","start",conf)
    return id,handle
end

local function setupservice(clusterservice)
    if not clusterservice then
        log.error("cluster service is nil with cluster id %d,please check config in database.")
        return
    end

    local services = {}

    for _,cs in pairs(clusterservice) do
        if cs.cluster == clusterid and cs.is_launch ~= 0 and cs.id ~= bootconf.service.id then
            local id,handle = launchservice(cs)
            if id and handle then
                services[id] = handle
                services["service."..tostring(cs.id)] = handle
            end
        end
    end

    channel.subscribe(services)

    return services
end

local function setupcluster(clusterconfs)
    for _,c in pairs(clusterconfs) do
        if is_selfcluster(c.id) then
            local name = cluster_name(c)
            local hostaddr = cluster_hostaddr(c)

            cluster.reload({
                [name] = hostaddr,
            })

            cluster.open(name)

            channel.localprovider({
                name = name,
                addr = hostaddr,
                id = c.id,
            })

            return name,hostaddr
        end
    end
end

local function getlocalips()
    local ips = {}
    local file = io.popen("ifconfig")
    io.input(file)
    for l in io.lines() do
        local s = l:match("inet%s+(%d+%.%d+%.%d+%.%d+)")
        if s then ips[s] = true end
    end
    io.close(file)
    
    return ips
end

local function checkbootconf()
    local localips = getlocalips()
    local bootnodeconf = bootconf.node
    local clusterconf = channel.call("config.?","msg","query_cluster_conf",bootconf.node.id)
    assert(clusterconf,"boot cluster conf is not exists")
    assert(clusterconf.name == bootnodeconf.name,
        string.format("boot cluster name does not match. %s ~= %s",clusterconf.name,bootnodeconf.name))
    assert(clusterconf.host == "0.0.0.0" or localips[clusterconf.host] == localips[bootnodeconf.host],
        string.format("boot cluster host does not match. %s ~= %s",clusterconf.host,bootnodeconf.host))
    assert(clusterconf.port == bootnodeconf.port,
        string.format("boot cluster port does not match. %d ~= %s",clusterconf.port,bootnodeconf.port))
    
    local bootserviceconf = bootconf.service
    local serviceconf = channel.call("config.?","msg","query_service_conf",bootconf.service.id)
    assert(serviceconf,"boot service conf is not exists")
    assert(serviceconf.name == bootserviceconf.name,
        string.format("boot service name does not match. %s ~= %s",serviceconf.name,bootserviceconf.name))
    assert(serviceconf.type == bootserviceconf.type,
        string.format("boot service type does not match. %s ~= %s",serviceconf.type,bootserviceconf.type))
end


local function setupbootcluster()
    local bootnode = bootconf.node
    local name = cluster_name(bootnode)
    local addr = cluster_hostaddr(bootnode)
    log.info("boot cluster name: %s %s",name,addr)
    if bootnode.id ~= clusterid then
        channel.subscribe(service_id(bootconf.service),{
            provider = name,
            addr = addr,
        })
        return
    end

    local sid,handle = launchservice(bootconf.service)
    channel.subscribe(sid,handle)
end

local function cluster_services(serviceconfs,c_conf)
    local services = {}
    for _,conf in pairs(serviceconfs) do
        if not is_selfcluster(conf.cluster) and c_conf and c_conf.is_launch ~= 0 and conf.is_launch ~= 0 then
            local c_id = cluster_name(c_conf)
            local c_hostaddr = cluster_hostaddr(c_conf)
            local handle = {
                provider = c_id,
                addr = c_hostaddr,
            }
            services[conf.name.."."..conf.id] = handle
            services["service."..conf.id] = handle
        end
    end
    return services
end

local function setupintiservice(serviceconfs)
    local ss = channel.list()
    if ss and table.nums(ss) ~= 0 and table.Or(ss,function (_,name)
        return string.match(name,"init.%d") and true or false
    end) then
        return
    end
    local id,handle,conf
    for _,s in pairs(serviceconfs) do
        if s.type == nameservice.TIINIT and s.name ==  nameservice.TNINIT  and 
            s.is_launch ~= 0 and s.cluster == clusterid 
        then
            id,handle = launchservice(s)
            assert(id)
            assert(handle)
            conf = s
            break
        end
    end

    channel.subscribe(id,handle)
    return id,conf
end 
local function setup()
    setupbootcluster()
    checkbootconf()

    local clusterconfs = table.map(
        channel.call("config.?","msg","query_cluster_conf"),
        function(c)  return c.id,c end
    )
    local localname,localaddr = setupcluster(clusterconfs)
    local clusters = table.map(clusterconfs,function(c) 
        return cluster_name(c),cluster_hostaddr(c)
    end)
    cluster.reload(clusters)
    channel.load_service(clusters)

    local serviceconfs = table.map(
        channel.call(bootconf.service.name..".?","msg","query_service_conf"),
        function(c) return c.id,c end
    )

    local init_sid,init_conf  = setupintiservice(serviceconfs)
    if init_conf then serviceconfs[init_conf.id] = nil end
    local localservices = setupservice(serviceconfs)
    local localprovider = {provider = localname, addr = localaddr,}
    localservices = table.map(localservices,function(_,sid)
        return sid,localprovider
    end)

    if init_sid then
        localservices[init_sid] = localprovider
        localservices['service.'..init_conf.id] = localprovider
    end

    for _,conf in pairs(clusterconfs) do
        if conf.is_launch ~= 0 and not is_selfcluster(conf.id) then
            channel.subscribe(localservices,cluster_name(conf))
        end
    end
end

skynet.start(function()
    assert(bootconf.node)
    assert(bootconf.service)
    assert(bootconf.node.id)
    assert(bootconf.service.id)
    assert(bootconf.service.name)
    assert(bootconf.service.conf)

    setup()

    -- if debug == nil or debug == "debug" then
    --     skynet.newservice("debug_console", 8008)
    -- end

    skynet.exit()
end)
