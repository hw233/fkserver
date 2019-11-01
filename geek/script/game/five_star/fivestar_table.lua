-- 五星宏辉逻辑
local pb = require "pb_files"

local base_table = require "game.lobby.base_table"
require "game.net_func"
require "game.five_star.fivestar_robot"
local send2client_pb = send2client_pb
local random = require "random"
require "game.lobby.base_bonus"
local json = require "cjson"
local log = require "log"

require "timer"
local add_timer = add_timer

local offlinePunishment_flag = false

local LOG_MONEY_OPT_TYPE_FIVESTAR = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_FIVESTAR")
-- enum LAND_CARD_TYPE
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

local fivestar_table = base_table:new()



--0  0： 方块A ， 1： 梅花A ， 2： 红桃A ， 3： 黑桃A
--1  4： 方块2 ， 5： 梅花2 ， 6： 红桃2 ， 7： 黑桃2
--2  8： 方块3 ， 9： 梅花3 ， 10：红桃3 ， 11：黑桃3
--3  12：方块4 ， 13：梅花4 ， 14：红桃4 ， 15：黑桃4
--4  16：方块5 ， 17：梅花5 ， 18：红桃5 ， 19：黑桃5
--5  20：方块6 ， 21：梅花6 ， 22：红桃6 ， 23：黑桃6
--6  24：方块7 ， 25：梅花7 ， 26：红桃7 ， 27：黑桃7
--7  28：方块8 ， 29：梅花8 ， 30：红桃8 ， 31：黑桃8
--8  32：方块9 ， 33：梅花9 ， 34：红桃9 ， 35：黑桃9
--9  36：方块10， 37：梅花10， 38：红桃10， 39：黑桃10
--10 40：方块J ， 41：梅花J ， 42：红桃J ， 43：黑桃J
--11 44：方块Q ， 45：梅花Q ， 46：红桃Q ， 47：黑桃Q
--12 48：方块K ， 49：梅花K ， 50：红桃K ， 51：黑桃K
--13 52: 小王  ， 53: 大王


local FiveStar_Color_Spade = 1              --黑桃
local FiveStar_Color_Heart = 2              --红心
local FiveStar_Color_Diamond = 3            --梅花
local FiveStar_Color_Club = 4               --方块
local FiveStar_Color_King = 5               --大小王
local FiveStar_Color_Kill = -1              --必杀



-- 初始化
function fivestar_table:init(room, table_id, chair_count)
    -- =====================================================================================
    -- 空闲时间(游戏状态)
    self.FIVESTAR_STATUS_FREE = 1
        -- 开始游戏倒记时(时间长度)
        self.fivestar_time_start_countdown = 3
    -- 下注时间(游戏状态)
    self.FIVESTAR_STATUS_BETTING = 2
        -- 押注阶段倒记时(时间长度)
        self.fivestar_time_betting_countdown = 12
    -- 结算(游戏状态)
    self.FIVESTAR_STATUS_SETTLEMENT = 3
        -- 结算倒记时(发牌与结束时间合)
        self.fivestar_time_settlement_countdown = 10
    -- 记录历史最大数量
    self.history_max = 1000
    -- 单次下注最小金额
    self.bet_limit = 100
    -- 单区下注最大金额
    self.bet_max = 1000000
    -- 所有区总合下注金额（所有玩家共用）
    self.bet_all_max = 10000000
    -- 日志等级
    self.logLevel = 2
    -- 显示玩家数量
    self.show_playersmax = 10
    -- 幸运星计算次数
    self.luck_count_num = 5
    -- 显示幸运星玩家数量
    self.show_luck_playersmax = 10
    -- 大赢家阀值
    self.big_win_limit = 200000
    -- 大赢家记录历史最大数量
    self.big_win_history_max = 50
    -- 广播阈值
    self.grand_base = self.big_win_limit

    -- 概率顺序为 必杀-大小王-黑-红-梅-方
    -- 必杀机率
    self.kill_Chance = 5
    -- 大小王机率
    self.king_Chance = 3
    -- 黑桃
    self.spade_Chance = 23
    -- 红桃
    self.heart_Chance = 23
    -- 梅花
    self.diamond_Chance = 23
    -- 方块
    self.club_Chance = 23
    -- 赔率
    self.fivestar_times = {}
    self.fivestar_times[FiveStar_Color_Spade] = 3.8
    self.fivestar_times[FiveStar_Color_Heart] = 3.8
    self.fivestar_times[FiveStar_Color_Diamond] = 4
    self.fivestar_times[FiveStar_Color_Club] = 4
    self.fivestar_times[FiveStar_Color_King] = 3

    self.playerinfo = {}
    self.playerLuckinfo = {}

    -- 机器人设置
    self.robot_threshold = {
        playerless = 6,             -- 玩家+机器人 小于时添加机器人阀值
        playergreater = 25,         -- 玩家+机器人 大于时删除机器人阀值
        add_min = 6,                -- 添加最小数量(人+机器人)
        add_max = 10,               -- 添加最大数量(人+机器人)
        win_exit = 1,              -- 赢钱后退出机率(百分率)
        loss_exit = 5,             -- 输钱后退出机率(百分率)
        notbet_exit = 1,            -- 未下注退出机率(百分率)
        money_min = 30000,          -- 机器人初始最小金额300
        money_max = 150000,         -- 机器人初始最大金额1500
        money_threshold = 10000,    -- 机器人金钱退出阀值（小于即退出）
        King_time = {
            times = 5,              -- 下注概率
            bet_time = 1,           -- 下注次数
            betinfo = {             -- 下注信息
                [1000] = 50,          -- key对应金额下注概率
                [2000] = 50,          -- key对应金额下注概率
            },
        },
        Spade_time = {
            times = 15,             -- 下注概率
            bet_time = 2,           -- 下注次数
            betinfo = {             -- 下注信息
                [1000] = 40,          -- key对应金额下注概率
                [2000] = 30,          -- key对应金额下注概率
                [5000] = 20,          -- key对应金额下注概率
                [10000] = 10,         -- key对应金额下注概率
            },
        },
        Heart_time = {
            times = 15,             -- 下注概率
            bet_time = 2,           -- 下注次数
            betinfo = {             -- 下注信息
                [1000] = 40,          -- key对应金额下注概率
                [2000] = 30,          -- key对应金额下注概率
                [5000] = 20,          -- key对应金额下注概率
                [10000] = 10,         -- key对应金额下注概率
            },
        },
        Diamond_time = {
            times = 15,             -- 下注概率
            bet_time = 2,           -- 下注次数
            betinfo = {             -- 下注信息
                [1000] = 40,          -- key对应金额下注概率
                [2000] = 30,          -- key对应金额下注概率
                [5000] = 20,          -- key对应金额下注概率
                [10000] = 10,         -- key对应金额下注概率
            },
        },
        Club_time = {
            times = 15,             -- 下注概率
            bet_time = 2,           -- 下注次数
            betinfo = {             -- 下注信息
                [1000] = 40,          -- key对应金额下注概率
                [2000] = 30,          -- key对应金额下注概率
                [5000] = 20,          -- key对应金额下注概率
                [10000] = 10,         -- key对应金额下注概率
            },
        },
    }


    self.bet_num_list = {
        [1] = 100,
        [2] = 1000,
        [3] = 5000,
        [4] = 10000,
        [5] = 50000,
        [6] = 100000,
    }


    self.history_cards = {}
    self.big_win_history = {}

    base_table.init(self, room, table_id, chair_count)
    self:init_status()

    self.android_list = {}
    self.android_guid = 0
    self.android_guid_title = string.format("%d%d%d000",def_game_id, self.room_.id, self.table_id_)
    self.android_bet_times = (self.robot_threshold.King_time.times + self.robot_threshold.Spade_time.times + self.robot_threshold.Heart_time.times + self.robot_threshold.Diamond_time.times + self.robot_threshold.Club_time.times )/ self.fivestar_time_betting_countdown -- 每秒下注概率
