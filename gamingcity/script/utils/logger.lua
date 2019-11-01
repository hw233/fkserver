
local skynet = require "skynet"

function log.info(format, ...)
    print(string.format("[INFO]      " .. format, ...))
end

function log_trace(format, ...)
    print(string.format("[TRACE]     " .. format, ...))
end

function log_debug(format, ...)
    print(string.format("[DEBUG]     " .. format, ...))
end

function log_assert(format,...)
    print(string.format("[ASSERT]     " .. format, ...))
end

function log.warning(format, ...)
    print(string.format("[WARNING]   " .. format, ...))
end

function log_exception(format, ...)
    print(string.format("[EXCEPTION] " .. format, ...))
end

function log.error(format, ...)
    print(string.format("[ERROR]     " .. format, ...))
end
