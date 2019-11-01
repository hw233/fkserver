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

local FSM_E     = def.FSM_event
local FSM_S     = def.FSM_state

local ACTION = def.ACTION

local ACTION_PRIORITY = {
    [ACTION.JIA_BEI] = 6,
    [ACTION.PASS] = 5,
    [ACTION.LEFT_CHI] = 4,
    [ACTION.MID_CHI] = 4,
    [ACTION.RIGHT_CHI] = 4,
    [ACTION.PENG] = 3,
    [ACTION.AN_GANG] = 2,
    [ACTION.MING_GANG] = 2,
    [ACTION.BA_GANG] = 2,
    [ACTION.HU] = 1,
}



local maajan_table = base_table:new()

local function on_event_error(self,event_table)
    log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
end


-- 初始化
function maajan_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.tiles = {
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29, 31,32,33,34,35,36,37,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29, 31,32,33,34,35,36,37,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29, 31,32,33,34,35,36,37,
        1,2,3,4,5,6,7,8,9, 11,12,13,14,15,16,17,18,19, 21,22,23,24,25,26,27,28,29, 31,32,33,34,35,36,37,
    }
    
    self.dealer = maajan_tile_dealer:new(self.tiles)
    self.quan_feng = 13
    self.clock = timer_manager:new_timer(def.ACTION_TIME_OUT,function() end)
    self.clock:pause()

    
    self.state_event_handle = setmetatable({
        [FSM_S.WAIT_CHU_PAI] = self.on_action_when_wait_chu_pai,
        [FSM_S.WAIT_PENG_GANG_HU_CHI] = self.on_peng_gang_hu_chi,
        [FSM_S.WAIT_BA_GANG_HU] = self.ba_gang_hu,
        [FSM_S.GAME_BALANCE] = self.on_game_balance,
        [FSM_S.GAME_CLOSE] = self.on_game_close,
        [FSM_S.GAME_ERR] = self.on_game_error,
        [FSM_S.GAME_IDLE_HEAD] = self.on_game_idle_head,
    },{
        __index = function(t,s)
            return self.on_game_idle_head
        end
    })
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

    self:update_state(FSM_S.BU_HUA_BIG)
    self:on_bu_hua_big()
end

function maajan_table:wait_chu_pai()
    self:update_state(FSM_S.WAIT_CHU_PAI)
    self.clock:restart(function()
        self:increase_time_out_and_deposit(self.players[self.waiting_action.chair_id])
    end)
end

function maajan_table:wait_peng_gang_hu_chi()
    self:update_state(FSM_S.WAIT_PENG_GANG_HU_CHI)
    self.clock:restart(function()
        self:increase_time_out_and_deposit(self.players[self.waiting_action.chair_id])
    end)
end

function maajan_table:ba_gang_hu(event_table)
    local event_handle = {
        [FSM_E.PASS] = function(self,event_table)   
            self:do_mo_pai()
        end,
        [FSM_E.HU] = function(self,event_table)
            local act = self.waiting_action
            if act.hu and (act.chair_id == event_table.chair_id) then
                act.do_hu = true
            end
    
            if self.waiting_action.do_hu then -- 选择了胡
                local player = self.players[self.chu_pai_player_index]
                for _,v in pairs(player.pai.ming_pai) do--取消巴杠
                    if v[1] == self.last_chu_pai then
                        v[4],v[5] = nil,nil
                        break
                    end
                end
    
                local player_hu = self.players[event_table.chair_id]
                player_hu.hu = true
                player_hu.hu_time = os.time()
                player_hu.hu_pai = self.last_chu_pai
                player_hu.qiang_gang_hu = true
                player_hu.split_list = clone(act.split_list)
                player_hu.jiang_tile = act.jiang_tile
                
                self:broad_cast_player_hu(player_hu,true)
                self:update_state(FSM_S.GAME_BALANCE)
            end 
        end,
        [FSM_E.JIA_BEI] = function(self,event_table)
            if self.waiting_action.hu and (self.waiting_action.chair_id == event_table.chair_id) then
                self.waiting_action.do_jiabei = true
                local player = self.players[event_table.chair_id]
                self:player_jiabei(player)
                self:do_mo_pai()
            end
        end,
    }

    event_handle[event_table.type](self,event_table)
end

function maajan_table:on_action_when_wait_chu_pai(event_table)
    local action_handle = {
        [FSM_E.CHU_PAI] = self.on_chu_pai_when_wait_chu_pai,
        [FSM_E.GANG] = self.on_gang_when_wait_chu_pai,
        [FSM_E.HU] = self.on_hu_when_wait_chu_pai,
        [FSM_E.JIA_BEI] = self.on_jia_bei_when_wait_chu_pai,
    }

    local f = action_handle[event_table.type]
    if f then
        f(self,event_table)
    else
        log.error("maajan_table:on_action_when_wait_chu_pai action:%s",event_table.type)
    end
end

function maajan_table:on_peng_gang_hu_chi(event_table)
    local wait_action = self.wait_action[event_table.chair_id]
    if not wait_action then
        log.error("no action waiting when on_peng_gang_hu_chi_bei,action:%s",event_table.type)
        return
    end

    wait_action.done = {
        action = event_table.type,
        param = msg,
    }
 
    if not table.logic_and(self.wait_action,function(wait_action) 
        return wait_action.done ~= nil
    end) 
    then
        return
    end

    local actions = {}
    for _,action in pairs(self.wait_action) do
        table.insert(actions,action)
    end

    table.sort(actions,function(l,r) 
        local l_priority = ACTION_PRIORITY[l.done.action]
        local r_priority = ACTION_PRIORITY[l.done.action]
        if l_priority ~= r_priority then
            return l_priority < r_priority
        end

        return l.chair_id < r.chair_id
    end)

    self.do_action = actions[1]
    self:judge_action_peng_gang_hu_chi_bei_after_event()
    self.done = nil
    self.wait_action = {}
