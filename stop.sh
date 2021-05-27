echo "kill $(pgrep skynet)";

killall -TERM skynet;

for i in {1..20}; do
	killall -0 skynet
	if [ $? -gt 0 ]; then
		echo "停止成功!";
		exit;
	fi
	echo "等待 $(pgrep skynet) 退出!";
	sleep 1;
done

echo "等待超时!"