end


function fivestar_table:SendServerStatus( player )

    local l_time = 0
    if self.status == self.FIVESTAR_STATUS_FREE then
        l_time = self.fivestar_time_start_countdown  - (get_second_time() - self.timer)
    elseif self.status == self.FIVESTAR_STATUS_BETTING then
        l_time = self.fivestar_time_betting_countdown  - (get_second_time() - self.timer)
    elseif self.status == self.FIVESTAR_STATUS_SETTLEMENT then
        l_time = self.fivestar_time_settlement_countdown  - (get_second_time() - self.timer)
    end
    log.info("status [%d] left_time [%d]" , self.status , l_time)

    -- 空闲时间(游戏状态)
    --self.FIVESTAR_STATUS_FREE = 1
    --    -- 开始游戏倒记时(时间长度)
    --    self.fivestar_time_start_countdown = 3
    ---- 下注时间(游戏状态)
    --self.FIVESTAR_STATUS_BETTING = 2
    --    -- 押注阶段倒记时(时间长度)
    --    self.fivestar_time_betting_countdown = 20
    ---- 结算(游戏状态)
    --self.FIVESTAR_STATUS_SETTLEMENT = 3
    --    -- 结算倒记时(发牌与结束时间合)
    --    self.fivestar_time_settlement_countdown = 15


    local notify = {
        game_status = self.status,
        left_time = l_time,
    }

    if player then
        return self.status , l_time
    else
        self:broadcast2client("SC_FiveStarServerStatuse", notify)
    end
end


