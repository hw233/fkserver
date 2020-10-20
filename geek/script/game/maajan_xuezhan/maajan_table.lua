local base_table = require "game.lobby.base_table"
local def 		= require "game.maajan_xuezhan.base.define"
local mj_util 	= require "game.maajan_xuezhan.base.mang_jiang_util"
local log = require "log"
local json = require "cjson"
local maajan_tile_dealer = require "maajan_tile_dealer"
local base_private_table = require "game.lobby.base_private_table"
local enum = require "pb_enums"
local profile = require "skynet.profile"
local skynet = require "skynetproto"
local club_utils = require "game.club.club_utils"

local yield = profile.yield
local resume = profile.resume

require "functions"

local FSM_S  = def.FSM_state

local ACTION = def.ACTION

local ACTION_PRIORITY = {
    [ACTION.PASS] = 5,
    [ACTION.PENG] = 4,
    [ACTION.AN_GANG] = 3,
    [ACTION.MING_GANG] = 3,
    [ACTION.BA_GANG] = 3,
    [ACTION.MEN] = 2,
    [ACTION.MEN_ZI_MO] = 2,
    [ACTION.TING] = 2,
    [ACTION.HU] = 1,
    [ACTION.ZI_MO] = 1,
}

local SECTION_TYPE = def.SECTION_TYPE
local TILE_AREA = def.TILE_AREA
local HU_TYPE_INFO = def.HU_TYPE_INFO
local HU_TYPE = def.HU_TYPE

local all_tiles = {
    [4] = {
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
    },
    [3] = {
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
    },
    [2] = {
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
    }
}

local play_opt_conf = {
    si_ren_liang_fang = {
        start_count = 4,
        tiles = {
            all = {
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
            },
        }
    },
    san_ren_liang_fang = {
        start_count = 3,
        tiles = {
            count = 13,
            all = {
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
            },
        }
    },
    er_ren_san_fang = {
        start_count = 2,
        tiles = {
            count = 13,
            all = {
                1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
            },
        }
    },
    er_ren_liang_fang = {
        start_count = 2,
        tiles = {
            count = 13,
            all = {
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
                11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
            },
        }
    },
    er_ren_yi_fang = {
        start_count = 2,
        tiles = {},
    },
}

local function get_play_conf(play_opt,tiles_opt)
    local play_conf = play_opt_conf[play_opt]
    if not play_conf then return end

    local start_count = play_conf.start_count
    local tiles_conf = play_conf.tiles

    local function get_all_tiles(opt)
        if tiles_conf.all then
            return tiles_conf.all
        end

        if not opt or opt > 2 or opt < 0 then
            log.error("get_play_conf got invalid tiles opt.%s",opt)
            return all_tiles[start_count]
        end

        local tiles = {}
        for i = 1,9 do
            table.insert(tiles,opt * 10 + i)
            table.insert(tiles,opt * 10 + i)
            table.insert(tiles,opt * 10 + i)
            table.insert(tiles,opt * 10 + i)
        end

        return tiles
    end

    local function get_game_tile_count(opt)
        if tiles_conf.count then
            return tiles_conf.count
        end

        return opt
    end

    return start_count,get_all_tiles(tiles_opt.all),get_game_tile_count(tiles_opt.count)
end


local maajan_table = base_table:new()

-- 初始化
function maajan_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
    self.cur_state_FSM = nil
    self.start_count = self.chair_count
end

function maajan_table:on_private_inited()
    self.cur_round = nil
    self.zhuang = nil
    self.game_tile_count = 13
    local room_private_conf = self:room_private_conf()
    if not room_private_conf then return end

    if not room_private_conf.play then return end

    local play_opt = room_private_conf.play.option
    if not play_opt then return end

    local rule_play = self.rule.play

    local start_count,tiles,game_tile_count = get_play_conf(play_opt,{
        count = rule_play.tile_count,
        all = rule_play.tile_men,
    })

    self.start_count = start_count
    self.tiles = tiles
    self.game_tile_count = game_tile_count
    self.cur_state_FSM = nil

    log.dump(tiles)
    log.dump(game_tile_count)
end

function maajan_table:on_private_dismissed()
    log.info("maajan_table:on_private_dismissed")
    self.cur_round = nil
    self.zhuang = nil
    self.tiles = nil
    self.cur_state_FSM = nil
    for _,p in pairs(self.players) do
        p.total_money = nil
    end
    self:cancel_all_auto_action_timer()
    self:cancel_clock_timer()

    base_table.on_private_dismissed(self)
end

function base_table:check_start()
    if table.nums(self.ready_list) == self.start_count then
        self:start(self.start_count)
    end
end

function maajan_table:on_started(player_count)
    self.start_count = player_count
    base_table.on_started(self,player_count)
	for _,v in pairs(self.players) do
        v.hu                    = nil
        v.deposit               = false
        v.last_action           = nil
        v.mo_pai_count          = 0
        v.chu_pai_count         = 0
        v.pai                   = {
            shou_pai = {},
            ming_pai = {},
            desk_tiles = {},
            huan = nil,
        }
        v.jiao                  = nil

        v.mo_pai = nil
        v.chu_pai = nil
        v.que = nil
        v.multi_pao = nil

        v.statistics = v.statistics or {}
    end

    self:ding_zhuang()
	self.chu_pai_player_index      = self.zhuang --出牌人的索引
    self.last_chu_pai              = -1 --上次的出牌
    self.mo_pai_count = nil
    self:update_state(FSM_S.PER_BEGIN)
    self.game_log = {
        start_game_time = os.time(),
        zhuang = self.zhuang,
        mj_min_scale = self.mj_min_scale,
        players = table.map(self.players,function(_,chair) return chair,{} end),
        action_table = {},
        rule = self.private_id and self.rule or nil,
        club = (self.private_id and self.conf.club) and club_utils.root(self.conf.club).id,
        table_id = self.private_id or nil,
    }

    self.tiles = self.tiles or all_tiles[player_count]

    self.dealer = maajan_tile_dealer:new(self.tiles)
    self:cancel_clock_timer()
    self:cancel_all_auto_action_timer()
    self:pre_begin()
    self:huan_pai()
end

