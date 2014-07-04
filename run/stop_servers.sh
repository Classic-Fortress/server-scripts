#!/bin/bash

[ "$1" == "--silent" ] || silent=1

# kill mvdsv
[ "$silent" != "1" ] || echo -n "* Stopping mvdsv (port 27500)..."
if [ -f ~/.cfortsv/pid/server ]
then
        pid=$(cat ~/.cfortsv/pid/server)
        if ps -p $pid >/dev/null
        then
                if ps -p $pid | grep mvdsv | grep -v grep > /dev/null
                then
                        kill -9 $pid >/dev/null
                        rm -f ~/.cfortsv/pid/server >/dev/null
                        [ "$silent" != "1" ] || echo "[OK]"
                else
                        [ "$silent" != "1" ] || echo "[PID INCORRECT]"
                fi
        else
                [ "$silent" != "1" ] || echo "[NOT RUNNING]"
        fi
else
        [ "$silent" != "1" ] || echo "[PID NOT FOUND]"
fi

# kill qtv
[ "$silent" != "1" ] || echo -n "* Stopping qtv (port 28000)..."
if [ -f ~/.cfortsv/pid/qtv ]
then
        pid=$(cat ~/.cfortsv/pid/qtv)
        if ps -p $pid >/dev/null
        then
                if ps -p $pid | grep qtv | grep -v grep > /dev/null
                then
                        kill -9 $pid >/dev/null
                        rm -f ~/.cfortsv/pid/qtv >/dev/null
                        [ "$silent" != "1" ] || echo "[OK]"
                else
                        [ "$silent" != "1" ] || echo "[PID INCORRECT]"
                fi
        else
                [ "$silent" != "1" ] || echo "[NOT RUNNING]"
        fi
else
        [ "$silent" != "1" ] || echo "[PID NOT FOUND]"
fi

# kill qwfwd
[ "$silent" != "1" ] || echo -n "* Stopping qwfwd (port 30000)..."
if [ -f ~/.cfortsv/pid/qwfwd ]
then
        pid=$(cat ~/.cfortsv/pid/qwfwd)
        if ps -p $pid >/dev/null
        then
                if ps -p $pid | grep qwfwd | grep -v grep > /dev/null
                then
                        kill -9 $pid >/dev/null
                        rm -f ~/.cfortsv/pid/qwfwd >/dev/null
                        [ "$silent" != "1" ] || echo "[OK]"
                else
                        [ "$silent" != "1" ] || echo "[PID INCORRECT]"
                fi
        else
                [ "$silent" != "1" ] || echo "[NOT RUNNING]"
        fi
else
        [ "$silent" != "1" ] || echo "[PID NOT FOUND]"
fi
