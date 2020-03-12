local pb = require "pb_files"
local base_table = require "game.lobby.base_table"
local def 		= require "game.maajan_customized.base.define"
local mj_util 	= require "game.maajan_customized.base.mang_jiang_util"
local log = require "log"
local json = require "cjson"
local maajan_tile_dealer = require "maajan_tile_dealer"
local base_private_table = require "game.lobby.base_private_table"
local enum = require "pb_enums"

require "functions"

local FSM_E  = def.FSM_event
local FSM_S  = def.FSM_state

local ACTION = def.ACTION

local ACTION_PRIORITY = {
    [ACTION.PASS] = 5,
    [ACTION.PENG] = 4,
    [ACTION.AN_GANG] = 3,
    [ACTION.MING_GANG] = 3,
    [ACTION.BA_GANG] = 3,
    [ACTION.FREE_BA_GANG] = 3,
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
local JI_TILE_TYPE = def.JI_TILE_TYPE

local chair_count_tiles = {
    [2] = {
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
    },
    [3] = {
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
    },
    [4] = {
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29,
    }
}

local maajan_table = base_table:new()

-- 初始化
function maajan_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
    self.cur_state_FSM = nil
    
    self.state_event_handle = {
        [FSM_S.WAIT_CHU_PAI] = self.on_action_when_wait_chu_pai,
        [FSM_S.CHECK_TING] = self.on_action_when_check_ting,
        [FSM_S.WAIT_ACTION_AFTER_CHU_PAI] = self.on_action_after_chu_pai,
        [FSM_S.WAIT_ACTION_AFTER_MO_PAI] = self.on_action_after_mo_pai,
        [FSM_S.WAIT_QIANG_GANG_HU] = self.on_qiang_gang_hu,
        [FSM_S.GAME_CLOSE] = self.game_over,
    }
end

function maajan_table:do_ding_zhuang(next_zhuang)
    for chair_id,_ in pairs(self.players) do
        if chair_id ~= next_zhuang then
            self.lian_zhuang[chair_id] = 0
        end
    end
    self.zhuang = next_zhuang
    self.lian_zhuang[next_zhuang] = self.lian_zhuang[next_zhuang] + 1
end

function maajan_table:on_private_inited()
    self.cur_round = nil
    self.zhuang = nil
    self.lian_zhuang = nil
    self.tiles = chair_count_tiles[self.chair_count or 4]
end

function maajan_table:on_private_dismissed()
    self.cur_round = nil
    self.zhuang = nil
    self.lian_zhuang = nil
    self.tiles = nil
    self.cur_state_FSM = nil
    for _,p in pairs(self.players) do
        p.total_money = nil
    end
end

function maajan_table:on_started()
    base_table.on_started(self)
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
        }
        v.ting                  = nil
        v.men                   = nil
        v.jiao                  = nil

        v.ji                    = {
            chong_feng = {
                wu_gu = false,
                normal = false,
            },
            zhe_ren = {
                wu_gu = false,
                normal = false,
            }
        }

        v.mo_pai = nil
        v.chu_pai = nil
        v.free_an_gang_tiles = nil
    end

    self.timer = {}

    if not self.zhuang then 
        self.zhuang = self.private_id and self.conf.owner.chair_id or math.random(1,self.chair_count)
    end

    self.lian_zhuang = self.lian_zhuang or table.fill(nil,0,1,self.chair_count)
    self:do_ding_zhuang(self.zhuang)

	self.chu_pai_player_index      = self.zhuang --出牌人的索引
	self.last_chu_pai              = -1 --上次的出牌
    self.waiting_player_actions    = {}
	self:update_state(FSM_S.PER_BEGIN)
	self.do_logic_update = true
    local game_log_players = {}
    for i = 1,self.chair_count do game_log_players[i] = {} end
    self.game_log = {
        start_game_time = os.time(),
        zhuang = self.zhuang,
        mj_min_scale = self.mj_min_scale,
        players = game_log_players,
        action_table = {},
        rule = self.private_id and self.conf.conf or nil,
        table_id = self.private_id or nil,
    }

    local tiles = chair_count_tiles[self.chair_count]
    if not tiles then
        log.error("maajan_table:start tiles is nil.check private_table rule.")
    end

    local all_tiles = clone(tiles)
    if self.conf.conf.play.dai_zhong and self.chair_count == 4 then
        for _ = 1,4 do table.insert(all_tiles,35) end
    end
    
    self.dealer = maajan_tile_dealer:new(all_tiles)

    self:on_pre_begin()
end

function maajan_table:on_pre_begin(evt)
    self:update_state(FSM_S.XI_PAI)
    self:on_xi_pai()
end

function maajan_table:on_xi_pai(evt)
    self:prepare_tiles()

    for _,v in pairs(self.players) do
        self:send_data_to_enter_player(v)
    end

    self.chu_pai_player_index = self.zhuang
    
    for k,v in pairs(self.players) do
        self.game_log.players[k].start_pai = self:tile_count_2_tiles(v.pai.shou_pai)
    end

    self:on_check_ting()
end

function maajan_table:do_qiang_gang_hu(actions)
    for chair_id,action in pairs(actions) do
        local do_action = action.done
        if do_action == ACTION.HU then
            local tile = action.actions[do_action]
            local player = self.players[chair_id]
            player.hu = {
                tile = tile,
                whoee = self.chu_pai_player_index,
                qiang_gang = true,
            }
            self:log_game_action(player,do_action,tile)
            self:broadcast_player_hu(player,do_action)
        end
    end

    if table.logic_or(self.players,function(p) return p.hu end) then
        self:on_game_balance()
    end
end

function maajan_table:go_on_ba_gang_without_qiang_gang(tile)
    local player = self:chu_pai_player()
    self:adjust_shou_pai(player,player.last_action,tile)
    self:log_game_action(player,player.last_action,tile)
    self:jump_to_player_index(player)
    self:do_mo_pai()
end

function maajan_table:wait_qiang_gang_hu(actions)
    self:update_state(FSM_S.WAIT_QIANG_GANG_HU)
    self.waiting_player_actions = actions
    for _,acts in pairs(actions) do
        self:send_action_waiting(acts)
    end
end

