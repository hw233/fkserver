
pids=$(pgrep skynet)
if [  "$pids" != ""  ]
then
	echo "kill" $pids
	kill -TERM $pids
fi

echo "停止成功!"