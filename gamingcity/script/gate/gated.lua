
local skynet = require "skynet"

local loginservice,protocol = ...
loginservice = tonumber(loginservice)
skynet.setenv("conn.protocol",protocol)

local msgserver = require "gate.msgserver"
local netmsgopt = require "netmsgopt"
local datacenter = require "skynet.datacenter"
local log = require "log"



local server = {}
local onlineguid = {}
local onlinesession = {}
local logining = {}
local sms = {}
local sms_time_limit

local MSG = {}

function MSG.CS_RequestSms(fd,msg)
    local sms_session = sms[fd]
    sms_time_limit = sms_time_limit or datacenter.query("sms_limit_time")
    if sms_session and sms_session.last then
        if os.time() - sms_session.last >= sms_time_limit then
            log.info( "RequestSms in time [%d] session [%d]", os.time() - sms_session.last, fd )
            netmsgopt.send(fd,0,"SC_RequestSms",{
                result = LOGIN_RESULT_SMS_REPEATED,
            })
            return
        end
    end

    log.info( "RequestSms session [%d] =================", fd )
    if not msg.tel then
        log.error( "RequestSms session [%d] =================tel not find", fd)
        netmsgopt.send(fd,0,"SC_RequestSms",{
            result = LOGIN_RESULT_SMS_FAILED,
        })
        return true
    end

    local tel = msg.tel

    log.info( "RequestSms guid [%d] =================tel[%s] platform_id[%s]",  msg.tel, msg.platform_id)
    local tellen = string.len(tel)
    if tellen < 7 or tellen > 18 then
        netmsgopt.send(fd,0,"SC_RequestSms",{
            result = LOGIN_RESULT_TEL_LEN_ERR,
        })
        return true
    end

    local tel_head = string.sub(tel,0, 3)

    --170 171的不准绑定
    if tel_head == "170" or tel_head == "171" then
        netmsgopt.send(fd,0,"SC_RequestSms",{
            result = LOGIN_RESULT_TEL_ERR,
        } )
        return true
    end

    if tel_head == "999" then
        local sms_no =  string.sub(tel,tellen - 6)
        sms[fd] = {
            tel = tel,
            sms_no = sms_no,
            last = os.time(),
        }
        return true
    end

    if not string.find(tel,"^\\d+&")() then
        netmsgopt.send(fd,0,"SC_RequestSms",{
            result = LOGIN_RESULT_TEL_ERR,
        })
        return true
    end

    -- if msg.intention == 2 then
    --     auto session = GateSessionManager::instance().get_login_session()
    --     if session then
    --         msg.gate_session_id =  get_id
    --         msg.guid =  guid
    --         msg.gate_id( static_cast<GateServer*>(BaseServer::instance()).get_gate_id() )
    --         log.info( "gateid[%d] guid[%d] sessiong[%d]", static_cast<GateServer*>(BaseServer::instance()).get_gate_id(), get_guid(), get_id() )
    --         session.send_pb( &msg )
    --     else
    --         log.warning( "login server disconnect" )
    --     end
    -- else
        -- do_get_sms_http( msg.tel, msg.platform_id )
    -- end

	return true
end

function server.login(fd,guid,conf)
    local s = logining[fd]
    if not s then
        skynet.error(string.format(" %d logining,but connection is closed.",uid))
        return
    end

	-- you can use a pool to alloc new agent
	local agent = skynet.newservice("msgagent",skynet.self())
	local u = {
		agent = agent,
        guid = guid,
        fd = fd,
        addr = msgserver.ip(),
        conf = conf,
    }

	-- trash subid (no used)
	skynet.call(agent, "lua", "login", u)
    onlineguid[guid] = u
    onlinesession[fd] = u
    logining[fd] = nil

	msgserver.login(fd,guid,conf)
	return
end

function server.logout(guid)
	local u = onlineguid[guid]
	if u then
		msgserver.logout(guid)
		onlineguid[guid] = nil
		pcall(skynet.call,loginservice, "lua", "logout")
	end
end

function server.kickout(guid)
	local u = onlineguid[guid]
	if u then
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	end
end

function server.disconnect_handler(c)
    if c.fd then
        logining[c.fd] = nil
    end

	local u = onlineguid[c.guid]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

function server.login_failed(fd,msg)
    if not logining[fd] then 
        return
    end

    logining[fd] = nil
end

local function login_repeat(fd,guid)
    netmsgopt.send(fd,guid,"LC_Login",{
        result = LOGIN_RESULT_REPEAT_LOGIN,
    })
end

function server.request_handler(fd,msgstr)
    local s = onlinesession[fd]
    if not s then
        log.error("request without build session.",fd)
        return
    end

    local guid,msgid,msgbuf = netmsgopt.unpack(msgstr)
    if s.guid ~= guid then
        log.error("request with fake guid,guid:%d,fake guid:%d",s.guid,guid)
        return
    end

    local msgname = assert(netmsgopt.query(msgid)).msgname
    local msg = netmsgopt.decode(msgid,msgbuf)
    local u = onlineguid[guid]
    if u then
        skynet.send(u.agent,"client",msgname,msg)
        return
    end

    local f = MSG[msgname]
    if f then
        f(fd,msg)
        return
    end

    if not logining[fd] then
        logining[fd] = true
        skynet.send(loginservice,"client",fd,msgserver.ip(fd),msgname,msg)
    else
        login_repeat(fd,guid)
    end
end

skynet.init(function()
    skynet.call(loginservice,"lua","register_gate",skynet.self())
end)

msgserver.start(server)