end

function maajan_table:on_bu_hua_big(event_table)
    -- local bu_hu_count = 0
    -- local bu_hua_table_01 = {{tiles = {}},{tiles = {}}}
    -- local bu_hua_table_02 = {{tiles = {}},{tiles = {}}}
    -- for k,v in pairs(self.players) do
    --     while true do
    --         for tile,_ in pairs(v.pai.shou_pai) do
    --             if math.floor(tile / 10) > 2 then
    --                 local mo_pai = self.dealer:deal_one_on(function(t) end)
    --                 local player_pai = v.pai.shou_pai
    --                 player_pai[tile] = nil
    --                 player_pai[mo_pai]  = (player_pai[mo_pai] or 0) + 1

    --                 if k == 1 then
    --                     table.insert(bu_hua_table_01[k].tiles,tile)
    --                     table.insert(bu_hua_table_01[k].tiles,mo_pai)
    --                     table.insert(bu_hua_table_02[k].tiles,tile)
    --                     table.insert(bu_hua_table_02[k].tiles,255)
    --                 else
    --                     table.insert(bu_hua_table_01[k].tiles,tile)
    --                     table.insert(bu_hua_table_01[k].tiles,255)
    --                     table.insert(bu_hua_table_02[k].tiles,tile)
    --                     table.insert(bu_hua_table_02[k].tiles,mo_pai)
    --                 end
                    
    --                 table.insert(v.pai.hua_pai,tile)
    --                 log.info(string.format( "bu hua %s %s",mj_util.getPaiStr({tile}),mj_util.getPaiStr({mo_pai})))
    --                 bu_hu_count = bu_hu_count + 1
    --             end
    --         end
            
    --         local bu_hu_finish = true
    --         for t,_ in pairs(v.pai.shou_pai) do
    --             if math.floor(t / 10) == 4 then
    --                 bu_hu_finish = false 
    --                 break
    --             end
    --         end
    --         if bu_hu_finish then 
    --             break 
    --         end
    --     end
    -- end

    -- if bu_hu_count > 0 then
    --     send2client_pb(self.players[1],"SC_Maajan_Bu_Hua",{pb_bu_hu = bu_hua_table_01})
    --     send2client_pb(self.players[2],"SC_Maajan_Bu_Hua",{pb_bu_hu = bu_hua_table_02})

    --     self.game_log.players[1].bu_hua = clone(bu_hua_table_01)
    --     self.game_log.players[2].bu_hua = clone(bu_hua_table_02)
    -- end

    for k,v in ipairs(self.players) do
        if k == self.zhuang then
            v.tian_ting = mj_util.panTing_14(v.pai)
        else
            v.tian_ting = mj_util.panTing(v.pai)
        end
    end

    self:wait_chu_pai()
    self.clock = timer_manager:new_timer(def.ACTION_TIME_OUT,function()
        self:on_timeout_when_wait_chu_pai()
    end)
end

function maajan_table:do_mo_pai()
    self:update_state(FSM_S.WAIT_MO_PAI)

    local mo_pai
    local mo_pai_table_dis = {}
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai
    repeat
        local len = self.dealer.remain_count
        log.info("-------left pai " .. len .. " tile")
        if len == 0 then
            self:update_state(FSM_S.GAME_BALANCE)
            break
        end

        player.mo_pai_count = player.mo_pai_count + 1
        mo_pai = self.dealer:deal_one()
        shou_pai[mo_pai] = (shou_pai[mo_pai] or 0) + 1
        log.info("---------mo pai:  %s ------",mo_pai)
        self:wait_chu_pai()
    until true
    self:auto_act_if_deposit(player,"hu_mo_pai")
    self:auto_act_if_deposit(player,"gang_mo_pai")
    self:broadcast2client("SC_Maajan_Tile_Left",{tile_left = self.dealer.remain_count,})
    for k,v in pairs(self.players) do
        if v.chair_id == self.chu_pai_player_index and mo_pai then
            send2client_pb(v,"SC_Maajan_Draw",{tile = mo_pai,chair_id = k})
            table.insert(self.game_log.action_table,{chair = k,act = "Draw",msg = {tiles = mo_pai}})
        else
            send2client_pb(v,"SC_Maajan_Draw",{tile = 255,chair_id = player.chair_id})
        end
    end
end

function maajan_table:on_timeout_when_wait_chu_pai(event_table)
    local player = self:chu_pai_player()
    local last_index = #player.pai.shou_pai
    self:do_chu_pai(player.pai.shou_pai[last_index])
    self:increase_time_out_and_deposit(player)
end

function maajan_table:on_chu_pai_when_wait_chu_pai(event_table)
    self:do_chu_pai(event_table.tile)
end

