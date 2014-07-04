#!/bin/bash

# kill mvdsv
echo -n "* Stopping mvdsv (port 27500)..."
if [ -f ~/.cfortsv/pid/server ]
then
        pid=$(cat ~/.cfortsv/pid/server)
        if ps -p $pid > /dev/null
        then
                if ps -p $pid | grep mvdsv | grep -v grep > /dev/null
                then
                        kill -9 $pid
                        rm -f ~/.cfortsv/pid/server
                        echo "[OK]"
                else
                        echo "[PID INCORRECT]"
                fi
        else
                echo "[NOT RUNNING]"
        fi
else
        echo "[PID NOT FOUND]"
fi

# kill qtv
echo -n "* Stopping qtv (port 28000)..."
if [ -f ~/.cfortsv/pid/qtv ]
then
        pid=$(cat ~/.cfortsv/pid/qtv)
        if ps -p $pid > /dev/null
        then
                if ps -p $pid | grep qtv | grep -v grep > /dev/null
                then
                        kill -9 $pid
                        rm -f ~/.cfortsv/pid/qtv
                        echo "[OK]"
                else
                        echo "[PID INCORRECT]"
                fi
        else
                echo "[NOT RUNNING]"
        fi
else
        echo "[PID NOT FOUND]"
fi

# kill qwfwd
echo -n "* Stopping qwfwd (port 30000)..."
if [ -f ~/.cfortsv/pid/qwfwd ]
then
        pid=$(cat ~/.cfortsv/pid/qwfwd)
        if ps -p $pid > /dev/null
        then
                if ps -p $pid | grep qwfwd | grep -v grep > /dev/null
                then
                        kill -9 $pid
                        rm -f ~/.cfortsv/pid/qwfwd
                        echo "[OK]"
                else
                        echo "[PID INCORRECT]"
                fi
        else
                echo "[NOT RUNNING]"
        fi
else
        echo "[PID NOT FOUND]"
fi
