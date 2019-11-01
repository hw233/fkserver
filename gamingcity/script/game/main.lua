
def_game_name,def_game_id = table.unpack({...})

local skynet = require "skynet"
local msgopt = require "msgopt"
local dbopt = require "dbopt"
local redisopt = require "redisopt"
local pb = require "pb"

require "functions"


-- enum GAME_READY_MODE
local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")

function get_game_cfg(game_id)
    local cfg = dbopt.config:query("SELECT * FROM t_game_server_cfg WHERE game_id = %d and is_open = 1;",game_id)
    
    -- dump(cfg)
	if cfg and #cfg > 0 then
        return cfg[1]
	end

	log.error(string.format("get_game_cfg failed,game id = %d", def_game_id))
end

function get_register_money()
    return global_int_cfg.register_money
end

function get_private_room_bank()
    return global_int_cfg.private_room_bank
end

local function get_global_int_cfg()
    local rs = dbopt.config:query("SELECT * FROM t_globle_int_cfg;")
    if not rs or #rs == 0 then
        return {}
    end

    local cfg = {}
    for _,r in pairs(rs) do
        cfg[r.key] = r.value
    end

    -- dump(cfg)

    return cfg
end

local function get_redis_cfg()
    return dbopt.config:query("SELECT * FROM t_redis_cfg;")
end