function maajan_table:on_gang_when_wait_chu_pai(event_table) --自杠 巴杠
    local cur_chu_pai_player = self:chu_pai_player()
    if cur_chu_pai_player.chair_id == event_table.chair_id then
        cur_chu_pai_player.last_act_is_gang = false
        local actions = mj_util.get_actions(cur_chu_pai_player.pai)
        local gp = event_table.tile
        if actions[ACTION.AN_GANG] and actions[ACTION.AN_GANG][gp] then
            self:do_mo_pai()
            self:adjust_shou_pai(cur_chu_pai_player,ACTION.AN_GANG,gp,true)
        end

        if actions[ACTION.BA_GANG] and actions[ACTION.BA_GANG][gp] then
            self.last_chu_pai = gp
            self:adjust_shou_pai(cur_chu_pai_player,ACTION.BA_GANG,gp)

            local hu_player = {}
            self.wait_action = {}
            for k,v in pairs(self.players) do
                if v and k ~= self.chu_pai_player_index then --排除自己
                    local actions = mj_util.get_actions(v.pai, self.last_chu_pai)
                    actions[ACTION.BA_GANG] = nil -- 别人出的牌  不能巴杠
                    actions[ACTION.PENG] = nil
                    actions[ACTION.AN_GANG] = nil
                    actions[ACTION.LEFT_CHI] = nil
                    actions[ACTION.MID_CHI] = nil
                    actions[ACTION.RIGHT_CHI] = nil
                    actions.chair_id = v.chair_id
                    if actions[ACTION.HU] then
                        hu_player = v
                        if self:hu_fan_match(hu_player) then
                            self.wait_action[k] = actions
                        end
                    end
                end
            end
            
            if #self.wait_action == 0 then
                self:do_mo_pai()
            else
                self:update_state(FSM_S.WAIT_BA_GANG_HU)
                self.clock:restart(function()
                    self:increase_time_out_and_deposit(self.players[self.wait_action.chair_id])
                    self:do_mo_pai()
                end)
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

    player.hu_info = mj_util.panHu(player.pai)
    if #player.hu_info > 0 then
        player.gang_shang_hua = player.last_act_is_gang
        if self.dealer.remain_count == 0 then
            player.miao_shou_hui_chun = true
        else
            player.zi_mo = true
        end

        if player.mo_pai_count == 0 and self.chu_pai_player_index == self.zhuang then
            player.tian_hu = true -- 天胡
        elseif player.mo_pai_count == 1 and not player.has_done_chu_pai then
            player.di_hu = true -- 地胡
        end

        if self:hu_fan_match(player) then
            player.hu_time = os.time()
            player.hu_pai = self.last_chu_pai
            self:broad_cast_player_hu(player,false)
            self:update_state(FSM_S.GAME_BALANCE)
        else
            player.gang_shang_hua = false
            player.miao_shou_hui_chun = false
            player.zi_mo = false
            player.tian_hu = false -- 天胡
            player.di_hu = false -- 地胡
            player.hu_info = nil
            player.split_list = nil
            player.jiang_tile = nil
        end
    end
end

function maajan_table:on_jia_bei_when_wait_chu_pai(event_table)
    local player = self.players[self.chu_pai_player_index]
    if (player.can_jiabei_this_chupai_round and player.chair_id == event_table.chair_id) then
        local hu_info = mj_util.panHu(player.pai)
        if #hu_info > 0 then
            player.can_jiabei_this_chupai_round = false
            self:player_jiabei(player)
            for k,v in ipairs(player.pai.shou_pai) do
                if v == event_table.tile then
                    --self:do_chu_pai(event_table.tile)
                    break
                end
            end
        end
    end
end

function maajan_table:on_wait_peng_gang_hu_chi(event)
    peng_chi_hu_gang_event_handle[event.type](self,event)
end

function maajan_table:on_game_balance(event_table)
    if event_table.type == FSM_E.UPDATE then
        local hu_player = nil
        local lost_player = nil
        local room_cell_score = self.cell_score_
        for k,v in pairs(self.players) do
            if v then 
                v.describe = v.describe or ""
                local log_p = self.game_log.players[v.chair_id]
                log_p.hu = v.hu
                log_p.pai = v.pai
                if v.hu then
                    hu_player = v
                    v.win_money = v.fan * room_cell_score
                    log.info("player hu",v.fan,v.win_money,v.describe)
                    log_p.fan = v.fan
                    log_p.describe = v.describe
                    log_p.win_money = v.win_money
                    log_p.finish_task = v.finish_task
                else
                    lost_player = v
                    v.ting = mj_util.panTing(v.pai)
                    log.info(string.format("GAME_BALANCE %d ting %s",v.chair_id,tostring(v.ting)))
                end
            end
        end
        local win_money = 0
        local win_taxes = 0
        if hu_player then
            win_money = hu_player.win_money
            for k,v in pairs(self.players) do
                if v.money < win_money then
                    win_money = v.money
                end
            end

            if lost_player.cost_money then
                win_taxes = math.ceil(win_money * self.room_:get_room_tax())
                --lost_player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = win_money}}, LOG_MONEY_OPT_TYPE_MAAJAN)
                --hu_player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = win_money - win_taxes}}, LOG_MONEY_OPT_TYPE_MAAJAN)
            end 
        else
            --流局
        end
        local msg = {}
        msg.pb_players = {}
        for k,v in pairs(self.players) do
            local tplayer = {}
            tplayer.chair_id = v.chair_id
            tplayer.finish_task = v.finish_task
            tplayer.is_hu = v.hu
            if v.hu then
                tplayer.win_money = win_money
                tplayer.taxes = win_taxes
            else
                tplayer.win_money = -win_money
                tplayer.taxes = 0
            end
            tplayer.hu_fan = v.fan
            tplayer.jiabei = v.jiabei
            tplayer.describe = v.describe
            tplayer.desk_pai = v.pai.desk_tiles
            tplayer.hua_pai = v.pai.hua_pai
            tplayer.shou_pai = v.pai.shou_pai
            tplayer.pb_ming_pai = {}
            for k1,v1 in pairs(v.pai.ming_pai) do
                table.insert(tplayer.pb_ming_pai,{tiles = v1})
            end
            table.insert(msg.pb_players,tplayer)
        end

        self:broadcast2client("SC_Maajan_Game_Finish",msg)

        self.game_log.end_game_time = os.time()
        local s_log = json.encode(self.game_log)
        log.info(s_log)
        self:save_game_log(self.game_log.table_game_id,self.def_game_name,s_log,self.game_log.start_game_time,self.game_log.end_game_time)

        self:update_state(FSM_S.GAME_CLOSE)
    else
        log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type) 
    end
