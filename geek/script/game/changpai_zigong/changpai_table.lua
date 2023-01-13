local base_table = require "game.lobby.base_table"
local def 		= require "game.changpai_zigong.base.define"
local mj_util 	= require "game.changpai_zigong.base.changpai_util"
local log = require "log"
local json = require "json"
local changpai_tile_dealer = require "changpai_tile_dealer"
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
local action_name_str = {  
    [ACTION.PENG] = "Peng", 
    [ACTION.BA_GANG] = "BaGang",
    [ACTION.ZI_MO] = "ZiMo",
    [ACTION.FAN_PAI] = "FanPai",
    [ACTION.CHI] = "Chi",
    [ACTION.TOU] = "Tou",
    [ACTION.TRUSTEE] = "Trustee",
    [ACTION.PASS] = "Pass",
    [ACTION.HU] = "Hu",
    [ACTION.TING] = "Ting",
    [ACTION.CHU_PAI] = "Discard",
    [ACTION.MO_PAI] = "Draw",
    [ACTION.QIANG_GANG_HU] = "QiangGangHu",
    [ACTION.ROUND] = "Round",
    [ACTION.TUO] = "Tuo",
    [ACTION.TIAN_HU] = "TianHu",
    
}
local TIME_TYPE = def.TIME_TYPE
local ACTION_PRIORITY = {
    [ACTION.PASS] = 6,
    [ACTION.PENG] = 4,
    [ACTION.TOU] = 3,
    [ACTION.BA_GANG] = 2,
    [ACTION.TING] = 2,
    [ACTION.HU] = 1,
    [ACTION.ZI_MO] = 1,
    [ACTION.CHI] = 5,
}
local USER_PRIORITY = {
    [1]={[1] = 1,[2] = 2,[3] = 3,[4] = 4 },
    [2]={[2] = 1,[3] = 2,[4] = 3,[1] = 4,},
    [3]={[3] = 1,[4] = 2,[1] = 3,[2] = 4,},
    [4]={[4] = 1,[1] = 2,[2] = 3,[3] = 4 },
}


local SECTION_TYPE = def.SECTION_TYPE
local TILE_AREA = def.TILE_AREA
local HU_TYPE_INFO = def.HU_TYPE_INFO
local HU_TYPE = def.CP_HU_TYPE

local all_tiles_data ={
	[1]={value=2,hong=2,hei=0,index=1},
	[2]={value=3,hong=1,hei=2,index=2},
	[3]={value=4,hong=1,hei=3,index=3},
	[4]={value=4,hong=0,hei=4,index=4},
	[5]={value=5,hong=5,hei=0,index=5},
	[6]={value=5,hong=0,hei=5,index=6},
	[7]={value=6,hong=0,hei=6,index=7},
	[8]={value=6,hong=1,hei=5,index=8},
	[9]={value=6,hong=4,hei=2,index=9},
	[10]={value=7,hong=0,hei=7,index=10},
	[11]={value=7,hong=1,hei=6,index=11},
	[12]={value=7,hong=4,hei=3,index=12},
	[13]={value=8,hong=0,hei=8,index=13},
	[14]={value=8,hong=0,hei=8,index=14},
	[15]={value=8,hong=8,hei=0,index=15},
	[16]={value=9,hong=0,hei=9,index=16},
	[17]={value=9,hong=4,hei=5,index=17},
	[18]={value=10,hong=0,hei=10,index=18},
	[19]={value=10,hong=4,hei=6,index=19},
	[20]={value=11,hong=0,hei=11,index=20},
	[21]={value=12,hong=6,hei=6,index=21}
}
local all_tiles = {
    [1] = {
        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
    }
}

local play_opt_conf = {
    si_ren_liang_fang = {
        start_count = 4,
        tiles = {
            all = {
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
            },
        }
    },
    san_ren_liang_fang = {
        start_count = 3,
        tiles = {
            count = 13,
            all = {
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
            },
        }
    },
    er_ren_san_fang = {
        start_count = 2,
        tiles = {
            count = 13,
            all = {
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
            },
        }
    },
    er_ren_liang_fang = {
        start_count = 2,
        tiles = {
            count = 13,
            all = {
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
                1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
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


local changpai_table = base_table:new()

-- 初始化
function changpai_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
    self.cur_state_FSM = nil
    self.start_count = self.chair_count
    self.hashu = 0
    
end

function changpai_table:on_private_inited()
    
    self.cur_round = nil
    self.zhuang = nil
    self.zhuang_pai = nil
    self.qie_pai = nil
    self.game_tile_count = 15
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
    game_tile_count=15
    self.start_count = start_count--开始人数
    self.tiles = all_tiles[4]     --所有的牌，没啥变化，基本固定死了
    self.game_tile_count = 15     --开局的牌数，也是没啥变化，基本也是固定死
    self.game_tile_count = game_tile_count
    self.cur_state_FSM = nil


end

function changpai_table:on_private_dismissed()
    log.info("changpai_table:on_private_dismissed")
    self.cur_round = nil
    self.zhuang = nil
    self.hashu = 0
    self.zhuang_pai = nil
    self.qie_pai = nil
    self.tiles = nil
    self.cur_state_FSM = nil
    for _,p in pairs(self.players) do
        p.total_money = nil
    end
    self:cancel_all_auto_action_timer()
    self:cancel_clock_timer()
    self:cancel_main_timer()
    base_table.on_private_dismissed(self)
end

function changpai_table:check_start()
    if self:is_play() then
        log.error("changpai_table:check_start is gaming %s",self:id())
        return
    end

    if table.nums(self.ready_list) == self.start_count then
        self:start(self.start_count)
    end
end

function changpai_table:on_started(player_count)
    self.bTest = false
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
            un_usecard = {},
        }
        v.zhuan_shou_pai = nil
        v.jiao                  = nil
        v.is_bao_pai = false  --下家是不是已经真实胡牌了，自摸

        v.bao_pai = false
        v.bao_card = nil
        v.mo_pai = nil
        v.chu_pai = nil
        v.que = nil
        v.first_multi_pao = nil
        v.gzh = nil
        v.gsp = nil
        v.gsc = nil
        v.statistics = v.statistics or {}
        v.last_penghu = nil
        v.tuos = nil
        
    end
    self.zhuang = nil
    self.rec_chu_pai = {}
    self.rec_fan_pai = {}
	self.chu_pai_player_index      =  nil --出牌人的索引
    self.last_chu_pai              = -1 --上次的出牌
    self.mo_pai_count = nil
    self:update_state(FSM_S.PER_BEGIN)
    self.game_log = {
        zhuang = 1,
        start_game_time = os.time(),
        mj_min_scale = self.mj_min_scale,
        players = table.map(self.players,function(_,chair) return chair,{} end),
        action_table = {},
        rule = self.private_id and self.rule or nil,
        club = (self.private_id and self.conf.club) and club_utils.root(self.conf.club).id,
        table_id = self.private_id or nil,
        all_pai = {},
    }

    self.tiles = self.tiles or all_tiles[1]
    self.dealer = nil
    self.dealer = changpai_tile_dealer:new(self.tiles)
    self:cancel_clock_timer()
    self:cancel_main_timer()
    self:cancel_all_auto_action_timer()
    self:pre_begin()--这里是包括定庄，洗牌，发牌，庄家摸第16张牌，给在位置的所有玩家发送牌数据
    ---self:action_after_fapai()
    log.dump("开始游戏了")

        local function auto_fapai()
            self:lockcall(function()
                self:broadcast2client("Changpai_Toupaistate",{status = FSM_S.WAIT_ACTION_AFTER_FIRSTFIRST_TOU_PAI,})
                self:action_after_fapai()
            end)
        end

    self:begin_clock_timer(TIME_TYPE.MAIN_XI_PAI,TIME_TYPE.MAIN_XI_PAI,function ()
        auto_fapai()
    end)--偷牌阶段第一个先偷，假如有时间等待时间，不然下家偷
end
function changpai_table:get_unusecard_list(player)
    local cards = {}
    local count = player.pai and player.pai.un_usecard and player.pai.un_usecard or {}
    for k, v in pairs(count) do
        if v then
            table.insert(cards,k)
        end
    end
    return cards
end
function changpai_table:set_unuse_card(player,tile)

    if player and tile and player.pai then
        player.pai.un_usecard = player.pai.un_usecard or {}
        player.pai.un_usecard[tile] = 1
    end
end
function changpai_table:clear_unuse_card(player)
    player.pai.un_usecard = nil
end
function changpai_table:action_after_fapai()
   
    self:cancel_clock_timer()
    self:update_state(FSM_S.WAIT_ACTION_AFTER_FIRSTFIRST_TOU_PAI)
    local player = self:chu_pai_player()
    local actions = self:get_actions_first_turn(player)
    if table.nums(actions) > 0 then
        self:action_after_tou_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
                session_id = self:session(),
            },
        })
    else
        self:next_player_index() --没有actions 跳到下家
        if(self.chu_pai_player_index==self.zhuang) then
            self:action_after_first_tou()
        else
            self:action_after_fapai()
        end
    end
end
function changpai_table:on_action_after_tianhu(player,msg,auto)
    
    self:cancel_clock_timer()
    local action = self:check_action_before_do(self.waiting_actions,player,msg)
    if not action then 
        log.warning("on_action_after_mo_pai invalid action guid:%s,action:%s",player.guid,msg.action)
        return 
    end
    
   
    local do_action = msg.action
    local chair_id = player.chair_id
    local tile = msg.value_tile

    if chair_id ~= self.chu_pai_player_index then
        log.error("do action:%s but chair_id:%s is not current chair_id:%s after mo_pai",
            do_action,chair_id,self.chu_pai_player_index)
        return
    end

    log.dump(self.waiting_actions,tostring(player.guid))
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
    self:cancel_main_timer()
    self:cancel_auto_action_timer(player)
    self.waiting_actions = {}
    if do_action == ACTION.TIAN_HU then
        -- 天胡
        --local hu = self:hu(player,nil,tile)
        local is_zi_mo = true
        player.hu = {
            time = timer.nanotime(),
            tile = tile,
            types = self:hu(player,nil,tile),
            zi_mo = is_zi_mo,
        }

        player.statistics.hu = (player.statistics.hu or 0) + 1
        
        self:log_game_action(player,do_action,tile,auto)
        self:broadcast_player_hu(player,do_action)
        self:do_balance()
    end
    
    if do_action == ACTION.PASS then
        
        send2client(player,"SC_Changpai_Do_Action",{
            action = do_action,
            chair_id = player.chair_id,
            session_id = msg.session_id,
           
        })

        if self.rule.play.bao_jiao then
            self:foreach(player,function(ps)
                self:baoting()   
            end)
        else
            --这里可能要加一条信息告诉玩家出牌动作
            self:broadcast_discard_turn()
            self:chu_pai()
        end 
        return
    end

    self:done_last_action(player,{action = do_action,tile = tile,})
end
function changpai_table:on_cs_bao_ting(player,msg)
    self:lockcall(function() self:on_baoting(player,msg) end)
end
function changpai_table:on_baoting(player,msg)
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
function changpai_table:baoting()
    self:update_state(FSM_S.WAIT_BAO_TING)
    self:broadcast2client("SC_AllowBaoting",{})

    -- 发送玩家是否能报听，能报听的话，就发可听的牌的数据
    self:foreach(function(p)
        self:send_baoting_tips(p)
    end)
    
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type and (trustee_type == 1 or (trustee_type == 2 and self.cur_round > 1))  then
        local function auto_baoting(p)
            local baoting = 0
            log.info("%d",baoting)
            self:on_baoting(p,{
                baoting = baoting
            })
        end
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
function changpai_table:send_baoting_tips(p)
    local hu_tips = self.rule and self.rule.play.bao_jiao or nil
    if not hu_tips or p.trustee then return end


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
    else
        -- send2client(p,"SC_BaoTingInfos",{
        --     canbaoting = 0,
        --     ting = {}
        -- })
        self:on_baoting(p,{ baoting = 0})
    end
