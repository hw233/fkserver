-- 注册诈金花消息

require "game.changpai_zigong.on_changpai"

local msgopt = require "msgopt"
msgopt:reg({
	CS_Changpai_Do_Action = on_cs_do_action,
	CS_Changpai_Action_Discard = on_cs_act_discard,
	CS_VoteTableReq = on_cs_vote_table_req,
	CS_VoteTableCommit = on_cs_vote_table_commit,
	CS_ChangpaiGetTingTilesInfo = on_cs_get_ting_tiles_info,
	CS_Baoting = on_cs_bao_ting,
})