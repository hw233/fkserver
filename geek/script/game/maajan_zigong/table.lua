local base_table = require "game.lobby.base_table"
local def 		= require "game.maajan_zigong.base.define"
local mj_util 	= require "game.maajan_zigong.base.mang_jiang_util"
local log = require "log"
local json = require "json"
local maajan_tile_dealer = require "maajan_tile_dealer"
local base_private_table = require "game.lobby.base_private_table"
local enum = require "pb_enums"
local club_utils = require "game.club.club_utils"
local timer = require "timer"

require "functions"
local table = table
local string = string
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local strfmt = string.format

local FSM_S  = def.FSM_state

local ACTION = def.ACTION

local   ACTION_PRIORITY = {
    [ACTION.PASS] = 10,
    [ACTION.RUAN_PENG] = 6,
    [ACTION.RUAN_AN_GANG] = 5,
    [ACTION.RUAN_MING_GANG] = 5,
    [ACTION.RUAN_BA_GANG] = 5,
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
local TY_VALUE = mj_util.get_ty()
local all_tiles = {
    [1] = {
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,

    },
    [2] = {
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        37,37,37,37,
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
            tinsert(tiles,opt * 10 + i)
            tinsert(tiles,opt * 10 + i)
            tinsert(tiles,opt * 10 + i)
            tinsert(tiles,opt * 10 + i)
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
    self.textTitles = nil
end

function maajan_table:on_private_inited()
    self.cur_round = nil
    self.zhuang = nil
    self.game_tile_count = 13
    local room_private_conf = self:room_private_conf()
    if not room_private_conf then return end

    if not room_private_conf.chair_count_option then return end
    self.start_count = room_private_conf.chair_count_option[self.rule.room.player_count_option+1]
    log.dump(room_private_conf.chair_count_option)
    log.dump(self.start_count)
    if not room_private_conf.play then return end

    self.rule.play.cha_da_jiao = true
    self.rule.play.hai_di = true
    self.rule.play.tian_di_hu = true

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

function maajan_table:check_start()
    if self:is_play() then
        log.error("maajan_table:check_start is gaming %s",self:id())
        return
    end
    log.info("check_start self.start_count %d ",self.start_count)
    if table.nums(self.ready_list) == self.start_count then
        self:start(self.start_count)
    end
end

function maajan_table:on_started(player_count)
    self.start_count = player_count
    base_table.on_started(self,player_count)
    self.rule.play.cha_da_jiao = true
    self.rule.play.hai_di = true
    self.rule.play.tian_di_hu = true
    self.zhuang = not self.zhuang and self:first_zhuang() or self.zhuang
    self.zhuang_tian_hu = nil
    self.liuju = false
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
        v.piao = nil
        v.first_multi_pao = nil
        v.gzh = nil
        v.gsp = nil
        v.gsg = nil
        v.statistics = v.statistics or {}
        v.hupiaoscore = nil
        v.gangscore = nil
        v.niaoscore = nil
        v.huscore = nil
        v.baoting = nil
        v.baotingInfo = nil  -- 听牌数据
        v.luoboscore = nil
    end
    self.zhuang_first_chu_pai      = true
    self.mo_pai_player_last        = self.zhuang --摸最后一张牌的索引
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
        luobo_tiles = {}, -- { pai = nil}
        luobo_counts = {},        
    }
    local cardtype = self.rule.play.lai_zi and 2 or 1
    self.tiles = self.tiles or all_tiles[cardtype]
    self.dealer = maajan_tile_dealer:new(self.tiles)
    self.testLesttile = 0
    self.testcount = 0
    self.bTest = false
    local private_conf = self:room_private_conf()
    log.dump(private_conf,"private_conf")
    -- 萝卜
    self.luobo_tiles = {}       -- { pai = nil}
    self.zhong_luobos = {}
    self.zhong_luobo_counts = {}
    self.luobo_tiles_count = 0
    if self.rule.luobo then
        if self.rule.luobo.luobo_option == 0 then  -- 1个萝卜
            self.luobo_tiles_count = private_conf.luobo.luobo_option[self.rule.luobo.luobo_option + 1]
            log.info("选择萝卜数:luobo_tiles_count %d ",self.luobo_tiles_count)
        elseif self.rule.luobo.luobo_option == 1 then  -- 2个萝卜
            self.luobo_tiles_count = private_conf.luobo.luobo_option[self.rule.luobo.luobo_option + 1]
            log.info("选择萝卜数:luobo_tiles_count %d ",self.luobo_tiles_count)
        else
            log.warning("房间萝卜参数错误:luobo_option %d ",self.rule.luobo.luobo_option)
        end  
    end

    self:cancel_clock_timer()
    self:cancel_all_auto_action_timer()
    self:check_offline()
    self:check_trusteeship()
    -- 是否选择了飘，没有飘就直接洗牌发牌
    if self.rule.piao and self.rule.piao.piao_option ~= nil then    
        local td = self.rule.piao.piao_option     
        local piaoType = private_conf.piao.piao_option[self.rule.piao.piao_option + 1]
        if piaoType == 1 then -- 随飘
            log.info("随飘玩法,开始选飘")
            self:piao_fen()
        else                  -- 必飘
            self:update_state(FSM_S.PIAO_FEN)
            self:broadcast2client("SC_AllowPiaoFen",{})
            self:foreach(function(p)
                log.info("必飘玩法: %s,1",p.guid)
                self:on_piao_fen(p,{piao = 1})
            end)
        end 
    else
        -- 无漂开始洗牌发牌
        self:pre_begin()
        if self.rule.play.bao_jiao then -- 有报听玩法
            log.info("无飘,报听玩法,开始报听")
            self:baoting()
        else
            log.info("无飘,无报听玩法")
            self:jump_to_player_index(self.zhuang)
            self:action_after_piao_fen()
        end 
    end
end

function maajan_table:fast_start_vote_req(player)
    local player_count = table.sum(self.players,function(p) return 1 end)
    if player_count < 2 then
        send2client(player,"SC_VoteTableReq",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    self:lockcall(function() self:fast_start_vote(player) end)
end

function maajan_table:fast_start_vote_commit(p,msg)
    self:lockcall(function()
        local agree = msg.agree
        agree = agree and true or false
        if not self.vote_result[p.chair_id] then
            self.vote_result[p.chair_id] = agree
        end

        self:broadcast2client("SC_VoteTableCommit",{
            result = enum.ERROR_NONE,
            chair_id = p.chair_id,
            guid = p.guid,
            agree = agree,
        })

        if agree then
            if not table.And(self.players,function(_,chair) return self.vote_result[chair] ~= nil end) then
                return
            end
        end

        local all_agree = table.And(self.vote_result,function(a) return a end)
        self:broadcast2client("SC_VoteTable",{success = all_agree})
        if not all_agree then
            self:update_state(nil)
            self.co = nil
            return true
        end

        self:start(table.nums(self.players))
    end)
end

function maajan_table:on_reconnect_when_fast_start_vote(player)
    local status = {}
    for chair,r in pairs(self.vote_result) do
        local pi = self.players[chair]
        tinsert(status,{
            chair_id = pi.chair_id,
            guid = pi.guid,
            agree = r,
        })
    end

    send2client(player,"SC_VoteTableRequestInfo",{
        vote_type = "FAST_START",
        request_guid = player.guid,
        request_chair_id = player.chair_id,
        -- timeout= math.ceil(timer and timer.remainder or timeout),
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

    self.vote_result = {}

    self.vote_result[player.chair_id] = true
    self:broadcast2client("SC_VoteTableCommit",{
        result = enum.ERROR_NONE,
        chair_id = player.chair_id,
        guid = player.guid,
        agree = true,
    })

    self:begin_clock_timer(timeout,function()
        self:foreach(function(p)
            if self.vote_result[p.chair_id] == nil then
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

    if self.game_log then
        table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Trustee",trustee = trustee,time = timer.nanotime()})
    end
end

-- 检查玩家是否正在托管
function maajan_table:check_trusteeship()
    if not self.rule.trustee or table.nums(self.rule.trustee) == 0 then
        return 
    end
    self:foreach(function(p)
        if p.trustee and self.game_log then
            log.info("check_trusteeship add game_log player Trustee,guid:%d",p.guid)
            table.insert(self.game_log.action_table,{chair = p.chair_id,act = "Trustee",trustee = true,time = timer.nanotime()})
        end
    end) 
end

-- 检查玩家是否离线
function maajan_table:check_offline()
	self:foreach(function(p)
        log.dump(p.active,"check_player_active:" .. p.guid)
        if not p.active and self.game_log then
            log.info("add game_log player Offline,guid:%d",p.guid)
            table.insert(self.game_log.action_table,{chair = p.chair_id,act = "Offline",time = timer.nanotime()})
        end
    end)    
end

function maajan_table:on_offline(player)
	base_table.on_offline(self,player)
    if self.game_log then
	    table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Offline",time = timer.nanotime()})
    end
end

function maajan_table:on_reconnect(player)
	base_table.on_reconnect(self,player)
	if self.game_log then
		table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Reconnect",time = timer.nanotime()})
	end
end

function maajan_table:session()
    self.session_id = (self.session_id or 0) + 1
    return self.session_id
end

function maajan_table:xi_pai()
    self:update_state(FSM_S.XI_PAI)
    self:prepare_tiles()
    self:foreach(function(v)
        if v.chair_id == self.zhuang then
            local mo_pai = v.mo_pai -- self:choice_first_turn_mo_pai(v)
            log.dump(mo_pai,"choice_first_turn_mo_pai")
        end
        
        self:send_data_to_enter_player(v)
        self.game_log.players[v.chair_id].start_pai = self:tile_count_2_tiles(v.pai.shou_pai)
    end)
end

function maajan_table:on_reconnect_when_action_qiang_gang_hu(p)
    send2client(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    self:send_piao_fen_status(p)
    self:send_baoting_status(p)
    self:send_ting_tips(p)

    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,p)
    end
    
    for chair,actions in pairs(self.qiang_gang_actions or {}) do
        self:send_action_waiting(actions)
    end
end

function maajan_table:on_action_qiang_gang_hu(player,msg,auto)
    if self.cur_state_FSM ~= FSM_S.WAIT_QIANG_GANG_HU then
        log.error("maajan_table:on_action_qiang_gang_hu wrong state %s",self.cur_state_FSM)
        return
    end
    
    local done_action = self:check_action_before_do(self.qiang_gang_actions or {},player,msg)
    if not done_action then 
        log.error("on_action_qiang_gang_hu,no wait qiang gang action,%s",player.guid)
        return
    end
    self:cancel_auto_action_timer(player)
    done_action.done = { action = msg.action,auto = auto }
    local all_done = table.And(self.qiang_gang_actions or {},function(action) return action.done ~= nil end) 
    if not all_done then
        return
    end

    local target_act = done_action.target_action
    local qiang_tile = done_action.tile
    local chu_pai_player = self:chu_pai_player()
    local all_pass = table.And(self.qiang_gang_actions or {},function(action) return action.done.action == ACTION.PASS end)
    if all_pass then
        self.qiang_gang_actions = nil
        self:adjust_shou_pai(chu_pai_player,target_act,qiang_tile,done_action.session_id,done_action.substitute_num)
        chu_pai_player.statistics.ming_gang = (chu_pai_player.statistics.ming_gang or 0) + 1
        chu_pai_player.gzh = nil
        self:log_game_action(chu_pai_player,target_act,qiang_tile,false,done_action.substitute_num)
        self:done_last_action(chu_pai_player,{action = target_act,tile = qiang_tile,substitute_num = done_action.substitute_num})
        self:mo_pai()
        return
    end

    self:log_failed_game_action(chu_pai_player,target_act,qiang_tile,false,done_action.substitute_num)
    local qiang_hu_count = table.sum(self.qiang_gang_actions or {},function(waiting)
        return (waiting.done and waiting.done.action & (ACTION.QIANG_GANG_HU | ACTION.HU)) and 1 or 0
    end)
    local hu_count_before = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    chu_pai_player.first_multi_pao = (hu_count_before == 0 and qiang_hu_count > 1) or nil
    local decrfalg= false 
    local function do_qiang_gang_hu(p,action)
        local act = action.done.action
        local done_action_tile = action.tile
        p.hu = {
            time = timer.nanotime(),
            tile = done_action_tile,
            types = self:hu(p,done_action_tile,nil,true),
            zi_mo = false,
            whoee = self.chu_pai_player_index,
            qiang_gang = true,
        }

        self:log_game_action(p,act,done_action_tile,action.done.auto,action.substitute_num)
        self:broadcast_player_hu(p,act,action.target,nil,action.substitute_num)
        p.statistics.hu = (p.statistics.hu or 0) + 1
        chu_pai_player.statistics.dian_pao = (chu_pai_player.statistics.dian_pao or 0) + 1
        if not decrfalg then 
            table.decr(chu_pai_player.pai.shou_pai,(action.substitute_num == 0) and done_action_tile or TY_VALUE)
            decrfalg = true 
        end 
        self:done_last_action(p,{action = act,tile = done_action_tile,substitute_num = action.substitute_num })
    end

    table.foreach(self.qiang_gang_actions or {},function(action,chair)
        local done_act = action.done.action
        if (done_act & (ACTION.QIANG_GANG_HU | ACTION.HU)) > 0 then
            local p = self.players[chair]
            do_qiang_gang_hu(p,action)
        end
    end)

    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    if self.start_count - hu_count == 1 then
        self:do_balance()
        return
    end

    local _,last_hu_chair = table.max(self.qiang_gang_actions or {},function(_,c) return c end)
    local last_hu_player = self.players[last_hu_chair]
    self:next_player_index(last_hu_player)
    self:mo_pai()
end

function maajan_table:qiang_gang_hu(actions)
    self:update_state(FSM_S.WAIT_QIANG_GANG_HU)
    self.qiang_gang_actions = actions
    for _,action in pairs(actions) do
        self:send_action_waiting(action)
    end

    table.insert(self.game_log.action_table,{
        act = "WaitActions",
        data = table.series(actions,function(v)
            return {
                chair_id = v.chair_id,
                session_id = v.session_id,
                actions = self:series_action_map(v.actions),
            }
        end),
        time = timer.nanotime()
    })
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_action(p,action)
            self:lockcall(function()
                self:on_action_qiang_gang_hu(p,{
                    action = ACTION.QIANG_GANG_HU,
                    value_tile = action.tile,
                    session_id = action.session_id,
                },true)
            end)
        end

        log.dump(self.qiang_gang_actions)
        self:begin_clock_timer(trustee_seconds,function()
            table.foreach(self.qiang_gang_actions,function(action,_)
                if action.done then return end

                local p = self.players[action.chair_id]
                self:set_trusteeship(p,true)
                auto_action(p,action)
            end)
        end)

        table.foreach(self.qiang_gang_actions,function(action,_) 
            local p = self.players[action.chair_id]
            if not p.trustee then return end

            self:begin_auto_action_timer(p,math.random(1,2),function() 
                auto_action(p,action)
            end)
        end)
    end
end

function maajan_table:on_reconnect_when_piao_fen(player)
    -- local leftcount = self.dealer.remain_count and self.dealer.remain_count or (self.rule.play.lai_zi and 76 or 72)
    -- send2client(player,"SC_Maajan_Tile_Left",{tile_left = leftcount,})
    self:send_piao_fen_status(player)
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

function maajan_table:on_piao_fen(player,msg)
    if self.cur_state_FSM ~= FSM_S.PIAO_FEN then
        log.error("maajan_table:on_piao_fen error state %s,guid:%s",self.cur_state_FSM,player.guid)
        return
    end

    if player.piao ~= nil then
        log.error("maajan_table:on_piao_fen repeated %s,guid:%s",msg.piao,player.guid)
        send2client(player,"SC_PiaoFen",{
            result = enum.ERROR_OPERATION_REPEATED
        })
        return
    end

    player.piao = msg.piao
    log.info("player on_piao_fen guid:%d, piaofen:%d ",player.guid,player.piao)
    self:broadcast2client("SC_PiaoFen",{
        result = enum.ERROR_NONE,
        status = {
            chair_id = player.chair_id,
            done = true,
        }
    })

    self:cancel_auto_action_timer(player)

    if not table.And(self.players,function(p) return p.piao ~= nil end) then
        return
    end

    self:cancel_clock_timer()
    
    local log_players = self.game_log.players
    local p_piaos = {}
    self:foreach(function(p)
        log_players[p.chair_id].piao = p.piao
        tinsert(p_piaos,{
            chair_id = p.chair_id,
            piao = p.piao,
        })
    end)

    self:broadcast2client("SC_PiaoFenCommit",{
        piao_fens = p_piaos,
    })
    
    -- 漂分后开始洗牌发牌
    self:pre_begin()
    if self.rule.play.bao_jiao then -- 有报听玩法
        log.info("报听玩法,开始报听")
        self:baoting()
    else
        self:jump_to_player_index(self.zhuang)
        self:action_after_piao_fen()
    end    
end

function maajan_table:piao_fen()
    self:update_state(FSM_S.PIAO_FEN)
    self:broadcast2client("SC_AllowPiaoFen",{})

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type and (trustee_type == 1 or (trustee_type == 2 and self.cur_round > 1))  then
        local function auto_piao_fen(p)
            local min_piao = 0
            log.info("%d",min_piao)
            self:on_piao_fen(p,{
                piao = min_piao
            })
        end
        self:begin_clock_timer(trustee_seconds,function()
            self:foreach(function(p)
                if p.piao then return end
                if p.piao ~= nil then return end
                self:set_trusteeship(p,true)
                auto_piao_fen(p)
            end)
        end)

        log.dump(table.series(self.players,function(p) return p.guid end))
        self:foreach(function(p)
            log.info("%s,%s",p.guid,p.trustee)
            if not p.trustee then return end
            self:begin_auto_action_timer(p,math.random(1,2),function() 
                auto_piao_fen(p)
            end)
        end)
    end
end

function maajan_table:on_action_after_mo_pai(player,msg,auto)
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
    local substitute_num = msg.substitute_num or 0 
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

    local waiting = self.waiting_actions[player.chair_id]

    local session_id = waiting.session_id

    local player_actions = self.waiting_actions[player.chair_id].actions
    if not player_actions[do_action] and do_action ~= ACTION.PASS and do_action ~= ACTION.CHU_PAI then
        log.error("do action %s,but action is illigle,%s",do_action)
        return
    end
    self.waiting_actions = {}
    self.zhuang_first_chu_pai = false
    if (do_action & (ACTION.BA_GANG | ACTION.FREE_BA_GANG | ACTION.RUAN_BA_GANG)) > 0 then
        local qiang_gang_hu = {}
        self:foreach_except(player,function(p)
            if p.hu then return end

            local actions = self:get_actions(p,nil,tile,true)
            if not actions[ACTION.HU] then return end

            qiang_gang_hu[p.chair_id] = {
                chair_id = p.chair_id,
                target = chair_id,
                target_action = do_action,
                tile = tile,
                substitute_num  =substitute_num ,
                actions = {
                    [ACTION.QIANG_GANG_HU] = actions[ACTION.HU]
                },
                session_id = self:session(),
            }
        end)

        if table.nums(qiang_gang_hu) > 0 then
            send2client(player,"SC_Maajan_Do_Action_Commit",{
                action = do_action,
                chair_id = player.chair_id,
                session_id = msg.session_id,
            })
            
            self:qiang_gang_hu(qiang_gang_hu)
            return
        end

        self:log_game_action(player,do_action,tile,auto,substitute_num)
        self:adjust_shou_pai(player,do_action,tile,session_id,substitute_num)
        self:clean_gzh(player)
        self:jump_to_player_index(player)
        player.statistics.ming_gang = (player.statistics.ming_gang or 0) + 1
        self:mo_pai()
    end

    if do_action == ACTION.AN_GANG or do_action == ACTION.RUAN_AN_GANG  then
        self:clean_gzh(player)
        self:adjust_shou_pai(player,do_action,tile,session_id,substitute_num)
        self:log_game_action(player,do_action,tile,auto,substitute_num)
        self:jump_to_player_index(player)
        player.statistics.an_gang = (player.statistics.an_gang or 0) + 1
        self:mo_pai()
    end
    if do_action == ACTION.GANG_HUAN_PAI then
        self:clean_gzh(player)
        self:adjust_shou_pai(player,do_action,tile,session_id)
        self:log_game_action(player,do_action,tile,auto)
        self:jump_to_player_index(player)
        self:action_after_gang_huan_pai()
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
            time = timer.nanotime(),
            tile = tile,
            types = self:hu(player,nil,player.mo_pai),
            zi_mo = is_zi_mo,
            whoee = whoee,
        }

        player.statistics.zi_mo = (player.statistics.zi_mo or 0) + 1

        self:log_game_action(player,do_action,tile,auto)
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
        send2client(player,"SC_Maajan_Do_Action",{
            action = do_action,
            chair_id = player.chair_id,
            session_id = msg.session_id,
        })
        self:chu_pai()
        return
    end

    self:done_last_action(player,{action = do_action,tile = tile,substitute_num = substitute_num})
end

function maajan_table:on_reconnect_when_action_after_mo_pai(p)
    self:send_piao_fen_status(p)
    self:send_baoting_status(p)
    send2client(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})

    local action = self.waiting_actions[p.chair_id]
    if action and not action.done then
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

    table.insert(self.game_log.action_table,{
        act = "WaitActions",
        data = table.series(waiting_actions,function(v)
            return {
                chair_id = v.chair_id,
                session_id = v.session_id,
                actions = self:series_action_map(v.actions),
            }
        end),
        time = timer.nanotime()
    })

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_action(p,action)
            local act = action.actions[ACTION.ZI_MO] and ACTION.ZI_MO or ACTION.PASS
            local tile = p.mo_pai
            self:lockcall(function()
                self:on_action_after_mo_pai(p,{
                    action = act,
                    value_tile = tile,
                    session_id = action.session_id,
                },true)
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
function maajan_table:choice_gang_huan_pai_mo_pai(player)
    player.mo_pai = TY_VALUE
    return TY_VALUE
end
function maajan_table:action_after_piao_fen()
    local player = self:chu_pai_player()

    local mo_pai = player.mo_pai -- self:choice_first_turn_mo_pai(player)
    -- log.dump(mo_pai)

    log.info("---------fake mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})

    local actions = self:get_actions_first_turn(player,mo_pai)
    log.dump(actions,"action_after_piao_fen_"..player.guid)
    if table.nums(actions) > 0 then
        self:action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
                session_id = self:session(),
            },
        })
    else
        self:chu_pai()
    end
end
function maajan_table:action_after_gang_huan_pai()
    local player = self:chu_pai_player()

    local mo_pai = self:choice_gang_huan_pai_mo_pai(player)
    log.dump(mo_pai)

    log.info("---------action_after_gang_huan_pai  mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})

    local actions = self:get_actions_gang_huan_pai(player,mo_pai)
    log.dump(actions)
    if table.nums(actions) > 0 then
        self:action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
                session_id = self:session(),
            },
        })
    else
        self:chu_pai()
    end
end
function maajan_table:on_reconnect_when_action_after_chu_pai(p)
    send2client(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    self:send_piao_fen_status(p)
    self:send_baoting_status(p)
    local action = self.waiting_actions[p.chair_id]
    if action and not action.done then
        self:send_action_waiting(action)
    end
    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,p)
    end
end

function maajan_table:on_action_after_chu_pai(player,msg,auto)
    if not self.waiting_actions then
        log.error("maajan_table:on_action_after_chu_pai not waiting actions,%s",player.guid)
        return
    end

    local action = self:check_action_before_do(self.waiting_actions,player,msg)
    
    if action then
        local done_action = msg.action
        action.done = {
            action = done_action,
            tile = msg.value_tile,
            auto = auto,
            substitute_num = msg.substitute_num or 0
        }
        local chair = action.chair_id
        self:cancel_auto_action_timer(self.players[chair])

        if done_action == ACTION.PASS then
            send2client(player,"SC_Maajan_Do_Action",{
                action = done_action,
                chair_id = player.chair_id,
                session_id = msg.session_id,
            })
        end
    else 
        log.error("do action %s error, player guid %s",msg.action,player.guid)
        log.dump(player.pai.shou_pai)
        return
    end

    local hu_action_count = table.sum(self.waiting_actions,function(action)
        return action.actions[ACTION.HU] and 1 or 0
    end)

    local hu_done_count = table.sum(self.waiting_actions,function(action)
        return (action.actions[ACTION.HU] and action.done ~= nil) and 1 or 0
    end)

    local hu_count = table.sum(self.waiting_actions,function(action)
        return (action.done ~= nil and action.done.action == ACTION.HU) and 1 or 0
    end)

    if  hu_action_count == 0 or
        hu_action_count > hu_done_count or
        hu_count == 0
    then
        if not table.And(self.waiting_actions,function(action) return action.done ~= nil end) then
            send2client(player,"SC_Maajan_Do_Action_Commit",{
                action = msg.action,
                chair_id = player.chair_id,
                session_id = msg.session_id,
            })
            return
        end
    end

    self:cancel_clock_timer()

    local all_actions = table.series(self.waiting_actions,function(action)
        return action.done ~= nil and action or nil
    end)

    self.waiting_actions = nil

    table.sort(all_actions,function(l,r)
        if ACTION_PRIORITY[l.done.action] == ACTION_PRIORITY[r.done.action] and  (l.done.action ==ACTION.RUAN_MING_GANG or l.done.action ==ACTION.RUAN_PENG)  then 
            if l.done.substitute_num ==  r.done.substitute_num then
                return self:check_chair_closer(l.chair_id,r.chair_id)
            else
                return  l.done.substitute_num < r.done.substitute_num
            end 
        else
            return ACTION_PRIORITY[l.done.action] < ACTION_PRIORITY[r.done.action]
        end 
    end)

    local top_action = all_actions[1]
    local top_session_id = top_action.session_id
    local top_done_act = top_action.done.action
    local chu_pai_player = self:chu_pai_player()
    local player = self.players[top_action.chair_id]
    if not player then
        log.error("do action %s,nil player in chair %s",top_action.done.action,top_action.chair_id)
        return
    end

    local function check_all_pass(actions)
        for _,act in pairs(actions) do
            if act.done.action == ACTION.PASS then
                local p = self.players[act.chair_id]
                if self.rule.play.guo_zhuang_hu then
                    local hu_action = act.actions[ACTION.HU]
                    if hu_action then
                        self:set_gzh_on_pass(p,chu_pai_player.chu_pai)
                    end
                end
    
                if self.rule.play.guo_shou_peng then
                    local peng_action = act.actions[ACTION.PENG]
                    local ruan_peng_action = act.actions[ACTION.RUAN_PENG]
                    if peng_action or ruan_peng_action then
                        self:set_gsp_on_pass(p,chu_pai_player.chu_pai)
                    end
                end

                if self.rule.play.guo_shou_gang then
                    local ruan_ming_gang_action = act.actions[ACTION.RUAN_MING_GANG]
                    if ruan_ming_gang_action then
                        self:set_gsg_on_pass(p,chu_pai_player.chu_pai)
                    end
                end
            elseif act.done.action ~= ACTION.HU and act.actions[ACTION.HU] then
                local p = self.players[act.chair_id]
                if self.rule.play.guo_zhuang_hu then
                    local hu_action = act.actions[ACTION.HU]
                    if hu_action then
                        self:set_gzh_on_pass(p,chu_pai_player.chu_pai)
                    end
                end
            end
        end
    end

    local tile = top_action.done.tile
    local substitute_num = top_action.done.substitute_num or 0
    if top_done_act == ACTION.PENG or top_done_act == ACTION.RUAN_PENG then
        self:clean_gzh(player)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,top_session_id,substitute_num)
        self:log_game_action(player,top_done_act,tile,top_action.done.auto,substitute_num)
        check_all_pass(all_actions)
        self:jump_to_player_index(player)
        self:chu_pai()
    end
    if def.is_action_gang(top_done_act) then
        self:clean_gzh(player)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,top_session_id,substitute_num)
        self:log_game_action(player,top_done_act,tile,top_action.done.auto,substitute_num)
        check_all_pass(all_actions)
        self:jump_to_player_index(player)
        self:mo_pai()
        player.statistics.ming_gang = (player.statistics.ming_gang or 0) + 1
    end

    if top_done_act == ACTION.HU then
        local hu_actions = table.series(all_actions,function(act) return act.done.action == ACTION.HU and act or nil end)
        local hu_count_before = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
        if table.nums(hu_actions) > 1 and hu_count_before == 0 then
            chu_pai_player.first_multi_pao = true
        end

        for _,act in pairs(hu_actions) do
            local p = self.players[act.chair_id]
            p.hu = {
                time = timer.nanotime(),
                tile = tile,
                types = self:hu(p,tile),
                zi_mo = false,
                whoee = self.chu_pai_player_index,
            }

            if chu_pai_player.last_action and def.is_action_gang(chu_pai_player.last_action.action) then
                local pai = chu_pai_player.pai
                for _,s in pairs(pai.ming_pai) do
                    if s.tile == chu_pai_player.last_action.tile and def.is_section_gang(s.type) then
                        s.dian_pao = act.chair_id   -- 杠上炮，转雨
                    end
                end
            end

            self:log_game_action(p,act.done.action,tile,act.done.auto)
            self:broadcast_player_hu(p,act.done.action,act.session_id)
            p.statistics.hu = (p.statistics.hu or 0) + 1
            chu_pai_player.statistics.dian_pao = (chu_pai_player.statistics.dian_pao or 0) + 1
        end

        table.pop_back(chu_pai_player.pai.desk_tiles)

        check_all_pass(all_actions)

        local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
        if self.start_count - hu_count == 1 then
            self:do_balance()
        else
            local _,last_hu_chair = table.max(hu_actions,function(act) return act.chair_id end)
            local last_hu_player = self.players[last_hu_chair]
            self:next_player_index(last_hu_player)
            self:mo_pai()
        end
    end

    if top_done_act == ACTION.PASS then
        check_all_pass(all_actions)
        self:next_player_index()
        self:mo_pai()
        return
    end

    self:done_last_action(player,{action = top_done_act,tile = tile,substitute_num = substitute_num})
