
pids=$(pgrep skynet)
if [  "$pids" != ""  ]
then
	echo "kill" $pids
	kill -HUP $pids
fi

echo "停止成功!"