local pb = require "pb_files"

Operation = {
    Idle = pb.enum("Operations","O_Idle"),
    Bet = pb.enum("Operations","O_Bet"),
    BetSame = pb.enum("Operations","O_BetSame"),
	Hit = pb.enum("Operations","O_Hit"),
	Stand = pb.enum("Operations","O_Stand"),
	Double = pb.enum("Operations","O_Double"),
	Surrender = pb.enum("Operations","O_Surrender"),
	SplitCard = pb.enum("Operations","O_SplitCard"),
	BuySecurity = pb.enum("Operations","O_BuySecurity"),
}

PlayerStatus = {
    Idle = pb.enum("PlayerStatus","P_Idle"),
	ReadyStart = pb.enum("PlayerStatus","P_ReadyStart"),
	Stand = pb.enum("PlayerStatus","P_Stand"),
	Surrender = pb.enum("PlayerStatus","P_Surrender"),
	Bomb = pb.enum("PlayerStatus","P_Bomb"),
	WaitHit = pb.enum("PlayerStatus","P_WaitHit"),
	BuySecurity = pb.enum("PlayerStatus","P_BuySecurity"),
	Bet = pb.enum("PlayerStatus","P_Bet"),
	WaitBalance = pb.enum("PlayerStatus","P_WaitBalance"),
}

TableStatus = {
    Idle = pb.enum("TableStatus","T_Idle"),
	ReadyStart = pb.enum("TableStatus","T_ReadyStart"),
	WaitBet = pb.enum("TableStatus","T_WaitBet"),
	DealCards = pb.enum("TableStatus","T_DealCards"),
	WaitBuySecurity = pb.enum("TableStatus","T_WaitBuySecurity"),
	WaitOperate = pb.enum("TableStatus","T_WaitOperate"),
	WaitBalance = pb.enum("TableStatus","T_WaitBalance"),
}