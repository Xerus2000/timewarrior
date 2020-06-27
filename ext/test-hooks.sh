#!/bin/sh
testdir=/tmp/timew-hook-test
rm -r $testdir
export TIMEWARRIORDB=$testdir/timew
export TASKDATA=$testdir/task
export TASKRC=$TASKDATA/taskrc
hooksdir=$TASKDATA/hooks
mkdir -p $hooksdir
cp ./*.timewarrior $hooksdir
( timew :quiet :yes && echo yes | task ) >/dev/null 2>&1

set -e
highlight() { echo "[4m$@[0m"; }
verbose=$(test "$1" = "v" && echo "true" || echo "false")
debug() { $verbose && $@ || true; }
if test "$1" = "q"
then task() { command task "$@" 2>/dev/null; }
else $verbose || task() { command task "$@" 3>&1 1>&2 2>&3 3>&- | (grep -v "override:" || true); }
fi

highlight A new task is started with correct time
task add test +t1 +t2 start:2020-04-04 entry:2020-04-03
debug task 1 info
test "$(timew get dom.active.start)" = "2020-04-04T00:00:00"

highlight Modify start time
task 1 modify start:2020-04-05T12:00
debug timew
test "$(timew get dom.active.start)" = "2020-04-05T12:00:00"

highlight Modify tags
task 1 modify +t3 project:testing
test "$(timew get dom.tag.count)" = "5"

highlight Modify start time of second task
task add test2 +t2 entry:2020-04-03
task 2 info
task 2 modify start:2020-04-06
test "$(timew get dom.tracked.count)" = "1"
test "$(timew get dom.tag.count)" = "5"
test "$(timew get dom.active.start)" = "2020-04-05T12:00:00"

highlight Modify tags of second now started task
task 2 modify +t3
debug timew
test "$(timew get dom.tag.count)" = "5"
test "$(timew get dom.active.start)" = "2020-04-05T12:00:00"

highlight Start different task
#task start 1
