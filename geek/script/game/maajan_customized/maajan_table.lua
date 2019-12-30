local pb = require "pb_files"
local base_table = require "game.lobby.base_table"
local def 		= require "game.maajan_customized.base.define"
local mj_util 	= require "game.maajan_customized.base.mang_jiang_util"
local log = require "log"
local json = require "cjson"
local maajan_tile_dealer = require "maajan_tile_dealer"
local timer_manager = require "game.timer_manager"
local base_player = require "game.lobby.base_player"
local enum = require "pb_enums"

require "functions"

local FSM_E  = def.FSM_event
local FSM_S  = def.FSM_state

local ACTION = def.ACTION

local ACTION_PRIORITY = {
    [ACTION.PASS] = 7,
    [ACTION.JIA_BEI] = 6,
    [ACTION.LEFT_CHI] = 5,
    [ACTION.MID_CHI] = 5,
    [ACTION.RIGHT_CHI] = 5,
    [ACTION.PENG] = 4,
    [ACTION.AN_GANG] = 3,
    [ACTION.MING_GANG] = 3,
    [ACTION.BA_GANG] = 3,
    [ACTION.MEN] = 2,
    [ACTION.HU] = 1,
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
	self.tiles = chair_count_tiles[4]
    
    self.dealer = maajan_tile_dealer:new(self.tiles)
    self.cur_state_FSM = nil
    
    self.state_event_handle = {
        [FSM_S.WAIT_CHU_PAI] = self.on_action_when_wait_chu_pai,
        [FSM_S.WAIT_PENG_GANG_HU_CHI] = self.on_peng_gang_hu_chi,
        [FSM_S.WAIT_BA_GANG_HU] = self.on_ba_gang_hu_after_mo_pai,
        [FSM_S.GAME_CLOSE] = self.on_game_over,
        [FSM_S.GAME_ERR] = self.on_game_error,
        [FSM_S.GAME_IDLE_HEAD] = self.on_game_idle_head,
    }
end

function maajan_table:clear()
    base_table.clear(self)
    self.cur_state_FSM = nil
end


function maajan_table:on_pre_begin(event_table)
    self:update_state(FSM_S.XI_PAI)
    self:on_xi_pai()
end

function maajan_table:on_xi_pai(event_table)
    self:prepare_tiles()

    for _,v in pairs(self.players) do
        self:send_data_to_enter_player(v)
    end

    self.chu_pai_player_index = self.zhuang
    
    for k,v in pairs(self.players) do
        self.game_log.players[k].start_pai = self:tile_count_2_tiles(v.pai.shou_pai)
    end

    self.game_log.start_gong_pai = self.dealer:remain_tiles()

    self:on_bu_hua_big()
end

function maajan_table:wait_chu_pai()
    self:update_state(FSM_S.WAIT_CHU_PAI)
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

function maajan_table:wait_action_after_chu_pai(actions)
    self:update_state(FSM_S.WAIT_PENG_GANG_HU_CHI)
    self.waiting_player_actions = actions
    for _,action in pairs(actions) do
        self:send_action_waiting(action)
    end
end

function maajan_table:wait_action_after_mo_pai(actions)
    self:update_state(FSM_S.WAIT_BA_GANG_HU)
    self.waiting_player_actions = actions
    for _,action in pairs(actions) do
        self:send_action_waiting(action)
    end
end

function maajan_table:on_ba_gang_hu_after_mo_pai(event_table)
    self:do_action_after_mo_pai(event_table)
end

function maajan_table:start(player_count)
	local ret = base_table.start(self,player_count)
	for _,v in pairs(self.players) do
        v.hu                    = nil
        v.deposit               = false
        v.miao_shou_hui_chun    = false
        v.hai_di_lao_yue        = false
        v.last_action           = false
        v.has_done_chu_pai      = false
        v.quan_qiu_ren          = false
        v.dan_diao_jiang        = false
        v.tian_ting             = false
        v.baoting               = false
        v.hua_count             = 0
        v.mo_pai_count          = 0
        v.jiabei				= 0
        v.pai                   = {
            shou_pai = {},
            ming_pai = {},
            desk_tiles = {}
        }
        v.ting                  = nil
        v.men                   = nil
        v.is_men                = false --是否闷

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
    end

    self.timer = {}
    self.task = {
        tile = 0,
        type = 0
    }

    self.cur_state_FSM             = FSM_S.PER_BEGIN
    local zhuang =  math.random(1,player_count)
    self.zhuang = zhuang
	self.chu_pai_player_index      = zhuang --出牌人的索引
	self.last_chu_pai              = -1 --上次的出牌
    self.waiting_player_actions    = {}
	self:update_state(FSM_S.PER_BEGIN)
	self.do_logic_update = true
    self.table_game_id = self:get_now_game_id()
    self:next_game()
    self.game_log = {
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        zhuang = self.zhuang,
        mj_min_scale = self.mj_min_scale,
        action_table = {},
        players = table.fill(nil,{},1,self.chair_count),
    }

    if self.private_id then
        self.cur_round = (self.cur_round or 0) + 1
    end

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

function maajan_table:prepare_tiles()
    self.dealer:shuffle()
    local pre_tiles = {
        
    }

    for i,pretiles in pairs(pre_tiles) do
        local p = self.players[i]
        if not p then
            log.error("deal tiles got nil player,chair_id:%d",i)
            break
        end
        local tiles = {}
        for _,tile in pairs(pretiles) do
            tile = self.dealer:deal_one_on(function(t) return t == tile end)
            if tile > 0 then
                table.insert(tiles,tile)
            end
        end
        for _,t in pairs(tiles) do
            local c = p.pai.shou_pai[t]
            p.pai.shou_pai[t] = (c or 0) + 1
        end
    end

    for i = 1,self.chair_count do
        local p = self.players[i]
        if not pre_tiles[i] then
            local tiles = self.dealer:deal_tiles(13)
            for _,t in pairs(tiles) do
                local c = p.pai.shou_pai[t]
                p.pai.shou_pai[t] = (c or 0) + 1
            end
        end
    end
end

function maajan_table:get_actions(p,mo_pai,in_pai)
    local actions = mj_util.get_actions(p.pai,mo_pai,in_pai)
    if p.men then
        actions[ACTION.PENG] = nil
        actions[ACTION.LEFT_CHI] = nil
        actions[ACTION.MID_CHI] = nil
        actions[ACTION.RIGHT_CHI] = nil
    end

    return actions
end

function maajan_table:on_action_when_wait_chu_pai(event_table)
    local action_handle = {
        [ACTION.AN_GANG] = self.on_gang_when_wait_chu_pai,
        [ACTION.CHU_PAI] = self.on_chu_pai_when_wait_chu_pai,
        [ACTION.BA_GANG] = self.on_gang_when_wait_chu_pai,
        [ACTION.HU] = self.on_hu_when_wait_chu_pai,
    }

    local f = action_handle[event_table.type]
    if f then
        f(self,event_table)
    else
        log.error("maajan_table:on_action_when_wait_chu_pai action:%s",event_table.type)
    end
end

local action_name_str = {
    [ACTION.AN_GANG] = "AnGang",
    [ACTION.PENG] = "Peng",
    [ACTION.MING_GANG] = "MingGang",
    [ACTION.BA_GANG] = "BaGang",
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
}
function maajan_table:log_game_action(player,action,tile)
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[action],msg = {tile = tile}})
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
    local is_round_over = false
    local hu_tile
    local men_tile 
    local chu_pai_player = self:chu_pai_player()
    for _,action in pairs(do_actions) do
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
        elseif def.is_action_gang(action.done.action) then
            self:check_ji_tile_when_peng_gang(player,action.done.action,tile)
            table.pop_back(chu_pai_player.pai.desk_tiles)
            self:adjust_shou_pai(player,action.done.action,tile)
            self:log_game_action(player,action.done.action,tile)
            self:jump_to_player_index(player)
            self:do_mo_pai()
        elseif action.done.action == ACTION.HU then
            hu_tile = tile
            player.hu = {
                time = os.time(),
                tile = tile,
                types = mj_util.hu(player.pai,tile),
                zi_mo = false,
                whoee = self.chu_pai_player_index,
            }
            self:log_game_action(player,action.done.action,tile)
            self:broadcast_player_hu(player,action.done.action)
        elseif action.done.action == ACTION.MEN then
            men_tile = tile
            player.men = player.men or {}
            table.insert(player.men,{
                time = os.time(),
                tile = tile,
                types = mj_util.hu(player.pai,tile),
                whoee = self.chu_pai_player_index,
                zi_mo = false,
            })

            self:log_game_action(player,action.done.action,tile)
            self:broadcast_player_men(player,action.done.action,tile)
        elseif def.is_action_chi(action.done.action) then
            if not action[action.done.action][tile] then
                return
            end

            table.pop_back(chu_pai_player.pai.desk_tiles)
            self:adjust_shou_pai(player,action.done.action,tile)
            self:log_game_action(player,action.done.action,tile)
            self:jump_to_player_index(player)
            self:wait_chu_pai()
        elseif action[ACTION.HU] and action.done.action == ACTION.JIA_BEI then
            self:player_jiabei(player)
            self:broadcast_player_hu(player,action)
            self:jump_to_player_index(player)
            self:next_player_index()
            self:do_mo_pai()
            self:log_game_action(player,action.done.action,tile)
        elseif action.done.action == ACTION.PASS then
            self:next_player_index()
            self:do_mo_pai()
        end
    end

    if hu_tile then
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:on_game_balance()
    elseif men_tile then
        table.pop_back(chu_pai_player.pai.desk_tiles)
        table.sort(do_actions,function(l,r) return l.chair_id < r.chair_id end)
        self:jump_to_player_index(self.players[do_actions[1].chair_id])
        self:next_player_index()
        self:do_mo_pai()
    end
