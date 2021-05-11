
local dump = require "fix.dump"

local param = ...
local verify = require "login.verify.verify"
param = tonumber(param)
verify.remove_account_lock_imei(param)
dump(print,"suc")