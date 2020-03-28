local pb = require "pb_files"
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

local yield = profile.yield
local resume = profile.resume

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



local maajan_table = base_table:new()

-- 初始化
function maajan_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
    self.cur_state_FSM = nil
end

function maajan_table:on_private_inited()
    self.cur_round = nil
    self.zhuang = nil
    self.tiles = all_tiles[4]
end

function maajan_table:on_private_dismissed()
    self.cur_round = nil
    self.zhuang = nil
    self.tiles = nil
    self.cur_state_FSM = nil
    for _,p in pairs(self.players) do
        p.total_money = nil
    end
    if self:is_play() then
        self:safe_event({type = ACTION.CLOSE})
    end
end

function maajan_table:clear_event_pump()
    self:gotofunc(nil)
    self.co = nil
end

function maajan_table:on_started(player_count)
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
    end

    self.zhuang = self.private_id and self.zhuang or math.random(1,self.chair_count)

	self.chu_pai_player_index      = self.zhuang --出牌人的索引
	self.last_chu_pai              = -1 --上次的出牌
    self.waiting_player_actions    = {}
	self:update_state(FSM_S.PER_BEGIN)
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

    self.dealer = maajan_tile_dealer:new(all_tiles[player_count])

    self.co = skynet.fork(function()
        self:main()
    end)
end

function maajan_table:xi_pai()
    self:update_state(FSM_S.XI_PAI)
    self:prepare_tiles()

    self:foreach(function(v)
        self:send_data_to_enter_player(v)
        self.game_log.players[v.chair_id].start_pai = self:tile_count_2_tiles(v.pai.shou_pai)
    end)

    self.chu_pai_player_index = self.zhuang
end

