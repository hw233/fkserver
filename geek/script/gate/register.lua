
local msgopt = require "msgopt"
local netmsgopt = require "netmsgopt"

require "gate.msg.on_client"
require "gate.msg.on_config"
require "gate.msg.on_login"

local register_dispatcher = netmsgopt.register
local register_server_dispatcher = msgopt.register


register_dispatcher("C_RequestPublicKey",on_C_RequestPublicKey)
register_dispatcher("CL_RegAccount",on_CL_RegAccount)
register_dispatcher("CL_Login",on_CL_Login)
register_dispatcher("CL_LoginByPotato",on_CL_Login_By_Potato)
register_dispatcher("CL_LoginBySms",on_CL_LoginBySms)
register_dispatcher("CS_RequestSms",on_CS_RequestSms)
register_dispatcher("CG_GameServerCfg",on_CG_GameServerCfg)
register_dispatcher("CL_GetInviterInfo",on_CL_GetInviterInfo)
register_dispatcher("CS_SetNickname",on_CS_SetNickname)
register_dispatcher("CS_ResetAccount",on_CS_ResetAccount)
register_dispatcher("CS_SetPassword",on_CS_SetPassword)
register_dispatcher("CS_SetPasswordBySms",on_CS_SetPasswordBySms)
register_dispatcher("CS_BankSetPassword",on_CS_BankSetPassword)
register_dispatcher("CS_BankChangePassword",on_CS_BankChangePassword)
register_dispatcher("CS_BankLogin",on_CS_BankLogin)
register_dispatcher("CS_BankDraw", on_CS_BankDraw)
register_dispatcher("FS_ChangMoneyDeal",on_FS_ChangMoneyDeal)

register_server_dispatcher("S_Filter",on_S_Filter)
register_server_dispatcher("S_ReplyServerConfig",on_S_ReplyServerConfig)
register_server_dispatcher("S_NotifyGameServerStart",on_S_NotifyGameServerStart)
register_server_dispatcher("S_ReplyUpdateGameServerConfig",on_S_ReplyUpdateGameServerConfig)
register_server_dispatcher("S_NotifyLoginServerStart",on_S_NotifyLoginServerStart)
register_server_dispatcher("S_ReplyUpdateLoginServerConfigByGate",on_S_ReplyUpdateLoginServerConfigByGate)
register_server_dispatcher("FG_GameServerCfg",on_FG_GameServerCfg)
register_server_dispatcher("SS_JoinPrivateRoom",on_SS_JoinPrivateRoom)
register_server_dispatcher("S_ReplyWarningAddr",on_S_ReviceWarnningAddr)
register_server_dispatcher("LG_UpdatePlayerBank",on_LG_UpdatePlayerBank)