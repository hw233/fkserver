local pb = require "pb"
local protoc = require "protoc"

pb.loadfile("./geek/pb/error_code.proto")
pb.loadfile("./geek/pb/enum_define.proto")
pb.loadfile("./geek/pb/common.proto")
pb.loadfile("./geek/pb/message_club.proto")
pb.loadfile("./geek/pb/player_define.proto")
pb.loadfile("./geek/pb/message_define.proto")
pb.loadfile("./geek/pb/message_maajan.proto")

return pb