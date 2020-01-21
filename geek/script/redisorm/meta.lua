
local json = require "cjson"
local log = require "log"

local function default(v)
    return v
end

local typemetafunc = {
    string = {
        encode = tostring,
        decode = tostring,
    },
    number = {
        encode = tonumber,
        decode = tonumber,
    },
    json = {
        encode = json.encode,
        decode = json.decode,
    },
    boolean = {
        encode = function(v)
            return (v and v == true) and "true" or "false"
        end,
        decode = function(v)
            return (v and v == "true") and true or false
        end,
    },
}

setmetatable(typemetafunc,{
    __index = function(t,k)
        local c = {
            encode = default,
            decode = default,
        }
        t[k] = c
        return c
    end,
})

local field = {}

function field:create(type)
    local o = {
        conv = typemetafunc[type],
        type = type,
    }

    setmetatable(o,{__index = field})

    return o
end

function field:encode(v)
    return self.conv.encode(v)
end

function field:decode(v)
    return self.conv.decode(v)
end

local unkown_field = {}

function unkown_field:decode(v)
    return v
end

function unkown_field:encode(v)
    return v
end

local redismeta = {}

function redismeta:create(conf)
    local fields = conf.fields

    local meta = {}
    for k,m in pairs(fields) do
        meta[k] = field:create(m)
    end

    setmetatable(meta,{
        __index = function(t,k)
            t[k] = unkown_field
            return unkown_field
        end,
    })

    local metadata = setmetatable({
        meta = meta,
        name = conf.name,
        primary = conf.primary,
        index = conf.index_fields,
    },{
        __index = redismeta,
    })

    return metadata
end

function redismeta:key(id)
    return self.name..":"..tostring(id)
end

function redismeta:decode(field,v)
    local t = type(field)
    if t == "string" then
        return self.meta[field]:decode(v)
    end

    if t == "table" then
        for k,v in pairs(field) do
            field[k] = self.meta[k]:decode(v)
        end
        return field
    end

    return v
end

function redismeta:encode(field,v)
    local t = type(field)
    if t == "string" then
        return self.meta[field]:encode(v)
    end

    if t == "table" then
        for k,v in pairs(field) do
            field[k] = self.meta[k]:encode(v)
        end
        return field
    end

    return v
end

function redismeta:check(field,value)
    local t = type(value)
    if t == "number" or t == "boolean" then
        return self.meta[field].type == t
    end
    
    return self.meta[field].type == "json" and t == "string"
end


return redismeta