
require "login.msg.on_gate"
require "functions"
local msgopt = require "msgopt"

local register_dispatcher = msgopt.register

register_dispatcher("S_Logout",on_s_logout)
register_dispatcher("L_KickClient",on_L_KickClient)
register_dispatcher("CS_RequestSms",on_cs_request_sms)
register_dispatcher("GL_NewNotice ",on_gl_NewNotice)
register_dispatcher("SL_GameNotice",on_SL_GameNotice)
register_dispatcher("CL_Login",on_cl_login)
register_dispatcher("CL_RegAccount",on_cl_reg_account)
register_dispatcher("CL_LoginBySms",on_cl_login_by_sms)
register_dispatcher("CL_Auth",on_cl_auth)