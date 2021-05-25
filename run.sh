export ROOT=$(cd `dirname $0`; pwd)
export CMDLINE="game $*"

# while getopts "Dk" arg
# do
# 	case $arg in
# 		D)
# 			export DAEMON=true
# 			;;
# 		k)
# 			kill `cat $ROOT/run/skynet.pid`
# 			exit 0;
# 			;;
# 	esac
# done

$ROOT/skynet $ROOT/geek/boot.lua