skynet.start(function()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    global_int_cfg = get_global_int_cfg()
    if not global_int_cfg then
        skynet.error("gamed get_global_int_cfg faild!")
        skynet.exit()
        return
    end

    game_cfg = get_game_cfg(def_game_id)

    if not game_cfg then 
        skynet.error("gamed get_game_cfg faild!")
        skynet.exit()
        return
    end

    def_first_game_type = game_cfg.first_game_type
    def_second_game_type = game_cfg.second_game_type
    game_lua_cfg = game_cfg.room_lua_cfg

    local redis_cfg = get_redis_cfg()
    for i,cfg in pairs(redis_cfg) do
        redisopt.connect({
            id = i,
            host = cfg.ip,
            port = cfg.port,
            auth = cfg.password,
        })
    end

    open_lan_mate = true

    math.randomseed(tostring(os.time()):reverse():sub(1, 6))

    --维护开关响应(全局变量0正常,1进入维护中,默认正常)
    cash_switch = 0  --提现开关全局变量
    game_switch = 0  --游戏开关全局变量

    local tb_game_obj = {
		lobby = function ()
			local base_room = require "game.lobby.base_room"
			local mgr = base_room
			room:init(game_cfg, 2, GAME_READY_MODE_NONE, game_lua_cfg)
			return room
		end,

		fishing = function ()
			pb.register_file("gamingcity/pb/common_msg_fishing.proto")
			require "game.fishing.fishing_room"
			local mgr = fishing_room:new()
			room:init(game_cfg, 4, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		jc_fishing = function ()
			pb.register_file("gamingcity/pb/common_msg_fishing.proto")
			require "game.jc_fishing.fishing_room"
			local mgr = fishing_room:new()
			room:init(game_cfg, 4, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		sanshui = function ()
			pb.register_file("gamingcity/pb/common_msg_sanshui.proto")
			require "game.sanshui.sanshui_room"
			local mgr = sanshui_room:new()
			room:init(game_cfg, 4, GAME_READY_MODE_PART, game_lua_cfg)
			return room
		end,

		twenty_one = function()
			pb.register_file("gamingcity/pb/common_msg_twenty_one.proto")
			require "game.twenty_one.twenty_one_room"
			local mgr = twenty_one_room:new()
			room:init(game_cfg, 5, GAME_READY_MODE_PART, game_lua_cfg)
			return room
		end,

		demo = function ()
			require "game.demo.demo_room"
			local mgr = demo_room:new()
			room:init(game_cfg, 2, GAME_READY_MODE_NONE, game_lua_cfg)
			return room
		end,

		shuihu_zhuan = function ()
			local game_rooms = require("game/shuihu_zhuan/game_rooms")
			local mgr = game_rooms:new()
			room:init(game_cfg, 1, GAME_READY_MODE_NONE, game_lua_cfg)
			local manager = require("game/shuihu_zhuan/game_manager")
			manager.init(1, 300, 1)
			return room
		end,

		land = function ()
			pb.register_file("gamingcity/pb/common_msg_land.proto")
			require "game.land.land_room"
			local mgr = land_room:new()
			room:init(game_cfg, 3, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		bigtwo = function ()
			pb.register_file("gamingcity/pb/common_msg_bigtwo.proto")
			require "game.bigtwo.bigtwo_room"
			local mgr = bigtwo_room:new()
			room:init(game_cfg, 4, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		zhajinhua = function ()
			pb.register_file("gamingcity/pb/common_msg_zhajinhua.proto")
			require "game.zhajinhua.zhajinhua_room"
			local mgr = zhajinhua_room:new()
			room:init(game_cfg, 5, GAME_READY_MODE_PART, game_lua_cfg)
			return room
		end,

		showhand = function ()
			pb.register_file("gamingcity/pb/common_msg_showhand.proto")
			require "game.showhand.showhand_room"
			local mgr = showhand_room:new()
			room:init(game_cfg, 2, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		ox = function ()
			pb.register_file("gamingcity/pb/common_msg_ox.proto")
			require "game.ox.ox_room"
			local mgr = ox_room:new()
			room:init(game_cfg, 30, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		texas = function ()
			pb.register_file("gamingcity/pb/common_msg_texas.proto")
			require "game.texas.texas_room"
			local mgr = texas_room:new()
			room:init(game_cfg, 7, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		sangong = function ()
			pb.register_file("gamingcity/pb/common_msg_sangong.proto")
			require "game.sangong.sangong_room"
			local mgr = sangong_room:new()
			room:init(game_cfg, 5, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		banker_ox = function ()
			pb.register_file("gamingcity/pb/common_msg_banker.proto")
			require "game.banker_ox.banker_room"
			local mgr = banker_room:new()
			room:init(game_cfg, 5, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		slotma = function ()
			pb.register_file("gamingcity/pb/common_msg_slotma.proto")
			require "game.slotma.slotma_room"
			local mgr = slotma_room:new()
			room:init(game_cfg, 1, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		maajan = function ()
			pb.register_file("gamingcity/pb/common_msg_maajan.proto")
			require "game.maajan.maajan_room"
			local mgr = maajan_room:new()
			room:init(game_cfg, 2, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		classics_ox = function ()
			pb.register_file("gamingcity/pb/common_msg_classics_ox.proto")
			require "game.classics_ox.classics_room"
			local mgr = classics_room:new()
			room:init(game_cfg, 5, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		thirteen_warter = function ()
			pb.register_file("gamingcity/pb/common_msg_thirteen_water.proto")
			require "game.thirteen_water.thirteen_room"
			local mgr = thirteen_room:new()
			room:init(game_cfg, 4, GAME_READY_MODE_PART, game_lua_cfg)
			return room
		end,

		multi_showhand = function ()
			pb.register_file("gamingcity/pb/common_msg_multi_showhand.proto")
			require "game.multi_showhand.multi_showhand_room"
			local mgr = multi_showhand_room:new()
			room:init(game_cfg, 5, GAME_READY_MODE_PART, game_lua_cfg)
			return room
		end,

		redblack = function ()
			pb.register_file("gamingcity/pb/common_msg_redblack.proto")
			require "game.redblack.redblack_room"
			local mgr = redblack_room:new()
			room:init(game_cfg, 30, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		shaibao = function ()
			pb.register_file("gamingcity/pb/common_msg_shaibao.proto")
			require "game.shaibao.shaibao_room"
			local mgr = shaibao_room:new()
			room:init(game_cfg, 30, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		fivestar = function ()
			pb.register_file("gamingcity/pb/common_msg_fivestar.proto")
			require "game.five_star.fivestar_room"
			local mgr = fivestar_room:new()
			room:init(game_cfg, 30, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		toradora = function ()
			pb.register_file("gamingcity/pb/common_msg_toradora.proto")
			require "game.toradora.toradora_room"
			local mgr = toradora_room:new()
			room:init(game_cfg, 30, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,

		shelongmen = function()
			pb.register_file("gamingcity/pb/common_msg_shelongmen.proto")
			require "game.shelongmen.shelongmen_room"
			local mgr = shelongmen_room:new()
			room:init(game_cfg, 30, GAME_READY_MODE_ALL, game_lua_cfg)
			return room
		end,
	}

	if not g_room then
		g_room = tb_game_obj[def_game_name]()
	end

    require "game.register"
    require "hotfix"
    require "game.lobby.base_player"
    require "game.lobby.base_android"
    require "game.lobby.gm_cmd"
    require "game.timer_manager"
    
	--诈金花和老虎机有奖池
    if def_game_name == "zhajinhua" or def_game_name == "slotma" then
        require "game.lobby.prize_pool"
		if not g_prize_pool then
			g_prize_pool = prize_pool:new()
			g_prize_pool:init(def_game_name)
		end
	end

    
    local base_passive_android = base_passive_android
    local room = g_room

    local function on_tick()
        timer_manager:tick()
        base_players:save_all()
        base_passive_android:on_tick()
        room:tick()

        skynet.timeout(4,on_tick)
    end
    skynet.timeout(4,on_tick)
end)