function maajan_table:fast_start_vote_req(player)
    local player_count = table.sum(self.players,function(p) return 1 end)
    if player_count < 2 then
        send2client_pb(player,"SC_VoteTableReq",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    self.lock(function() self:fast_start_vote(player) end)
end

function maajan_table:fast_start_vote_commit(p,msg)
    self.lock(function()
        local agree = msg.agree
        agree = agree and true or false
        if not vote_result[p.chair_id] then
            vote_result[p.chair_id] = agree
        end

        self:broadcast2client("SC_VoteTableCommit",{
            result = enum.ERROR_NONE,
            chair_id = p.chair_id,
            guid = p.guid,
            agree = agree,
        })

        if agree then
            if not table.logic_and(self.players,function(_,chair) return vote_result[chair] ~= nil end) then
                return
            end
        end

        local all_agree = table.logic_and(vote_result,function(a) return a end)
        self:broadcast2client("SC_VoteTable",{success = all_agree})
        if not all_agree then
            self:update_state(nil)
            self.co = nil
            return true
        end

        self:start(table.nums(self.players))
    end)
end

function maajan_table:on_reconnect_when_fast_start_vote()
    local status = {}
    for chair,r in pairs(vote_result) do
        local pi = self.players[chair]
        table.insert(status,{
            chair_id = pi.chair_id,
            guid = pi.guid,
            agree = r,
        })
    end

    send2client_pb(p,"SC_VoteTableRequestInfo",{
        vote_type = "FAST_START",
        request_guid = player.guid,
        request_chair_id = player.chair_id,
        timeout= math.ceil(timer and timer.remainder or timeout),
        status = status
    })
end

function maajan_table:fast_start_vote(player)
    self:update_state(FSM_S.FAST_START_VOTE)
    
    local timeout = 60
    self:broadcast2client("SC_VoteTableReq",{
        vote_type = "FAST_START",
        request_guid = player.guid,
        request_chair_id = player.chair_id,
        timeout = timeout,
    })

    local vote_result = {}

    vote_result[player.chair_id] = true
    self:broadcast2client("SC_VoteTableCommit",{
        result = enum.ERROR_NONE,
        chair_id = player.chair_id,
        guid = player.guid,
        agree = true,
    })

    self:begin_clock_timer(timeout,function()
        self:foreach(function(p)
            if vote_result[p.chair_id] == nil then
                self:fast_start_vote_commit(p,{agree = false})
            end
        end)
    end)
end

function maajan_table:set_trusteeship(player,trustee)
    if not self.rule.trustee or table.nums(self.rule.trustee) == 0 then
        return 
    end

    base_table.set_trusteeship(self,player,trustee)
    if not trustee then
        self:cancel_auto_action_timer(player)
    end
end

function maajan_table:clean_trusteeship()
    self:foreach(function(p) p.trustee = nil end)
end

function maajan_table:xi_pai()
    self:update_state(FSM_S.XI_PAI)
    self:prepare_tiles()
    self:foreach(function(v)
        self:send_data_to_enter_player(v)
        self.game_log.players[v.chair_id].start_pai = self:tile_count_2_tiles(v.pai.shou_pai)
    end)
end

function maajan_table:on_reconnect_when_action_qiang_gang_hu(p)
    send2client_pb(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client_pb(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    self:send_ding_que_status(p)
    self:send_ting_tips(p)

    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,p)
    end

    for chair,actions in pairs(self.waiting_actions) do
        self:send_action_waiting(actions)
    end
end

function maajan_table:on_action_qiang_gang_hu(p,msg)
    local action = self:check_action_before_do(self.waiting_actions,p,msg)
    if not action then return end

    local act = msg.action
    local tile = msg.value_tile

    self:cancel_auto_action_timer(p)
    action.done = { action = act }
    local all_done = table.logic_and(self.waiting_actions,function(action) return action.done ~= nil end)
    if all_done then
        self:cancel_clock_timer()
    end

    local chu_pai_player = self:chu_pai_player()
    if act == ACTION.HU then
        p.hu = {
            time = os.time(),
            tile = self.qiang_gang_tile,
            types = self:hu(p,self.qiang_gang_tile),
            zi_mo = false,
            whoee = self.chu_pai_player_index,
            qiang_gang = true,
        }

        self:log_game_action(p,act,tile)
        self:broadcast_player_hu(p,act)
        p.statistics.hu = (p.statistics.hu or 0) + 1
        chu_pai_player.statistics.dian_pao = (chu_pai_player.statistics.dian_pao or 0) + 1

        if table.nums(actions_to_do) > 1 then
            chu_pai_player.multi_pao = true
        end

        table.decr(chu_pai_player.pai.shou_pai,tile)

        local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
        if self.start_count - hu_count == 1 then
            self:do_balance()
            return
        end

        local last_hu_player = nil
        self:foreach(function(p) if p.hu then last_hu_player = p end end)
        self:next_player_index(last_hu_player)
        self:mo_pai()
        self:done_last_action(p,{action = ACTION.BA_GANG,tile = self.qiang_gang_tile})
    end

    if all_done then
        local all_pass = table.logic_and(self.waiting_actions,function(action) return action.done.action == ACTION.PASS end)
        self.waiting_actions = {}
        if not all_pass then
            self.qiang_gang_tile = nil
            return
        end

        self:adjust_shou_pai(chu_pai_player,ACTION.BA_GANG,self.qiang_gang_tile)
        chu_pai_player.statistics.ming_gang = (chu_pai_player.statistics.ming_gang or 0) + 1
        chu_pai_player.guo_zhuang_hu = nil
        self:done_last_action(chu_pai_player,{action = ACTION.BA_GANG,tile = self.qiang_gang_tile})
        self:mo_pai()
        self.qiang_gang_tile = nil
    end
end

function maajan_table:qiang_gang_hu(player,actions,tile)
    self:update_state(FSM_S.WAIT_QIANG_GANG_HU)
    self.waiting_actions = actions
    for chair,action in pairs(actions) do
        self:send_action_waiting(action)
    end

    self.qiang_gang_tile = tile

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_action(p)
            self.lock(function()
                self:on_action_qiang_gang_hu(p,{
                    action = ACTION.HU,
                    value_tile = tile,
                })
            end)
        end

        log.dump(self.waiting_actions)
        self:begin_clock_timer(trustee_seconds,function()
            table.foreach(self.waiting_actions,function(action,_)
                if action.done then return end

                local p = self.players[action.chair_id]
                self:set_trusteeship(p,true)
                auto_action(p)
            end)
        end)

        table.foreach(self.waiting_actions,function(action,_) 
            local p = self.players[action.chair_id]
            if not p.trustee then return end

            self:begin_auto_action_timer(p,math.random(1,2),function() 
                auto_action(p)
            end)
        end)
    end
end

function maajan_table:on_reconnect_when_huan_pai(player)
    send2client_pb(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    self:send_huan_pai_status(player)
    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,player)
    end
end

function maajan_table:on_huan_pai(player,msg)
    local tiles = msg.tiles
    for _,tile in pairs(tiles) do
        local c = player.pai.shou_pai[tile]
        if not c or c == 0 then
            send2client_pb(player.guid,"SC_HuanPai",{
                result = enum.PARAMETER_ERROR,
            })
            log.error("maajan_table:huan_pai tiles %s",table.concat(tiles,","))
            return
        end
    end
    
    local tile_count = table.nums(tiles)
    local huan_count = self:get_huan_count()
    if tile_count ~= huan_count then
        send2client_pb(player.guid,"SC_HuanPai",{
            result = enum.PARAMETER_ERROR,
        })
        log.error("maajan_table:huan_pai huan_count == %d,but tiles count = %d",huan_count,tile_count)
        return
    end

    local huan_type = self:get_huan_type()
    if huan_type == 1 then
        local g = table.group(tiles,function(t) return math.floor(t / 10) end)
        local mens = table.map(g,function(gp,men) return men,table.nums(gp) end)
        local men_count = table.nums(mens)
        if men_count ~= 1 then
            send2client_pb(player.guid,"SC_HuanPai",{
                result = enum.PARAMETER_ERROR,
            })
            log.error("maajan_table:huan_pai huan_type == %d,but men count = %d",huan_type,men_count)
            return
        end
    end

    self:cancel_auto_action_timer(player)

    player.pai.huan = {old = tiles,}

    send2client_pb(player,"SC_HuanPai",{
        result = enum.ERROR_NONE,
        chair_id = player.chair_id,
        done = true,
        self_choice = tiles,
    })

    self:broadcast2client_except(player,"SC_HuanPai",{
        result = enum.ERROR_NONE,
        chair_id = player.chair_id,
        done = true,
    })

    if not table.logic_and(self.players,function(p) return p.pai.huan ~= nil end) then
        return
    end

    self:cancel_clock_timer()
    
    local order = self:do_huan_pai()
    self.game_log.huan_order = order
    local log_players = self.game_log.players
    self:foreach(function(p)
        log_players[p.chair_id].huan = p.pai.huan
        send2client_pb(p,"SC_HuanPaiCommit",{
            new_shou_pai = p.pai.huan.new,
            huan_order = order,
        })
    end)

    self:ding_que()
end

function maajan_table:huan_pai()
    if not self.rule.huan or table.nums(self.rule.huan) == 0 then
        self:ding_que()
        return
    end

    self:update_state(FSM_S.HUAN_PAI)
    self:broadcast2client("SC_AllowHuanPai",{})

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type and (trustee_type == 1 or (trustee_type == 2 and self.cur_round > 1))  then
        local function random_choice(alltiles,count)
            local ats = clone(alltiles)
            local tiles = {}
            for _ = 1,count do
                local i,tile = table.choice(ats)
                table.insert(tiles,tile)
                table.remove(ats,i)
            end

            return tiles
        end

        local function auto_huan_pai(p,huan_type,huan_count)
            if huan_type ~= 1 then
                local huan_tiles = random_choice(self:tile_count_2_tiles(p.pai.shou_pai),huan_count)
                log.dump(huan_pai)
                self.lock(function()
                    self:on_huan_pai(p,{
                        tiles = huan_tiles
                    })
                end)
                return
            end

            local men_tiles = table.group(p.pai.shou_pai,function(_,tile) return mj_util.tile_men(tile) end)

            local c = 0
            local tilecounts
            repeat
                _,tilecounts = table.choice(men_tiles)
                c = table.sum(tilecounts)
            until c > huan_count

            local huan_tiles = random_choice(self:tile_count_2_tiles(tilecounts),huan_count)
            self.lock(function()
                self:on_huan_pai(p,{tiles = huan_tiles})
            end)
            return
        end

        local huan_count = self:get_huan_count()
        local huan_type = self:get_huan_type()
        log.info("%s,%s",huan_type,huan_count)
        self:begin_clock_timer(trustee_seconds,function()
            self:foreach(function(p)
                if p.pai.huan then return end

                self:set_trusteeship(p,true)
                auto_huan_pai(p,huan_type,huan_count)
            end)
        end)

        self:foreach(function(p)
            if not p.trustee then return end
            
            self:begin_auto_action_timer(p,math.random(1,2),function()
                auto_huan_pai(p,huan_type,huan_count)
            end)
        end)
    end
end

function maajan_table:on_reconnect_when_ding_que(player)
    send2client_pb(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    self:send_ding_que_status(player)
    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,player)
    end
end

function maajan_table:begin_auto_action_timer(p_or_chair,timeout,fn)
    local chair_id = type(p_or_chair) == "table" and p_or_chair.chair_id or p_or_chair
    if self.action_timers[chair_id] then
        log.warning("maajan_table:begin_auto_action_timer timer not nil")
    end
    self.action_timers[chair_id] = self:calllater(timeout,fn)
end

function maajan_table:cancel_auto_action_timer(p_or_chair)
    self.action_timers = self.action_timers or {} 
    local chair_id = type(p_or_chair) == "table" and p_or_chair.chair_id or p_or_chair
    if self.action_timers[chair_id] then
        self.action_timers[chair_id]:kill()
        self.action_timers[chair_id] = nil
    end
end

function maajan_table:cancel_all_auto_action_timer()
    for _,timer in pairs(self.action_timers or {}) do
        timer:kill()
    end

    self.action_timers = {}
end

function maajan_table:begin_clock_timer(timeout,fn)
    if self.clock_timer then 
        log.warning("maajan_table:begin_clock_timer timer not nil")
        self.clock_timer:kill()
    end

    self.clock_timer = self:new_timer(timeout,fn)
    self:begin_clock(timeout)

    log.info("maajan_table:begin_clock_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.clock_timer.id,timeout)
end

function maajan_table:cancel_clock_timer()
    log.info("maajan_table:cancel_clock_timer table_id:%s,timer:%s",self.table_id_,self.clock_timer and self.clock_timer.id or nil)
    if self.clock_timer then
        self.clock_timer:kill()
        self.clock_timer = nil
    end
end

function maajan_table:on_ding_que(player,msg)
    local men = msg.men
    if not men or men < 0 or men > 3 then
        send2client_pb(player,"SC_DingQue",{
            result = enum.PARAMETER_ERROR
        })
        return
    end

    player.que = msg.men
    self:broadcast2client("SC_DingQue",{
        result = enum.ERROR_NONE,
        status = {
            chair_id = player.chair_id,
            done = true,
        }
    })

    self:cancel_auto_action_timer(player)

    if not table.logic_and(self.players,function(p) return p.que ~= nil end) then
        return
    end

    self:cancel_clock_timer()
    
    local log_players = self.game_log.players
    local p_ques = {}
    self:foreach(function(p)
        log_players[p.chair_id].que = p.que
        table.insert(p_ques,{
            chair_id = p.chair_id,
            men = p.que,
        })
    end)

    self:broadcast2client("SC_DingQueCommit",{
        ding_ques = p_ques,
    })

    self:jump_to_player_index(self.zhuang)
    self:action_after_ding_que()
end

function maajan_table:ding_que()
    if #self.tiles < 108 then
        self:jump_to_player_index(self.zhuang)
        self:action_after_ding_que()
        return
    end

    self:update_state(FSM_S.DING_QUE)
    self:broadcast2client("SC_AllowDingQue",{})

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type and (trustee_type == 1 or (trustee_type == 2 and self.cur_round > 1))  then
        local function auto_ding_que(p)
            local g = table.group(p.pai.shou_pai,function(c,tile) return mj_util.tile_men(tile) end)
            local men_count = table.map(g,function(gp,men) return men,table.sum(gp)  end)
            local min_men,c = table.min(men_count)
            log.info("%s,%s",min_men,c)
            self:on_ding_que(p,{
                men = min_men
            })
        end
        self:begin_clock_timer(trustee_seconds,function()
            self:foreach(function(p)
                if p.que then return end

                self:set_trusteeship(p,true)
                auto_ding_que(p)
            end)
        end)

        log.dump(table.series(self.players,function(p) return p.guid end))
        self:foreach(function(p)
            log.info("%s,%s",p.guid,p.trustee)
            if not p.trustee then return end
            self:begin_auto_action_timer(p,math.random(1,2),function() 
                auto_ding_que(p)
            end)
        end)
    end
end

function maajan_table:on_action_after_mo_pai(player,msg)
    local action = self:check_action_before_do(self.waiting_actions,player,msg)
    if not action then 
        log.warning("on_action_after_mo_pai invalid action guid:%s,action:%s",player.guid,msg.action)
        return 
    end

    self:cancel_clock_timer()
    self:cancel_all_auto_action_timer()

    local do_action = msg.action
    local chair_id = player.chair_id
    local tile = msg.value_tile

    if chair_id ~= self.chu_pai_player_index then
        log.error("do action:%s but chair_id:%s is not current chair_id:%s after mo_pai",
            do_action,chair_id,self.chu_pai_player_index)
        return
    end

    log.dump(self.waiting_actions)
    local player = self:chu_pai_player()
    if not player then
        log.error("do action %s,but wrong player in chair %s",do_action,player.chair_id)
        return
    end

    local player_actions = self.waiting_actions[player.chair_id].actions
    if not player_actions[do_action] and do_action ~= ACTION.PASS and do_action ~= ACTION.CHU_PAI then
        log.error("do action %s,but action is illigle,%s",do_action)
        return
    end

    self.waiting_actions = {}

    if do_action == ACTION.BA_GANG then
        local qiang_gang_hu = {}
        self:foreach_except(player,function(p)
            if p.hu then return end

            local actions = self:get_actions(p,nil,tile)
            if actions[ACTION.HU] then
                qiang_gang_hu[p.chair_id] = {
                    chair_id = p.chair_id,
                    actions = {
                        [ACTION.HU] = actions[ACTION.HU]
                    }
                }
            end
        end)

        self:log_game_action(player,do_action,tile)
        local is_qiang_gang = table.nums(qiang_gang_hu) > 0
        if is_qiang_gang then
            self:qiang_gang_hu(player,qiang_gang_hu,tile)
            return
        end

        self:adjust_shou_pai(player,do_action,tile)
        self:jump_to_player_index(player)
        player.statistics.ming_gang = (player.statistics.ming_gang or 0) + 1
        player.guo_zhuang_hu = nil
        self:mo_pai()
    end

    if do_action == ACTION.AN_GANG then
        self:adjust_shou_pai(player,do_action,tile)
        self:log_game_action(player,do_action,tile)
        self:jump_to_player_index(player)
        player.statistics.an_gang = (player.statistics.an_gang or 0) + 1
        player.guo_zhuang_hu = nil
        self:mo_pai()
    end

    if do_action == ACTION.ZI_MO then
        -- 点杠花算点炮
        local is_zi_mo = true
        local whoee = nil
        if self.rule.play.dgh_dian_pao and player.last_action and player.last_action.action == ACTION.MING_GANG then
            is_zi_mo = nil
            for _,s in pairs(player.pai.ming_pai) do
                if s.tile == player.last_action.tile and s.type == SECTION_TYPE.MING_GANG then
                    whoee = s.whoee
                    break
                end
            end
        end

        player.hu = {
            time = os.time(),
            tile = tile,
            types = self:hu(player,nil,player.mo_pai),
            zi_mo = is_zi_mo,
            whoee = whoee,
        }

        player.statistics.zi_mo = (player.statistics.zi_mo or 0) + 1

        self:log_game_action(player,do_action,tile)
        self:broadcast_player_hu(player,do_action)
        local hu_count  = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
        if self.start_count - hu_count  == 1 then
            self:do_balance()
        else
            self:next_player_index()
            self:mo_pai()
        end
    end

    if do_action == ACTION.PASS then
        self:broadcast2client("SC_Maajan_Do_Action",{chair_id = player.chair_id,action = do_action})
        self:chu_pai()
    end

    self:done_last_action(player,{action = do_action,tile = tile,})
end

function maajan_table:on_reconnect_when_action_after_mo_pai(p)
    self:send_ding_que_status(p)
    send2client_pb(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client_pb(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})

    local action = self.waiting_actions[p.chair_id]
    if action then
        self:send_action_waiting(action)
    end

    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,p)
    end
end

function maajan_table:action_after_mo_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_MO_PAI)
    self.waiting_actions = waiting_actions
    for _,action in pairs(self.waiting_actions) do
        self:send_action_waiting(action)
    end

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_action(p,action)
            local act = action.actions[ACTION.ZI_MO] and ACTION.ZI_MO or ACTION.PASS
            local tile = p.mo_pai
            self.lock(function()
                self:on_action_after_mo_pai(p,{
                    action = act,
                    value_tile = tile,
                    chair_id = p.chair_id,
                })
            end)
        end

        self:begin_clock_timer(trustee_seconds,function()
            log.dump(self.waiting_actions)
            table.foreach(self.waiting_actions,function(action,_)
                if action.done then return end

                local p = self.players[action.chair_id]
                self:set_trusteeship(p,true)
                auto_action(p,action)
            end)
        end)

        table.foreach(self.waiting_actions,function(action,_) 
            log.dump(self.waiting_actions)
            local p = self.players[action.chair_id]
            if not p.trustee then return end

            self:begin_auto_action_timer(p,math.random(1,2),function() 
                auto_action(p,action)
            end)
        end)
    end
end

function maajan_table:choice_first_turn_mo_pai(player)
    local fake_mo_pai
    for tile,c in pairs(player.pai.shou_pai) do
        if c > 0 then 
            fake_mo_pai = tile
            break
        end
    end

    player.mo_pai = fake_mo_pai
    return fake_mo_pai
end

function maajan_table:action_after_ding_que()
    local player = self:chu_pai_player()

    local mo_pai = self:choice_first_turn_mo_pai(player)
    log.dump(mo_pai)

    log.info("---------fake mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})

    local actions = self:get_actions_first_turn(player,mo_pai)
    log.dump(actions)
    if table.nums(actions) > 0 then
        self:action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
            }
        })
    else
        self:chu_pai()
    end
