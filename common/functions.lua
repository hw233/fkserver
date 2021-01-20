--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function dump(value,nesting,desciption)
    if type(nesting) ~= "number" then nesting = 5 end

    local lookupTable = {}
    local result = {}
    
    local dinfo = debug.getinfo(2)
    print(string.format("dump from: %s:%d",dinfo.short_src,dinfo.currentline))

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
    dump_(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

function checknumber(value, base)
    return tonumber(value, base) or 0
end

function checkint(value)
    return math.round(checknumber(value))
end

function checkbool(value)
    return (value ~= nil and value ~= false)
end

function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end

local setmetatableindex_
setmetatableindex_ = function(t, index)
    local mt = getmetatable(t)
    if not mt then mt = {} end
    if not mt.__index then
        mt.__index = index
        setmetatable(t, mt)
    elseif mt.__index ~= index then
        setmetatableindex_(mt, index)
    end
end
setmetatableindex = setmetatableindex_

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(object)
end

function class(classname, ...)
    local cls = {__cname = classname}

    local supers = {...}
    for _, super in ipairs(supers) do
        local superType = type(super)
        assert(superType == "nil" or superType == "table" or superType == "function",
            string.format("class() - create class \"%s\" with invalid super class type \"%s\"",
                classname, superType))

        if superType == "function" then
            assert(cls.__create == nil,
                string.format("class() - create class \"%s\" with more than one creating function",
                    classname));
            -- if super is function, set it to __create
            cls.__create = super
        elseif superType == "table" then
            if super[".isclass"] then
                -- super is native class
                assert(cls.__create == nil,
                    string.format("class() - create class \"%s\" with more than one creating function or native class",
                        classname));
                cls.__create = function() return super:create() end
            else
                -- super is pure lua class
                cls.__supers = cls.__supers or {}
                cls.__supers[#cls.__supers + 1] = super
                if not cls.super then
                    -- set first super pure lua class as class.super
                    cls.super = super
                end
            end
        else
            error(string.format("class() - create class \"%s\" with invalid super type",
                        classname), 0)
        end
    end

    cls.__index = cls
    if not cls.__supers or #cls.__supers == 1 then
        setmetatable(cls, {__index = cls.super})
    else
        setmetatable(cls, {__index = function(_, key)
            local supers = cls.__supers
            for i = 1, #supers do
                local super = supers[i]
                if super[key] then return super[key] end
            end
        end})
    end

    if not cls.ctor then
        -- add default constructor
        cls.ctor = function() end
    end
    cls.new = function(...)
        local instance
        if cls.__create then
            instance = cls.__create(...)
        else
            instance = {}
        end
        setmetatableindex(instance, cls)
        instance.class = cls
        instance:ctor(...)
        return instance
    end
    cls.create = function(_, ...)
        return cls.new(...)
    end

    return cls
end

function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n,v = debug.getlocal(3, 1)
                currentModuleName = v
            end

            currentModuleNameParts = string.split(currentModuleName, "[^%.]+")
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end

    return require(moduleFullName)
end

function math.newrandomseed()
    local ok, socket = pcall(function()
        return require("socket")
    end)

    if ok then
        math.randomseed(socket.gettime() * 1000)
    else
        math.randomseed(os.time())
    end
    math.random()
    math.random()
    math.random()
    math.random()
end

math.newrandomseed()

function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end

local pi_div_180 = math.pi / 180
function math.angle2radian(angle)
    return angle * pi_div_180
end

local pi_mul_180 = math.pi * 180
function math.radian2angle(radian)
    return radian / pi_mul_180
end

function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

function io.readfile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

function io.filesize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end


function table.nums(t)
    local count = 0
    for _,_ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

table.count = table.nums

function table.series(tb,fn)
    local s = {}
    for k,v in pairs(tb or {}) do
        if fn then
            local tmp = fn(v,k)
            if tmp ~= nil then table.insert(s,tmp) end
        else
            table.insert(s,v)
        end
    end

    return s
end

function table.keys(tb)
    local keys = {}
    for k, _ in pairs(tb or {}) do
        table.insert(keys,k)
    end
    return keys
end

function table.values(tb)
    local values = {}
    for _, v in pairs(tb) do
        values[#values + 1] = v
    end
    return values
end

function table.merge(dest,src,agg)
    local ret = clone(dest or {})

    for k,v in pairs(src or {}) do
        ret[k] = agg and agg(dest[k],v) or v
    end

    return ret
end

function table.merge_x(src,fn,dest)
    local ret = clone(dest or {})

    for k,v in pairs(src or {}) do
        ret[k] = fn and fn(dest[k],v) or v
    end

    return ret
end

function table.mergeto(dest, src, agg)
    dest = dest or {}
    for k, v in pairs(src or {}) do
        dest[k] = agg and agg(dest[k],v) or v
    end
    return dest
end

function table.mergeto_x(src,fn,dest)
    dest = dest or {}
    for k, v in pairs(src or {}) do
        dest[k] = fn and fn(dest[k],v) or v
    end
    return dest
end

function table.merge_tables(tbs,agg)
    local r
    for _,tb in pairs(tbs or {}) do
        if not r then 
            r = clone(tb)
        else 
            table.mergeto(r,tb,agg) 
        end
    end
    return r or {}
end

function table.insertto(dest, src, begin)
    begin = checkint(begin)
    if (not begin) or begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        local v = array[i]
        local is = type(value) == "function" and value(v,i) or value == v
        if is then return i end
    end
    return false
end

function table.keyof(hashtable, value)
    for k, v in pairs(hashtable or {}) do
        local is = type(value) == "function" and value(v,k) or value == v
        if is then return k end
    end
    return nil
end

function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function table.map(t,fn)
    if not t or not fn then return {} end

    local ret = {}
    for k,v in pairs(t or {}) do
        local k1,v1 = fn(v,k)
        if k1 then ret[k1] = v1 end
    end

    return ret
end

table.pick = table.map

function table.ref_map(t, fn)
    for k, v in pairs(t or {}) do
        t[k] = fn(v, k)
    end
end

function table.group(t,fn)
    local g = {}
    for k,v in pairs(t or {}) do
        local x = fn(v,k)
        g[x] = g[x]  or {}
        g[x][k] = v
    end
    return g
end

function table.walk(t, fn,on)
    for k,v in pairs(t or {}) do
        if not on or on(v,k) then fn(v, k) end
    end
end

function table.filter(t, fn)
    for k, v in pairs(t or {}) do
        if fn and not fn(v, k) then t[k] = nil end
    end
end

function table.select(t,fn,serial)
    local tb = {}

    for k,v in pairs(t or {}) do
        local v = (fn and fn(v,k)) and v  or nil
        if serial then
            if v then table.insert(tb,v) end
        else
            tb[k] = v
        end 
    end

    return tb
end

function table.unique_value(t)
    if not t then return {} end

    local check = {}
    local n = {}
    for k, v in pairs(t) do
        if not check[v] then
            n[k] = v
            check[v] = true
        end
    end
    return n
end

function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

function table.choice(t)
    assert(type(t) == "table")
    local len = table.nums(t)
    if len == 0 then
        return nil
    end
    local i = math.random(len)
    local index = 1
    for k,v in pairs(t) do
        if index == i then
            return k,v
        end

        index = index + 1
    end
    return nil
end

function table.merge_back(dst,tb,func)
    for _,v in pairs(tb or {}) do 
        table.insert(dst,(func and func(v) or v))
    end
	return dst
end

function table.push_back(dst,v)
	table.insert(dst,v)
end

function table.union(dst,src,agg)
    dst = dst or {}

    local tb = {}
    for k,v in pairs(dst or {}) do
        table.insert(tb,agg and agg(v,k) or v)
    end

    for k,v in pairs(src or {}) do
        table.insert(tb,agg and agg(v,k) or v)
    end
    return tb
end

function table.unionto(dst,src,agg)
    dst = dst or {}

    for k,v in pairs(src or {}) do
        table.insert(dst,agg and agg(v,k) or v)
    end

    return dst
end

function table.union_tables(tbs,agg)
    local t = {}

    for _,tb in pairs(tbs or {}) do
            table.unionto(t,tb,agg)
    end

    return t
end

function table.pop_back(tb)
	local ret = tb[#tb]
	table.remove(tb)
	return ret
end

function table.slice(tb,head,trail)
    if not trail then trail = #tb end
	if head > trail then return nil end
    if head == trail then return tb[head] end
    
	local vals = {}
	for i = head,trail do table.insert(vals,tb[i]) end
	return vals
end

function table.incr(tb,key,v)
    tb[key] = tb[key] or 0
    local value = tb[key] + (v or 1)
	tb[key] = value
	return value
end

function table.decr(tb,key,v)
    tb[key] = tb[key] or 0
    local value = tb[key] - (v or 1)
	tb[key] = value
	return value
end

function table.fill(tb,value,head,trail)
	head	= head or 1
	trail	= trail or head
    tb		= tb or {}
	for i = head,trail do tb[i] = value end
	return tb
end

function table.sum(tb,agg)
    local value = 0
    for k,v in pairs(tb or {}) do
        value = value + (agg and agg(v,k) or tonumber(v))
    end

    return value
end

function table.min(tb,agg)
    local mini,minv
    for i,v in pairs(tb or {}) do
        local aggv = agg and agg(v,i) or v
        if not minv or aggv < minv then
            minv = aggv
            mini = i
        end
    end
    return mini,minv
end

function table.max(tb,agg)
    local maxi,maxv
    for i,v in pairs(tb or {}) do
        local aggv = agg and agg(v,i) or v
        if not maxv or aggv > maxv then
            maxv = aggv
            maxi = i
        end
    end
    return maxi,maxv
end

function table.logic_and(tb,agg)
    for k,v in pairs(tb or {}) do
        if not agg(v,k) then return false end
    end

    return true
end

function table.logic_or(tb,agg)
    for k,v in pairs(tb or {}) do
        if agg(v,k) then return true end
    end

    return false
end

function table.foreach(tb,op,on)
    for k,v in pairs(tb or {}) do
        if not on or on(v,k) then op(v,k) end
    end
end

function table.agg(tb,init,agg_op)
    local ret = init or {}
    for k,v in pairs(tb or {}) do ret = agg_op(ret,v,k) end
    return ret
end

function table.ref_broadcast(tb,func)
    for k,v in pairs(tb or {}) do 
        tb[k] = func(v,k)
    end
end

function table.broadcast(tb,func)
    local r = {}
    for k,v in pairs(tb or {}) do r[k] = func(v,k) end
    return r
end

function table.get(tb,field,default)
    if not tb[field] then
        tb[field] = default
    end

    return tb[field]
end

function table.join(left,right,on,join_type,prefix)
    prefix = prefix or "r"
    join_type = join_type or "inner"

    local function merge_with_prefix(l,r,pre)
        pre = pre or "r"
        local tb = clone(l)
        for k,v in pairs(r) do
            k = not tb[k] and k or pre .. "_".. k
            tb[k] = v
        end
        return tb
    end
    local join_func = {
        left = function()
            local res = {}
            for _,lr in pairs(left) do
                local row
                for _,rr in pairs(right) do
                    if on(lr,rr) then
                        row = merge_with_prefix(lr,rr,prefix)
                    end
                end
                table.insert(res,row or lr)
            end

            return res
        end,
        right = function()
            local res = {}
            for _,rr in pairs(right) do
                local row
                for _,lr in pairs(left) do
                    if on(lr,rr) then
                        row = merge_with_prefix(lr,rr,prefix)
                    end
                end
                if not row then
                    table.insert(res,table.map(rr,function(v,k) return prefix .. "_".. k,v end))
                else
                    table.insert(res,row)
                end
            end

            return res
        end,
        inner = function()
            local res = {}
            for _,lr in pairs(left) do
                local row
                for _,rr in pairs(right) do
                    if on(lr,rr) then
                        row = merge_with_prefix(lr,rr,prefix)
                    end
                end
                if row then
                    table.insert(res,row)
                end
            end

            return res
        end
    }
    
    return join_func[join_type]()
end

function table.reverse(tb)
    local ret = {}
    for j = #tb,1,-1 do
        table.insert(ret,tb[j])
    end
    return ret
end

function table.intersect(left,right,on)
    local inter = {}
    for _,l in pairs(left) do
        for _,r in pairs(right) do
            if on(l,r) then
                table.insert(inter,l)
            end
        end
    end
    return inter
end

function table.extract(tb,field)
    return table.series(tb,function(v) return v[field] end)
end

function table.tostring(tb)
    return string.format("{%s}",table.concat(tb,","))
end


string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

function string.split(input, fetcher)
    if not fetcher or fetcher == '' then 
        return nil 
    end

    local next = string.gmatch(input,fetcher)
    local ss = {}
    local s = next()
    while s do
        table.insert(ss,s)
        s = next()
    end
    return ss
end

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

function string.urlencode(input)
    -- input = string.gsub(tostring(input), "\n", "\r\n")

    input = string.gsub(input, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    -- input = string.gsub(input, " ", "+")
    -- convert spaces to "+" symbols
    return input
end

function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function string.eval(str)
    return assert(load(str))()
end
