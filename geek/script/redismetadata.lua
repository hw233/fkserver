
local redismeta = require "redisorm.meta"

local redismetadata = {}

redismetadata.player = {}

redismetadata.player.info = redismeta:create({
    fields = {
        guid = "number",
        account  = "string",
        nickname = "string",
        bank = "number",
        is_android = "number",
        level = "number",
        login_time = "number",
        login_award_day = "number",
        login_award_receive_day = "number",
        online_award_time = "number",
        header_icon = "number",
        platform_id = "number",
        slotma_addtion = "number",
        relief_payment_count = "number",
        is_collapse = "number",
        sex = "number",
        icon = "string",
        app_id = "string",
        is_guest = "number",
        vip = "number",
        is_locked = "number",
        tickets = "number",
        user_type = "number",
        status = "number",
        role = "number",
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
        type = "number",
        parent = "number",
    }
})

redismetadata.conf = redismeta:create({
    fields = {
        commission = "number",
        commission_rate = "number",
        visual = "boolean",
        club_id = "number",
        template_id = "number",
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
        template = "number",
    }
})

redismetadata.privatetable.template = redismeta:create({
    fields = {
        template_id = "number",
        game_type = "number",
        rule = "json",
        description = "string",
        game_id = "number",
        club_id = "number",
        advanced_rule = "json",
    }
})

redismetadata.mail = redismeta:create({
    fields = {
        email_id = "string",
        sender = "number",
        reciever = "number",
        expire = "number",
        content = "json",
        status = "number",
        create_time = "number",
    }
})

redismetadata.money = redismeta:create({
    fields = {
        id = "number",
        club = "number",
        type = "number",
    },
})


return redismetadata