end

function maajan_table:action_after_chu_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_CHU_PAI)
    self.waiting_actions = waiting_actions
    for _,action in pairs(self.waiting_actions) do
        self:send_action_waiting(action)
    end

    table.insert(self.game_log.action_table,{
        act = "WaitActions",
        data = table.series(waiting_actions,function(v)
            return {
                chair_id = v.chair_id,
                session_id = v.session_id,
                actions = self:series_action_map(v.actions),
            }
        end),
        time = timer.nanotime()
    })

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_action(p,action)
            log.warning("auto action %s",p.guid)
            log.dump(action)
            local act = action.actions[ACTION.HU] and ACTION.HU or ACTION.PASS
            local tile = self:chu_pai_player().chu_pai
            self:lockcall(function()
                self:on_action_after_chu_pai(p,{
                    action = act,
                    value_tile = tile,
                    session_id = action.session_id,
                },true)
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
        self.liuju = true
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

    player.gzh = nil
    player.gsp = nil
    player.gsg = nil
    player.mo_pai = mo_pai
    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    player.mo_pai_count = (player.mo_pai_count or 0) + 1
end

function maajan_table:clean_gzh(player)
    player.gzh = nil
end

function maajan_table:set_gzh_on_pass(passer,tile)
    passer.gzh = passer.gzh or {}
    local gzh = passer.gzh
    local hu_tiles = self:ting(passer)
    local block_tile_fan = table.map(hu_tiles or {},function(_,tile)
        return tile,self:hu_fan(passer,tile)
    end)
    
    local block_fan = block_tile_fan[tile]
    if block_fan then
        for tile,fan in pairs(block_tile_fan) do
            if fan <= block_fan then
                gzh[tile] = fan
            end
        end
    end
    log.dump(gzh,"set_gzh_on_pass")
end

function maajan_table:is_in_gzh(player,tile)
    return player.gzh and player.gzh[tile]
end

function maajan_table:clean_gsp(player)
    player.gsp = nil
end

function maajan_table:set_gsp_on_pass(passer,tile)
    passer.gsp = passer.gsp or {}
    passer.gsp[tile] = true
end
function maajan_table:is_in_gsp(player,tile)
    return player.gsp and player.gsp[tile]
end

function maajan_table:clean_gsg(player)
    player.gsg = nil
end

function maajan_table:set_gsg_on_pass(passer,tile)
    passer.gsg = passer.gsg or {}
    passer.gsg[tile] = true
end
function maajan_table:is_in_gsg(player,tile)
    return player.gsg and player.gsg[tile]
end

function maajan_table:mo_pai()
    self:update_state(FSM_S.WAIT_MO_PAI)
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai

    self:clean_gzh(player)
    self:clean_gsp(player)
    self:clean_gsg(player)
    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 0 then
        self.liuju = true
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

    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    
    table.incr(shou_pai,mo_pai)
    log.info("---------mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = "Draw",msg = {tile = mo_pai}})
    self:on_mo_pai(player,mo_pai)

    local actions = self:get_actions(player,mo_pai)
    log.dump(actions,"mo_pai_"..player.guid)
    if table.nums(actions) > 0 then
        self:action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
                session_id = self:session(),
            }
        })
    else
        self:chu_pai()
    end