end
function changpai_table:send_baoting_status(player)
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
function changpai_table:action_after_first_tou()--偷牌结束要么天胡，要么出牌
    local player = self:chu_pai_player()

    local mo_pai = self:choice_first_turn_mo_pai(player)


    log.info("---------fake mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})

    local actions = self:get_actions(player,mo_pai,nil,nil,nil)
    log.dump(actions)
    
    if table.nums(actions) > 0 and actions[ACTION.TIAN_HU] then
        log.info("---------you tian  hu------")
        local hu_actions = {[ACTION.TIAN_HU] = actions[ACTION.TIAN_HU]}
        log.dump(hu_actions)
        self:first_action_tianhu({
            [self.chu_pai_player_index] = {
                actions =hu_actions,
                chair_id = self.chu_pai_player_index,
                session_id = self:session(),
            }
        })

    else
        if self.rule.play.bao_jiao then
            self:foreach(player,function(ps)
                self:baoting()
            end)
    
        else
            --这里可能要加一条信息告诉玩家出牌动作
            self:broadcast_discard_turn()
            self:chu_pai()
        end 
    end

end
function changpai_table:fast_start_vote_req(player)
    local player_count = table.sum(self.players,function(p) return 1 end)
    if player_count < 2 then
        send2client(player,"SC_VoteTableReq",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    self:lockcall(function() self:fast_start_vote(player) end)
end

function changpai_table:fast_start_vote_commit(p,msg)
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

function changpai_table:on_reconnect_when_fast_start_vote(player)
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

function changpai_table:fast_start_vote(player)
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

    self:begin_clock_timer(timeout,timeout,function()
        self:foreach(function(p)
            if self.vote_result[p.chair_id] == nil then
                self:fast_start_vote_commit(p,{agree = false})
            end
        end)
    end)
end

function changpai_table:set_trusteeship(player,trustee)
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

function changpai_table:on_offline(player)
	base_table.on_offline(self,player)
    if self.game_log then
	    table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Offline",time = timer.nanotime()})
    end
end

function changpai_table:on_reconnect(player)
	base_table.on_reconnect(self,player)
	if self.game_log then
		table.insert(self.game_log.action_table,{chair = player.chair_id,act = "Reconnect",time = timer.nanotime()})
	end
end

function changpai_table:session()
    self.session_id = (self.session_id or 0) + 1
    return self.session_id
end

function changpai_table:xi_pai()
    self:update_state(FSM_S.XI_PAI)
    self:prepare_tiles()
    self:foreach(function(v)
        self:send_data_to_enter_player(v)
        self.game_log.players[v.chair_id].start_pai = self:tile_count_2_tiles(v.pai.shou_pai)
        
    end)
    local allcards =self.dealer:get_all_left_tiles() or {}
    self.game_log.all_pai = table.values(allcards)
    
    self:broadcast2client("SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
end

function changpai_table:on_reconnect_when_action_qiang_gang_hu(p)
    send2client(p,"SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})

    self:send_ting_tips(p)

    if self.main_timer then
        self:begin_clock(self.main_timer.remainder,self.main_timer.remainder,p)
    end
    
    for chair,actions in pairs(self.qiang_gang_actions or {}) do
        self:send_action_waiting(actions)
    end
end

function changpai_table:on_action_qiang_gang_hu(player,msg,auto)
    self:cancel_main_timer()
    self:cancel_clock_timer()
    if self.cur_state_FSM ~= FSM_S.WAIT_QIANG_GANG_HU then
        log.error("changpai_table:on_action_qiang_gang_hu wrong state %s",self.cur_state_FSM)
        return
    end
    
    local done_action = self:check_action_before_do(self.qiang_gang_actions or {},player,msg)
    if not done_action then 
        log.error("on_action_qiang_gang_hu,no wait qiang gang action,%s",player.guid)
        return
    end

    local tile = msg.value_tile

    self:cancel_all_auto_action_timer()
    

    done_action.done = { action = msg.action,auto = auto }
    local all_done = table.And(self.qiang_gang_actions or {},function(action) return action.done ~= nil end) 
    if not all_done then
        return
    end

    local target_act = done_action.target_action
    local qiang_tile = done_action.tile
    local chu_pai_player = self:chu_pai_player()
    --点击pass 就设置过手胡
    local function check_all_pass(actions)
        for _,act in pairs(actions) do
            if act.done.action == ACTION.PASS then
                local p = self.players[act.chair_id]
                
                    local hu_action = act.actions[ACTION.QIANG_GANG_HU]
                    if hu_action then
                        self:set_gzh_on_pass(p,self:hu_fan(p,qiang_tile))
                    end
                
            end
        end
    end


    local all_pass = table.And(self.qiang_gang_actions or {},function(action) return action.done.action == ACTION.PASS end)
    if all_pass then
        check_all_pass(self.qiang_gang_actions)
        self.qiang_gang_actions = nil
        self:adjust_shou_pai(chu_pai_player,target_act,qiang_tile)
        chu_pai_player.statistics.ming_gang = (chu_pai_player.statistics.ming_gang or 0) + 1
        
        self:log_game_action(chu_pai_player,target_act,qiang_tile)
        self:done_last_action(chu_pai_player,{action = target_act,tile = qiang_tile})
        self:mo_pai()
        return
    end

    self:log_failed_game_action(chu_pai_player,target_act,tile)
    local qiang_hu_count = table.sum(self.qiang_gang_actions or {},function(waiting)
        return (waiting.done and waiting.done.action & (ACTION.QIANG_GANG_HU | ACTION.HU)) and 1 or 0
    end)
    local hu_count_before = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    chu_pai_player.first_multi_pao = (hu_count_before == 0 and qiang_hu_count > 1) or nil
    local qianggangdecr = true 
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

        log.dump(p)
        self:broadcast_players_tuos(player,done_action_tile)
        self:log_game_action(p,act,done_action_tile,action.done.auto)
        self:broadcast_player_hu(p,act,action.target)
        p.statistics.hu = (p.statistics.hu or 0) + 1
        
        chu_pai_player.statistics.dian_pao = (chu_pai_player.statistics.dian_pao or 0) + 1
        if  qianggangdecr then 
            table.decr(chu_pai_player.pai.shou_pai,done_action_tile)
            qianggangdecr = false 
        end 
        self:done_last_action(p,{action = act,tile = done_action_tile})
    end
    check_all_pass(self.qiang_gang_actions)
    table.foreach(self.qiang_gang_actions or {},function(action,chair)
        local done_act = action.done.action
        if (done_act & (ACTION.QIANG_GANG_HU | ACTION.HU)) > 0 then
            local p = self.players[chair]
            do_qiang_gang_hu(p,action)
        end
    end)

    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    if hu_count>0 then
        self:do_balance(tile)
        return
    end

    --local _,last_hu_chair = table.max(self.qiang_gang_actions or {},function(_,c) return c end)
    --local last_hu_player = self.players[last_hu_chair]
    --self:next_player_index(last_hu_player)
    --self:mo_pai()
end

function changpai_table:qiang_gang_hu(player,actions,tile)
    self:update_state(FSM_S.WAIT_QIANG_GANG_HU)
    self.qiang_gang_actions = actions
    for chair,action in pairs(actions) do
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
                    value_tile = tile,
                    session_id = action.session_id,
                })
            end)
        end

        self:begin_main_timer(trustee_seconds,trustee_seconds,function()
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


function changpai_table:begin_auto_action_timer(p_or_chair,timeout,fn)
    local chair_id = type(p_or_chair) == "table" and p_or_chair.chair_id or p_or_chair
    if self.action_timers[chair_id] then
        log.warning("changpai_table:begin_auto_action_timer timer not nil")
    end
    self.action_timers[chair_id] = self:calllater(timeout,fn)
end

function changpai_table:cancel_auto_action_timer(p_or_chair)
    self.action_timers = self.action_timers or {} 
    local chair_id = type(p_or_chair) == "table" and p_or_chair.chair_id or p_or_chair
    if self.action_timers[chair_id] then
        self.action_timers[chair_id]:kill()
        self.action_timers[chair_id] = nil
    end
end

function changpai_table:cancel_all_auto_action_timer()
    for _,timer in pairs(self.action_timers or {}) do
        timer:kill()
    end
    self.action_timers = {}
end

function changpai_table:begin_main_timer(timeout,totaltime,fn)
    if self.main_timer then 
        log.warning("changpai_table:begin_main_timer timer not nil")
        self.main_timer:kill()
    end

    self.main_timer = self:new_timer(timeout,fn)
    self:begin_clock(timeout,nil,totaltime)

    log.info("changpai_table:begin_main_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.main_timer.id,timeout)
end
function changpai_table:cancel_main_timer()
    log.info("changpai_table:cancel_main_timer table_id:%s,timer:%s",self.table_id_,self.main_timer and self.main_timer.id or nil)
    if self.main_timer then
        self.main_timer:kill()
        self.main_timer = nil
    end
end
function changpai_table:begin_clock_timer(timeout,totaltime,fn)
    if self.clock_timer then 
        log.warning("changpai_table:begin_clock_timer timer not nil")
        self.clock_timer:kill()
    end

    self.clock_timer = self:new_timer(timeout,fn)
    self:begin_clock(timeout,nil,totaltime)

    log.info("changpai_table:begin_clock_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.clock_timer.id,timeout)
end

function changpai_table:cancel_clock_timer()
    log.info("changpai_table:cancel_clock_timer table_id:%s,timer:%s",self.table_id_,self.clock_timer and self.clock_timer.id or nil)
    if self.clock_timer then
        self.clock_timer:kill()
        self.clock_timer = nil
    end
end
function changpai_table:broadcast_players_tuos(player,in_pai)
    local tuonum = {}
        for chair, p in pairs(self.players) do
            if chair==player.chair_id  then
                
                tuonum[p.chair_id] = mj_util.tuos(p.pai,in_pai,nil,nil)
                p.tuos = tuonum[p.chair_id]
                log.dump(tuonum[p.chair_id])
            else
                tuonum[p.chair_id] = mj_util.ming_tuos(p.pai)
            end
        
        end
    send2client(player,"SC_CP_Tuo_Num",{
        tuos = tuonum
    })
    self:foreach_except(player,function(ps)

        for chair, p in pairs(self.players) do
            if chair==ps.chair_id  then
                tuonum[p.chair_id] = mj_util.tuos(p.pai,nil,nil,nil)
            else
                tuonum[p.chair_id] = mj_util.ming_tuos(p.pai)
            end
        
        end
        send2client(ps,"SC_CP_Tuo_Num",{
            tuos = tuonum
        })
    end)
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = "Tuo",msg = {tuos = tuonum}})
end
function changpai_table:on_action_after_mo_pai(player,msg,auto)
    
    self:cancel_clock_timer()
    local action = self:check_action_before_do(self.waiting_actions,player,msg)
    if not action then 
        log.warning("on_action_after_mo_pai invalid action guid:%s,action:%s",player.guid,msg.action)
        return 
    end


    local do_action = msg.action
    local chair_id = player.chair_id
    local tile = msg.value_tile

    if chair_id ~= self.chu_pai_player_index then
        log.error("do action:%s but chair_id:%s is not current chair_id:%s after mo_pai",
            do_action,chair_id,self.chu_pai_player_index)
        return
    end

    log.dump(self.waiting_actions,tostring(player.guid))
    local player = self:chu_pai_player()
    if not player then
        log.error("do action %s,but wrong player in chair %s",do_action,player.chair_id)
        return
    end
    self:cancel_auto_action_timer(self.players[self.chu_pai_player_index])
    self:cancel_main_timer()
    local waiting = self.waiting_actions[player.chair_id]

    local session_id = waiting.session_id

    local player_actions = self.waiting_actions[player.chair_id].actions
    if not player_actions[do_action] and do_action ~= ACTION.PASS and do_action ~= ACTION.CHU_PAI then
        log.error("do action %s,but action is illigle,%s",do_action)
        return
    end

    self.waiting_actions = {}

    if (do_action & ACTION.BA_GANG) > 0 then
        local qiang_gang_hu = {}
        self:foreach_except(player,function(p)
            if p.hu then return end

            local actions = self:get_actions(p,nil,tile,true,nil)
            if not actions[ACTION.HU] then return end

            qiang_gang_hu[p.chair_id] = {
                chair_id = p.chair_id,
                target = chair_id,
                target_action = do_action,
                tile = tile,
                actions = {
                    [ACTION.QIANG_GANG_HU] = actions[ACTION.HU]
                },
                session_id = self:session(),
            }
        end)
 
        if table.nums(qiang_gang_hu) > 0 then
            send2client(player,"SC_Changpai_Do_Action_Commit",{
                action = do_action,
                chair_id = player.chair_id,
                session_id = msg.session_id,
            })
            
            self:qiang_gang_hu(player,qiang_gang_hu,tile)
            
            return
        end
        

        self:log_game_action(player,do_action,tile,auto)
        self:adjust_shou_pai(player,do_action,tile,session_id)
        self:clean_gzh(player)
        self:broadcast_players_tuos(player)
        
        self:jump_to_player_index(player)
        player.statistics.ming_gang = (player.statistics.ming_gang or 0) + 1
        
        self:mo_pai()
        
    end
    if do_action == ACTION.TOU then
        self:clean_gzh(player)
        self:adjust_shou_pai(player,do_action,tile,session_id)
        self:log_game_action(player,do_action,tile,auto)
        self:broadcast_players_tuos(player)
        
        self:mo_pai()
        
    end


    if do_action == ACTION.HU  then
        local is_zi_mo = true
        player.hu = {
            time = timer.nanotime(),
            tile = tile,
            types = self:hu(player,nil,player.mo_pai),
            zi_mo = is_zi_mo,  
        }

        log.dump(player)
        self:broadcast_players_tuos(player)
        
        player.statistics.hu = (player.statistics.hu or 0) + 1
        
        self:log_game_action(player,do_action,tile,auto)
        self:broadcast_player_hu(player,do_action)
        local hu_count  = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
        if  hu_count  > 0 then
            self:do_balance()
        end
    end

    if do_action == ACTION.PASS then
        
        send2client(player,"SC_Changpai_Do_Action",{
            action = do_action,
            chair_id = player.chair_id,
            session_id = msg.session_id,
            
        })
        self:broadcast_discard_turn()
        self:chu_pai()
        return
    end

    self:done_last_action(player,{action = do_action,tile = tile,})
end
function changpai_table:on_reconnect_when_action_after_fan_pai(p)
    send2client(p,"SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})

    local action =self.waiting_actions and self.waiting_actions[p.chair_id] or nil
    if action and not action.done then
        self:send_action_waiting(action)
    end

end
function changpai_table:on_reconnect_when_action_after_mo_pai(p)
    send2client(p,"SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
    local action =self.waiting_actions and self.waiting_actions[p.chair_id] or nil
    if action and not action.done then
        self:send_action_waiting(action)
    end

end
--偷牌摆牌进牌后，产生的事件，以及通知玩家事件等待响应，已经托管玩家的自动响应机制
function changpai_table:action_after_tou_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_FIRSTFIRST_TOU_PAI)
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
            local act = action.actions[ACTION.HU] and ACTION.HU or ACTION.PASS
            local tile = p.mo_pai
            self:lockcall(function()
                self:on_action_after_first_tou_pai(p,{
                    action = act,
                    value_tile = tile,
                    chair_id = p.chair_id,
                    session_id = action.session_id,
                },true)
            end)
        end

        self:begin_main_timer(trustee_seconds,trustee_seconds,function()
            log.dump(self.waiting_actions)
            table.foreach(self.waiting_actions,function(action,_)
                if action.done then return end
                log.dump(action)
                local p = self.players[action.chair_id]
                log.dump(p)
                log.dump(self.players)
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

function changpai_table:action_after_fan_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_FAN_PAI)
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
    log.dump(trustee_type,trustee_seconds)
    log.dump(self.waiting_actions)
    if trustee_type then
        local function auto_action(p,action)
           
            local act = action.actions[ACTION.HU] and ACTION.HU or ACTION.PASS
            
            local nest_user = 1
            local all_actions = self.waiting_actions
            
            if self.chu_pai_player_index+1 > self.start_count then
                nest_user = (self.chu_pai_player_index+1 ) %  self.start_count
            else
                nest_user = (self.chu_pai_player_index+1 )
            end
            local chu_player =  self:chu_pai_player()
            local tile = chu_player.fan_pai
            local other = nil
            local is_bao = false
            log.dump(self:is_bao_pai(p,chu_player.fan_pai))
            log.dump(chu_player.fan_pai)
            if nest_user == p.chair_id and chu_player and chu_player.fan_pai and self:is_bao_pai(p,chu_player.fan_pai) then
                
                log.dump(all_actions)
                for _,acx in pairs(all_actions) do
                    if acx then 
                        if  acx.chair_id ==self.chu_pai_player_index   then     
                            local chi_action = acx.actions[ACTION.CHI]
                            log.dump(chi_action)
                                if chi_action then
                                    
                                    is_bao =true 
                                    break
                                end
                            
                                    
                        end
                    end
                    
                end
                log.dump(is_bao)
                if is_bao then
                    for _,acx in pairs(all_actions) do
                        log.dump(acx.actions[ACTION.CHI] )
                        if acx.chair_id == nest_user and  acx.actions[ACTION.CHI] then
                            for i, ac in pairs(acx.actions[ACTION.CHI]) do
                                log.dump(i )
                                log.dump(act )
                                if act == ACTION.PASS then
                                    other = i
                                    act = action.actions[ACTION.CHI] and ACTION.CHI or ACTION.PASS
                                end
                                
                            end 
                        end
                       
                    end
                end
                
            end

            self:lockcall(function()
                self:on_action_after_fan_pai(p,{
                    action = act,
                    value_tile = tile,
                    other_tile = other ,
                    chair_id = p.chair_id,
                    session_id = action.session_id,
                    is_sure = true
                },true)
            end)
        end

        self:begin_main_timer(trustee_seconds,trustee_seconds,function()
            log.dump(self.waiting_actions)
            table.foreach(self.waiting_actions,function(action,_)
                if action.done then return end
                log.dump(action)
                local p = self.players[action.chair_id]
                self:set_trusteeship(p,true)
                auto_action(p,action)
            end)
        end)

        table.foreach(self.waiting_actions,function(action,_) 

            local p = self.players[action.chair_id]
            log.dump(self.waiting_actions,p.chair_id)
            if not p.trustee then return end

            self:begin_auto_action_timer(p,math.random(1,2),function() 
                auto_action(p,action)
            end)
        end)
    end
end
function changpai_table:first_action_tianhu(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_TIAN_HU)
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
            local act = action.actions[ACTION.TIAN_HU] and ACTION.TIAN_HU or ACTION.PASS
            local tile = p.mo_pai
            self:lockcall(function()
                self:on_action_after_tianhu(p,{
                    action = act,
                    value_tile = tile,
                    chair_id = p.chair_id,
                    session_id = action.session_id,
                },true)
            end)
        end

        self:begin_main_timer(trustee_seconds,trustee_seconds,function()
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
--摸牌后产生的事件，发送给玩家，以及托管玩家的自动响应机制
function changpai_table:action_after_mo_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_JIN_PAI)
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
            local act = action.actions[ACTION.HU] and ACTION.HU or ACTION.PASS
            local tile = p.mo_pai
            self:lockcall(function()
                self:on_action_after_mo_pai(p,{
                    action = act,
                    value_tile = tile,
                    chair_id = p.chair_id,
                    session_id = action.session_id,
                },true)
            end)
        end

        self:begin_main_timer(trustee_seconds,trustee_seconds,function()
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

function changpai_table:choice_first_turn_mo_pai(player)
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
function changpai_table:on_reconnect_when_tian_hu(p)
    send2client(p,"SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client(p,"SC_Changpai_Discard_Round",{chair_id = self.chu_pai_player_index})
    local action = self.waiting_actions[p.chair_id]
    if action and not action.done then
        self:send_action_waiting(action)
    end
    if self.main_timer then
        self:begin_clock(self.main_timer.remainder,p)
    end
end
function changpai_table:on_reconnect_when_first_tou_pai(p)
    send2client(p,"SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
    local action = self.waiting_actions[p.chair_id]
    if action and not action.done then
        self:send_action_waiting(action)
    end
    if self.main_timer then
        self:begin_clock(self.main_timer.remainder,p)
    end
end

function changpai_table:on_reconnect_when_action_after_chu_pai(p)
    send2client(p,"SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
    local action = self.waiting_actions and self.waiting_actions[p.chair_id] or nil 
    if action and not action.done then
        self:send_action_waiting(action)
    end
end
function changpai_table:set_palyer_bao_pai(allactions,player)
    
 
    local nest_user = 1
    if player and player.chair_id-1 < 1 then
        nest_user =  self.start_count
    else
        nest_user = player and player.chair_id-1 
    end
    local lastuser = self.players[nest_user]
    log.dump(lastuser)
    log.dump(self.chu_pai_player_index)
    log.dump(allactions)
    log.dump(lastuser.chair_id)
    if not allactions[lastuser.chair_id]  then
        return false
    end
    if not allactions[lastuser.chair_id].actions   then
        return false
    end
    if  not allactions[lastuser.chair_id].actions[ACTION.CHI] then
        return false
    end
    if lastuser and  nest_user == self.chu_pai_player_index and self:is_bao_pai(player,lastuser.fan_pai) then
        
        if player and  allactions[player.chair_id] then
            self:send_action_waiting(allactions[player.chair_id])
        end
        return true
    end
    
    return false

end
function changpai_table:on_action_after_fan_pai(player,msg,auto)

    log.dump(player)
    log.dump(msg)
    
    self:cancel_clock_timer()
    if player then self:cancel_auto_action_timer(player) end
    if not self.waiting_actions  or table.nums(self.waiting_actions) == 0 then
        log.error("changpai_table:on_action_after_chu_pai not waiting actions,%s",player.guid)
        return
    end
    local fan_tile = msg.value_tile
    local chu_pai_player = self:chu_pai_player()

    if msg.action ==ACTION.PASS and self.chu_pai_player_index ~=player.chair_id then
       if self:set_palyer_bao_pai(self.waiting_actions,player) then return end
    end

    if msg.action ==ACTION.PASS and self.chu_pai_player_index ==player.chair_id and not msg.is_sure then

        
        --包牌判断，假如对下家形成包牌，就返回存在包牌风险提醒，假如下家已经是包牌，那不管
        local nest_user = 1
        if self.chu_pai_player_index+1 > self.start_count then
            nest_user = (self.chu_pai_player_index+1 ) %  self.start_count
        else
            nest_user = (self.chu_pai_player_index+1 )
        end
        local user = self.players[nest_user]
        if self:is_bao_pai(user,chu_pai_player.fan_pai) and not msg.is_sure then
                
            send2client(player,"SC_CP_Canbe_Baopai",{
                tile = chu_pai_player.fan_pai,
                number = 2
            })
            return
        end
    end

    local action = self:check_action_before_do(self.waiting_actions,player,msg)
    if action then
        local done_action = msg.action
        action.done = {
            action = done_action,
            tile = msg.value_tile,
            other_tile = msg.other_tile,
            auto = auto,
        }
        local chair = action.chair_id
        
        if done_action == ACTION.PASS then
            
            send2client(player,"SC_Changpai_Do_Action",{
                action = done_action,
                chair_id = player.chair_id,
                session_id = msg.session_id,
               
            })
        end
    end

    local all_notdone = {}
    log.dump(self.waiting_actions)
    local userpri = USER_PRIORITY[self.chu_pai_player_index]
    for k, v in pairs(self.waiting_actions) do
        for i, act in pairs(v.actions) do
            if act then
                table.insert(all_notdone,{ac=i,chairid=v.chair_id})
            end
           
        end
    end
    table.sort(all_notdone,function(l,r)
        return ACTION_PRIORITY[l.ac] < ACTION_PRIORITY[r.ac]
    end)
    table.sort(all_notdone,function(l,r)
        if  ACTION_PRIORITY[l.ac] == ACTION_PRIORITY[r.ac] then
            return userpri[l.chairid] < userpri[r.chairid]
        end
        return ACTION_PRIORITY[l.ac] < ACTION_PRIORITY[r.ac]
    end)
    log.dump(all_notdone)
    if all_notdone and  all_notdone[1].ac == msg.action and all_notdone[1].chairid==player.chair_id then
        
    else
        if not table.And(self.waiting_actions,function(action) return action.done ~= nil end) then
            send2client(player,"SC_Changpai_Do_Action_Commit",{
                action = msg.action,
                chair_id = player.chair_id,
                session_id = msg.session_id,
            })
            return
        end
    end

    
    local all_actions = table.series(self.waiting_actions,function(action)
        return action.done ~= nil and action or nil
    end)


    self.waiting_actions = nil
    -------- 提前结束的时候其它定时器要消掉
    self:cancel_all_auto_action_timer()
    self:cancel_main_timer()

    table.sort(all_actions,function(l,r)
        return ACTION_PRIORITY[l.done.action] < ACTION_PRIORITY[r.done.action]
    end)
    table.sort(all_actions,function(l,r)
        if  ACTION_PRIORITY[l.done.action] == ACTION_PRIORITY[r.done.action] then
            return userpri[l.chair_id] < userpri[r.chair_id]
        end
        return ACTION_PRIORITY[l.done.action] < ACTION_PRIORITY[r.done.action]
    end)
    
   
    local top_action = all_actions[1]
    local top_session_id = top_action.session_id
    local top_done_act = top_action.done.action
   
    local player = self.players[top_action.chair_id]
    if not player then
        log.error("do action %s,nil player in chair %s",top_action.done.action,top_action.chair_id)
        return
    end
    log.dump(all_actions,"on_action_after_chu_pai"..player.guid)

   

    local function check_all_pass(actions)
        for _,act in pairs(actions) do
            if act.done.action == ACTION.PASS then
                local p = self.players[act.chair_id]
               
                    local hu_action = act.actions[ACTION.HU]
                    if hu_action then
                        self:set_gzh_on_pass(p,self:hu_fan(p,chu_pai_player.fan_pai))
                    end                
               
                    local peng_action = act.actions[ACTION.PENG]
                    if peng_action then
                        self:set_gsp_on_pass(p,chu_pai_player.fan_pai)
                    end

                    local tou_action = act.actions[ACTION.TOU]
                    if tou_action then
                        self:set_gst_on_pass(p,chu_pai_player.fan_pai)
                    end
                    
                    local chi_action = act.actions[ACTION.CHI]
                    if chi_action then
                        self:set_gsc_on_pass(p,chu_pai_player.fan_pai)
                    end
                
            end
        end
    end
    
    local tile = top_action.done.tile
    local othertile = top_action.done.other_tile
    if top_done_act == ACTION.CHI then  
        
        local nest_user = 1
        if self.chu_pai_player_index+1 > self.start_count then
            nest_user = (self.chu_pai_player_index+1 ) %  self.start_count
        else
            nest_user = (self.chu_pai_player_index+1 )
        end
        local chu_player =  self:chu_pai_player()
   
        if nest_user == player.chair_id and chu_player and chu_player.fan_pai and self:is_bao_pai(player,chu_player.fan_pai) then
            
            
            for _,act in pairs(all_actions) do
                if act.done.action == ACTION.PASS and act.chair_id ==self.chu_pai_player_index and not chu_player.bao_card then     
                    local chi_action = act.actions[ACTION.CHI]
                   
                    if chi_action then
                        chu_player.bao_pai = true  
                        chu_player.bao_card = chu_player.fan_pai
                    end 
                               
                end
            end
            
        end
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,othertile,top_session_id)
        --log.error("---------adjust_shou_pai--------")
        --self:log_game_action(player,top_done_act,tile,top_action.done.auto)
        tinsert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[top_done_act],msg = {tile = tile,other_tile = othertile },auto = auto,time = timer.nanotime()})
        check_all_pass(all_actions)
        


        


        self:jump_to_player_index(player)
        self:broadcast_players_tuos(player)
        self:broadcast_discard_turn()
        self:chu_pai()

    end

    if top_done_act == ACTION.PENG then
        self:clean_gzh(player)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,top_session_id)
        self:log_game_action(player,top_done_act,tile,top_action.done.auto)
        check_all_pass(all_actions)
        self:broadcast_players_tuos(player)
        self:jump_to_player_index(player)
        self:mo_pai()
    end
    if top_done_act == ACTION.TOU then
        self:clean_gzh(player)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,top_session_id)
        self:log_game_action(player,top_done_act,tile,top_action.done.auto)
        check_all_pass(all_actions)
        self:broadcast_players_tuos(player)
        self:mo_pai()
    end
    if def.is_action_gang(top_done_act) then
        self:clean_gzh(player)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,top_session_id)
        self:log_game_action(player,top_done_act,tile,top_action.done.auto)
        check_all_pass(all_actions)
        self:jump_to_player_index(player)
        self:mo_pai()
        player.statistics.ming_gang = (player.statistics.ming_gang or 0) + 1
    end

    if top_done_act == ACTION.HU then

        local p = player
        p.hu = {
            time = timer.nanotime(),
            tile = chu_pai_player.fan_pai,
            types = self:hu(p,tile),
            zi_mo = true,
            whoee = nil,
        }

        log.dump(p.pai.shou_pai)
        -----------------------------
        self:broadcast_players_tuos(player,chu_pai_player.fan_pai)
        -------------------------------

        self:log_game_action(p,top_done_act,tile,top_action.done.auto)
        self:broadcast_player_hu(p,top_done_act,top_session_id)
        p.statistics.hu = (p.statistics.hu or 0) + 1
       
        

        table.pop_back(chu_pai_player.pai.desk_tiles)

        check_all_pass(all_actions)

        local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
        if  hu_count > 0 then
            self:do_balance(tile)
        end
    end

    if top_done_act == ACTION.PASS then

        check_all_pass(all_actions)
        self:next_player_index()
        --self:fan_pai()
        
        local function auto_fanpai()
            self:lockcall(function()
                self:fan_pai()
            end)
        end
        self:begin_clock_timer(TIME_TYPE.MAIN_FAN_PAI,TIME_TYPE.MAIN_FAN_PAI,function ()
            auto_fanpai()
        end)
        return
    end

    self:done_last_action(player,{action = top_done_act,tile = tile})
end
function changpai_table:on_action_after_chu_pai(player,msg,auto)
    
    self:cancel_clock_timer()
    if not self.waiting_actions then
        log.error("changpai_table:on_action_after_chu_pai not waiting actions,%s",player.guid)
        return
    end

    local nest_user = 1
    if self.chu_pai_player_index+1 > self.start_count then
        nest_user = (self.chu_pai_player_index+1 ) %  self.start_count
    else
        nest_user = (self.chu_pai_player_index+1 )
    end
    local chu_pai_player = self:chu_pai_player()
    local allactions = self.waiting_actions
    log.dump(msg)
    log.dump(allactions)
    log.dump(self:is_bao_pai(player,chu_pai_player.chu_pai))
    if msg.action ==ACTION.PASS and nest_user ==player.chair_id then
        if self:is_bao_pai(player,chu_pai_player.chu_pai) and allactions[player.chair_id] and  allactions[player.chair_id].actions[ACTION.CHI] then 
            self:send_action_waiting(allactions[player.chair_id])
            return 
        end
     end

    local action = self:check_action_before_do(self.waiting_actions,player,msg)
    log.dump(action)
    if action then
        local done_action = msg.action
        action.done = {
            action = done_action,
            tile = msg.value_tile,
            othertile =msg.other_tile,
            auto = auto,
        }
        local chair = action.chair_id
        self:cancel_auto_action_timer(self.players[chair])

        if done_action == ACTION.PASS then
             
            send2client(player,"SC_Changpai_Do_Action",{
                action = done_action,
                chair_id = player.chair_id,
                session_id = msg.session_id,
                
            })
        end
    end
   


    local all_notdone = {}
    local userpri = USER_PRIORITY[self.chu_pai_player_index]
    for k, v in pairs(self.waiting_actions) do
        for i, act in pairs(v.actions) do
            if act then
                table.insert(all_notdone,{ac=i,chairid=v.chair_id})
            end
           
        end
    end
    table.sort(all_notdone,function(l,r)
            if  ACTION_PRIORITY[l.ac] == ACTION_PRIORITY[r.ac] then
                return userpri[l.chairid] < userpri[r.chairid]
            else
                return ACTION_PRIORITY[l.ac] < ACTION_PRIORITY[r.ac]
            end
    end)

    if all_notdone[1].ac == msg.action and all_notdone[1].chairid==player.chair_id then

    else
        if not table.And(self.waiting_actions,function(action) return action.done ~= nil end) then
            send2client(player,"SC_Changpai_Do_Action_Commit",{
                action = msg.action,
                chair_id = player.chair_id,
                session_id = msg.session_id,
            })
            return
        end
    end
    
    -------- 提前结束的时候其它定时器要消掉
    self:cancel_all_auto_action_timer()
    self:cancel_main_timer()
    --所有已经操作的 acitons
    local all_actions = table.series(self.waiting_actions,function(action)
        return action.done ~= nil and action or nil
    end)

    self.waiting_actions = nil

    
    table.sort(all_actions,function(l,r)
        return ACTION_PRIORITY[l.done.action] < ACTION_PRIORITY[r.done.action]
    end)
    table.sort(all_actions,function(l,r)
        if  ACTION_PRIORITY[l.done.action] == ACTION_PRIORITY[r.done.action] then
            return userpri[l.chair_id] < userpri[r.chair_id]
        end
        return ACTION_PRIORITY[l.done.action] < ACTION_PRIORITY[r.done.action]
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
    --当玩家按下pass 的时候，要判断这个玩家是否设置成为过庄胡，或者过手碰
    log.dump(all_actions,"on_action_after_chu_pai"..player.guid)
    local function check_all_pass(actions)
        for _,act in pairs(actions) do
            if act.done.action == ACTION.PASS then
                local p = self.players[act.chair_id]
                
                    local hu_action = act.actions[ACTION.HU]
                    if hu_action then
                        self:set_gzh_on_pass(p,self:hu_fan(p,chu_pai_player.chu_pai))
                        
                    end
 
    
                
                    local peng_action = act.actions[ACTION.PENG]
                    if peng_action then
                        self:set_gsp_on_pass(p,chu_pai_player.chu_pai)
                        
                    end
               
                
                    local chi_action = act.actions[ACTION.CHI]
                    if chi_action then
                        self:set_gsc_on_pass(p,chu_pai_player.chu_pai)
                        
                    end
               
            end
        end
    end

    log.dump(top_action)
    log.dump(msg)
    local tile = top_action.done.tile
    local othertile = top_action.done.othertile
    if top_done_act == ACTION.CHI then
        
        

        local nest_user = 1
        if self.chu_pai_player_index+1 > self.start_count then
            nest_user = (self.chu_pai_player_index+1 ) %  self.start_count
        else
            nest_user = (self.chu_pai_player_index+1 )
        end
        if nest_user == player.chair_id and self:is_bao_pai(player,chu_pai_player.chu_pai) and not chu_pai_player.bao_card then
            chu_pai_player.bao_pai = true   
            chu_pai_player.bao_card = chu_pai_player.chu_pai or nil
        end
        log.dump(chu_pai_player.bao_pai)
        log.dump(chu_pai_player.bao_card)

        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,othertile,top_session_id)
        --self:log_game_action(player,top_done_act,tile,top_action.done.auto)
        tinsert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[top_done_act],msg = {tile = tile,other_tile = othertile },auto = auto,time = timer.nanotime()})
        check_all_pass(all_actions)

        self:broadcast_players_tuos(player)
        self:jump_to_player_index(player)
        self:broadcast_discard_turn()
        self:chu_pai()
    end

    if top_done_act == ACTION.PENG then
        self:clean_gzh(player)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,top_session_id)
        self:log_game_action(player,top_done_act,tile,top_action.done.auto)
        check_all_pass(all_actions)
        self:broadcast_players_tuos(player)
        self:jump_to_player_index(player)
        self:mo_pai()
    end
    if top_done_act == ACTION.TOU then
        self:clean_gzh(player)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,top_session_id)
        self:log_game_action(player,top_done_act,tile,top_action.done.auto)
        check_all_pass(all_actions)
        self:broadcast_players_tuos(player)
        self:mo_pai()
    end
    if def.is_action_gang(top_done_act) then
        self:clean_gzh(player)
        table.pop_back(chu_pai_player.pai.desk_tiles)
        self:adjust_shou_pai(player,top_done_act,tile,top_session_id)
        self:log_game_action(player,top_done_act,tile,top_action.done.auto)
        check_all_pass(all_actions)
        self:broadcast_players_tuos(player)
        self:jump_to_player_index(player)
        self:mo_pai()
        player.statistics.ming_gang = (player.statistics.ming_gang or 0) + 1
    end

    if top_done_act == ACTION.HU then

        local p = player
        p.hu = {
            time = timer.nanotime(),
            tile = chu_pai_player.chu_pai or nil,
            types = self:hu(p,chu_pai_player.chu_pai),
            zi_mo = false,
            whoee = self.chu_pai_player_index,
        }
        player.statistics.hu = (player.statistics.hu or 0) + 1
        chu_pai_player.statistics.dian_pao = (chu_pai_player.statistics.dian_pao or 0) + 1
        
        log.dump(p.pai.shou_pai)
        self:broadcast_players_tuos(player,chu_pai_player.chu_pai)
        self:log_game_action(p,top_done_act,tile,top_action.done.auto)
        self:broadcast_player_hu(p,top_done_act,top_session_id)
        

        table.pop_back(chu_pai_player.pai.desk_tiles)

        check_all_pass(all_actions)
        local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
        if hu_count > 0 then
            self:do_balance(tile)
        end
    end

    if top_done_act == ACTION.PASS then
        check_all_pass(all_actions)
        self:next_player_index()
        
        local function auto_fanpai()
            self:lockcall(function()
                self:fan_pai()
            end)
        end
        self:begin_clock_timer(TIME_TYPE.MAIN_FAN_PAI,TIME_TYPE.MAIN_FAN_PAI,function ()
            auto_fanpai()
        end)
        --self:fan_pai()
        return
    end

    self:done_last_action(player,{action = top_done_act,tile = tile})