end

function maajan_table:on_reconnect_when_action_after_chu_pai(p)
    send2client_pb(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client_pb(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    self:send_ding_que_status(p)
    local action = self.waiting_actions[p.chair_id]
    if action then
        self:send_action_waiting(action)
    end
    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,p)
    end
end

function maajan_table:on_action_after_chu_pai(player,msg)
    local action = self:check_action_before_do(self.waiting_actions,player,msg)
    if action then
        action.done = {
            action = msg.action,
            tile = msg.value_tile,
        }
        local chair = action.chair_id
        self:cancel_auto_action_timer(self.players[chair])
    end

    if not table.logic_and(self.waiting_actions,function(action) return action.done ~= nil end) then
        return 
    end

    self:cancel_clock_timer()

    local all_actions = table.values(self.waiting_actions)
    if table.nums(all_actions) == 0 then
        self:next_player_index()
        self:mo_pai()
        return
    end

    table.sort(all_actions,function(l,r)
        return ACTION_PRIORITY[l.done.action] < ACTION_PRIORITY[r.done.action]
    end)

    local function do_action(actions_to_do)
        local action = actions_to_do[1]

        local chu_pai_player = self:chu_pai_player()
        
        local player = self.players[action.chair_id]
        if not player then
            log.error("do action %s,nil player in chair %s",action.done.action,action.chair_id)
            return
        end

        local tile = action.done.tile
        if action.done.action == ACTION.PENG then
            table.pop_back(chu_pai_player.pai.desk_tiles)
            self:adjust_shou_pai(player,action.done.action,tile)
            self:log_game_action(player,action.done.action,tile)
            self:jump_to_player_index(player)
            self:chu_pai()
        end

        if def.is_action_gang(action.done.action) then
            table.pop_back(chu_pai_player.pai.desk_tiles)
            self:adjust_shou_pai(player,action.done.action,tile)
            self:log_game_action(player,action.done.action,tile)
            self:jump_to_player_index(player)
            self:mo_pai()
            player.statistics.ming_gang = (player.statistics.ming_gang or 0) + 1
            player.guo_zhuang_hu = nil
        end

        if action.done.action == ACTION.HU then
            for _,act in ipairs(actions_to_do) do
                local p = self.players[act.chair_id]
                p.hu = {
                    time = os.time(),
                    tile = tile,
                    types = self:hu(p,tile),
                    zi_mo = false,
                    whoee = self.chu_pai_player_index,
                }

                if chu_pai_player.last_action and def.is_action_gang(chu_pai_player.last_action.action) then
                    local pai = chu_pai_player.pai
                    for _,s in pairs(pai.ming_pai) do
                        if s.tile == chu_pai_player.last_action.tile and def.is_section_gang(s.type) then
                            s.dian_pao = act.chair_id
                        end
                    end
                end

                self:log_game_action(p,act.done.action,tile)
                self:broadcast_player_hu(p,act.done.action)
                p.statistics.hu = (p.statistics.hu or 0) + 1
                chu_pai_player.statistics.dian_pao = (chu_pai_player.statistics.dian_pao or 0) + 1
            end

            if table.nums(actions_to_do) > 1 then
                chu_pai_player.multi_pao = true
            end

            table.pop_back(chu_pai_player.pai.desk_tiles)

            local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
            if self.start_count - hu_count == 1 then
                self:do_balance()
            else
                local last_hu_player = nil
                self:foreach(function(p) if p.hu then last_hu_player = p end end)
                self:next_player_index(last_hu_player)
                self:mo_pai()
            end
        end

        if def.is_action_chi(action.done.action) then
            if not action[action.done.action][tile] then
                return
            end

            table.pop_back(chu_pai_player.pai.desk_tiles)
            self:adjust_shou_pai(player,action.done.action,tile)
            self:log_game_action(player,action.done.action,tile)
            self:jump_to_player_index(player)
            self:chu_pai()
        end

        if action.done.action == ACTION.PASS then
            if self.rule.play.guo_zhuang_hu then
                local hu_action = action.actions[ACTION.HU]
                if hu_action then
                    player.guo_zhuang_hu = self:max_hu(player.pai,hu_action)
                end
            end

            if self.rule.play.guo_shou_peng then
                local peng_action = action.actions[ACTION.PENG]
                if peng_action then
                    player.guo_shou_peng = peng_action.tile
                end
            end

            self:broadcast2client("SC_Maajan_Do_Action",{chair_id = player.chair_id,action = ACTION.PASS})
            self:next_player_index()
            self:mo_pai()
        end

        self:done_last_action(player,{action = action.done.action,tile = tile})
    end

    local top_action
    local actions_to_do = {}
    for _,action in pairs(all_actions) do
        top_action = top_action or action
        if action.done.action ~= top_action.done.action then
            break
        end
        table.insert(actions_to_do,action)
    end
    
    do_action(actions_to_do)
end

function maajan_table:action_after_chu_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_CHU_PAI)
    self.waiting_actions = waiting_actions
    for _,action in pairs(self.waiting_actions) do
        self:send_action_waiting(action)
    end

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_action(p,action)
            local act = action.actions[ACTION.HU] and ACTION.HU or ACTION.PASS
            local tile = self:chu_pai_player().chu_pai
            self.lock(function()
                self:on_action_after_chu_pai(p,{
                    action = act,
                    value_tile = tile
                })
            end)
        end

        self:begin_clock_timer(trustee_seconds,function()
            table.foreach(self.waiting_actions,function(action,_)
                local p = self.players[action.chair_id]
                self:set_trusteeship(p,true)
                auto_action(p,action)
            end)
        end)

        table.foreach(self.waiting_actions,function(action,_)
            local p = self.players[action.chair_id]
            if not p.trustee then return end

            self:begin_auto_action_timer(p,math.random(1,2),function()
                auto_action(p,action)
            end)
        end)
    end
