
local skynet = require "skynet"
require "functions"
local chronos = require "chronos"


local print = print
local SERVICE_NAME = SERVICE_NAME
local logd = ".logd"
local debuglayer = 3

local bootconf = require "conf.boot"
local stdout_enable = bootconf.stdout_log

local function debuginfo()
    return debug.getinfo(debuglayer)
end

local function traceback()
    return debug.traceback(nil,debuglayer)
end

local function strtime()
    local time = chronos.nanotime()
    local ms = math.ceil((time % 1) * 1000)
    return string.format("[%s.%03d]",os.date("%Y-%m-%d %H:%M:%S",math.floor(time)),ms)
end

local level_fmts = {
    ["ERROR"] = "\27[31m%s\27[0m",
    ["WARNING"] = "\27[33m%s\27[0m",
}

local function log_out(s,level)
    skynet.send(logd, "lua",LOG_NAME or SERVICE_NAME,s)

    if not stdout_enable then
        return
    end

    local level_fmt = level and level_fmts[level] or nil
    if level_fmt then 
        print(string.format(level_fmt,s)) 
        return
    end

    print(s)
end

local log = {}

function log.info(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"INFO",...) .. string.format("(%s:%d)",d.short_src,d.currentline)

    log_out(s)
end

function log.trace(fmt, ...)
    local s = string.format("%s %-8s"..fmt,strtime(),"TRACE",...) .. "\n" .. traceback()
    log_out(s)
end

function log.debug(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"DEBUG",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    log_out(s)
end

function log.assert(fmt,...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"ASSERT",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    log_out(s)
end

function log.warning(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"WARNING",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    log_out(s,"WARNING")
end

function log.exception(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"EXCEPTION",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    log_out(s,"ERROR")
end

function log.error(fmt, ...)
    local d = debuginfo()
    local s = string.format("%s %-8s"..fmt,strtime(),"ERROR",...) .. string.format("(%s:%d)",d.short_src,d.currentline)
    log_out(s,"ERROR")
end

local function log_dump(value,description,nesting)
    if type(nesting) ~= "number" then nesting = 4 end

    local lookupTable = {}
    local result = {}

    local function dump_value_(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end
    
    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, description, "- ", 1)

    return table.concat(result,"\n")
end

function log.dump(value,description,nesting)
    local str = log_dump(value,description,nesting)
    local d = debuginfo()
    local s = string.format("%s %-8s",strtime(),"DUMP") .. string.format("(%s:%d)",d.short_src,d.currentline)
    log_out(s .. "\n" .. str)
end

skynet.init(function()
	logd = skynet.uniqueservice("logd")
end)

return log