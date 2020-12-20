
require "login.msg.on_gate"
require "functions"
local msgopt = require "msgopt"

local register_dispatcher = msgopt.register

register_dispatcher("S_Logout",on_s_logout)
register_dispatcher("CS_RequestSmsVerifyCode",on_cs_request_sms_verify_code)
register_dispatcher("CL_Login",on_cl_login)
register_dispatcher("CL_RegAccount",on_cl_reg_account)
register_dispatcher("CL_LoginBySms",on_cl_login_by_sms)
register_dispatcher("CL_Auth",on_cl_auth)