end

function changpai_table:action_after_chu_pai(waiting_actions)
    self:update_state(FSM_S.WAIT_ACTION_AFTER_CHU_PAI)
    self.waiting_actions = waiting_actions
    log.dump(self.waiting_actions)
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
            --形成包牌就必须吃了
            local all_actions = self.waiting_actions
            local tile = self:chu_pai_player().chu_pai
            local nest_user = 1
            local other = nil
            if self.chu_pai_player_index+1 > self.start_count then
                nest_user = (self.chu_pai_player_index+1 ) %  self.start_count
            else
                nest_user = (self.chu_pai_player_index+1 )
            end
            local chu_player =  self:chu_pai_player()
            if nest_user == p.chair_id and chu_player and chu_player.chu_pai and self:is_bao_pai(p,chu_player.chu_pai) then
                for _,playeraction in pairs(all_actions) do
                    log.dump(playeraction.actions[ACTION.CHI] )
                    if playeraction.chair_id == nest_user and  playeraction.actions[ACTION.CHI] then
                        for i, ac in pairs(playeraction.actions[ACTION.CHI]) do
                            log.dump(i )
                            log.dump(act )
                            if act == ACTION.PASS and ac then
                                other = i
                                act = action.actions[ACTION.CHI] and ACTION.CHI or ACTION.PASS
                                break
                            end
                            
                        end 
                    end
                   
                end                   
            end
            
        
            self:lockcall(function()
                self:on_action_after_chu_pai(p,{
                    action = act,
                    value_tile = tile,
                    other_tile = other,
                    session_id = action.session_id,
                },true)
            end)
        end

        self:begin_main_timer(trustee_seconds,trustee_seconds,function()
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

function changpai_table:fake_mo_pai()
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai

    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 5 then
        self.hashu = self.zhuang
        self:do_balance()
        return
    end

    local mo_pai
    if table.nums(self.pre_gong_tiles or {}) > 0 then
        for i,tile in pairs(self.pre_gong_tiles) do
            if self.bTest then
                mo_pai = tile
                self.dealer.remain_count = self.dealer.remain_count -1
            else
                mo_pai = self.dealer:deal_one_on(function(t) return t == tile end)
            end
            self.pre_gong_tiles[i] = nil
            break
        end
    else
        mo_pai = self.dealer:deal_one()
    end

    table.incr(shou_pai,mo_pai)
    player.mo_pai = mo_pai

    player.gzh = nil
    player.gsp = nil
    player.gsc = nil
    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    player.mo_pai_count = (player.mo_pai_count or 0) + 1

    for chair, p in pairs(self.players) do
        p.tuos = mj_util.tuos(p.pai,nil,nil,nil)    
       
    end
end
-----------------过手胡
function changpai_table:clean_gzh(player)
    player.gzh = nil
end

function changpai_table:set_gzh_on_pass(passer,fans)
    passer.gzh = {hufans = fans, istrue = true}

end

function changpai_table:is_in_gzh(player,tile)
    return player.gzh and player.gzh.istrue
end
function changpai_table:get_gzh_fans(player)
    return player.gzh and player.gzh.hufans
end
-----------------过手吃
function changpai_table:clean_gsc(player)
    player.gsc = nil
end

function changpai_table:set_gsc_on_pass(passer,tile)
    passer.gsc = passer.gsc or {}
    passer.gsc[tile] = true
    
end

function changpai_table:is_in_gsc(player,tile)
    return player.gsc and player.gsc[tile]
end
-----------------
-----------------过手偷
function changpai_table:clean_gst(player)
    player.gst = nil
end

function changpai_table:set_gst_on_pass(passer,tile)
    passer.gst = passer.gst or {}
    passer.gst[tile] = true
end

function changpai_table:is_in_gst(player,tile)
    return false
end
-----------------过手碰
function changpai_table:clean_gsp(player)
    player.gsp = nil
end

function changpai_table:set_gsp_on_pass(passer,tile)
    passer.gsp = passer.gsp or {}
    passer.gsp[tile] = true
end

function changpai_table:is_in_gsp(player,tile)
    return player.gsp and player.gsp[tile]
end

function changpai_table:clean_last_can_penghu(player)
    player.last_penghu  = nil
end 

function changpai_table:get_last_can_penghu(player)
    return player.last_penghu and player.last_penghu.hufan
end
--------------------
-- 手牌最后4张牌,其他玩家出牌是否能操作碰胡,碰后是单吊将
function changpai_table:last_action_is_can_penghu(player,in_pai,allactions,chair_id)
    log.dump(player,"last_action_is_can_penghu_"..player.guid) 
    self:clean_last_can_penghu(player)
    if self.rule.play.guo_zhuang_hu then
        local sum = table.sum(player.pai.shou_pai)
        if sum == 4 then
            local iscanPeng = false
            local iscanHu = false
            for _,act in pairs(allactions) do
                local hu_action = act.actions[ACTION.HU]
                if hu_action then
                    iscanHu = true
                end
                local peng_action = act.actions[ACTION.PENG]
                if peng_action then
                    iscanPeng = true
                end
            end
            if iscanHu and iscanPeng then
                local p = self.players[chair_id]
                p.last_penghu = {
                    can_penghu = true,
                    hufan = self:hu_fan(p,in_pai,nil),
                }     
                log.dump(p.last_penghu,"last_penghu_"..p.guid)           
            end
        end
    end
end
function changpai_table:tou_pai()--偷牌也就是摸牌，但是是在一开始的偷拍阶段 
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai

    self:clean_gzh(player)
    self:clean_gsp(player)
    self:clean_gsc(player)

    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 5 then
        self.hashu = self.zhuang
        self:do_balance()
        return
    end

    local mo_pai
    if table.nums(self.pre_gong_tiles or {}) > 0 then
        for i,tile in pairs(self.pre_gong_tiles) do
            if self.bTest then
                mo_pai = tile
                self.dealer.remain_count = self.dealer.remain_count -1
            else
                mo_pai = self.dealer:deal_one_on(function(t) return t == tile end)
            end
            self.pre_gong_tiles[i] = nil
            break
        end
    else
        mo_pai = self.dealer:deal_one()
    end

    if not mo_pai then
        self.hashu = self.zhuang
        self:do_balance()
        return
    end

    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    self:on_mo_pai(player,mo_pai)
    table.incr(shou_pai,mo_pai)
    log.info("---------mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = "Draw",msg = {tile = mo_pai}})
    
end
function changpai_table:mo_pai()
    self:update_state(FSM_S.WAIT_MO_PAI)
    local player = self:chu_pai_player()
    local shou_pai = player.pai.shou_pai

    self:clean_gzh(player)
    self:clean_gsp(player)
    self:clean_gsc(player)

    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 5 then
        self.hashu = self.zhuang
        self:do_balance()
        return
    end

    local mo_pai
    if table.nums(self.pre_gong_tiles or {}) > 0 then
        for i,tile in pairs(self.pre_gong_tiles) do
            if self.bTest then
                mo_pai = tile
                self.dealer.remain_count = self.dealer.remain_count -1
            else
                mo_pai = self.dealer:deal_one_on(function(t) return t == tile end)
            end
            self.pre_gong_tiles[i] = nil
            break
        end
    else
        mo_pai = self.dealer:deal_one()
    end

    if not mo_pai then
        self.hashu = self.zhuang
        self:do_balance()
        return
    end

    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    log.dump(shou_pai,"add before")
    table.incr(shou_pai,mo_pai)
    log.dump(shou_pai,"add after")
    log.info("---------mo pai,guid:%s,pai:  %s ------",player.guid,mo_pai)
    self:broadcast2client("SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = "Draw",msg = {tile = mo_pai}})
    self:on_mo_pai(player,mo_pai)
    self:broadcast_players_tuos(player)
    self:clear_unuse_card(player)    
    

    local actions = self:get_actions(player,mo_pai)
    log.dump(actions,tostring(player.guid))
    if table.nums(actions) > 0 then
        self:action_after_mo_pai({
            [self.chu_pai_player_index] = {
                actions = actions,
                chair_id = self.chu_pai_player_index,
                session_id = self:session(),
            }
        })
    else
        self:broadcast_discard_turn()
        self:chu_pai()
    end
end

function changpai_table:ting(p)
    local si_dui = self.rule.play and self.rule.play.si_dui
    local ting_tiles = mj_util.is_ting(p.pai,si_dui) or {}
    if p.que and ting_tiles then
        table.filter(ting_tiles,function(_,tile) return mj_util.tile_men(tile) ~= p.que end)
    end

    return ting_tiles
end

function changpai_table:ting_full(p)
    
    local ting_tiles = mj_util.is_ting_full(p.pai)
    ting_tiles = table.map(ting_tiles,function(tiles,discard)
        local hu_tiles = table.map(tiles,function(_,tile)
            return tile, tile or nil
        end)
        return discard, table.nums(hu_tiles) > 0 and hu_tiles or nil
    end)

    return ting_tiles
end

function changpai_table:broadcast_discard_turn()
    self:broadcast2client("SC_Changpai_Discard_Round",{chair_id = self.chu_pai_player_index})
    for index, p in pairs(self.players) do
        tinsert(self.game_log.action_table,{chair =p.chair_id,act = action_name_str[ACTION.ROUND],msg = {chair_id = self.chu_pai_player_index},auto = nil,time = timer.nanotime()})
        break
    end
end

function changpai_table:broadcast_wait_discard(player)
    local chair_id = type(player) == "table" and player.chair_id or player
    self:broadcast2client("SC_ChangpaiWaitingDiscard",{chair_id = chair_id})
end
function changpai_table:on_action_after_jin_pai(player,msg,auto)
end
function changpai_table:on_action_after_first_tou_pai(player,msg,auto)
    local action = self:check_action_before_do(self.waiting_actions,player,msg)
    if not action then 
        log.warning("on_action_after_mo_pai invalid action guid:%s,action:%s",player.guid,msg.action)
        return 
    end

    self:cancel_clock_timer()
    self:cancel_main_timer()
   

    local do_action = msg.action
    local chair_id = player.chair_id
    local tile = msg.value_tile

    if chair_id ~= self.chu_pai_player_index then
        log.error("do action:%s but chair_id:%s is not current chair_id:%s after mo_pai",
            do_action,chair_id,self.chu_pai_player_index)
        return
    end

    log.dump(self.waiting_actions,tostring(player.guid))
    local player = self:chu_pai_player()
    if not player then
        log.error("do action %s,but wrong player in chair %s",do_action,player.chair_id)
        return
    end
    self:cancel_auto_action_timer(player)
    local waiting = self.waiting_actions[player.chair_id]

    local session_id = waiting.session_id

    local player_actions = self.waiting_actions[player.chair_id].actions
    if not player_actions[do_action] and do_action ~= ACTION.PASS and do_action ~= ACTION.CHU_PAI then
        log.error("do action %s,but action is illigle,%s",do_action)
        return
    end

    self.waiting_actions = {}
    --这个改成巴牌
    if do_action == ACTION.BA_GANG then
        self:clean_gzh(player)
        self:adjust_shou_pai(player,do_action,tile,session_id)
        self:log_game_action(player,do_action,tile,auto)
        self:jump_to_player_index(player)
        self:tou_pai() --从桌子上的牌拿一张
        self:broadcast_players_tuos(player)
        player.statistics.an_gang = (player.statistics.an_gang or 0) + 1    
        self:action_after_fapai()--假如可以巴牌也要摸一张
    end
     --这个偷牌
     if do_action == ACTION.TOU then
        self:clean_gzh(player)
        self:adjust_shou_pai(player,do_action,tile,session_id)
        self:log_game_action(player,do_action,tile,auto)
        self:broadcast_players_tuos(player)
        self:tou_pai()--从桌子上的牌拿一张   
        self:action_after_fapai()--假如还可以偷牌也要摸一张
    end

    if do_action == ACTION.PASS then


        send2client(player,"SC_Changpai_Do_Action",{
            action = do_action,
            chair_id = player.chair_id,
            session_id = msg.session_id,
            
        })

         self:next_player_index() --没有actions 跳到下家
        if(self.chu_pai_player_index==self.zhuang) then
            self:action_after_first_tou() --跳回到庄家以后，出牌或者自摸
        else
            self:action_after_fapai()
        end
        return
    end
    self:done_last_action(player,{action = do_action,tile = tile,})
    self:broadcast_players_tuos(player)
end
function changpai_table:on_action_chu_pai(player,msg,auto)
    
    self:cancel_clock_timer()
    if self.cur_state_FSM ~= FSM_S.WAIT_CHU_PAI then
        log.error("changpai_table:on_action_chu_pai state error %s",self.cur_state_FSM)
        return
    end

    if self.chu_pai_player_index ~= player.chair_id then
        log.error("changpai_table:on_action_chu_pai chu_pai_player %s ~= %s",player.chair_id,self.chu_pai_player_index)
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
    local cards = self:get_unusecard_list(player)
    for index, value in pairs(cards) do
       
        if value == chu_pai_val then
            log.error("tile cannot play guid:%s,tile:%s",player.guid,chu_pai_val)
            return
        end
    end
    
    --包牌判断，假如对下家形成包牌，就返回存在包牌风险提醒，假如下家已经是包牌，那不管
    local nest_user = 1
    if self.chu_pai_player_index+1 > self.start_count then
        nest_user = (self.chu_pai_player_index+1 ) %  self.start_count
    else
        nest_user = (self.chu_pai_player_index+1 )
    end
    local user = self.players[nest_user]
   
    if self:is_bao_pai(user,chu_pai_val) and not msg.is_sure then
                
        send2client(player,"SC_CP_Canbe_Baopai",{
            tile = chu_pai_val,
            number = 1
        })
        return
    end
 

    --------------------------------------------------------------------------------
    self:cancel_main_timer()
    self:cancel_auto_action_timer(player)

    log.info("---------chu pai guid:%s,chair: %s,tile:%s ------",player.guid,self.chu_pai_player_index,chu_pai_val)
    shou_pai[chu_pai_val] = shou_pai[chu_pai_val] - 1
    self:on_chu_pai(chu_pai_val)

    tinsert(player.pai.desk_tiles,chu_pai_val)
    self:broadcast2client("SC_Changpai_Action_Discard",{chair_id = player.chair_id, tile = chu_pai_val})
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = "Discard",msg = {tile = chu_pai_val},auto = auto,time = timer.nanotime()})

    self:broadcast_players_tuos(player)
    self:set_gsc_on_pass(player,chu_pai_val)
    
    local waiting_actions = {}
    local nestid = player.chair_id+1
    nestid = nestid > self.start_count and nestid%self.start_count or nestid

    for key, v in pairs(self.players) do
          if  player.chair_id ~= v.chair_id then
            if v.chair_id == nestid then
                local actions = self:get_actions(v,nil,chu_pai_val,nil,true)
                if table.nums(actions) > 0 then
                    waiting_actions[v.chair_id] = {
                        chair_id = v.chair_id,
                        actions = actions,
                        session_id = self:session(),
                    }
                end
            else
                local actions = self:get_actions(v,nil,chu_pai_val,nil,false)
                if table.nums(actions) > 0 then
                    waiting_actions[v.chair_id] = {
                        chair_id = v.chair_id,
                        actions = actions,
                        session_id = self:session(),
                    }
                end
            end
        end
    end


    if table.nums(waiting_actions) == 0 then
        self:next_player_index()
        
        local function auto_fanpai()
            self:lockcall(function()
                self:fan_pai()
            end)
        end
        self:begin_clock_timer(TIME_TYPE.MAIN_FAN_PAI,TIME_TYPE.MAIN_FAN_PAI,function ()
            auto_fanpai()
        end)
        
    else
        self:action_after_chu_pai(waiting_actions)
    end
end
function changpai_table:is_bao_pai(player,in_pai)
    local tileNum = 0
    local ming_pai = player.pai.ming_pai or {}
    for _, s in pairs(ming_pai) do
        if s and s.tile == in_pai and (s.type == SECTION_TYPE.PENG or  s.type == SECTION_TYPE.TOU)  then
            return true
        end 
        if s.type == SECTION_TYPE.CHI and s.othertile == in_pai and  mj_util.tile_is_chongfan(in_pai)then
            tileNum= tileNum+1
        end
    end
    if  tileNum >=2 then
        return true
    end
    return  false
end
function changpai_table:send_ting_tips(p)
    local hu_tips = self.rule and self.rule.play.hu_tips or nil
    if not hu_tips or p.trustee then return end

    local ting_tiles = self:ting_full(p)
    if table.nums(ting_tiles) > 0 then
        local pai = p.pai
        local discard_tings = table.series(ting_tiles,function(tiles,discard)--把可以胡的牌放到手牌中算翻发给前端
            table.decr(pai.shou_pai,discard)
            local tings = table.series(tiles,function(_,tile) return {tile = tile,fan = self:hu_fan(p,tile)} end)
            table.incr(pai.shou_pai,discard)
            return { discard = discard, tiles_info = tings, }
        end)

        send2client(p,"SC_CP_TingTips",{
            ting = discard_tings
        })
    end
end

function changpai_table:on_reconnect_when_chu_pai(p)
    send2client(p,"SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
    send2client(p,"SC_Changpai_Discard_Round",{chair_id = self.chu_pai_player_index})
    self:send_ting_tips(p)

    if self.main_timer then
        self:begin_clock(self.main_timer.remainder,p)
    end
end
function changpai_table:call_chu_pai(p)
    send2client(p,"SC_Changpai_Discard_Round",{chair_id = self.chu_pai_player_index})
end
function changpai_table:chu_pai()
    local player = self:chu_pai_player()
    self:broadcast_discard_turn()
    self:update_state(FSM_S.WAIT_CHU_PAI)

    
    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type then
        local function auto_chu_pai(p)
            local chu_tile = p.mo_pai
            
            if not chu_tile or not p.pai.shou_pai[chu_tile] or p.pai.shou_pai[chu_tile] <= 0 then
                local c
                repeat
                    chu_tile,c = table.choice(p.pai.shou_pai)
                    local cards = self:get_unusecard_list(player)
                    for _, value in pairs(cards) do
                        if value == c then
                            c=0
                        end
                    end
                until c > 0
            end

            log.info("auto_chu_pai chair_id %s,tile %s",p.chair_id,chu_tile)
            self:lockcall(function()
                self:on_action_chu_pai(p,{
                    tile = chu_tile,
                    is_sure = true
                },true)
            end)
        end

        log.info("begin chu_pai clock %s",player.chair_id)
        self:begin_main_timer(trustee_seconds,trustee_seconds,function()
            log.dump(self.chu_pai_player_index)
            
            local p = self.players[self.chu_pai_player_index]
            log.dump(p)
            log.info("chu_pai clock timeout %s",p.chair_id)
            self:set_trusteeship(p,true)
            auto_chu_pai(p)
        end)

        if player.trustee then
            log.info("begin auto_chu_pai timer %s",player.chair_id)
            local p = self.players[player.chair_id]
            self:begin_auto_action_timer(p,math.random(1,2),function()
                auto_chu_pai(p)
            end)
        end
    end

    self:send_ting_tips(player)
end
function changpai_table:fan_pai()

    self:cancel_clock_timer()
    self:cancel_all_auto_action_timer()
    local player = self:chu_pai_player()
    
    local len = self.dealer.remain_count
    log.info("-------left pai " .. len .. " tile")
    if len == 5 then
        self.hashu = self.zhuang
        self:do_balance()
        return
    end

    local fan_pai
    if table.nums(self.pre_gong_tiles or {}) > 0 then
        for i,tile in pairs(self.pre_gong_tiles) do
            if self.bTest then
                fan_pai = tile
                self.dealer.remain_count = self.dealer.remain_count -1
            else
                fan_pai = self.dealer:deal_one_on(function(t) return t == tile end)
            end
            self.pre_gong_tiles[i] = nil
            break
        end
    else
        fan_pai = self.dealer:deal_one()
    end

    if not fan_pai then
        self.hashu = self.zhuang
        self:do_balance()
        return
    end

    self.mo_pai_count = (self.mo_pai_count or 0) + 1
    
    --table.incr(shou_pai,mo_pai)
    log.info("---------mo pai,guid:%s,pai:  %s ------",player.guid,fan_pai)
    self:broadcast2client("SC_Changpai_Tile_Left",{tile_left = self.dealer.remain_count,})
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = "FanPai",msg = {tile = fan_pai}})
    self:on_fan_pai(player,fan_pai)

    self:on_user_fan_pai(fan_pai)
    --翻牌的时候所有玩家都可以相应action
    local waiting_actions = {}
    local nestid = player.chair_id+1
    nestid = nestid>self.start_count and nestid%self.start_count or nestid
    
    
     for key, v in pairs(self.players) do        
        log.info("--- get_selfactionsAndset_pass  guid:%s,chair: %s,tile:%s ------",player.guid,self.chu_pai_player_index,fan_pai)
                self:clean_last_can_penghu(player)
                
                if nestid == v.chair_id  then
                    local actions = self:get_actions(v,nil,fan_pai,nil,true,false)
                    if table.nums(actions) > 0 then
                        waiting_actions[v.chair_id] = {
                            chair_id = v.chair_id,
                            actions = actions,
                            session_id = self:session(),
                        }
                    end 
                else
                    if player.chair_id == v.chair_id  then
                        local actions = self:get_actions(v,nil,fan_pai,nil,true,true)
                        if table.nums(actions) > 0 then
                            waiting_actions[v.chair_id] = {
                                chair_id = v.chair_id,
                                actions = actions,
                                session_id = self:session(),
                            }
                        end 
                        
                    else
                        local actions = self:get_actions(v,nil,fan_pai,nil,false,false)
                        if table.nums(actions) > 0 then
                            waiting_actions[v.chair_id] = {
                                chair_id = v.chair_id,
                                actions = actions,
                                session_id = self:session(),
                            }
                        end 
                    end
                end
                   
    end

    if table.nums(waiting_actions) == 0 then
        self:next_player_index()

        local function auto_fanpai()
            self:lockcall(function()
                
                self:fan_pai()
            end)
        end
        self:begin_clock_timer(TIME_TYPE.MAIN_FAN_PAI,TIME_TYPE.MAIN_FAN_PAI,function ()
            auto_fanpai()
        end)
        --self:fan_pai()
    else
        self:action_after_fan_pai(waiting_actions)
    end
    

