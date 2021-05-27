echo "kill $(pgrep skynet)";

killall -TERM skynet;

killall -0 skynet
if [ $? -gt 0 ]; then
	echo "停止成功!";
	exit;
fi
tail -f ./nohup.out

echo "等待超时!"

