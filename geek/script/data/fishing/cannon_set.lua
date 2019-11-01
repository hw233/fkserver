cannon_pos = {
	cannon = {
		--    炮台ID  X位置     Y位置      朝向--
		[0] = {pos_x=0.25, pos_y=0.035, direction=3.14},
		[1] = {pos_x=0.75, pos_y=0.035, direction=3.14},
		[2] = {pos_x=0.75, pos_y=0.965, direction=0.0},
		[3] = {pos_x=0.25, pos_y=0.965, direction=0.0},
	},
	cannon_effect = {name="PaoTaiEffect", pos_x=-115, pos_y=0},
	jetton = {pos_x=-60, pos_y=0, Max=4},
	lock = {name="lock_flag", line="lock_line", flag="lock_flag_%d", pos_x=160, pos_y=-120}
}

cannon_set = {
	[0] = {normal=0, ion=1, double=1,
		cannon_type = {
			{type=0,
			  cannon = {{res_name="fish_pao1", name="move", res_type=0, pos_x=0, pos_y=0, fire_offest=0, type=0}},
			  bullet = {{res_name="bullet2", name="move", res_type=1, scale=1.0}},
			  net= {{res_name="effect_fish_bomb", name="effect_fish_bomb_01_ani", res_type=1, pos_x=0, pos_y=0, scale=0.8}},
			},
			{type=1,
			  cannon = {{res_name="fish_pao2", name="move", res_type=0, pos_x=0, pos_y=0, fire_offest=0, type=0}},
			  bullet = {{res_name="bullet3", name="Animation1", res_type=1, scale=1.0}},
			  net= {{res_name="effect_fish_bomb", name="effect_fish_bomb_02_ani", res_type=1, pos_x=0, pos_y=0, scale=0.8}},
			},
		},
	},
	[1] = {normal=0, ion=1, double=1,
		cannon_type = {
			{type=0,
			  cannon ={{res_name="fish_pao3", name="move", res_type=0, pos_x=0, pos_y=0, fire_offest=0, type=0}},
			  bullet = {{res_name="bullet4", name="mve", res_type=1, scale=1.0}},
			  net= {{res_name="effect_fish_bomb", name="effect_fish_bomb_03_ani", res_type=1, pos_x=0, pos_y=0, scale=0.8}},
			},
			{type=1,
			  cannon ={{res_name="fish_pao4", name="move", res_type=0, pos_x=0, pos_y=0, fire_offest=0, type=0}},
			  bullet = {{res_name="bullet5", name="move", res_type=1, scale=1.0}},
			  net= {{res_name="effect_fish_bomb", name="effect_fish_bomb_04_ani", res_type=1, pos_x=0, pos_y=0, scale=0.8}},
			},
		},
	},
}