function fivestar_table:load_lua_cfg()
    self:log_important(string.format("fivestar_table:load_lua_cfg : [%s] ",self.room_.room_cfg))
    local fivestar_config = json.decode(self.room_.room_cfg)
    if fivestar_config then
        -- 开始游戏倒记时(时间长度)
        if fivestar_config.fivestar_time_start_countdown then
            self.fivestar_time_start_countdown = fivestar_config.fivestar_time_start_countdown
        end
        -- 押注阶段倒记时(时间长度)
        if fivestar_config.fivestar_time_betting_countdown then
            self.fivestar_time_betting_countdown = fivestar_config.fivestar_time_betting_countdown
        end
        -- 结算倒记时(发牌与结束时间合)
        if fivestar_config.fivestar_time_settlement_countdown then
            self.fivestar_time_settlement_countdown = fivestar_config.fivestar_time_settlement_countdown
        end
        -- 记录历史最大数量
        if fivestar_config.history_max then
            self.history_max = fivestar_config.history_max
        end
        -- 单次下注最小金额
        if fivestar_config.bet_limit then
            self.bet_limit = fivestar_config.bet_limit
        end
        -- 单区下注最大金额
        if fivestar_config.bet_max then
            self.bet_max = fivestar_config.bet_max
        end
        -- 所有区总合下注金额（所有玩家共用）
        if fivestar_config.bet_all_max then
            self.bet_all_max = fivestar_config.bet_all_max
        end
        -- 日志等级
        if fivestar_config.logLevel then
            self.logLevel = fivestar_config.logLevel
        end
        -- 显示玩家数量
        if fivestar_config.show_playersmax then
            self.show_playersmax = fivestar_config.show_playersmax
        end

        -- 幸运星计算次数
        if fivestar_config.luck_count_num then
            self.luck_count_num = fivestar_config.luck_count_num
        end
        -- 显示幸运星玩家数量
        if fivestar_config.show_luck_playersmax then
            self.show_luck_playersmax = fivestar_config.show_luck_playersmax
        end
        -- 大赢家阀值
        if fivestar_config.big_win_limit then
            self.big_win_limit = fivestar_config.big_win_limit
        end
        -- 大赢家记录历史最大数量
        if fivestar_config.big_win_history_max then
            self.big_win_history_max = fivestar_config.big_win_history_max
        end
        -- 广播阈值
        if fivestar_config.grand_base then
            self.grand_base = fivestar_config.grand_base
        end
        -- 必杀机率
        if fivestar_config.kill_Chance then
            self.kill_Chance = fivestar_config.kill_Chance
        end
        -- 大小王机率
        if fivestar_config.king_Chance then
            self.king_Chance = fivestar_config.king_Chance
        end
        -- 黑桃
        if fivestar_config.spade_Chance then
            self.spade_Chance = fivestar_config.spade_Chance
        end
        -- 红桃
        if fivestar_config.heart_Chance then
            self.heart_Chance = fivestar_config.heart_Chance
        end
        -- 梅花
        if fivestar_config.diamond_Chance then
            self.diamond_Chance = fivestar_config.diamond_Chance
        end
        -- 方块
        if fivestar_config.club_Chance then
            self.club_Chance = fivestar_config.club_Chance
        end
        -- 赔率
        if fivestar_config.fivestar_times then
            for k,v in pairs(fivestar_config.fivestar_times) do
                self.fivestar_times[tonumber(k)] = v
            end
        end

        if fivestar_config.bet_num_list then
            for k,v in pairs(fivestar_config.bet_num_list) do
                self.bet_num_list[tonumber(k)] = v
            end
            self:broadcast2client("SC_FiveStarBetNumList", {
                betnumlist = self.bet_num_list,
            })
        end
        -- 机器人设置
        if fivestar_config.robot_threshold then
            if fivestar_config.robot_threshold.playerless then
                self.robot_threshold.playerless = fivestar_config.robot_threshold.playerless                -- 玩家+机器人 小于时添加机器人阀值
            end
            if fivestar_config.robot_threshold.playergreater then
                self.robot_threshold.playergreater = fivestar_config.robot_threshold.playergreater          -- 玩家+机器人 大于时删除机器人阀值
            end
            if fivestar_config.robot_threshold.add_min then
                self.robot_threshold.add_min = fivestar_config.robot_threshold.add_min                      -- 添加最小数量(人+机器人)
            end
            if fivestar_config.robot_threshold.add_max then
                self.robot_threshold.add_max = fivestar_config.robot_threshold.add_max                      -- 添加最大数量(人+机器人)
            end
            if fivestar_config.robot_threshold.win_exit then
                self.robot_threshold.win_exit = fivestar_config.robot_threshold.win_exit                    -- 赢钱后退出机率(百分率)
            end
            if fivestar_config.robot_threshold.loss_exit then
                self.robot_threshold.loss_exit = fivestar_config.robot_threshold.loss_exit                  -- 输钱后退出机率(百分率)
            end
            if fivestar_config.robot_threshold.notbet_exit then
                self.robot_threshold.notbet_exit = fivestar_config.robot_threshold.notbet_exit              -- 未下注后退出机率(百分率)
            end
            if fivestar_config.robot_threshold.money_min then
                self.robot_threshold.money_min = fivestar_config.robot_threshold.money_min                  -- 机器人初始最小金额
            end
            if fivestar_config.robot_threshold.money_max then
                self.robot_threshold.money_max = fivestar_config.robot_threshold.money_max                  -- 机器人初始最大金额
            end
            if fivestar_config.robot_threshold.money_threshold then
                self.robot_threshold.money_threshold = fivestar_config.robot_threshold.money_threshold      -- 机器人金钱退出阀值（小于即退出）
            end
            if fivestar_config.robot_threshold.King_time then
                if fivestar_config.robot_threshold.King_time.times then
                    self.robot_threshold.King_time.times = fivestar_config.robot_threshold.King_time.times
                end
                if fivestar_config.robot_threshold.King_time.bet_time then
                    self.robot_threshold.King_time.bet_time = fivestar_config.robot_threshold.King_time.bet_time
                end
                if fivestar_config.robot_threshold.King_time.betinfo then
                    for k,v in pairs(fivestar_config.robot_threshold.King_time.betinfo) do
                        self.robot_threshold.King_time.betinfo[tonumber(k)] = v
                    end
                end
            end
            if fivestar_config.robot_threshold.Spade_time then
                if fivestar_config.robot_threshold.Spade_time.times then
                    self.robot_threshold.Spade_time.times = fivestar_config.robot_threshold.Spade_time.times
                end
                if fivestar_config.robot_threshold.Spade_time.bet_time then
                    self.robot_threshold.Spade_time.bet_time = fivestar_config.robot_threshold.Spade_time.bet_time
                end
                if fivestar_config.robot_threshold.Spade_time.betinfo then
                    for k,v in pairs(fivestar_config.robot_threshold.Spade_time.betinfo) do
                        self.robot_threshold.Spade_time.betinfo[tonumber(k)] = v
                    end
                end
            end
            if fivestar_config.robot_threshold.Heart_time then
                if fivestar_config.robot_threshold.Heart_time.times then
                    self.robot_threshold.Heart_time.times = fivestar_config.robot_threshold.Heart_time.times
                end
                if fivestar_config.robot_threshold.Heart_time.bet_time then
                    self.robot_threshold.Heart_time.bet_time = fivestar_config.robot_threshold.Heart_time.bet_time
                end
                if fivestar_config.robot_threshold.Heart_time.betinfo then
                    for k,v in pairs(fivestar_config.robot_threshold.Heart_time.betinfo) do
                        self.robot_threshold.Heart_time.betinfo[tonumber(k)] = v
                    end
                end
            end
            if fivestar_config.robot_threshold.Diamond_time then
                if fivestar_config.robot_threshold.Diamond_time.times then
                    self.robot_threshold.Diamond_time.times = fivestar_config.robot_threshold.Diamond_time.times
                end
                if fivestar_config.robot_threshold.Diamond_time.bet_time then
                    self.robot_threshold.Diamond_time.bet_time = fivestar_config.robot_threshold.Diamond_time.bet_time
                end
                if fivestar_config.robot_threshold.Diamond_time.betinfo then
                    for k,v in pairs(fivestar_config.robot_threshold.Diamond_time.betinfo) do
                        self.robot_threshold.Diamond_time.betinfo[tonumber(k)] = v
                    end
                end
            end
            if fivestar_config.robot_threshold.Club_time then
                if fivestar_config.robot_threshold.Club_time.times then
                    self.robot_threshold.Club_time.times = fivestar_config.robot_threshold.Club_time.times
                end
                if fivestar_config.robot_threshold.Club_time.bet_time then
                    self.robot_threshold.Club_time.bet_time = fivestar_config.robot_threshold.Club_time.bet_time
                end
                if fivestar_config.robot_threshold.Club_time.betinfo then
                    for k,v in pairs(fivestar_config.robot_threshold.Club_time.betinfo) do
                        self.robot_threshold.Club_time.betinfo[tonumber(k)] = v
                    end
                end
            end
        end
    else
        self:log_error_msg("fivestar_config is nil")
    end

    self:log_important(string.format([[
        fivestar_time_start_countdown [%d] fivestar_time_betting_countdown[%d] fivestar_time_settlement_countdown[%d] history_max[%d] bet_limit[%d] bet_max[%d] bet_all_max[%d] logLevel[%d] show_playersmax[%d]
        kill_Chance[%d] king_Chance[%d] spade_Chance[%d] heart_Chance[%d] diamond_Chance[%d] club_Chance[%d] spade_times[%f] heart_times[%f] diamond_times[%f] club_times[%f] King_times[%f] 
        big_win_limit[%d] , big_win_history_max[%d] , grand_base[%d] ,show_luck_playersmax[%d] ,luck_count_num [%d]
        robot_threshold { playerless[%d] playergreater[%d] add_min[%d] add_max[%d] win_exit[%d] loss_exit[%d] notbet_exit[%d] money_min[%d] money_max[%d] money_threshold[%d] }
        ]]
        , self.fivestar_time_start_countdown , self.fivestar_time_betting_countdown , self.fivestar_time_settlement_countdown , self.history_max , self.bet_limit , self.bet_max , self.bet_all_max , self.logLevel , self.show_playersmax,
        self.kill_Chance , self.king_Chance , self.spade_Chance , self.heart_Chance , self.diamond_Chance , self.club_Chance ,
        self.fivestar_times[FiveStar_Color_Spade] , self.fivestar_times[FiveStar_Color_Heart] , self.fivestar_times[FiveStar_Color_Diamond] , self.fivestar_times[FiveStar_Color_Club] , self.fivestar_times[FiveStar_Color_King],
        self.big_win_limit , self.big_win_history_max , self.grand_base, self.show_luck_playersmax,self.luck_count_num,
        self.robot_threshold.playerless,self.robot_threshold.playergreater,self.robot_threshold.add_min,self.robot_threshold.add_max,self.robot_threshold.win_exit,self.robot_threshold.loss_exit,self.robot_threshold.notbet_exit,
        self.robot_threshold.money_min,self.robot_threshold.money_max,self.robot_threshold.money_threshold
    ))

    self:log_important(string.format("King_time times[%d] bet_time[%d]",self.robot_threshold.King_time.times,self.robot_threshold.King_time.bet_time))
    for k,v in pairs(self.robot_threshold.King_time.betinfo) do
        self:log_important(string.format("King_time [%d] = [%d]", k , v))
    end
    self:log_important(string.format("Spade_time times[%d] bet_time[%d]",self.robot_threshold.Spade_time.times,self.robot_threshold.Spade_time.bet_time))
    for k,v in pairs(self.robot_threshold.Spade_time.betinfo) do
        self:log_important(string.format("Spade_time [%d] = [%d]", k , v))
    end
    self:log_important(string.format("Heart_time times[%d] bet_time[%d]",self.robot_threshold.Heart_time.times,self.robot_threshold.Heart_time.bet_time))
    for k,v in pairs(self.robot_threshold.Heart_time.betinfo) do
        self:log_important(string.format("Heart_time [%d] = [%d]", k , v))
    end
    self:log_important(string.format("Diamond_time times[%d] bet_time[%d]",self.robot_threshold.Diamond_time.times,self.robot_threshold.Diamond_time.bet_time))
    for k,v in pairs(self.robot_threshold.Diamond_time.betinfo) do
        self:log_important(string.format("Diamond_time [%d] = [%d]", k , v))
    end
    self:log_important(string.format("Club_time times[%d] bet_time[%d]",self.robot_threshold.Club_time.times,self.robot_threshold.Club_time.bet_time))
    for k,v in pairs(self.robot_threshold.Club_time.betinfo) do
        self:log_important(string.format("Club_time [%d] = [%d]", k , v))
    end

    self.android_bet_times = (self.robot_threshold.King_time.times + self.robot_threshold.Spade_time.times + self.robot_threshold.Heart_time.times + self.robot_threshold.Diamond_time.times + self.robot_threshold.Club_time.times )/ self.fivestar_time_betting_countdown -- 每秒下注概率
    self:check_player_num()
end

function fivestar_table:robot_exit( guid )
    -- body
    self.android_list[guid] = nil
end

