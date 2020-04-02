-- 注册诈金花消息

require "game.maajan_xuezhan.on_maajan"

--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数

register_dispatcher("CS_Maajan_Act_Win",on_cs_act_win)--胡
register_dispatcher("CS_Maajan_Act_Double",on_cs_act_double)--加倍
register_dispatcher("CS_Maajan_Act_Discard",on_cs_act_discard)--打牌
register_dispatcher("CS_Maajan_Act_Peng",on_cs_act_peng)--碰
register_dispatcher("CS_Maajan_Act_Gang",on_cs_act_gang)--杠
register_dispatcher("CS_Maajan_Act_Pass",on_cs_act_pass)--过
register_dispatcher("CS_Maajan_Act_Chi",on_cs_act_chi)--吃
register_dispatcher("CS_Maajan_Act_Trustee",on_cs_act_trustee)--托管
register_dispatcher("CS_Maajan_Act_BaoTing",on_cs_act_baoting)--报听
register_dispatcher("CS_Maajan_Do_Action",on_cs_do_action)
register_dispatcher("CS_Maajan_Action_Discard",on_cs_act_discard)
register_dispatcher("CS_HuanPai",on_cs_huan_pai)
register_dispatcher("CS_DingQue",on_cs_ding_que)
register_dispatcher("CS_VoteTableReq",on_cs_vote_table_req)
register_dispatcher("CS_VoteTableCommit",on_cs_vote_table_commit)