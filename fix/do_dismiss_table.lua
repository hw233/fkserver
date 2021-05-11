local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local table_id = tonumber(...)
if not table_id then
  print("table id is",table_id)
  return
end

local tb = g_room:find_table(table_id)
if not tb then
  print("table",table_id,"not found")
end

tb:do_dismiss()

print("success")