function fivestar_table:android_bet()
    if getNum(self.android_list) > 0 then
        for _,v in pairs(self.android_list) do
            repeat
                local  bet_time_temp = random.boost_integer(1,100)
                if bet_time_temp < self.android_bet_times then -- 下注
                    bet_time_temp = random.boost_integer(1,self.robot_threshold.King_time.times + self.robot_threshold.Spade_time.times + self.robot_threshold.Heart_time.times + self.robot_threshold.Diamond_time.times + self.robot_threshold.Club_time.times)
                    bet_time_temp = bet_time_temp - self.robot_threshold.King_time.times
                    if bet_time_temp <= 0 then
                        if self.color_list[FiveStar_Color_King].Android_bet_times_list[v.guid] and self.color_list[FiveStar_Color_King].Android_bet_times_list[v.guid] > self.robot_threshold.King_time.bet_time then
                            break
                        end
                        local bet_money_time = random.boost_integer(1,100)
                        local android_bet_money = 0
                        for k,v in pairs(self.robot_threshold.King_time.betinfo) do
                            bet_money_time = bet_money_time - v
                            if bet_money_time <= 0 then
                                android_bet_money = k
                                break
                            end
                        end
                        self:android_bet_color(v , FiveStar_Color_King , android_bet_money)
                        break
                    end
                    bet_time_temp = bet_time_temp - self.robot_threshold.Spade_time.times
                    if bet_time_temp <= 0 then
                        if self.color_list[FiveStar_Color_Spade].Android_bet_times_list[v.guid] and self.color_list[FiveStar_Color_Spade].Android_bet_times_list[v.guid] > self.robot_threshold.Spade_time.bet_time then
                            break
                        end
                        local bet_money_time = random.boost_integer(1,100)
                        local android_bet_money = 0
                        for k,v in pairs(self.robot_threshold.Spade_time.betinfo) do
                            bet_money_time = bet_money_time - v
                            if bet_money_time <= 0 then
                                android_bet_money = k
                                break
                            end
                        end
                        self:android_bet_color(v , FiveStar_Color_Spade , android_bet_money)
                        break
                    end
                    bet_time_temp = bet_time_temp - self.robot_threshold.Heart_time.times
                    if bet_time_temp <= 0 then
                        if self.color_list[FiveStar_Color_Heart].Android_bet_times_list[v.guid] and self.color_list[FiveStar_Color_Heart].Android_bet_times_list[v.guid] > self.robot_threshold.Heart_time.bet_time then
                            break
                        end
                        local bet_money_time = random.boost_integer(1,100)
                        local android_bet_money = 0
                        for k,v in pairs(self.robot_threshold.Heart_time.betinfo) do
                            bet_money_time = bet_money_time - v
                            if bet_money_time <= 0 then
                                android_bet_money = k
                                break
                            end
                        end
                        self:android_bet_color(v , FiveStar_Color_Heart , android_bet_money)
                        break
                    end
                    bet_time_temp = bet_time_temp - self.robot_threshold.Diamond_time.times
                    if bet_time_temp <= 0 then
                        if self.color_list[FiveStar_Color_Diamond].Android_bet_times_list[v.guid] and self.color_list[FiveStar_Color_Diamond].Android_bet_times_list[v.guid] > self.robot_threshold.Diamond_time.bet_time then
                            break
                        end
                        local bet_money_time = random.boost_integer(1,100)
                        local android_bet_money = 0
                        for k,v in pairs(self.robot_threshold.Diamond_time.betinfo) do
                            bet_money_time = bet_money_time - v
                            if bet_money_time <= 0 then
                                android_bet_money = k
                                break
                            end
                        end
                        self:android_bet_color(v , FiveStar_Color_Diamond , android_bet_money)
                        break
                    else
                    -- end
                    -- bet_time_temp = bet_time_temp - self.robot_threshold.Club_time.times
                    -- if bet_time_temp < 0 then
                        if self.color_list[FiveStar_Color_Club].Android_bet_times_list[v.guid] and self.color_list[FiveStar_Color_Club].Android_bet_times_list[v.guid] > self.robot_threshold.Club_time.bet_time then
                            break
                        end
                        local bet_money_time = random.boost_integer(1,100)
                        local android_bet_money = 0
                        for k,v in pairs(self.robot_threshold.Club_time.betinfo) do
                            bet_money_time = bet_money_time - v
                            if bet_money_time <= 0 then
                                android_bet_money = k
                                break
                            end
                        end
                        self:android_bet_color(v , FiveStar_Color_Club , android_bet_money)
                    end
                end
            until(true)
        end
    end
end

function fivestar_table:Android_check()
    if getNum(self.android_list) > 0 then
        for k,v in pairs(self.android_list) do
            repeat
                if v.money < self.robot_threshold.money_threshold then
                    -- 身上金钱低于阀值退出
                    self:robot_exit(k)
                    break
                end
                local temp_exit_time = random.boost_integer(1,100)
                if v.win_or_loss == 1 then
                    if temp_exit_time < self.robot_threshold.win_exit then
                        -- 赢钱后退出
                        self:robot_exit(k)
                        break
                    end
                end
                if v.win_or_loss == 2 then
                    if temp_exit_time < self.robot_threshold.loss_exit then
                        -- 赢钱后退出
                        self:robot_exit(k)
                        break
                    end
                end
                if v.win_or_loss == 0 then
                    if temp_exit_time < self.robot_threshold.notbet_exit then
                        -- 未下注后退出
                        self:robot_exit(k)
                        break
                    end
                end
                v.win_or_loss = 0
            until(true)
        end
    end
end

function fivestar_table:Refresh_player_listInfo()
    self.playerinfo = {}
    self.playerLuckinfo = {}
    for k,v in pairs(self.players) do
        if v then
            local money = v:get_money()
            local headericon = v:get_header_icon()
            local rateofwin = v.luck_list and v.luck_list.rateofwin * 100 or 0
            local winmoney = v.luck_list and v.luck_list.winmoney * 100 or 0

            table.insert(self.playerinfo, {guid = v.guid,head_id = headericon,money = money, header_icon = headericon,ip_area = v.ip_area})
            table.insert(self.playerLuckinfo , {guid = v.guid,head_id = headericon,money = money, header_icon = headericon,ip_area = v.ip_area, rateofwin = rateofwin , winmoney = winmoney })
        end
    end
    if self.android_list then
        for k,v in pairs(self.android_list) do
            if v then
                local money = v:get_money()
                local headericon = v:get_header_icon()
                local rateofwin = v.luck_list and v.luck_list.rateofwin * 100 or 0
                local winmoney = v.luck_list and v.luck_list.winmoney * 100 or 0
                table.insert(self.playerinfo, {guid = v.guid,head_id = headericon,money = money, header_icon = headericon,ip_area = v.ip_area})
                table.insert(self.playerLuckinfo , {guid = v.guid,head_id = headericon,money = money, header_icon = headericon,ip_area = v.ip_area, rateofwin = rateofwin , winmoney = winmoney })
            end
        end
    end
    table.sort(self.playerinfo, function (a, b)
        if a.money == b.money then
            return a.guid < b.guid
        else
            return a.money > b.money
        end
    end)

    table.sort(self.playerLuckinfo, function (a, b)
        if a.rateofwin == b.rateofwin then
            return a.winmoney > b.winmoney
        else
            return a.rateofwin > b.rateofwin
        end
    end)
end

--玩家站起离开房间
function fivestar_table:player_stand_up(player, is_offline)
    --print(debug.traceback())
    local player_guid =  player.guid
    self:log_msg(string.format(" player_stand_uptable id[%d] guid[%s]",self.table_id_,tostring(player.guid)))
    if is_offline then
        player.in_game = false
    end
    local ret = base_table.player_stand_up(self,player, is_offline)
    if ret then
        self:Refresh_player_listInfo()
        self:update_player_listInfo()
    end
    return ret
end

function fivestar_table:update_player_listInfo(player)
    -- body
    local player_info_list_temp = {}
    for i=1,self.show_playersmax do
        local x = self.playerinfo[i]
        if x == nil then
            break
        end
        table.insert(player_info_list_temp,x)
    end
    local notify = {
        top_player_total = getNum(self.playerinfo),
        pb_player_info_list = player_info_list_temp,
    }
    local luck_notify = {
        pb_luck_player_list = self.playerLuckinfo
    }
    if not player then
        self:broadcast2client("SC_FiveStarPlayerList", notify)
        self:broadcast2client("SC_FiveStarLuckPlayerList", luck_notify)
    else
        send2client_pb(player,"SC_FiveStarPlayerList", notify)
        self:broadcast2client("SC_FiveStarLuckPlayerList", luck_notify)
    end