end

function maajan_table:on_game_close(event_table)
    if event_table.type == FSM_E.UPDATE then
        self.do_logic_update = false
        self:clear_ready()

        local room_limit = self.room_:get_room_limit()
        for i,v in ipairs(self.players) do
            if v then
                if v.deposit then
                    v:forced_exit()
                else
                    v:check_forced_exit(room_limit)
                    if v.is_android then
                        self:ready(v)
                    end
                end
            end
        end

        for i,v in pairs (self.players) do
            if game_switch == 1 then--游戏将进入维护阶段
                if  v and v.is_player == true then 
                    send2client_pb(v, "SC_GameMaintain", {
                    result = GAME_SERVER_RESULT_MAINTAIN,
                    })
                    v:forced_exit()
                end
            end
        end
    else
        log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type)
    end
end

function maajan_table:on_game_error(event_table)
    if event_table.type == FSM_E.UPDATE then  
        for k,v in pairs(self.players) do
            if v then 
                v.hu = false
                v.ting = false
            end
        end  
        self:update_state(FSM_S.GAME_CLOSE)
    else
        log.info("FSM_event error cur_state/event is " .. self.cur_state_FSM .. "/" .. event_table.type)
    end
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
            for k,v in pairs(FSM_S) do
                if self.cur_state_FSM == v then
                    log.info("cur state is " .. k)
                    for _,v1 in pairs(self.players) do
                        if v1 and v1.pai then 
                            mj_util.printPai(self:tile_count_2_tiles(v1.pai.shou_pai))
                            local str = ""
                            for _,v in pairs(v1.pai.ming_pai) do
                                str = str .. " #" .. mj_util.getPaiStr(v)
                            end
                            if #str > 0 then log.info(str)	end
                       end
                    end
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
	local maajan_config = json.decode(self.room_.room_cfg)
	self.mj_min_scale = maajan_config.mj_min_scale
end

function maajan_table:start(player_count,is_test)
	local ret = base_table.start(self,player_count)
	for k,v in pairs(self.players) do
        v.hu                    = false
        v.deposit               = false
        v.miao_shou_hui_chun    = false
        v.hai_di_lao_yue        = false
        v.zi_mo                 = false
        v.last_act_is_gang      = false
        v.has_done_chu_pai      = false
        v.quan_qiu_ren          = false
        v.dan_diao_jiang        = false
        v.tian_ting             = false
        v.baoting               = false
        v.finish_task           = false
        v.can_jiabei_this_chupai_round = true
        v.hua_count             = 0
        v.mo_pai_count          = 0
        v.jiabei				= 0
        v.pai                   = {
            shou_pai = {},
            ming_pai = {},
            hua_pai = {},
            desk_tiles = {}
        }

        if is_test then
            v.deposit   = true
        end
    end
    
    self.timer = {}
    self.task = {
        tile = 0,
        type = 0
    }
	self.gongPai = {}
	self.cur_state_FSM             = FSM_S.PER_BEGIN
	self.chu_pai_player_index      = 1 --出牌人的索引   
	self.last_chu_pai              = -1 --上次的出牌
    self.waiting_action       = {}
    self.do_action = nil
	self.zhuang = math.random(1,player_count)
	self.record                = {}
	self:update_state(FSM_S.PER_BEGIN)
	self.do_logic_update = true
    self.quan_feng = self.quan_feng + 1 
    
    if self.quan_feng > 13 then 
        self.quan_feng = 10 
    end

    self.table_game_id = self:get_now_game_id()
    self:next_game()
    self.game_log = {
        table_game_id = self.table_game_id,
        start_game_time = os.time(),
        zhuang = self.zhuang,
        quan_feng = self.quan_feng,
        task = self.task,
        mj_min_scale = self.mj_min_scale,
        action_table = {},
        players = table.fill(nil,1,self.chair_count,{}),
    }

    self:on_pre_begin()
end

function maajan_table:prepare_tiles()
    self.dealer:shuffle()
    for i = 1,self.chair_count do
        local tiles = self.dealer:deal_tiles(self.zhuang == i and 14 or 13)
        for _,t in pairs(tiles) do
            local c = self.players[i].pai.shou_pai[t]
            self.players[i].pai.shou_pai[t] = (c or 0) + 1
        end
    end

    -- for _,p in pairs(self.players) do
    --     dump(p.pai)
    -- end
    

    self.gongPai = self.dealer:remain_tiles()

    local tile = math.random(1,#self.gongPai)
    if math.floor(tile / 10) < 3 then
        local act = {FSM_E.CHI,FSM_E.PENG,FSM_E.HU}
        self.task.tile = tile
        self.task.type = act[math.random(#act)]
    elseif math.floor(tile / 10) < 4 then
        local act = {FSM_E.PENG,FSM_E.HU}
        self.task.tile = tile
        self.task.type = act[math.random(#act)]
    end
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
function maajan_table:check_cancel_ready(player, is_offline)
	return true
end

function maajan_table:is_play( ... )
	return false
end

function maajan_table:reconnect(player)
    self:clear_deposit_and_time_out(player)
end

function maajan_table:tick()
    self.old_player_count = self.old_player_count or 1 
	local tmp_player_count = self:get_player_count()
	if self.old_player_count ~= tmp_player_count then
		-- log.info("player count", tmp_player_count)
        self.old_player_count = tmp_player_count
	end

	if self.do_logic_update then
		-- self:safe_event({type = FSM_E.UPDATE})
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
        self.Maintain_time = self.Maintain_time or get_second_time()
        if get_second_time() - self.Maintain_time > 5 then
            self.Maintain_time = get_second_time()
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
    self.clock:pause()
end

function maajan_table:increase_time_out_and_deposit(player)
    player.time_out_count = player.time_out_count or 0
    if player.time_out_count >= 2 then
        player.deposit = true
        player.time_out_count = 0
    end
end

--胡
function maajan_table:on_cs_act_win(player, msg)
    self:clear_deposit_and_time_out(player)
	self:safe_event({chair_id = player.chair_id,type = FSM_E.HU})
end

--加倍
function maajan_table:on_cs_act_double(player, msg)
    local msg_t = msg or {tile = player.pai.shou_pai[#player.pai.shou_pai]}
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = FSM_E.JIA_BEI,tile = msg_t.tile})
end

--打牌
function maajan_table:on_cs_act_discard(player, msg)
    if msg and msg.tile and mj_util.check_tile(msg.tile) then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = FSM_E.CHU_PAI,tile = msg.tile})
    end
end

--碰
function maajan_table:on_cs_act_peng(player, msg)
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = FSM_E.PENG})
end

--杠
function maajan_table:on_cs_act_gang(player, msg)
    if msg and msg.tile and mj_util.check_tile(msg.tile) then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = FSM_E.GANG,tile = msg.tile})
    end