end

function maajan_table:ting(p)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local lai_zi = self.rule.play and self.rule.play.lai_zi
    local ting_tiles = mj_util.is_ting(p.pai,si_dui,lai_zi) or {}

    return ting_tiles
end

function maajan_table:ting_full(p)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local lai_zi = self.rule.play and self.rule.play.lai_zi
    local ting_tiles = mj_util.is_ting_full(p.pai,si_dui,lai_zi)

    return ting_tiles
end

function maajan_table:broadcast_discard_turn()
    self:broadcast2client("SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
end

function maajan_table:broadcast_wait_discard(player)
    local chair_id = type(player) == "table" and player.chair_id or player
    self:broadcast2client("SC_MaajanWaitingDiscard",{chair_id = chair_id})
end

function maajan_table:on_action_chu_pai(player,msg,auto)
    if self.cur_state_FSM ~= FSM_S.WAIT_CHU_PAI then
        log.error("maajan_table:on_action_chu_pai state error %s",self.cur_state_FSM)
        return
    end

    if self.chu_pai_player_index ~= player.chair_id then
        log.error("maajan_table:on_action_chu_pai chu_pai_player %s ~= %s",player.chair_id,self.chu_pai_player_index)
        return
    end

    local chu_pai_val = msg.tile

    if not mj_util.check_tile(chu_pai_val) then -- or chu_pai_val ==  TY_VALUE
        log.error("player %s chu_pai,tile invalid error:%s",self.chu_pai_player_index,chu_pai_val)
        return
    end

    local shou_pai = player.pai.shou_pai
    if not shou_pai[chu_pai_val] or shou_pai[chu_pai_val] == 0 then
        log.error("tile isn't exist when chu guid:%s,tile:%s",player.guid,chu_pai_val)
        return
    end
    -- 报听玩家出牌校验
    if player.baoting then
        if not self:iscandiscard(player,chu_pai_val,player.mo_pai) then
            log.error("player discard isn't baoting when chu guid:%s,tile:%s",player.guid,chu_pai_val)
            return
        end
    end
    self.zhuang_first_chu_pai = false
    self:cancel_clock_timer()
    self:cancel_all_auto_action_timer()

    log.info("---------chu pai guid:%s,chair: %s,tile:%s ------",player.guid,self.chu_pai_player_index,chu_pai_val)
    shou_pai[chu_pai_val] = shou_pai[chu_pai_val] - 1
    self:on_chu_pai(chu_pai_val)
    tinsert(player.pai.desk_tiles,chu_pai_val)
    self:broadcast2client("SC_Maajan_Action_Discard",{chair_id = player.chair_id, tile = chu_pai_val})
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = "Discard",msg = {tile = chu_pai_val},auto = auto,time = timer.nanotime()})

    local waiting_actions = {}
    if chu_pai_val ~= TY_VALUE then -- 打出癞子牌不可碰扛胡
        self:foreach(function(v)
            if v.hu then return end
            if player.chair_id == v.chair_id then 
                -- 自己出牌,判断自己打出的这张牌自己是否能碰胡(过庄胡、过手碰)需要
                log.info("--- get_selfactionsAndset_pass  guid:%s,chair: %s,tile:%s ------",player.guid,self.chu_pai_player_index,chu_pai_val)
                local selfactions = self:get_selfactionsAndset_pass(v,chu_pai_val)
                log.dump(selfactions,"get_selfactionsAndset_pass guid_"..player.guid)
                return 
            end
    
            local actions = self:get_actions(v,nil,chu_pai_val)
            if table.nums(actions) > 0 then
                waiting_actions[v.chair_id] = {
                    chair_id = v.chair_id,
                    actions = actions,
                    session_id = self:session(),
                }
            end
        end)
    end
    
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
    if table.nums(ting_tiles) > 0 then
        local pai = p.pai
        local discard_tings = table.series(ting_tiles,function(tiles,discard)
            table.decr(pai.shou_pai,discard)
            local tings = table.series(tiles,function(_,tile) return {tile = tile,fan = self:hu_fan(p,tile)} end)
            table.incr(pai.shou_pai,discard)
            return { discard = discard, tiles_info = tings, }
        end)
        log.dump(discard_tings,"discard_tings_"..p.guid)
        send2client(p,"SC_TingTips",{
            ting = discard_tings
        })
    end
end