end

function fivestar_table:check_player_num()
    self:log_msg(string.format("fivestar_table:check_player_num androidNO [%d] #self.players[%d]  self.robot_threshold.playerless[%d]" , getNum(self.android_list) , getNum(self.players) ,  self.robot_threshold.playerless))
    -- body

    if getNum(self.android_list) + getNum(self.players) < self.robot_threshold.playerless then
        local num = random.boost_integer(self.robot_threshold.add_min,self.robot_threshold.add_max)
        if self.android_guid + num > 1000 - 1 then
            self.android_guid = 0
        end
        self:log_msg(string.format("android add num %d",num))
        for i = 1, num do
            for j = self.android_guid,1000 do
                local robot_guid_temp = -1 * (tonumber(self.android_guid_title) + j)
                if not self.android_list[robot_guid_temp] then
                    local robot_temp = fivestar_robot:creat_robot( robot_guid_temp ,random.boost_integer(self.robot_threshold.money_min,self.robot_threshold.money_max))
                    self.android_list[robot_guid_temp] = robot_temp
                    self.android_guid = j + 1
                    break
                end
            end
        end
    end

    if getNum(self.android_list) + getNum(self.players) > self.robot_threshold.playergreater then
        self.android_list = {}
        self.android_guid = 0
    end
end

-- 请求游戏数据
function fivestar_table:get_playerInfo( player )
    -- body


    local status,l_time = self:SendServerStatus(player)

    local notify_player_info = {
        pb_player = {},
        pb_allplayer = {},
        game_status = status,
        left_time = l_time,
        bet_max = self.bet_max,
        bet_all_max = self.bet_all_max,
    }

    if self.status == self.FIVESTAR_STATUS_BETTING then
        if self.player_bet_list[player.is_android and player.guid or player.chair_id] then
            -- 玩家本局下过注
            for k,v in pairs(self.player_bet_list[player.is_android and player.guid or player.chair_id]) do
                local data_temp = {
                    color = k,
                    bet_sum = v,
                }
                table.insert(notify_player_info.pb_player,data_temp)
            end
        end
        for k,v in pairs(self.color_list) do
            local data_temp = {
                color = k,
                bet_sum = v.bet_player_sum + v.bet_android_sum,
            }
            table.insert(notify_player_info.pb_allplayer,data_temp)
        end
    end
    player.in_game = true


    if self.status >= self.FIVESTAR_STATUS_SETTLEMENT then
        local Settlement_all = deepcopy(self.notify_all)
        send2client_pb(player,"SC_FiveStarSettlement_all" , Settlement_all)

        local  notify = self.SC_FiveStarSettlement[player.guid]
        send2client_pb(player, "SC_FiveStarSettlement", notify)
    end

    send2client_pb(player,"SC_FiveStarBetNumList" , { betnumlist = self.bet_num_list, })

    send2client_pb(player,"SC_GetPlayInfo",notify_player_info)
    self:update_player_listInfo(player)

end

function fivestar_table:send_maintain_player()
    -- body
    self:log_msg(string.format("================== fivestar_table:send_maintain_player ====================  game_name = [%s] gameid = [%d] game_switch_is_open[%d] get_db_status[%d] game_switch[%d] will maintain.....................",self.def_game_name,self.def_game_id,self.room_.game_switch_is_open,get_db_status(),game_switch))

    local iRet = false

    for i,v in pairs (self.players) do
        if  v and v.is_player == true and v.vip ~= 100 then
            send2client_pb(v, "SC_GameMaintain", {
            result = GAME_SERVER_RESULT_MAINTAIN,
            })
            v:forced_exit()
            iRet = true
        end
    end

    if getNum(self.android_list) > 0 and getNum(self.players) < 1 then
        iRet = true
    end
    return iRet
end

function fivestar_table:start()
    -- body
    if base_table.start(self) == nil then
        self:log_msg(string.format("cant Start Game ===================================================="))
        self:init_status()
        return
    end
    self.tax_num = self.room_:get_room_tax()

    self:shuffle()

    self.table_game_id = self:get_now_game_id()
    self:next_game()
    self:log_msg(string.format("gamestart ================================================= gameid[%s]",self.table_game_id))

    self.status = self.FIVESTAR_STATUS_BETTING
    self.gamelog.start_game_time = get_second_time()
    self.timer = get_second_time()
    self:SendServerStatus()
end

function fivestar_table:get_rand_key( ... )
    -- body
    local  rand_key =  random.boost_integer(0 , 22)
    self.rand_key = get_second_time()
    if rand_key == 0 then
        self.rand_key = 0
    elseif rand_key == 2 then
        self.rand_key = self.room_.cur_player_count_
    elseif rand_key == 3 then
        self.rand_key = self.room_.cur_player_count_ + def_first_game_type
    elseif rand_key == 4 then
        self.rand_key = self.room_.cur_player_count_ + def_first_game_type + def_second_game_type
    elseif rand_key == 5 then
        self.rand_key = self.room_.cur_player_count_ + get_second_time()
    elseif rand_key == 6 then
        self.rand_key = self.room_.cur_player_count_ + def_first_game_type + get_second_time()
    elseif rand_key == 7 then
        self.rand_key = self.room_.cur_player_count_ + def_first_game_type + def_second_game_type + get_second_time()
    elseif rand_key == 8 then
        self.rand_key = def_first_game_type
    elseif rand_key == 9 then
        self.rand_key = def_first_game_type + def_second_game_type
    elseif rand_key == 10 then
        self.rand_key = def_first_game_type + get_second_time()
    elseif rand_key == 11 then
        self.rand_key = def_first_game_type + def_second_game_type + get_second_time()
    elseif rand_key == 12 then
        self.rand_key = self.rand_key + self.room_.cur_player_count_
    elseif rand_key == 13 then
        self.rand_key = self.rand_key + self.room_.cur_player_count_ + def_first_game_type
    elseif rand_key == 14 then
        self.rand_key = self.rand_key + self.room_.cur_player_count_ + def_first_game_type + def_second_game_type
    elseif rand_key == 15 then
        self.rand_key = self.rand_key + self.room_.cur_player_count_ + def_first_game_type + get_second_time()
    elseif rand_key == 16 then
        self.rand_key = self.room_.cur_player_count_ + def_first_game_type + def_second_game_type + get_second_time()
    elseif rand_key == 17 then
        self.rand_key = self.rand_key + def_first_game_type
    elseif rand_key == 18 then
        self.rand_key = self.rand_key + def_first_game_type + def_second_game_type
    elseif rand_key == 19 then
        self.rand_key = self.rand_key + get_second_time()
    elseif rand_key == 20 then
        self.rand_key = self.rand_key + def_first_game_type + get_second_time()
    elseif rand_key == 21 then
        self.rand_key = self.rand_key + def_first_game_type + def_second_game_type + get_second_time()
    else
        self.rand_key = get_second_time()
    end
end

function fivestar_table:random( A , B)
    -- body
    self:get_rand_key()
    return random.boost_key(A,B,self.rand_key)
end