function maajan_table:huan_pai()
    if not self.conf.conf.huan or table.nums(self.conf.conf.huan) == 0 then
        return
    end

    self:update_state(FSM_S.HUAN_PAI)
    self:broadcast2client("SC_AllowHuanPai",{})

    local function on_huan_pai(player,msg)
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
            local mens = {}
            table.foreach(tiles,function(t) table.incr(mens,math.floor(t / 10)) end)
            local men_count = table.nums(mens)
            if men_count ~= 1 then
                send2client_pb(player.guid,"SC_HuanPai",{
                    result = enum.PARAMETER_ERROR,
                })
                log.error("maajan_table:huan_pai huan_type == %d,but men count = %d",huan_type,men_count)
                return
            end
        end

        player.pai.huan = {old = tiles,}
        self:broadcast2client("SC_HuanPai",{
            result = enum.ERROR_NONE,
            chair_id = player.chair_id,
            done = true,
        })
    end
    
    repeat
        local evt = yield()
        if evt.type == ACTION.CLOSE then
            self:clear_event_pump()
            return
        end

        if evt.type == ACTION.RECONNECT then
            local player = evt.player
            send2client_pb(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
            self:send_huan_pai_status(player)
        else
            on_huan_pai(evt.player,evt.msg)
        end
    until table.logic_and(self.players,function(p) return p.pai.huan ~= nil end)

    local order = self:do_huan_pai()
    self:foreach(function(p)
        send2client_pb(p,"SC_HuanPaiCommit",{
            new_shou_pai = p.pai.huan.new,
            huan_order = order,
        })
    end)
end

function maajan_table:ding_que()
    if self.chair_count == 2 then
        return
    end

    self:update_state(FSM_S.DING_QUE)
    self:broadcast2client("SC_AllowDingQue",{})

    local function on_ding_que(player,msg)
        local men = msg.men
        if men < 0 or men > 3 then
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
    end

    repeat
        local evt = yield()
        repeat
            if evt.type == ACTION.CLOSE then
                self:clear_event_pump()
                return
            end

            if evt.type == ACTION.RECONNECT then
                local player = evt.player
                send2client_pb(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
                self:send_ding_que_status(player)
                break
            end

            on_ding_que(evt.player,evt.msg)
        until true
    until table.logic_and(self.players,function(p) return p.que ~= nil end)

    local p_ques = {}
    self:foreach(function(p)
        table.insert(p_ques,{
            chair_id = p.chair_id,
            men = p.que,
        })
    end)

    self:broadcast2client("SC_DingQueCommit",{
        ding_ques = p_ques,
    })
end

function maajan_table:action_after_mo_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_MO_PAI)
    for _,action in pairs(waiting_actions) do
        self:send_action_waiting(action)
    end

    local function reconnect(p)
        self:send_ding_que_status(p)
        send2client_pb(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
        send2client_pb(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
        self:send_action_waiting(waiting_actions[p.chair_id])
        if self.chu_pai_player_index == p.chair_id then
            send2client_pb(p,"SC_Maajan_Draw",{
                chair_id = p.chair_id,
                tile = p.mo_pai,
            })
        end
    end

    local function on_action(evt)
        local do_action = evt.type
        local chair_id = evt.chair_id
        local tile = evt.tile

        if chair_id ~= self.chu_pai_player_index then
            log.error("do action:%s but chair_id:%s is not current chair_id:%s after mo_pai",
                do_action,chair_id,self.chu_pai_player_index)
            return
        end

        dump(waiting_actions)
        local player = self:chu_pai_player()
        if not player then
            log.error("do action %s,but wrong player in chair %s",do_action,player.chair_id)
            return
        end

        local player_actions = waiting_actions[player.chair_id].actions
        if not player_actions[do_action] and do_action ~= ACTION.PASS and do_action ~= ACTION.CHU_PAI then
            log.error("do action %s,but action is illigle,%s",do_action)
            return
        end

        if do_action == ACTION.BA_GANG then
            local qiang_gang_hu = {}
            self:foreach_except(player,function(p)
                if p.hu then return end

                local actions = self:get_actions(p,nil,tile)
                if actions[ACTION.HU] then
                    qiang_gang_hu[p.chair_id] = {[ACTION.HU] = actions[ACTION.HU]}
                end
            end)

            self:log_game_action(player,do_action,tile)
            if table.nums(qiang_gang_hu) == 0 then
                self:adjust_shou_pai(player,do_action,tile)
                self:jump_to_player_index(player)
                self:gotofunc(function() self:mo_pai() end)
            else
                self:action_after_chu_pai(qiang_gang_hu)
                for chair,_ in pairs(qiang_gang_hu) do
                    local p = self.players[chair]
                    if p.hu then p.hu.qiang_gang = true end
                end
            end
        end

        if do_action == ACTION.AN_GANG then
            self:adjust_shou_pai(player,do_action,tile)
            self:log_game_action(player,do_action,tile)
            self:jump_to_player_index(player)
            self:gotofunc(function() self:mo_pai() end)
        end

        if do_action == ACTION.ZI_MO then
            player.hu = {
                time = os.time(),
                tile = tile,
                types = mj_util.hu(player.pai),
                zi_mo = true,
                gang_hua = def.is_action_gang(player.last_action or 0),
            }

            self:log_game_action(player,do_action,tile)
            self:broadcast_player_hu(player,do_action)
            local hu_count  = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
            if self.chair_count - hu_count  == 1 then
                self:gotofunc(function() self:do_balance() end)
            else
                self:next_player_index()
                self:gotofunc(function() self:mo_pai() end)
            end
        end

        if do_action == ACTION.PASS then
            self:gotofunc(function() self:chu_pai() end)
        end

        self:done_last_action(player,do_action)
    end

    while true do
        local evt = yield()
        if evt.type == ACTION.CLOSE then
            self:clear_event_pump()
            return
        end

        if evt.type == ACTION.RECONNECT then
            reconnect(evt.player)
        else
            on_action(evt)
            break
        end
    end
end

function maajan_table:action_after_chu_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_CHU_PAI)
    for _,action in pairs(waiting_actions) do
        self:send_action_waiting(action)
    end

    local function reconnect(p)
        send2client_pb(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
        self:send_ding_que_status(p)
        local action = waiting_actions[p.chair_id]
        dump(action)
        if action then 
            self:send_action_waiting(action)
        end
    end

    repeat
        local evt = yield()
        if evt.type == ACTION.CLOSE then
            self:clear_event_pump()
            return
        elseif evt.type == ACTION.RECONNECT then
            reconnect(evt.player)
        else
            local action = self:check_action_before_do(waiting_actions,evt)
            if action then
                action.done = {
                    action = evt.type,
                    tile = evt.tile,
                }
            end
        end
    until table.logic_and(waiting_actions,function(action) return action.done ~= nil end)

    local all_actions = table.values(
            table.select(waiting_actions,function(action) return action.done.action ~= ACTION.PASS end)
        )

    if table.nums(all_actions) == 0 then
        self:next_player_index()
        self:gotofunc(function() self:mo_pai()  end)
        return
    end

    table.sort(all_actions,function(l,r)
        local l_priority = ACTION_PRIORITY[l.done.action]
        local r_priority = ACTION_PRIORITY[r.done.action]
        return l_priority < r_priority
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
            self:gotofunc(function() self:chu_pai() end)
        end

        if def.is_action_gang(action.done.action) then
            table.pop_back(chu_pai_player.pai.desk_tiles)
            self:adjust_shou_pai(player,action.done.action,tile)
            self:log_game_action(player,action.done.action,tile)
            self:jump_to_player_index(player)
            self:gotofunc(function() self:mo_pai() end)
        end

        if action.done.action == ACTION.HU then
            for _,act in ipairs(actions_to_do) do
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
            local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
            if self.chair_count - hu_count == 1 then
                self:gotofunc(function() self:do_balance() end)
            else
                local last_hu_player = nil
                for _,p in ipairs(self.players) do
                    if p.hu then last_hu_player = p end
                end
                self:jump_to_player_index(last_hu_player)
                self:next_player_index()
                self:gotofunc(function() self:mo_pai() end)
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
            self:gotofunc(function() self:chu_pai() end)
        end

        if action.done.action == ACTION.PASS then
            self:next_player_index()
            self:gotofunc(function() self:mo_pai() end)
        end

        self:done_last_action(player,action.done.action)
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

function maajan_table:mo_pai()
    self:update_state(FSM_S.WAIT_MO_PAI)
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai

    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 0 then
        self:gotofunc(function() self:do_balance() end)
        return
    end

    local mo_pai = self.dealer:deal_one()
    if not mo_pai then
        self:gotofunc(function() self:do_balance() end)
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
        self:gotofunc(function()
            self:action_after_mo_pai({
                [self.chu_pai_player_index] = {
                    actions = actions,
                    chair_id = self.chu_pai_player_index,
                }
            })
        end)
    else
        self:gotofunc(function() self:chu_pai() end)
    end
end

function maajan_table:close()
    self:gotofunc(nil)
    self.co = nil
end

function maajan_table:chu_pai()
    self:update_state(FSM_S.WAIT_CHU_PAI)
    self:broadcast_desk_state()
    self:broadcast2client("SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})

    local function reconnect(p)
        send2client_pb(p,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
        send2client_pb(p,"SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
        self:send_ding_que_status(p)
        if p.chair_id == self.chu_pai_player_index then
            send2client_pb(p,"SC_Maajan_Draw",{
                chair_id = p.chair_id,
                tile = p.mo_pai,
            })
        end
    end

    local evt = yield()
    while true do
        if evt.type == ACTION.CLOSE then
            self:clear_event_pump()
            return
        end

        if evt.type == ACTION.RECONNECT then
            reconnect(evt.player)
            evt = yield()
        else
            break
        end
    end

    local chu_pai_val = evt.tile

    if not mj_util.check_tile(chu_pai_val) then
        log.error("player %d chu_pai,tile invalid error",self.chu_pai_player_index)
        return
    end

    local player = self:chu_pai_player()
    if not player then
        log.error("player isn't exists when chu guid:%s,tile:%s",self.chu_pai_player_index,chu_pai_val)
        return
    end

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

    dump(waiting_actions)
    if table.nums(waiting_actions) == 0 then
        self:next_player_index()
        self:gotofunc(function() self:mo_pai() end)
    else
        self:gotofunc(function() self:action_after_chu_pai(waiting_actions) end)
    end
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

function maajan_table:do_balance()
    local items = self:game_balance()
    local scores = {}
    for chair_id,item in pairs(items) do
        scores[chair_id] =
            table.sum(item.hu or {},function(t)
                return table.sum(t.typescore,function(ts) return (ts.score or 0) * (ts.count or 0) end)
            end) +
            table.sum(item.gang or {},function(t) return (t.score or 0) * (t.count or 0) end)
    end

    local msg = {
        players = {},
        player_balance = {},
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

        table.insert(msg.players,{
            chair_id = chair_id,
            desk_pai = desk_pai,
            shou_pai = shou_pai,
            pb_ming_pai = ming_pai,
        })

        local balance_item = items[chair_id]
        table.insert(msg.player_balance,{
            chair_id = chair_id,
            total_score = p.total_score,
            round_score = p_score,
            gang = balance_item and balance_item.gang or {},
            items = balance_item and balance_item.hu or {},
            status = player_balance_status(p),
            hu_tile = p.hu and p.hu.tile or nil,
        })

        local win_money = self:calc_score_money(p_score)
        chair_money[chair_id] = win_money
    end

    dump(msg)

    -- chair_money = self:balance(chair_money,enum.LOG_MOENY_OPT_TYPE_MAAJAN_CUSTOMIZE)
    -- for _,balance in pairs(msg.player_balance) do
    --     local p = self.players[balance.chair_id]
    --     local p_log = self.game_log.players[balance.chair_id]
    --     local money = chair_money[balance.chair_id]
    --     balance.round_money = money
    --     p.total_money = (p.total_money or 0) + money
    --     balance.total_money = p.total_money
    --     p_log.total_money = p.total_money
    --     p_log.win_money = money
    -- end

    self:broadcast2client("SC_Maajan_Game_Finish",msg)

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

function maajan_table:gotofunc(f)
    self.f = f
end

function maajan_table:main()
    self:pre_begin()
    self:huan_pai()
    self:ding_que()
    self:mo_pai()

    while self.f do
        self.f()
    end
end

function maajan_table:get_huan_type()
    local type_option = self.conf.conf.huan.type_opt + 1
    return self.room_.conf.private_conf.huan.type_option[type_option]
end

function maajan_table:get_huan_count()
    local count_option = self.conf.conf.huan.count_opt + 1
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
        pop_shou_pai(p,p.pai.huan.old)
    end)

    local huan_order = math.random(0,1)
    if self.chair_count == 4 then
        huan_order = math.random(0,2)
    end

    if huan_order == 0 then
        for i = 1,self.chair_count do
            local p = self.players[i]
            local p1 = self.players[(i - 2) % self.chair_count + 1]
            push_shou_pai(p1,p.pai.huan.old)
            p1.pai.huan.new = p.pai.huan.old
        end
    elseif huan_order == 1 then
        for i = 1,self.chair_count do
            local p = self.players[i]
            local p1 = self.players[i % self.chair_count + 1]
            push_shou_pai(p1,p.pai.huan.old)
            p1.pai.huan.new = p.pai.huan.old
        end
    elseif huan_order == 2 then
        local p1 = self.players[1]
        local p2 = self.players[2]
        local p3 = self.players[3]
        local p4 = self.players[4]
        swap(p1,p3)
        swap(p2,p4)
    end

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
    local actions = mj_util.get_actions(p.pai,mo_pai,in_pai)
    for act,tiles in pairs(actions) do
        for tile,_ in pairs(tiles) do
            if math.floor(tile / 10) == p.que then
                tiles[tile] = nil
            end
        end

        if table.nums(tiles) == 0 then
            actions[act] = nil
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
}

function maajan_table:log_game_action(player,action,tile)
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[action],msg = {tile = tile}})
end

function maajan_table:done_last_action(player,action)
    player.last_action = action
    self:foreach_except(player,function(p) p.last_action = nil end)
end

function maajan_table:check_action_before_do(waiting_actions,event)
    local action = event.type
    local chair_id = event.chair_id
    local tile = event.tile
    local player_actions = waiting_actions[chair_id]
    if not player_actions then
        log.error("no action waiting when check_action_before_do,chair_id,action:%s,tile:",chair_id,action,tile)
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

function maajan_table:get_hu_items(hu)
    return self:max_hu_score(hu.types).types
end

local BalanceItemType = {
    Hu = pb.enum("Maajan_Balance_Item.ItemType","Hu"),
    ZiMo = pb.enum("Maajan_Balance_Item.ItemType","ZiMo"),
    Men = pb.enum("Maajan_Balance_Item.ItemType","Men"),
    MenZiMo = pb.enum("Maajan_Balance_Item.ItemType","MenZiMo"),
}

function maajan_table:calculate_hu(p,hu)
    local types = {}
    local ts = self:get_hu_items(hu)
    if not hu.zi_mo then
        if hu.gang_pao then
            table.insert(table.get(types,p.chair_id,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                type = HU_TYPE.GANG_SHANG_PAO, score = HU_TYPE_INFO[HU_TYPE.GANG_SHANG_PAO].score,
                fan = HU_TYPE_INFO[HU_TYPE.GANG_SHANG_PAO].fan,count = 1,
            })

            table.insert(table.get(types,hu.whoee,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                type = HU_TYPE.GANG_SHANG_PAO, score = - HU_TYPE_INFO[HU_TYPE.GANG_SHANG_PAO].score,
                fan = - HU_TYPE_INFO[HU_TYPE.GANG_SHANG_PAO].fan,count = 1,
            })
        end

        if hu.qiang_gang then
            table.insert(table.get(types,p.chair_id,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                type = HU_TYPE.QIANG_GANG_HU, score = HU_TYPE_INFO[HU_TYPE.QIANG_GANG_HU].score,
                fan = - HU_TYPE_INFO[HU_TYPE.QIANG_GANG_HU].fan,count = 1,
            })

            table.insert(table.get(types,hu.whoee,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                type = HU_TYPE.QIANG_GANG_HU, score = - HU_TYPE_INFO[HU_TYPE.QIANG_GANG_HU].score,
                fan = - HU_TYPE_INFO[HU_TYPE.QIANG_GANG_HU].fan,count = 1,
            })
        end

        for _,t in pairs(ts) do
            table.insert(table.get(types,p.chair_id,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                score = t.score * t.count,fan = t.fan * t.count,type = t.type,tile = hu.tile,count = 1,
            })

            table.insert(table.get(types,hu.whoee,{
                type = BalanceItemType.Hu,
                typescore = {},
            }).typescore,{
                score = -t.score * t.count,fan = -t.fan * t.count,type = t.type,tile = hu.tile,count = 1,
            })
        end
    else
        for chair_id,_ in pairs(self.players) do
            types[chair_id] = {
                type = BalanceItemType.ZiMo,
                typescore = {},
            }
        end

        local kill_count = table.sum(self.players,function(pj)
            return (pj ~= p and (not pj.hu or pj.hu.time < pj.hu.time)) and 1 or 0
        end)

        if hu.gang_hua then
            local t = HU_TYPE.GANG_SHANG_HUA
            local gang_hua_score = HU_TYPE_INFO[t].score
            local gang_hua_fan = HU_TYPE_INFO[t].fan
            for chair_id,pj in pairs(self.players) do
                if pj ~= p and ((pj.hu and pj.hu.time < p.hu.time) or not pj.hu) then
                    table.insert(types[chair_id].typescore,{fan = - gang_hua_fan,score = - gang_hua_score,type = t,count = 1})
                else
                    table.insert(types[chair_id].typescore,{fan = gang_hua_fan,score = gang_hua_score,type = t,count = kill_count})
                end
            end
        end

        for _,t in pairs(ts) do
            for chair_id,pj in pairs(self.players) do
                if p == pj then
                    table.insert(types[chair_id].typescore,{
                        fan = t.fan * t.count,score = t.score * t.count,type = t.type,tile = hu.tile,count = kill_count,
                    })
                elseif (not pj.hu or pj.hu.time < p.hu.time) then
                    table.insert(types[chair_id].typescore,{
                        fan = - t.fan * t.count,score = -t.score * t.count,type = t.type,tile = hu.tile,count = 1,
                    })
                end
            end
        end
    end

    return types
end

function maajan_table:get_gang_items(p)
    local items = {}
    for _,s in pairs(p.pai.ming_pai or {}) do
        if s.type == SECTION_TYPE.AN_GANG then
            table.insert(items,{
                fan = HU_TYPE_INFO[HU_TYPE.AN_GANG].fan,score = HU_TYPE_INFO[HU_TYPE.AN_GANG].score,
                type = HU_TYPE.AN_GANG,tile = s.tile,count = 1,time = s.time
            })
        end

        if s.type == SECTION_TYPE.MING_GANG then
            table.insert(items,{
                fan = HU_TYPE_INFO[HU_TYPE.MING_GANG].fan,score = HU_TYPE_INFO[HU_TYPE.MING_GANG].score,
                type = HU_TYPE.MING_GANG, tile = s.tile,whoee = s.whoee,count = 1,player_count = 1
            })
        end

        if s.type == SECTION_TYPE.BA_GANG then
            table.insert(items,{
                fan = HU_TYPE_INFO[HU_TYPE.BA_GANG].fan, score = HU_TYPE_INFO[HU_TYPE.BA_GANG].score,
                type = HU_TYPE.BA_GANG,tile = s.tile,count = 1,time = s.time,
            })
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

    local types = {}
    table.walk(self:get_gang_items(p),function(t)
        if t.whoee then
            if p.hu or p.jiao and not is_dian_gang_pao then
                table.insert(table.get(types,p.chair_id,{}),{
                    type = t.type,score = t.score, fan = t.fan,tile = t.tile,count = 1
                })
                table.insert(table.get(types,t.whoee,{}),{
                    type = t.type,score = -t.score,fan = -t.fan,tile = t.tile,count = 1
                })
            end
            return
        end

        local player_count = table.sum(self.players,function(pj)
            return (pj ~= p and (not pj.hu or pj.hu.time > t.time)) and 1 or 0
        end)
        if p.hu or p.jiao and not is_dian_gang_pao then
            table.insert(table.get(types,p.chair_id,{}),{
                fan = t.fan,type = t.type,score = t.score * player_count * t.count,tile = t.tile,count = 1
            })
            self:foreach_except(p,function(pj,i)
                if not pj.hu or pj.hu.time > t.time then
                    table.insert(table.get(types,i,{}),{
                        fan = -t.fan,type = t.type,score = -t.score * t.count,tile = t.tile,count = 1
                    })
                end
            end)
        end
    end)

    return types
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

function maajan_table:balance_player(p)
    local hu_count = table.sum(self.players,function(v) return v.hu and 1 or 0 end)

    local items = {}
    if p.hu then
        local hu_res = self:calculate_hu(p,p.hu)
        for chair_id,item in pairs(hu_res) do
            table.get(items,chair_id,{}).hu = item
        end
    end

    if p.hu or p.jiao then
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


function maajan_table:game_balance()
    for _,p in pairs(self.players) do
        if not p.hu then
            local ting_tiles = mj_util.is_ting(p.pai)
            if table.nums(ting_tiles) > 0 then
                p.jiao = p.jiao or {tiles = ting_tiles}
            end
        end
    end

    local items = {}

    for c,_ in pairs(self.players) do
        items[c] = {
            hu = {},
            gang = {},
        }
    end

    for _,p in pairs(self.players) do
        local p_item = self:balance_player(p)
        for c,item in pairs(items) do
            local p_item_c = p_item[c]
            if p_item_c then
                if p_item_c.hu then
                    table.insert(item.hu,p_item_c.hu)
                end
                table.unionto(item.gang,p_item_c.gang or {})
            end
        end
    end

    return items
end

function maajan_table:on_game_overed()
    self.game_log = {}
    self:ding_zhuang()

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
    self:clear_event_pump()
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

    self.zhuang = nil
end

function maajan_table:ding_zhuang()
    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    if hu_count == 0 then
        return
    end

    local pao_counts = {}
    for _,p in pairs(self.players) do
        if p.hu then
            table.incr(pao_counts,self.players[p.hu.zi_mo and p.chair_id or p.hu.whoee].chair_id)
        end
    end

    local max_chair,max_c = table.max(pao_counts)
    if max_c and max_c > 1 then
        self.zhuang = max_chair
        return
    end

    local ps = table.values(self.players)
    table.sort(ps,function(l,r)
        if l.hu and not r.hu then return true end
        if not l.hu and r.hu then return false end
        return l.hu.time < r.hu.time
    end)

    self.zhuang = ps[1].chair_id
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

function maajan_table:on_cs_huan_pai(player,msg)
    self:safe_event({chair_id = player.chair_id,player = player,type = ACTION.HUAN_PAI,msg = msg})
end

function maajan_table:on_cs_ding_que(player,msg)
    self:safe_event({chair_id = player.chair_id,player = player,type = ACTION.DING_QUE,msg = msg})
end

function maajan_table:safe_event(evt)
    if self.cur_state_FSM ~= FSM_S.GAME_CLOSE then
        for k,v in pairs(FSM_E) do
            if evt.type == v then
                log.info("cur event is " .. k)
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
                [FSM_S.DING_QUE] = "DING_QUE",
                [FSM_S.HUAN_PAI] = "HUAN_PAI",
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

    local ret,msg = resume(self.co,evt)
    if not ret then
        error(debug.traceback(self.co,msg))
    end
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

function maajan_table:update_state(new_state)
    self.cur_state_FSM = new_state
end

function maajan_table:is_action_time_out()
    local time_out = (os.time() - self.last_action_change_time_stamp) >= def.ACTION_TIME_OUT 
    return time_out
end

function maajan_table:next_player_index()
    local chair = self.chu_pai_player_index
    repeat
        chair = (chair % self.chair_count) + 1
    until not self.players[chair].hu
    self.chu_pai_player_index = chair
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
                    type = (action == ACTION.BA_GANG and SECTION_TYPE.BA_GANG or SECTION_TYPE.FREE_BA_GANG),
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
        que_men = player.que or -1,
        pb_players = {},
    }

    self:foreach(function(v)
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

        if self.chu_pai_player_index == chair_id then
            tplayer.mo_pai = v.mo_pai
        end
        table.insert(msg.pb_players,tplayer)
    end)

    dump(msg)
    
    local last_chu_pai_player,last_tile = self:get_last_chu_pai()
    if is_reconnect then
        msg.pb_rec_data = {
            last_chu_pai_chair = last_chu_pai_player and last_chu_pai_player.chair_id or nil,
            last_chu_pai = last_tile
        }
    end

    send2client_pb(player,"SC_Maajan_Desk_Enter",msg)
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
    
    player.deposit = nil
    self:send_data_to_enter_player(player,true)

    self:safe_event({
        type = ACTION.RECONNECT,
        player = player,
    })

    base_table.reconnect(self,player)
end

function maajan_table:can_hu(player,in_pai)
    local hu_types = mj_util.hu(player.pai,in_pai)
    if table.nums(hu_types) == 0 then
        return false
    end

    local hu_type = self:max_hu_score(hu_types)
    local gang = table.sum(player.pai.ming_pai,function(s)
        return (s.type == SECTION_TYPE.AN_GANG or s.type == SECTION_TYPE.MING_GANG or
                s.type == SECTION_TYPE.BA_GANG ) and 1 or 0
    end)

    local chu_pai_player = self:chu_pai_player()
    return  def.is_action_gang(chu_pai_player.last_action or 0) or
            gang > 0 or
            hu_type.score > 1
end

function maajan_table:hu_type_score(types)
    local hts = {}
    for type,count in pairs(types) do
        table.insert(hts,{
            fan = HU_TYPE_INFO[type].fan,
            score = HU_TYPE_INFO[type].score,
            type = type,
            count = count,
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