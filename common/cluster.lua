local skynet = require "skynet"

local clusterd
local cluster = {}
local sender = {}
local task_queue = {}

local function request_sender(q, node)
	local ok, c = pcall(skynet.call, clusterd, "lua", "sender", node)
	if not ok then
		skynet.error(c)
		c = nil
	end
	-- run tasks in queue
	local confirm = coroutine.running()
	q.confirm = confirm
	q.sender = c
	for _, task in ipairs(q) do
		if type(task) == "table" then
			if c then
				skynet.send(c, "lua", "push", table.unpack(task,1,task.n))
				-- skynet.send(c, "lua", "push", task[1], skynet.pack(table.unpack(task,2,task.n)))
			end
		else
			skynet.wakeup(task)
			skynet.wait(confirm)
		end
	end
	task_queue[node] = nil
	sender[node] = c
end

local function get_queue(t, node)
	local q = {}
	t[node] = q
	skynet.fork(request_sender, q, node)
	return q
end

setmetatable(task_queue, { __index = get_queue } )

local function get_sender(node)
	local s = sender[node]
	if not s then
		local q = task_queue[node]
		local task = coroutine.running()
		table.insert(q, task)
		skynet.wait(task)
		skynet.wakeup(q.confirm)
		return q.sender
	end
	return s
end

function cluster.call(node, address,proto, ...)
	-- skynet.pack(...) will free by cluster.core.packrequest
	return skynet.call(get_sender(node), "lua", "req",  address,proto, skynet.pack(...))
end
function cluster.rawcall(node, address, proto, msg,sz)
	return skynet.rawcall(get_sender(node), "lua", "req",  address,proto,msg,sz)
end

function cluster.send(node, address, proto, ...)
	local s = sender[node]
	if not s then
		table.insert(task_queue[node], table.pack(address,proto, skynet.pack(...)))
	else
		skynet.send(sender[node], "lua", "push", address,proto,skynet.pack(...))
	end
end

function cluster.rawsend(node, address, proto, msg,sz)
	local s = sender[node]
	if not s then
		table.insert(task_queue[node], table.pack(address,proto, msg,sz))
	else
		skynet.rawsend(sender[node], "lua", "push", address,proto,msg,sz)
	end
end

function cluster.open(port)
	if type(port) == "string" then
		skynet.call(clusterd, "lua", "listen", port)
	else
		skynet.call(clusterd, "lua", "listen", "0.0.0.0", port)
	end
end

function cluster.reload(config)
	skynet.call(clusterd, "lua", "reload", config)
end

function cluster.proxy(node, name)
	return skynet.call(clusterd, "lua", "proxy", node, name)
end

function cluster.snax(node, name, address)
	local snax = require "skynet.snax"
	if not address then
		address = cluster.call(node, ".service", "QUERY", "snaxd" , name)
	end
	local handle = skynet.call(clusterd, "lua", "proxy", node, address)
	return snax.bind(handle, name)
end

function cluster.register(name, addr)
	assert(type(name) == "string")
	assert(addr == nil or type(addr) == "number")
	return skynet.call(clusterd, "lua", "register", name, addr)
end

function cluster.query(node, name)
	return skynet.call(get_sender(node), "lua", "req", 0, skynet.pack(name))
end

skynet.init(function()
	clusterd = skynet.uniqueservice("service.clusterd")
end)

return cluster