function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then

            return lookup_table[object]
        end  -- if
        local new_table = {}
        lookup_table[object] = new_table


        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function fivestar_table:Settlement()
    self.notify_all = {}
    -- 随机出花色
    local chance = self:random(1,self.kill_Chance + self.king_Chance + self.spade_Chance + self.heart_Chance + self.diamond_Chance + self.club_Chance)
    local color = 1
    if chance >= self.kill_Chance + self.king_Chance + self.spade_Chance + self.heart_Chance + self.diamond_Chance then
        color = FiveStar_Color_Club
    elseif chance >= self.kill_Chance + self.king_Chance + self.spade_Chance + self.heart_Chance then
        color = FiveStar_Color_Diamond
    elseif chance >= self.kill_Chance + self.king_Chance + self.spade_Chance then
        color = FiveStar_Color_Heart
    elseif chance >= self.kill_Chance + self.king_Chance then
        color = FiveStar_Color_Spade
    elseif chance >= self.kill_Chance then
        color = FiveStar_Color_King
    else
        color = FiveStar_Color_Kill
    end

    if color == FiveStar_Color_Kill then
        self.gamelog.isKill = 1
        local sum = self.bet_max * self.fivestar_times[FiveStar_Color_King]
        for k,v in pairs(self.color_list) do
            if self.fivestar_times[k] and sum > v.bet_player_sum * self.fivestar_times[k] and k ~=  FiveStar_Color_King then
                sum = v.bet_player_sum * self.fivestar_times[k]
                color = k
            end
        end
        if color == FiveStar_Color_Kill then -- 所有区 押注 倍数结果一样
            color = self:random(FiveStar_Color_Spade , FiveStar_Color_Club)    -- 随机一个
        end
    end