function maajan_table:on_reconnect_when_chu_pai(p)
    send2client(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    self:send_piao_fen_status(p)
    self:send_baoting_status(p)
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
            
            if not chu_tile or not p.pai.shou_pai[chu_tile] or p.pai.shou_pai[chu_tile] <= 0 then -- or chu_tile==TY_VALUE
                local c
                repeat
                    chu_tile,c = table.choice(p.pai.shou_pai)
                until c > 0
            end

            log.info("auto_chu_pai chair_id %s,tile %s",p.chair_id,chu_tile)
            self:lockcall(function()
                self:on_action_chu_pai(p,{
                    tile = chu_tile,
                },true)
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
    return self.room_.conf.private_conf.fan.max_option[fan_opt] or 3
end
function maajan_table:get_add_score()
    local fan_opt = self.rule.fan.chaoFan or 0
    return self.room_.conf.private_conf.fan.add_score[fan_opt] or 0
end
function maajan_table:waluobo()
    log.dump(self.luobo_tiles,"luobo_tiles_count_"..self.luobo_tiles_count)
    self:foreach(function(v)
        local zhongluobo = nil
        if not self.zhong_luobos[v.chair_id] then
            self.zhong_luobos[v.chair_id] = {}
        end
        if v.pai then
            log.dump(v.pai.shou_pai,"waluobo_shou_pai_"..v.guid)
            log.dump(v.pai.ming_pai,"waluobo_ming_pai_"..v.guid)
            for _, luobo_tile in pairs(self.luobo_tiles) do
                if v.pai.shou_pai[luobo_tile.pai] then
                    if not zhongluobo then zhongluobo = {} end
                    for i = 1, v.pai.shou_pai[luobo_tile.pai], 1 do
                        tinsert(self.zhong_luobos[v.chair_id],luobo_tile.pai)
                    end
                end
                for _, s in pairs(v.pai.ming_pai) do
                    if s.tile == luobo_tile.pai then
                        if s.type == SECTION_TYPE.AN_GANG or s.type == SECTION_TYPE.MING_GANG  or 
                           s.type == SECTION_TYPE.RUAN_AN_GANG or s.type == SECTION_TYPE.RUAN_MING_GANG then
                            local num = s.substitute_num and (4 - s.substitute_num) or 4
                            for i = 1, num, 1 do
                                tinsert(self.zhong_luobos[v.chair_id],luobo_tile.pai)
                            end
                        elseif s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.RUAN_PENG then
                            local num = s.substitute_num and (3 - s.substitute_num) or 3
                            for i = 1, num, 1 do
                                tinsert(self.zhong_luobos[v.chair_id],luobo_tile.pai)
                            end
                        end
                    elseif luobo_tile.pai == TY_VALUE and s.substitute_num then
                        for i = 1, s.substitute_num, 1 do
                            tinsert(self.zhong_luobos[v.chair_id],luobo_tile.pai)
                        end
                    end
                end                               
                if v.hu and v.hu.tile and not v.hu.zi_mo then   
                    log.info("hu:guid:%d,tale:%d,luobo_tile.pai %d",v.guid,v.hu.tile,luobo_tile.pai)                 
                    if v.hu.tile == luobo_tile.pai then
                        tinsert(self.zhong_luobos[v.chair_id],luobo_tile.pai)
                    end
                end 
            end            
        end
    end)
    log.dump(self.zhong_luobos,"zhong_luobos")
end

function maajan_table:do_balance()    
    self:waluobo()
    local typefans,fanscores = self:game_balance()
    log.dump(typefans,"do_balance_typefans")
    log.dump(fanscores,"do_balance_fanscores")
    local msg = {
        players = {},
        player_balance = {},
        luobos = {},
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
    local wei_hu_count = table.sum(self.players,function(p) return (not p.hu) and 1 or 0 end)
    local jiao_count = table.sum(self.players,function(p) return p.jiao and 1 or 0 end)
    local wei_jiao_count = table.sum(self.players,function(p) return (not p.hu and not p.jiao) and 1 or 0 end)
    log.info("do_balance wei_hu_count %d,jiao_count %d,wei_jiao_count %d",wei_hu_count,jiao_count,wei_jiao_count)
    local hufan = 0
    local chair_money = {}
    for chair_id,p in pairs(self.players) do
        tinsert(self.zhong_luobo_counts,self:get_luobo(chair_id))
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

        tinsert(msg.players,{
            chair_id = chair_id,
            desk_pai = desk_pai,
            shou_pai = shou_pai,
            pb_ming_pai = ming_pai,
        })
        hufan = 0
        if p.hu then
            hufan = (p.piao and p.piao > 0) and (fanscores[chair_id].fan + 1) or fanscores[chair_id].fan
        elseif p.jiao and wei_hu_count >= 2 then
            if (p.piao and p.piao > 0) and jiao_count > 0 and wei_jiao_count > 0 then
                hufan = fanscores[chair_id].fan + 1
            else
                hufan = fanscores[chair_id].fan
            end            
        end
        tinsert(msg.player_balance,{
            chair_id = chair_id,
            total_score = p.total_score,
            round_score = p_score,
            items = typefans[chair_id],
            hu_tile = p.hu and p.hu.tile or nil,
            hu_fan = hufan ,
            hu = p.hu and (p.hu.zi_mo and 2 or 1) or nil,
            status = p.hu and 2 or ((p.jiao and jiao_count > 0 and wei_jiao_count > 0) and 1 or nil),
            hu_index = p.hu and p.hu.index or nil,
            piao    		= p.piao,	    -- 选择的飘分	
            gang_score		= p.gangscore,	-- 杠分
            luobo_score	    = p.luoboscore,	-- 萝卜分
            hu_score        = p.huscore,    -- 胡分
            baoting    		= p.baoting,	-- 是否选择报叫
            luobo_count     = self.zhong_luobo_counts[chair_id],
        })
        
        local win_money = self:calc_score_money(p_score)
        chair_money[chair_id] = win_money
        log.info("player hu %s,%s,%s,hufan %d",chair_id,p_score,win_money,hufan)
    end
    for _, mp in pairs(self.luobo_tiles) do
        tinsert(msg.luobos,{
            pai = mp.pai,
        })
    end
    log.dump(msg,"SC_MaajanZiGongGameFinish")

    chair_money = self:balance(chair_money,enum.LOG_MONEY_OPT_TYPE_MAAJAN_ZIGONG)
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

    self:broadcast2client("SC_MaajanZiGongGameFinish",msg)

    self:notify_game_money()

    self.game_log.balance = msg.player_balance
    self.game_log.end_game_time = os.time()
    self.game_log.cur_round = self.cur_round
    self.game_log.luobo_tiles = self.luobo_tiles
    self.game_log.luobo_counts = self.zhong_luobo_counts

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

function maajan_table:series_action_map(actions)
    local acts = {}
    for act,tiles in pairs(actions) do
        for tile,_ in pairs(tiles) do
            tinsert(acts,{
                action = act,
                tile = tile,
            })
        end
    end

    return acts
end

function maajan_table:send_action_waiting(action)
    local chair_id = action.chair_id
    log.info("send_action_waiting,%s",chair_id)
    send2client(self.players[chair_id],"SC_WaitingDoActions",{
        chair_id = chair_id,
        actions = self:series_action_map(action.actions),
        session_id = action.session_id,
    })
end

function maajan_table:prepare_tiles() 
    -- self.dealer:shuffle()
    -- self.pre_tiles = {
    --     -- [1] = {21,21,22,22,23,23,24,24,25,25,26,26,8},
    --     -- [2] = {11,12,13,14,15,16,17,18,19,19,19,19,8},
    -- }
    if not self.bTest then
        self.dealer:shuffle()
        self.pre_tiles = {}
        self.pre_gong_tiles = {}
        self.testcount = self.dealer.remain_count - self.start_count * 13 - 1
        log.warning("使用了 系统随机 的手牌")
        -- 萝卜从牌值里面选
        if self.rule.luobo and self.luobo_tiles_count > 0 then
            local tiles = self.dealer:get_luobo_tiles(self.luobo_tiles_count)
            for key, value in pairs(tiles) do
                local luobopai = {
                    pai = value,
                }
                tinsert(self.luobo_tiles,luobopai)
            end 
        end       
    else   
        self.zhuang = 1
        self.chu_pai_player_index = self.zhuang --出牌人的索引
        self.dealer.remain_count = self.rule.play.lai_zi and 76 or 72
        -- 测试剩余手牌
        self.testcount = self.dealer.remain_count - self.start_count * 13 - 1
        -- 测试手牌     
        self.pre_tiles = {
            [1] = {12,15,18,19,14,15,15,17,17,18,25,26,26},     -- 万 庄
            [2] = {13,13,14,22,22,22,23,23,27,27,27,28,29},    -- 筒 
        }
        -- 测试摸牌,从前到后
        self.pre_gong_tiles = {
            29,24,6,11,17,24,22,23,21,25,25,17,11,17,23,12,17,24,25,27,29,
        }
        -- 萝卜从牌值里面选
        if self.rule.luobo and self.luobo_tiles_count > 0 then
            local tiles = {26,25}
            for key, value in pairs(tiles) do
                local luobopai = {
                    pai = value,
                }
                tinsert(self.luobo_tiles,luobopai)
            end 
        end
        log.warning("使用了 测试配置 的手牌")
    end
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
    self.testLesttile = self.dealer.remain_count
end

function maajan_table:types_fan(ts)    
    local da_dui_zi_fan = HU_TYPE_INFO[HU_TYPE.DA_DUI_ZI].fan
    local qing_yi_se_fan = HU_TYPE_INFO[HU_TYPE.QING_YI_SE].fan
    for _,t in pairs(ts) do
        if t.type == HU_TYPE.QING_YI_SE then
            t.fan = qing_yi_se_fan
        end

        if t.type == HU_TYPE.QING_DA_DUI then
            t.fan = qing_yi_se_fan + da_dui_zi_fan
        end

        if t.type == HU_TYPE.DA_DUI_ZI then
            t.fan = da_dui_zi_fan
        end


        -- if t.type == HU_TYPE.QING_QI_DUI and play_opt == "er_ren_yi_fang" then
        --     t.fan = qing_yi_se_fan + HU_TYPE_INFO[HU_TYPE.QI_DUI].fan
        -- end

        -- if t.type == HU_TYPE.QING_LONG_BEI and play_opt == "er_ren_yi_fang" then
        --     t.fan = qing_yi_se_fan + HU_TYPE_INFO[HU_TYPE.LONG_QI_DUI].fan
        -- end

        -- if t.type == HU_TYPE.QING_SI_DUI then
        --     t.fan = qing_yi_se_fan + HU_TYPE_INFO[HU_TYPE.SI_DUI].fan
        -- end

        -- if t.type == HU_TYPE.QING_LONG_SI_DUI then
        --     t.fan = qing_yi_se_fan + HU_TYPE_INFO[HU_TYPE.LONG_SI_DUI].fan
        -- end
    end
    -- log.dump(ts,"types_fan")
    return ts
end

function maajan_table:serial_types(tsmap)
    local types = table.series(tsmap,function(c,t)
        local tinfo = HU_TYPE_INFO[t]
        return {type = t,fan = tinfo.fan,score = tinfo.score,count = c}
    end)
    -- log.dump(types,"serial_types")
    return self:types_fan(types)
end

function maajan_table:gang_types(p)
    local s2hu_type = {
        [SECTION_TYPE.MING_GANG] = HU_TYPE.MING_GANG,
        [SECTION_TYPE.AN_GANG] = HU_TYPE.AN_GANG,
        [SECTION_TYPE.BA_GANG] = HU_TYPE.BA_GANG,
        [SECTION_TYPE.RUAN_MING_GANG] = HU_TYPE.RUAN_MING_GANG,
        [SECTION_TYPE.RUAN_AN_GANG] = HU_TYPE.RUAN_AN_GANG,
        [SECTION_TYPE.RUAN_BA_GANG] = HU_TYPE.RUAN_BA_GANG,
    }

    local ss = table.select(p.pai.ming_pai,function(s) return  s2hu_type[s.type] ~= nil end)
    local gfan= table.group(ss,function(s) return  s2hu_type[s.type] end)
    local typescount = table.map(gfan,function(gp,t)
        return t,table.nums(gp)
    end)

    return typescount
end

function maajan_table:calc_types(ts)
    ts = self:serial_types(ts)
    return table.sum(ts,function(t) return (t.score or 1) * (t.count or 0) end),
        table.sum(ts,function(t) return (t.count or 1) * (t.fan or 0) end)
end

function maajan_table:hu_fan(player,in_pai,mo_pai,qiang_gang)
    local rule_hu = self:rule_hu(player.pai,in_pai,mo_pai)
    local ext_hu = self:ext_hu(player,mo_pai,qiang_gang)
    local hu = table.merge(rule_hu,ext_hu,function(l,r) return l or r end)
    local types = table.merge(hu,self:gang_types(player),function(l,r) return l or r end)
    local score,fan = self:calc_types(types)
    fan = fan or  0 
    fan = fan > self:get_max_fan() and self:get_max_fan() or fan 
    return fan or 0,score or 0
end

function maajan_table:get_actions_first_turn(p,mo_pai)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local actions = {}
    -- 庄家天胡，不能报听，有胡必胡
    if p.chair_id == self.zhuang and self.zhuang_first_chu_pai then
        if self.zhuang_tian_hu then
            actions[ACTION.ZI_MO] = {[mo_pai] = true,}
            return actions
        end
    end

    actions = mj_util.get_actions_first_turn(p.pai,mo_pai,si_dui)
    log.dump(actions,"11 get_actions_first_turn_"..p.guid)

    if actions[ACTION.AN_GANG] and  actions[ACTION.RUAN_AN_GANG] then 
        for tiles,_ in pairs(actions[ACTION.AN_GANG]) do
            actions[ACTION.RUAN_AN_GANG][tiles] = nil 
        end
        if table.nums(actions[ACTION.RUAN_AN_GANG]) == 0 then
            actions[ACTION.RUAN_AN_GANG] = nil
        end
    end 
    -- 校验报叫后,还能否操作杠牌
    if p.baoting then
        if actions[ACTION.HU] or actions[ACTION.ZI_MO] then
            actions[ACTION.AN_GANG] = nil
            actions[ACTION.MING_GANG] = nil
            actions[ACTION.BA_GANG] = nil
            actions[ACTION.RUAN_AN_GANG] = nil
            actions[ACTION.RUAN_MING_GANG] = nil
            actions[ACTION.RUAN_BA_GANG] = nil            
            actions[ACTION.GANG_HUAN_PAI] = nil
        end
        if actions[ACTION.AN_GANG] then
            for tile,_ in pairs(actions[ACTION.AN_GANG]) do
                if not self:is_baoting_can_gang(p,actions,ACTION.AN_GANG,tile) then
                    actions[ACTION.AN_GANG] = nil
                end
            end            
        end
        if actions[ACTION.RUAN_AN_GANG] and table.nums(actions[ACTION.RUAN_AN_GANG]) >= 0 then
            for tile,_ in pairs(actions[ACTION.RUAN_AN_GANG]) do
                if not self:is_baoting_can_gang(p,actions,ACTION.RUAN_AN_GANG,tile) then
                    actions[ACTION.RUAN_AN_GANG][tile]  = nil
                end
            end 
            if table.nums(actions[ACTION.RUAN_AN_GANG]) == 0 then
                actions[ACTION.RUAN_AN_GANG] = nil
            end 
        end
    end

    log.dump(actions,"22 get_actions_first_turn_"..p.guid)

    return actions
end

function maajan_table:get_actions_gang_huan_pai(p,mo_pai)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local lai_zi = self.rule.play and self.rule.play.lai_zi
    local actions = mj_util.get_actions_gang_huan_pai(p.pai,mo_pai,si_dui,lai_zi)

    log.dump(actions)

    if actions[ACTION.AN_GANG] and actions[ACTION.RUAN_AN_GANG]  then 
        for tiles,_ in pairs(actions[ACTION.AN_GANG]) do
            actions[ACTION.RUAN_AN_GANG][tiles] = nil 
        end
        if table.nums(actions[ACTION.RUAN_AN_GANG]) == 0 then
            actions[ACTION.RUAN_AN_GANG] = nil
        end
    end 
    if actions[ACTION.BA_GANG] and actions[ACTION.RUAN_BA_GANG]  then 
        for tiles,_ in pairs(actions[ACTION.BA_GANG]) do
            actions[ACTION.RUAN_BA_GANG][tiles] = nil 
        end
        if table.nums(actions[ACTION.RUAN_BA_GANG]) == 0 then
            actions[ACTION.RUAN_BA_GANG] = nil
        end
    end 
    return actions
end

function maajan_table:get_actions(p,mo_pai,in_pai,qiang_gang)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local lai_zi = self.rule.play and self.rule.play.lai_zi  
    local actions = mj_util.get_actions(p.pai,mo_pai,in_pai,si_dui,lai_zi)
    log.dump(p.pai,"get_actions_"..p.guid)
    log.dump(actions,"11 get_actions_"..p.guid)

    if in_pai then 
        if actions[ACTION.PENG] then 
            actions[ACTION.RUAN_PENG] = nil
        end 
        if actions[ACTION.MING_GANG] then 
            actions[ACTION.RUAN_MING_GANG] = nil
        end 
        -- 是否报听博自摸
        if self.rule.play.bo_zi_mo then
            if p.baoting and actions[ACTION.HU] then
                actions[ACTION.HU] = nil
            end
        end
        if self:is_in_gzh(p,in_pai) and actions[ACTION.HU] then
            local max_hu_fan = self:hu_fan(p,in_pai,mo_pai,qiang_gang)
            if max_hu_fan and max_hu_fan <= p.gzh[in_pai] then
                actions[ACTION.HU] = nil
            end
        end

        if  not self:can_hu(p,in_pai,nil,qiang_gang) and actions[ACTION.HU] then
            actions[ACTION.HU] = nil
        end

        if self:is_in_gsp(p,in_pai) and actions[ACTION.PENG] then
            local action = actions[ACTION.PENG]
            for gsp_tile,_ in pairs(p.gsp) do
                action[gsp_tile] = nil
            end
            if table.nums(action) == 0 then
                actions[ACTION.PENG] = nil
            end
        end
        if  self:is_in_gsp(p,in_pai) and actions[ACTION.RUAN_PENG] then
            local action = actions[ACTION.RUAN_PENG]
            for gsp_tile,_ in pairs(p.gsp) do
                action[gsp_tile] = nil
            end
            if table.nums(action) == 0 then
                actions[ACTION.RUAN_PENG] = nil
            end
        end
        if self:is_in_gsg(p,in_pai) and actions[ACTION.RUAN_MING_GANG] then
            local action = actions[ACTION.RUAN_MING_GANG]
            for gsp_tile,_ in pairs(p.gsg) do
                action[gsp_tile] = nil
            end
            if table.nums(action) == 0 then
                actions[ACTION.RUAN_MING_GANG] = nil
            end
        end
    end 
    
    if actions[ACTION.AN_GANG] and actions[ACTION.RUAN_AN_GANG] then 
        for tiles,_ in pairs(actions[ACTION.AN_GANG]) do
            actions[ACTION.RUAN_AN_GANG][tiles] = nil 
        end
        if table.nums(actions[ACTION.RUAN_AN_GANG]) == 0 then
            actions[ACTION.RUAN_AN_GANG] = nil
        end 
    end 
    if actions[ACTION.BA_GANG] and actions[ACTION.RUAN_BA_GANG] then 
        for tiles,_ in pairs(actions[ACTION.BA_GANG]) do
            actions[ACTION.RUAN_BA_GANG][tiles] = nil 
        end
        if table.nums(actions[ACTION.RUAN_BA_GANG]) == 0 then
            actions[ACTION.RUAN_BA_GANG] = nil
        end
    end 
    local remain = self.dealer.remain_count
    if remain == 0 and (actions[ACTION.AN_GANG] or actions[ACTION.MING_GANG] or actions[ACTION.BA_GANG] 
        or actions[ACTION.RUAN_AN_GANG] or actions[ACTION.RUAN_MING_GANG] or actions[ACTION.RUAN_BA_GANG]) then
        actions[ACTION.AN_GANG] = nil
        actions[ACTION.MING_GANG] = nil
        actions[ACTION.BA_GANG] = nil
        actions[ACTION.RUAN_AN_GANG] = nil
        actions[ACTION.RUAN_MING_GANG] = nil
        actions[ACTION.RUAN_BA_GANG] = nil
    end
    -- 报听玩家，有胡必胡
    if p.baoting then
        actions[ACTION.PENG] = nil
        actions[ACTION.RUAN_PENG] = nil
        -- 报听后能否杠牌
        if actions[ACTION.HU] or actions[ACTION.ZI_MO] then
            actions[ACTION.AN_GANG] = nil
            actions[ACTION.MING_GANG] = nil
            actions[ACTION.BA_GANG] = nil
            actions[ACTION.RUAN_AN_GANG] = nil
            actions[ACTION.RUAN_MING_GANG] = nil
            actions[ACTION.RUAN_BA_GANG] = nil            
            actions[ACTION.GANG_HUAN_PAI] = nil
        end
        if actions[ACTION.AN_GANG] then
            for tile,_ in pairs(actions[ACTION.AN_GANG]) do
                if not self:is_baoting_can_gang(p,actions,ACTION.AN_GANG,tile) then
                    actions[ACTION.AN_GANG][tile] = nil
                end
                if mo_pai then
                    if mo_pai ~= tile then
                        actions[ACTION.AN_GANG][tile] = nil
                    end
                end
            end    
            if table.nums(actions[ACTION.AN_GANG]) == 0 then
                actions[ACTION.AN_GANG] = nil
            end      
        end
        if actions[ACTION.RUAN_AN_GANG] and table.nums(actions[ACTION.RUAN_AN_GANG]) >= 0 then
            for tile,_ in pairs(actions[ACTION.RUAN_AN_GANG]) do
                if not self:is_baoting_can_gang(p,actions,ACTION.RUAN_AN_GANG,tile) then
                    actions[ACTION.RUAN_AN_GANG][tile]  = nil
                end
            end 
            if table.nums(actions[ACTION.RUAN_AN_GANG]) == 0 then
                actions[ACTION.RUAN_AN_GANG] = nil
            end 
        end
        if in_pai then
            if actions[ACTION.MING_GANG] then
                for tile,_ in pairs(actions[ACTION.MING_GANG]) do
                    if not self:is_baoting_can_gang(p,actions,ACTION.MING_GANG,tile) then
                        actions[ACTION.MING_GANG] = nil
                    end
                end            
            end
            if actions[ACTION.RUAN_MING_GANG] and table.nums(actions[ACTION.RUAN_MING_GANG]) >= 0 then
                for tile,_ in pairs(actions[ACTION.RUAN_MING_GANG]) do
                    if not self:is_baoting_can_gang(p,actions,ACTION.RUAN_MING_GANG,tile) then
                        actions[ACTION.RUAN_MING_GANG][tile]  = nil
                    end
                end 
                if table.nums(actions[ACTION.RUAN_MING_GANG]) == 0 then
                    actions[ACTION.RUAN_MING_GANG] = nil
                end 
            end
        end
    end
    log.dump(actions,"22 get_actions_"..p.guid)
    return actions
end
-- 自己出牌,判断是否过庄胡、过手碰、过手杠
function maajan_table:get_selfactionsAndset_pass(p,in_pai)
    local actions
    if self.rule.play.guo_zhuang_hu or self.rule.play.guo_shou_peng or self.rule.play.guo_shou_gang then
        actions = self:get_actions(p,nil,in_pai)
        if table.nums(actions) > 0 then
            if self.rule.play.guo_zhuang_hu then
                local hu_action = actions[ACTION.HU]
                if hu_action then
                    self:set_gzh_on_pass(p,in_pai)
                end
            end

            if self.rule.play.guo_shou_peng then
                local peng_action = actions[ACTION.PENG]
                if peng_action then
                    self:set_gsp_on_pass(p,in_pai)
                end
            end

            if self.rule.play.guo_shou_gang then
                local ruan_ming_gang_action = actions[ACTION.RUAN_MING_GANG]
                if ruan_ming_gang_action then
                    self:set_gsg_on_pass(p,in_pai)
                end
            end
        end
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
    [ACTION.QIANG_GANG_HU] = "QiangGangHu",
    [ACTION.RUAN_AN_GANG] = "RuanAnGang",
    [ACTION.RUAN_PENG] = "RuanPeng",
    [ACTION.RUAN_MING_GANG] = "RuanMingGang",
    [ACTION.RUAN_BA_GANG] = "RuanBaGang",
    [ACTION.GANG_HUAN_PAI] = "GangHuanPai",
}

function maajan_table:log_game_action(player,action,tile,auto,substitute_num)
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[action],msg = {tile = tile,substitute_num=substitute_num or 0 },auto = auto,time = timer.nanotime()})
end

