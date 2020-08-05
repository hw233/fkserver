
local json = require "cjson"
local log = require "log"

local function default(v)
    return v
end


local typemetafunc = {
    string = {
        encode = function(v) return tostring(v) end,
        decode = function(v) return tostring(v) end,
    },
    number = {
        encode = function(v) return tonumber(v) end,
        decode = function(v) return tonumber(v) end,
    },
    json = {
        encode = function(v)
            return type(v) == "table" and json.encode(v) or v 
        end,
        decode = function(v) 
            return type(v) == "string" and json.decode(v) or v
        end,
    },
    bool = {
        encode = function(v)
            return v and "true" or "false"
        end,
        decode = function(v)
            return (v and v == "true") and true or false
        end,
    },
    hash = {
        decode = function(val,n)
            return table.map(val,function(v,k)
                local nk = n[k]
                local meta = rawget(nk,"meta")
                if meta then
                    v = meta.decode(v)
                end
                return k,v
            end)
        end,
        encode = function(val,n)
            return table.map(val,function(v,k)
                local nk = n[k]
                local meta = rawget(nk,"meta")
                return k,meta and meta.encode(v) or v
            end)
        end
    },
    number_hash = {
        decode = function(val,n)
            return table.map(val,function(v,k)
                local nk = n[k]
                local meta = rawget(nk,"meta")
                if meta then
                    v = meta.decode(v)
                end
                return tonumber(k),v
            end)
        end,
        encode = function(val,n)
            return table.map(val,function(v,k)
                local nk = n[k]
                local meta = rawget(nk,"meta")
                return k,meta and meta.encode(v) or v
            end)
        end
    },
    set = {
        decode = function(val,n)
            return table.map(val,function(v)
                local nk = n[v]
                local meta = rawget(nk,"meta")
                return meta and meta.encode(v) or v,true
            end)
        end,
        encode = function(val)
            return table.keys(val)
        end
    },
    list = {
        encode = function(val,n)
            return table.map(val,function(v,k)
                local nk = n[k]
                local meta = rawget(nk,"meta")
                return k,meta and meta.encode(v) or v
            end)
        end,
        decode = function(val,n)
            return table.map(val,function(v,k)
                local nk = n[k]
                local meta = rawget(nk,"meta")
                return k,meta and meta.decode(v) or v
            end)
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

local model_meta = {
    number = typemetafunc.number,
    string = typemetafunc.string,
    json = typemetafunc.json,
    bool = typemetafunc.bool,
    hash = typemetafunc.hash,
    set = typemetafunc.set,
    key = typemetafunc.key,
    list = typemetafunc.list,
    number_hash = typemetafunc.number_hash,
}

local model_son_metatable = {
    __index = function(son,s)
        for model,node in pairs(son) do
            if tostring(s):match("^"..model.."$") then
                return node
            end
        end

        return nil
    end,
    __newindex = function(son,model,node)
        rawset(son,model,node)
    end
}

local function create_model_son()
    return setmetatable({},model_son_metatable)
end

local model_node = {}

local function set_model_meta(n,model,metatypes)
    local mn = n[model]
    if type(metatypes) == "table" then
        for son_model,son_metatype in pairs(metatypes) do
            local meta = model_meta[son_metatype]
            assert(meta)
            local nson = mn[son_model]
            rawset(nson,"meta",meta)
        end
        return
    end

    local meta = model_meta[metatypes]
    assert(meta)
    rawset(mn,"meta",meta)
end

local function get_son_model_node(n,s)
    if not s then
        return
    end

    local son_node
    if not rawget(n,"__son") then
        rawset(n,"__son",create_model_son())
        son_node = model_node.create(nil,n)
        n.__son[s] = son_node
        return son_node
    end

    son_node = n.__son[s]
    if not son_node then
        son_node = model_node.create(nil,n)
        n.__son[s] = son_node
    end

    return son_node
end

local function create_model_node(meta,parent)
    return setmetatable({
        __son = nil,
        meta = meta,
        __parent = parent,
    },{
        __index = get_son_model_node,
        __newindex = set_model_meta,
    })
end

model_node.create = create_model_node

local root = model_node.create()

return root