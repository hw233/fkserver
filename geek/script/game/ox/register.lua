-- 注册牛牛消息

require "game.ox.on_ox"

register_dispatcher("CS_OxRequestBanker", on_cs_ox_request_banker)  --用户申请上庄
register_dispatcher("CS_OxUnRequestBanker", on_cs_ox_unrequest_banker)  --用户申请下庄(上庄列表中的用户)
register_dispatcher("CS_OxLeaveBanker", on_cs_ox_leave_banker)   --在当庄的用户主动申请下庄 
register_dispatcher("CS_OxCallBanker", on_cs_ox_call_banker)
register_dispatcher("CS_OxAddScore", on_cs_ox_bet)
register_dispatcher("CS_OxSplitCards",on_cs_ox_split_cards)
register_dispatcher("CS_OxStartGame",on_cs_ox_start_game)