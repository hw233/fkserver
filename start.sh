
export ROOT=$(cd `dirname $0`; pwd)
export CLUSTER=$1

if [ $# = 0 ]
then
	echo "Warning:应输入cluster id ......"
fi

pids=$(pgrep skynet)
if [  "$pids" != ""  ]
then
	echo "kill" $pids
	kill $pids
fi

nohup $ROOT/skynet $ROOT/geek/boot.lua  &
echo "启动成功!"