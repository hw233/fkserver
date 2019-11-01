-- ai操作相关
local AiPlayCard = AiPlayCard
local AiPlayCardPassive = AiPlayCardPassive
local GrabLandlord = GrabLandlord
local GrabLandlord2 = GrabLandlord2

function ai_AiPlayCard(cmd_pb_str, func)
	AiPlayCard(cmd_pb_str,"ai_execute_callback", g_ai_init_query_queue_index)
end

function ai_AiPlayCardPassive(cmd_pb_str, func)
	AiPlayCardPassive(cmd_pb_str,"ai_execute_callback", g_ai_init_query_queue_index)
end

function ai_GrabLandlord(cmd_pb_str, func)
	GrabLandlord(cmd_pb_str,"ai_execute_callback", g_ai_init_query_queue_index)
end

function ai_GrabLandlord2(cmd_pb_str, func)
	GrabLandlord2(cmd_pb_str,"ai_execute_callback", g_ai_init_query_queue_index)
end