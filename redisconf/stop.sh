pids=$(pgrep redis-server)
if [  "$pids" != ""  ]
then
	echo "kill" $pids
	kill $pids
fi

echo "停止成功!"