
cluster=1

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

cluster=$1

nohup ./skynet geek/boot.lua $cluster &
echo "启动成功!"