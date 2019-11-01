-- ai操作相关
local AiPlayCard = AiPlayCard
local AiPlayCardPassive = AiPlayCardPassive
local GrabLandlord = GrabLandlord
local GrabLandlord2 = GrabLandlord2

if not g_ai_init_query_queue then
	g_ai_init_query_queue_index = 1
	g_ai_init_query_queue = {}
end

function ai_execute_callback(index, reply)
	local func = g_ai_init_query_queue[index]
	assert(func)
	func(reply)
	g_ai_init_query_queue[index] = nil
end

function ai_AiPlayCard(cmd_pb_str, func)
	g_ai_init_query_queue[g_ai_init_query_queue_index] = func
	AiPlayCard(cmd_pb_str,"ai_execute_callback", g_ai_init_query_queue_index)
	g_ai_init_query_queue_index = g_ai_init_query_queue_index + 1
end

function ai_AiPlayCardPassive(cmd_pb_str, func)
	g_ai_init_query_queue[g_ai_init_query_queue_index] = func
	AiPlayCardPassive(cmd_pb_str,"ai_execute_callback", g_ai_init_query_queue_index)
	g_ai_init_query_queue_index = g_ai_init_query_queue_index + 1
end

function ai_GrabLandlord(cmd_pb_str, func)
	g_ai_init_query_queue[g_ai_init_query_queue_index] = func
	GrabLandlord(cmd_pb_str,"ai_execute_callback", g_ai_init_query_queue_index)
	g_ai_init_query_queue_index = g_ai_init_query_queue_index + 1
end

function ai_GrabLandlord2(cmd_pb_str, func)
	g_ai_init_query_queue[g_ai_init_query_queue_index] = func
	GrabLandlord2(cmd_pb_str,"ai_execute_callback", g_ai_init_query_queue_index)
	g_ai_init_query_queue_index = g_ai_init_query_queue_index + 1
end