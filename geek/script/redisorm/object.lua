
local redisopt = require "redisopt"

local reddb = redisopt.default

local node_metatable = {
    __index = function(t,key)

    end,
    __newindex = function(t,key)

    end,
}

local hash_metatable = {
    __index = function(t,key)

    end,
}

local list_metatable = {
    __index = function(t,key)

    end,
}

local set_metatable = {
    __index = function(t,key)

    end,
}
local key_metatable = {
    __index = function(t,key)

    end,
}

local node_creator = {
    key = key_metatable,
    hash = hash_metatable,
    list = list_metatable,
    set = set_metatable,
}

local function create_node(meta,parent)
    return setmetatable({
            __parent = parent,
            __meta = meta,
        },
        node_creator[meta.type]
    )
end

local tree = {
    root = create_node()
}

setmetatable(tree,{
    __index = function(t,key)
        local next = string.gmatch(key,"[^%:|%.]+")
        local node = t.root
        for s in next() do
            local n = node[s]
            if not n then return end
            node = n
        end
        return node
    end,
    __newindex = function(t,key,type)
        local next = string.gmatch(key,"[^%:|%.]+")
        local node = t.root
        local s = next()
        local model = s
        while s do
            model = s
            local n = node[model]
            if not n then break end
            node = n
            s = next()
        end

        if not node then return end

        node[model] = type
    end
})

local db = setmetatable({},{
    __index = function(t,name)
        local o = setmetatable({
            __name = name
        },{
            __index = tree,
        })

        t[name] = o

        return o
    end
})

return db