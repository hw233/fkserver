local skynet = require "skynet"
local timermgr = require "timermgr"

local table = table
local math = math

local tinsert = table.insert
local mfloor = math.floor

local INTERVAL = 1

local starttick = skynet.time()

local tasks = {}
local secondtasks = {}

local function guard()
    local now = skynet.time()
    local elapsed = mfloor(now - starttick)
    for second, fns in pairs(secondtasks) do
        if elapsed % second < 1 then
            for fn in pairs(fns) do
                fn()
            end
        end
    end
    timermgr:new_timer(INTERVAL,guard)
end

timermgr:new_timer(INTERVAL,guard)

local m = {}

function m.exec(second,fn)
    assert(second and second > 0 and fn and type(fn) == "function")
    second = mfloor(second)
    tasks[fn] = second
    secondtasks[second] = secondtasks[second] or {}
    secondtasks[second][fn] = second
end

function m.remove(fn)
    local second = tasks[fn]
    if not second then return end
    secondtasks[second][fn] = nil
end

return m