end

function maajan_table:do_action_after_mo_pai(event_table)
    local do_action = event_table.type
    local chair_id = event_table.chair_id
    local tile = event_table.tile
    if event_table.chair_id ~= self.chu_pai_player_index then
        log.error("do action:%s but chair_id:%s is not current chair_id:%s after mo_pai",
            do_action,chair_id,self.chu_pai_player_index)
        return
    end

    local player = self:chu_pai_player()
    local player_actions = self.waiting_player_actions[player.chair_id].actions
    if not player then
        log.error("do action %s,but wrong player in chair %s",do_action,player.chair_id)
        return
    end

    if not player_actions[do_action] and do_action ~= ACTION.PASS then
        log.error("do action %s,but action is illigle,%s",do_action)
        return
    end

    if do_action == ACTION.BA_GANG or do_action == ACTION.FREE_BA_GANG or do_action == ACTION.AN_GANG then
        self:adjust_shou_pai(player,do_action,tile)
        self:log_game_action(player,do_action,tile)
        self:jump_to_player_index(player)
        self:do_mo_pai()
    elseif do_action == ACTION.ZI_MO then
        player.hu = {
            time = os.time(),
            tile = tile,
            types = mj_util.hu(player.pai,tile),
            zi_mo = true,
        }

        self:log_game_action(player,do_action,tile)
        self:broadcast_player_hu(player,do_action)
        self:on_game_balance()
    elseif do_action == ACTION.MEN_ZI_MO then
        player.pai.shou_pai[tile] = player.pai.shou_pai[tile] - 1
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
    elseif player_actions[ACTION.ZI_MO] and do_action == ACTION.JIA_BEI then
        self:player_jiabei(player)
        self:jump_to_player_index(player)
        self:next_player_index()
        self:do_mo_pai()
        self:log_game_action(player,do_action,tile)
    elseif do_action == ACTION.PASS then
        self:wait_chu_pai()
    end

    self.waiting_player_actions = {}
end

function maajan_table:on_peng_gang_hu_chi(event_table)
    local waiting_action = self.waiting_player_actions[event_table.chair_id]
    if not waiting_action then
        log.error("no action waiting when on_peng_gang_hu_chi_bei,action:%s",event_table.type)
        return
    end

    local actions = waiting_action.actions
    if not actions then
        log.error("on action %s,%s,actions is nil")
        return
    end

    if def.is_action_gang(event_table.type) then
        local tile = event_table.tile
        local type = event_table.type
        if actions[event_table.type] and actions[event_table.type][tile] then

        else
            log.error("no action waiting when on_peng_gang_hu_chi_bei,action:%s,tile:%s",
                event_table.type,event_table.tile)
            return
        end

        waiting_action.done = {
            action = type,
            tile = tile,
        }
    else
        waiting_action.done = {
            action = event_table.type,
            tile = event_table.tile,
        }
    end

    if not table.logic_and(self.waiting_player_actions,function(action)
        return action.done ~= nil
    end) then
        return
    end

    local all_actions = {}
    for _,action in pairs(self.waiting_player_actions) do
        table.insert(all_actions,action)
    end

    table.sort(all_actions,function(l,r)
        local l_priority = ACTION_PRIORITY[l.done.action]
        local r_priority = ACTION_PRIORITY[l.done.action]
        if l_priority ~= r_priority then
            return l_priority < r_priority
        end

        return l.chair_id < r.chair_id
    end)

    self.waiting_player_actions = {}
    self:do_sorted_actions_after_chu_pai(all_actions)
