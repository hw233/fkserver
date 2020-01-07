
local redismeta = require "redisorm.meta"

local redismetadata = {}

redismetadata.player = {}

redismetadata.player.info = redismeta:create({
    fields = {
        guid = "number",
        account  = "string",
        nickname = "string",
        money = "number",
        diamond = "number",
        gold = "number",
        room_card = "number",
        bank = "number",
        is_android = "number",
        level = "number",
        login_time = "number",
        login_award_day = "number",
        login_award_receive_day = "number",
        online_award_time = "number",
        header_icon = "number",
        platform_id = "number",
        reg_time = "number",
        reg_gold = "number",
        bind_time = "number",
        bind_gold = "number",
        slotma_addtion = "number",
        relief_payment_count = "number",
        is_collapse = "number",
        sex = "number",
        icon = "string",
        app_id = "string",
        is_guest = "number",
        vip = "number",
        in_game = "number",
        player_id = "number",
        is_locked = "number",
        tickets = "number",
        user_type = "number",
        hasn_uncheck_mail = "number",
        status = "number",   
        redress_count = "number",
        is_banded_code = "number",
        has_zjh_auth = "number",
    },
})

redismetadata.player.online = redismeta:create({
    fields = {
        gate = "number",
        server  = "number",
        first_game_type = "number",
        second_game_type = "number",
        room_id = "number",
        table_id = "number",
        chair_id = "number",
        table = "number",
        chair = "number",
        game = "number",
        global_table = "number",
    },
})

redismetadata.club = {}
redismetadata.club.info = redismeta:create({
    fields = {
        id = "number",
        level = "number",
        status = "number",
        online_count = "number",
        owner = "number",
    }
})

redismetadata.club.request = redismeta:create({
    fields = {
        club_id = "number",
        id = "number",
        type = "string",
        who = "number",
        whoee = "number",
    }, 
})

redismetadata.privatetable = {}
redismetadata.privatetable.info = redismeta:create({
    fields = {
        club_id = "number",
        table_id = "number",
        game_type = "number",
        rule = "json",
        owner = "number",
        real_table_id = "number",
        room_id = "number",
        create_time = "number",
    }
})

redismetadata.privatetable.template = redismeta:create({
    fields = {
        game_type = "number",
        rule = "string",
    }
})


return redismetadata