function maajan_table:log_failed_game_action(player,action,tile,auto,substitute_num)
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[action],msg = {tile = tile,substitute_num=substitute_num or 0},auto = auto,failed = true,})
end

function maajan_table:done_last_action(player,action)
    player.last_action = action
    self:foreach_except(player,function(p) p.last_action = nil end)
end

function maajan_table:check_action_before_do(waiting_actions,player,msg)
    local action = msg.action
    local chair_id = player.chair_id
    local tile = msg.value_tile
    local substitute_num = msg.substitute_num or 0 
    local counts = player.pai.shou_pai
    if not waiting_actions then
        log.error("waiting actions nil when check_action_before_do,chair_id %s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    local player_actions = waiting_actions[chair_id]
    if not player_actions then
        log.error("no action waiting when check_action_before_do,chair_id %s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    if player_actions.session_id ~= msg.session_id then
        log.error("action session id %s,%s when check_action_before_do,chair_id %s,action:%s,tile:%s",
            player_actions.session_id,msg.session_id,chair_id,action,tile)
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
            log.error("no action waiting when check_action_before_do,chair_id %s,action:%s,tile:%s",chair_id,action,tile)
            return
        end
    end

    if not actions[action] or not actions[action][tile] then
        log.error("no action waiting when check_action_before_do,chair_id %s,action:%s,tile:%s",chair_id,action,tile)
        return
    end
    local ty_num = counts[TY_VALUE] or 0
    if ty_num < substitute_num  then
        log.error("substitute_num error when check_action_before_do,chair_id %s,action:%s,tile:%s,shoupaisubs:%s,subs:%s",chair_id,action,tile,ty_num,substitute_num)
        return
    end
    if action == ACTION.RUAN_PENG and  (substitute_num ~=1 or not counts[tile] or counts[tile] < 1   )then
        log.error("RUAN_PENG error when check_action_before_do,chair_id %s,action:%s,tile:%s,shoupaisubs:%s,subs:%s",chair_id,action,tile,ty_num,substitute_num)
        return
    end
    if action == ACTION.RUAN_MING_GANG and  (not counts[tile] or counts[tile] < 3-substitute_num   ) then
        log.error("RUAN_MING_GANG error when check_action_before_do,chair_id %s,action:%s,tile:%s,shoupaisubs:%s,subs:%s",chair_id,action,tile,ty_num,substitute_num)
        return
    end
    if action == ACTION.RUAN_AN_GANG and  (not counts[tile] or counts[tile] < 4-substitute_num   ) then
        log.error("RUAN_AN_GANG error when check_action_before_do,chair_id %s,action:%s,tile:%s,shoupaisubs:%s,subs:%s",chair_id,action,tile,ty_num,substitute_num)
        return
    end
    if action == ACTION.RUAN_BA_GANG  and substitute_num==0 and (not counts[tile] or  counts[tile] <1 )then 
        log.error("RUAN_BA_GANG substitute_num error when check_action_before_do,chair_id %s,action:%s,tile:%s,shoupaisubs:%s,subs:%s",chair_id,action,tile,ty_num,substitute_num)
        return
    end
    return player_actions
end

function maajan_table:on_mo_pai(player,mo_pai)
    player.mo_pai = mo_pai
    player.mo_pai_count = (player.mo_pai_count or 0) + 1
    send2client(player,"SC_Maajan_Draw",{tile = mo_pai,chair_id = player.chair_id})
    self:foreach_except(player,function(p)
        send2client(p,"SC_Maajan_Draw",{tile = 255,chair_id = player.chair_id})
        p.mo_pai = nil
    end)
    self.mo_pai_player_last = player.chair_id
end

function maajan_table:calculate_hu(hu)
    return self:serial_types(hu.types)
end

function maajan_table:calculate_gang(p)
    local s2hu_type = {
        [SECTION_TYPE.MING_GANG] = HU_TYPE.MING_GANG,
        [SECTION_TYPE.AN_GANG] = HU_TYPE.AN_GANG,
        [SECTION_TYPE.BA_GANG] = HU_TYPE.BA_GANG,
        [SECTION_TYPE.RUAN_MING_GANG] = HU_TYPE.RUAN_MING_GANG,
        [SECTION_TYPE.RUAN_AN_GANG] = HU_TYPE.RUAN_AN_GANG,
        [SECTION_TYPE.RUAN_BA_GANG] = HU_TYPE.RUAN_BA_GANG,
    }

    local ss = table.select(p.pai.ming_pai,function(s) return  s2hu_type[s.type] ~= nil end)
    local gfan= table.group(ss,function(s) return  s2hu_type[s.type] end)
    local gangfans = table.map(gfan,function(gp,t)
        return t,{fan = HU_TYPE_INFO[t].fan,count = table.nums(gp)}
    end)
    -- log.dump(ss,"calculate_gang ss")
    -- log.dump(gfan,"calculate_gang gfan")
    log.dump(gangfans,"calculate_gang gangfans ".. p.guid)
    local scores = table.agg(p.pai.ming_pai,{},function(tb,s)
        local t = s2hu_type[s.type]
        if not t then return tb end
        local hu_type_info = HU_TYPE_INFO[t]
        -- 有杠上炮，这个杠分就转雨
        local who = s.dian_pao and self.players[s.dian_pao] or p
        log.dump(who,"calculate_gang_p_"..p.guid.."_who_"..who.guid)
        if t == HU_TYPE.MING_GANG or  t == HU_TYPE.RUAN_MING_GANG then
            -- tb[who.chair_id] = (tb[who.chair_id] or 0) + hu_type_info.score
            -- tb[s.whoee] = (tb[s.whoee] or 0) - hu_type_info.score
            -- who.gangscore = (who.gangscore or 0) + hu_type_info.score
            -- self.players[s.whoee].gangscore = (self.players[s.whoee].gangscore or 0) - hu_type_info.score
            self:foreach_except(who,function(pi)
                log.dump(pi,"MING_GANG_p_"..p.guid.."_who_"..pi.guid)
                if pi == p then return end
                if pi.hu and pi.hu.time < s.time then return end
                local gangscore = (s.whoee == pi.chair_id) and hu_type_info.score or hu_type_info.score / 2
                log.info("MING_GANG gangscore %d ",gangscore)
                tb[who.chair_id] = (tb[who.chair_id] or 0) + gangscore
                tb[pi.chair_id] = (tb[pi.chair_id] or 0) - gangscore
                who.gangscore = (who.gangscore or 0) + gangscore
                pi.gangscore = (pi.gangscore or 0) - gangscore
            end)
        elseif t == HU_TYPE.AN_GANG or t == HU_TYPE.BA_GANG or t == HU_TYPE.RUAN_AN_GANG or t == HU_TYPE.RUAN_BA_GANG then
            self:foreach_except(who,function(pi)
                log.dump(pi,"AN_GANG_p_"..p.guid.."_who_"..pi.guid)
                if pi == p then return end
                if pi.hu and pi.hu.time < s.time then return end
                log.info("MING_GANG who.chair_id %d, pi.chair_id ",who.chair_id,pi.chair_id)
                tb[who.chair_id] = (tb[who.chair_id] or 0) + hu_type_info.score
                tb[pi.chair_id] = (tb[pi.chair_id] or 0) - hu_type_info.score
                who.gangscore = (who.gangscore or 0) + hu_type_info.score
                pi.gangscore = (pi.gangscore or 0) - hu_type_info.score
            end)
        end

        return tb
    end)

    local fans = table.series(gangfans,function(v,t) return {type = t,fan = v.fan,count = v.count} end)
    -- log.dump(fans,"calculate_gang fans")
    -- log.dump(scores,"calculate_gang scores")
    return fans,scores
end

function maajan_table:calculate_jiao(p)
    if not p.jiao or p.baoting then return end
    
    local jiao_tiles = p.jiao.tiles
    if table.nums(jiao_tiles) == 0 then 
        return {} 
    end

    local type_fans = table.flatten(
        table.series(jiao_tiles,function(_,tile)
            local tt = self:rule_hu_types(p.pai,tile)
            return table.series(tt,function(ts)
                local _,fan = self:calc_types(ts)
                return {types = self:serial_types(ts),fan = fan,tile = tile}
            end)
        end)
    )
    
    if self.rule.play.cha_da_jiao then
        table.sort(type_fans,function(l,r) return l.fan > r.fan end)
    end

    return type_fans[1]
end


function maajan_table:game_balance()
    self:foreach(function(p)
        log.dump(p.pai.shou_pai,"game_balance pai.shou_pai_"..p.guid)
        if p.hu or p.baoting then return end

        local ting_tiles = self:ting(p)
        if table.nums(ting_tiles) > 0 then
            p.jiao = p.jiao or {tiles = ting_tiles}
            log.dump(p.jiao)
        end
    end)

    local wei_hu_count = table.sum(self.players,function(p) return (not p.hu) and 1 or 0 end)
    local jiao_count = table.sum(self.players,function(p) return p.jiao and 1 or 0 end)
    log.dump(wei_hu_count)
    if wei_hu_count  == 1 then  self.liuju = false  end 
    local typefans,scores,baotingfans = {},{},{}
    self:foreach(function(p)
        local hu
        if p.hu then
            hu = self:calculate_hu(p.hu)
            if p.baoting then -- 报听
                if not baotingfans[p.chair_id] then baotingfans[p.chair_id] = {} end
                tinsert(baotingfans[p.chair_id],{type = HU_TYPE.BAO_TING,fan = 1,score = 0,count = 1})
            end
        elseif p.jiao then
            local jiao = self:calculate_jiao(p)
            hu = jiao.types
            p.jiao.tile = jiao.tile
        elseif p.baoting and (jiao_count > 0 or wei_hu_count == 1) then -- 报听   
            if not baotingfans[p.chair_id] then baotingfans[p.chair_id] = {} end             
            tinsert(baotingfans[p.chair_id],{type = HU_TYPE.BAO_TING,fan = 0,score = 0,count = 1})
        end
        
        local gangfans,gangscores
        if p.jiao or p.hu or wei_hu_count == 1 then
            gangfans,gangscores = self:calculate_gang(p)
        end
        if not typefans[p.chair_id] then typefans[p.chair_id] = {} end
        local types = table.union(hu or {},baotingfans[p.chair_id] or {})
        typefans[p.chair_id] = table.union(types or {},gangfans or {})
        
        table.mergeto(scores,gangscores or {},function(l,r) return (l or 0) + (r or 0) end)
    end)
    -- log.dump(piaoscors,"game_balance piaoscors")
    log.dump(typefans,"game_balance typefans")
    log.dump(scores,"game_balance scores") 
    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    local baopei_count =  hu_count and (self.start_count - hu_count - 1) or 0
    local max_fan = self:get_max_fan()
    local fans = table.map(typefans,function(v,chair)
        local fan = table.sum(v,function(t) return t.fan * t.count end)
        return chair,(fan > max_fan and max_fan or fan)
    end)
    -- log.dump(fans,"game_balance fans")
    self:foreach(function(p)
        local chair_id = p.chair_id
        local fan = fans[chair_id]
        local fan_score = 2 ^ math.abs(fan)
        local type = typefans[chair_id]
        local piaofan = 1
        local pi_fan_score = 1
        log.dump(type,"typefans_"..chair_id)
        -- 萝卜加分
        local zhong_luobo_score = self:get_luobo(chair_id)  

        if p.hu then
            if not p.hu.zi_mo then  -- 吃胡
                local whoee = p.hu.whoee
                -- 输家是否也报叫
                if self.players[whoee].baoting then
                    if fan + 1 <= max_fan then  -- 不大于最大番，就加番
                        fan_score = fan_score * 2
                        fan = fan + 1
                    end
                end
                -- 输家是否金钩钓
                if self.rule.play.jin_gou_gou then
                    typefans[whoee],fan_score = self:is_jin_gou_diao(whoee,typefans[whoee],fan,max_fan)
                end                
                -- 飘番
                piaofan = self:get_piaofan(chair_id,whoee)
                local pi_score = fan_score * piaofan
                log.info("guid:%d,pi_fan_score:%d, fan_score:%d, piaofan:%d, pi_score:%d ",p.guid,pi_fan_score,fan_score,piaofan,pi_score)
                -- 萝卜分
                pi_score = pi_score + zhong_luobo_score
                scores[whoee] = (scores[whoee] or 0) - pi_score
                scores[chair_id] = (scores[chair_id] or 0) + pi_score
                self.players[chair_id].huscore = (self.players[chair_id].huscore or 0) + pi_score
                self.players[whoee].huscore = (self.players[whoee].huscore or 0) - pi_score
                self.players[chair_id].luoboscore = zhong_luobo_score
                return
            end        

            self:foreach_except(p,function(pi)
                if pi.hu and pi.hu.time <= p.hu.time then return end
                fan = fans[chair_id]
                fan_score = 2 ^ math.abs(fan)
                pi_fan_score = fan_score
                local chair_i = pi.chair_id
                -- 输家是否也报叫
                if self.players[chair_i].baoting then
                    if fan + 1 <= max_fan then  -- 不大于最大番，就加番
                        pi_fan_score = pi_fan_score * 2
                        fan = fan + 1
                    end
                end
                -- 输家是否金钩钓
                if self.rule.play.jin_gou_gou then
                    typefans[chair_i],pi_fan_score = self:is_jin_gou_diao(chair_i,typefans[chair_i],fan,max_fan)
                end
                if self.rule.play.zi_mo_jia_di then
                    pi_fan_score = pi_fan_score + 1
                end
                -- 飘番
                piaofan = self:get_piaofan(chair_id,chair_i)
                pi_fan_score = pi_fan_score * piaofan   
                -- 萝卜分
                pi_fan_score = pi_fan_score + zhong_luobo_score
                scores[chair_i] = (scores[chair_i] or 0) - pi_fan_score
                scores[chair_id] = (scores[chair_id] or 0) + pi_fan_score
                self.players[chair_id].huscore = (self.players[chair_id].huscore or 0) + pi_fan_score
                self.players[chair_i].huscore = (self.players[chair_i].huscore or 0) - pi_fan_score
                self.players[chair_id].luoboscore = zhong_luobo_score
            end)
        elseif self.liuju then
            if p.baoting then -- 杀报听,报听玩家赔给报叫玩家最大的胡番  
                self:foreach_except(p,function(pi)
                    if pi.hu or pi.baoting or not pi.jiao then return end                
                    local chair_i = pi.chair_id
                    local bhave = false
                    for _, vtype in pairs(typefans[chair_i]) do
                        if vtype.type == HU_TYPE.SHA_BAO then
                            bhave = true
                            break
                        end
                    end
                    if not bhave then
                        tinsert(typefans[chair_i],{type = HU_TYPE.SHA_BAO,fan = 1,score = 1,count = 1})
                    end
                    fan = fans[chair_i]
                    fan_score = 2 ^ math.abs(fan)
                    -- 报听+1番
                    if fans[chair_i] + 1 <= max_fan then  -- 不大于最大番，就加番
                        fan_score = fan_score * 2
                        fan = fan + 1
                    end
                    -- 输家是否金钩钓
                    if self.rule.play.jin_gou_gou then
                        typefans[chair_id],fan_score = self:is_jin_gou_diao(chair_id,typefans[chair_id],fan,max_fan)
                    end
                    -- 飘番
                    piaofan = self:get_piaofan(chair_i,chair_id)
                    fan_score = fan_score * piaofan   
                    -- 萝卜分
                    zhong_luobo_score = self:get_luobo(chair_i)
                    fan_score = fan_score + zhong_luobo_score                
                    scores[chair_id] = (scores[chair_id] or 0) - fan_score
                    scores[chair_i] = (scores[chair_i] or 0) + fan_score
                    self.players[chair_id].huscore = (self.players[chair_id].huscore or 0) - fan_score
                    self.players[chair_i].huscore = (self.players[chair_i].huscore or 0) + fan_score
                    self.players[chair_i].luoboscore = zhong_luobo_score
                    if self.rule.play.cha_da_jiao then
                        pi.statistics.cha_da_jiao = (pi.statistics.cha_da_jiao or 0) + 1
                    end
                end)
            elseif p.jiao then -- 查大叫            
                self:foreach_except(p,function(pi)
                    if pi.hu or pi.jiao or pi.baoting then return end
                    local chair_i = pi.chair_id
                    -- 输家是否金钩钓
                    if self.rule.play.jin_gou_gou then
                        typefans[chair_i],fan_score = self:is_jin_gou_diao(chair_i,typefans[chair_i],fan,max_fan)
                    end
                    -- 飘番
                    piaofan = self:get_piaofan(chair_i,chair_id)
                    fan_score = fan_score * piaofan   
                    -- 萝卜分
                    fan_score = fan_score + zhong_luobo_score  
                    scores[chair_id] = (scores[chair_id] or 0) + fan_score
                    scores[chair_i] = (scores[chair_i] or 0) - fan_score
                    self.players[chair_id].huscore = (self.players[chair_id].huscore or 0) + fan_score
                    self.players[chair_i].huscore = (self.players[chair_i].huscore or 0) - fan_score
                    self.players[chair_id].luoboscore = zhong_luobo_score
                    if self.rule.play.cha_da_jiao then
                        pi.statistics.cha_da_jiao = (pi.statistics.cha_da_jiao or 0) + 1
                    end
                end)
            end
        end
    end)

    local fanscores = table.map(self.players,function(_,chair)
        return chair,{fan = fans[chair] or 0,score = scores[chair] or 0,}
    end)
    log.dump(typefans,"game_balance typefans")
    log.dump(fanscores,"game_balance fanscores")
    return typefans,fanscores
end

-- 是否金钩钓加番
function maajan_table:is_jin_gou_diao(chairid,typefan,fan,max_fan)
    log.dump(typefan,"fan_score_"..self.players[chairid].guid.."_"..fan)
    local types,fanscore = typefan,(2 ^ math.abs(fan))
    if table.sum(self.players[chairid].pai.shou_pai) == 1 then
        local bhave = false
        for _, vtype in pairs(types) do
            if vtype.type == HU_TYPE.DAN_DIAO_JIANG then
                bhave = true
                break
            end
        end
        if not bhave then
            tinsert(types,{type = HU_TYPE.DAN_DIAO_JIANG,fan = 1,score = 0,count = 0})
        end
        if fan + 1 <= max_fan then  -- 不大于最大番，就加番
            fanscore = 2 ^ math.abs(fan) * 2
        end
    end
    log.dump(types,"fanscore_"..self.players[chairid].guid.."_"..fanscore)

    return types,fanscore
end

function maajan_table:on_game_overed()
    self:cancel_all_auto_action_timer()
    self:cancel_clock_timer()
    
    self.game_log = nil

    self.zhuang = self:ding_zhuang() or self.zhuang

    self:clear_ready()
    self.cur_state_FSM = nil

    self:foreach(function(v)
        v.hu = nil
        v.jiao = nil
        v.pai = {
            ming_pai = {},
            shou_pai = {},
            desk_tiles = {},
            huan = nil,
        }
        v.mo_pai = nil
        v.mo_pai_count = nil
        v.chu_pai = nil
        v.chu_pai_count = nil

        v.piao = nil
        v.hupiaoscore = nil
        v.gangscore = nil
        v.niaoscore = nil
        v.huscore = nil
        v.baoting = nil
        v.baotingInfo = nil  -- 听牌数据
        v.luoboscore = nil
    end)
    self.luobo_tiles = {}
    self.zhong_luobos = {}
    self.zhong_luobo_counts = {}
    self.liuju = false
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
    self.luobo_tiles = {}
    self.zhong_luobos = {}
    self.zhong_luobo_counts = {}
    self:foreach(function(p)
        log.dump(p.statistics,"p.statistics_"..p.guid)
        p.statistics = nil
    end)
end

function maajan_table:ding_zhuang()
    if not self.zhuang then
        return
    end

    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    if hu_count == 0 then 
        log.info("本局荒庄,mo_pai_player_last %d,self.zhuang %d ",self.mo_pai_player_last , self.zhuang)
        self.zhuang = self.mo_pai_player_last and self.mo_pai_player_last or self.zhuang -- 荒庄，下局最后一个摸牌的玩家坐庄
        return self.zhuang
    end

    for _,p in pairs(self.players) do
        if p.first_multi_pao then
            return p.chair_id
        end
    end

    local ps = table.values(self.players)
    table.sort(ps,function(l,r)
        if l.hu and not r.hu then return true end
        if not l.hu and r.hu then return false end
        if l.hu and r.hu then return l.hu.time < r.hu.time end
        return false
    end)

    return ps[1].chair_id
end

function maajan_table:first_zhuang()
    local max_chair,_ = table.max(self.players,function(_,i) return i end)
    local chair
    repeat
        chair = math.random(1,max_chair)
        local p = self.players[chair]
    until p

    return chair
end

function maajan_table:tile_count_2_tiles(counts,excludes)
    local tiles = {}
    for t,c in pairs(counts) do
        local exclude_c = excludes and excludes[t] or 0
        for _ = 1,c - exclude_c do
            tinsert(tiles,t)
        end
    end

    return tiles
end

function maajan_table:is_play(...)
    return self.cur_state_FSM ~= nil
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
            [ACTION.RUAN_PENG] = self.on_action_after_chu_pai,
            [ACTION.RUAN_MING_GANG] = self.on_action_after_chu_pai,
        },
        [FSM_S.WAIT_ACTION_AFTER_MO_PAI] = {
            [ACTION.AN_GANG] = self.on_action_after_mo_pai,
            [ACTION.BA_GANG] = self.on_action_after_mo_pai,
            [ACTION.PASS] = self.on_action_after_mo_pai,
            [ACTION.ZI_MO] = self.on_action_after_mo_pai,
            [ACTION.GANG_HUAN_PAI] = self.on_action_after_mo_pai,
            [ACTION.RUAN_AN_GANG] = self.on_action_after_mo_pai,
            [ACTION.RUAN_BA_GANG] = self.on_action_after_mo_pai,
        },
        [FSM_S.WAIT_QIANG_GANG_HU] = {
            [ACTION.HU] = self.on_action_qiang_gang_hu,
            [ACTION.PASS] = self.on_action_qiang_gang_hu,
            [ACTION.QIANG_GANG_HU] = self.on_action_qiang_gang_hu,
        },
        [FSM_S.FINAL_END] = {

        },
    }
    
    local fn = state_actions[self.cur_state_FSM] and state_actions[self.cur_state_FSM][msg.action] or nil
    if fn then
        self:lockcall(fn,self,player,msg)
    else
        log.error("unkown state but got action %s",msg.action)
    end