end

function maajan_table:on_bu_hua_big(event_table)
    self:update_state(FSM_S.BU_HUA_BIG)

    for _,v in ipairs(self.players) do
        v.tian_ting = mj_util.is_ting(v.pai)
    end

    self:do_mo_pai()
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

    player.mo_pai_count = player.mo_pai_count + 1
    local mo_pai = self.dealer:deal_one()
    player.mo_pai = mo_pai
    local actions = self:get_actions(player,mo_pai)
    self:wait_chu_pai()
    if table.nums(actions) > 0 then
        self:wait_action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
            }
        })
    end

    shou_pai[mo_pai] = (shou_pai[mo_pai] or 0) + 1
    log.info("---------mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    for k,v in pairs(self.players) do
        if v.chair_id == self.chu_pai_player_index and mo_pai then
            send2client_pb(v,"SC_Maajan_Draw",{tile = mo_pai,chair_id = k})
            table.insert(self.game_log.action_table,{chair = k,act = "Draw",msg = {tiles = mo_pai}})
        else
            send2client_pb(v,"SC_Maajan_Draw",{tile = 255,chair_id = player.chair_id})
            v.mo_pai = nil
        end
    end

    self:auto_act_if_deposit(player,actions,mo_pai)
end

function maajan_table:on_timeout_when_wait_chu_pai(event_table)
    local player = self:chu_pai_player()
    self:do_chu_pai(player.pai.shou_pai[player.mo_pai])
    self:increase_time_out_and_deposit(player)
end

function maajan_table:on_chu_pai_when_wait_chu_pai(event_table)
    self:do_chu_pai(event_table.tile)
end

function maajan_table:on_gang_when_wait_chu_pai(event_table)
    local cur_chu_pai_player = self:chu_pai_player()
    
    if cur_chu_pai_player.chair_id == event_table.chair_id then
        local actions = self:get_actions(cur_chu_pai_player,nil,self.last_chu_pai)
        local gangtile = event_table.tile
        if actions[ACTION.AN_GANG] and actions[ACTION.AN_GANG][gangtile] then
            self:adjust_shou_pai(cur_chu_pai_player,ACTION.AN_GANG,gangtile)
            self:do_mo_pai()
        end

        if actions[ACTION.BA_GANG] and actions[ACTION.BA_GANG][gangtile] then
            self.last_chu_pai = gangtile
            self:adjust_shou_pai(cur_chu_pai_player,ACTION.BA_GANG,gangtile)

            local hu_player = {}
            local player_actions = {}
            for k,v in pairs(self.players) do
                if v and k ~= self.chu_pai_player_index then --排除自己
                    actions = self:get_actions(v,nil, self.last_chu_pai)
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

function maajan_table:on_hu_when_wait_chu_pai(event_table) --自摸胡
    local player = self.players[self.chu_pai_player_index]
    if player.chair_id ~= event_table.chair_id then
        return
    end

    player.hu.types = mj_util.hu(player.pai,event_table.tile)
    if #player.hu.types > 0 then
        if player.mo_pai_count == 0 and self.chu_pai_player_index == self.zhuang then
            player.tian_hu = true -- 天胡
        elseif player.mo_pai_count == 1 and not player.has_done_chu_pai then
            player.di_hu = true -- 地胡
        end

        if self:hu_fan_match(player) then
            player.hu = {
                time = os.time(),
                tile = self.last_chu_pai,
                types = mj_util.hu(player.pai,self.last_chu_pai),
                zi_mo = true,
            }
            self:broadcast_player_hu(player,ACTION.ZI_MO)
            self:on_game_balance()
        end
    end
end

function maajan_table:on_chi(player,action,tile)
    
end

function maajan_table:on_peng(player,tile)

end

function maajan_table:on_gang(player,action,tile)

end

function maajan_table:on_hu(player,tile)
    
end

function maajan_table:on_zi_mo(player,tile)

end

function maajan_table:on_men(player,tile)

end

function maajan_table:can_ting(player)
    return #mj_util.is_ting(player.pai) > 0
end

function maajan_table:get_hu_items(hu)
    local hu_type = self:max_hu_fan(hu.types)
    local hu_score = hu_type.score
    if hu.zi_mo then
        return self.cell_score * hu_score * 2,table.keys(hu_type.types)
    end

    return self.cell_score * hu_score,table.keys(hu_type.types)
end

local BalanceItemType = {
    Hu = pb.enum("Maajan_Balance_Item.ItemType","Hu"),
    ZiMo = pb.enum("Maajan_Balance_Item.ItemType","ZiMo"),
    Men = pb.enum("Maajan_Balance_Item.ItemType","Men"),
    MenZiMo = pb.enum("Maajan_Balance_Item.ItemType","MenZiMo"),
}

function maajan_table:calculate_hu(p,hu)
    local player_count = table.nums(self.players)
    local types = {}
    local hu_score,ts = self:get_hu_items(hu)

    for _,t in pairs(ts) do
        if not hu.zi_mo then
            types[p.chair_id] = types[p.chair_id] or {}
            table.insert(types[p.chair_id],{
                type = BalanceItemType.ZiMo,
                typescore = {score = hu_score,type = t,tile = hu.tile,count = 1},
            })

            types[hu.whoee] = types[hu.whoee] or {}
            table.insert(types[hu.whoee],{
                type = BalanceItemType.ZiMo,
                typescore = {score = 0-hu_score,type = t,tile = hu.tile,count = 1}
            })
        else
            types[p.chair_id] = types[p.chair_id] or {}
            table.insert(types[p.chair_id],{
                type = BalanceItemType.Hu,
                typescore = {score = (player_count - 1) * hu_score,type = t,tile = hu.tile,count = 1}
            })
            for j,pj in pairs(self.players) do
                if p ~= pj then
                    types[j] = types[j] or {}
                    table.insert(types[j],{
                        type = BalanceItemType.Hu,
                        typescore = {score = 0-hu_score,type = t,tile = hu.tile,count = 1},
                    })
                end
            end
        end
    end

    return types
end



function maajan_table:calculate_men(p,men)
    local player_count = table.nums(self.players)
    local types = {}
    local hu_score,ts = self:get_hu_items(men)
    for _,t in pairs(ts) do
        if men.zi_mo then
            types[p.chair_id] = types[p.chair_id] or {}
            table.insert(types[p.chair_id],{
                type = BalanceItemType.MenZiMo,
                typescore = {score = (player_count - 1) * hu_score,type = t,tile = men.tile,count = 1},
            })
            for j,pj in pairs(self.players) do
                if p ~= pj and (p.hu or (not p.hu and not pj.ting))then
                    types[j] = types[j] or {}
                    table.insert(types[j],{
                        type = BalanceItemType.ZiMo,
                        typescore = {type = t,score = -hu_score,tile = men.tile,count = 1}
                    })
                end
            end
        else
            local pj = self.players[men.whoee]
            if p.hu or (not p.hu and not pj.ting) then
                types[p.chair_id] = types[p.chair_id] or {}
                table.insert(types[p.chair_id],{
                    type = BalanceItemType.Men,
                    typescore = {score = hu_score,type = t,tile = men.tile,count = 1},
                })

                types[men.whoee] = types[men.whoee] or {}
                table.insert(types[men.whoee],{
                    type = BalanceItemType.Men,
                    typescore = {type = t,score = -hu_score,tile = men.tile,count = 1},
                })
            end
        end
    end

    return types
end

function maajan_table:get_gang_items(p)
    local types = {}
    for _,s in pairs(p.pai.ming_pai or {}) do
        if s.type == SECTION_TYPE.AN_GANG then
            local an_gang_score = HU_TYPE_INFO[HU_TYPE.AN_GANG].score
            table.insert(types,{score = an_gang_score,type = HU_TYPE.AN_GANG,tile = s.tile,count = 1})
        end

        if s.type == SECTION_TYPE.MING_GANG then
            local ming_gang_score = HU_TYPE_INFO[HU_TYPE.MING_GANG].score
            table.insert(types,{ score = ming_gang_score, type = HU_TYPE.MING_GANG, tile = s.tile,whoee = s.whoee,count = 1})
        end

        if s.type == SECTION_TYPE.BA_GANG then
            local ba_gang_score = HU_TYPE_INFO[HU_TYPE.BA_GANG].score
            table.insert(types,{score = ba_gang_score,type = HU_TYPE.BA_GANG,tile = s.tile,count = 1})
        end
    end

    return types
end


function maajan_table:calculate_gang(p)
    local player_count = table.nums(self.players)
    local types = {}
    local ts = self:get_gang_items(p)
    for _,t in pairs(ts) do
        if t.whoee then
            if p.hu or p.men or p.ting then
                types[p.chair_id] = types[p.chair_id] or {}
                table.insert(types[p.chair_id],{type = t.type,score = t.score * t.count,tile = t.tile,count = t.count})
                types[t.whoee] = types[t.whoee] or {}
                table.insert(types[t.whoee],{type = t.type,score = -t.score * t.count,tile = t.tile,count = t.count})
            end
        else
            if p.hu or p.men or p.ting then
                types[p.chair_id] = types[p.chair_id] or {}
                table.insert(types[p.chair_id],{type = t.type,score = t.score * (player_count - 1) * t.count,tile = t.tile,count = t.count})
                for i,pi in pairs(self.players) do
                    if p ~= pi then
                        types[i] = types[i] or {}
                        table.insert(types[i],{type = t.type,score = -t.score * t.count,tile = t.tile,count = t.count})
                    end
                end
            end
        end
    end

    return types
end

function maajan_table:calculate_ting(p)
    local types = {}
    
    if p.ting then
        for _,pi in pairs(self.players) do
            if p ~= pi and not pi.ting and not pi.men and not pi.hu then
                types[p.chair_id] = types[p.chair_id] or {}
                table.insert(types[p.chair_id],{type = HU_TYPE.JIAO_PAI,score = 1,whoee = pi.chair_id,count = 1})
                types[pi.chair_id] = types[pi.chair_id] or {}
                table.insert(types[pi.chair_id],{type = HU_TYPE.WEI_JIAO,score = -1,count = 1})
            end
        end
    end

    return types
end


function maajan_table:get_ji_items(p,ji_tiles)
    if not p.hu and not p.men and not p.ting then return {} end

    local types = {}

    for tile,c in pairs(p.pai.shou_pai) do
        if c > 0 then
            for t,_ in pairs(ji_tiles[tile] or {}) do
                table.insert(types,{ type = t, tile = tile, score = HU_TYPE_INFO[t].score,count = c})
            end
        end
    end

    for _,s in pairs(p.pai.ming_pai) do
        local tile = s.tile
        if (tile == 21 and p.ji.zhe_ren.normal) or (tile == 18 and p.ji.zhe_ren.wu_gu) then
            table.insert(types,{
                type = HU_TYPE.ZHE_REN_JI,
                tile = tile,score = HU_TYPE_INFO[HU_TYPE.ZHE_REN_JI].score,
                whoee = s.whoee,
                count = s.type == SECTION_TYPE.PENG and 3 or 4
            })
        else
            for t,_ in pairs(ji_tiles[tile] or {}) do
                table.insert(types,{type = t, tile = tile, score = HU_TYPE_INFO[t].score,whoee = s.whoee,count = 4 })
            end
        end
    end

    for _,tile in pairs(p.pai.desk_tiles) do
        if (tile == 21 and p.ji.chong_feng.normal) or (tile == 18 and p.ji.chong_feng.wu_gu) then
            p.ji.chong_feng.normal = tile == 21 and false or p.ji.chong_feng.normal
            p.ji.chong_feng.wu_gu = tile == 18 and false or p.ji.chong_feng.wu_gu
            table.insert(types,{type = HU_TYPE.CHONG_FENG_JI,tile = tile,score = HU_TYPE_INFO[HU_TYPE.CHONG_FENG_JI].score,count = 1})
        else
            for t,_ in pairs(ji_tiles[tile] or {}) do
                table.insert(types,{ type = t, tile = tile, score = HU_TYPE_INFO[t].score,count = 1,})
            end
        end
    end

    return types
end

function maajan_table:calculate_ji(p,ji_tiles)
    local player_count = table.nums(self.players)
    local types = {}

    local ts = self:get_ji_items(p,ji_tiles)
    for _,t in pairs(ts) do
        if t.whoee then
            local pj = self.players[t.whoee]
            types[p.chair_id] = types[p.chair_id] or {}
            table.insert(types[p.chair_id],t)
            if (p.hu or p.men or p.ting) and not pj.ting then
                types[t.whoee] = types[t.whoee] or {}
                table.insert(types[t.whoee],{type = t.type,score = -t.score,tile = t.tile,count = t.count})
            end
        else
            types[p.chair_id] = types[p.chair_id] or {}
            table.insert(types[p.chair_id],{type = t.type,score = t.score * (player_count - 1),tile = t.tile,count = t.count})
            for _,pj in pairs(self.players) do
                if p ~= pj and (p.hu or p.men or p.ting) and not pj.ting then
                    types[pj.chair_id] = types[pj.chair_id] or {}
                    table.insert(types[pj.chair_id],{type = t.type,score = -t.score,tile = t.tile,count = t.count})
                end
            end
        end
    end

    return types
end


function maajan_table:gen_ji_tiles()
    local ji_tiles = {}
    ji_tiles[21] = {[HU_TYPE.NORMAL_JI] = 1}
    if self.conf.rule.wu_gu_ji then
        ji_tiles[18] = {[HU_TYPE.WU_GU_JI] = 1}
    end

    local ben_ji_tile
    local is_chui_fen_ji = self.conf.rule.chui_feng_ji
    if self.dealer.remain_count > 0 then
        ben_ji_tile = self.dealer:deal_one()
        for _ = 1,100 do
            if ben_ji_tile < 30 then break end
            ben_ji_tile = self.dealer:deal_one()
        end
        
        

        local ben_ji_value = ben_ji_tile % 10
        local fan_pai_ji = math.floor(ben_ji_tile / 10) * 10 + ben_ji_value % 9 + 1

        if fan_pai_ji == 15 and is_chui_fen_ji then
            return ben_ji_tile,{[15] = {[HU_TYPE.CHUI_FENG_JI] = 1}}
        end
        
        ji_tiles[fan_pai_ji] = ji_tiles[fan_pai_ji] or {}
        ji_tiles[fan_pai_ji][HU_TYPE.FAN_PAI_JI] = 1
        if self.conf.rule.yao_bai_ji then
            local yao_bai_ji = math.floor(ben_ji_tile / 10) * 10 + (ben_ji_value - 9 - 1) % 9 + 1
            ji_tiles[yao_bai_ji] = ji_tiles[yao_bai_ji] or {}
            ji_tiles[yao_bai_ji][HU_TYPE.FAN_PAI_JI] = 1
            if yao_bai_ji == 15 and is_chui_fen_ji then
                return ben_ji_tile,{[15] = {[HU_TYPE.CHUI_FENG_JI] = 1}}
            end
        end

        if self.conf.rule.ben_ji then
            ji_tiles[ben_ji_tile] = ji_tiles[ben_ji_tile] or {}
            ji_tiles[ben_ji_tile][HU_TYPE.FAN_PAI_JI] = 1
        end
    end

    if self.conf.rule.xing_qi_ji then
        local today = tonumber(os.date("%w"))
        if table.keyof(self.tiles,today) then
            ji_tiles[today] = ji_tiles[today] or  {}
            ji_tiles[today][HU_TYPE.XING_QI_JI] = 1
        end

        if table.keyof(self.tiles,10 + today) then
            ji_tiles[10 + today] = ji_tiles[10 + today] or  {}
            ji_tiles[10 + today][HU_TYPE.XING_QI_JI] = 1
        end

        if table.keyof(self.tiles,20 + today) then
            ji_tiles[20 + today] = ji_tiles[20 + today] or  {}
            ji_tiles[20 + today][HU_TYPE.XING_QI_JI ] = 1
        end
    end

    return ben_ji_tile,ji_tiles
end

function maajan_table:balance_player(p,ji_tiles)
    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    local items = {}
    if p.hu then
        local hu_res = self:calculate_hu(p,p.hu)
        for chair_id,item in pairs(hu_res) do
            items[chair_id] = items[chair_id] or {}
            items[chair_id].hu = item
        end

        for _,men in pairs(p.men or {}) do
            local men_res = self:calculate_men(p,men)
            for chair_id,item in pairs(men_res) do
                items[chair_id] = items[chair_id] or {}
                items[chair_id].men = items[chair_id].men or {}
                table.insert(items[chair_id].men,item)
            end
        end

        local ji_res = self:calculate_ji(p,ji_tiles)
        for chair_id,item in pairs(ji_res) do
            items[chair_id] = items[chair_id] or {}
            items[chair_id].ji = item
        end

        local gang_res = self:calculate_gang(p)
        for chair_id,item in pairs(gang_res) do
            items[chair_id] = items[chair_id] or {}
            items[chair_id].gang = item
        end
    elseif p.men or p.ting then
        if hu_count == 0 then
            for _,men in pairs(p.men or {}) do
                local men_res = self:calculate_men(p,men)
                for chair_id,item in pairs(men_res) do
                    items[chair_id] = items[chair_id] or {}
                    items[chair_id].men = items[chair_id].men or {}
                    table.insert(items[chair_id].men,item)
                end
            end
            
            if p.ting then
                local ting_res = self:calculate_ting(p)
                for chair_id,item in pairs(ting_res) do
                    items[chair_id] = items[chair_id] or {}
                    items[chair_id].hu = item
                end
            end
        end

        local ji_res = self:calculate_ji(p,ji_tiles)
        for chair_id,item in pairs(ji_res) do
            items[chair_id] = items[chair_id] or {}
            items[chair_id].ji = item
        end

        local gang_res = self:calculate_gang(p)
        for chair_id,item in pairs(gang_res) do
            items[chair_id] = items[chair_id] or {}
            items[chair_id].gang = item
        end
    end

    return items
end



function maajan_table:game_balance(ji_tiles)
    local items = {}

    for _,p in pairs(self.players) do
        if not p.hu and not p.men then
            local ting_tiles = mj_util.is_ting(p.pai)
            if #ting_tiles > 0 then
                p.ting = p.ting or {}
                p.ting.tiles = ting_tiles
            end
        end
    end

    for _,p in pairs(self.players) do
        local p_items = self:balance_player(p,ji_tiles)
        for chair_id,item in pairs(p_items) do
            items[chair_id] = items[chair_id] or {}

            local it = items[chair_id]
            it.hu = table.union(it.hu or {},item.hu or {})
            it.men = table.union(it.men or {},item.men or {})
            it.gang = table.union(it.gang or {},item.gang or {})
            it.ji = table.union(it.ji or {},item.ji or {})
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
    if p.ting or p.men then return BalanceStatus.JiaoPai end
    return BalanceStatus.WeiJiao
end

function maajan_table:on_game_balance()
    local fan_pai_tile,ji_tiles = self:gen_ji_tiles()
    local items = self:game_balance(ji_tiles)
    local scores = {}
    for chair_id,item in pairs(items) do
        scores[chair_id] =
            table.sum(item and item.hu or {},function(t) return t.typescore.score end) +
            table.sum(item and item.men or {},function(it) return
                table.sum(it,function(t) return t.typescore.score end)
            end) +
            table.sum(item and item.ji or {},function(t) return t.score end) +
            table.sum(item and item.gang or {},function(t) return t.score end)
    end

    local msg = {
        players = {},
        player_balance = {},
        ben_ji = fan_pai_tile,
    }

    for chair_id,p in pairs(self.players) do
        local p_score = scores[chair_id] or 0
        local shou_pai = self:tile_count_2_tiles(p.pai.shou_pai)
        p.total_money = p.total_money or 0
        local p_log = self.game_log.players[chair_id]
        if p.hu then
            p_log.hu = p.hu
            p_log.hu.types = table.keys(p.hu.types)
        end
        p_log.pai = p.api
        p.win_money = p_score
        p.total_money = p.total_money + p.win_money
        log.info("player hu %s,%s,%s,%s",chair_id,p.score,p.win_money,p.describe)
        p_log.score = p_score
        p_log.describe = p.describe
        p_log.win_money = p.win_money
        p_log.total_money = p.total_money
        p_log.finish_task = p.finish_task

        table.insert(msg.players,{
            chair_id = chair_id,
            desk_pai = p.pai.desk_tiles,
            shou_pai = shou_pai,
            pb_ming_pai = p.pai.ming_pai,
        })

        local balance_item = items[chair_id]

        local hu_men = {}
        if balance_item and balance_item.hu then
            table.insert(hu_men,{ type = 2,typescore = balance_item.hu,})
        end

        if balance_item and balance_item.men then
            for _,men in pairs(balance_item and balance_item.men or {}) do
                if table.nums(men) > 0 then
                    table.insert(hu_men,{type = 1,typescore = men,})
                end
            end
        end

        table.insert(msg.player_balance,{
            chair_id = chair_id,
            total_score = p.total_money,
            round_score = p_score,
            gang = balance_item and balance_item.gang or {},
            ji = balance_item and balance_item.ji or {},
            items = hu_men,
            status = player_balance_status(p),
        })
    end

    dump(msg)

    self:broadcast2client("SC_Maajan_Game_Finish",msg)

    self.game_log.end_game_time = os.time()
    local s_log = json.encode(self.game_log)
    log.info(s_log)
    self:save_game_log(self.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)

    self:on_game_over()
end

function maajan_table:on_game_over()
    self.do_logic_update = false
    self:clear_ready()
    self:update_state(FSM_S.PER_BEGIN)

    if self.private_id and self.cur_round and self.cur_round >= self.conf.round then
        local final_scores = {}
        for chair_id,p in pairs(self.players) do
            table.insert(final_scores,{
                chair_id = chair_id,
                guid = p.guid,
                score = p.total_money,
            })
        end

        self:broadcast2client("SC_Maajan_Final_Game_Over",{
            player_scores = final_scores,
        })
        for _,p in pairs(self.players) do
            p:forced_exit()
        end

        self.cur_round = 0
    else
        for _,v in ipairs(self.players) do
            v.hu = nil
            v.men = nil
            v.ting = nil
            v.pai = {
                ming_pai = {},
                shou_pai = {},
                desk_tiles = {},
            }
            if v.deposit then
                v:forced_exit()
            elseif v.is_android then
                self:ready(v)
            end
        end
    end

    base_table.on_game_over(self)
end

function maajan_table:on_game_error(event_table)
    for _,v in pairs(self.players) do
        if v then 
            v.hu = false
            v.ting = false
        end
    end
    self:on_game_over()
end

function maajan_table:on_game_idle_head(event_table)

end

function maajan_table:FSM_event(event_table)
    if self.cur_state_FSM ~= FSM_S.GAME_CLOSE then
        for k,v in pairs(FSM_E) do
            if event_table.type == v then
            --log.info("cur event is " .. k)
            end
        end

    
        if self.last_act ~= self.cur_state_FSM then
            local states = {
                [FSM_S.PER_BEGIN] = "PER_BEGIN",
                [FSM_S.XI_PAI] = "XI_PAI",
                [FSM_S.BU_HUA_BIG] = "BU_HUA_BIG",
                [FSM_S.WAIT_MO_PAI] =  "WAIT_MO_PAI",
                [FSM_S.WAIT_CHU_PAI] =  "WAIT_CHU_PAI",
                [FSM_S.WAIT_PENG_GANG_HU_CHI] = "WAIT_PENG_GANG_HU_CHI",
                [FSM_S.WAIT_BA_GANG_HU] = "WAIT_BA_GANG_HU",
                [FSM_S.GAME_BALANCE] =	"GAME_BALANCE",
                [FSM_S.GAME_CLOSE] = "GAME_CLOSE",
                [FSM_S.GAME_ERR] = 	"GAME_ERR",
                [FSM_S.GAME_IDLE_HEAD] = "GAME_IDLE_HEAD",
            }

            log.info("cur state is " .. states[self.cur_state_FSM])
            for _,p in pairs(self.players) do
                if p and p.pai then 
                    mj_util.printPai(self:tile_count_2_tiles(p.pai.shou_pai))
                end
            end
            self.last_act = self.cur_state_FSM
        end
    end

    local state_handle = self.state_event_handle[self.cur_state_FSM]
    if state_handle then
        state_handle(self,event_table)
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
	return self.cur_state_FSM and self.cur_state_FSM ~= FSM_S.GAME_CLOSE and true or false
end

function maajan_table:tick()
    self.old_player_count = self.old_player_count or 1 
	local tmp_player_count = self:get_player_count()
	if self.old_player_count ~= tmp_player_count then
        self.old_player_count = tmp_player_count
	end

	if self.do_logic_update then
        local dead_list = {}
        for k,v in pairs(self.timer) do
            if os.time() > v.dead_line then
                v.execute()
                dead_list[#dead_list + 1] = k
            end
        end
        for k,v in pairs(dead_list) do
            self.timer[v] = nil
        end
    else
        self.Maintain_time = self.Maintain_time or os.time()
        if os.time() - self.Maintain_time > 5 then
            self.Maintain_time = os.time()
            for _,v in ipairs(self.players) do
                if v then
                    --维护时将准备阶段正在匹配的玩家踢出
                    local iRet = base_table:on_notify_ready_player_maintain(v)--检查游戏是否维护
                end
            end
        end
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
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = msg.action,tile = msg.value_tile})
end