end

--过
function maajan_table:on_cs_act_pass(player, msg)
    self:clear_deposit_and_time_out(player)
    self:safe_event({chair_id = player.chair_id,type = FSM_E.PASS})
end

--吃
function maajan_table:on_cs_act_chi(player, msg)
    if msg and msg.tiles and #msg.tiles == 3 then
        self:clear_deposit_and_time_out(player)
        self:safe_event({chair_id = player.chair_id,type = FSM_E.CHI,tiles = msg.tiles})
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
   --[[
    local ok = xpcall(maajan_table.FSM_event,function() log.info(debug.traceback()) end,self,...)
    if not ok then
        log.info("safe_event error") 
        self:update_state(FSM_S.GAME_ERR)
    end
    ]]
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

function maajan_table:broad_cast_player_hu(player,is_ba_gang_hu)
    assert(player.hu)
    player.is_ba_gang_hu = is_ba_gang_hu
    local msg = {chair_id = player.chair_id, tile = player.hu_pai,ba_gang_hu = 0}
    if is_ba_gang_hu then
        msg.ba_gang_hu = 1
    end

    self:broadcast2client("SC_Maajan_Act_Win",msg)
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
        local player = self:chu_pai_player()
        player.can_jiabei_this_chupai_round = true
        self:broadcast2client("SC_Maajan_Discard_Round",{chair_id = self.chu_pai_player_index})
    end
end

function maajan_table:is_action_time_out()
    local time_out = (os.time() - self.last_action_change_time_stamp) >= def.ACTION_TIME_OUT 
    return time_out
end

function maajan_table:next_player_index()
    self.chu_pai_player_index = (self.chu_pai_player_index + self.chair_count) % self.chair_count + 1
end

function maajan_table:jump_to_player_index(player)
    self.chu_pai_player_index = player.chair_id
end

function maajan_table:adjust_shou_pai(player, action, tile)
    local adjust_count = 0
    local shou_pai = player.pai.shou_pai
    local ming_pai = player.pai.ming_pai
   
    if action == ACTION.AN_GANG then 
        shou_pai[tile] = shou_pai[tile] - 4

        table.insert(ming_pai,{
            tile = tile,
            type = action,
        })
        self:broadcast2client("SC_Maajan_Act_Gang",{chair_id = player.chair_id,tile = tile,type = action})
        player.last_act_is_gang = true
    end

    if action == ACTION.MING_GANG then
        shou_pai[tile] = shou_pai[tile] - 3

        table.insert(ming_pai,{
            tile = tile,
            type = action,
        })
        self:broadcast2client("SC_Maajan_Act_Gang",{chair_id = player.chair_id,tile = tile,type = action})
        player.last_act_is_gang = true
    end

    if action == ACTION.BA_GANG then  --巴杠
        shou_pai[tile] = shou_pai[tile] - 1

        for k,s in ipairs(ming_pai) do
            if s.type == ACTION.PENG and s.tiles[1] == tile then
                ming_pai[k] = {
                    type = ACTION.BA_GANG,
                    tiles = tile,
                }
                break
            end
        end
        self:broadcast2client("SC_Maajan_Act_Gang",{chair_id = player.chair_id,tile = tile,type = action,})
        player.last_act_is_gang = true
    end

    if action == ACTION.PENG then
        shou_pai[tile] = shou_pai[tile] - 2

        table.insert(ming_pai,{
            type = ACTION.PENG,
            tiles = tile,
        })
        self:broadcast2client("SC_Maajan_Act_Peng",{chair_id = player.chair_id,tile = tile,type = action})
    end

    if action == ACTION.LEFT_CHI then
        table.decr(shou_pai,tile - 1)
        table.decr(shou_pai,tile - 2)
        table.insert(ming_pai,{
            type = ACTION.LEFT_CHI,
            tiles = tile,
        })
        self:broadcast2client("SC_Maajan_Act_Chi",{chair_id = player.chair_id,tile = tile,type = action})
    end

    if action == ACTION.MID_CHI then
        table.decr(shou_pai,tile - 1)
        table.decr(shou_pai,tile + 1)
        table.insert(ming_pai,{
            type = ACTION.MID_CHI,
            tiles = tile,
        })
        self:broadcast2client("SC_Maajan_Act_Chi",{chair_id = player.chair_id,tile = tile,type = action})
    end

    if action == ACTION.RIGHT_CHI then
        table.decr(shou_pai,tile + 1)
        table.decr(shou_pai,tile + 2)
        table.insert(ming_pai,{
            type = ACTION.RIGHT_CHI,
            tiles = tile,
        })
        self:broadcast2client("SC_Maajan_Act_Chi",{chair_id = player.chair_id,tile = tile,type = action})
    end
