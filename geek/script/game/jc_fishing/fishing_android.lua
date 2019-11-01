
require "game.lobby.base_player"
pb = require "pb_files"

local room = g_room

fishing_android = class("fishing_android",base_player)

function fishing_android:ctor()
    self.is_android = true
    self.last_fire_tick = os.clock()
    self.client_id = 0
    self.fire_count = 0
    self.fish_ids = {}
    self.bullet_ids = {}
    self.is_allow_fire = false
    self.max_bullet_count = 20
    self.msgs = {}
    self.fire_count = 0
    self.catch_count = 0

    math.randomseed(os.time())
end

function fishing_android:init(guid_, account_, nickname_)
    self.super.init(self,guid_,account_,nickname_)
end

function fishing_android:fire()
    if not self.is_allow_fire then
        return
    end

    if #self.bullet_ids >= self.max_bullet_count then
        return
    end

    local tb = room:find_table_by_player(self)
    if not tb then
        return
    end

    local msg_string_buffer = pb.encode("CS_Fire",{
            chair_id = self.chair_id,
            direction = 90,
            client_id = self.client_id + self.chair_id * 10000,
            fire_time = os.clock(),
            pos_x = 0,pos_y = 0
        })

    local msg_id = pb.enum("CS_Fire.MsgID","ID")

    tb.cpp_table:PostMsg(self.guid,self.chair_id,msg_id,msg_string_buffer)

    table.insert(self.bullet_ids,self.client_id + self.chair_id * 10000)
    self.client_id = ((self.client_id + 1) % 10000) == 0 and 0 or self.client_id + 1
    self.fire_count = self.fire_count + 1
end

function fishing_android:proc_msg()
    local tb = room:find_table_by_player(self)
    if not tb then
        print("proc msg,cannot find table")
        return
    end

    local msgname = ""
    local msg = {}
    local msgs = self.msgs
    self.msgs = {}
    for _,v in pairs(msgs) do
        msgname = v.msgname
        msg = v.msg

        if msgname == "SC_SendFish" then
--            print("SC_SendFish",msg.fish_id)
            table.insert(self.fish_ids,msg.fish_id)
        elseif msgname == "SC_AllowFire" then
            self.is_allow_fire = msg.allow_fire == 1 and true or false
        elseif msgname == "SC_GameConfig" then
            self.max_bullet_count = msg.max_bullet_count
        elseif msgname == "SC_KillFish" then
            for i,v in pairs(self.fish_ids) do
                if v == msg.fish_id then
--                    print("kill fish",tb.table_id_,v)
                    table.remove(self.fish_ids,i)
                    break
                end
            end
        elseif msgname == "SC_KillBullet" then
            for i,v in pairs(self.bullet_ids) do
                if v == msg.bullet_id then
--                    print("kill bullet:",tb.table_id_,v)
                    table.remove(self.bullet_ids,i)
                    break
                end
            end
        elseif msgname == "SC_SwitchScene" then
            if msg.switching == 1 then
                self.fish_ids = {}
            end
        elseif msgname == "SC_SendFishList" then
            for k,v in pairs(msg.pb_fishes) do
                table.insert(self.fish_ids,v.fish_id)
            end
        end
    end
end

function fishing_android:tick()
    self:proc_msg()

    local tb = room:find_table_by_player(self)
    if not tb then
        return
    end
    --print("allow fire:",tb.table_id_,self.guid)
    if self.is_allow_fire then
        if os.clock() - self.last_fire_tick >= 0.2 then
            self.last_fire_tick = os.clock()
            self:fire()
        end
    end

    if #self.fish_ids > 0 and #self.bullet_ids > 0 then
        math.randomseed(os.time())
        local fish_i = math.random(#self.fish_ids)
        local bullet_i = math.random(#self.bullet_ids)
--        print(tb.table_id_,#self.fish_ids,#self.bullet_ids)
        tb.cpp_table:OnNetCast(self.guid,self.chair_id,self.bullet_ids[bullet_i],0,self.fish_ids[fish_i])
        self.catch_count = self.catch_count + 1
    end
end

function fishing_android:on_msg(msgname,msg)
    table.insert(self.msgs,{msgname = msgname,msg = msg})
end

function fishing_android:on_msg_str(msgid,msg_str)
    local msgname = ""
    if msgid == 12107 then
        msgname = "SC_AllowFire"
    elseif msgid == 12115 then
        msgname = "SC_SendFish"
    elseif msgid == 12117 then
        msgname = "SC_GameConfig"
    elseif msgid == 12110 then
        msgname = "SC_KillFish"
    elseif msgid == 12109 then
        msgname = "SC_KillBullet"
    elseif msgid == 12108 then
        msgname = "SC_SwitchScene"
    elseif msgid == 12116 then
        msgname = "SC_SendFishList"
    end

    if msgname ~= "" then
        local msg = pb.decode(msgname,msg_str,string.len(msg_str))
        table.insert(self.msgs,{msgname = msgname,msg = msg})
    end
end

function fishing_android:on_fish_dead(fish_id)
    for i,v in pairs(self.fish_ids) do
        if v == fish_id then
--            print("fish out of screen:",fish_id)
            table.remove(self.fish_ids,i)
        end
    end
end

function on_fish_removed(room_id,table_id,fish_id)
    local tb = {}
    local room = room:find_room(room_id)
    if not room then
        return
    end

    tb = room:find_table(table_id)
    if not tb then
        return
    end

    tb:on_fish_dead(fish_id)
end