--胡
function maajan_table:on_cs_act_win(player, msg)
    self:clear_deposit_and_time_out(player)
	self:safe_event({chair_id = player.chair_id,type = ACTION.HU})
end

--加倍
function maajan_table:on_cs_act_double(player, msg)
    local msg_t = msg or {tile = player.pai.shou_pai[#player.pai.shou_pai]}
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = ACTION.JIA_BEI,tile = msg_t.tile})
end

--打牌
function maajan_table:on_cs_act_discard(player, msg)
    if msg and msg.tile and mj_util.check_tile(msg.tile) then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = ACTION.CHU_PAI,tile = msg.tile})
    end
end

--碰
function maajan_table:on_cs_act_peng(player, msg)
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = ACTION.PENG})
end

--杠
function maajan_table:on_cs_act_gang(player, msg)
    if msg and msg.tile and mj_util.check_tile(msg.tile) then
        self:clear_deposit_and_time_out(player)
        local waituing_action = self.waiting_player_actions[player.chair_id]
        if not waituing_action then
            log.error("on_cs_act_gang but no waiting action,%s",player.chair_id)
            return
        end

        local action
        if waituing_action.actions[ACTION.AN_GANG] then
            action = ACTION.AN_GANG
        elseif waituing_action.actions[ACTION.MING_GANG] then
            action = ACTION.MING_GANG
        elseif waituing_action.actions[ACTION.BA_GANG] then
            action = ACTION.BA_GANG
        end

        if not action then
            log.error("on_cs_act_gang but no waiting action,%s",player.chair_id)
            return
        end

        self:safe_event({chair_id = player.chair_id,type = action,tile = msg.tile})
    end
