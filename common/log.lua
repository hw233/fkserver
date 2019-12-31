
local skynet = require "skynet"

local print = print

local debuglayer = 3
local function debuginfo()
    return debug.getinfo(debuglayer)
end

local function strtime()
    local time = skynet.time()
    local ms = math.ceil((time % 1) * 1000)
    return string.format("[%s.%03d]",os.date("%Y-%m-%d %H:%M:%S",math.floor(time)),ms)
end

local log = {}

function log.info(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"INFO",...) .. string.format("(%s:%d)",d.short_src,d.currentline)

    print(s)
end

function log.trace(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"TRACE",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    print(s)
end

function log.debug(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"DEBUG",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    print(s)
end

function log.assert(fmt,...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"ASSERT",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    print(s)
end

function log.warning(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"WARNING",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    print("\27[33m"..s.."\27[0m")
end

function log.exception(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"EXCEPTION",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    print("\27[31m"..s.."\27[0m")
end

function log.error(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"ERROR",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    print("\27[31m"..s.."\27[0m")
end

return log