end    
function changpai_table:get_max_fan()
    local fan_opt = self.rule.fan.max_option + 1
    return self.room_.conf.private_conf.fan.max_option[fan_opt]
end
function changpai_table:get_is_chi_piao()
    local piao_opt = self.rule.play.chi_piao
    return piao_opt
end
function changpai_table:get_player_piao(p)
    local chipiao = false
    if self:get_is_chi_piao() then
        if p.hu and p.hu.types~=HU_TYPE.BABA_HEI and p.hu.types~=HU_TYPE.HEI_LONG then
            if self.zhuang == p.chair_id and p.tuos and p.tuos >=16 then
                chipiao = true
            end
            if self.zhuang ~= p.chair_id and p.tuos and  p.tuos >=14 then
                chipiao = true
            end 
        end
        if p.hu and (p.hu.types==HU_TYPE.BABA_HEI or p.hu.types==HU_TYPE.HEI_LONG)  then
            chipiao = true
        end     
    end
    return chipiao
end
function changpai_table:get_player_xiaohu(p)
    local xiaohu =false
        if p.hu  then 
            if self.zhuang == p.chair_id and p.tuos and p.tuos <16 and  p.tuos >=14 then
                xiaohu = true
            end
            if self.zhuang ~= p.chair_id and p.tuos and  p.tuos <14 and   p.tuos >=12 then
                xiaohu = true
            end
        end 
        if self:get_player_piao(p) then
            xiaohu =false
        end
    return xiaohu
