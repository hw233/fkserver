local pb = require "pb_files"

BetArea = {
    ShePian = pb.enum("BET_AREA", "SHE_PIAN"),
    SheZhong = pb.enum("BET_AREA", "SHE_ZHONG"),
    ShunZi = pb.enum("BET_AREA", "SHUN_ZI"),
    ZhuangZhu = pb.enum("BET_AREA", "ZHUANG_ZHU"),
    DuiZi = pb.enum("BET_AREA", "DUI_ZI")
}

TableStatus = {
    Error = pb.enum("TableStatus", "T_Error"),
    Idle = pb.enum("TableStatus", "T_Idle"),
    WaitBet = pb.enum("TableStatus", "T_WaitBet"),
    GameOver = pb.enum("TableStatus", "T_GameOver")
}


AreaMultiple = {
    [BetArea.ShePian] = 1,
    [BetArea.SheZhong] = 3,
    [BetArea.ShunZi] = 5,
    [BetArea.ZhuangZhu] = 8,
    [BetArea.DuiZi] = 10
}