end

--掉线，离开，自动胡牌
function maajan_table:auto_act_if_deposit(player,type)
    local delay_seconds = 2
    if not player.deposit then
        return
    end

    if "hu_mo_pai" == type or "hu_ba_gang" == type or "hu_chu_pai" == type then
        local hu_info = 0
        if "hu_mo_pai" == type then 
            hu_info = mj_util.panHu(player.pai) 
        end

        if "hu_ba_gang" == type or "hu_chu_pai" == type then 
            hu_info = mj_util.panHu(player.pai,self.last_chu_pai)
        end
        
        if #hu_info > 0 then
            timer_manager:calllater(delay_seconds,function()
                self:safe_event({chair_id = player.chair_id,type = FSM_E.HU})  
            end)
        end
    elseif "gang_mo_pai" == type then
        timer_manager:calllater(delay_seconds,function()
            self:safe_event({chair_id = player.chair_id,type = FSM_E.GANG,tile = player.pai.shou_pai[#(player.pai.shou_pai)]})  
        end)
    elseif "gang_chu_pai" == type then
        timer_manager:calllater(delay_seconds,function()
            self:safe_event({chair_id = player.chair_id,type = FSM_E.GANG,tile = self.last_chu_pai})  
        end)
    elseif "peng_chu_pai" == type then
        timer_manager:calllater(delay_seconds,function()
            self:safe_event({chair_id = player.chair_id,type = FSM_E.PENG})  
        end)
    elseif "chi_chu_pai" == type then
        timer_manager:calllater(delay_seconds,function()
            self:safe_event({chair_id = player.chair_id,type = FSM_E.CHI, tiles = {self.last_chu_pai,self.last_chu_pai+1,self.last_chu_pai+2}})
            self:safe_event({chair_id = player.chair_id,type = FSM_E.CHI, tiles = {self.last_chu_pai-1,self.last_chu_pai,self.last_chu_pai+1}})
            self:safe_event({chair_id = player.chair_id,type = FSM_E.CHI, tiles = {self.last_chu_pai-2,self.last_chu_pai-1,self.last_chu_pai}})  
        end)
    end
end

--执行 出牌
function maajan_table:do_chu_pai(chu_pai_val)
    self.clock:pause()

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

    local shou_pai = player.pai.shou_pai
    if not shou_pai[chu_pai_val] or shou_pai[chu_pai_val] == 0 then
        log.error("tile isn't exist when chu guid:%s,tile:%s",player.guid,chu_pai_val)
        return
    end

    log.info("---------chu pai index: %s ------",self.chu_pai_player_index)
    log.info("---------chu pai val:   %s ------",chu_pai_val)
 
    shou_pai[chu_pai_val] = shou_pai[chu_pai_val] - 1
    self.last_chu_pai = chu_pai_val --上次的出牌
    table.insert(player.pai.desk_tiles,chu_pai_val)
    self:broadcast2client("SC_Maajan_Act_Discard",{chair_id = player.chair_id, tile = chu_pai_val})
    table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Discard",msg = {tile = chu_pai_val}})
    self.waiting_action = {}
    self:foreach_except(self.chu_pai_player_index,function(v) 
        if v.hu then return end

        local actions = mj_util.get_actions(v.pai, self.last_chu_pai)
        actions[ACTION.BA_GANG] = nil -- 别人出的牌  不能巴杠
        actions.chair_id = v.chair_id
        if actions[ACTION.HU] then
            if v.mo_pai_count == 0 then
                v.ren_hu = true
            end

            if self.dealer.remain_count == 0 then
                v.hai_di_lao_yue = true
            end

            local shou_pai_count = table.sum(v.pai.shou_pai)
            if shou_pai_count <= 2 then
                local an_gang_count = table.sum(v.pai.ming_pai,function(v)
                        return v.type == def.GANG_TYPE.AN_GANG and 1 or 0
                    end)
                v.quan_qiu_ren = an_gang_count == 0
                if not v.quan_qiu_ren then
                    v.dan_diao_jiang = true
                end
            end

            if not self:hu_fan_match(v) then
                actions[ACTION.HU] = nil
                v.ren_hu = false
                v.hai_di_lao_yue = false
                v.quan_qiu_ren = false
                v.dan_diao_jiang = false
            end
        end

        if #actions > 0 then
            self.waiting_action[v.chair_id] = actions
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
    
    if table.nums(self.waiting_action) == 0 then
        self:next_player_index()
        self:do_mo_pai()
    else
        self:wait_peng_gang_hu_chi()
    end

    player.last_act_is_gang = false
    player.has_done_chu_pai = true -- 出过牌了，判断地胡用
end

function maajan_table:on_peng_gang_hu_chi_bei_timeout()
    for chair_id,act in pairs(self.waiting_action) do
        self:on_peng_gang_hu_chi(FSM_E.PASS,{
            chair_id = act.chair_id,
        })
    end
end

function maajan_table:check_game_over()
    return self.dealer.remain_count == 0
end

function maajan_table:judge_action_peng_gang_hu_chi_bei_after_event()
    local act = self.do_action
    local act_player = self.players[act.chair_id]

    if not act_player then
        log.error("do action %s,nut wrong player in chair %s",act.done.action,act.chair_id)
        return
    end

    if not act[act.done.action] then
        log.error("do action %s,but not waiting action",act.done.action)
        return
    end

    local tile = self.last_chu_pai

    if act.done.action == ACTION.PENG then
        table.pop_back(act_player.pai.desk_tiles)
        self:adjust_shou_pai(act_player,act.done.action,tile)
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "Peng",msg = {tile = tile}}) 
        self:jump_to_player_index(act_player)
        self:wait_chu_pai()
    elseif def.is_action_gang(act.done.action) then
        table.pop_back(act_player.pai.desk_tiles)
        self:adjust_shou_pai(act_player,act.done.action,tile)
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "MingGang",msg = {tile = tile}})
        self:jump_to_player_index(act_player)
        self:do_mo_pai()
    elseif act.done.action == ACTION.HU then
        table.pop_back(act_player.pai.desk_tiles)
        act_player.hu = true
        act_player.hu_time = os.time()
        act_player.hu_pai = tile
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "Hu",msg = {tile = tile}})
        self:broad_cast_player_hu(act_player,false)
        self:update_state(FSM_S.GAME_BALANCE)
        self:jump_to_player_index(act_player)
        self:next_player_index()
    elseif def.is_action_chi(act.done.action) then
        if not act[act.done.action][tile] then
            return
        end

        local chi_cards
        if act.done.action == ACTION.LEFT_CHI then
            chi_cards = {tile - 2,tile - 1,tile}
        elseif act.done.action == ACTION.MID_CHI then
            chi_cards = {tile - 1,tile,tile + 1}
        elseif act.done.action == ACTION.RIGHT_CHI then
            chi_cards = {tile,tile + 1,tile + 2}
        end
       
        table.pop_back(act_player.pai.desk_tiles)
        self:adjust_shou_pai(act_player,act.done.action,tile)
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "Chi",msg = {tile = tile,tiles = chi_cards}})
        self:jump_to_player_index(act_player)
        self:wait_chu_pai()
    elseif act[ACTION.HU] and act.done.action == ACTION.JIA_BEI then
        act_player.ren_hu = false
        act_player.hai_di_lao_yue = false
        act_player.quan_qiu_ren = false
        act_player.dan_diao_jiang = false
        self:player_jiabei(act_player)
        self:jump_to_player_index(act_player)
        self:next_player_index()
        self:do_mo_pai()
        table.insert(self.game_log.action_table,{chair = act_player.chair_id,act = "JiaBei",msg = {tile = tile}}) 
    elseif act.done.action == ACTION.PASS then
        act_player.ren_hu = false
        act_player.hai_di_lao_yue = false
        act_player.quan_qiu_ren = false
        act_player.dan_diao_jiang = false
        self:next_player_index()
        self:do_mo_pai()
    end