end
function changpai_table:get_chao_add_score(p)
    local add_score_option = self.rule.fan.chaoFan+1
    return self.room_.conf.private_conf.fan.add_score[add_score_option]
end
function changpai_table:do_balance(in_pai)

    for _, p in pairs(self.players) do
        if p.hu then
            p.tuos = mj_util.tuos(p.pai,in_pai,nil,nil)
        else
            p.tuos = mj_util.tuos(p.pai,nil,nil,nil)
        end
        
    end
    local typefans,fanscores = self:game_balance(in_pai)

    local typessend={}
    
    for key, value in pairs(typefans) do 
        local playersend={}
        for inx, v in pairs(value) do
            if v then
                table.insert(playersend,{type =v.type or nil,count = v.count or nil })
            end
        end
        typessend[key] = playersend or nil
    end
    local msg = {
        players = {},
        player_balance = {},
    }


    local player_hu = {}
    for index, value in pairs(self.players) do
       if value.hu then
            player_hu = value.hu
       end
    end

    local chair_money = {}
    for chair_id,p in pairs(self.players) do
        local p_score = fanscores[chair_id] and fanscores[chair_id].score or 0
        if p and p.hu and p.hu.tile and  not in_pai then   
            table.decr(p.pai.shou_pai,p.hu.tile)
        end
        log.dump(p.pai.shou_pai)
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
        local dianpao =false
        if player_hu and player_hu.whoee and  player_hu.whoee == p.chair_id and not player_hu.zi_mo then
            dianpao = true
        end
        p.total_score = (p.total_score or 0) + p_score
        p_log.score = p_score
        p_log.is_chipiao = self:get_player_piao(p)
        p_log.is_xiaohu = self:get_player_xiaohu(p)
        p_log.is_dianpao = dianpao
        p_log.bao_pai = p.is_bao_pai
        p_log.tuos = p.tuos
        
        
        tinsert(msg.players,{
            chair_id = chair_id,
            desk_pai = desk_pai,
            shou_pai = shou_pai,
            pb_ming_pai = ming_pai,
            tuos =p.tuos ,
            is_chipiao = self:get_player_piao(p),
            is_xiaohu = self:get_player_xiaohu(p),
            is_dianpao = dianpao,
            is_baopai = p.is_bao_pai
        })

        tinsert(msg.player_balance,{
            chair_id = chair_id,
            total_score = p.total_score,
            round_score = p_score,
            items = typessend[chair_id],
            hu_tile = p.hu and p.hu.tile or nil,
            hu_fan = fanscores[chair_id] and fanscores[chair_id].fan or 0 ,
            hu = p.hu and (p.hu.zi_mo and 2 or 1) or nil,
            status = p.hu and 2  or nil,
            hu_index = p.hu and p.hu.index or nil,
        })

        local win_money = self:calc_score_money(p_score)
        chair_money[chair_id] = win_money
        log.info("player hu %s,%s,%s",chair_id,p_score,win_money)
    end

  

    local logids = {
        [350] = enum.LOG_MONEY_OPT_TYPE_CHANGPAI_ZIGONG,
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
    
    msg.leftpai = self.dealer:deal_tiles(self.dealer.remain_count)
    self:broadcast2client("SC_ChangpaiGameFinish",msg)

    self:notify_game_money()

    self.game_log.balance = msg.player_balance
    self.game_log.end_game_time = os.time()
    self.game_log.cur_round = self.cur_round 
    if self.start_count == 2 and self.qie_pai then
        self.game_log.qie_pai =table.values(self.qie_pai)
    end
    self:save_game_log(self.game_log)

    self.game_log = nil
    
    self:game_over()
end

function changpai_table:pre_begin()
    self:xi_pai()
end

function changpai_table:series_action_map(actions)
    local acts = {}
    for act,tiles in pairs(actions) do
        if  tiles then
            for tile,v in pairs(tiles) do   
                tinsert(acts,{
                    action = act,
                    tile = v.tile,   
                    other_tile = v.othertile or nil,  
                })
        end
        end
        
    end
    return acts
end

function changpai_table:send_action_waiting(action)
    local chair_id = action.chair_id
    log.info("send_action_waiting,%s",chair_id)
    send2client(self.players[chair_id],"SC_CP_WaitingDoActions",{
        chair_id = chair_id,
        actions = self:series_action_map(action.actions),
        session_id = action.session_id,
    })
end

function changpai_table:prepare_tiles()
    if not self.bTest then
        self.dealer:shuffle()
        self.pre_tiles = {}
    else   
        
        
        -- -- 这个是没有可以出的牌     
        -- self.pre_tiles = {
        --     [1] = {1,1,1,2,2,3,3,4,4,7,7,13,9,6},     -- 万 庄
        --     [2] = {16,11,8,9,19,5,5,13,9,2,8,15,17,11,12},    -- 筒  
        --     [3] = {15,12,6,9,18,16,17,6,4,12,17,17,16,7,8},      -- 万
        -- }
        -- -- 测试摸牌,从前到后
        -- self.pre_gong_tiles = {
        --     16,2,3,4,7,6,8,20,14,13,10,15,14
        -- }
        -- 黑龙     
        -- self.pre_tiles = {
        --     [1] = {10,10,16,6,20,2,18,18,3,7,12,13,16,7,14},     -- 万 庄
        --     [2] = {16,16,5,12,9,21,21,17,9,7,2,11,12,11,14},    -- 筒  
        --     [3] = {21,20,6,19,18,19,21,15,15,3,12,15,11,17,8},      -- 万
        -- }
        -- -- 测试摸牌,从前到后
        -- self.pre_gong_tiles = {
        --     8,6,18,3,4,20,6,
        -- }
        -- 测试手牌     
        -- 测试手牌     
       -- 测试手牌     
       self.pre_tiles = {
        [1] = {12,12,12,4,18,2,20,4,19,5,17,5,17,8,15},     -- 万 庄
        [2] = {6,7,11,11,16,16,8,9,2,20,15,9,17,7,6},    -- 筒  
        [3] = {5,16,7,7,2,16,6,1,1,9,6,14,11,11,9},      -- 万
    }
    -- 测试摸牌,从前到后
    self.pre_gong_tiles = {
        11,16,14,12,20,17,14,20,1,15,3,8,
    }
        self.dealer.remain_count = 52
    end
    
    if self.hashu and self.hashu > 0 then
        self.zhuang_pai = nil
        self.zhuang = self.hashu
        self.hashu = 0
             
    else
        log.info("zhuang_pai %d  ",self.zhuang_pai)
        local index  = math.random(21)
        self.zhuang_pai =  self.dealer:use_one() or index --2的话1号是庄
        self.zhuang =  mj_util.tile_value(self.zhuang_pai) % (self.start_count)+1
        self.game_log.zhuang = self.zhuang
    end
    --log.error("-------------------------------%d-------%d",self.hashu,self.zhuang)
    if self.start_count == 2 then
        self.qie_pai = self.dealer:deal_tiles(15) 
    end
    
    self.chu_pai_player_index = self.zhuang --出牌人的索引
    self.game_log.zhuang = self.zhuang
    
    self:foreach(function(p)--给每个玩家发牌
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
    log.info("user   %d",self.chu_pai_player_index)
    self:fake_mo_pai()--庄家多摸一张牌 也就是16张牌
end


function changpai_table:serial_types(tsmap)
    -- local types = table.series(tsmap,function(c,t)
    --     local tinfo = HU_TYPE_INFO[t]
    --     return {type = t,fan = tinfo.fan,score = tinfo.score,count = c}
    -- end)
    local types = {}
    local tinfo = {}
    if tsmap then
        tinfo = HU_TYPE_INFO[tsmap]
        types[tsmap] = {fan = tinfo.fan,score = tinfo.score,count = 1,type = tsmap}
    end
    
    return types
end

function changpai_table:gang_types(p)
    local s2hu_type = {
        [SECTION_TYPE.CHONGFAN_PENG] = HU_TYPE.CHONGFAN_PENG,
        [SECTION_TYPE.SI_ZHANG] = HU_TYPE.SI_ZHANG,
        [SECTION_TYPE.TUO_24] = HU_TYPE.TUO_24,
        [SECTION_TYPE.CHONGFAN_TOU] = HU_TYPE.CHONGFAN_TOU,
        [SECTION_TYPE.CHONGFAN_CHI_3] = HU_TYPE.CHONGFAN_CHI_3,
    }

    local ss = table.select(p.pai.ming_pai,function(s) return  s2hu_type[s.type] ~= nil end)
    local gfan= table.group(ss,function(s) return  s2hu_type[s.type] end)
    local typescount = table.map(gfan,function(gp,t)
        return t,table.nums(gp)
    end)

    return typescount --算出明牌中有这些动作的种类和数量 [HU_TYPE]=counts
end

function changpai_table:calc_types(ts)
    ts = self:serial_types(ts)
    return table.sum(ts,function(t) return (t.score or 1) * (t.count or 0) end),
        table.sum(ts,function(t) return (t.count or 1) * (t.fan or 0) end)
end
--求出最大番数
function changpai_table:hu_fan(player,in_pai,mo_pai,qiang_gang)
    local typefans = {}
    local gangfans
    local hutypes = self:hu(player,in_pai,mo_pai,qiang_gang)
    local types = self:serial_types(hutypes)
    gangfans = self:calculate_gang(player,in_pai) --只要有人胡杠什么的就要算钱
    typefans[player.chair_id] = table.union(types or {},gangfans or {})
    
 

    local fans = table.map(typefans,function(v,chair)
        local fan = table.sum(v,function(t) return t.fan * t.count end)
        return chair,fan
    end)
   

    return fans[player.chair_id]
end

function changpai_table:get_actions_first_turn(p,mo_pai)
   
    local actions = mj_util.get_actions_first_turn(p.pai,mo_pai)
   
    return actions
end

function changpai_table:get_actions(p,mo_pai,in_pai,qiang_gang,can_eat,can_ba)  

 
    local actions = mj_util.get_actions(p.pai,mo_pai,in_pai,can_eat,self.zhuang==p.chair_id,can_ba)

   log.dump(actions)
 
    if  not self:can_hu(p,in_pai,mo_pai,qiang_gang) and actions[ACTION.HU] then
        actions[ACTION.HU] = nil
    end

    if actions[ACTION.CHI] then
        for i = 1, 21, 1 do
            if actions[ACTION.CHI][i] then
                
                local Notcards =p.pai.un_usecard or nil
                local count={}
                local index =0
                 for key, num in pairs(p.pai.shou_pai) do
                     if num>0 then  
                        if key==i  then                            
                            count[key] =  num-1
                            
                            local act = actions[ACTION.CHI][key] or nil 
                            count[act.tile or i] = 0
                            index = act.tile or 0
                            
                        else
                            count[key] =  num
                        end  
                        if index>0 then count[index] = 0  end
                        
                     end      
                 end
                 
                 if Notcards then
                     for key, num in pairs(count) do
                         if num > 0 and Notcards[key] then
                            count[key] = 0   
                         end
                     end
            
                     local elph=table.select(count,function (s)  return s>0 end)
                     
                     if table.nums(elph) == 0 then
                        actions[ACTION.CHI][i] = nil
                     end      
                 end 
                
            end
        end
        local action = actions[ACTION.CHI]
        if table.nums(action) == 0 then
            actions[ACTION.CHI] = nil
        end    
    end
 
    if in_pai and self:is_in_gzh(p,in_pai) and actions[ACTION.HU] then
        local hufans = self:hu_fan(p,in_pai)
        if self:get_gzh_fans(p) >=hufans then
            actions[ACTION.HU] = nil
        end   
    end
    if mo_pai and self:is_in_gzh(p) and actions[ACTION.HU] then
        local hufans = self:hu_fan(p,nil,mo_pai)
        if self:get_gzh_fans(p) >=hufans then
            actions[ACTION.HU] = nil
        end  
    end
    
 
    if in_pai and self:is_in_gsp(p,in_pai) and actions[ACTION.PENG] then

        local action = actions[ACTION.PENG]
        for gsp_tile,_ in pairs(p.gsp) do
            action[gsp_tile] = nil
        end
        if table.nums(action) == 0 then
            actions[ACTION.PENG] = nil
        end

    end
    if in_pai and self:is_in_gsc(p,in_pai) and actions[ACTION.CHI] then
        local action = actions[ACTION.CHI]
        for gsc_tile,_ in pairs(p.gsc) do
            
            for key, value in pairs(action) do
                
                if value.tile == gsc_tile then
                    action[key] = nil
                end
            end
        end
        if table.nums(action) == 0 then
            actions[ACTION.CHI] = nil
        end

    end
    if in_pai and self:is_in_gst(p,in_pai) and actions[ACTION.TOU] then
        local action = actions[ACTION.TOU]
        for gsh_tile,_ in pairs(p.gsh) do
            action[gsh_tile] = nil
        end
        if table.nums(action) == 0 then
            actions[ACTION.HU] = nil
        end
    end
    if in_pai and mj_util.tile_value(in_pai) == 7 then
        actions[ACTION.HU] = nil
    end
    local remain = self.dealer.remain_count
    if remain < 5 then
        actions[ACTION.BA_GANG] = nil
        actions[ACTION.HU] = nil
        actions[ACTION.PENG] = nil
        actions[ACTION.CHI] = nil
        actions[ACTION.TOU] = nil
        actions[ACTION.ZI_MO] = nil
    end

    if self.zhuang==p.chair_id and actions[ACTION.HU] and  p.chu_pai_count and p.chu_pai_count == 0 then      
        actions[ACTION.TIAN_HU] = actions[ACTION.HU]
        actions[ACTION.HU] = nil
    end
    return actions
end



function changpai_table:log_game_action(player,action,tile,auto)
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[action],msg = {tile = tile},auto = auto,time = timer.nanotime()})
end

