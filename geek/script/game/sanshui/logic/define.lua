local define = {}

define.TABLE_STATUS = {
    IDLE = 0, --空闲
    READY_START = 1,--准备开始
    WAIT_SELECT_CARDS = 2,--等待选牌
    WAIT_BI_PAI = 3,--等待比牌
}

define.PLAYER_STATUS = {
    IDLE = 0,
    READY = 1,--准备好
    SELECT_CARDS = 2,
    SELECT_CARDS_END = 3,
    BI_PAI = 4,
    BI_PAI_END = 5,
}

define.CADE_TYPE = {
    WU_LONG =                    {name = "wu_long",win_fen =  1,index = 0},--乌龙
    DUI_ZI =                        {name = "dui_zi",win_fen =  1,index = 1},--对子
    LIANG_DUI =                   {name = "liang_dui",win_fen =  1,index = 2},--两对
    SAN_TIAO =                    {name = "san_tiao",win_fen =  1,index = 3,extra = {[1] = 2}},--三条
    SHUN_ZI =                      {name = "shun_zi",win_fen =  1,index = 4},--顺子
    TONG_HUA =                   {name = "tong_hua",win_fen =  1,index = 5},--同花
    HU_LU =                         {name = "hu_lu",win_fen =  1,index = 6,extra = {[2] = 1}},--葫芦
    TIE_ZHI =                       {name = "tie_zhi",win_fen =  1,index = 7,extra = {[2] = 6,[3] = 3}},--铁枝
    TONG_HUA_SHUN =         {name = "tong_hua_shun",win_fen =  1,index = 8,extra = {[2] = 8,[3] = 4}},--同花顺
    SAN_TONG_HUA =            {name = "san_tong_hua",win_fen = 3,index = 9},--三同花
    SAN_SHUN_ZI =               {name = "san_shun_zi",win_fen = 4,index = 10},--三顺子
    LIU_DUI_BAN =                {name = "liu_dui_ban",win_fen = 4,index = 11},--六对半
    WU_DUI_SAN_TIAO =       {name = "wu_dui_san_tiao",win_fen = 5,index = 12},--五对三条
    SI_TAO_SAN_TIAO =         {name = "si_tao_san_tiao",win_fen = 6,index = 13},--四套三条
    COU_YI_SE =                   {name = "cou_yi_se",win_fen = 10,index = 14},--凑一色
    QUAN_XIAO =                  {name = "quan_xiao",win_fen = 10,index = 15},--全小
    QUAN_DA =                     {name = "quan_da",win_fen = 10,index = 16},--全大
    SAN_FEN_TIAN_XIA =        {name = "san_fen_tian_xia",win_fen = 20,index = 17},--三分天下
    SAN_TONG_HUA_SHUN =   {name = "san_tong_hua_shun",win_fen = 20,index = 18},--三同花顺
    SHI_ER_HUANG_ZHU =      {name = "shi_er_huang_zhu",win_fen = 24,index = 19},--十二皇族
    YI_TIAO_LONG =              {name = "yi_tiao_long",win_fen = 36,index = 20},--一条龙
    QING_LONG =                  {name = "qing_long",win_fen = 108,index = 21},--清龙
}

return define