end

function maajan_table:send_data_to_enter_player(player,is_reconnect)
    local msg = {}
    msg.state = self.cur_state_FSM
    msg.zhuang = self.zhuang
    msg.self_chair_id = player.chair_id
    msg.act_time_limit = def.ACTION_TIME_OUT
    msg.decision_time_limit = def.ACTION_TIME_OUT
    msg.is_reconnect = is_reconnect
    msg.pb_task_data = {
        task_type = self.task.type,
	    task_tile = self.task.tile,
	    task_scale = 2
    }
    msg.pb_players = {}
    for _,v in pairs(self.players) do
        local tplayer = {}
        tplayer.chair_id = v.chair_id
        tplayer.desk_pai = v.pai.desk_tiles
        tplayer.pb_ming_pai = v.pai.ming_pai
        tplayer.hua_pai = v.pai.hua_pai
        tplayer.shou_pai = {}
        if v.chair_id == player.chair_id then
            tplayer.shou_pai = self:tile_count_2_tiles(v.pai.shou_pai)
        else
            tplayer.shou_pai = table.fill(nil,1,table.sum(v.pai.shou_pai),255)
        end
        tplayer.is_ting = v.baoting
        table.insert(msg.pb_players,tplayer)
    end

    if is_reconnect then
        msg.pb_rec_data = {}
        msg.pb_rec_data.act_left_time = self.clock.remainder
        if msg.pb_rec_data.act_left_time < 0 then 
            msg.pb_rec_data.act_left_time = 0 
        end   
        msg.pb_rec_data.chu_pai_player_index = self.chu_pai_player_index
        msg.pb_rec_data.last_chu_pai = self.last_chu_pai
    end

    send2client_pb(player,"SC_Maajan_Desk_Enter",msg)

    if is_reconnect then
        send2client_pb(player,"SC_Maajan_Tile_Letf",{tile_left = self.dealer.remain_count,})
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
    self:send_data_to_enter_player(player,true)
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
    if self.task.type == FSM_E.CHI then
        for k,v in pairs(player.pai.ming_pai) do
            if mj_util.is_action_chi(v.type) and tile == v.tile then
                done = true break
            end
        end
    elseif self.task.type == FSM_E.PENG then
        for k,v in pairs(player.pai.ming_pai) do
            if v.type == ACTION.PENG and tile == v.tile then
                done = true break
            end
        end
    elseif self.task.type == FSM_E.HU then
        if player.hu_pai == tile then
            done = true
        end
    end
    return done
end

function maajan_table:hu_fan_match(player)
    self:calculate_hu(player)
    return player.fan >= self.mj_min_scale
end