function changpai_table:log_failed_game_action(player,action,tile,auto)
    tinsert(self.game_log.action_table,{chair = player.chair_id,act = action_name_str[action],msg = {tile = tile},auto = auto,failed = true,})
end

function changpai_table:done_last_action(player,action)
    player.last_action = action
    self:foreach_except(player,function(p) p.last_action = nil end)
end

function changpai_table:check_action_before_do(waiting_actions,player,msg)
    local action = msg.action
    local chair_id = player.chair_id
    local tile = msg.value_tile

    if not waiting_actions then
        log.error("waiting actions nil when check_action_before_do,chair_id %s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    local player_actions = waiting_actions[chair_id]
    if not player_actions then
        log.error("no action waiting when check_action_before_do,chair_id %s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    if player_actions.session_id ~= msg.session_id and  not msg.is_sure then
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

    if not actions[action]  then
        log.error("no action waiting when check_action_before_do,chair_id %s,action:%s,tile:%s",chair_id,action,tile)
        return
    end

    return player_actions
end

function changpai_table:on_fan_pai(player,fan_pai)
    player.fan_pai = fan_pai
    player.mo_pai_count = (player.mo_pai_count or 0) + 1
    send2client(player,"SC_Changpai_Fan",{tile = fan_pai,chair_id = player.chair_id})
    self:foreach_except(player,function(p)
        send2client(p,"SC_Changpai_Fan",{tile = fan_pai,chair_id = player.chair_id})
        p.fan_pai = nil
    end)
end
function changpai_table:on_mo_pai(player,mo_pai)
    player.mo_pai = mo_pai
    player.mo_pai_count = (player.mo_pai_count or 0) + 1
    send2client(player,"SC_Changpai_Draw",{tile = mo_pai,chair_id = player.chair_id})
    self:foreach_except(player,function(p)
        send2client(p,"SC_Changpai_Draw",{tile = 255,chair_id = player.chair_id})
        p.mo_pai = nil
    end)
end

function changpai_table:calculate_hu(hu)
    return self:serial_types(hu.types)
end



function changpai_table:calculate_gang(p,in_pai)
    
    local chong_fan ={--冲番牌
        [1] = true,
        [3] = true,
        [5] = true,
        [12] = true,
        [15] = true,
        [17] = true,
        [21] = true,
    }
    local scores = {}

    local gangfans = {}
    
    local chi_pai = {}
    local count={}
    
    for key, num in pairs(p.pai.shou_pai) do
        if num>0 then
            count[key]=num
        end
    end
    if in_pai then
        if count[in_pai] then count[in_pai]=count[in_pai]+ 1
        else count[in_pai] =1 end
    end
    for _, s in pairs(p.pai.ming_pai) do 
        if  s.type == SECTION_TYPE.BA_GANG then
            count[s.tile]=4
            -- if chong_fan[s.tile]  then--假如是冲番牌
            --     if gangfans[HU_TYPE.CHONGFAN_PENG] then gangfans[HU_TYPE.CHONGFAN_PENG].count=gangfans[HU_TYPE.CHONGFAN_PENG].count+1
            --     else gangfans[HU_TYPE.CHONGFAN_PENG]={fan = HU_TYPE_INFO[HU_TYPE.CHONGFAN_PENG].fan,count = 1,type = HU_TYPE.CHONGFAN_PENG} end
            -- end
        end
        if s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU then
            count[s.tile]=count[s.tile] and count[s.tile]+3 or 3
        end
        if s.type == SECTION_TYPE.CHI then
            count[s.tile]=count[s.tile] and count[s.tile]+1 or 1
            count[s.othertile]=count[s.othertile] and count[s.othertile]+1 or 1
        end
    end
    for key, value in pairs(count) do
        if value==4 then
            if chong_fan[key] then
                if gangfans[HU_TYPE.CHONGFAN_CHI_3] then gangfans[HU_TYPE.CHONGFAN_CHI_3].count=gangfans[HU_TYPE.CHONGFAN_CHI_3].count+1
                else gangfans[HU_TYPE.CHONGFAN_CHI_3]={fan = HU_TYPE_INFO[HU_TYPE.CHONGFAN_CHI_3].fan,count = 1,type = HU_TYPE.CHONGFAN_CHI_3} end
                if gangfans[HU_TYPE.SI_ZHANG] then gangfans[HU_TYPE.SI_ZHANG].count=gangfans[HU_TYPE.SI_ZHANG].count+1
                else gangfans[HU_TYPE.SI_ZHANG]={fan = HU_TYPE_INFO[HU_TYPE.SI_ZHANG].fan,count = 1,type = HU_TYPE.SI_ZHANG} end
            else
                if gangfans[HU_TYPE.SI_ZHANG] then gangfans[HU_TYPE.SI_ZHANG].count=gangfans[HU_TYPE.SI_ZHANG].count+1
                else gangfans[HU_TYPE.SI_ZHANG]={fan = HU_TYPE_INFO[HU_TYPE.SI_ZHANG].fan,count = 1,type = HU_TYPE.SI_ZHANG} end
            end     
        end
        if value==3 then
            if chong_fan[key] then
                if gangfans[HU_TYPE.CHONGFAN_CHI_3] then gangfans[HU_TYPE.CHONGFAN_CHI_3].count=gangfans[HU_TYPE.CHONGFAN_CHI_3].count+1
                else gangfans[HU_TYPE.CHONGFAN_CHI_3]={fan = HU_TYPE_INFO[HU_TYPE.CHONGFAN_CHI_3].fan,count = 1,type = HU_TYPE.CHONGFAN_CHI_3} end
            end 
        end
    end
    -- for _, s in pairs(p.pai.ming_pai) do      
        
    --     if s.type == SECTION_TYPE.CHI then
    --         if chi_pai[s.tile] then chi_pai[s.tile]=chi_pai[s.tile]+1 
    --         else chi_pai[s.tile]=1 end   
    --     end

    --     if s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU then 
    --         if chong_fan[s.tile]  and s.type == SECTION_TYPE.PENG then--假如是冲番牌
    --             if gangfans[HU_TYPE.CHONGFAN_PENG] then gangfans[HU_TYPE.CHONGFAN_PENG].count=gangfans[HU_TYPE.CHONGFAN_PENG].count+1
    --             else gangfans[HU_TYPE.CHONGFAN_PENG]={fan = HU_TYPE_INFO[HU_TYPE.CHONGFAN_PENG].fan,count = 1,type = HU_TYPE.CHONGFAN_PENG} end
    --         elseif  chong_fan[s.tile]  and s.type == SECTION_TYPE.TOU then 
    --             if gangfans[HU_TYPE.CHONGFAN_TOU] then gangfans[HU_TYPE.CHONGFAN_TOU].count=gangfans[HU_TYPE.CHONGFAN_TOU].count+1
    --             else gangfans[HU_TYPE.CHONGFAN_TOU]={fan = HU_TYPE_INFO[HU_TYPE.CHONGFAN_TOU].fan,count = 1,type = HU_TYPE.CHONGFAN_TOU} end
    --         end
    --     end 
    -- end
    -- for tile, value in ipairs(chi_pai) do
    --     if value>=3 and chong_fan[tile] then
    --     if gangfans[HU_TYPE.CHONGFAN_CHI_3] then gangfans[HU_TYPE.CHONGFAN_CHI_3].count=gangfans[HU_TYPE.CHONGFAN_CHI_3].count+1
    --     else gangfans[HU_TYPE.CHONGFAN_CHI_3]={fan = HU_TYPE_INFO[HU_TYPE.CHONGFAN_CHI_3].fan,count = 1,type = HU_TYPE.CHONGFAN_CHI_3} end
    --     end
    -- end

    local tuo_num = p.tuos or 0
    if tuo_num>=24 then
        gangfans[HU_TYPE.TUO_24]  = {fan = HU_TYPE_INFO[HU_TYPE.TUO_24].fan,count = 1,type = HU_TYPE.TUO_24} 
    end
    
    log.dump(p.chair_id,"tianhu")
    log.dump(p.chu_pai_count ,"chu_pai_count")
    if p.chair_id == self.zhuang  and p.chu_pai_count == 0 then
        gangfans[HU_TYPE.TIAN_HU] = {fan = HU_TYPE_INFO[HU_TYPE.TIAN_HU].fan,count = 1,type = HU_TYPE.TIAN_HU}
        log.dump(gangfans,"tianhu")
    end

    -- if p.chair_id ~= self.zhuang and p.mo_pai_count <= 1 and p.chu_pai_count == 0 and table.nums(p.pai.ming_pai) == 0 then
    --     gangfans[HU_TYPE.DI_HU] = {fan = HU_TYPE_INFO[HU_TYPE.DI_HU].fan,count = 1,type = HU_TYPE.DI_HU}
    -- end


    local fans = table.series(gangfans,function(v,t) return {type = t,fan = v.fan,count = v.count} end)
    return fans,scores
end

function changpai_table:calculate_jiao(p)
    if not p.jiao then return end

    local jiao_tiles = p.jiao.tiles
    if table.nums(jiao_tiles) == 0 then 
        return {} 
    end

    local type_fans = table.flatten(
        table.series(jiao_tiles,function(_,tile)
            local tt = self:rule_hu_types(p.pai,tile,p.chair_id==self.zhuang)
            return table.series(tt,function(ts)
                local _,fan = self:calc_types(ts)
                return {types = self:serial_types(ts),fan = fan,tile = tile}
            end)
        end)
    )
    
    if self.rule.play.cha_da_jiao then
        table.sort(type_fans,function(l,r) return l.fan > r.fan end)
    elseif self.rule.play.cha_xiao_jiao then
        table.sort(type_fans,function(l,r) return l.fan < r.fan end)
    end

    return type_fans[1]
end


function changpai_table:game_balance(in_pai)
    --没有胡的人数
    local wei_hu_count = table.sum(self.players,function(p) return (not p.hu) and 1 or 0 end)

    local typefans,scores = {},{}
    self:foreach(function(p)
        local hu
        if p.hu then
            hu = self:calculate_hu(p.hu) --统计番数，胡的类型数，胡的分数
        end
        local gangfans,gangscores
        if  p.hu then
            gangfans,gangscores = self:calculate_gang(p,in_pai) --只要有人胡杠什么的就要算钱
        end

        typefans[p.chair_id] = table.union(hu or {},gangfans or {})
        table.mergeto(scores,gangscores or {},function(l,r) return (l or 0) + (r or 0) end)
    end)



    local max_fan = self:get_max_fan() or 3

    local fans = table.map(typefans,function(v,chair)
        local fan = table.sum(v,function(t) return t.fan * t.count end)
        return chair,fan
    end)
 

    self:foreach(function(p)
        local chair_id = p.chair_id
        local fan = fans[chair_id]
        local fan_score = 0 --不管谁胡都是算剩余所有玩家乘以自身数千
        local winscore =  0
        local chaofan_add = 0
 
        local zongfan = fan

        if p.hu then

            if self:get_max_fan()==4 then --超番加分
                if  zongfan>4  then
                    chaofan_add =  (zongfan - 4) * self:get_chao_add_score()
                    fan_score = 2 ^ math.abs(4)
                    fan_score= fan_score 
                else
                    
                    fan_score = 2 ^ math.abs(zongfan)
                    fan_score= fan_score   
                end
                 
            elseif self:get_max_fan()==3 then
                fan = zongfan>3 and 3 or zongfan
                fan_score = 2 ^ math.abs(fan)
                fan_score= fan_score 
            else
                
                fan_score = 2 ^ math.abs(zongfan)
                fan_score= fan_score   
            end
            if self:get_player_piao(p) then --吃飘加分
                
                fan_score = fan_score*2
                fan_score = fan_score + chaofan_add
                
            end
            if self:get_player_xiaohu(p) then --只要小胡都是一分
                fan_score = 1
            end
            winscore= fan_score * (self.start_count-1)
            if not p.hu.zi_mo then
                local whoee = p.hu.whoee
                scores[whoee] = (scores[whoee] or 0) - winscore
                scores[chair_id] = (scores[chair_id] or 0) + winscore
                return
            end
            local chairid = chair_id -1 
            if chairid < 1 then
                chairid = self.start_count
            end
            local lastplayer = self.players[chairid]

            if lastplayer and lastplayer.bao_card  then     
                lastplayer.is_bao_pai =true          
                scores[chairid] = (scores[chairid] or 0) - winscore
                scores[chair_id] = (scores[chair_id] or 0) + winscore
                return
            end       
            
            if self.rule.play.zi_mo_jia_di then
                fan_score = fan_score + 1
            end
           
            self:foreach_except(p,function(pi)  
                local chair_i = pi.chair_id
                scores[chair_i] = (scores[chair_i] or 0) - fan_score
                scores[chair_id] = (scores[chair_id] or 0) + fan_score
            end)

        end
    end)

    local fanscores = table.map(self.players,function(_,chair)
        return chair,{fan = fans[chair] or 0,score = scores[chair] or 0,}
    end)
    log.dump(typefans,"typefans")
    return typefans,fanscores
end

function changpai_table:on_game_overed()
    self:cancel_all_auto_action_timer()
    self:cancel_clock_timer()
    self:cancel_main_timer()
    self.game_log = nil

    self.zhuang =  nil

    self:clear_ready()
    self.cur_state_FSM = nil

    self:foreach(function(v)
        v.hu = nil
        v.jiao = nil
        v.bao_card = nil
        v.pai = {
            ming_pai = {},
            shou_pai = {},
            desk_tiles = {},
            huan = nil,
        }
        v.mo_pai = nil
        v.mo_pai_count = nil
        v.chu_pai = nil
        v.fan_pai = nil
        v.chu_pai_count = 0

        v.que = nil
    end)

    base_table.on_game_overed(self)
end

function changpai_table:on_process_start(player_count)
    base_table.on_process_start(self,player_count)
end

function changpai_table:on_process_over(reason)
    self:broadcast2client("SC_Changpai_Final_Game_Over",{
        player_scores = table.series(self.players,function(p,chair)
            return {
                chair_id = chair,
                guid = p.guid,
                score = p.total_score or 0,
                money = p.total_money or 0,
                hucount =  p.statistics.hu,
                dianpaonum = p.statistics.dian_pao,
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
    self.zhuang_pai = nil

    self.cur_state_FSM = nil
    self.qie_pai = nil
	base_table.on_process_over(self,reason,{
        balance = total_winlose,
    })
    self.hashu = 0
    self:foreach(function(p)
        p.statistics = nil
    end)
end

function changpai_table:ding_zhuang()
    if not self.zhuang then
        return
    end

    local hu_count = table.sum(self.players,function(p) return p.hu and 1 or 0 end)
    if hu_count == 0 then
        return
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

function changpai_table:first_zhuang()
    local max_chair,_ = table.max(self.players,function(_,i) return i end)
    local chair
    repeat
        chair = math.random(1,max_chair)
        local p = self.players[chair]
    until p

    return chair
end

function changpai_table:tile_count_2_tiles(counts,excludes)
    local tiles = {}
    for t,c in pairs(counts) do
        local exclude_c = excludes and excludes[t] or 0
        for _ = 1,c - exclude_c do
            tinsert(tiles,t)
        end
    end

    return tiles
end

function changpai_table:is_play(...)
    return self.cur_state_FSM ~= nil
end

function changpai_table:clear_deposit_and_time_out(player)
    if player.deposit then
        player.deposit = false
        self:broadcast2client("SC_Changpai_Act_Trustee",{chair_id = player.chair_id,is_trustee = player.deposit})
    end
    player.time_out_count = 0
end

function changpai_table:increase_time_out_and_deposit(player)
    player.time_out_count = player.time_out_count or 0
    if player.time_out_count >= 2 then
        player.deposit = true
        player.time_out_count = 0
    end
end

function changpai_table:on_cs_do_action(player,msg)
    self:clear_deposit_and_time_out(player)
    
    local state_actions = {
        [FSM_S.PER_BEGIN] = {

        },
        [FSM_S.XI_PAI] = {

        },
        [FSM_S.WAIT_MO_PAI] = {

        },
        [FSM_S.WAIT_ACTION_AFTER_TIAN_HU] = {
            [ACTION.TIAN_HU] = self.on_action_after_tianhu,
            [ACTION.PASS] = self.on_action_after_tianhu
        },
        [FSM_S.WAIT_CHU_PAI] = {
            [ACTION.CHU_PAI] = self.on_action_chu_pai
        },
        [FSM_S.WAIT_ACTION_AFTER_FIRSTFIRST_TOU_PAI] = {   --发完牌的第一阶段偷牌
            [ACTION.TOU] = self.on_action_after_first_tou_pai,
            [ACTION.BA_GANG] = self.on_action_after_first_tou_pai,
            [ACTION.PASS] = self.on_action_after_first_tou_pai
        },
        [FSM_S.WAIT_ACTION_AFTER_JIN_PAI] = {   --进张有点像麻将的摸牌
            [ACTION.TOU] = self.on_action_after_mo_pai,
            [ACTION.BA_GANG] = self.on_action_after_mo_pai,
            [ACTION.PASS] = self.on_action_after_mo_pai,
            [ACTION.HU] = self.on_action_after_mo_pai,
            [ACTION.ZI_MO] = self.on_action_after_mo_pai
        },
        [FSM_S.WAIT_ACTION_AFTER_CHU_PAI] = {   --出牌
            [ACTION.PENG] = self.on_action_after_chu_pai,
            [ACTION.HU] = self.on_action_after_chu_pai,
            [ACTION.PASS] = self.on_action_after_chu_pai,
            [ACTION.CHI] = self.on_action_after_chu_pai,
        },
        [FSM_S.WAIT_ACTION_AFTER_FAN_PAI] = {   --翻牌有点像麻将的出牌
            [ACTION.BA_GANG] = self.on_action_after_fan_pai,
            [ACTION.PASS] = self.on_action_after_fan_pai,
            [ACTION.ZI_MO] = self.on_action_after_fan_pai,
            [ACTION.CHI] = self.on_action_after_fan_pai,
            [ACTION.PENG] = self.on_action_after_fan_pai,
            [ACTION.HU] = self.on_action_after_fan_pai,
        },
        [FSM_S.WAIT_QIANG_GANG_HU] = {          --抢巴胡有点像麻将的抢杠胡
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
        log.error("unkown state but got action %s fsm %d",msg.action,self.cur_state_FSM)
    end
end

--打牌
function changpai_table:on_cs_act_discard(player, msg)
    if msg and msg.tile and mj_util.check_tile(msg.tile) then
        self:clear_deposit_and_time_out(player)
    end
    self:lockcall(function() self:on_action_chu_pai(player,msg) end)
end


function changpai_table:chu_pai_player()
    return self.players[self.chu_pai_player_index]
end

function changpai_table:broadcast_player_hu(player,action,target,session_id)
    
    local msg = {
        chair_id = player.chair_id, 
        value_tile = player.hu.tile,
        action = action,
        target_chair_id = target,
        session_id = session_id,
        
    }

    self:broadcast2client("SC_Changpai_Do_Action",msg)
end

function changpai_table:update_state(new_state)
    self.cur_state_FSM = new_state
    
end

function changpai_table:is_action_time_out()
    local time_out = (os.time() - self.last_action_change_time_stamp) >= def.ACTION_TIME_OUT
    return time_out
end

function changpai_table:next_player_index(from)
    self:done_last_action(self.players[self.chu_pai_player_index])
    local chair = from and from.chair_id or self.chu_pai_player_index
    repeat
        chair = (chair % self.chair_count) + 1
        local p = self.players[chair]
    until p and not p.hu
    self.chu_pai_player_index = chair
   
end

function changpai_table:jump_to_player_index(player)
    local chair_id = type(player) == "number" and player or player.chair_id
    self.chu_pai_player_index = chair_id
    
end

function changpai_table:adjust_shou_pai(player, action, tile,othertile,session_id)
    local shou_pai = player.pai.shou_pai
    local ming_pai = player.pai.ming_pai
    if action == ACTION.BA_GANG then  --巴杠      
        for k,s in pairs(ming_pai) do
            if s.tile == tile and (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU) then
                local num = 1
                if mj_util.tile_hong(tile)>0 then num =2 end
                tinsert(ming_pai,{
                    type = SECTION_TYPE.BA_GANG,
                    tile = tile,
                    area = TILE_AREA.MING_TILE,
                    whoee = s.whoee,
                    tuos = num,
                    time = timer.nanotime(),
                })
                ming_pai[k] = nil
                table.decr(shou_pai,tile)
                break
            end
        end
        
    end

    if action == ACTION.PENG then
        table.decr(shou_pai,tile,2)
        local num = 3
        if mj_util.tile_hong(tile)>0 then num =6 end
        tinsert(ming_pai,{
            type = SECTION_TYPE.PENG,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            tuos = num,
            whoee = self.chu_pai_player_index,
        })
        self:set_unuse_card(player,tile)
    end
    if action == ACTION.TOU then
        table.decr(shou_pai,tile,3)
        local num = 3
        if mj_util.tile_hong(tile)>0 then num =6 end
        tinsert(ming_pai,{
            type = SECTION_TYPE.TOU,
            tile = tile,
            area = TILE_AREA.MING_TILE,
            tuos = num,
            whoee = self.chu_pai_player_index,
        })
        self:set_unuse_card(player,tile)
    end
    local chu_player =  self:chu_pai_player()
    local is_baopai = chu_player.bao_pai or nil
    local baopai =is_baopai and chu_player.bao_card  or nil
    log.dump(is_baopai)
    log.dump(chu_player.bao_card)
    if action == ACTION.CHI then
        table.decr(shou_pai,othertile,1)
        local num = 1
        if mj_util.tile_hong(tile)>0 and mj_util.tile_hong(othertile)>0 then num = 2  end
        if mj_util.tile_hong(tile)==0 and mj_util.tile_hong(othertile)==0 then num = 0 end
        tinsert(ming_pai,{
            type = SECTION_TYPE.CHI,
            tile = tile,
            othertile = othertile,
            tuos = num,
            substitute_num = baopai or nil,
            area = TILE_AREA.MING_TILE,
        })
        self:set_unuse_card(player,tile)
        --log.error("-----set_unuse_card------")
        chu_player.bao_pai = false 
    end

    if self.rec_fan_pai then self.rec_fan_pai=nil end
    if self.rec_chu_pai then self.rec_chu_pai=nil end   

    
    local cards = self:get_unusecard_list(player)  or {}           
    self:broadcast2client("SC_Changpai_Do_Action",
    {chair_id = player.chair_id,
    value_tile = tile,
    other_tile = othertile,
    action = action,
    substitute_num = baopai or nil,
    session_id = session_id,
    unusablecard = table.values(cards)
    })
    

end

--掉线，离开，自动胡牌
function changpai_table:auto_act_if_deposit(player,actions)
    
end

function changpai_table:on_chu_pai(tile)
    for _, p in pairs(self.players) do
        if p.chair_id == self.chu_pai_player_index then
            p.chu_pai = tile
            p.chu_pai_count = (p.chu_pai_count or 0) + 1
        else
            p.chu_pai = nil
        end
    end
    self.rec_chu_pai = {chair_id = self.chu_pai_player_index , pai = tile}
    self.rec_fan_pai = {}
end
function changpai_table:on_user_fan_pai(tile)
    for _, p in pairs(self.players) do
        if p.chair_id == self.chu_pai_player_index then
            p.fan_pai = tile
           
        else
            p.fan_pai = nil
        end
    end
    self.rec_chu_pai = {}
    self.rec_fan_pai = {chair_id = self.chu_pai_player_index , pai = tile}
end
function changpai_table:get_last_chu_pai()
    for _,p in pairs(self.players) do
        if p.chu_pai then
            return p,p.chu_pai
        end
    end
end

function changpai_table:send_data_to_enter_player(player,is_reconnect)
    local fan_pai={}
    local chu_pai={}
    if self.rec_fan_pai then
        fan_pai.chair_id =self.rec_fan_pai and self.rec_fan_pai.chair_id or nil
        fan_pai.card =self.rec_fan_pai and self.rec_fan_pai.pai or nil
    end
    if self.chu_pai then
        chu_pai.chair_id = self.rec_chu_pai and self.rec_chu_pai.chair_id or nil
        chu_pai.card = self.rec_chu_pai and self.rec_chu_pai.pai or nil
    end
    local msg = {
        state = self.cur_state_FSM,
        round = self.cur_round,
        zhuang = self.zhuang or nil , 
        zhuang_pai = self.zhuang_pai or nil,   
        self_chair_id = player.chair_id,
        act_time_limit = def.ACTION_TIME_OUT,
        decision_time_limit = def.ACTION_TIME_OUT,
        is_reconnect = is_reconnect,
        pb_players = {},
        qie_pai = self.qie_pai,
        last_fan_pai = fan_pai,
        last_chu_pai = chu_pai,
    }


      
    self:foreach(function(v)

        local cards = self:get_unusecard_list(v)  or {} 
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
        if player.chair_id == v.chair_id then
            tplayer.tuos = v.pai and mj_util.tuos(v.pai,nil,nil,nil) or 0
        else
            tplayer.tuos = v.pai and mj_util.ming_tuos(v.pai) or 0
        end
        
        tplayer.unusablecard = table.values(cards)
        tinsert(msg.pb_players,tplayer)
    end)



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
            total_scores = strtotal_scores, -- table.keys(table.map(self.players,function(p,chair) return chair,p.total_score end)),
            total_money = strtotal_money, -- table.map(self.players,function(p,chair) return chair,p.total_money end)),
        }
        log.dump(msg.pb_rec_data,"is_reconnect_"..tostring(player.guid))
    end

    if self.cur_round and self.cur_round > 0 then
        send2client(player,"SC_Changpai_Desk_Enter",msg)
    end
end

function changpai_table:send_hu_status(player)
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

    send2client(player,"SC_CP_HuStatus",{
        status = status,
    })
end

function changpai_table:reconnect(player)
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


    if self.cur_state_FSM == FSM_S.WAIT_CHU_PAI then
        self:on_reconnect_when_chu_pai(player)    
    elseif self.cur_state_FSM == FSM_S.WAIT_ACTION_AFTER_TIAN_HU then
        self:on_reconnect_when_tian_hu(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_ACTION_AFTER_FIRSTFIRST_TOU_PAI then
        self:on_reconnect_when_first_tou_pai(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_ACTION_AFTER_CHU_PAI then
        self:on_reconnect_when_action_after_chu_pai(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_ACTION_AFTER_FAN_PAI then
        self:on_reconnect_when_action_after_fan_pai(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_ACTION_AFTER_JIN_PAI then
        self:on_reconnect_when_action_after_mo_pai(player)
    elseif self.cur_state_FSM == FSM_S.WAIT_QIANG_GANG_HU then
        self:on_reconnect_when_action_qiang_gang_hu(player)    
    end

    --self:send_hu_status(player)

    base_table.reconnect(self,player)
end

function changpai_table:begin_clock(timeout,player,total_time)
    if player then
        send2client(player,"SC_TimeOutNotify",{
            left_time = math.ceil(timeout),
            total_time = total_time and math.floor(total_time) or nil,
        })
        return
    end

    self:broadcast2client("SC_TimeOutNotify",{
        left_time = math.ceil(timeout),
        total_time =total_time and  math.ceil(total_time) or nil,
    })
end

function changpai_table:ext_hu(player,mo_pai,qiang_gang)
    local types = {}

    local chu_pai_player = self:chu_pai_player()

    if self.rule.play.tian_di_hu then
        if player.chair_id == self.zhuang and mo_pai and self.mo_pai_count == 1 then
            types[HU_TYPE.TIAN_HU] = 1
        end

        if player.chair_id ~= self.zhuang and player.mo_pai_count <= 1 and player.chu_pai_count == 0 and table.nums(player.pai.ming_pai) == 0 then
            types[HU_TYPE.DI_HU] = 1
        end
    end

    local dgh_dian_pao = self.rule.play.dgh_dian_pao
    local discarder_last_action = chu_pai_player.last_action
    return types
end

function changpai_table:rule_hu_types(pai,in_pai,mo_pai,is_zhuang)
    local private_conf = self:room_private_conf()
    local hu_types = mj_util.hu(pai,in_pai,mo_pai,is_zhuang)
  
    return table.series(hu_types,function(ones)
        local ts = {}
        for t,c in pairs(ones) do
            ts[t] = c
        end
        return ts
    end)
end

function changpai_table:rule_hu(pai,in_pai,mo_pai,is_zhuang)
    local types = self:rule_hu_types(pai,in_pai,mo_pai,is_zhuang)
    local type =0
    for key, types in pairs(types) do 
        if types then
            for key, value in pairs(types) do
                if value then
                    type =  key 
                end
            end
        return type   
        end
    end
    return {}
end

function changpai_table:hu(player,in_pai,mo_pai,qiang_gang)
    local rule_hu = self:rule_hu(player.pai,in_pai,mo_pai,player.chair_id==self.zhuang)
    return rule_hu
end

function changpai_table:is_hu(pai,in_pai,is_zhuang)
    return mj_util.is_hu(pai,in_pai,is_zhuang)
end

function changpai_table:can_hu(player,in_pai,mo_pai,qiang_gang)
    return self:is_hu(player.pai,in_pai,player.chair_id==self.zhuang)
end

function changpai_table:get_ting_tiles_info(player)
    self:lockcall(function()
        local hu_tips = self.rule and self.rule.play.hu_tips or nil
        if not hu_tips then 
            send2client(player,"SC_ChangpaiGetTingTilesInfo",{
                result = enum.ERROR_OPERATION_INVALID,
            })
            return
        end

        if player.hu then 
            send2client(player,"SC_ChangpaiGetTingTilesInfo",{
                result = enum.ERROR_OPERATION_INVALID,
            })
            return
        end
        
        local ting_tiles = self:ting(player)
        local hu_tile_fans = table.series(ting_tiles or {},function(_,tile)
            return {tile = tile,fan = self:hu_fan(player,tile)} 
        end)

        send2client(player,"SC_ChangpaiGetTingTilesInfo",{
            tiles_info = hu_tile_fans,
        })
    end)
end

function changpai_table:global_status_info(type)
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
    -- table:info:123456 房间信息
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
function changpai_table:get_anti_cheat()
    local info = base_table.get_anti_cheat(self)
    return info
end 
return changpai_table