end

function maajan_table:fake_mo_pai()
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai

    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 0 then
        self:do_balance()
        return
    end

    local mo_pai
    if table.nums(self.pre_gong_tiles or {}) > 0 then
        for i,tile in pairs(self.pre_gong_tiles) do
            mo_pai = self.dealer:deal_one_on(function(t) return t == tile end)
            self.pre_gong_tiles[i] = nil
            break
        end
    else
        mo_pai = self.dealer:deal_one()
    end

    table.incr(shou_pai,mo_pai)

    player.guo_zhuang_hu = nil
    player.guo_shou_peng = nil

    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    player.mo_pai_count = (player.mo_pai_count or 0) + 1
end

function maajan_table:mo_pai()
    self:update_state(FSM_S.WAIT_MO_PAI)
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai

    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 0 then
        self:do_balance()
        return
    end

    local mo_pai
    if table.nums(self.pre_gong_tiles or {}) > 0 then
        for i,tile in pairs(self.pre_gong_tiles) do
            mo_pai = self.dealer:deal_one_on(function(t) return t == tile end)
            self.pre_gong_tiles[i] = nil
            break
        end
    else
        mo_pai = self.dealer:deal_one()
    end

    if not mo_pai then
        self:do_balance()
        return
    end

    player.guo_zhuang_hu = nil
    player.guo_shou_peng = nil

    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    
    table.incr(shou_pai,mo_pai)
    log.info("---------mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Draw",msg = {tile = mo_pai}})
    self:on_mo_pai(player,mo_pai)

    local actions = self:get_actions(player,mo_pai)
    log.dump(actions)
    if table.nums(actions) > 0 then
        self:action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
            }
        })
    else
        self:chu_pai()
    end
end

function maajan_table:ting(p)
    if not self:is_que(p) then return {} end

    local si_dui = self.rule.play and self.rule.play.si_dui
    local ting_tiles = mj_util.is_ting(p.pai,si_dui) or {}
    if p.que and ting_tiles then
        table.filter(ting_tiles,function(_,tile) return mj_util.tile_men(tile) ~= p.que end)
    end

    return ting_tiles
end

function maajan_table:is_que(p)
    if not p.que then return true end

    local g = table.group(p.pai.shou_pai,function(_,tile) return mj_util.tile_men(tile) end)
    local men_counts = table.map(g,function(gp,men)  return men,table.sum(gp)  end)
    local men_count = table.sum(men_counts,function(c,men) return (c > 0 and men < 3) and 1 or 0 end)
    return men_count <= 2
end

function maajan_table:ting_full(p)
    if not self:is_que(p) then return {} end

    local si_dui = self.rule.play and self.rule.play.si_dui
    local ting_tiles = mj_util.is_ting_full(p.pai,si_dui)
    if p.que then
        ting_tiles = table.map(ting_tiles,function(tiles,discard)
            local hu_tiles = table.map(tiles,function(_,tile)
                return tile,mj_util.tile_men(tile) ~= p.que and tile or nil
            end)
            return discard, table.nums(hu_tiles) > 0 and hu_tiles or nil
        end)
    end

    return ting_tiles
end

