local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"
require "functions"
local redisopt = require "redisopt"
local reddb = redisopt.default

local unionid_uuid = {
    ["oXRuxxB1ZN2qwUD00HIka15j52pw"] = "ded15fd9d75dd5cbe594a9816690157c0a2405b2",
    ["oXRuxxNeDixr7RjR1pUYVLUqIGRg"] = "c8324a82bf027056d23586dff8bf958b165c2c46",
    ["oXRuxxF-SNUP2jUWDs65uo7_tpak"] = "69bee1c28e482f861cfe41a4bb06b86becd63b6a",
    ["oXRuxxH4vL8LvXNvu-jgvJnK1mtk"] = "7dca073c7a75f4e570f4aa5894678e1728cdef19",
    ["ompjp1EwAK30tTz1HUlvXlstf7os"] = "e4d235def6754b7203e60f6905dd0471dc9b2ba6",
    ["ompjp1ASiIbHTbAo84QE65hyNVEs"] = "e0916cfec1947b35bc356d8e29e481ef0dd2505b",
    ["ompjp1GElT0sNauAp70N62HpNc1w"] = "cf3022ad9a8588f963ed911e19a6bec3d0480840",
    ["ompjp1MQLa7okDlhzuiojY9XbUNw"] = "758cd743cf12e30361ed529ab79d0c0893337e4a",
    ["ompjp1Mh6qqpxfUrUTYviMZQHuuE"] = "19a5ead3bd5db380e123f645cf8197d1f18a1b6c",
}
local uuid_guid = {
     ["ded15fd9d75dd5cbe594a9816690157c0a2405b2"] = 815833,
     ["c8324a82bf027056d23586dff8bf958b165c2c46"] = 151026,
     ["69bee1c28e482f861cfe41a4bb06b86becd63b6a"] = 320551,
     ["7dca073c7a75f4e570f4aa5894678e1728cdef19"] = 956630,
     ["e4d235def6754b7203e60f6905dd0471dc9b2ba6"] = 513332,
     ["e0916cfec1947b35bc356d8e29e481ef0dd2505b"] = 318535,
     ["cf3022ad9a8588f963ed911e19a6bec3d0480840"] = 951816,
     ["758cd743cf12e30361ed529ab79d0c0893337e4a"] = 899421,
     ["19a5ead3bd5db380e123f645cf8197d1f18a1b6c"] = 452546,
}

local unionid = ...
local uuid = unionid_uuid[unionid]
if uuid then
    local guid = uuid_guid[uuid]
    dump(print,string.format("suc guid[%d] uuid[%s] unionid[%s]",guid,uuid,unionid))
    reddb:set(string.format("player:auth_id:%s",unionid),uuid)
    reddb:set("player:account:"..tostring(uuid),guid)
else
    dump(print,string.format("not uuid unionid[%s]",unionid))
end

