local skynet = require "skynet"
local log = require "log"
local channel = require "channel"
local bootconf = require "conf.boot"
local cluster = require "cluster"
local callmod = require "callmod"
require "skynet.manager"

local string = string
local table = table
local tolower = string.lower
local strfmt = string.format
local tinsert = table.insert
local tunpack = table.unpack
local tconcat = table.concat

local cmdlines = {...}

local function cluster_name(conf)
    return conf.name .. "." .. conf.id
end

local function cluster_hostaddr(conf)
    return conf.port and conf.host .. ":" .. conf.port or conf.host
end

local function service_id(conf)
    return conf.name .. "." .. conf.id
end

local function setupbootservice()
    local bootnode = bootconf.node
    local name = cluster_name(bootnode)
    local addr = cluster_hostaddr(bootnode)
	channel.subscribe(service_id(bootconf.service),{
		provider = name,
		addr = addr,
	})
end


local function setup()
    setupbootservice()
    
    local clusterconfs = channel.call("config.?","msg","query_cluster_conf")
	
	local clusters = {}
	for _,c in pairs(clusterconfs) do
		clusters[cluster_name(c)] = cluster_hostaddr(c)
	end

	cluster.reload(clusters)
	
	local services = {}

	for cid in pairs(clusters) do
		local ok,cc = pcall(cluster.call,cid,"@channel","lua","query")
		if ok then
			for sid,sc in pairs(cc) do
				if type(sc.addr) == "number" then
					services[sid] = cid .. "@" .. sid
				else
					services[sid] = sc.addr
				end
			end
			break
		end
	end

    channel.subscribe(services)
end

local conf_handle = {
	reload = function()

	end,
	usage = function()
		local lines = {
			"control usage:",
			"reload sid: reload service config of sid from db",
		}
		print(tconcat(lines,"\n"))
	end,
}

skynet.start(function()
	local cmd = cmdlines[1]
	if not cmd then
		conf_handle.usage()
		skynet.abort()
		return
	end

	setup()

	local fn = conf_handle[tolower(cmd)] or conf_handle.usage
	if fn then
		fn()
	end

	skynet.abort()
end)