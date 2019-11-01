local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local dbopt = require "dbopt"
local netmsgopt = require "netmsgopt"
require "functions"
local log = require "log"

local connection = {}
local connection_id = {}

local session = {}

function session.on_accept(fd,msg)
    connection[fd] = true
    socketdriver.start(fd)
end

function session.on_connect(fd,conf)
    connection[fd] = conf
    connection_id[conf.type][conf.id] = conf
    socketdriver.start(fd)
end

function session.on_disconnect(fd)
    local c = connection[fd]
    if not c then
        return
    end

    local id = c.id
    local type = c.type

    if connection_id[type] then
        connection_id[type][id] = nil
    end

    connection[fd] = nil

    if c.type == SessionGate then
        dbopt.config:query("UPDATE t_game_server_cfg SET is_start = 0 WHERE game_id = %d;", c.server_id)
    end

    socketdriver.close(fd)
end

function session.on_c_connect(fd,s)
    local c = connection[fd]
    if not c then 
        return false
    end

    s.fd = fd
    connection[fd] = s
    connection_id[s.type][s.server_id] = s
    return true
end

function session.on_s_connect(fd,s)
    local c = connection[fd]
    if not c then
        return
    end

    if s.type == SessionGate then
        dbopt.config:query("UPDATE t_game_server_cfg SET is_start = 1 WHERE game_id = %d;", msg.server_id)
    end

    s.fd = fd
    connection[fd] = s
    connection_id[s.type][s.server_id] = s
end

function session.byfd(fd)
    if not fd or not connection[fd] then return nil end

    return connection[fd].id
end

function session.byid(tp,id)
    if not tp or not connection_id[tp] then return nil end
    if not id then return connection_id[tp] end
    return connection_id[tp][id]
end

function session.sendpb(fd,msgname,msg)
    socketdriver.send(fd,msgopt.pack_pb(msgname,msg))
end

function session.sendpb2id(tp,id,msgname,msg)
    if not connection_id[tp] then 
        log.warning(".......")
        return
    end

    if id then
        if not connection_id[tp][id] then
            log.warning(".......")
            return
        end

        socketdriver.send(connection[tp][id].fd,netmsgopt.pack(msgname,msg))
        return
    end

    for _,session in pairs(connection_id[tp]) do
        socketdriver.send(session.fd,netmsgopt.pack(msgname,msg))
    end
end

function session.sendpb2any(tp,msgname,msg)
    if not connection_id[tp] then 
        log.warning("......")
        return
    end

    socketdriver.send(table.choice(connection[tp]).fd,pack.pack(msgname,msg))
end

function session.broadcast2type(tp,msgname,msg)
    sendpb2id(tp,nil,msgname,msg)
end

broadcastpb2type = function() end
sendpb2any = function() end
sendpb2id = function() end
sendpb = function() end

netmsgopt.register("S_Connect",session.on_s_connect)

return session
