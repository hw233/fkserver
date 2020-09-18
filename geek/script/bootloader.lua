local skynet = require "skynetproto"
require "functions"
require "skynet.manager"
local channel = require "channel"
local cluster = require "cluster"
local bootconf = require "conf.boot"
local nameservice = require "nameservice"
local log = require "log"


local clusterid = skynet.getenv("clusterid")
clusterid = tonumber(clusterid)


local servicepath = {
    [nameservice.TIDDB] = "db.main",
    [nameservice.TIDCONFIG] = "config.main",
    [nameservice.TIDLOGIN] = "login.main",
    [nameservice.TIDGM] = "gm.main",
    [nameservice.TIDGATE] = "gate.main",
    [nameservice.TIDGAME] = "game.main",
    [nameservice.TIDSTATISTICS] = "statistics.main",

    [nameservice.TNDB] = "db.main",
    [nameservice.TNCONFIG] = "config.main",
    [nameservice.TNLOGIN] = "login.main",
    [nameservice.TNGM] = "gm.main",
    [nameservice.TNGATE] = "gate.main",
    [nameservice.TNGAME] = "game.main",
    [nameservice.TNSTATISTICS] = "statistics.main",
}

local function isselfcluster(id)
    return clusterid == id
end

local function launchservice(conf)
    local serviceid = conf.name .. "." .. tostring(conf.id)
    local s = nameservice.new(serviceid,servicepath[conf.type or conf.name])
    skynet.call(s,"lua","start",conf)
    return serviceid,s
end

local function setupservice(clusterservice)
    if not clusterservice then
        log.error("cluster service is nil with cluster id %d,please check config in database.")
        return
    end

    for _,cs in pairs(clusterservice) do
        if cs.cluster == clusterid and cs.is_launch ~= 0 and cs.id ~= bootconf.service.id then
            local id,service = launchservice(cs)
            channel.subscribe("service."..tostring(cs.id),service)
        end
    end
end

local function setupcluster(clusterconfs)
    local selfname = nil

    local clusters = {}
    for _,c in pairs(clusterconfs) do
        local clustername = c.name .. "." .. tostring(c.id)
        if isselfcluster(c.id) then
            selfname = c.name .. "." .. tostring(c.id)
        end

        if c.is_launch then
            local host = c.port and c.host .. ":" .. tostring(c.port) or c.host
            clusters[clustername] = host
        end
    end

    cluster.reload(clusters)

    if bootconf.node.id == clusterid then
        return
    end

    channel.localprovider(selfname)
    cluster.open(selfname)
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
    local bootnodename = bootnode.name .. "." .. tostring(bootnode.id)
    log.info("boot cluster name: %s",bootnodename)
    cluster.reload({
        [bootnodename] = string.format("%s:%d",bootnode.host,bootnode.port),
    })

    if bootnode.id ~= clusterid then
        local boostseriveid = "config."..tostring(bootconf.service.id)
        channel.subscribe(boostseriveid,bootnodename.."@"..boostseriveid)
        return
    end

    channel.localprovider(bootnodename)
    cluster.open(bootnodename)
    local sid,handle = launchservice(bootconf.service)
    return sid,handle
end


local function setup()
    setupbootcluster()
    checkbootconf()

    local serviceconfs = channel.call(bootconf.service.name..".?","msg","query_service_conf")
    setupservice(serviceconfs)

    local clusterconfs = channel.call("config.?","msg","query_cluster_conf")
    setupcluster(clusterconfs)

    for _,conf in pairs(serviceconfs) do
        local clusterconf = clusterconfs[conf.cluster]
        if conf.cluster ~= clusterid and clusterconf then
                local cid = clusterconf.name.."."..clusterconf.id
                local serviceid = conf.name.."."..conf.id
                channel.subscribe(serviceid,cid.."@"..serviceid)
                channel.subscribe("service."..conf.id,cid.."@"..serviceid)
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
end)
