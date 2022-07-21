
require "login.msg.on_gate"
require "functions"
local msgopt = require "msgopt"

local h = {
	S_Logout = on_s_logout,
	CS_RequestSmsVerifyCode = on_cs_request_sms_verify_code,
	CL_Login = on_cl_login,
	CL_RegAccount = on_cl_reg_account,
	CL_LoginBySms = on_cl_login_by_sms,
	CL_Auth = on_cl_auth,
	S_AuthCheck = on_s_auth_check,
}

msgopt:reg(h)