--0  0： 方块A ， 1： 梅花A ， 2： 红桃A ， 3： 黑桃A
--1  4： 方块2 ， 5： 梅花2 ， 6： 红桃2 ， 7： 黑桃2
--2  8： 方块3 ， 9： 梅花3 ， 10：红桃3 ， 11：黑桃3
--3  12：方块4 ， 13：梅花4 ， 14：红桃4 ， 15：黑桃4
--4  16：方块5 ， 17：梅花5 ， 18：红桃5 ， 19：黑桃5
--5  20：方块6 ， 21：梅花6 ， 22：红桃6 ， 23：黑桃6
--6  24：方块7 ， 25：梅花7 ， 26：红桃7 ， 27：黑桃7
--7  28：方块8 ， 29：梅花8 ， 30：红桃8 ， 31：黑桃8
--8  32：方块9 ， 33：梅花9 ， 34：红桃9 ， 35：黑桃9
--9  36：方块10， 37：梅花10， 38：红桃10， 39：黑桃10
--10 40：方块J ， 41：梅花J ， 42：红桃J ， 43：黑桃J
--11 44：方块Q ， 45：梅花Q ， 46：红桃Q ， 47：黑桃Q
--12 48：方块K ， 49：梅花K ， 50：红桃K ， 51：黑桃K
--13 52: 小王  ， 53: 大王

    -- color = FiveStar_Color_King
    local five_star_card = random.boost_integer(4 , 55)
    if color == FiveStar_Color_King then
        five_star_card = random.boost_integer(52,53)
    elseif color == FiveStar_Color_Spade then
        five_star_card = getdivisibleInt(five_star_card , 4 ) - 1
    elseif color == FiveStar_Color_Heart then
        five_star_card = getdivisibleInt(five_star_card , 4 ) - 2
    elseif color == FiveStar_Color_Diamond then
        five_star_card = getdivisibleInt(five_star_card , 4 ) - 3
    else
        color = FiveStar_Color_Club
        five_star_card = getdivisibleInt(five_star_card , 4 ) - 4
    end

    -- 结算 逐个处理
    self.notify_all = {                    --下发客户端的结算消息
        pb_allplayer_Settlement = {},       --玩家在各区域的总输赢
        pb_allplayer_area = {},             --所有玩家在各区域的总输赢
        total_money = 0,                    --庄家总输赢 正为庄家输 负为庄家赢
        card = five_star_card,              --所开的牌
        pb_win_lose = {},
    }
    local  total = 0

    self:add_history(five_star_card)
    self.gamelog.five_star_card = five_star_card
    self:log_msg(string.format("gameid[%s] select_color[%d] card[%d]" ,self.table_game_id,  color , five_star_card))
    for k,v in pairs(self.color_list) do
        local color_Settlement = {
            color = k,
            bet_sum = 0,
            money = 0,
        }
        local sum = 0     

        if k == color then      -- 当前开出的花色
            sum = math.ceil((v.bet_player_sum + v.bet_android_sum) * self.fivestar_times[color])
        elseif color ~= FiveStar_Color_King then
            sum = -1 * (v.bet_player_sum + v.bet_android_sum)
        end

        color_Settlement.bet_sum = (v.bet_player_sum + v.bet_android_sum)
        color_Settlement.money = sum
        total = total + sum
        self:log_msg(string.format("gameid[%s] color[%d] times[%f] bet_money[%d] sum[%d] total[%d]" ,self.table_game_id, k , self.fivestar_times[color] , (v.bet_player_sum + v.bet_android_sum), sum , total))
        table.insert(self.notify_all.pb_allplayer_area , color_Settlement)
    end
    self.gamelog.color = color
    self.gamelog.color_list = deepcopy(self.notify_all.pb_allplayer_area)
    self:log_msg(string.format("gameid[%s] total[%d]" ,self.table_game_id,  total))
    self.notify_all.total_money = total
    self.gamelog.total_money = total
    self:log_msg(string.format("gameid[%s] total[%d]" ,self.table_game_id,  total))

    self.SC_FiveStarSettlement = {}
    local sum_tax = 0
    for k,v in pairs(self.player_bet_list) do

        -- 下注流水日志
        self:player_bet_flow_log(v,v.bet_sum)

        local  notify = {}
        notify.bet_sum = v.bet_sum
        notify.pb_player = {}
        notify.player_money = 0
        notify.show_tax = self.room_.tax_show_
        notify.tax = 0
        -- .players
        local add_money = 0
        local s_type = 1  -- default loss ,2 win

        local player_temp = self.players[k]
        if not player_temp then
            player_temp = self.android_list[k]
        end


        if not player_temp then
            self:log_error_msg(string.format("gameid[%s] player[%d] is not in list big error" , self.table_game_id , player_temp.guid))
        else
            for i,j in pairs(v) do
                if type(i) == "number" then
                    local color_Settlement = {
                        color = i,
                        bet_sum = 0,
                        money = 0,
                    }
                    local sum = 0
                    if i == color then      -- 当前开出的花色
                        sum = math.ceil(j * self.fivestar_times[color])
                    elseif color ~= FiveStar_Color_King then
                        sum = -1 * j
                    end
                    color_Settlement.bet_sum = j
                    color_Settlement.money = sum
                    if sum > 0 then                        
                        -- if self.tax_open_ == 1  then
                        --     color_Settlement.money = sum - math.ceil((sum - j) * self.tax_num)
                        -- end
                        add_money = add_money + sum - j -- 赢了要减去下注金额
                    else
                        add_money = add_money + sum
                    end

                    self:log_msg(string.format("gameid[%s] guid [%d] color[%d] times[%f] bet_money[%d] sum[%d] add_money[%d]" ,self.table_game_id , player_temp.guid , i, self.fivestar_times[color] , j, sum, add_money))
                    table.insert(notify.pb_player , color_Settlement)


                    table.insert(self.notify_all.pb_allplayer_Settlement , {
                        guid = player_temp.guid,
                        color = i,
                        bet_sum = j,
                        money = i == color and sum or -1 * j,
                    })
                end
            end
            self.gamelog.player_list[player_temp.guid] = notify.pb_player
            self:CalculateRateOfWin(player_temp, add_money)
            local s_old_money = player_temp:get_money()

            self.gamelog.tax_open = self.tax_open_
            if add_money > 0 then
                s_type = 2
                -- 税收开关是否开启
                if self.tax_open_ == 1  then
                    notify.tax = math.ceil(add_money * self.tax_num)
                    add_money = add_money - notify.tax
                end
                self.gamelog.player_list[player_temp.guid].win_money = add_money
                self.gamelog.player_list[player_temp.guid].tax = notify.tax
                sum_tax = sum_tax + notify.tax

                player_temp:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = add_money}}, LOG_MONEY_OPT_TYPE_FIVESTAR)

                if add_money > self.big_win_limit then
                    local msg = {
                            guid = player_temp.guid,
                            head_id = player_temp:get_header_icon(),
                            winmoney = add_money,
                            time = get_second_time(),
                            ip_area = player_temp.ip_area,
                        }
                    self:add_big_win_history(msg)
                    table.insert(self.big_win_list, msg)
                end


                if add_money > self.grand_base and player_temp.is_player ~= false then
                    log.info("gameid[%s] player guid[%d] nickname[%s]in banker ox game earn money[%d] upto [%d],broadcast to all players.",self.table_game_id, player_temp.guid,player_temp.nickname,add_money,self.grand_base)
                    broadcast_world_marquee(def_first_game_type,def_second_game_type,0,player_temp.nickname,add_money / 100)
                end

            elseif add_money < 0 then
                self.gamelog.player_list[player_temp.guid].loss_money = add_money
                player_temp:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -add_money}}, LOG_MONEY_OPT_TYPE_FIVESTAR)
            else
                self.gamelog.player_list[player_temp.guid].winmoney = 0
            end

            table.insert(self.notify_all.pb_win_lose , { guid = player_temp.guid, money = add_money } )

            notify.player_money = add_money
            notify.cur_money = player_temp:get_money()
            send2client_pb(player_temp, "SC_FiveStarSettlement", notify)
            self.SC_FiveStarSettlement[player_temp.guid] = notify


            if self:islog(player_temp.guid) then                
                player_temp:check_and_create_bonus()
                local tax = 0
                self:player_money_log(player_temp,s_type,s_old_money,notify.tax,add_money,self.table_game_id)
            end
        end
    end

    if getNum(self.big_win_list) then
        self:broadcast2client("SC_BigWinPlayerList" , { pb_bigwinlist = self.big_win_list })
    end

    self.notify_all.tax_num = 0
    if self.tax_open_ == 1  then
        self.notify_all.tax_num = self.tax_num
    end

    local Settlement_all = deepcopy(self.notify_all)
    dump(Settlement_all)
    self:broadcast2client("SC_FiveStarSettlement_all" , Settlement_all)
    for k,v in pairs(self.color_list) do
        self.gamelog.color_list[k].bet_player_sum = v.bet_player_sum
        self.gamelog.color_list[k].bet_android_sum = v.bet_android_sum

        if k == color then      -- 当前开出的花色
            self.gamelog.color_list[k].playerWin = math.ceil(v.bet_player_sum * self.fivestar_times[color])
            self.gamelog.color_list[k].androidWin = math.ceil(v.bet_android_sum * self.fivestar_times[color])
        elseif color ~= FiveStar_Color_King then
            self.gamelog.color_list[k].playerLoss = v.bet_player_sum
            self.gamelog.color_list[k].androidLoss = v.bet_android_sum
        end

    end

    -- 游戏结束
    self.gamelog.table_game_id = self.table_game_id
    self.gamelog.end_game_time = get_second_time()

    local s_log = json.encode(self.gamelog)
    self:log_important(s_log)
    if self.player_total and self.player_total > 0 then
        self:log_important(s_log)
        self:save_game_log(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
    else
        --- 没有玩家下注不记录日志
    end
    -- end
    self:log_important("game end")

    -- 踢人
    for i,v in pairs(self.players) do
        if v and v.in_game == false then
            self:log_important(string.format("player guid[%d] v.is_android[%s] v.in_game[%s]",v.guid , tostring(v.is_android) , tostring(v.in_game)))
            v:forced_exit()
        end

        if v and v:check_room_limit(self.room_:get_room_limit()) then
            self:log_important(string.format("player guid[%d] not find in game forced_exit",v.guid))
            v:forced_exit()
        end
    end

    self:Android_check()
    -- self:init_status()
    self.status = self.FIVESTAR_STATUS_SETTLEMENT
    self.timer = get_second_time()
    self:SendServerStatus()
end

function fivestar_table:islog(guid)
    if guid > 0 then
        return true
    end
    return self.robot_islog
end

function fivestar_table:CalculateRateOfWin( player , money )
    -- body
    if not player.luck_list then
        player.luck_list = {}
        player.luck_list.rateofwin = 1
        player.luck_list.index = 1
        player.luck_list.winmoney = 0
    end

    player.luck_list[player.luck_list.index] = {
        is_win = money > 0 and 1 or 0,
        winmoney = money,
    }

    local wintimes = 0
    local playertimes = 0
    local winmoney = 0
    for i = 1,self.luck_count_num do
        if player.luck_list[i] then
            if player.luck_list[i].is_win == 1 then
                wintimes = wintimes + 1
            end
            winmoney = winmoney + player.luck_list[i].winmoney
            playertimes = playertimes + 1
        else
            break
        end
    end
    player.luck_list.rateofwin = wintimes / playertimes
    player.luck_list.winmoney = winmoney
    player.luck_list.index = player.luck_list.index + 1
    if player.luck_list.index > self.luck_count_num then
        player.luck_list.index = 1
    end
end

-- 判断是否游戏中
function  fivestar_table:is_play( player )
    self:log_msg(string.format("fivestar_table:is_play : status[%d]",self.status))
    if player == nil then
        self:log_error_msg(string.format("player is nil......"))
        return false
    end
    self:log_msg(string.format("~~~~~~~~~~~guid: %d",player.guid))

    if self.status ~= self.FIVESTAR_STATUS_BETTING then
        return false
    end

    if player.is_player == false then --机器人
        return false
    end

    -- 未下注玩家可以退出，已下注不能退出
    if not self.player_bet_list[player.is_android and player.guid or player.chair_id]  or self.player_bet_list[player.is_android and player.guid or player.chair_id].bet_sum == 0 then
        return false
    end
    return true
end

-- 检查是否可取消准备
function fivestar_table:check_cancel_ready(player, is_offline)

    self:log_msg(string.format("fivestar_table:check_cancel_ready : player[%d] is_offline[%s]",player.guid, tostring(is_offline)))
    base_table.check_cancel_ready(self,player,is_offline)
    player:setStatus(is_offline)
    if is_offline then
        -- 判断玩家是否下注
        if (not self.player_bet_list[player.is_android and player.guid or player.chair_id]  or self.player_bet_list[player.is_android and player.guid or player.chair_id].bet_sum == 0) or self.status ~= self.FIVESTAR_STATUS_BETTING then
            return true
        else
            self:log_important(string.format("guid[%d] offline",player.guid))
            self:player_offline(player)
            return false
        end
    end
    --退出
    return true
end

function fivestar_table:android_bet_color(player , color , money )
    -- body
    local msg = {
        betting_money = money,
        color = color,
    }
    self:fivestarBetting(player , msg)
end

function fivestar_table:fivestarBetting(player, msg)
    -- body
    if self.status ~= self.FIVESTAR_STATUS_BETTING then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] status error [%d]", player.guid,self.status ))
        return
    end
    if not msg then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] msg is nil", player.guid))
        return
    end
    -- 1 黑 2 红 3 梅 4 方 5 大小王 其它错误
    if not msg.color or msg.color < FiveStar_Color_Spade or msg.color > FiveStar_Color_King then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] msgcolor error", player.guid))
        return
    end
    if not msg.betting_money or msg.betting_money < 0 then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] msgbettingmoney error", player.guid))
        return
    end
    -- 判断是否小于最小限制
    if msg.betting_money < self.bet_limit then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] msgbettingmoney < bet_limit", player.guid))
        send2client_pb(player, "SC_FiveStarBetting", { re_status = 3})
        return
    end
    -- 判断是否大于总注最大限制
    if self.player_total + self.android_total + msg.betting_money > self.bet_all_max then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] msgbettingmoney > bet_all_max", player.guid))
        send2client_pb(player, "SC_FiveStarBetting", { re_status = 5})
        return
    end
    if not self.player_bet_list[player.is_android and player.guid or player.chair_id] then
        self.player_bet_list[player.is_android and player.guid or player.chair_id] = {
            bet_sum = 0,
        }
    end

    local player_bet_sum = self.player_bet_list[player.is_android and player.guid or player.chair_id].bet_sum
    player_bet_sum = player_bet_sum + msg.betting_money
    if player_bet_sum > player:get_money() then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] msgbettingmoney > player_money", player.guid))
        send2client_pb(player, "SC_FiveStarBetting", { re_status = 2, money = player_bet_sum - msg.betting_money,})
        return
    end
    local bet_sum = 0
    local color_table = self.color_list[msg.color]
    if color_table == nil then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] msgcolor error", player.guid))
        return
    end
    local playerInfo = color_table.playerlist[player.guid]
    if playerInfo ~= nil then
        bet_sum = playerInfo
    end
    bet_sum = bet_sum + msg.betting_money
    -- 判断单区下注是否达到最大限制
    if bet_sum > self.bet_max then
        self:log_important(string.format("fivestar_table:fivestarBetting guid[%d] msgbettingmoney > bet_max", player.guid))
        send2client_pb(player, "SC_FiveStarBetting", { re_status = 4})
        return
    end

    self.player_bet_list[player.is_android and player.guid or player.chair_id].bet_sum = player_bet_sum
    if self.player_bet_list[player.is_android and player.guid or player.chair_id][msg.color] then
        self.player_bet_list[player.is_android and player.guid or player.chair_id][msg.color] = self.player_bet_list[player.is_android and player.guid or player.chair_id][msg.color] + msg.betting_money
    else
        self.player_bet_list[player.is_android and player.guid or player.chair_id][msg.color] = msg.betting_money
    end

    if self.all_player_bet_money_total[player.guid] == nil then
        self.all_player_bet_money_total[player.guid] = msg.betting_money
    else
        self.all_player_bet_money_total[player.guid] = self.all_player_bet_money_total[player.guid] + msg.betting_money
    end

    self:log_msg(string.format("gameid[%s] player[%d] color[%d][%s] money[%d] bet_sum[%d] player_money[%d] bet_all_area_sum_money[%d]", self.table_game_id, player.guid , msg.color, color_table.color_name ,msg.betting_money,bet_sum,player:get_money(),self.all_player_bet_money_total[player.guid]))
    send2client_pb(player, "SC_FiveStarBetting", { re_status = 1 , color = msg.color , money = msg.betting_money, cur_money = player:get_money() - self.all_player_bet_money_total[player.guid] , bet_left = self.bet_max - bet_sum - 1 , })
    color_table.playerlist[player.guid] = bet_sum
    if player.is_android then
        self.android_total = self.android_total + msg.betting_money
        if color_table.Android_bet_times_list[player.guid] then
            color_table.Android_bet_times_list[player.guid] = color_table.Android_bet_times_list[player.guid] + 1
        else
            color_table.Android_bet_times_list[player.guid] = 1
        end
        color_table.bet_android_sum = color_table.bet_android_sum + msg.betting_money
    else
        self.player_total = self.player_total + msg.betting_money
        color_table.bet_player_sum = color_table.bet_player_sum + msg.betting_money
    end
    local notify = {
        -- chair_id = player.chair_id,
        guid = player.guid,
        color = msg.color,
        betting_money = msg.betting_money,
        bet_left = self.bet_all_max - self.player_total - self.android_total,
    }
    self:broadcast2client("SC_FiveStarBetting_broad", notify)
