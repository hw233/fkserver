export ROOT=$(cd `dirname $0`; pwd)
export CMDLINE="control $*"

$ROOT/skynet $ROOT/geek/boot.lua