end

--打牌
function maajan_table:on_cs_act_discard(player, msg)
    if msg and msg.tile and mj_util.check_tile(msg.tile) then
        self:clear_deposit_and_time_out(player)
    end
    self:lockcall(function() self:on_action_chu_pai(player,msg) end)
end

--过
function maajan_table:on_cs_act_pass(player, msg)
    self:clear_deposit_and_time_out(player)
end

--托管
function maajan_table:on_cs_act_trustee(player, msg)
    self:clear_deposit_and_time_out(player)
end

-- function maajan_table:on_cs_huan_pai(player,msg)
--     self:lockcall(function() self:on_huan_pai(player,msg) end)
-- end

function maajan_table:on_cs_piao_fen(player,msg)
    self:lockcall(function() self:on_piao_fen(player,msg) end)
end

function maajan_table:on_cs_bao_ting(player,msg)
    self:lockcall(function() self:on_baoting(player,msg) end)
end

function maajan_table:chu_pai_player()
    return self.players[self.chu_pai_player_index]
end

function maajan_table:broadcast_player_hu(player,action,target,session_id,substitute_num)
    local msg = {
        chair_id = player.chair_id, 
        value_tile = player.hu.tile,
        action = action,
        target_chair_id = target,
        session_id = session_id,
        substitute_num =substitute_num
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
function maajan_table:check_chair_closer(l,r)
    local chair = self.chu_pai_player_index
    repeat
        chair = (chair % self.chair_count) + 1
        local p = self.players[chair]
    until p and not p.hu and (chair == l or chair== r)
    return chair == l
end


function maajan_table:jump_to_player_index(player)
    local chair_id = type(player) == "number" and player or player.chair_id
    self.chu_pai_player_index = chair_id
    self:broadcast_discard_turn()
end

function maajan_table:adjust_shou_pai(player, action, tile,session_id,substitute_num)
    local shou_pai = player.pai.shou_pai
    local ming_pai = player.pai.ming_pai
    substitute_num = substitute_num or 0 
    log.dump(player.pai)
    if action == ACTION.AN_GANG then
        table.decr(shou_pai,tile,4)
        tinsert(ming_pai,{
            type = SECTION_TYPE.AN_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            time = timer.nanotime(),
        })
    end
    if action == ACTION.RUAN_AN_GANG then
        table.decr(shou_pai,tile,4-substitute_num)
        table.decr(shou_pai,TY_VALUE,substitute_num)
        tinsert(ming_pai,{
            type = SECTION_TYPE.RUAN_AN_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            time = timer.nanotime(),
            substitute_num = substitute_num,
            inisubstitute_num = substitute_num
        })
    end

    if action == ACTION.MING_GANG then
        table.decr(shou_pai,tile,3)
        tinsert(ming_pai,{
            type = SECTION_TYPE.MING_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            whoee = self.chu_pai_player_index,
            time = timer.nanotime()
        })
    end
    if action == ACTION.RUAN_MING_GANG then
        table.decr(shou_pai,tile,3-substitute_num)
        table.decr(shou_pai,TY_VALUE,substitute_num)
        tinsert(ming_pai,{
            type = SECTION_TYPE.RUAN_MING_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            whoee = self.chu_pai_player_index,
            time = timer.nanotime(),
            substitute_num = substitute_num,
            inisubstitute_num = substitute_num
        })
    end
    if action == ACTION.BA_GANG then  --巴杠
        for k,s in pairs(ming_pai) do
            if s.tile == tile and s.type == SECTION_TYPE.PENG then
                tinsert(ming_pai,{
                    type = SECTION_TYPE.BA_GANG,
                    tile = tile,
                    area = TILE_AREA.MING_TILE,
                    whoee = s.whoee,
                    time = timer.nanotime(),
                })
                ming_pai[k] = nil
                table.decr(shou_pai,tile)
                break
            end
        end
    end
    if action == ACTION.RUAN_BA_GANG then  --巴杠
        for k,s in pairs(ming_pai) do
            if s.tile == tile and (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.RUAN_PENG ) then
                tinsert(ming_pai,{
                    type = SECTION_TYPE.RUAN_BA_GANG,
                    tile = tile,
                    area = TILE_AREA.MING_TILE,
                    whoee = s.whoee,
                    time = timer.nanotime(),
                    substitute_num = substitute_num + (s.substitute_num or 0),
                    inisubstitute_num = substitute_num + (s.substitute_num or 0)
                })
                ming_pai[k] = nil
                local a = (substitute_num == 1) and table.decr(shou_pai,TY_VALUE) or  table.decr(shou_pai,tile)
                break
            end
        end
    end
    if action == ACTION.GANG_HUAN_PAI then
        for k,s in pairs(ming_pai) do
            if s.tile == tile and s.substitute_num and s.substitute_num >0 and (s.type == SECTION_TYPE.RUAN_BA_GANG or s.type == SECTION_TYPE.RUAN_MING_GANG  or s.type == SECTION_TYPE.RUAN_AN_GANG  ) then
                s.substitute_num =  s.substitute_num -1
                table.decr(shou_pai,tile)
                table.incr(shou_pai,TY_VALUE)
                break
            end
        end
    end
    if action == ACTION.PENG then
        table.decr(shou_pai,tile,2)
        tinsert(ming_pai,{
            type = SECTION_TYPE.PENG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            whoee = self.chu_pai_player_index,
        })
    end
    if action == ACTION.RUAN_PENG then
        table.decr(shou_pai,tile,2-substitute_num)
        table.decr(shou_pai,TY_VALUE,substitute_num)
        tinsert(ming_pai,{
            type = SECTION_TYPE.RUAN_PENG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            whoee = self.chu_pai_player_index,
            substitute_num = substitute_num,
            inisubstitute_num = substitute_num
        })
    end

    if action == ACTION.LEFT_CHI then
        table.decr(shou_pai,tile - 1)
        table.decr(shou_pai,tile - 2)
        tinsert(ming_pai,{
            type = SECTION_TYPE.LEFT_CHI,
            tile = tile,
            area = TILE_AREA.MING_TILE,
        })
    end

    if action == ACTION.MID_CHI then
        table.decr(shou_pai,tile - 1)
        table.decr(shou_pai,tile + 1)
        tinsert(ming_pai,{
            type = SECTION_TYPE.MID_CHI,
            tile = tile,
            area = TILE_AREA.MING_TILE,
        })
    end

    if action == ACTION.RIGHT_CHI then
        table.decr(shou_pai,tile + 1)
        table.decr(shou_pai,tile + 2)
        tinsert(ming_pai,{
            type = SECTION_TYPE.RIGHT_CHI,
            tile = tile,
            area = TILE_AREA.MING_TILE,
        })
    end
    log.dump(player.pai)
    self:broadcast2client("SC_Maajan_Do_Action",{chair_id = player.chair_id,value_tile = tile,action = action,session_id = session_id,substitute_num = substitute_num})
end

--掉线，离开，自动胡牌
function maajan_table:auto_act_if_deposit(player,actions)
    
end

function maajan_table:on_chu_pai(tile)
    for _, p in pairs(self.players) do
        if p.chair_id == self.chu_pai_player_index then
            p.chu_pai = tile
            p.chu_pai_count = (p.chu_pai_count or 0) + 1
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
        tinsert(msg.pb_players,tplayer)
    end)

    -- log.dump(msg)

    local last_chu_pai_player,last_tile = self:get_last_chu_pai()
    if is_reconnect  then
        local total_scores,strtotal_scores = table.map(self.players,function(p,chair) return chair,p.total_score end),{}
        local total_money,strtotal_money = table.map(self.players,function(p,chair) return chair,p.total_money end),{}
        for k,score in pairs(total_scores) do
            strtotal_scores[k] = tostring(score)
        end
        for k,money in pairs(total_money) do
            strtotal_money[k] = tostring(money)
        end
        msg.pb_rec_data = {
            last_chu_pai_chair = last_chu_pai_player and last_chu_pai_player.chair_id or nil,
            last_chu_pai = last_tile,
            total_scores = strtotal_scores, -- table.map(self.players,function(p,chair) return chair,p.total_score end),
            total_money = strtotal_money, -- table.map(self.players,function(p,chair) return chair,p.total_money end),
        }
        log.dump(msg.pb_rec_data,"is_reconnect_"..tostring(player.guid))
    end

    if self.cur_round and self.cur_round > 0 then
        send2client(player,"SC_Maajan_Desk_Enter",msg)
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
        tinsert(status,{
            chair_id = p.chair_id,
            hu = p.hu and (p.hu.zi_mo and 2 or 1) or nil,
            hu_index = p.hu and i or nil,
            hu_tile = p.hu and p.hu.tile or nil,
        })
    end)

    send2client(player,"SC_HuStatus",{
        status = status,
    })
