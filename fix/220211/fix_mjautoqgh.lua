local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local maajan_table = require "game.maajan_xuezhan.maajan_table"

local def 	= require "game.maajan_xuezhan.base.define"
local FSM_S  = def.FSM_state
local ACTION = def.ACTION

local timer = require "timer"
local log = require "log"

function maajan_table:qiang_gang_hu(player,actions,tile)
	log.dump("fix qiang_gang_hu!!!!!!!!!!!!!!")
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
