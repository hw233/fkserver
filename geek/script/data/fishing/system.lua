system_set = { 
	show_debug_info=0,
    shadow=1,
	--游戏默认的窗口大小--
	default_screen_set = {width=1027, height=768},
	--金币渔币兑换比例和一次性兑换渔币数量--
	exchange_score = {ratio={1,1}, once=1000000, show_gold_min_mul=1},
	--开炮时间最小间隔(毫秒)  最大间隔--
	fire = {interval=200, max_interval=90000, max_bullet=20},
	catch = {notice_level=3000, android_prob_mul=1.0},
	special = {max_count=3},
	--离子炮设定  出现的倍率　出现的机率　　时长--
	ion_set = {multiple=30, probability=500, time=7},
	cannon_set = {normal=0, ion=1, double=1},
	first_fire  = {{level=0, count=10, type_list={1,2,3,4,5}, weight_list={1,1,1,1,1}}},
}