end

function maajan_table:send_piao_fen_status(player)
    local piao_fen_status = {}
    local piao_fen_info = {}
    if self.cur_state_FSM == FSM_S.PIAO_FEN then
        tinsert(piao_fen_info,{
            chair_id = player.chair_id,
            piao = player.piao or -1,
        })
        self:foreach(function(p) 
            tinsert(piao_fen_status,{
                chair_id = p.chair_id,
                done = p.piao and true or false,
            })
        end)
    else
        self:foreach(function(p) 
            tinsert(piao_fen_info,{
                chair_id = p.chair_id,
                piao = p.piao or -1,
            })
        end)
    end

    send2client(player,"SC_PiaoFenStatus",{
        piao_status = table.nums(piao_fen_status) > 0 and piao_fen_status or nil,
        piao_info = piao_fen_info,
    })
end

function maajan_table:send_huan_pai_status(player)
    local huan_status = {}
    self:foreach(function(p)
        tinsert(huan_status,{
            chair_id = p.chair_id,
            done = p.pai.huan and true or false,
        })
    end)

    send2client(player,"SC_HuanPaiStatus",{
        self_choice = player.pai.huan and player.pai.huan.old or nil,
        status = huan_status,
    })
end

function maajan_table:reconnect(player)
    log.info("player reconnect : %d,self.cur_state_FSM : %d ",player.chair_id,self.cur_state_FSM)
    
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

    -- if self.cur_state_FSM == FSM_S.HUAN_PAI then
    --     self:on_reconnect_when_huan_pai(player)
    -- else
    if self.cur_state_FSM == FSM_S.PIAO_FEN then
        self:on_reconnect_when_piao_fen(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_BAO_TING then
        self:on_reconnect_when_baoting(player)
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
        send2client(player,"SC_TimeOutNotify",{
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

function maajan_table:ext_hu(player,mo_pai,qiang_gang)
    local types = {}

    local chu_pai_player = self:chu_pai_player()
    log.dump(self.rule.play.tian_di_hu,"tian_di_hu")
    if self.rule.play.tian_di_hu then
        if player.chair_id == self.zhuang and mo_pai and self.mo_pai_count == 1 then
            types[HU_TYPE.TIAN_HU] = 1
        end

        if (not mo_pai) and chu_pai_player.chair_id == self.zhuang and player.chair_id ~= self.zhuang and player.mo_pai_count <= 1 and player.chu_pai_count == 0 and table.nums(player.pai.ming_pai) == 0 then
            if self.cur_state_FSM ~= FSM_S.WAIT_BAO_TING then 
                types[HU_TYPE.DI_HU] = 1
            end
        end
    end

    local dgh_dian_pao = self.rule.play.dgh_dian_pao
    local discarder_last_action = chu_pai_player.last_action
    local is_zi_mo = mo_pai and true or false

    -- 海底捞
    if self.dealer.remain_count == 0 then
        if is_zi_mo then
            types[HU_TYPE.HAI_DI_LAO_YUE] = 1
        else
            types[HU_TYPE.HAI_DI_PAO] = 1
        end
    end

    local gang_hua = chu_pai_player == player and discarder_last_action and def.is_action_gang(discarder_last_action.action or 0)
    if gang_hua then
        if dgh_dian_pao and player.last_action and player.last_action.action == ACTION.MING_GANG then
            types[HU_TYPE.GANG_SHANG_PAO] = 1
            is_zi_mo = nil
        else
            types[HU_TYPE.GANG_SHANG_HUA] = 1
        end
    end

    if is_zi_mo and self.rule.play.zi_mo_jia_fan then
        types[HU_TYPE.ZI_MO] = 1    
    end

    if chu_pai_player ~= player and discarder_last_action and def.is_action_gang(discarder_last_action.action) then
        types[HU_TYPE.GANG_SHANG_PAO] = 1
    end

    if qiang_gang then
        types[HU_TYPE.QIANG_GANG_HU] = 1
    end

    -- log.dump(types,"ext_hu types")
    return types
end

function maajan_table:rule_hu_types(pai,in_pai,mo_pai)
    -- local private_conf = self:room_private_conf()
    -- local play_opt = (not private_conf or not private_conf.play) and "xuezhan" or private_conf.play.option
    local rule_play = self.rule.play
    local si_dui,lai_zi = rule_play.si_du,rule_play.lai_zi
    local hu_types = mj_util.hu(pai,in_pai,mo_pai,si_dui,lai_zi)
    -- log.dump(hu_types,"hu_types111")
    return table.series(hu_types,function(ones)
        local ts = {}
        local bHave = true
        -- log.dump(ones,"ones111")
        for t,c in pairs(ones) do
            if t == HU_TYPE.QING_DA_DUI then
                ts[HU_TYPE.QING_YI_SE] = 1
                ts[HU_TYPE.DA_DUI_ZI] = 1
            else
                ts[t] = c
            end
        end
        -- log.dump(ts,"ts222")
        return ts
    end)
end

function maajan_table:rule_hu(pai,in_pai,mo_pai)
    local types = self:rule_hu_types(pai,in_pai,mo_pai)
    -- log.dump(types,"rule_hu_types")
    table.sort(types,function(l,r)
        local lscore,lfan = self:calc_types(l)
        local rscore,rfan = self:calc_types(r)
        local curlscore = lscore + 2 ^ lfan
        local currscore = rscore + 2 ^ rfan
        return ( curlscore == currscore ) and (lfan > rfan) or curlscore > currscore
    end)
    -- log.dump(types,"rule_hu_types[1]")
    return types[1] or {}
end

function maajan_table:hu(player,in_pai,mo_pai,qiang_gang)
    local rule_hu = self:rule_hu(player.pai,in_pai,mo_pai)
    local ext_hu = self:ext_hu(player,mo_pai,qiang_gang)
    -- log.dump(rule_hu,"rule_hu")
    -- log.dump(ext_hu,"ext_hu")
    return table.merge(rule_hu,ext_hu,function(l,r) return l or r end)
end

function maajan_table:is_hu(pai,in_pai)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local lai_zi = self.rule.play and self.rule.play.lai_zi
    return mj_util.is_hu(pai,in_pai,si_dui,lai_zi)
end

function maajan_table:can_hu(player,in_pai,mo_pai,qiang_gang)
    if self.rule.play.yi_fan_qi_hu then -- 一番起胡
        local fan,_ = self:hu_fan(player,in_pai,mo_pai,qiang_gang)
        if self.rule.play.bao_jiao then
            local chupai_player = self:chu_pai_player()
            if (in_pai and chupai_player.baoting) or player.baoting then fan = fan + 1 end
        end
        return fan > 0
    end
    local room_private_conf = self:room_private_conf()
    if not room_private_conf.play then
        return self:is_hu(player.pai,in_pai)
    end

    local play_opt = room_private_conf.play.option
    if  not play_opt  then
        return self:is_hu(player.pai,in_pai)
    end

    local fan,_ = self:hu_fan(player,in_pai,mo_pai,qiang_gang)
    return fan > 0
end

function maajan_table:get_ting_tiles_info(player)
    self:lockcall(function()
        local hu_tips = self.rule and self.rule.play.hu_tips or nil
        if not hu_tips then 
            send2client(player,"SC_MaajanGetTingTilesInfo",{
                result = enum.ERROR_OPERATION_INVALID,
            })
            return
        end

        if player.hu then 
            send2client(player,"SC_MaajanGetTingTilesInfo",{
                result = enum.ERROR_OPERATION_INVALID,
            })
            return
        end
        
        -- if not self:is_piao(player) then
        --     send2client(player,"SC_MaajanGetTingTilesInfo",{
        --         result = enum.ERROR_NONE,
        --     })
        --     return
        -- end

        local ting_tiles = self:ting(player)
        local hu_tile_fans = table.series(ting_tiles or {},function(_,tile)
            return {tile = tile,fan = self:hu_fan(player,tile)} 
        end)

        log.dump(hu_tile_fans)

        send2client(player,"SC_MaajanGetTingTilesInfo",{
            tiles_info = hu_tile_fans,
        })
    end)
end

function maajan_table:global_status_info(type)
    if type then
        local n = table.nums(self.players)
	    local min_count = self.start_count or self.room_.min_gamer_count or self.chair_count
        if type == 1 then -- 查询全部桌子
            -- if n < min_count then -- 过滤等待中的桌子
            --     return
            -- end
        elseif type == 2 then -- 查询等待中的桌子
            if n >= min_count then -- 过滤满人的桌子
                return
            end
        end
    end

    local seats = {}
    for chair_id,p in pairs(self.players) do
        tinsert(seats,{
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
            online = p.active,
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

function maajan_table:get_anti_cheat()
    local info = base_table.get_anti_cheat(self)
    self:foreach(function(p)
        if p.hu and p.hu.whoee then
			info[p.chair_id][p.hu.whoee].type_list[enum.ANTI_CHEAT_PINGHU] =1
        end
		if p.pai and p.pai.ming_pai then 
			for _, s in pairs(p.pai.ming_pai) do
				if s.whoee then
					info[p.chair_id][s.whoee].type_list[enum.ANTI_CHEAT_PENGGANG] = info[p.chair_id][s.whoee].type_list[enum.ANTI_CHEAT_PENGGANG] or 0
					info[p.chair_id][s.whoee].type_list[enum.ANTI_CHEAT_PENGGANG] = info[p.chair_id][s.whoee].type_list[enum.ANTI_CHEAT_PENGGANG] +1
				end
			end
		end 
    end)
    return info
end 

function maajan_table:send_baoting_tips(p)
    local hu_tips = self.rule and self.rule.play.bao_jiao or nil
    if not hu_tips then return end
    -- if not self.zhuang_first_chu_pai then return end
    local canBaoting = false
    -- 天胡不能报听
    if p.chair_id == self.zhuang then 
        self.zhuang_tian_hu = self.zhuang_tian_hu and self.zhuang_tian_hu or self:is_hu(p.pai,nil)
        if self.zhuang_tian_hu then
            log.info("zhuang tianhu can not baoting guid:%d",p.guid)
            -- send2client(p,"SC_BaoTingInfos",{
            --     canbaoting = 0,
            --     ting = {}
            -- })
            self:on_baoting(p,{ baoting = 0})
            return false
        end
    end
    local ting_tiles = p.chair_id == self.zhuang and self:ting_full(p) or self:ting(p)
    log.dump(ting_tiles,"send_baoting_tips_"..p.guid)
    if table.nums(ting_tiles) > 0 then
        local pai = p.pai
        local discard_tings = {}
        if p.chair_id == self.zhuang then
            discard_tings = table.series(ting_tiles,function(tiles,discard)
                table.decr(pai.shou_pai,discard)
                local tings = table.series(tiles,function(_,tile) return {tile = tile,fan = self:hu_fan(p,tile)} end)
                table.incr(pai.shou_pai,discard)
                return { discard = discard, tiles_info = tings, }
            end)
        else
            discard_tings = table.series(ting_tiles or {},function(_,tile)
                return {tile = tile,fan = self:hu_fan(p,tile)} 
            end)
        end
        p.baotingInfo = discard_tings
        log.dump(discard_tings,"discard_tings_"..p.guid)
        send2client(p,"SC_BaoTingInfos",{
            canbaoting = 1,
            ting = discard_tings
        })
        canBaoting = true
    else
        -- send2client(p,"SC_BaoTingInfos",{
        --     canbaoting = 0,
        --     ting = {}
        -- })
        self:on_baoting(p,{ baoting = 0})
    end
    return canBaoting
end

function maajan_table:send_baoting_status(player)
    if not self.rule.play.bao_jiao then
        return
    end
    local baoting_status = {}
    local baoting_info = {}
    if self.cur_state_FSM == FSM_S.WAIT_BAO_TING then
        tinsert(baoting_info,{
            chair_id = player.chair_id,
            baoting = player.baoting or nil,
        })
        self:foreach(function(p) 
            tinsert(baoting_status,{
                chair_id = p.chair_id,
                done = p.baoting ~= nil and true or false,
            })
        end)
    else
        self:foreach(function(p) 
            tinsert(baoting_info,{
                chair_id = p.chair_id,
                baoting = p.baoting or nil,
            })
        end)
        self:foreach(function(p) 
            tinsert(baoting_status,{
                chair_id = p.chair_id,
                done = p.baoting ~= nil and true or false,
            })
        end)
    end

    send2client(player,"SC_BaotingStatus",{
        baoting_status = baoting_status, -- table.nums(baoting_status) > 0 and baoting_status or nil,
        baoting_info = baoting_info,
    })

    if self.cur_state_FSM == FSM_S.WAIT_BAO_TING or self.zhuang_first_chu_pai then
        self:foreach(function(p)
            self:send_baoting_tips(p)
        end)
    end
end

function maajan_table:on_reconnect_when_baoting(player)
    send2client(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    self:send_baoting_status(player)
    if self.clock_timer then
        self:begin_clock(self.clock_timer.remainder,player)
    end
end

function maajan_table:send_baoting_data_to_enter_player(player,is_reconnect)
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
        tinsert(msg.pb_players,tplayer)
    end)

    -- log.dump(msg)

    local last_chu_pai_player,last_tile = self:get_last_chu_pai()
    if is_reconnect  then
        local total_scores,strtotal_scores = table.map(self.players,function(p,chair) return chair,p.total_score end),{}
        local total_money,strtotal_money = table.map(self.players,function(p,chair) return chair,p.total_money end),{}
        for k,score in pairs(total_scores) do
            strtotal_scores[k] = tostring(score)
        end
        for k,money in pairs(total_money) do
            strtotal_money[k] = tostring(money)
        end
        msg.pb_rec_data = {
            last_chu_pai_chair = last_chu_pai_player and last_chu_pai_player.chair_id or nil,
            last_chu_pai = last_tile,
            total_scores = strtotal_scores, -- table.map(self.players,function(p,chair) return chair,p.total_score end),
            total_money = strtotal_money, -- table.map(self.players,function(p,chair) return chair,p.total_money end),
        }
        log.dump(msg.pb_rec_data,"is_reconnect_"..tostring(player.guid))
    end

    if self.cur_round and self.cur_round > 0 then
        send2client(player,"SC_Maajan_Desk_Enter",msg)
    end
end

function maajan_table:on_cs_act_baoting(player,msg)
    self:lockcall(function() self:on_bao_ting(player,msg) end)
end

function maajan_table:on_baoting(player,msg)
    if self.cur_state_FSM ~= FSM_S.WAIT_BAO_TING then
        log.error("maajan_table:on_baoting error state %s,guid:%s",self.cur_state_FSM,player.guid)
        return
    end

    if player.baoting ~= nil then
        log.error("maajan_table:on_baoting repeated %s,guid:%s",msg.baoting,player.guid)
        send2client(player,"SC_Baoting",{
            result = enum.ERROR_OPERATION_REPEATED
        })
        return
    end

    player.baoting = (msg.baoting == 1) and true or false
    if not player.baoting then
        player.baotingInfo = nil
    end
    log.info("player on_baoting guid:%d, baoting:%d ",player.guid,player.baoting)
    self:broadcast2client("SC_Baoting",{
        result = enum.ERROR_NONE,
        status = {
            chair_id = player.chair_id,
            done = true,
        }
    })

    self:cancel_auto_action_timer(player)

    if not table.And(self.players,function(p) return p.baoting ~= nil end) then
        return
    end

    self:cancel_clock_timer()
    
    local log_players = self.game_log.players
    local p_baotings = {}
    self:foreach(function(p)
        log_players[p.chair_id].baoting = p.baoting
        tinsert(p_baotings,{
            chair_id = p.chair_id,
            baoting = p.baoting,
        })
    end)

    self:broadcast2client("SC_BaotingCommit",{
        baotings = p_baotings,
    })
    -- 报听后开始出牌等    
    self:jump_to_player_index(self.zhuang)
    self:action_after_baoting()
end

function maajan_table:baoting()
    self:update_state(FSM_S.WAIT_BAO_TING)
    self:broadcast2client("SC_AllowBaoting",{})
    local havePlayerCanbaoting = false
    -- 发送玩家是否能报听，能报听的话，就发可听的牌的数据
    self:foreach(function(p)
        if self:send_baoting_tips(p) then
            havePlayerCanbaoting = true
        end        
    end)
    
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type and (trustee_type == 1 or (trustee_type == 2 and self.cur_round > 1)) and havePlayerCanbaoting then
        local function auto_baoting(p)
            local baoting = 0
            log.info("%d",baoting)
            self:on_baoting(p,{
                baoting = baoting
            })
        end
        log.info("baoting clock %s",trustee_type)
        self:begin_clock_timer(trustee_seconds,function()
            self:foreach(function(p)
                if p.baoting ~= nil then return end
                self:set_trusteeship(p,true)
                auto_baoting(p)
            end)
        end)

        log.dump(table.series(self.players,function(p) return p.guid end))
        self:foreach(function(p)
            log.info("%s,%s",p.guid,p.trustee)
            if not p.trustee then return end
            self:begin_auto_action_timer(p,math.random(1,2),function() 
                auto_baoting(p)
            end)
        end)
    end
end

function maajan_table:action_after_baoting()
    local player = self:chu_pai_player()

    local mo_pai = player.mo_pai -- self:choice_first_turn_mo_pai(player)
    -- log.dump(mo_pai)

    log.info("---------fake mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})

    local actions = self:get_actions_first_turn(player,mo_pai)
    log.dump(actions,"action_after_baoting_"..player.guid)
    if table.nums(actions) > 0 then
        self:action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
                session_id = self:session(),
            },
        })
    else
        self:chu_pai()
    end
end

function maajan_table:get_piaofan(winchairid,losechairid)
    local piaofan = 1
    if self.rule.piao and self.rule.piao.piao_option ~= nil then
        piaofan = piaofan * (self.players[winchairid].piao > 0 and 2 or 1)
        piaofan = piaofan * (self.players[losechairid].piao > 0 and 2 or 1)
    end

    return piaofan
end

function maajan_table:get_luobo(chair_id)
    local zhong_luobo_score = 0
    if self.rule.luobo and self.luobo_tiles_count > 0 then
        if self.zhong_luobos and table.nums(self.zhong_luobos[chair_id]) > 0 then
            zhong_luobo_score = table.nums(self.zhong_luobos[chair_id])
        end
    end

    return zhong_luobo_score
end
-- 报听后杠牌，是否影响胡番
function maajan_table:is_baoting_can_gang(p,actions,type,tile)
    local canAction = true
    local player = clone(p)
    log.dump(player.pai,"is_baoting_can_gang_"..player.guid.."_"..tile.."_"..type)
    local pai = player.pai
    local ty_num = pai.shou_pai[TY_VALUE] or 0 
    log.dump(player.baotingInfo,"baotingInfo_"..player.guid)
    local baotingFan = self:get_baoting_maxfan(player.baotingInfo)
    local sub = pai.shou_pai[tile] or 0 
    local shou_pai = player.pai.shou_pai
    local ming_pai = player.pai.ming_pai

    if type == ACTION.AN_GANG then
        table.decr(pai.shou_pai,tile,4)
        tinsert(ming_pai,{
            type = SECTION_TYPE.AN_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
        })
        local ting_tiles = self:ting(player)
        if table.nums(ting_tiles) > 0 then
            local hu_tile_fans = table.series(ting_tiles or {},function(_,tile)
                return {tile = tile,fan = self:hu_fan(player,tile)} 
            end)
            local max_hu_fan = self:get_baoting_maxfan(hu_tile_fans)
            log.info("AN_GANG max_hu_fan:%d,baotingFan:%d",max_hu_fan,baotingFan)
            if max_hu_fan < baotingFan then
                canAction = false
            end
        else
            canAction = false
        end
        -- table.incr(pai.shou_pai,tile,4)
    end
    if type == ACTION.RUAN_AN_GANG then
        if (ty_num + sub) >= 4 then
            table.decr(pai.shou_pai,tile,sub)
            table.decr(pai.shou_pai,TY_VALUE,4-sub)
            log.dump(player.pai,"11 RUAN_AN_GANG_"..player.guid.."_"..tile)
            local ting_tiles = self:ting(player)
            if table.nums(ting_tiles) > 0 then
                local hu_tile_fans = table.series(ting_tiles or {},function(_,tile)
                    return {tile = tile,fan = self:hu_fan(player,tile)} 
                end)
                local max_hu_fan = self:get_baoting_maxfan(hu_tile_fans)
                log.info("RUAN_AN_GANG max_hu_fan:%d,baotingFan:%d",max_hu_fan,baotingFan)
                if max_hu_fan < baotingFan then
                    canAction = false
                end
            else
                canAction = false
            end
            -- table.incr(pai.shou_pai,tile,sub)
            -- table.incr(pai.shou_pai,TY_VALUE,4-sub)
            log.dump(player.pai,"22 RUAN_AN_GANG_"..player.guid.."_"..tile)
        else
            canAction = false
        end
    end

    if type == ACTION.MING_GANG then
        table.decr(pai.shou_pai,tile,3)
        tinsert(ming_pai,{
            type = SECTION_TYPE.MING_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            whoee = self.chu_pai_player_index,
        })
        local ting_tiles = self:ting(player)
        if table.nums(ting_tiles) > 0 then
            local hu_tile_fans = table.series(ting_tiles or {},function(_,tile)
                return {tile = tile,fan = self:hu_fan(player,tile)} 
            end)
            local max_hu_fan = self:get_baoting_maxfan(hu_tile_fans)
            log.info("MING_GANG max_hu_fan:%d,baotingFan:%d",max_hu_fan,baotingFan)
            if max_hu_fan < baotingFan then
                canAction = false
            end
        else
            canAction = false
        end
        -- table.incr(pai.shou_pai,tile,3)
    end
    if type == ACTION.RUAN_MING_GANG then
        if (ty_num + sub) >= 3 then
            table.decr(pai.shou_pai,tile,sub)
            table.decr(pai.shou_pai,TY_VALUE,3-sub)
            local ting_tiles = self:ting(player)
            if table.nums(ting_tiles) > 0 then
                local hu_tile_fans = table.series(ting_tiles or {},function(_,tile)
                    return {tile = tile,fan = self:hu_fan(player,tile)} 
                end)
                local max_hu_fan = self:get_baoting_maxfan(hu_tile_fans)
                log.info("RUAN_MING_GANG max_hu_fan:%d,baotingFan:%d",max_hu_fan,baotingFan)
                if max_hu_fan < baotingFan then
                    canAction = false
                end
            else
                canAction = false
            end
            -- table.incr(pai.shou_pai,tile,sub)
            -- table.incr(pai.shou_pai,TY_VALUE,3-sub)
        else
            canAction = false
        end
    end
    log.dump(canAction,"canAction_"..tile)
    log.dump(p.pai,"p is_baoting_can_gang_"..p.guid)
    log.dump(player.pai,"player is_baoting_can_gang_"..player.guid)
    player = nil
    return canAction
end
-- 报听后不能换牌
function maajan_table:iscandiscard(p,distile,mopai)
    local bdiscard = false
    if p.chair_id == self.zhuang and self.zhuang_first_chu_pai then
        if p.baotingInfo then
            for _, ting in pairs(p.baotingInfo) do
                if ting.discard and ting.tiles_info then
                    if ting.discard == distile then
                        bdiscard = true
                        p.baotingInfo = ting.tiles_info
                        break
                    end
                end
            end
        end
    else
        if p.baotingInfo and mopai then
            if distile == mopai then
                bdiscard = true
            end
        end
    end
    
    return bdiscard
end
-- 获取报听的最大番
function maajan_table:get_baoting_maxfan(baotinginfo)
    local maxfan = 0
    for _, info in pairs(baotinginfo) do
        if info.tiles_info then
            for _, v in pairs(info.tiles_info) do
                if v.fan > maxfan then
                    maxfan = v.fan
                end
            end
        else
            if info.fan > maxfan then
                maxfan = info.fan
            end
        end
    end
    
    return maxfan
end

return maajan_table