function maajan_table:broadcast_discard_turn()
    self:broadcast2client("SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
end

function maajan_table:broadcast_wait_discard(player)
    local chair_id = type(player) == "table" and player.chair_id or player
    self:broadcast2client("SC_MaajanWaitingDiscard",{chair_id = chair_id})
end

function maajan_table:on_action_chu_pai(player,msg)
    if self.cur_state_FSM ~= FSM_S.WAIT_CHU_PAI then
        return
    end

    local chu_pai_val = msg.tile

    if not mj_util.check_tile(chu_pai_val) then
        log.error("player %s chu_pai,tile invalid error:%s",self.chu_pai_player_index,chu_pai_val)
        return
    end

    local shou_pai = player.pai.shou_pai
    if not shou_pai[chu_pai_val] or shou_pai[chu_pai_val] == 0 then
        log.error("tile isn't exist when chu guid:%s,tile:%s",player.guid,chu_pai_val)
        return
    end

    self:cancel_clock_timer()
    self:cancel_all_auto_action_timer()

    log.info("---------chu pai guid:%s,chair: %s,tile:%s ------",player.guid,self.chu_pai_player_index,chu_pai_val)
    shou_pai[chu_pai_val] = shou_pai[chu_pai_val] - 1
    self:on_chu_pai(chu_pai_val)
    table.insert(player.pai.desk_tiles,chu_pai_val)
    self:broadcast2client("SC_Maajan_Action_Discard",{chair_id = player.chair_id, tile = chu_pai_val})
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Discard",msg = {tile = chu_pai_val}})

    local waiting_actions = {}
    self:foreach(function(v)
        if v.hu then return end
        if player.chair_id == v.chair_id then return end

        local actions = self:get_actions(v,nil,chu_pai_val)
        if table.nums(actions) > 0 then
            waiting_actions[v.chair_id] = {
                chair_id = v.chair_id,
                actions = actions,
            }
        end
    end)

    log.dump(waiting_actions)
    if table.nums(waiting_actions) == 0 then
        self:next_player_index()
        self:mo_pai()
    else
        self:action_after_chu_pai(waiting_actions)
    end
end

function maajan_table:send_ting_tips(p)
    local hu_tips = self.rule and self.rule.play.hu_tips or nil
    if not hu_tips or p.trustee then return end

    local ting_tiles = self:ting_full(p)
    log.dump(ting_tiles)
    if table.nums(ting_tiles) > 0 then
        local pai = clone(p.pai)
        local discard_tings = table.series(ting_tiles,function(tiles,discard)
            table.decr(pai.shou_pai,discard)
            local tings = table.series(tiles,function(_,tile) return {tile = tile,fan = self:hu_fan(pai,tile)} end)
            table.incr(pai.shou_pai,discard)
            return { discard = discard, tiles_info = tings, }
        end)

        log.dump(discard_tings)

        send2client_pb(p,"SC_TingTips",{
            ting = discard_tings
        })

        return true
    end
end

function maajan_table:on_reconnect_when_chu_pai(p)
    send2client_pb(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client_pb(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    self:send_ding_que_status(p)
    self:send_ting_tips(p)

    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,p)
    end
end

function maajan_table:chu_pai()
    self:update_state(FSM_S.WAIT_CHU_PAI)
    
    local player = self:chu_pai_player()
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_chu_pai(p)
            local chu_tile = p.mo_pai
            if p.que then
                local men_tiles = table.group(p.pai.shou_pai,function(_,tile) return mj_util.tile_men(tile) end)

                log.dump(men_tiles)
                if men_tiles[p.que] and table.sum(men_tiles[p.que]) > 0 then
                    local c
                    repeat
                        chu_tile,c = table.choice(men_tiles[p.que])
                        log.info("%d,%d",chu_tile,c)
                    until c and c > 0
                end
            end

            if not chu_tile or not p.pai.shou_pai[chu_tile] or p.pai.shou_pai[chu_tile] <= 0 then
                local c
                repeat
                    chu_tile,c = table.choice(p.pai.shou_pai)
                until c > 0
            end

            log.info("auto_chu_pai chair_id %s,tile %s",p.chair_id,chu_tile)
            self.lock(function()
                self:on_action_chu_pai(p,{
                    tile = chu_tile,
                })
            end)
        end

        log.info("begin chu_pai clock %s",player.chair_id)
        self:begin_clock_timer(trustee_seconds,function()
            log.info("chu_pai clock timeout %s",player.chair_id)
            self:set_trusteeship(player,true)
            auto_chu_pai(player)
        end)

        if player.trustee then
            log.info("begin auto_chu_pai timer %s",player.chair_id)
            self:begin_auto_action_timer(player,math.random(1,2),function()
                log.info("auto_chu_pai timeout %s",player.chair_id)
                auto_chu_pai(player)
            end)
        end
    end

    self:send_ting_tips(player)
end

function maajan_table:get_max_fan()
    local fan_opt = self.rule.fan.max_option + 1
    return self.room_.conf.private_conf.fan.max_option[fan_opt]
end

function maajan_table:do_balance()
    local typefans,fanscores = self:game_balance()
    log.dump(typefans)
    log.dump(fanscores)
    local msg = {
        players = {},
        player_balance = {},
    }

    local ps = table.values(self.players)
    table.sort(ps,function(l,r)
        if l.hu and not r.hu then return true end
        if not l.hu and r.hu then return false end
        if l.hu and r.hu then return l.hu.time < r.hu.time end
        return false
    end)

    table.foreach(ps,function(p,i)
        if p.hu then p.hu.index = i end
    end)

    local jiao_count = table.sum(self.players,function(p) return p.jiao and 1 or 0 end)

    local chair_money = {}
    for chair_id,p in pairs(self.players) do
        local p_score = fanscores[chair_id] and fanscores[chair_id].score or 0
        local shou_pai = self:tile_count_2_tiles(p.pai.shou_pai)
        local ming_pai = table.values(p.pai.ming_pai)
        local desk_pai = table.values(p.pai.desk_tiles)
        local p_log = self.game_log.players[chair_id]
        p_log.chair_id = chair_id
        p_log.nickname = p.nickname
        p_log.head_url = p.icon
        p_log.guid = p.guid
        p_log.sex = p.sex
        p_log.pai = {
            desk_pai = desk_pai,
            shou_pai = shou_pai,
            ming_pai = ming_pai,
            huan = p.pai.huan,
        }

        p.total_score = (p.total_score or 0) + p_score
        p_log.score = p_score

        table.insert(msg.players,{
            chair_id = chair_id,
            desk_pai = desk_pai,
            shou_pai = shou_pai,
            pb_ming_pai = ming_pai,
        })

        table.insert(msg.player_balance,{
            chair_id = chair_id,
            total_score = p.total_score,
            round_score = p_score,
            items = typefans[chair_id],
            hu_tile = p.hu and p.hu.tile or nil,
            hu_fan = fanscores[chair_id].fan,
            hu = p.hu and (p.hu.zi_mo and 2 or 1) or nil,
            status = p.hu and 2 or (p.jiao and 3 or (jiao_count > 0 and 1 or nil)),
            hu_index = p.hu and p.hu.index or nil,
        })

        local win_money = self:calc_score_money(p_score)
        chair_money[chair_id] = win_money
        log.info("player hu %s,%s,%s",chair_id,p_score,win_money)
    end

    log.dump(msg)

    local logids = {
        [200] = enum.LOG_MONEY_OPT_TYPE_MAAJAN_XUEZHAN,
        [201] = enum.LOG_MONEY_OPT_TYPE_MAAJAN_XUEZHAN_SI_ER,
        [202] = enum.LOG_MONEY_OPT_TYPE_MAAJAN_XUEZHAN_SAN_ER,
        [203] = enum.LOG_MONEY_OPT_TYPE_MAAJAN_XUEZHAN_ER_SAN,
        [204] = enum.LOG_MONEY_OPT_TYPE_MAAJAN_XUEZHAN_ER_ER,
        [205] = enum.LOG_MONEY_OPT_TYPE_MAAJAN_XUEZHAN_ER_YI,
    }

    chair_money = self:balance(chair_money,logids[def_first_game_type])
    for _,balance in pairs(msg.player_balance) do
        local p = self.players[balance.chair_id]
        local p_log = self.game_log.players[balance.chair_id]
        local money = chair_money[balance.chair_id]
        balance.round_money = money
        p.total_money = (p.total_money or 0) + money
        balance.total_money = p.total_money
        p_log.total_money = p.total_money
        p_log.win_money = money
    end

    self:broadcast2client("SC_MaajanXueZhanGameFinish",msg)

    self:notify_game_money()

    self.game_log.balance = msg.player_balance
    self.game_log.end_game_time = os.time()
    self.game_log.cur_round = self.cur_round

    self:save_game_log(self.game_log)

    self.game_log = nil
    
    self:game_over()
end

function maajan_table:pre_begin()
    self:xi_pai()
end

function maajan_table:get_huan_type()
    local type_option = self.rule.huan.type_opt + 1
    return self.room_.conf.private_conf.huan.type_option[type_option]
end

function maajan_table:get_huan_count()
    local count_option = self.rule.huan.count_opt + 1
    return self.room_.conf.private_conf.huan.count_option[count_option]
end

function maajan_table:do_huan_pai()
    local function push_shou_pai(player,tiles)
        for _,tile in pairs(tiles) do
            table.incr(player.pai.shou_pai,tile)
        end
    end

    local function pop_shou_pai(player,tiles)
        for _,tile in pairs(tiles) do
            table.decr(player.pai.shou_pai,tile)
        end
    end

    local function swap(p1,p2)
        p1.pai.huan.new = p2.pai.huan.old
        push_shou_pai(p1,p2.pai.huan.old)
        p2.pai.huan.new = p1.pai.huan.old
        push_shou_pai(p2,p1.pai.huan.old)
    end

    self:foreach(function(p)
        log.dump(p.pai.shou_pai)
        pop_shou_pai(p,p.pai.huan.old)
    end)

    local player_count = table.sum(self.players,function(p) return p and 1 or 0 end)
    local huan_order = player_count == 4 and math.random(0,2) or math.random(0,1)
    if huan_order == 0 then
        self:foreach(function(p,i)
            local j  = i
            local p1
            repeat
                j = (j - 2) % self.chair_count + 1
                p1 = self.players[j]
            until p1
            push_shou_pai(p1,p.pai.huan.old)
            p1.pai.huan.new = p.pai.huan.old
        end)
    elseif huan_order == 1 then
        self:foreach(function(p,i)
            local j  = i
            local p1
            repeat
                j = j % self.chair_count + 1
                p1 = self.players[j]
            until p1
            push_shou_pai(p1,p.pai.huan.old)
            p1.pai.huan.new = p.pai.huan.old
        end)
    elseif huan_order == 2 then
        local p1 = self.players[1]
        local p2 = self.players[2]
        local p3 = self.players[3]
        local p4 = self.players[4]
        swap(p1,p3)
        swap(p2,p4)
    end

    self:foreach(function(p)
        log.dump(p.pai.shou_pai)
    end)

    return huan_order
end

function maajan_table:send_action_waiting(action)
    local chair_id = action.chair_id
    log.info("send_action_waiting,%s",chair_id)
    local actions = {}
    for act,tiles in pairs(action.actions) do
        for tile,_ in pairs(tiles) do
            table.insert(actions,{
                action = act,
                tile = tile,
            })
        end
    end

    send2client_pb(self.players[chair_id],"SC_WaitingDoActions",{
        chair_id = chair_id,
        actions = actions,
    })
end

function maajan_table:prepare_tiles()
    self.dealer:shuffle()
    self.pre_tiles = {
        -- [1] = {21,21,22,22,23,23,24,24,25,25,25,25,26},
        -- [2] = {11,12,13,14,15,16,17,18,19,8,8,8,7},
        -- [3] = {21,21,22,22,23,23,24,24,25,25,26,26,27},
        -- [4] = {21,21,22,22,23,23,24,24,25,25,26,26,27},
    }

    self:foreach(function(p)
        local tiles = self.pre_tiles[p.chair_id]
        if tiles then
            self.dealer:pick_tiles(tiles)
        end

        local c = table.nums(tiles or {})
        if c < self.game_tile_count then
            tiles = table.union(tiles or {},self.dealer:deal_tiles(self.game_tile_count - c))
        end

        for _,t in pairs(tiles) do
            table.incr(p.pai.shou_pai,t)
        end
    end)

    self.chu_pai_player_index = self.zhuang
    self:fake_mo_pai()
end

function maajan_table:max_hu(pai,tiles)
    local fans = table.series(tiles,function(_,tile) return self:hu_fan(pai,tile) end)
    table.sort(fans,function(l,r) return l > r end)
    if table.nums(fans) > 0 then
        return fans[1]
    end
end

function maajan_table:hu_fan(pai,tile)
    local hu = self:rule_hu(pai,tile)
    local fans = self:calculate_hu({
        types = hu,
        tile = tile,
    })

    return table.sum(fans,function(t) return (t.fan or 0) * (t.count or 1) end)
end

function maajan_table:get_actions_first_turn(p,mo_pai)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local actions = mj_util.get_actions_first_turn(p.pai,mo_pai,si_dui)

    log.dump(actions)

    if p.que then
        for act,tiles in pairs(actions) do
            for tile,_ in pairs(tiles) do
                if mj_util.tile_men(tile) == p.que then
                    tiles[tile] = nil
                end
            end

            if table.nums(tiles) == 0 then
                actions[act] = nil
            end
        end
    end

    if not self:is_que(p) and (actions[ACTION.HU] or actions[ACTION.ZI_MO]) then
        actions[ACTION.HU] = nil
        actions[ACTION.ZI_MO] = nil
    end

    return actions
end

function maajan_table:get_actions(p,mo_pai,in_pai)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local actions = mj_util.get_actions(p.pai,mo_pai,in_pai,si_dui)

    log.dump(actions)

    if p.que then
        for act,tiles in pairs(actions) do
            for tile,_ in pairs(tiles) do
                if mj_util.tile_men(tile) == p.que then
                    tiles[tile] = nil
                end
            end

            if table.nums(tiles) == 0 then
                actions[act] = nil
            end
        end
    end

    if p.guo_zhuang_hu and actions[ACTION.HU] then
        local max_hu_fan = self:max_hu(p.pai,actions[ACTION.HU])
        if max_hu_fan and max_hu_fan <= p.guo_zhuang_hu then
            actions[ACTION.HU] = nil
        end
    end

    if in_pai and not self:can_hu(p,in_pai) and actions[ACTION.HU] then
        actions[ACTION.HU] = nil
    end

    if p.guo_shou_peng and actions[ACTION.PENG] then
        local action = actions[ACTION.PENG]
        if action[p.guo_shou_peng] then
            actions[ACTION.PENG][p.guo_shou_peng] = nil
        end
    end

    if not self:is_que(p) and (actions[ACTION.HU] or actions[ACTION.ZI_MO]) then
        actions[ACTION.HU] = nil
        actions[ACTION.ZI_MO] = nil
    end

    return actions
end

local action_name_str = {
    [ACTION.AN_GANG] = "AnGang",
    [ACTION.PENG] = "Peng",
    [ACTION.MING_GANG] = "MingGang",
    [ACTION.BA_GANG] = "BaGang",
    [ACTION.FREE_BA_GANG] = "FreeBaGang",
    [ACTION.ZI_MO] = "ZiMo",
    [ACTION.LEFT_CHI] = "LeftChi",
    [ACTION.MID_CHI] = "MidChi",
    [ACTION.RIGHT_CHI] = "RightChi",
    [ACTION.JIA_BEI] = "JiaBei",
    [ACTION.TRUSTEE] = "Trustee",
    [ACTION.PASS] = "Pass",
    [ACTION.HU] = "Hu",
    [ACTION.TING] = "Ting",
    [ACTION.CHU_PAI] = "Discard",
    [ACTION.MEN] = "Men",
    [ACTION.MO_PAI] = "Draw",
    [ACTION.MEN_ZI_MO] = "ZiMoMen",
    [ACTION.FREE_AN_GANG] = "FreeAnGang",
}

function maajan_table:log_game_action(player,action,tile)
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[action],msg = {tile = tile}})
end