function maajan_table:on_qiang_gang_hu(event)
    local chair_id = event.chair_id
    local tile = event.tile
    local action = event.type

    local player = self.players[chair_id]
    if not player then
        log.error("but player is nil,chair_id:%s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    local w_act = self.waiting_player_actions[chair_id]
    if (not w_act or not w_act.actions or not w_act.actions[action]) and action ~= ACTION.PASS then
        log.error("not action is wating,chair_id:%s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    if action ~= ACTION.HU and action ~= ACTION.PASS then
        log.error("not action is wating,chair_id:%s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    self.waiting_player_actions[chair_id].done = action
    if not table.logic_and(self.waiting_player_actions,function(act) return act.done ~= nil end) then
        return
    end

    local actions = table.value(self.waiting_player_actions)
    table.sort(actions,function(l,r)
        local l_priority = ACTION_PRIORITY[l.done.action]
        local r_priority = ACTION_PRIORITY[r.done.action]
        return l_priority < r_priority
    end)

    if table.logic_and(actions,function(act) return act.done.action == ACTION.PASS end) then
        self:go_on_ba_gang_without_qiang_gang(tile)
        return
    end

    self.waiting_player_actions = {}
    self:do_qiang_gang_hu(actions)
end

function maajan_table:on_action_when_check_ting(event)
    local chair_id = event.chair_id
    local tile = event.tile
    local action = event.type

    local player = self.players[chair_id]
    if not player then
        log.error("but player is nil,chair_id:%s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    local w_act = self.waiting_player_actions[chair_id]
    if (not w_act or not w_act.actions or not w_act.actions[action]) and action ~= ACTION.PASS then
        log.error("not action is wating,chair_id:%s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    self.waiting_player_actions[chair_id].done = action
    local actions = w_act.actions
    if action == ACTION.TING then
        local ting_tiles = actions[ACTION.TING]
        player.ting = {
            tiles = ting_tiles,
            ying_bao = true,
        }

        self:broadcast2client("SC_Maajan_Do_Action",{
            chair_id = chair_id,
            action = ACTION.TING,
        })

        self:log_game_action(player,ACTION.TING,tile)

        dump(self.waiting_player_actions)
    end

    if not table.logic_and(self.waiting_player_actions,function(act) return act.done ~= nil end) then
        return
    end

    self.waiting_player_actions = {}
    self:do_mo_pai()
end

function maajan_table:wait_chu_pai()
    self:update_state(FSM_S.WAIT_CHU_PAI)
    self:broadcast_desk_state()
    self:broadcast2client("SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
end

function maajan_table:send_action_waiting(action)
    local chair_id = action.chair_id
    log.info("send_action_waiting,%s",chair_id)
    local actions = {}
    for act,tiles in pairs(action.actions) do
        if act == ACTION.TING then
            self:send_ting(self.players[chair_id],tiles)
        else
            for tile,_ in pairs(tiles) do
                table.insert(actions,{
                    action = act,
                    tile = tile,
                })
            end
        end
    end

    send2client_pb(self.players[chair_id],"SC_WaitingDoActions",{
        chair_id = chair_id,
        actions = actions,
    })
end

function maajan_table:wait_action_after_chu_pai(actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_CHU_PAI)
    self.waiting_player_actions = actions
    for _,action in pairs(actions) do
        self:send_action_waiting(action)
    end
end

function maajan_table:wait_action_after_mo_pai(actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_MO_PAI)
    for chair_id,action in pairs(actions) do
        self.waiting_player_actions[chair_id] = self.waiting_player_actions[chair_id] or {}
        table.mergeto(self.waiting_player_actions[chair_id],action)

        if actions[ACTION.TING] then
            self:send_ting(self.players[chair_id],action[ACTION.TING])
        end
        self:send_action_waiting(action)
    end
end

function maajan_table:prepare_tiles()
    self.dealer:shuffle()
    local pre_tiles = {
        -- [1] = {11,11,11,12,12,12,21,22,23,24,25,26,27},
        -- [2] = {22,22,23,23,24,24,25,25,26,26,27,27,28},
    }

    for i,pretiles in pairs(pre_tiles) do
        local p = self.players[i]
        if not p then
            log.error("prepare_tiles got nil player,chair_id:%d",i)
            break
        end
        for _,tile in pairs(pretiles) do
            local is = self.dealer:deal_one_on(function(t) return t == tile end)
            if is > 0 then
                table.incr(p.pai.shou_pai,tile)
            else
                log.error("prepare_tiles deal tile is 0")
            end
        end
    end

    for i = 1,self.chair_count do
        if not pre_tiles[i] then
            local p = self.players[i]
            local tiles = self.dealer:deal_tiles(13)
            for _,t in pairs(tiles) do
                table.incr(p.pai.shou_pai,t)
            end
        end
    end
end

function maajan_table:get_actions(p,mo_pai,in_pai)
    if  not p.ting and not p.men and table.nums(p.pai.ming_pai) == 0 and
        (p.chu_pai_count == 0 or (self.conf.rule.yi_zhang_bao_ting and p.chu_pai_count == 1)) then
        local ting_tiles = mj_util.is_ting(p.pai)
        if table.nums(ting_tiles) > 0 and not mo_pai and not in_pai then
            return {
                [ACTION.TING] = ting_tiles,
            }
        end
    end

    local actions = mj_util.get_actions(p.pai,mo_pai,in_pai)
    if p.ting then
        actions[ACTION.PENG] = nil
        actions[ACTION.AN_GANG] = nil
        actions[ACTION.MING_GANG] = nil
        actions[ACTION.BA_GANG] = nil
        actions[ACTION.FREE_BA_GANG] = nil
        actions[ACTION.FREE_AN_GANG] = nil
        if (actions[ACTION.MEN] or actions[ACTION.MEN_ZI_MO]) and not self.conf.rule.bao_ting_ke_men then
            actions[ACTION.MEN] = nil
            actions[ACTION.MEN_ZI_MO] = nil
        end
    end

    if mo_pai then
        if  not p.ting and not p.men and
            (p.chu_pai_count == 0 or
            (self.conf.rule.yi_zhang_bao_ting and p.chu_pai_count == 1)) and
            table.nums(p.pai.ming_pai) == 0 then
            local pai = clone(p.pai)
            table.incr(pai.shou_pai,mo_pai)
            local ting_tiles = mj_util.is_ting_full(pai)
            if table.nums(ting_tiles) > 0 then
                actions[ACTION.TING] = ting_tiles
            end
        end
    end

    if p.men then
        actions[ACTION.PENG] = nil
        actions[ACTION.AN_GANG] = nil
        actions[ACTION.MING_GANG] = nil
        actions[ACTION.BA_GANG] = nil
        actions[ACTION.FREE_BA_GANG] = nil
        actions[ACTION.FREE_AN_GANG] = nil
    end

    if actions[ACTION.AN_GANG] and p.free_an_gang_tiles then
        for tile,_ in pairs(actions[ACTION.AN_GANG]) do
            if p.free_an_gang_tiles[tile] then
                actions[ACTION.AN_GANG][tile] = nil
                table.get(actions,ACTION.FREE_AN_GANG,{})[tile] = true
            end
        end
    end

    return actions
end

function maajan_table:on_action_when_wait_chu_pai(evt)
    local action_handle = {
        [ACTION.AN_GANG] = self.on_gang_when_wait_chu_pai,
        [ACTION.CHU_PAI] = self.on_chu_pai_when_wait_chu_pai,
        [ACTION.BA_GANG] = self.on_gang_when_wait_chu_pai,
        [ACTION.HU] = self.on_hu_when_wait_chu_pai,
        [ACTION.ZI_MO] = self.on_hu_when_wait_chu_pai,
        [ACTION.PASS] = function(...) end,
    }

    local f = action_handle[evt.type]
    if f then
        f(self,evt)
    else
        log.error("maajan_table:on_action_when_wait_chu_pai action:%s",evt.type)
    end
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
    for _,p in pairs(self.players) do
        if p ~= player then
            p.last_action = nil
        end
    end
end

function maajan_table:do_sorted_actions_after_chu_pai(actions)
    local top_action
    local actions_to_do = {}
    for _,action in pairs(actions) do
        top_action = top_action or action
        if action.done.action ~= top_action.done.action then 
            break
        end
        table.insert(actions_to_do,action)
    end
    self:do_action_after_chu_pai(actions_to_do)
end

function maajan_table:do_action_after_chu_pai(do_actions)
    local action = do_actions[1]

    local chu_pai_player = self:chu_pai_player()

    local player = self.players[action.chair_id]
    if not player then
        log.error("do action %s,nut wrong player in chair %s",action.done.action,action.chair_id)
        return
    end

    local tile = action.done.tile
    if action.done.action == ACTION.PENG then
        self:check_ji_tile_when_peng_gang(player,action.done.action,tile)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,action.done.action,tile)
        self:log_game_action(player,action.done.action,tile)
        self:jump_to_player_index(player)
        self:wait_chu_pai()
    end

    if action.done.action == ACTION.TING then
        if not player then return end
        player.ting = player.ting or {}
        player.ting.ruan_bao = true
    end

    if def.is_action_gang(action.done.action) then
        self:check_ji_tile_when_peng_gang(player,action.done.action,tile)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,action.done.action,tile)
        self:log_game_action(player,action.done.action,tile)
        self:jump_to_player_index(player)
        self:do_mo_pai()
    end

    if action.done.action == ACTION.HU then
        for _,act in pairs(do_actions) do
            local p = self.players[act.chair_id]
            p.hu = {
                time = os.time(),
                tile = tile,
                types = mj_util.hu(p.pai,tile),
                zi_mo = false,
                whoee = self.chu_pai_player_index,
                gang_pao = def.is_action_gang(chu_pai_player.last_action or 0),
            }

            self:log_game_action(p,act.done.action,tile)
            self:broadcast_player_hu(p,act.done.action)
        end
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:on_game_balance()
    end

    if action.done.action == ACTION.MEN then
        for _,act in pairs(do_actions) do
            local p = self.players[act.chair_id]
            p.men = p.men or {}
            table.insert(p.men,{
                time = os.time(),
                tile = tile,
                types = mj_util.hu(p.pai,tile),
                whoee = self.chu_pai_player_index,
                zi_mo = false,
            })

            self:log_game_action(p,act.done.action,tile)
            self:broadcast_player_men(p,act.done.action,tile)
        end

        table.pop_back(chu_pai_player.pai.desk_tiles)
        table.sort(do_actions,function(l,r) return l.chair_id < r.chair_id end)
        self:jump_to_player_index(self.players[do_actions[#do_actions].chair_id])
        self:next_player_index()
        self:do_mo_pai()
    end

    if def.is_action_chi(action.done.action) then
        if not action[action.done.action][tile] then
            return
        end

        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,action.done.action,tile)
        self:log_game_action(player,action.done.action,tile)
        self:jump_to_player_index(player)
        self:wait_chu_pai()
    end

    if action.done.action == ACTION.PASS then
        self:next_player_index()
        self:do_mo_pai()
    end

    self:done_last_action(player,action.done.action)
end

function maajan_table:on_action_after_mo_pai(evt)
    local do_action = evt.type
    local chair_id = evt.chair_id
    local tile = evt.tile
    if chair_id ~= self.chu_pai_player_index then
        log.error("do action:%s but chair_id:%s is not current chair_id:%s after mo_pai",
            do_action,chair_id,self.chu_pai_player_index)
        return
    end

    dump(self.waiting_player_actions)
    local player = self:chu_pai_player()
    if not player then
        log.error("do action %s,but wrong player in chair %s",do_action,player.chair_id)
        return
    end

    local player_actions = self.waiting_player_actions[player.chair_id].actions
    if not player_actions[do_action] and do_action ~= ACTION.PASS and do_action ~= ACTION.CHU_PAI then
        log.error("do action %s,but action is illigle,%s",do_action)
        return
    end

    local self_waiting_actions = self.waiting_player_actions[player.chair_id] and self.waiting_player_actions[player.chair_id].actions
    local waiting_an_gang_tiles = self_waiting_actions[ACTION.AN_GANG] or self_waiting_actions[ACTION.FREE_AN_GANG]

    self.waiting_player_actions = {}--只能写在此处，do_mo_pai有可能会覆盖此值
    
    if do_action == ACTION.BA_GANG or do_action == ACTION.FREE_BA_GANG then
        local qiang_gang_hu = {}
        self:foreach_except(player,function(p)
            local actions = self:get_actions(p,nil,tile)
            if actions[ACTION.HU] then
                qiang_gang_hu[p.chair_id] = true
            end
        end)

        self:log_game_action(player,do_action,tile)
        if table.nums(qiang_gang_hu) == 0 then
            self:adjust_shou_pai(player,do_action,tile)
            self:jump_to_player_index(player)
            self:do_mo_pai()
        else
            for chair,_ in pairs(qiang_gang_hu) do
                local p = self.players[chair]
                self:log_game_action(p,ACTION.HU,tile)
                p.hu = {
                    time = os.time(),
                    tile = tile,
                    types = mj_util.hu(p.pai,tile),
                    whoee = player.chair_id,
                    qiang_gang = true,
                }
                self:broadcast_player_hu(p,do_action)
            end
            
            self:on_game_balance()
        end
    end

    if do_action == ACTION.AN_GANG or do_action == ACTION.FREE_AN_GANG then
        self:adjust_shou_pai(player,do_action,tile)
        self:log_game_action(player,do_action,tile)
        self:jump_to_player_index(player)
        self:do_mo_pai()
    end

    if do_action == ACTION.ZI_MO then
        player.hu = {
            time = os.time(),
            tile = tile,
            types = mj_util.hu(player.pai),
            zi_mo = true,
            gang_hua = def.is_action_gang(player.last_action or 0),
        }

        if self.zhuang == chair_id and player.chu_pai_count == 0 then
            player.ting = {
                ying_bao = true,
            }
        end

        self:log_game_action(player,do_action,tile)
        self:broadcast_player_hu(player,do_action)
        self:on_game_balance()
    end

    if do_action == ACTION.MEN_ZI_MO then
        table.decr(player.pai.shou_pai,tile)
        player.men = player.men or {}
        table.insert(player.men,{
            time = os.time(),
            tile = tile,
            types = mj_util.hu(player.pai,tile),
            zi_mo = true,
        })

        self:log_game_action(player,do_action,tile)
        self:broadcast_player_men(player,do_action,tile)
        self:jump_to_player_index(player)
        self:next_player_index()
        self:do_mo_pai()
    end

    if do_action == ACTION.TING then
        self:broadcast2client("SC_Maajan_Do_Action",{chair_id = player.chair_id,action = do_action,})
        self:do_chu_pai(tile)

        local ting_tiles = player_actions[ACTION.TING]
        player.ting = {
            tiles = ting_tiles[tile],
            ruan_bao = true,
        }

        if waiting_an_gang_tiles then
            player.free_an_gang_tiles = waiting_an_gang_tiles
        end
    end

    if do_action == ACTION.PASS then
        if waiting_an_gang_tiles then
            player.free_an_gang_tiles = waiting_an_gang_tiles
        end
        self:wait_chu_pai()
    end

    self:done_last_action(player,do_action)
end

function maajan_table:check_action_before_do(event)
    local action = event.type
    local chair_id = event.chair_id
    local tile = event.tile
    local waiting_action = self.waiting_player_actions[chair_id]
    if not waiting_action then
        log.error("no action waiting when check_action_before_do,chair_id,action:%s,tile:",chair_id,action,tile)
        return
    end

    local actions = waiting_action.actions
    if not actions then
        log.error("on action %s,%s,actions is nil",chair_id,tile)
        return
    end

    if action == ACTION.PASS then
        return waiting_action
    end

    if def.is_action_gang(action) then
        if not actions[action] or not actions[action][tile] then
            log.error("no action waiting when check_action_before_do,chair_id,action:%s,tile:%s",chair_id,action,tile)
            return
        end
    end

    return waiting_action
end

function maajan_table:on_action_after_chu_pai(evt)
    local waiting_actions = self:check_action_before_do(evt)
    if not waiting_actions then
        return
    end

    waiting_actions.done = {
        action = evt.type,
        tile = evt.tile,
    }

    if not table.logic_and(self.waiting_player_actions,function(action)
        return action.done ~= nil
    end) then
        return
    end

    local all_actions = {}

    for _,action in pairs(self.waiting_player_actions) do
        if action.done.action ~= ACTION.PASS then
            table.insert(all_actions,action)
        end
    end

    if table.nums(all_actions) == 0 then
        self.waiting_player_actions = {}
        self:next_player_index()
        self:do_mo_pai()
        return
    end

    table.sort(all_actions,function(l,r)
        local l_priority = ACTION_PRIORITY[l.done.action]
        local r_priority = ACTION_PRIORITY[r.done.action]
        return l_priority < r_priority
    end)

    self.waiting_player_actions = {}
    self:do_sorted_actions_after_chu_pai(all_actions)
end

function maajan_table:on_check_ting()
    self:update_state(FSM_S.CHECK_TING)
    local has_ting = false
    for chair_id,player in pairs(self.players) do
        if chair_id ~= self.zhuang then
            local actions = self:get_actions(player)
            if actions[ACTION.TING] then
                has_ting = true
                self.waiting_player_actions[chair_id] = {
                    chair_id = chair_id,
                    actions = actions,
                }

                self:send_ting(player,actions[ACTION.TING])
            end
        end
    end

    if not has_ting then
        self:do_mo_pai()
    end
end

function maajan_table:send_ting(player,ting_tiles)
    if table.nums(ting_tiles) == 0 then
        return
    end

    local ting = {}
    for discard,tiles in pairs(ting_tiles) do
        if type(tiles) == "table" then
            table.insert(ting,{discard = discard,tiles = table.keys(tiles),})
        else
            ting[1] = ting[1] or {tiles = {}}
            table.insert(ting[1].tiles,discard)
        end
    end

    send2client_pb(player,"SC_WaitingTing",{
        ting = ting,
    })
end

function maajan_table:on_mo_pai(mo_pai)
    for k,p in pairs(self.players) do
        if p.chair_id == self.chu_pai_player_index then
            p.mo_pai = mo_pai
            p.mo_pai_count = p.mo_pai_count + 1
            send2client_pb(p,"SC_Maajan_Draw",{tile = mo_pai,chair_id = k})
        else
            send2client_pb(p,"SC_Maajan_Draw",{tile = 255,chair_id = self.chu_pai_player_index})
            p.mo_pai = nil
        end
    end
end

function maajan_table:do_mo_pai()
    self:update_state(FSM_S.WAIT_MO_PAI)
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai

    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 0 then
        self:on_game_balance()
        return
    end

    local mo_pai
    mo_pai = self.dealer:deal_one()
    if not mo_pai then
        self:on_game_balance()
        return
    end

    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    local actions = self:get_actions(player,mo_pai)
    dump(actions)
    table.incr(shou_pai,mo_pai)
    log.info("---------mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Draw",msg = {tile = mo_pai}})
    self:on_mo_pai(mo_pai)

    if table.nums(actions) > 0 then
        self:wait_action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
            }
        })
    else
        self:wait_chu_pai()
    end

    self:auto_act_if_deposit(player,actions,mo_pai)
end

function maajan_table:on_timeout_when_wait_chu_pai(evt)
    local player = self:chu_pai_player()
    self:do_chu_pai(player.mo_pai)
    self:increase_time_out_and_deposit(player)
end

function maajan_table:on_chu_pai_when_wait_chu_pai(evt)
    self:do_chu_pai(evt.tile)
end

function maajan_table:on_gang_when_wait_chu_pai(evt)
    local cur_chu_pai_player = self:chu_pai_player()
    
    if cur_chu_pai_player.chair_id == evt.chair_id then
        local _,last_tile = self:get_last_chu_pai()
        local actions = self:get_actions(cur_chu_pai_player,nil,last_tile)
        local gangtile = evt.tile
        if actions[ACTION.AN_GANG] and actions[ACTION.AN_GANG][gangtile] then
            self:adjust_shou_pai(cur_chu_pai_player,ACTION.AN_GANG,gangtile)
            self:do_mo_pai()
        end

        if actions[ACTION.BA_GANG] and actions[ACTION.BA_GANG][gangtile] then
            cur_chu_pai_player.chu_pai = gangtile
            self:adjust_shou_pai(cur_chu_pai_player,ACTION.BA_GANG,gangtile)

            local hu_player = {}
            local player_actions = {}
            for k,v in pairs(self.players) do
                if v and k ~= self.chu_pai_player_index then --排除自己
                    actions = self:get_actions(v,nil, last_tile)
                    actions.chair_id = v.chair_id
                    if actions[ACTION.HU] then
                        hu_player = v
                        if self:hu_fan_match(hu_player) then
                            player_actions[k] = actions
                        end
                    end
                end
            end
            
            if #player_actions == 0 then
                self:do_mo_pai()
            else
                self.waiting_player_actions = player_actions
                self:update_state(FSM_S.WAIT_BA_GANG_HU)
                self:auto_act_if_deposit(hu_player,"hu_ba_gang")
            end
        end
    end
end

function maajan_table:on_hu_when_wait_chu_pai(evt) --自摸胡
    local player = self.players[self.chu_pai_player_index]
    if player.chair_id ~= evt.chair_id then
        return
    end

    player.hu.types = mj_util.hu(player.pai,evt.tile)
    if #player.hu.types > 0 then
        if player.mo_pai_count == 0 and self.chu_pai_player_index == self.zhuang then
            player.tian_hu = true -- 天胡
        elseif player.mo_pai_count == 1 and not player.has_done_chu_pai then
            player.di_hu = true -- 地胡
        end

        if self:hu_fan_match(player) then
            local _,last_chu_tile = self:get_last_chu_pai()
            player.hu = {
                time = os.time(),
                tile = last_chu_tile,
                types = mj_util.hu(player.pai,last_chu_tile),
                zi_mo = true,
            }
            self:broadcast_player_hu(player,ACTION.ZI_MO)
            self:on_game_balance()
        end
    end
end


function maajan_table:can_ting(player)
    return #mj_util.is_ting(player.pai) > 0
end

function maajan_table:get_hu_items(hu)
    return self:max_hu_score(hu.types).types
end

local BalanceItemType = {
    Hu = pb.enum("Maajan_Balance_Item.ItemType","Hu"),
    ZiMo = pb.enum("Maajan_Balance_Item.ItemType","ZiMo"),
    Men = pb.enum("Maajan_Balance_Item.ItemType","Men"),
    MenZiMo = pb.enum("Maajan_Balance_Item.ItemType","MenZiMo"),
}

function maajan_table:calculate_yi_kou_er(p,hu)
    local typescores = {}
    local yi_kou_er_score = HU_TYPE_INFO[HU_TYPE.ZHUANG].score
    if not hu.zi_mo then
        typescores[p.chair_id] = {}
        typescores[hu.whoee] = {}

        if p.chair_id == self.zhuang then
            table.insert(typescores[p.chair_id],{
                score = yi_kou_er_score,type = HU_TYPE.ZHUANG,count = 1,
            })

            table.insert(typescores[hu.whoee],{
                score = -yi_kou_er_score,type = HU_TYPE.ZHUANG,count = 1,
            })
        elseif self.zhuang == hu.whoee then
            table.insert(typescores[p.chair_id],{
                score = yi_kou_er_score,type = HU_TYPE.ZHUANG,count = 1,
            })

            table.insert(typescores[hu.whoee],{
                score = -yi_kou_er_score,type = HU_TYPE.ZHUANG,count = 1,
            })
        end
    else
        for chair_id,_ in pairs(self.players) do
            typescores[chair_id] = {}
        end

        if self.zhuang == p.chair_id then
            for _,pj in pairs(self.players) do
                if p == pj then
                    table.insert(typescores[p.chair_id],{
                        score = yi_kou_er_score ,type = HU_TYPE.ZHUANG,count = (self.chair_count - 1),
                    })
                else
                    table.insert(typescores[pj.chair_id],{
                        score =  - yi_kou_er_score,type = HU_TYPE.ZHUANG,count = 1,
                    })
                end
            end
        else
            table.insert(typescores[p.chair_id],{
                score = yi_kou_er_score ,type = HU_TYPE.ZHUANG,count = 1,
            })
            table.insert(typescores[self.zhuang],{
                score =  - yi_kou_er_score,type = HU_TYPE.ZHUANG,count = 1,
            })
        end
    end
    return typescores
end

function maajan_table:calculate_lian_zhuang(p,hu)
    local typescores = {}
    if not hu.zi_mo then
        typescores[p.chair_id] = {}
        typescores[hu.whoee] = {}

        local _,lian_zhuang_count = table.max({self.lian_zhuang[p.chair_id],self.lian_zhuang[hu.whoee]})
        if self.lian_zhuang[p.chair_id] > 0 or self.lian_zhuang[hu.whoee] > 0 then
            table.insert(typescores[p.chair_id],{
                score = lian_zhuang_count,type = HU_TYPE.LIAN_ZHUANG,count = 1,
            })

            table.insert(typescores[hu.whoee],{
                score = -lian_zhuang_count,type = HU_TYPE.LIAN_ZHUANG,count = 1,
            })
        end
    else
        for chair_id,_ in pairs(self.players) do
            typescores[chair_id] = {}
        end

        local max_chair_id,lian_zhuang_count = table.max(self.lian_zhuang)
        local lian_zhuang_score = lian_zhuang_count * HU_TYPE_INFO[HU_TYPE.LIAN_ZHUANG].score
        if max_chair_id == p.chair_id then
            for _,pj in pairs(self.players) do
                if p == pj then
                    table.insert(typescores[p.chair_id],{
                        score = lian_zhuang_score ,type = HU_TYPE.LIAN_ZHUANG,count = (self.chair_count - 1),
                    })
                else
                    table.insert(typescores[pj.chair_id],{
                        score =  - lian_zhuang_score,type = HU_TYPE.LIAN_ZHUANG,count = 1,
                    })
                end
            end
        else
            table.insert(typescores[p.chair_id],{
                score = lian_zhuang_score ,type = HU_TYPE.LIAN_ZHUANG,count = 1,
            })
            table.insert(typescores[max_chair_id],{
                score =  - lian_zhuang_score,type = HU_TYPE.LIAN_ZHUANG,count = 1,
            })
        end
    end
    return typescores
end

function maajan_table:calculate_zhuang(p,hu)
    if self.conf.rule.yi_kou_er then
        return self:calculate_yi_kou_er(p,hu)
    elseif self.conf.rule.lian_zhuang then
        return self:calculate_lian_zhuang(p,hu)
    end

    return {}
end

function maajan_table:calculate_hu(p,hu)
    local types = {}
    local ts = self:get_hu_items(hu)
    if not hu.zi_mo then
        local hu_fan = 2 ^ 0

        if hu.gang_pao then
            table.insert(table.get(types,p.chair_id,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                type = HU_TYPE.GANG_SHANG_PAO, score = HU_TYPE_INFO[HU_TYPE.GANG_SHANG_PAO].score,count = 1,
            })

            table.insert(table.get(types,hu.whoee,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                type = HU_TYPE.GANG_SHANG_PAO, score = - HU_TYPE_INFO[HU_TYPE.GANG_SHANG_PAO].score,count = 1,
            })
        end

        if hu.qiang_gang then
            table.insert(table.get(types,p.chair_id,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                type = HU_TYPE.QIANG_GANG_HU, score = HU_TYPE_INFO[HU_TYPE.QIANG_GANG_HU].score,count = 1,
            })

            table.insert(table.get(types,hu.whoee,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                type = HU_TYPE.QIANG_GANG_HU, score = - HU_TYPE_INFO[HU_TYPE.QIANG_GANG_HU].score,count = 1,
            })
        end

        for _,t in pairs(ts) do
            table.insert(table.get(types,p.chair_id,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                score = t.score * hu_fan,type = t.type,tile = hu.tile,count = 1,
            })

            table.insert(table.get(types,hu.whoee,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                score = -t.score * hu_fan,type = t.type,tile = hu.tile,count = 1,
            })
        end
    else
        local hu_fan = 2 ^ (HU_TYPE_INFO[HU_TYPE.ZI_MO].fan or 0)
        for chair_id,_ in pairs(self.players) do
            types[chair_id] = {
                type = BalanceItemType.ZiMo,
                typescore = {},
            }
        end

        if hu.gang_hua then
            local t = HU_TYPE.GANG_SHANG_HUA
            local gang_hua_score = HU_TYPE_INFO[t].score
            for chair_id,pj in pairs(self.players) do
                if pj ~= p then
                    table.insert(types[chair_id].typescore,{score = - gang_hua_score,type = t,count = 1})
                else
                    table.insert(types[chair_id].typescore,{score = gang_hua_score,type = t,count = self.chair_count - 1})
                end
            end
        end

        for _,t in pairs(ts) do
            for chair_id,pj in pairs(self.players) do
                if p == pj then
                    table.insert(types[chair_id].typescore,{
                        score = t.score * hu_fan,type = t.type,tile = hu.tile,count = self.chair_count - 1,
                    })
                else
                    table.insert(types[chair_id].typescore,{
                        score = -t.score * hu_fan,type = t.type,tile = hu.tile,count = 1,
                    })
                end
            end
        end
    end

    dump(types)

    local zhuang_typescores = self:calculate_zhuang(p,hu)
    for c,typescore in pairs(zhuang_typescores) do
        types[c] = types[c] or {
            type = hu.zi_mo and BalanceItemType.ZiMo or BalanceItemType.Hu,
            typescore = {}
        }
        table.unionto(types[c].typescore,typescore)
    end

    local ting_typescores = self:calculate_ting(p)
    for c,typescore in pairs(ting_typescores) do
        types[c] = types[c] or {
            type = hu.zi_mo and BalanceItemType.ZiMo or BalanceItemType.Hu,
            typescore = {}
        }
        table.unionto(types[c].typescore,typescore)
    end

    return types
end

function maajan_table:calculate_men(p,men)
    local hu_count = table.sum(self.players,function(pi) return pi.hu and 1 or 0 end)
    local jiao_count = table.sum(self.players,function(pi) return (pi.jiao or pi.ting or pi.men) and 1 or 0 end)
    if jiao_count == 0 or (jiao_count == table.sum(self.players,function(_) return 1 end) and hu_count == 0)  then
        return {}
    end

    local menee_count = 0
    if  hu_count > 0 then
        menee_count = table.sum(self.players,function(pj) return pj ~= p and 1 or 0 end)
    else
        menee_count = table.sum(self.players,function(pj) return (pj ~= p and not (pj.jiao or pj.men or not pj.ting)) and 1 or 0 end)
    end

    local types = {}
    local ts = self:get_hu_items(men)
    table.walk(ts,function(t)
        if men.zi_mo then
            local hu_fan = 2 ^ HU_TYPE_INFO[HU_TYPE.ZI_MO].fan
            if menee_count > 0 then
                table.insert(table.get(types,p.chair_id,{
                    type = BalanceItemType.MenZiMo,
                    typescore = {}
                }).typescore,{score = t.score * hu_fan,type = t.type,tile = men.tile,count = menee_count})
                self:foreach_except(p,function(pj,j)
                    if hu_count > 0 or not (pj.jiao or pj.men or pj.ting) then
                        table.insert(table.get(types,j,{
                            type = BalanceItemType.MenZiMo,
                            typescore = {}
                        }).typescore,{type = t.type,score = - t.score * hu_fan,tile = men.tile,count = 1})
                    end
                end)
            end

            return
        end

        local pj = self.players[men.whoee]
        if hu_count > 0 or not (pj.jiao or pj.men or pj.ting) then
              table.insert(table.get(types,p.chair_id,{
                type = BalanceItemType.Men,
                typescore = {}
            }).typescore,{type = t.type,score = t.score,tile = men.tile,count = 1})

            table.insert(table.get(types,men.whoee,{
                type = BalanceItemType.Men,
                typescore = {}
            }).typescore,{type = t.type,score = -t.score,tile = men.tile,count = 1})
        end
    end)

    return types
end

function maajan_table:get_gang_items(p)
    local items = {}
    for _,s in pairs(p.pai.ming_pai or {}) do
        if s.type == SECTION_TYPE.AN_GANG then
            local an_gang_score = HU_TYPE_INFO[HU_TYPE.AN_GANG].score
            table.insert(items,{score = an_gang_score,type = HU_TYPE.AN_GANG,tile = s.tile,count = 1})
        end

        if s.type == SECTION_TYPE.MING_GANG then
            local ming_gang_score = HU_TYPE_INFO[HU_TYPE.MING_GANG].score
            table.insert(items,{ score = ming_gang_score, type = HU_TYPE.MING_GANG, tile = s.tile,whoee = s.whoee,count = 1})
        end

        if s.type == SECTION_TYPE.BA_GANG then
            local ba_gang_score = HU_TYPE_INFO[HU_TYPE.BA_GANG].score
            table.insert(items,{score = ba_gang_score,type = HU_TYPE.BA_GANG,tile = s.tile,count = 1})
        end
    end

    return items
end


function maajan_table:calculate_gang(p)
    if table.sum(self.players,function(pi) return pi.hu and 1 or 0 end) == 0 then
        return {}
    end

    local is_dian_gang_pao = table.logic_or(self.players,function(pi)
        return p ~= pi and pi.hu and pi.hu.gang_pao and pi.hu.whoee == p
    end)

    local player_count = table.nums(self.players)
    local types = {}
    table.walk(self:get_gang_items(p),function(t)
        if t.whoee then
            if p.hu or p.men or p.ting or p.jiao and not is_dian_gang_pao then
                table.insert(table.get(types,p.chair_id,{}),{type = t.type,score = t.score,tile = t.tile,count = 1})
                table.insert(table.get(types,t.whoee,{}),{type = t.type,score = -t.score,tile = t.tile,count = 1})
            end
            return
        end

        if p.hu or p.men or p.ting or p.jiao and not is_dian_gang_pao then
            table.insert(table.get(types,p.chair_id,{}),{
                type = t.type,score = t.score * (player_count - 1) * t.count,tile = t.tile,count = 1
            })
            self:foreach_except(p.chair_id,function(_,i)
                table.insert(table.get(types,i,{}),{type = t.type,score = -t.score * t.count,tile = t.tile,count = 1})
            end)
        end
    end)

    return types
end

function maajan_table:calculate_ting(p)
    local function get_ting_info(ting)
        local tp = ting.ying_bao and HU_TYPE.YING_BAO or HU_TYPE.RUAN_BAO
        local score = HU_TYPE_INFO[tp].score
        return tp,score
    end

    if not p.hu then return {} end

    local typescores = {}
    if p.ting then
        local ptp,pscore = get_ting_info(p.ting)
        if p.hu.zi_mo then
            table.insert(table.get(typescores,p.chair_id,{}),{type = ptp,score = pscore,count = self.chair_count - 1,})
            self:foreach_except(p.chair_id,function(pi)
                table.insert(table.get(typescores,pi.chair_id,{}),{type = ptp,score = -pscore,count = 1,})
                if pi.ting then
                    local _,piscore = get_ting_info(pi.ting)
                    table.insert(table.get(typescores,pi.chair_id,{}),{type = HU_TYPE.SHA_BAO,score = - piscore,count = 1})
                    table.insert(table.get(typescores,p.chair_id,{}),{type = HU_TYPE.SHA_BAO,score = piscore,count = 1})
                end
            end)
        else
            table.insert(table.get(typescores,p.chair_id,{}),{type = ptp,score = pscore,count = 1})
            local whoee = self.players[p.hu.whoee]
            table.insert(table.get(typescores,whoee.chair_id,{}),{type = ptp,score = -pscore,count = 1})
            if whoee.ting then
                local _,whoeescore = get_ting_info(whoee.ting)
                table.insert(table.get(typescores,whoee.chair_id,{}),{type = HU_TYPE.SHA_BAO,score = - whoeescore,count = 1})
                table.insert(table.get(typescores,p.chair_id,{}),{type = HU_TYPE.SHA_BAO,score = whoeescore,count = 1})
            end
        end
    else
        if p.hu.zi_mo then
            self:foreach_except(p.chair_id,function(pi)
                if pi.ting then
                    local _,score = get_ting_info(pi.ting)
                    table.insert(table.get(typescores,p.chair_id,{}),{type = HU_TYPE.SHA_BAO,score = score,count = 1})
                    table.insert(table.get(typescores,pi.chair_id,{}),{type = HU_TYPE.SHA_BAO,score = - score,count = 1})
                end
            end)
        else
            local whoee = self.players[p.hu.whoee]
            if not whoee.ting then return {} end

            local _,score = get_ting_info(whoee.ting)
            table.insert(table.get(typescores,p.chair_id,{}),{type = HU_TYPE.SHA_BAO,score = score,count = 1})
            table.insert(table.get(typescores,whoee.chair_id,{}),{type = HU_TYPE.SHA_BAO,score = - score,count = 1})
        end
    end

    return typescores
end

function maajan_table:calculate_wei_hu(p)
    local types = {}
    local hu_count = table.sum(self.players,function(pi) return pi.hu and 1 or 0 end)
    local jiao_count = table.sum(self.players,function(pi) return (pi.hu or pi.men or pi.ting or pi.jiao) and 1 or 0 end)
    if hu_count == 0 and jiao_count < self.chair_count then
        if p.jiao or p.ting then
            self:foreach_except(p,function(pi)
                if not (pi.jiao or pi.ting or pi.men or pi.hu) then
                    table.insert(table.get(types,p.chair_id,{
                        type = BalanceItemType.JiaoPai,
                        typescore = {}
                    }).typescore,{type = HU_TYPE.JIAO_PAI,score = 1,whoee = pi.chair_id,count = 1})
                    table.insert(table.get(types,pi.chair_id,{
                        type = BalanceItemType.WeiJiao,
                        typescore = {}
                    }).typescore,{type = HU_TYPE.WEI_JIAO,score = -1,count = 1})
                end
            end)
        end
    end

    return types
end


function maajan_table:get_hong_zhong_items(p)
    local types = {}
  
    table.walk(p.pai.ming_pai or {},function(s)
        if s.tile ~= 35 then return end
        local count = 0
        local whoee = nil
        if s.type == SECTION_TYPE.PENG then
            count = 3
            whoee = s.whoee
        elseif s.type == SECTION_TYPE.AN_GANG or s.type == SECTION_TYPE.MING_GANG or 
            s.type == SECTION_TYPE.BA_GANG or s.type == SECTION_TYPE.FREE_BA_GANG then
            count = 4
            whoee = s.whoee
        else
            return
        end

        table.insert(types,{
            type = HU_TYPE.HONG_ZHONG, tile = 35, score = HU_TYPE_INFO[HU_TYPE.HONG_ZHONG].score * count,count = 1,whoee = whoee
        })
    end)

    local count = 0
    local shou_pai = p.pai.shou_pai

    count = count + (shou_pai[35] or 0)
    local desk_tiles = p.pai.desk_tiles
    for _,tile in pairs(desk_tiles) do
        if tile == 35 then count = count + 1 end
    end

    if count > 0 then
        table.insert(types,{ 
            type = HU_TYPE.HONG_ZHONG, tile = 35, score = HU_TYPE_INFO[HU_TYPE.HONG_ZHONG].score * count,count = 1
        })
    end

    return types
end

function maajan_table:calculate_hong_zhong(p)
    local player_count = table.nums(self.players)
    local types = {}

    local ts = self:get_hong_zhong_items(p)
    table.walk(ts,function(t)
        if t.whoee then
            table.insert(table.get(types,p.chair_id,{}),t)
            if (p.hu or p.men or p.ting or p.jiao) then
                table.insert(table.get(types,t.whoee,{}),{type = t.type,score = -t.score,tile = t.tile,count = t.count})
            end
            return
        end

        table.insert(table.get(types,p.chair_id,{}),{type = t.type,score = t.score * (player_count - 1),tile = t.tile,count = t.count})
        self:foreach_except(p,function(pj)
            if p.hu or p.men or p.ting or p.jiao then
                table.insert(table.get(types,pj.chair_id,{}),{type = t.type,score = -t.score,tile = t.tile,count = t.count})
            end
        end)
    end)

    return types
end

function maajan_table:get_ji_items(p,ji_tiles)
    local p_ming_ji_tiles = {}
    local p_an_ji_tiles = {}
    for tile,c in pairs(p.pai.shou_pai) do
        if c > 0 then
            for t,_ in pairs(ji_tiles[tile] or {}) do
                table.get(p_an_ji_tiles,t,{})[tile] = {count = c}
            end
        end
    end

    for _,s in pairs(p.pai.ming_pai) do
        local tile = s.tile
        local c = (s.type == SECTION_TYPE.PENG and 3 or 4)
        if tile == 21 and p.ji.zhe_ren.normal and ji_tiles[21] then
            table.get(p_ming_ji_tiles,HU_TYPE.ZHE_REN_JI,{})[tile] = {count = 1,whoee = s.whoee,}
        elseif tile == 18 and p.ji.zhe_ren.wu_gu and ji_tiles[18] then
            table.get(p_ming_ji_tiles,HU_TYPE.ZHE_REN_WU_GU,{})[tile] = {count = 1,whoee = s.whoee,}
        end

        for t,_ in pairs(ji_tiles[tile] or {}) do
            table.get(p_ming_ji_tiles,t,{})[tile] = {count = c}
        end
    end

    local desk_tiles = {}
    for _,tile in pairs(p.pai.desk_tiles) do
        if tile == 21 and p.ji.chong_feng.normal and ji_tiles[21] then
            local t = HU_TYPE.CHONG_FENG_JI
            if ji_tiles[21][HU_TYPE.JING_JI] then
                t = HU_TYPE.CHONG_FENG_JING_JI
            end

            table.get(p_ming_ji_tiles,t,{})[tile] = {count = 1}
            p.ji.chong_feng.normal = false
        elseif tile == 18 and p.ji.chong_feng.wu_gu and ji_tiles[18] then
            local t = HU_TYPE.CHONG_FENG_WU_GU
            if ji_tiles[18] and ji_tiles[18][HU_TYPE.JING_WU_GU_JI] then
                t = HU_TYPE.CHONG_FENG_JING_WU_GU
            end

            table.get(p_ming_ji_tiles,t,{})[tile] = {count = 1}
            p.ji.chong_feng.wu_gu = false
        end

        table.incr(desk_tiles,tile)
    end

    for tile,c in pairs(desk_tiles) do
        for t,_ in pairs(ji_tiles[tile] or {}) do
            table.get(p_ming_ji_tiles,t,{})[tile] = {count = c}
        end
    end

    return p_ming_ji_tiles,p_an_ji_tiles
end

function maajan_table:calculate_ji(p,ji_tiles)
    if table.sum(self.players,function(pi) return pi.hu and 1 or 0 end) == 0 then
        return {}
    end

    local is_dian_gang_pao = table.logic_or(self.players,function(pi)
        return pi ~= p and pi.hu and pi.hu.gang_pao and pi.hu.whoee == p.chair_id
    end)

    local player_count = table.nums(self.players)
    local function get_ji_scores(ji_items,is_an_ji)
        local types = {}
        for t,tiles in pairs(ji_items) do
            local tscore = HU_TYPE_INFO[t].score
            table.walk(tiles,function(c,tile)
                -- 碰杠鸡牌结算
                if c.whoee then
                    local who,whoee = p,self.players[c.whoee]
                    if not (p.hu or p.men or p.ting or p.jiao) then
                        if whoee.hu or whoee.men or whoee.ting or whoee.jiao then
                            who,whoee = whoee,who
                        else
                            who,whoee = nil,nil
                        end
                    end

                    if who == p and is_dian_gang_pao then return end

                    if who and whoee then
                        table.insert(table.get(types,who.chair_id,{}),{type = t,score = tscore * c.count,tile = tile,count = 1})
                        table.insert(table.get(types,whoee.chair_id,{}),{type = t,score = -tscore * c.count,tile = tile,count = 1})
                    end
                    return
                end
                
                if p.hu or p.men or p.ting or p.jiao then
                    if is_dian_gang_pao then return end

                    table.insert(table.get(types,p.chair_id,{}),{type = t,score = tscore * c.count,tile = tile,count = player_count - 1})
                    self:foreach_except(p,function(pj)
                        table.insert(table.get(types,pj.chair_id,{}),{type = t,score = -tscore * c.count,tile = tile,count = 1})
                    end)
                    return
                end
                -- 反赔
                if not is_an_ji and
                    (t == HU_TYPE.CHONG_FENG_JI or t == HU_TYPE.CHONG_FENG_WU_GU or t == HU_TYPE.CHONG_FENG_JING_JI or
                        t == HU_TYPE.CHONG_FENG_JING_WU_GU or t == HU_TYPE.NORMAL_JI or t == HU_TYPE.WU_GU_JI) then
                    local jiao_count = table.sum(self.players,function(pi) return (pi.hu or pi.ting or pi.men or pi.jiao) and 1 or 0 end)
                    if jiao_count > 0 then
                        table.insert(table.get(types,p.chair_id,{}),{type = t,score = - tscore * c.count,tile = tile,count = jiao_count})
                        table.walk_on(self.players,function(pj)
                            table.insert(table.get(types,pj.chair_id,{}),{type = t,score = tscore * c.count ,tile = tile,count = 1})
                        end,function(pj)
                            return p ~= pj and (pj.hu or pj.men or pj.ting or pj.jiao)
                        end)
                    end
                end
            end)
        end

        return types
    end

    local ming_ji_items,an_ji_items = self:get_ji_items(p,ji_tiles)
    local types = {}
    table.mergeto(types,get_ji_scores(ming_ji_items,false),function(l,r) return table.union(l or {},r or {}) end)
    table.mergeto(types,get_ji_scores(an_ji_items,true),function(l,r) return table.union(l or {},r or {}) end)
    table.unionto(types,self:calculate_hong_zhong(p))
    return types
end


function maajan_table:gen_ji_tiles()
    local ji_tiles = {}
    local ben_ji_tile
    local is_chui_fen_ji = self.conf.rule.chui_feng_ji
    if self.dealer.remain_count > 0 then
        repeat
            ben_ji_tile = self.dealer:deal_one()
            if ben_ji_tile == 35 then
                break
            end

            if ben_ji_tile == 15 and is_chui_fen_ji then
                return ben_ji_tile,{[15] = {[HU_TYPE.CHUI_FENG_JI] = true}}
            end

            local ben_ji_value = ben_ji_tile % 10
            local fan_pai_ji = math.floor(ben_ji_tile / 10) * 10 + ben_ji_value % 9 + 1
            table.get(ji_tiles,fan_pai_ji,{})[HU_TYPE.FAN_PAI_JI] = true

            if self.conf.rule.yao_bai_ji then
                local yao_bai_ji = math.floor(ben_ji_tile / 10) * 10 + (ben_ji_value - 2) % 9 + 1
                table.get(ji_tiles,yao_bai_ji,{})[HU_TYPE.FAN_PAI_JI] = true
            end

            if self.conf.rule.ben_ji then
                table.get(ji_tiles,ben_ji_tile,{})[HU_TYPE.FAN_PAI_JI] = true
            end
        until true
    end

    table.get(ji_tiles,21,{})[HU_TYPE.NORMAL_JI] = true

    if self.conf.rule.wu_gu_ji then
        table.get(ji_tiles,18,{})[HU_TYPE.WU_GU_JI] = true
    end

    if self.conf.rule.xing_qi_ji then
        local today = tonumber(os.date("%w"))
        if table.keyof(self.tiles,today) then
            table.get(ji_tiles,today,{})[HU_TYPE.XING_QI_JI] = true
        end

        if table.keyof(self.tiles,10 + today) then
            table.get(ji_tiles,10 + today,{})[HU_TYPE.XING_QI_JI] = true
        end

        if table.keyof(self.tiles,20 + today) then
            table.get(ji_tiles,20 + today,{})[HU_TYPE.XING_QI_JI ] = true
        end
    end

    if ji_tiles[21][HU_TYPE.FAN_PAI_JI] then
        ji_tiles[21][HU_TYPE.NORMAL_JI] = nil
        ji_tiles[21][HU_TYPE.FAN_PAI_JI] = nil
        ji_tiles[21][HU_TYPE.JING_JI] = true
    end

    if ji_tiles[18] and ji_tiles[18][HU_TYPE.FAN_PAI_JI] then
        ji_tiles[18][HU_TYPE.WU_GU_JI] = nil
        ji_tiles[18][HU_TYPE.FAN_PAI_JI] = nil
        ji_tiles[18][HU_TYPE.JING_WU_GU_JI] = true
    end

    return ben_ji_tile,ji_tiles
end

function maajan_table:balance_player(p,ji_tiles)
    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)

    local items = {}
    if p.hu then
        local hu_res = self:calculate_hu(p,p.hu)
        for chair_id,item in pairs(hu_res) do
            table.get(items,chair_id,{}).hu = item
        end
    end

    for _,men in pairs(p.men or {}) do
        local men_res = self:calculate_men(p,men)
        for chair_id,item in pairs(men_res) do
            table.get(items,chair_id,{})
            items[chair_id].men = items[chair_id].men or {}
            table.insert(items[chair_id].men,item)
        end
    end

    local ji_res = self:calculate_ji(p,ji_tiles)
    for chair_id,item in pairs(ji_res) do
        table.get(items,chair_id,{}).ji = item
    end

    if p.hu or p.ting or p.jiao or p.men then
        local gang_res = self:calculate_gang(p)
        for chair_id,item in pairs(gang_res) do
            table.get(items,chair_id,{}).gang = item
        end
    end

    if not p.hu and hu_count == 0 then
        local ting_res = self:calculate_wei_hu(p)
        for chair_id,item in pairs(ting_res) do
            table.get(items,chair_id,{}).hu = item
        end
    end

    return items
end



function maajan_table:game_balance(ji_tiles)
    for _,p in pairs(self.players) do
        if not p.hu and not p.men and not p.ting then
            local ting_tiles = mj_util.is_ting(p.pai)
            if table.nums(ting_tiles) > 0 then
                p.jiao = p.jiao or {}
                p.jiao.tiles = ting_tiles
            end
        end
    end

    local items = {}

    for c,_ in pairs(self.players) do
        items[c] = {
            hu = {},
            men = {},
            ji = {},
            gang = {},
        }
    end

    for _,p in pairs(self.players) do
        local p_item = self:balance_player(p,ji_tiles)
        for c,item in pairs(items) do
            local p_item_c = p_item[c]
            if p_item_c then
                if p_item_c.hu then 
                    table.insert(item.hu,p_item_c.hu)
                end
                table.unionto(item.men,p_item_c.men or {})
                table.unionto(item.ji,p_item_c.ji or {})
                table.unionto(item.gang,p_item_c.gang or {})
            end
        end
    end

    return items
end

local BalanceStatus = {
    Hu = pb.enum("Maajan_Blanace_Player.BalanceStatus","Hu"),
    JiaoPai = pb.enum("Maajan_Blanace_Player.BalanceStatus","JiaoPai"),
    WeiJiao = pb.enum("Maajan_Blanace_Player.BalanceStatus","WeiJiao"),
}

local function player_balance_status(p)
    if p.hu then return BalanceStatus.Hu end
    if p.ting or p.men or p.jiao then return BalanceStatus.JiaoPai end
    return BalanceStatus.WeiJiao
end

function maajan_table:on_game_balance()
    local fan_pai_tile,ji_tiles = self:gen_ji_tiles()
    dump(ji_tiles)
    local items = self:game_balance(ji_tiles)
    -- dump(items,9)
    local scores = {}
    for chair_id,item in pairs(items) do
        scores[chair_id] =
            table.sum(item.hu or {},function(t)
                return table.sum(t.typescore,function(ts) return (ts.score or 0) * (ts.count or 0) end)
            end) +
            table.sum(item.men or {},function(men)
                return table.sum(men.typescore,function(ts) return (ts.score or 0) * (ts.count or 0) end)
            end) +
            table.sum(item.ji or {},function(t) return (t.score or 0) * (t.count or 0) end) +
            table.sum(item.gang or {},function(t) return (t.score or 0) * (t.count or 0) end)
    end

    local msg = {
        players = {},
        player_balance = {},
        ben_ji = fan_pai_tile,
    }

    
    local chair_money = {}
    for chair_id,p in pairs(self.players) do
        local p_score = (scores[chair_id] or 0)
        local shou_pai = self:tile_count_2_tiles(p.pai.shou_pai)
        local ming_pai = table.values(p.pai.ming_pai)
        local desk_pai = table.values(p.pai.desk_tiles)
        local p_log = self.game_log.players[chair_id]
        p_log.nickname = p.nickname
        p_log.head_url = p.icon
        p_log.guid = p.guid
        p_log.sex = p.sex
        p_log.pai = {
            desk_pai = desk_pai,
            shou_pai = shou_pai,
            ming_pai = ming_pai,
        }
        
        p.total_score = (p.total_score or 0) + p_score
        log.info("player hu %s,%s,%s,%s",chair_id,p_score,win_money,p.describe)
        p_log.score = p_score
        p_log.describe = p.describe
        
        p_log.finish_task = p.finish_task

        table.insert(msg.players,{
            chair_id = chair_id,
            desk_pai = desk_pai,
            shou_pai = shou_pai,
            pb_ming_pai = ming_pai,
        })

        local balance_item = items[chair_id]

        local hu_men = {}
        if balance_item and balance_item.hu then
            table.unionto(hu_men,balance_item.hu)
        end

        if balance_item and balance_item.men then
            table.unionto(hu_men,balance_item.men)
        end

        table.insert(msg.player_balance,{
            chair_id = chair_id,
            total_score = p.total_score,
            round_score = p_score,
            gang = balance_item and balance_item.gang or {},
            ji = balance_item and balance_item.ji or {},
            items = hu_men,
            status = player_balance_status(p),
            hu_tile = p.hu and p.hu.tile or nil,
        })

        local win_money = self:calc_score_money(p_score)
        chair_money[chair_id] = win_money
    end

    chair_money = self:balance(chair_money,enum.LOG_MOENY_OPT_TYPE_MAAJAN_CUSTOMIZE)
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

    -- dump(msg,9)

    self:broadcast2client("SC_Maajan_Game_Finish",msg)

    self:notify_game_money()

    self.game_log.balance = msg.player_balance
    self.game_log.ben_ji = msg.ben_ji
    self.game_log.end_game_time = os.time()
    self.game_log.cur_round = self.cur_round

    self:save_game_log(self.game_log)

    self.game_log = nil
    
    self:game_over()
end


function maajan_table:on_game_overed()
    self.game_log = {}
    self:ding_zhuang()

    self.do_logic_update = false
    self:clear_ready()
    self:update_state(FSM_S.PER_BEGIN)

    if not self.private_id then
        for _,v in ipairs(self.players) do
            v.hu = nil
            v.men = nil
            v.ting = nil
            v.jiao = nil
            v.pai = {
                ming_pai = {},
                shou_pai = {},
                desk_tiles = {},
            }
            if v.deposit then
                v:forced_exit()
            elseif v:is_android() then
                self:ready(v)
            end
        end
    end

    base_table.on_game_overed(self)
end

function maajan_table:on_final_game_overed()
    local final_scores = {}
    for chair_id,p in pairs(self.players) do
        table.insert(final_scores,{
            chair_id = chair_id,
            guid = p.guid,
            score = p.total_score or 0,
        })
    end

    self:broadcast2client("SC_Maajan_Final_Game_Over",{
        player_scores = final_scores,
    })

    local total_winlose = {}
    for _,p in pairs(self.players) do
        total_winlose[p.guid] = p.total_money or 0
    end
    
    self:cost_tax(total_winlose)

    for _,p in pairs(self.players) do
        p.total_money = nil
        p.round_money = nil
        p.total_score = nil
    end
end

function maajan_table:ding_zhuang()
    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    if hu_count == 0 then
        local jiao_count = table.sum(self.players,function(p) return (p.ting or p.jiao) and 1 or 0 end)
        if jiao_count == 0 or jiao_count == self.chair_count then
            return
        end

        if self.chair_count > 2 and jiao_count == self.chair_count - 1 then
            for chair_id,p in pairs(self.players) do
                if not p.ting then
                    self.zhuang = chair_id
                end
            end
            return
        end

        local zhuang_p = self.players[self.zhuang]
        if zhuang_p.ting then 
            return
        end

        self.zhuang = (self.zhuang + 1) % self.chair_count + 1
        return
    end

    if self.chair_count > 2 and hu_count == self.chair_count - 1 then
        for chair_id,p in pairs(self.players) do
            if not p.hu then
                self.zhuang = chair_id
            end
        end
        return
    end

    local max_chair_id = 0
    for chair_id,p in pairs(self.players) do
        if chair_id > max_chair_id and p.hu then
            max_chair_id = chair_id
        end
    end

    if max_chair_id > 0 then
        self.zhuang = max_chair_id
    end
end

function maajan_table:FSM_event(evt)
    if self.cur_state_FSM ~= FSM_S.GAME_CLOSE then
        for k,v in pairs(FSM_E) do
            if evt.type == v then
            --log.info("cur event is " .. k)
            end
        end

    
        if self.last_act ~= self.cur_state_FSM then
            local states = {
                [FSM_S.PER_BEGIN] = "PER_BEGIN",
                [FSM_S.XI_PAI] = "XI_PAI",
                [FSM_S.CHECK_TING] = "CHECK_TING",
                [FSM_S.WAIT_MO_PAI] =  "WAIT_MO_PAI",
                [FSM_S.WAIT_CHU_PAI] =  "WAIT_CHU_PAI",
                [FSM_S.WAIT_ACTION_AFTER_CHU_PAI] = "WAIT_ACTION_AFTER_CHU_PAI",
                [FSM_S.WAIT_ACTION_AFTER_MO_PAI] = "WAIT_ACTION_AFTER_MO_PAI",
                [FSM_S.GAME_BALANCE] =	"GAME_BALANCE",
                [FSM_S.GAME_CLOSE] = "GAME_CLOSE",
            }

            log.info("cur state is " .. states[self.cur_state_FSM])
            for _,p in pairs(self.players) do
                if p and p.pai then 
                    log.info(mj_util.getPaiStr(self:tile_count_2_tiles(p.pai.shou_pai)))
                end
            end
            self.last_act = self.cur_state_FSM
        end
    end

    local state_handle = self.state_event_handle[self.cur_state_FSM]
    if state_handle then
        state_handle(self,evt)
    else
        log.error("unkown state handle with state:%s",self.cur_state_FSM)
    end
end

function maajan_table:tile_count_2_tiles(counts)
    local tiles = {}
    for t,c in pairs(counts) do
        for _ = 1,c do
            table.insert(tiles,t)
        end
    end

    return tiles
end

function maajan_table:load_lua_cfg()
	local maajan_config = self.room_.room_cfg
	self.mj_min_scale = maajan_config.mj_min_scale
end


function maajan_table:notify_offline(player)
    if self.do_logic_update then
        player.deposit = true
        self:broadcast2client("SC_Maajan_Act_Trustee",{chair_id = player.chair_id,is_trustee = player.deposit})
    else
        self.room_:player_exit_room(player)
    end
end

-- 检查是否可取消准备
function maajan_table:can_stand_up(player, reason)
    log.info("maajan_table:can_stand_up guid:%s,reason:%s",player.guid,reason)
    if reason == enum.STANDUP_REASON_DISMISS or
        reason == enum.STANDUP_REASON_FORCE then
        return true
    end

    return not self:is_play()
end

function maajan_table:is_play(...)
	return self.cur_state_FSM and self.cur_state_FSM ~= FSM_S.GAME_CLOSE
end

function maajan_table:tick()
    self.old_player_count = self.old_player_count or 1 
	local tmp_player_count = self:get_player_count()
	if self.old_player_count ~= tmp_player_count then
        self.old_player_count = tmp_player_count
	end
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
    dump(msg)
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = msg.action,tile = msg.value_tile})
end