end

--过
function maajan_table:on_cs_act_pass(player, msg)
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = ACTION.PASS})
end

--吃
function maajan_table:on_cs_act_chi(player, msg)
    if msg and msg.tiles and #msg.tiles == 3 then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = ACTION.CHI,tiles = msg.tiles})
    end
end

--托管
function maajan_table:on_cs_act_trustee(player, msg)
    self:clear_deposit_and_time_out(player)
end

--报听
function maajan_table:on_cs_act_baoting(player, msg)
    if not player.baoting then
        self:clear_deposit_and_time_out(player)
        player.baoting = true
        self:broadcast2client("SC_Maajan_Act_BaoTing",{chair_id = player.chair_id,is_ting = player.baoting})
    end
end

function maajan_table:safe_event(...)
    self:FSM_event(...)
end

function maajan_table:chu_pai_player()
    return self.players[self.chu_pai_player_index]
end

function maajan_table:broadcast_desk_state()
    if self.cur_state_FSM == FSM_S.PER_BEGIN or self.cur_state_FSM == FSM_S.XI_PAI
    or self.cur_state_FSM == FSM_S.WAIT_MO_PAI or self.cur_state_FSM >= FSM_S.GAME_IDLE_HEAD then
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

function maajan_table:player_jiabei(player)
    player.jiabei = player.jiabei + 1
    self:broadcast2client("SC_Maajan_Act_Double",{chair_id = player.chair_id,jiabei_val = player.jiabei})