function maajan_table:done_last_action(player,action)
    player.last_action = action
    self:foreach_except(player,function(p) p.last_action = nil end)
end

function maajan_table:check_action_before_do(waiting_actions,player,msg)
    local action = msg.action
    local chair_id = player.chair_id
    local tile = msg.value_tile
    local player_actions = waiting_actions[chair_id]
    if not player_actions then
        log.error("no action waiting when check_action_before_do,chair_id %s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    local actions = player_actions.actions
    if not actions then
        log.error("on action %s,%s,actions is nil",chair_id,tile)
        return
    end

    if action == ACTION.PASS then
        return player_actions
    end

    if def.is_action_gang(action) then
        if not actions[action] or not actions[action][tile] then
            log.error("no action waiting when check_action_before_do,chair_id,action:%s,tile:%s",chair_id,action,tile)
            return
        end
    end

    return player_actions
end

function maajan_table:on_mo_pai(player,mo_pai)
    player.mo_pai = mo_pai
    player.mo_pai_count = (player.mo_pai_count or 0) + 1
    send2client_pb(player,"SC_Maajan_Draw",{tile = mo_pai,chair_id = player.chair_id})
    self:foreach_except(player,function(p)
        send2client_pb(p,"SC_Maajan_Draw",{tile = 255,chair_id = player.chair_id})
        p.mo_pai = nil
    end)
end

function maajan_table:calculate_hu(hu)
    local types = table.series(hu.types,function(c,t)
        local type_info = HU_TYPE_INFO[t]
        return {type = t,fan = type_info.fan,score = type_info.score,count = c}
    end)

    if hu.qiang_gang then
        local type_info = HU_TYPE_INFO[HU_TYPE.QIANG_GANG_HU]
        table.insert(types,{type = HU_TYPE.QIANG_GANG_HU,fan = type_info.fan,score = type_info.score,count = 1})
    end

    local room_private_conf = self:room_private_conf()
    if not room_private_conf or not room_private_conf.play then
        return types
    end

    local play_opt = room_private_conf.play.option
    local da_dui_zi_fan = self.rule.play.da_dui_zi_fan_2 and 2 or HU_TYPE_INFO[HU_TYPE.DA_DUI_ZI].fan
    local qing_yi_se_fan = play_opt == "er_ren_yi_fang" and (self.rule.play.qing_yi_se_fan or 0) or HU_TYPE_INFO[HU_TYPE.QING_YI_SE].fan
    -- local si_dui_fan = HU_TYPE_INFO[HU_TYPE.SI_DUI].fan
    -- local long_si_dui_fang = HU_TYPE_INFO[HU_TYPE.LONG_SI_DUI].fan

    for _,t in pairs(types) do
        if t.type == HU_TYPE.QING_YI_SE then
            t.fan = qing_yi_se_fan
        end

        if t.type == HU_TYPE.QING_DA_DUI then
            t.fan = qing_yi_se_fan + da_dui_zi_fan
        end

        if t.type == HU_TYPE.DA_DUI_ZI then
            t.fan = da_dui_zi_fan
        end

        if t.type == HU_TYPE.QING_QI_DUI and play_opt == "er_ren_yi_fang" then
            t.fan = qing_yi_se_fan + HU_TYPE_INFO[HU_TYPE.QI_DUI].fan
        end

        if t.type == HU_TYPE.QING_LONG_BEI and play_opt == "er_ren_yi_fang" then
            t.fan = qing_yi_se_fan + HU_TYPE_INFO[HU_TYPE.LONG_QI_DUI].fan
        end

        if t.type == HU_TYPE.QING_SI_DUI then
            t.fan = qing_yi_se_fan + HU_TYPE_INFO[HU_TYPE.SI_DUI].fan
        end

        if t.type == HU_TYPE.QING_LONG_SI_DUI then
            t.fan = qing_yi_se_fan + HU_TYPE_INFO[HU_TYPE.LONG_SI_DUI].fan
        end
    end

    return types
end

function maajan_table:calculate_gang(p)
    local s2hu_type = {
        [SECTION_TYPE.MING_GANG] = HU_TYPE.MING_GANG,
        [SECTION_TYPE.AN_GANG] = HU_TYPE.AN_GANG,
        [SECTION_TYPE.BA_GANG] = HU_TYPE.BA_GANG,
    }

    local ss = table.select(p.pai.ming_pai,function(s) return  s2hu_type[s.type] ~= nil end)
    local gfan= table.group(ss,function(s) return  s2hu_type[s.type] end)
    local gangfans = table.map(gfan,function(gp,t)
        return t,{fan = HU_TYPE_INFO[t].fan,count = table.nums(gp)}
    end)

    local scores = table.agg(p.pai.ming_pai,{},function(tb,s)
        local t = s2hu_type[s.type]
        if not t then return tb end
        local hu_type_info = HU_TYPE_INFO[t]

        local who = s.dian_pao and self.players[s.dian_pao] or p
        
        if t == HU_TYPE.MING_GANG then
            tb[who.chair_id] = (tb[who.chair_id] or 0) + hu_type_info.score
            tb[s.whoee] = (tb[s.whoee] or 0) - hu_type_info.score
        elseif t == HU_TYPE.AN_GANG or t == HU_TYPE.BA_GANG then
            self:foreach_except(who,function(pi)
                if pi.hu and pi.hu.time < s.time then return end

                tb[who.chair_id] = (tb[who.chair_id] or 0) + hu_type_info.score
                tb[pi.chair_id] = (tb[pi.chair_id] or 0) - hu_type_info.score
            end)
        end

        return tb
    end)

    local fans = table.series(gangfans,function(v,t) return {type = t,fan = v.fan,count = v.count} end)
    return fans,scores
end

function maajan_table:calculate_jiao(p)
    if not p.jiao then return end

    local jiao_tiles = p.jiao.tiles
    if table.nums(jiao_tiles) == 0 then 
        return {} 
    end

    local type_fans = {}
    for tile,_ in pairs(jiao_tiles) do
        local hu = {
            types = self:rule_hu(p.pai,tile),
        }
        local hu_fans = self:calculate_hu(hu)
        local fan = table.sum(hu_fans,function(t) return (t.count or 1) * (t.fan or 0) end)
        table.insert(type_fans,{types = hu_fans,hu = hu,fan = fan,tile = tile})
    end

    if self.rule.play.cha_da_jao then
        table.sort(type_fans,function(l,r) return l.fan > r.fan end)
    elseif self.rule.play.cha_xiao_jao then
        table.sort(type_fans,function(l,r) return l.fan < r.fan end)
    end

    return type_fans[1]
end


function maajan_table:game_balance()
    self:foreach(function(p)
        if p.hu then return end

        local ting_tiles = self:ting(p)
        if table.nums(ting_tiles) > 0 then
            p.jiao = p.jiao or {tiles = ting_tiles}
            log.dump(p.jiao)
        end
    end)

    local wei_hu_count = table.sum(self.players,function(p) return (not p.hu) and 1 or 0 end)

    log.dump(wei_hu_count)

    local typefans,scores = {},{}
    self:foreach(function(p)
        local hu
        if p.hu then
            hu = self:calculate_hu(p.hu)
        elseif p.jiao then
            local jiao = self:calculate_jiao(p)
            hu = jiao.types
            p.jiao.tile = jiao.tile
        end
        
        local gangfans,gangscores
        if p.jiao or p.hu or wei_hu_count == 1 then
            gangfans,gangscores = self:calculate_gang(p)
        end

        typefans[p.chair_id] = table.union(hu or {},gangfans or {})
        table.mergeto(scores,gangscores or {},function(l,r) return (l or 0) + (r or 0) end)
    end)

    log.dump(typefans)

    local max_fan = self:get_max_fan() or 3

    local fans = table.map(typefans,function(v,chair)
        local fan = table.sum(v,function(t) return t.fan * t.count end)
        return chair,(fan > max_fan and max_fan or fan)
    end)

    self:foreach(function(p)
        local chair_id = p.chair_id
        local fan = fans[chair_id]
        local fan_score = 2 ^ math.abs(fan)
        if p.hu then
            if not p.hu.zi_mo then
                local whoee = p.hu.whoee
                scores[whoee] = (scores[whoee] or 0) - fan_score
                scores[chair_id] = (scores[chair_id] or 0) + fan_score
                return
            end

            if self.rule.play.zi_mo_jia_di then
                fan_score = fan_score + 1
            end

            self:foreach_except(p,function(pi)
                if pi.hu and pi.hu.time <= p.hu.time then return end

                local chair_i = pi.chair_id
                scores[chair_i] = (scores[chair_i] or 0) - fan_score
                scores[chair_id] = (scores[chair_id] or 0) + fan_score
            end)
        elseif p.jiao then
            self:foreach_except(p,function(pi)
                if pi.hu or pi.jiao then return end
                local chair_i = pi.chair_id
                scores[chair_id] = (scores[chair_id] or 0) + fan_score
                scores[chair_i] = (scores[chair_i] or 0) - fan_score
                if self.rule.play.cha_da_jiao then
                    pi.statistics.cha_da_jiao = (pi.statistics.cha_da_jiao or 0) + 1
                end
            end)
        end
    end)

    local fanscores = table.map(self.players,function(_,chair)
        return chair,{fan = fans[chair] or 0,score = scores[chair] or 0,}
    end)

    return typefans,fanscores
end

function maajan_table:on_game_overed()
    self:cancel_all_auto_action_timer()
    self:cancel_clock_timer()
    
    self.game_log = {}
    self:ding_zhuang()

    self:clear_ready()
    self:update_state(FSM_S.PER_BEGIN)

    self:foreach(function(v)
        v.hu = nil
        v.jiao = nil
        v.pai = {
            ming_pai = {},
            shou_pai = {},
            desk_tiles = {},
            huan = nil,
        }

        v.que = nil
    end)

    base_table.on_game_overed(self)
end

function maajan_table:on_process_start(player_count)
    base_table.on_process_start(self,player_count)
end

function maajan_table:on_process_over(reason)
    self:broadcast2client("SC_MaajanXueZhanFinalGameOver",{
        players = table.series(self.players,function(p,chair)
            return {
                chair_id = chair,
                guid = p.guid,
                score = p.total_score or 0,
                money = p.total_money or 0,
                statistics = table.series(p.statistics or {},function(c,t) return {type = t,count = c} end),
            }
        end),
    })

    local total_winlose = table.map(self.players,function(p) return p.guid,p.total_money or 0 end)

    self:cost_tax(total_winlose)

    for _,p in pairs(self.players) do
        p.total_money = nil
        p.round_money = nil
        p.total_score = nil
    end

    self.zhuang = nil
    self.cur_state_FSM = nil

	base_table.on_process_over(self,reason,{
        balance = total_winlose,
    })

    self:foreach(function(p)
        p.statistics = nil
    end)
end

function maajan_table:ding_zhuang()
    local function random_zhuang()
        local max_chair,_ = table.max(self.players,function(_,i) return i end)
        local chair
        repeat
            chair = math.random(1,max_chair)
            local p = self.players[chair]
        until p

        return chair
    end

    if not self.zhuang then
        self.zhuang = random_zhuang()
        return
    end

    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    if hu_count == 0 then
        return
    end

    local multi_paos = table.values(table.select(self.players,function(p) return p.multi_pao end))
    if table.nums(multi_paos) > 0 then
        local multi_pao_player = multi_paos[1]
        self.zhuang = multi_pao_player.chair_id
        return
    end

    local ps = table.values(self.players)
    table.sort(ps,function(l,r)
        if l.hu and not r.hu then return true end
        if not l.hu and r.hu then return false end
        if l.hu and r.hu then return l.hu.time < r.hu.time end
        return false
    end)

    log.dump(ps)

    self.zhuang = ps[1].chair_id
end

function maajan_table:tile_count_2_tiles(counts,excludes)
    local tiles = {}
    for t,c in pairs(counts) do
        local exclude_c = excludes and excludes[t] or 0
        for _ = 1,c - exclude_c do
            table.insert(tiles,t)
        end
    end

    return tiles
end

function maajan_table:load_lua_cfg()
	
end

-- 检查是否可取消准备
function maajan_table:can_stand_up(player, reason)
    log.info("maajan_table:can_stand_up guid:%s,reason:%s",player.guid,reason)
    if reason == enum.STANDUP_REASON_DISMISS or
        reason == enum.STANDUP_REASON_FORCE then
        return true
    end

    if reason == enum.STANDUP_REASON_OFFLINE and self.cur_state_FSM ~= nil then
        return false
    end

    return not self.cur_state_FSM
end

function maajan_table:is_play(...)
	return self.cur_state_FSM and self.cur_state_FSM ~= FSM_S.GAME_CLOSE and self.cur_state_FSM ~= FSM_S.PER_BEGIN
end

function maajan_table:clear_deposit_and_time_out(player)
    if player.deposit then
        player.deposit = false
        self:broadcast2client("SC_Maajan_Act_Trustee",{chair_id = player.chair_id,is_trustee = player.deposit})
    end
    player.time_out_count = 0
end

function maajan_table:increase_time_out_and_deposit(player)
    player.time_out_count = player.time_out_count or 0
    if player.time_out_count >= 2 then
        player.deposit = true
        player.time_out_count = 0
    end
end

function maajan_table:on_cs_do_action(player,msg)
    self:clear_deposit_and_time_out(player)
    
    local state_actions = {
        [FSM_S.PER_BEGIN] = {

        },
        [FSM_S.XI_PAI] = {

        },
        [FSM_S.WAIT_MO_PAI] = {

        },
        [FSM_S.WAIT_CHU_PAI] = {
            [ACTION.CHU_PAI] = self.on_action_chu_pai
        },
        [FSM_S.WAIT_ACTION_AFTER_CHU_PAI] = {
            [ACTION.PENG] = self.on_action_after_chu_pai,
            [ACTION.MING_GANG] = self.on_action_after_chu_pai,
            [ACTION.HU] = self.on_action_after_chu_pai,
            [ACTION.PASS] = self.on_action_after_chu_pai,
        },
        [FSM_S.WAIT_ACTION_AFTER_MO_PAI] = {
            [ACTION.AN_GANG] = self.on_action_after_mo_pai,
            [ACTION.BA_GANG] = self.on_action_after_mo_pai,
            [ACTION.PASS] = self.on_action_after_mo_pai,
            [ACTION.ZI_MO] = self.on_action_after_mo_pai,
        },
        [FSM_S.WAIT_QIANG_GANG_HU] = {
            [ACTION.HU] = self.on_action_qiang_gang_hu,
            [ACTION.PASS] = self.on_action_qiang_gang_hu,
        },
        [FSM_S.FINAL_END] = {

        },
    }

    local fn = state_actions[self.cur_state_FSM] and state_actions[self.cur_state_FSM][msg.action] or nil
    if fn then
        self.lock(fn,self,player,msg)
    else
        log.error("unkown state but got action %s",msg.action)
    end
end

--打牌
function maajan_table:on_cs_act_discard(player, msg)
    if msg and msg.tile and mj_util.check_tile(msg.tile) then
        self:clear_deposit_and_time_out(player)
    end
    self.lock(function() self:on_action_chu_pai(player,msg) end)
end

--过
function maajan_table:on_cs_act_pass(player, msg)
    self:clear_deposit_and_time_out(player)
end

--托管
function maajan_table:on_cs_act_trustee(player, msg)
    self:clear_deposit_and_time_out(player)
end

function maajan_table:on_cs_huan_pai(player,msg)
    self.lock(function() self:on_huan_pai(player,msg) end)
end

function maajan_table:on_cs_ding_que(player,msg)
    self.lock(function() self:on_ding_que(player,msg) end)
end

function maajan_table:chu_pai_player()
    return self.players[self.chu_pai_player_index]
end

function maajan_table:broadcast_player_hu(player,action)
    local msg = {
        chair_id = player.chair_id, value_tile = player.hu.tile,action = action,
    }

    self:broadcast2client("SC_Maajan_Do_Action",msg)
end

function maajan_table:update_state(new_state)
    self.cur_state_FSM = new_state
end

function maajan_table:is_action_time_out()
    local time_out = (os.time() - self.last_action_change_time_stamp) >= def.ACTION_TIME_OUT
    return time_out
end

function maajan_table:next_player_index(from)
    self:done_last_action(self.players[self.chu_pai_player_index])
    local chair = from and from.chair_id or self.chu_pai_player_index
    repeat
        chair = (chair % self.chair_count) + 1
        local p = self.players[chair]
    until p and not p.hu
    self.chu_pai_player_index = chair
    self:broadcast_discard_turn()
end

function maajan_table:jump_to_player_index(player)
    local chair_id = type(player) == "number" and player or player.chair_id
    self.chu_pai_player_index = chair_id
    self:broadcast_discard_turn()
end

function maajan_table:adjust_shou_pai(player, action, tile)
    local shou_pai = player.pai.shou_pai
    local ming_pai = player.pai.ming_pai

    if action == ACTION.AN_GANG then
        table.decr(shou_pai,tile,4)
        table.insert(ming_pai,{
            type = SECTION_TYPE.AN_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            time = os.time()
        })
    end

    if action == ACTION.MING_GANG then
        table.decr(shou_pai,tile,3)
        table.insert(ming_pai,{
            type = SECTION_TYPE.MING_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            whoee = self.chu_pai_player_index,
        })
    end

    if action == ACTION.BA_GANG then  --巴杠
        for k,s in pairs(ming_pai) do
            if s.tile == tile and s.type == SECTION_TYPE.PENG then
                table.insert(ming_pai,{
                    type = SECTION_TYPE.BA_GANG,
                    tile = tile,
                    area = TILE_AREA.MING_TILE,
                    whoee = s.whoee,
                    time = os.time(),
                })
                ming_pai[k] = nil
                table.decr(shou_pai,tile)
                break
            end
        end
    end

    if action == ACTION.PENG then
        table.decr(shou_pai,tile,2)
        table.insert(ming_pai,{
            type = SECTION_TYPE.PENG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            whoee = self.chu_pai_player_index,
        })
    end

    if action == ACTION.LEFT_CHI then
        table.decr(shou_pai,tile - 1)
        table.decr(shou_pai,tile - 2)
        table.insert(ming_pai,{
            type = SECTION_TYPE.LEFT_CHI,
            tile = tile,
            area = TILE_AREA.MING_TILE,
        })
    end

    if action == ACTION.MID_CHI then
        table.decr(shou_pai,tile - 1)
        table.decr(shou_pai,tile + 1)
        table.insert(ming_pai,{
            type = SECTION_TYPE.MID_CHI,
            tile = tile,
            area = TILE_AREA.MING_TILE,
        })
    end

    if action == ACTION.RIGHT_CHI then
        table.decr(shou_pai,tile + 1)
        table.decr(shou_pai,tile + 2)
        table.insert(ming_pai,{
            type = SECTION_TYPE.RIGHT_CHI,
            tile = tile,
            area = TILE_AREA.MING_TILE,
        })
    end

    self:broadcast2client("SC_Maajan_Do_Action",{chair_id = player.chair_id,value_tile = tile,action = action})
end

--掉线，离开，自动胡牌
function maajan_table:auto_act_if_deposit(player,actions)
    
end

function maajan_table:on_chu_pai(tile)
    for _, p in pairs(self.players) do
        if p.chair_id == self.chu_pai_player_index then
            p.chu_pai = tile
            p.chu_pai_count = p.chu_pai_count + 1
        else
            p.chu_pai = nil
        end
    end
end

function maajan_table:get_last_chu_pai()
    for _,p in pairs(self.players) do
        if p.chu_pai then
            return p,p.chu_pai
        end
    end
end

function maajan_table:send_data_to_enter_player(player,is_reconnect)
    local msg = {
        state = self.cur_state_FSM,
        round = self.cur_round,
        zhuang = self.zhuang,
        self_chair_id = player.chair_id,
        act_time_limit = def.ACTION_TIME_OUT,
        decision_time_limit = def.ACTION_TIME_OUT,
        is_reconnect = is_reconnect,
        pb_players = {},
    }

    self:foreach(function(v)
        local tplayer = {}
        tplayer.chair_id = v.chair_id
        if v.pai then
            tplayer.desk_pai = table.values(v.pai.desk_tiles)
            tplayer.pb_ming_pai = table.values(v.pai.ming_pai)
            tplayer.shou_pai = v.chair_id == player.chair_id and 
                self:tile_count_2_tiles(v.pai.shou_pai) or
                table.fill(nil,255,1,table.sum(v.pai.shou_pai))
        end

        if player.chair_id == v.chair_id then
            tplayer.mo_pai =  v.mo_pai
        end
        table.insert(msg.pb_players,tplayer)
    end)

    log.dump(msg)

    local last_chu_pai_player,last_tile = self:get_last_chu_pai()
    if is_reconnect  then
        msg.pb_rec_data = {
            last_chu_pai_chair = last_chu_pai_player and last_chu_pai_player.chair_id or nil,
            last_chu_pai = last_tile,
            total_scores = table.map(self.players,function(p) return p.chair_id,p.total_score end),
        }
    end

    if self.cur_round and self.cur_round > 0 then
        send2client_pb(player,"SC_Maajan_Desk_Enter",msg)
    end
end

function maajan_table:send_hu_status(player)
    local ps = table.values(self.players)
    table.sort(ps,function(l,r)
        if l.hu and not r.hu then return true end
        if not l.hu and r.hu then return false end
        if l.hu and r.hu then return l.hu.time < r.hu.time end
        return false
    end)

    local status = {}
    table.foreach(ps,function(p,i) 
        table.insert(status,{
            chair_id = p.chair_id,
            hu = p.hu and (p.hu.zi_mo and 2 or 1) or nil,
            hu_index = p.hu and i or nil,
            hu_tile = p.hu and p.hu.tile or nil,
        })
    end)

    send2client_pb(player,"SC_HuStatus",{
        status = status,
    })
end

function maajan_table:send_ding_que_status(player)
    local ding_que_status = {}
    local ding_que_info = {}
    if self.cur_state_FSM == FSM_S.DING_QUE then
        table.insert(ding_que_info,{
            chair_id = player.chair_id,
            men = player.que or -1,
        })
        self:foreach(function(p) 
            table.insert(ding_que_status,{
                chair_id = p.chair_id,
                done = p.que and true or false,
            })
        end)
    else
        self:foreach(function(p) 
            table.insert(ding_que_info,{
                chair_id = p.chair_id,
                men = p.que or -1,
            })
        end)
    end

    send2client_pb(player,"SC_DingQueStatus",{
        que_status = table.nums(ding_que_status) > 0 and ding_que_status or nil,
        que_info = ding_que_info,
    })
end

function maajan_table:send_huan_pai_status(player)
    local huan_status = {}
    self:foreach(function(p)
        table.insert(huan_status,{
            chair_id = p.chair_id,
            done = p.pai.huan and true or false,
        })
    end)

    send2client_pb(player,"SC_HuanPaiStatus",{
        self_choice = player.pai.huan and player.pai.huan.old or nil,
        status = huan_status,
    })
end

function maajan_table:reconnect(player)
    log.info("player reconnect : ".. player.chair_id)
    
    self:set_trusteeship(player)
    self:send_data_to_enter_player(player,true)

    if not self:is_play(player) then
        base_table.reconnect(self,player)
        return
    end


    if self.cur_state_FSM == FSM_S.FAST_START_VOTE then
        self:on_reconnect_when_fast_start_vote(player)
        base_table.reconnect(self,player)
        return
    end

    if self.cur_state_FSM == FSM_S.HUAN_PAI then
        self:on_reconnect_when_huan_pai(player)
    elseif self.cur_state_FSM == FSM_S.DING_QUE then
        self:on_reconnect_when_ding_que(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_CHU_PAI then
        self:on_reconnect_when_chu_pai(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_ACTION_AFTER_CHU_PAI then
        self:on_reconnect_when_action_after_chu_pai(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_ACTION_AFTER_MO_PAI then
        self:on_reconnect_when_action_after_mo_pai(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_QIANG_GANG_HU then
        self:on_reconnect_when_action_qiang_gang_hu(player)
    end

    self:send_hu_status(player)

    base_table.reconnect(self,player)
end

function maajan_table:begin_clock(timeout,player,total_time)
    if player then
        send2client_pb(player,"SC_TimeOutNotify",{
            left_time = math.ceil(timeout),
            total_time = total_time and math.floor(total_time) or nil,
        })
        return
    end

    self:broadcast2client("SC_TimeOutNotify",{
        left_time = timeout,
        total_time = total_time,
    })
end

function maajan_table:ext_hu(player,in_pai,mo_pai)
    local types = {}

    local chu_pai_player = self:chu_pai_player()
    if chu_pai_player == player and chu_pai_player.last_action and def.is_action_gang(chu_pai_player.last_action.action or 0) then
        types[HU_TYPE.GANG_SHANG_HUA] = 1
    end

    if self.rule.play.tian_di_hu then
        if player.chair_id == self.zhuang and mo_pai and self.mo_pai_count == 1 then
            types[HU_TYPE.TIAN_HU] = 1
        end

        if player.chair_id ~= self.zhuang and player.mo_pai_count <= 1 and player.chu_pai_count == 0 and table.nums(player.pai.ming_pai) == 0 then
            types[HU_TYPE.DI_HU] = 1
        end
    end

    if self.dealer.remain_count == 0 then
        types[HU_TYPE.HAI_DI_LAO_YUE] = 1
    end

    local is_zi_mo = mo_pai and true or false
    if self.rule.play.dgh_dian_pao and player.last_action and player.last_action.action == ACTION.MING_GANG then
        is_zi_mo = nil
    end

    if is_zi_mo and self.rule.play.zi_mo_jia_fan then
        types[HU_TYPE.ZI_MO] = 1
    end

    if chu_pai_player ~= player and chu_pai_player.last_action and def.is_action_gang(chu_pai_player.last_action.action) then
        types[HU_TYPE.GANG_SHANG_PAO] = 1
    end

    return types
end

function maajan_table:rule_hu(pai,in_pai,mo_pai)
    local private_conf = self:room_private_conf()
    local types = {}
    if not private_conf or not private_conf.play then
        types = mj_util.hu(pai,in_pai,mo_pai)
    else
        local play_opt = private_conf.play.option
        local hu_types = mj_util.hu(pai,in_pai,mo_pai)
        log.dump(hu_types)
        types = table.series(hu_types,function(ones)
            local ts = {}
            for t,c in pairs(ones) do
                if  (t == HU_TYPE.KA_WU_XING and not self.rule.play.jia_xin_5) or
                    (t == HU_TYPE.KA_ER_TIAO and not self.rule.play.ka_er_tiao) or
                    (t == HU_TYPE.QUAN_YAO_JIU and not self.rule.play.yao_jiu) or 
                    ((t == HU_TYPE.MEN_QING or t == HU_TYPE.DUAN_YAO) and not self.rule.play.men_qing) or 
                    -- ((t == HU_TYPE.QI_DUI or t == HU_TYPE.QING_QI_DUI or t == HU_TYPE.QING_LONG_BEI) and play_opt == "er_ren_yi_fang") or
                    ((t == HU_TYPE.SI_DUI or t == HU_TYPE.QING_SI_DUI or t == HU_TYPE.LONG_SI_DUI or t == HU_TYPE.QING_LONG_SI_DUI) and 
                        not self.rule.play.si_dui)
                then
                    
                elseif t == HU_TYPE.QING_DA_DUI and play_opt == "er_ren_yi_fang" then
                    ts[HU_TYPE.QING_YI_SE] = 1
                    ts[HU_TYPE.DA_DUI_ZI] = 1
                elseif t == HU_TYPE.JIANG_DUI and not self.rule.play.yao_jiu then
                    ts[HU_TYPE.DA_DUI_ZI] = c
                else
                    ts[t] = c
                end
            end

            return ts
        end)
    end


    local function get_types_info(ts)
        return table.sum(ts,function(_,t) return HU_TYPE_INFO[t].score end),
            table.sum(ts,function(_,t) return HU_TYPE_INFO[t].fan end)
    end

    table.sort(types,function(l,r)
        local lscore,lfan = get_types_info(l)
        local rscore,rfan = get_types_info(r)
        return lscore + 2 ^ lfan > rscore + 2 ^ rfan
    end)

    return types[1] or {}
end

function maajan_table:hu(player,in_pai,mo_pai)
    local rule_hu = self:rule_hu(player.pai,in_pai,mo_pai)
    local ext_hu = self:ext_hu(player,in_pai,mo_pai)
    return table.merge(rule_hu,ext_hu,function(l,r) return l or r end)
end

function maajan_table:is_hu(pai,in_pai)
    local si_dui = self.rule.play and self.rule.play.si_dui
    return mj_util.is_hu(pai,in_pai,si_dui)
end

function maajan_table:can_hu(player,in_pai)
    local room_private_conf = self:room_private_conf()
    if not room_private_conf.play then
        return self:is_hu(player.pai,in_pai)
    end

    local play_opt = room_private_conf.play.option
    if  not play_opt or 
        play_opt == "si_ren_liang_fang" or 
        play_opt == "er_ren_yi_fang" or 
        not self.rule.play.hu_at_least_2 then
        return self:is_hu(player.pai,in_pai)
    end

    local hu_types = self:hu(player,in_pai)
    if table.nums(hu_types) == 0 then
        return false
    end

    local score = table.sum(hu_types,function(c,t) return HU_TYPE_INFO[t].score end)
    local fan = table.sum(hu_types,function(c,t) return HU_TYPE_INFO[t].fan end)

    local gang = table.sum(player.pai.ming_pai,function(s)
        return (s.type == SECTION_TYPE.AN_GANG or s.type == SECTION_TYPE.MING_GANG or
                s.type == SECTION_TYPE.BA_GANG or s.type == SECTION_TYPE.FREE_BA_GANG or
                s.type == SECTION_TYPE.FREE_AN_GANG) and 1 or 0
    end)

    log.dump(gang)

    return  gang > 0 or score > 1 or fan > 0
end

function maajan_table:global_status_info()
    local seats = {}
    for chair_id,p in pairs(self.players) do
        table.insert(seats,{
            chair_id = chair_id,
            player_info = {
                guid = p.guid,
                icon = p.icon,
                nickname = p.nickname,
                sex = p.sex,
                longitude = p.gps_longitude,
                latitude = p.gps_latitude,
            },
            ready = self.ready_list[chair_id] and true or false,
            
        })
    end

    local private_conf = base_private_table[self.private_id]

    local info = {
        table_id = self.private_id,
        seat_list = seats,
        room_cur_round = self.cur_round or 0,
        rule = self.private_id and json.encode(self.rule) or "",
        game_type = def_first_game_type,
        template_id = private_conf and private_conf.template,
    }

    return info
end

return maajan_table