--打牌
function maajan_table:on_cs_act_discard(player, msg)
    if msg and msg.tile and mj_util.check_tile(msg.tile) then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = ACTION.CHU_PAI,tile = msg.tile})
    end
end

--过
function maajan_table:on_cs_act_pass(player, msg)
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = ACTION.PASS})
end

--托管
function maajan_table:on_cs_act_trustee(player, msg)
    self:clear_deposit_and_time_out(player)
end

function maajan_table:safe_event(...)
    self:FSM_event(...)
end

function maajan_table:chu_pai_player()
    return self.players[self.chu_pai_player_index]
end

function maajan_table:broadcast_desk_state()
    if  self.cur_state_FSM == FSM_S.PER_BEGIN or self.cur_state_FSM == FSM_S.XI_PAI or
        self.cur_state_FSM == FSM_S.WAIT_MO_PAI or self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
        return
    end

    self:broadcast2client("SC_Maajan_Desk_State",{state = self.cur_state_FSM})
end

function maajan_table:broadcast_player_hu(player,action)
    local msg = {
        chair_id = player.chair_id, value_tile = player.hu.tile,action = action,
    }

    self:broadcast2client("SC_Maajan_Do_Action",msg)
end

function maajan_table:broadcast_player_men(player,action,tile)
    local msg = {
        chair_id = player.chair_id, value_tile = (action == ACTION.MEN_ZI_MO and 255 or tile),action = action,
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

function maajan_table:next_player_index()
    self.chu_pai_player_index = (self.chu_pai_player_index % self.chair_count) + 1
end

function maajan_table:jump_to_player_index(player)
    self.chu_pai_player_index = player.chair_id
end

function maajan_table:adjust_shou_pai(player, action, tile)
    local shou_pai = player.pai.shou_pai
    local ming_pai = player.pai.ming_pai

    if action == ACTION.AN_GANG or action == ACTION.FREE_AN_GANG then
        table.decr(shou_pai,tile,4)
        table.insert(ming_pai,{
            type = action == ACTION.AN_GANG and SECTION_TYPE.AN_GANG or SECTION_TYPE.FREE_AN_GANG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
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

    if action == ACTION.BA_GANG or action == ACTION.FREE_BA_GANG then  --巴杠
        for k,s in pairs(ming_pai) do
            if s.tile == tile and s.type == SECTION_TYPE.PENG then
                table.insert(ming_pai,{
                    type = (action == ACTION.BA_GANG and SECTION_TYPE.BA_GANG or SECTION_TYPE.FREE_BA_GANG),
                    tile = tile,
                    area = TILE_AREA.MING_TILE,
                    whoee = s.whoee,
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

function maajan_table:check_ji_tile_when_chu_pai(p,tile)
    if tile == 21 then
        p.ji = p.ji or {
            chong_feng = {},
            zhe_ren = {},
        }

        local desk_ji_pai_count = table.sum(self.players,function(p)
            return table.sum(p.pai.desk_tiles,function(t) return t == 21 and 1 or 0 end)
        end)

        local ming_ji_pai_count = table.sum(self.players,function(p)
            return table.sum(p.pai.ming_pai,function(s) return s.tile == 21 and 1 or 0 end)
        end)

        if desk_ji_pai_count + ming_ji_pai_count == 0 then
            p.ji.chong_feng.normal = true
        end
    end

    if self.conf.rule.wu_gu_ji and tile == 18 then
        p.ji = p.ji or {
            chong_feng = {},
            zhe_ren = {},
        }

        local desk_ji_pai_count = table.sum(self.players,function(p)
            return table.sum(p.pai.desk_tiles,function(t) return t == 18 and 1 or 0 end)
        end)

        local ming_ji_pai_count = table.sum(self.players,function(p)
            return table.sum(p.pai.ming_pai,function(s) return s.tile == 18 and 1 or 0 end)
        end)

        if desk_ji_pai_count + ming_ji_pai_count == 0 then
            p.ji.chong_feng.wu_gu = true
        end
    end
end

function maajan_table:check_ji_tile_when_peng_gang(p,action,tile)
    if action ~= ACTION.MING_GANG and action ~= ACTION.PENG then
        return
    end

    local _,last_tile = self:get_last_chu_pai()
    if tile == 21 and last_tile == 21 then
        local pi = self:chu_pai_player()
        pi.ji.chong_feng.normal = false
        p.ji.chong_feng.normal = false
        p.ji.zhe_ren.normal = true
    end

    if self.conf.rule.wu_gu_ji and tile == 18 and last_tile == 18  then
        local pi = self:chu_pai_player()
        pi.ji.chong_feng.normal = false
        p.ji.chong_feng.wu_gu = false
        p.ji.zhe_ren.wu_gu = true
    end
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

--执行 出牌
function maajan_table:do_chu_pai(chu_pai_val)
    if not mj_util.check_tile(chu_pai_val) then
        log.error("player %d chu_pai,tile invalid error",self.chu_pai_player_index)
        return
    end

    local player = self:chu_pai_player()
    if not player then
        log.error("player isn't exists when chu guid:%s,tile:%s",self.chu_pai_player_index,chu_pai_val)
        return
    end

    if (player.ting or player.men) and chu_pai_val ~= player.mo_pai  then
        log.error("player chair_id [%d] do_chu_pai chu_pai[%d] ~= mo_pai[%d]",self.chu_pai_player_index,chu_pai_val,player.mo_pai)
        return
    end

    self:check_ji_tile_when_chu_pai(player,chu_pai_val)
    local shou_pai = player.pai.shou_pai
    if not shou_pai[chu_pai_val] or shou_pai[chu_pai_val] == 0 then
        log.error("tile isn't exist when chu guid:%s,tile:%s",player.guid,chu_pai_val)
        return
    end

    log.info("---------chu pai guid:%s,chair: %s,tile:%s ------",player.guid,self.chu_pai_player_index,chu_pai_val)

    shou_pai[chu_pai_val] = shou_pai[chu_pai_val] - 1
    self:on_chu_pai(chu_pai_val)
    table.insert(player.pai.desk_tiles,chu_pai_val)
    self:broadcast2client("SC_Maajan_Action_Discard",{chair_id = player.chair_id, tile = chu_pai_val})
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Discard",msg = {tile = chu_pai_val}})

    local player_actions = {}
    self:foreach(function(v)
        if v.hu then return end
        if player.chair_id == v.chair_id then return end

        local actions = self:get_actions(v,nil,chu_pai_val)
        if actions[ACTION.HU] or actions[ACTION.MEN] then
            if not self:can_hu(v,chu_pai_val) then
                actions[ACTION.HU] = nil
                actions[ACTION.MEN] = nil
            end
        end

        if table.nums(actions) > 0 then
            player_actions[v.chair_id] = {
                chair_id = v.chair_id,
                actions = actions,
            }
        end
    end)

    dump(player_actions)
    if table.nums(player_actions) == 0 then
        self:next_player_index()
        self:do_mo_pai()
    else
        self:wait_action_after_chu_pai(player_actions)
    end

    player.has_done_chu_pai = true -- 出过牌了，判断地胡用
end

function maajan_table:check_game_over()
    return self.dealer.remain_count == 0
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

    
    for chair_id,v in pairs(self.players) do
        local tplayer = {}
        tplayer.chair_id = v.chair_id
        if v.pai then
            tplayer.desk_pai = table.values(v.pai.desk_tiles)
            tplayer.pb_ming_pai = table.values(v.pai.ming_pai)
            tplayer.shou_pai = {}
            if v.chair_id == player.chair_id then
                local shou_pai = clone(v.pai.shou_pai)
                if is_reconnect and self.chu_pai_player_index == player.chair_id and player.mo_pai then 
                    table.decr(shou_pai,player.mo_pai)
                end
                tplayer.shou_pai = self:tile_count_2_tiles(shou_pai)
            else
                tplayer.shou_pai = table.fill(nil,255,1,table.sum(v.pai.shou_pai))
            end
        end

        tplayer.is_ting = v.ting and true or false

        local men_pai = {}
        for _,men in pairs(v.men or {}) do
            table.insert(men_pai,men.zi_mo and 255 or men.tile)
        end
        tplayer.men_pai = men_pai
        if self.chu_pai_player_index == chair_id then
            tplayer.mo_pai = v.mo_pai
        end
        table.insert(msg.pb_players,tplayer)
    end

    dump(msg)
    
    local last_chu_pai_player,last_tile = self:get_last_chu_pai()
    if is_reconnect then
        msg.pb_rec_data = {
            last_chu_pai_chair = last_chu_pai_player and last_chu_pai_player.chair_id or nil,
            last_chu_pai = last_tile
        }
    end

    send2client_pb(player,"SC_Maajan_Desk_Enter",msg)
    if is_reconnect then
        if self.dealer then
            send2client_pb(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
        end

        local has_waiting_ting = false
        for _,act in pairs(self.waiting_player_actions) do
            has_waiting_ting = has_waiting_ting or (act.actions[ACTION.TING] ~= nil)
        end
        if self.chu_pai_player_index == player.chair_id and not has_waiting_ting then
            send2client_pb(player,"SC_Maajan_Draw",{
                chair_id = player.chair_id,
                tile = player.mo_pai,
            })
            send2client_pb(player,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
        end

        local player_actions = self.waiting_player_actions[player.chair_id]
        if player_actions  then
            self:send_action_waiting(player_actions)
        end
    end
end

function maajan_table:reconnect(player)
	log.info("player reconnect : ".. player.chair_id)
    
    player.deposit = nil
    self:send_data_to_enter_player(player,true)
    base_table.reconnect(self,player)
end

--获取当前出牌玩家手上花牌的位置
function maajan_table:get_hua_pai_from_cur_player()
	local player = self.players[self.chu_pai_player_index]
	for tile,_ in pairs(player.pai.shou_pai) do
		if math.floor(tile / 10) == 4 then
			return tile
		end
	end
end

function maajan_table:player_finish_task(player)
    return false
end

function maajan_table:can_hu(player,in_pai)
    local hu_types = mj_util.hu(player.pai,in_pai)
    if table.nums(hu_types) == 0 then
        return false
    end

    local hu_type = self:max_hu_score(hu_types)
    local gang = table.sum(player.pai.ming_pai,function(s)
        return (s.type == SECTION_TYPE.AN_GANG or s.type == SECTION_TYPE.MING_GANG or
                s.type == SECTION_TYPE.BA_GANG or s.type == SECTION_TYPE.FREE_BA_GANG or 
                s.type == SECTION_TYPE.FREE_AN_GANG) and 1 or 0
    end)

    local chu_pai_player = self:chu_pai_player()
    return  chu_pai_player.ting or
            def.is_action_gang(chu_pai_player.last_action or 0) or
            player.ting or
            gang > 0 or
            hu_type.score > 1
end

function maajan_table:hu_type_score(types)
    local hts = {}
    for type,_ in pairs(types) do
        table.insert(hts,{
            score = HU_TYPE_INFO[type].score,
            type = type,
        })
    end

    return hts
end

function maajan_table:hu_fan_match(hu)
    local hu_type = self:max_hu_score(hu.types)
    return hu_type.score >= self.mj_min_scale
end

function maajan_table:max_hu_score(hu_types)
    local typescores = {}
    for _,ht in pairs(hu_types) do
        local types = self:hu_type_score(ht)
        table.insert(typescores,{
            types = types,
            score = table.sum(types,function(t) return t.score end)
        })
    end

    table.sort(typescores,function(l,r) return l.score > r.score end)

    return typescores[1]
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
            },
            ready = self.ready_list[chair_id] and true or false,
        })
    end

    local private_conf = base_private_table[self.private_id]

    local info = {
        table_id = self.private_id,
        seat_list = seats,
        room_cur_round = self.cur_round or 0,
        rule = self.private_id and json.encode(self.conf.conf) or "",
        game_type = def_first_game_type,
        template_id = private_conf and private_conf.template,
    }

    return info
end

return maajan_table