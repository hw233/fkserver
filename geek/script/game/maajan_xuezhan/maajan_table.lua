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
local timer_manager = require "game.timer_manager"

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

function maajan_table:get_trustee_conf()
    local trustee = self.conf and self.conf.conf and self.conf.conf.trustee or nil
    if trustee and trustee.type_opt ~= nil and trustee.second_opt ~= nil then
        local trstee_conf = self.room_.conf.private_conf.trustee
        local seconds = trstee_conf.second_opt[trustee.second_opt + 1]
        local type = trstee_conf.type_opt[trustee.type_opt + 1]
        log.info("%d,%d",seconds,type)
        return type,seconds
    end

    return nil
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

function maajan_table:set_trusteeship(player,trustee)
    if player.trustee and trustee then
        return 
    end

    trustee = trustee and true or false
    base_table.set_trusteeship(self,player,trustee)
    player.trustee = trustee and true or nil
    self:safe_event({player = player,type = ACTION.TRUSTEE,trustee = trustee})
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
            local mens = table.agg(tiles,{},function(tb,t)
                table.incr(tb,math.floor(t / 10))
                return tb
            end)
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
    end

    local timer
    local action_timers = {}
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function random_choice(tilecounts,count)
            local counts = tilecounts
            local tiles = {}
            for _ = 1,count do
                local c = 0
                local tile
                repeat
                    tile,c = table.choice(counts)
                until c > 0

                table.decr(counts,tile)
                table.insert(tiles,tile)
            end

            for _,tile in pairs(tiles) do
                table.incr(counts,tile)
            end

            return tiles
        end

        local function auto_huan_pai(p,huan_type,huan_count)
            if huan_type ~= 1 then
                local huan_pai = random_choice(p.pai.shou_pai,huan_count)
                dump(huan_pai)
                self:safe_event({player = p,type = ACTION.HUAN_PAI,msg = {tiles = huan_pai}})
                return
            end

            local men_tiles = table.agg(p.pai.shou_pai,{},function(tb,c,tile)
                table.get(tb,math.floor(tile / 10),{})[tile] = c
                return tb
            end)

            local c = 0
            local tiles
            repeat
                local men,_ = table.choice(men_tiles)
                tiles = men_tiles[men]
                c = table.sum(tiles)
            until c > huan_count

            local huan_tiles = random_choice(tiles,huan_count)
            self:safe_event({player = p,type = ACTION.HUAN_PAI,msg = {tiles = huan_tiles}})
            return
        end

        local huan_count = self:get_huan_count()
        local huan_type = self:get_huan_type()
        log.info("%s,%s",huan_type,huan_count)
        timer = timer_manager:new_timer(trustee_seconds,function()
            self:foreach(function(p)
                if p.pai.huan then return end

                self:set_trusteeship(p,true)
                auto_huan_pai(p,huan_type,huan_count)
            end)
        end)

        self:begin_clock(trustee_seconds)

        self:foreach(function(p)
            if not p.trustee then return end
            
            local act_timer = timer_manager:calllater(math.random(1,2),function()
                auto_huan_pai(p,huan_type,huan_count)
            end)

            action_timers[p.chair_id] = act_timer
        end)
    end

    repeat
        local evt = yield()
        if evt.type == ACTION.CLOSE then
            if timer then timer:kill() end
            for _,timer in pairs(action_timers) do
                timer:kill()
            end
            self:clear_event_pump()
            return
        end

        if evt.type == ACTION.RECONNECT then
            local player = evt.player
            send2client_pb(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
            self:send_huan_pai_status(player)
            if timer then
                self:begin_clock(timer.remainder,player)
            end
        elseif evt.type == ACTION.TRUSTEE then
            if not evt.trustee then
                local chair = evt.player.chair_id
                if action_timers[chair] then
                    action_timers[chair]:kill()
                end
            end
        else
            local player = evt.player
            local chair = player.chair_id
            on_huan_pai(player,evt.msg)
            if action_timers[chair] then
                action_timers[chair]:kill()
            end
        end
    until table.logic_and(self.players,function(p) return p.pai.huan ~= nil end)

    if timer then timer:kill() end

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
    end

    local timer
    local action_timers = {}
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_ding_que(p)
            local men_count = table.agg(p.pai.shou_pai,{},function(tb,c,tile)
                table.incr(tb,math.floor(tile / 10),c)
                return tb
            end)

            dump(men_count)

            local min_men,c = table.min(men_count)
            log.info("%s,%s",min_men,c)
            self:safe_event({player = p,type = ACTION.DING_QUE,msg = {men = min_men}})
        end
        timer = timer_manager:new_timer(trustee_seconds,function()
            self:foreach(function(p)
                if p.que then return end

                self:set_trusteeship(p,true)
                auto_ding_que(p)
            end)
        end)

        self:begin_clock(trustee_seconds)

        self:foreach(function(p)
            if not p.trustee then return end
            local act_timer = timer_manager:calllater(math.random(1,2),function() 
                auto_ding_que(p)
            end)

            action_timers[p.chair_id] = act_timer
        end)
    end

    repeat
        local evt = yield()
        repeat
            if evt.type == ACTION.CLOSE then
                if timer then timer:kill() end
                for _,timer in pairs(action_timers) do
                    timer:kill()
                end
                self:clear_event_pump()
                return
            end

            if evt.type == ACTION.RECONNECT then
                local player = evt.player
                send2client_pb(player,"SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
                self:send_ding_que_status(player)
                if timer then
                    self:begin_clock(timer.remainder,player)
                end
                break
            end

            if evt.type == ACTION.TRUSTEE then
                local chair = evt.player.chair_id
                if not evt.trustee and action_timers[chair] then
                    action_timers[chair]:kill()
                end
                break
            end

            local chair = evt.player.chair_id
            on_ding_que(evt.player,evt.msg)
            if action_timers[chair] then
                action_timers[chair]:kill()
            end
        until true
    until table.logic_and(self.players,function(p) return p.que ~= nil end)

    if timer then timer:kill() end

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
            local ming_pai_count = table.sum(player.pai.ming_pai,function(_) return 1 end)
            player.hu = {
                time = os.time(),
                tile = tile,
                types = mj_util.hu(player.pai),
                zi_mo = true,
                tian_hu = (player.chair_id == self.zhuang and player.mo_pai_count == 1) and true or nil,
                di_hu = (player.chair_id ~= self.zhuang and player.mo_pai_count == 1 and ming_pai_count == 0) and true or nil,
                hai_di = self.dealer.remain_count == 0 and true or nil,
                gang_hua = player.last_action and def.is_action_gang(player.last_action.action or 0)  or nil,
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
            self:broadcast2client("SC_Maajan_Do_Action",{chair_id = player.chair_id,action = do_action})
            self:gotofunc(function() self:chu_pai() end)
        end

        self:done_last_action(player,{action = do_action,tile = tile,})
    end

    local timer
    local action_timers = {}
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_action(p,action)
            local act = action.actions[ACTION.ZI_MO] and ACTION.ZI_MO or ACTION.PASS
            local tile = p.mo_pai
            self:safe_event({chair_id = p.chair_id,type = act,tile = tile})
        end

        timer = timer_manager:new_timer(trustee_seconds,function()
            dump(waiting_actions)
            table.foreach(waiting_actions,function(action,_) 
                if action.done then return end

                local p = self.players[action.chair_id]
                self:set_trusteeship(p,true)
                auto_action(p,action)
            end)
        end)

        self:begin_clock(trustee_seconds)

        table.foreach(waiting_actions,function(action,_) 
            dump(waiting_actions)
            local p = self.players[action.chair_id]
            if not p.trustee then return end

            local act_timer = timer_manager:calllater(math.random(1,2),function() 
                auto_action(p,action)
            end)

            action_timers[action.chair_id] = act_timer
        end)
    end

    while true do
        local evt = yield()
        if evt.type == ACTION.CLOSE then
            if timer then timer:kill() end
            self:clear_event_pump()
            return
        end

        if evt.type == ACTION.RECONNECT then
            reconnect(evt.player)
            if timer then
                self:begin_clock(timer.remainder,player)
            end
        elseif evt.type == ACTION.TRUSTEE then
            local chair = evt.player.chair_id
            if not evt.trustee and action_timers[chair] then
                action_timers[chair]:kill()
            end
        else
            if timer then timer:kill() end
            local chair = evt.chair_id
            if action_timers[chair] then
                action_timers[chair]:kill()
            end
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

    local timer
    local action_timers = {}
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_action(p,action)
            local act = action.actions[ACTION.HU] and ACTION.HU or ACTION.PASS
            local tile = self:chu_pai_player().chu_pai
            self:safe_event({chair_id = p.chair_id,type = act,tile = tile})
        end

        timer = timer_manager:new_timer(trustee_seconds,function()
            table.foreach(waiting_actions,function(action,_) 
                local p = self.players[action.chair_id]
                self:set_trusteeship(p,true)
                auto_action(p,action)
            end)
        end)

        self:begin_clock(trustee_seconds)

        table.foreach(waiting_actions,function(action,_) 
            local p = self.players[action.chair_id]
            if not p.trustee then return end

            local act_timer = timer_manager:calllater(math.random(1,2),function() 
                auto_action(p,action)
            end)
        
            action_timers[p.chair_id] = act_timer
        end)
    end

    repeat
        local evt = yield()
        if evt.type == ACTION.CLOSE then
            if timer then timer:kill() end
            for _,timer in pairs(action_timers) do
                timer:kill()
            end
            self:clear_event_pump()
            return
        elseif evt.type == ACTION.RECONNECT then
            reconnect(evt.player)
            if timer then
                self:begin_clock(timer.remainder,player)
            end
        elseif evt.type == ACTION.TRUSTEE then
            local chair = evt.player.chair_id
            if not evt.trustee and action_timers[chair] then
                action_timers[chair]:kill()
            end
        else
            local action = self:check_action_before_do(waiting_actions,evt)
            if action then
                action.done = {
                    action = evt.type,
                    tile = evt.tile,
                }
            end

            local chair = action.chair_id
            if action_timers[chair] then
                action_timers[chair]:kill()
            end
        end
    until table.logic_and(waiting_actions,function(action) return action.done ~= nil end)

    if timer then timer:kill() end

    local all_actions = table.values(waiting_actions)
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
                    hai_di = self.dealer.remain_count == 0 and true or nil,
                    whoee = self.chu_pai_player_index,
                    gang_pao = chu_pai_player.last_action and def.is_action_gang(chu_pai_player.last_action.action) or nil,
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
            self:broadcast2client("SC_Maajan_Do_Action",{chair_id = player.chair_id,action = ACTION.PASS})
            self:next_player_index()
            self:gotofunc(function() self:mo_pai() end)
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

    local timer
    local chu_pai_timer
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_chu_pai(p)
            local men_tiles = table.agg(p.pai.shou_pai,{},function(tb,c,tile)
                if c == 0 then return tb end
                table.get(tb,math.floor(tile / 10),{})[tile] = c
                return tb
            end)

            local chu_pai = p.mo_pai
            if men_tiles[p.que] and table.sum(men_tiles[p.que]) > 0 then
                local c
                repeat
                    chu_pai,c = table.choice(men_tiles[p.que])
                    log.info("%d,%d",chu_pai,c)
                until c and c > 0
            end

            log.info("auto_chu_pai chair_id %s,tile %s",p.chair_id,chu_pai)
            self:safe_event({chair_id = p.chair_id,type = ACTION.CHU_PAI,tile = chu_pai})
        end

        local player = self:chu_pai_player()

        timer = timer_manager:new_timer(trustee_seconds,function()
            self:set_trusteeship(player,true)
            auto_chu_pai(player)
        end)

        self:begin_clock(trustee_seconds)

        if player.trustee then
            chu_pai_timer = timer_manager:calllater(math.random(1,2),function()
                auto_chu_pai(player)
            end)
        end
    end

    local evt
    while true do
        evt = yield()
        if evt.type == ACTION.CLOSE then
            if timer then timer:kill() end
            if chu_pai_timer then chu_pai_timer:kill() end
            self:clear_event_pump()
            return
        end

        if evt.type == ACTION.RECONNECT then
            reconnect(evt.player)
            if timer then
                self:begin_clock(timer.remainder,player)
            end
        elseif evt.type == ACTION.TRUSTEE then
            if not evt.trustee and evt.player.chair_id == self.chu_pai_player_index then
                chu_pai_timer:kill()
            end
        else
            break
        end
    end

    if timer then timer:kill() end
    if chu_pai_timer then chu_pai_timer:kill() end

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

function maajan_table:get_max_fan()
    local fan_opt = self.conf.conf.fan.max_option
    return self.room_.conf.private_conf.fan.fan_option[fan_opt]
end

function maajan_table:do_balance()
    local typefans,scores = self:game_balance()
    local max_fan = self:get_max_fan() or 3
    local fans = table.agg(typefans,{},function(tb,v,chair)
        local fan = table.sum(v,function(t) return t.fan * t.count end)
        tb[chair] = fan > max_fan and max_fan or fan
        return tb
    end)

    self:foreach(function(p)
        if not p.hu then return end

        local chair_id = p.chair_id
        local fan = fans[chair_id]
        local fan_score = 2 ^ math.abs(fan)
        if not p.hu.zi_mo then
            local whoee = p.hu.whoee
            scores[whoee] = (scores[whoee] or 0) - fan_score
            scores[chair_id] = (scores[chair_id] or 0) + fan_score
            return
        end

        self:foreach_except(p,function(pi)
            if pi.hu and pi.hu.time <= p.hu.time then return end

            local chair_i = pi.chair_id
            scores[chair_i] = (scores[chair_i] or 0) - fan_score
            scores[chair_id] = (scores[chair_id] or 0) + fan_score
        end)
    end)

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
            hu_fan = fans[chair_id],
            hu = p.hu ~= nil,
        })

        local win_money = self:calc_score_money(p_score)
        chair_money[chair_id] = win_money
        log.info("player hu %s,%s,%s",chair_id,p_score,win_money)
    end

    dump(msg)

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

function maajan_table:calculate_hu(p)
    local types = {}

    if p.hu then
        local hu = p.hu
        if hu.qiang_gang then
            local t = HU_TYPE.QIANG_GANG_HU
            table.insert(types,{type = t,fan = HU_TYPE_INFO[t].fan,count = 1})
        end

        if hu.gang_hua then
            local t = HU_TYPE.GANG_SHANG_HUA
            table.insert(types,{type = t,fan = HU_TYPE_INFO[t].fan,count = 1})
        end

        if self.conf.conf.play.tian_di_hu then
            if hu.tian_hu then
                local t = HU_TYPE.TIAN_HU
                table.insert(types,{type = t,fan = HU_TYPE_INFO[t].fan,count = 1})
            end

            if hu.di_hu then
                local t = HU_TYPE.DI_HU
                table.insert(types,{type = t,fan = HU_TYPE_INFO[t].fan,count = 1})
            end
        end

        if hu.hai_di then
            local t = HU_TYPE.HAI_DI_LAO_YUE
            table.insert(types,{type = t,fan = HU_TYPE_INFO[t].fan,count = 1})
        end

        if hu.zi_mo and self.conf.conf.play.zi_mo_jia_fan then
            local t = HU_TYPE.ZI_MO
            table.insert(types,{type = t,fan = HU_TYPE_INFO[t].fan,count = 1})
        end

        if hu.gang_pao then
            local t = HU_TYPE.GANG_SHANG_PAO
            table.insert(types,{type = t,fan = HU_TYPE_INFO[t].fan,count = 1})
        end

        local ts = self:get_hu_items(hu)
        for _,t in pairs(ts) do
            repeat
                if (t.type == HU_TYPE.QUAN_YAO_JIU and not self.conf.conf.play.yao_jiu) or
                    (t.type == HU_TYPE.MEN_QING and not self.conf.conf.play.men_qing) then
                    break
                end

                table.insert(types,{type = t.type,fan = t.fan,count = t.count})
            until true
        end
    end

    return types
end

function maajan_table:calculate_gang(p)
    if not p.hu and not p.jiao then return end

    local s2hu_type = {
        [SECTION_TYPE.MING_GANG] = HU_TYPE.MING_GANG,
        [SECTION_TYPE.AN_GANG] = HU_TYPE.AN_GANG,
        [SECTION_TYPE.BA_GANG] = HU_TYPE.BA_GANG,
    }

    local gangfans = table.agg(p.pai.ming_pai,{},function(tb,s)
        local t = s2hu_type[s.type]
        if not t then return tb end
        local v = table.get(tb,t,{fan = 0,count = 0})
        v.fan = v.fan + HU_TYPE_INFO[t].fan
        v.count = v.count + 1
        return tb
    end)

    local scores = table.agg(p.pai.ming_pai,{},function(tb,s)
        local t = s2hu_type[s.type]
        if not t then return tb end
        local hu_type_info = HU_TYPE_INFO[t]

        if t == HU_TYPE.MING_GANG then
            tb[p.chair_id] = (tb[p.chair_id] or 0) + hu_type_info.score
            tb[s.whoee] = (tb[s.whoee] or 0) - hu_type_info.score
        elseif t == HU_TYPE.AN_GANG or t == HU_TYPE.BA_GANG then
            self:foreach_except(p,function(pi)
                if pi.hu and pi.hu.time < s.time then return end

                tb[p.chair_id] = (tb[p.chair_id] or 0) + hu_type_info.score
                tb[pi.chair_id] = (tb[pi.chair_id] or 0) - hu_type_info.score
            end)
        end

        return tb
    end)

    local fans = table.agg(gangfans,{},function(tb,v,t)
        table.insert(tb,{type = t,fan = v.fan,count = v.count})
        return tb
    end)

    return fans,scores
end

function maajan_table:calculate_wei_hu(p)
    local types = {}
    local hu_count = table.sum(self.players,function(pi) return pi.hu and 1 or 0 end)
    if hu_count == 0 then
        if p.jiao then
            self:foreach_except(p,function(pi)
                if not (pi.jiao or pi.hu) then
                    table.insert(table.get(types,p.chair_id,{
                        types = {}
                    }).types,{type = HU_TYPE.JIAO_PAI,count = 1})
                end
            end)
        end
    end

    return types
end


function maajan_table:game_balance()
    self:foreach(function(p)
        if p.hu then return end

        local ting_tiles = mj_util.is_ting(p.pai)
        if table.nums(ting_tiles) > 0 then
            p.jiao = p.jiao or {tiles = ting_tiles}
        end
    end)

    local fans,scores = {},{}
    self:foreach(function(p)
        local hu = self:calculate_hu(p)
        local gangfans,gangscores = self:calculate_gang(p)
        fans[p.chair_id] = table.union(hu or {},gangfans or {})
        table.mergeto(scores,gangscores or {},function(l,r) return (l or 0) + (r or 0) end)
    end)

    return fans,scores
end

function maajan_table:on_game_overed()
    self.game_log = {}
    self:ding_zhuang()

    self:clear_ready()
    self:update_state(FSM_S.PER_BEGIN)

    if not self.private_id then
        for _,v in ipairs(self.players) do
            v.hu = nil
            v.jiao = nil
            v.pai = {
                ming_pai = {},
                shou_pai = {},
                desk_tiles = {},
                huan = nil,
            }
            v.que = nil
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

    local pao_counts = table.agg(self.players,{},function(tb,p) 
        if not p.hu then return tb end
        table.incr(tb,self.players[p.hu.zi_mo and p.chair_id or p.hu.whoee].chair_id)
        return tb
    end)

    local max_chair,max_c = table.max(pao_counts)
    if max_c and max_c > 1 then
        self.zhuang = max_chair
        return
    end

    local ps = table.values(self.players)
    table.sort(ps,function(l,r)
        if l.hu and not r.hu then return true end
        if not l.hu and r.hu then return false end
        if not l.hu and not r.hu then return true end
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
	
end

function maajan_table:on_offline(player)
    self:set_trusteeship(player,true)
    
    base_table.on_offline(self,player)
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

    if self:is_play() then
        self:safe_event({
            type = ACTION.RECONNECT,
            player = player,
        })
    end

    self:set_trusteeship(player)

    base_table.reconnect(self,player)
end

function maajan_table:begin_clock(timeout,player,total_time)
    if player then 
        send2client_pb(player,"SC_TimeOutNotify",{
            left_time = timeout,
            total_time = total_time,
        })
        return
    end

    self:broadcast2client("SC_TimeOutNotify",{
        left_time = timeout,
        total_time = total_time,
    })
end

function maajan_table:can_hu(player,in_pai)
    return mj_util.is_hu(player.pai,in_pai)
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