end

function dump(obj)
    local getIndent, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "" .. val .. ""
        elseif type(val) == "string" then
            return '"' .. val .. '"'
        else
            return "" .. tostring(val) .. ""
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return '"' .. val .. '"'
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    --return dumpObj(obj, 0)
    print(dumpObj(obj, 0))
end

function fivestar_table:fivestarGetHistory(player)
    -- body
    local notify = {
        cards = self.history_cards,
    }
    send2client_pb(player,"SC_FiveStarGetHistory", notify)

end

function fivestar_table:add_history( card )
    -- body
    table.insert(self.history_cards , 1 , card)
    local count = #self.history_cards
    if count >= self.history_max  then
        self.history_cards[count] = nil
    end
end


function fivestar_table:fivestarGetBigWinHistory(player)
    -- body
    local notify = {
        pb_bigwinlist = self.big_win_history,
    }

    send2client_pb(player,"SC_BigWinPlayerListHistory", notify)
end

function fivestar_table:add_big_win_history( msg )
    -- body
    table.insert(self.big_win_history , 1 , msg)
    local count = #self.big_win_history
    if count >= self.big_win_history_max  then
        self.big_win_history[count] = nil
    end
end

function  fivestar_table:init_status()
    -- body
    self.notify_all = {}
    self.status = self.FIVESTAR_STATUS_FREE
    self.timer = get_second_time()
    self:SendServerStatus()
    self.player_total = 0
    self.android_total = 0
    self.player_bet_list = {}
    self.color_list = {}
    self.color_list[FiveStar_Color_Spade] = {
        playerlist = {},
        bet_player_sum = 0,
        bet_android_sum = 0,
        color_name = "spade",
        Android_bet_times_list = {},
    }
    self.color_list[FiveStar_Color_Heart] = {
        playerlist = {},
        bet_player_sum = 0,
        bet_android_sum = 0,
        color_name = "heart",
        Android_bet_times_list = {},
    }
    self.color_list[FiveStar_Color_Diamond] = {
        playerlist = {},
        bet_player_sum = 0,
        bet_android_sum = 0,
        color_name = "diamond",
        Android_bet_times_list = {},
    }
    self.color_list[FiveStar_Color_Club] = {
        playerlist = {},
        bet_player_sum = 0,
        bet_android_sum = 0,
        color_name = "club",
        Android_bet_times_list = {},
    }
    self.color_list[FiveStar_Color_King] = {
        playerlist = {},
        bet_player_sum = 0,
        bet_android_sum = 0,
        color_name = "king",
        Android_bet_times_list = {},
    }
    self.gamelog = {
        table_game_id = 0,
        start_game_time = 0,
        end_game_time = 0,
        color_list = {},
        player_list = {},
        color = -1,
        total_money = 0,
        isKill = 0,
    }
    self.big_win_list = {}
    self.all_player_bet_money_total = {} --所有玩家下注筹码统计
end

-- 洗牌
function fivestar_table:shuffle()
    if not self.cards then
        self.cards = {}
        for i = 1, 54 do
            self.cards[i] = i - 1
        end
    end

    for i = 1, 27 do
        local x = random.boost(54)
        local y = random.boost(54)

        if x ~= y then
            self.cards[x], self.cards[y] = self.cards[y], self.cards[x]
        end
    end
end

function fivestar_table:tick()
    if self.status == self.FIVESTAR_STATUS_FREE then
        if get_second_time() - self.timer > self.fivestar_time_start_countdown + 1 then
            self:Refresh_player_listInfo()
            self:update_player_listInfo()
            self:start()
        end
    elseif self.status == self.FIVESTAR_STATUS_BETTING then
        if get_second_time() ~= self.bet_timer then
            self.bet_timer = get_second_time()
            self:android_bet()
        end
        if get_second_time() - self.timer > self.fivestar_time_betting_countdown + 1 then
            self:Settlement()
        end
    elseif self.status == self.FIVESTAR_STATUS_SETTLEMENT then
        if get_second_time() - self.timer > self.fivestar_time_settlement_countdown + 1 then
            self:init_status()
            self:check_player_num()
        end
    end
end

return fivestar_table