end

function maajan_table:player_is_activity(player)
	return not player.is_android
end

function maajan_table:update_state(new_state)
    self.cur_state_FSM = new_state
    if self.cur_state_FSM == FSM_S.WAIT_CHU_PAI then
        self:broadcast_desk_state()
        self:broadcast2client("SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    end
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

    if action == ACTION.AN_GANG then
        table.decr(shou_pai,tile,4)
        table.insert(ming_pai,{
            type = SECTION_TYPE.AN_GANG,
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
        for i = 1,#ming_pai do
            local s = ming_pai[i]
            if s.tile == tile and s.type == SECTION_TYPE.PENG then
                table.insert(ming_pai,{
                    type = (action == ACTION.BA_GANG and SECTION_TYPE.BA_GANG or SECTION_TYPE.FREE_BA_GANG),
                    tile = tile,
                    area = TILE_AREA.MING_TILE,
                    whoee = s.whoee,
                })
                ming_pai[i] = nil
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
    local delay_seconds = 1
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

    if tile == 21 then
        if self.last_chu_pai == 21 then
            local pi = self:chu_pai_player()
            pi.ji.chong_feng.normal = false
            p.ji.chong_feng.normal = false
            p.ji.zhe_ren.normal = true
        end
    end

    if (self.conf.rule.wu_gu_ji and tile == 18)  then
        if self.last_chu_pai == 18 then
            local pi = self:chu_pai_player()
            pi.ji.chong_feng.normal = false
            p.ji.chong_feng.wu_gu = false
            p.ji.zhe_ren.wu_gu = true
        end
    end
end

--执行 出牌
function maajan_table:do_chu_pai(chu_pai_val)
    if not mj_util.check_tile(chu_pai_val) then
        log.error("player %d chu_pai,tile invalid error",self.chu_pai_player_index)
        return
    end

    local player = self.players[self.chu_pai_player_index]
    if not player then
        log.error("player isn't exists when chu guid:%s,tile:%s",self.chu_pai_player_index,chu_pai_val)
        return
    end

    if player.baoting then 
        --log.info("player %d do_chu_pai err baoting",player.guid)
        --return 
    end

    player.chu_pai = chu_pai_val
    self:check_ji_tile_when_chu_pai(player,chu_pai_val)
    local shou_pai = player.pai.shou_pai
    if not shou_pai[chu_pai_val] or shou_pai[chu_pai_val] == 0 then
        log.error("tile isn't exist when chu guid:%s,tile:%s",player.guid,chu_pai_val)
        return
    end

    log.info("---------chu pai guid:%s,chair: %s,tile:%s ------",player.guid,self.chu_pai_player_index,chu_pai_val)

    shou_pai[chu_pai_val] = shou_pai[chu_pai_val] - 1
    self.last_chu_pai = chu_pai_val --上次的出牌
    table.insert(player.pai.desk_tiles,chu_pai_val)
    self:broadcast2client("SC_Maajan_Action_Discard",{chair_id = player.chair_id, tile = chu_pai_val})
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Discard",msg = {tile = chu_pai_val}})

    local player_actions = {}
    self:foreach(function(v)
        if v.hu then return end
        if player.chair_id == v.chair_id then return end

        local actions = self:get_actions(v,nil,self.last_chu_pai)
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

        if actions[ACTION.HU] then
            self:auto_act_if_deposit(v,"hu_chu_pai")
        elseif actions[ACTION.AN_GANG] or actions[ACTION.MING_GANG] or actions[ACTION.BA_GANG] then
            self:auto_act_if_deposit(v,"gang_chu_pai")
        elseif actions[ACTION.PENG] then
            self:auto_act_if_deposit(v,"peng_chu_pai")
        elseif actions[ACTION.LEFT_CHI] or actions[ACTION.MID_CHI] or actions[ACTION.RIGHT_CHI] then
            self:auto_act_if_deposit(v,"chi_chu_pai")
        end
    end)

    if table.nums(player_actions) == 0 then
        self:next_player_index()
        self:do_mo_pai()
    else
        self:wait_action_after_chu_pai(player_actions)
    end

    player.last_act_is_gang = false
    player.has_done_chu_pai = true -- 出过牌了，判断地胡用
end

function maajan_table:check_game_over()
    return self.dealer.remain_count == 0
end

function maajan_table:send_data_to_enter_player(player,is_reconnect)
    local msg = {}
    msg.state = self.cur_state_FSM
    msg.round = self.cur_round
    msg.zhuang = self.zhuang
    msg.self_chair_id = player.chair_id
    msg.act_time_limit = def.ACTION_TIME_OUT
    msg.decision_time_limit = def.ACTION_TIME_OUT
    msg.is_reconnect = is_reconnect
    msg.pb_players = {}
    for chair_id,v in pairs(self.players) do
        local tplayer = {}
        tplayer.chair_id = v.chair_id
        if v.pai then
            tplayer.desk_pai = table.values(v.pai.desk_tiles)
            tplayer.pb_ming_pai = table.values(v.pai.ming_pai)
            tplayer.shou_pai = {}
            if v.chair_id == player.chair_id then
                tplayer.shou_pai = self:tile_count_2_tiles(v.pai.shou_pai)
            else
                tplayer.shou_pai = table.fill(nil,255,1,table.sum(v.pai.shou_pai))
            end
        end
        
        tplayer.is_ting = v.baoting

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

    

    if is_reconnect then
        msg.pb_rec_data = {}
        msg.pb_rec_data.chu_pai_player_index = self.chu_pai_player_index
        msg.pb_rec_data.last_chu_pai = self.last_chu_pai
    end

    dump(msg)

    send2client_pb(player,"SC_Maajan_Desk_Enter",msg)

    if is_reconnect then
        send2client_pb(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
        for _,v in pairs(self.players) do
            if v.baoting then
                send2client_pb(player,"SC_Maajan_Act_BaoTing",{chair_id = v.chair_id,is_ting = v.baoting})
            end
        end
    end
end

function maajan_table:reconnect(player)
	log.info("player reconnect : ".. player.chair_id)
    base_table.reconnect(self,player)
    player.deposit = nil
    self:send_data_to_enter_player(player,true)
    for _,action in pairs(self.waiting_player_actions or {}) do
        self:send_action_waiting(action)
    end
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
    local done = false
    local tile = self.task.tile
    if self.task.type == ACTION.CHI then
        for tp,v in pairs(player.pai.ming_pai) do
            if mj_util.is_action_chi(tp) and v[tile] then
                done = true break
            end
        end
    elseif self.task.type == ACTION.PENG then
        for tp,v in pairs(player.pai.ming_pai) do
            if tp == SECTION_TYPE.PENG and v[tile] then
                done = true break
            end
        end
    elseif self.task.type == ACTION.HU then
        if player.hu_pai == tile then
            done = true
        end
    end
    return done
end

function maajan_table:can_hu(player,in_pai)
    local hu_types = mj_util.hu(player.pai,in_pai)
    if table.nums(hu_types) == 0 then
        return false
    end

    local hu_type = self:max_hu_fan(hu_types)
    local gang = table.sum(player.pai.ming_pai,function(s) 
        return (s.type == SECTION_TYPE.AN_GANG or s.type == SECTION_TYPE.MING_GANG or
                s.type == SECTION_TYPE.BA_GANG or s.type == SECTION_TYPE.FREE_BA_GANG) and 1 or 0
    end)
    dump(gang)
    return gang > 0 or hu_type.score > 1
end

function maajan_table:hu_type_fan(types)
    local hts = {}
    for t,_ in pairs(types) do
        hts[t] = hts[t] or {}
        table.insert(hts[t],{
            score = HU_TYPE_INFO[t].score,
            type = t,
        })
    end

    return hts
end

function maajan_table:hu_fan_match(hu)
    local hu_type = self:max_hu_fan(hu.types)
    return hu_type.score >= self.mj_min_scale
end

function maajan_table:max_hu_fan(hu_types)
    local hts = {}
    for _,ht in pairs(hu_types) do
        local types = self:hu_type_fan(ht)
        table.insert(hts,{
            types = types,
            score = table.sum(types,function(v) return table.sum(v,function(t) return t.score end) end)
        })
    end

    table.sort(hts,function(l,r)
        return l.score > r.score
    end)

    return hts[1]
end

function maajan_table:global_status_info()
    local seats = {}
    for chair_id,p in pairs(self.players) do
        table.insert(seats,{
            chair_id = chair_id,
            open_id_icon = p.open_id_icon,
            guid = p.guid,
            nickname = p.nickname,
            sex = p.sex,
            ready = self.ready_list[chair_id] and true or false,
        })
    end

    local info = {
        table_id = self.private_id,
        seat_list = seats,
        room_cur_round = self.cur_round or 1,
        rule = self.private_id and json.encode(self.conf.conf) or "",
        game_type = def_first_game_type,
    }

    return info
end

return maajan_table