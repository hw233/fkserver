local callmod = require "callmod"

local string = string
local table = table
local tolower = string.lower
local strfmt = string.format
local tinsert = table.insert
local tunpack = table.unpack
local tconcat = table.concat

local cmdlines = {...}

assert(#cmdlines > 0,strfmt("invalid cmdlines %s.",tconcat(cmdlines," ")))

local cmd = tolower(cmdlines[1])
local args = {}
for i = 2,#cmdlines do
	tinsert(args,cmdlines[i])
end

local bootmod = {
	game = "bootgame",
	conf = "bootconf",
	control = "bootcontrol",
	test = "boottest",
}

local mod = bootmod[cmd] or cmd
callmod(mod,tunpack(args))