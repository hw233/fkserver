
local msgopt = require "msgopt"
require "config.msg.onmsg"

local register_dispatcher = msgopt.register

register_dispatcher("S_RequestServerConfig",on_S_RequestServerConfig)
register_dispatcher("S_RequestUpdateGameServerConfig",on_S_RequestUpdateGameServerConfig)
register_dispatcher("S_RequestUpdateLoginServerConfigByGate",on_S_RequestUpdateLoginServerConfigByGate)
register_dispatcher("S_RequestUpdateLoginServerConfigByGame",on_S_RequestUpdateLoginServerConfigByGame)
register_dispatcher("S_RequestUpdateDBServerConfigByGame",on_S_RequestUpdateDBServerConfigByGame)
register_dispatcher("S_RequestUpdateDBServerConfigByLogin",on_S_RequestUpdateDBServerConfigByLogin)
register_dispatcher("WF_UpdateDbCfg",on_WF_UpdateDbCfg)
register_dispatcher("WF_ChangeGameCfg",on_WF_ChangeGameCfg)
register_dispatcher("WF_GetCfg",on_WF_GetCfg)
register_dispatcher("SF_ChangeGameCfg",on_SF_ChangeGameCfg)
register_dispatcher("WS_MaintainUpdate",on_WS_MaintainUpdate)
register_dispatcher("GF_PlayerOut",on_GF_PlayerOut)
register_dispatcher("GF_PlayerIn",on_GF_PlayerIn)
register_dispatcher("WF_Recharge",on_WF_Recharge)
register_dispatcher("DF_Reply",on_DF_Reply) 
register_dispatcher("DF_ChangMoney",on_DF_ChangMoney)
register_dispatcher("FS_ChangMoneyDeal",on_FS_ChangMoneyDeal)
register_dispatcher("SS_JoinPrivateRoom",on_SS_JoinPrivateRoom)
register_dispatcher("S_RequestPlatformNum",on_S_RequestPlatformNum)
register_dispatcher("S_RequestPlatformRechargeSwitchIndex",on_S_RequestPlatformRechargeSwitchIndex)
register_dispatcher("S_RequestPlatformCashSwitchIndex",on_S_RequestPlatformCashSwitchIndex)
register_dispatcher("S_RequestPlatformPlayerToAgentCashSwitchIndex",on_S_RequestPlatformPlayerToAgentCashSwitchIndex)
register_dispatcher("S_RequestPlatformBankerTransferSwitchIndex",on_S_RequestPlatformBankerTransferSwitchIndex)
register_dispatcher("S_RequestGlobleIntCfg",on_S_RequestGlobleIntCfg)
register_dispatcher("S_RequestPlatformSwitchInfo",on_S_RequestPlatformSwitchInfo)
register_dispatcher("S_RequestPlatformAllCashSwitchIndex",on_S_RequestPlatformAllCashSwitchIndex)