function maajan_table:calculate_hu(player)
    local v = player
    local hu_info = clone(player.hu_info)
    local card_type = def.CARD_HU_TYPE_INFO
    if #(v.pai.hua_pai) == 8 then --全花
        table.insert(hu_info,card_type.QUAN_HUA)
    else
        for i=1,#(v.pai.hua_pai) do
            table.insert(hu_info,card_type.HUA_PAI)
        end
    end
    if v.tian_hu then--天胡
        table.insert(hu_info,card_type.TIAN_HU)
    elseif v.di_hu then--地胡
        table.insert(hu_info,card_type.DI_HU)
    elseif v.ren_hu then--人胡
        table.insert(hu_info,card_type.REN_HU)
    end
    if v.tian_ting then--天听
        table.insert(hu_info,card_type.TIAN_TING)
    end
    if v.baoting then--报听
        table.insert(hu_info,card_type.BAO_TING)
    end
    if v.qiang_gang_hu then
        table.insert(hu_info,card_type.QIANG_GANG_HU)
    end
    if v.miao_shou_hui_chun then
        table.insert(hu_info,card_type.MIAO_SHOU_HUI_CHUN)
    end
    if v.hai_di_lao_yue then
        table.insert(hu_info,card_type.HAI_DI_LAO_YUE)
    end
    if v.gang_shang_hua then
        table.insert(hu_info,card_type.GANG_SHANG_HUA)
    end
    if v.quan_qiu_ren then
        table.insert(hu_info,card_type.QUAN_QIU_REN)
    elseif v.dan_diao_jiang then
        table.insert(hu_info,card_type.DAN_DIAO_JIANG)
    end
    -- 一般高 --
    local shun_zi_count = {}
    for k1,v1 in pairs(v.pai.ming_pai) do
        if v1[1] ~= v1[2] then
            shun_zi_count[v1[1]] = shun_zi_count[v1[1]] or 0
            shun_zi_count[v1[1]] = shun_zi_count[v1[1]] + 1
        end
    end
    for k1,v1 in pairs(shun_zi_count) do
        if v1 >= 2 then
            table.insert(hu_info,card_type.YI_BAN_GAO)
        end
    end
    -- 一般高 --
    -- 四归一 --
    local si_gui_count = {}
    for k1,v1 in pairs(v.pai.ming_pai) do
        for k2,v2 in pairs(v1) do
            if k2 < 4 then
                si_gui_count[v2] = si_gui_count[v2] or 0 
                si_gui_count[v2] = si_gui_count[v2] + 1
            end
        end
    end
    for k1,v1 in pairs(v.pai.shou_pai) do
        si_gui_count[v1] = si_gui_count[v1] or 0 
        si_gui_count[v1] = si_gui_count[v1] + 1
    end

    for k1,v1 in pairs(si_gui_count) do
        if v1 >= 4 then
            table.insert(hu_info,card_type.SI_GUI_YI)
		end
    end
    -- 四归一 --
    -- 断幺 --
    local duan_yao = true
    for k1,v1 in pairs(v.pai.ming_pai) do
        for k2,v2 in pairs(v1) do
            if k2 < 5 and (v2 == 1 or v2 == 9 or (v2 >= 14 and v2 <= 16)) then
                duan_yao = false
            end
        end
    end
    for k1,v1 in pairs(v.pai.shou_pai) do
        if (v1 == 1 or v1 == 9 or (v1 >= 14 and v1 <= 16)) then
            duan_yao = false
        end
    end
    if duan_yao then
        table.insert(hu_info,card_type.DUAN_YAO)
    end
    -- 断幺 --
    -- 暗杠 --
    local four_an_gang_count = 0
    for k1,v1 in pairs(v.pai.ming_pai) do
        if #v1 > 4 and v1[5] == def.GANG_TYPE.AN_GANG then
            four_an_gang_count = four_an_gang_count + 1
        end
    end
    if four_an_gang_count > 0 then
        for i=1,four_an_gang_count do
            table.insert(hu_info,card_type.ZI_AN_GANG)
        end
    end
    -- 双暗杠 --
    if four_an_gang_count >=2 then 
        table.insert(hu_info,card_type.SHUANG_AN_GANG)
    end
    -- 双暗杠 --
    -- 双明杠 --
    local four_count = 0
    for k1,v1 in pairs(v.pai.ming_pai) do
        if #v1 >= 4 then four_count = four_count + 1 end
    end
    if four_count >=2 then 
        table.insert(hu_info,card_type.SHUANG_MING_GANG)
    end
    -- 双明杠 --
    -- 胡绝张 --
    local jue_count = 0
    for k1,v1 in pairs(self.gongPai) do
        if v1 == v.hu_pai then
            jue_count = 1
            break
        end
    end
    if jue_count == 0 then
        table.insert(hu_info,card_type.HU_JUE_ZHANG)
    end                    
    -- 胡绝张 --
    -- 不求人 --
    if v.zi_mo then
        v.bu_qiu_ren = true
        for k1,v1 in pairs(v.pai.ming_pai) do
            if #v1 < 4 or (#v1 >= 4 and v1[5] ~= def.GANG_TYPE.AN_GANG) then
                v.bu_qiu_ren = false
            end
        end
        if v.bu_qiu_ren then
            table.insert(hu_info,card_type.BU_QIU_REN)
        end
    end
    -- 不求人 --
    if v.zi_mo then
        table.insert(hu_info,card_type.ZI_MO)
    end

    local men_feng_ke = false
    local quan_feng_ke = false
    for k,val in ipairs(v.split_list) do
        if #val == 3 and val[1] == val[2] then
            if val[1] == self.quan_feng then
                quan_feng_ke = true
            end
            if v.chair_id == self.zhuang and val[1] == 10 then
                men_feng_ke = true
            elseif v.chair_id ~= self.zhuang and val[1] == 12 then
                men_feng_ke = true
            end
        end
    end
    if men_feng_ke then--门风刻
        table.insert(hu_info,card_type.MEN_FENG_KE)
    elseif quan_feng_ke then--圈风刻
        table.insert(hu_info,card_type.QUAN_FENG_KE)
    end
   
    local res = mj_util.get_fan_table_res(hu_info)
    v.fan = res.fan
    v.describe = res.describe
    if self:player_finish_task(v) then
        v.fan = v.fan * 2
        v.finish_task = true
    end
    for i=1,v.jiabei do
        v.fan = v.fan * 2
    end
end



return maajan_table

