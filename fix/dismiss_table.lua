

local enum = require "pb_enums"

local table_id = tonumber(...)

if not table_id then
	print("table id can not be nil:",table_id)
	return
end

local tb = g_room:find_table(table_id)
if not tb then
	print("table not found:",table_id)
	return
end

local result = tb:wait_force_dismiss(4)
if result == enum.ERROR_NONE then
	print("table dismiss success ",result)
	return
end

print("table dismiss failed:",result)