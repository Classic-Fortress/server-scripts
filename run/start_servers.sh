#!/bin/bash

[ "$1" == "--silent" ] || silent=1

# check if configuration files exist
error=0
if [ ! -f ~/.cfortsv/server.conf ] \
|| [ ! -f ~/.cfortsv/qtv.conf ] \
|| [ ! -f ~/.cfortsv/qwfwd.conf ]
then
        [ "$silent" != "1" ] || echo "WARNING: Symlinks to configuration files missing."
        if [ -f ~/.cfortsv/install_dir ]
        then
                directory=$(cat ~/.cfortsv/install_dir)
                if [ -f $directory/fortress/config.cfg ] \
                && [ -f $directory/qtv/config.cfg ] \
                && [ -f $directory/qwfwd/config.cfg ]
                then
                        [ "$silent" != "1" ] || printf "* Creating symlinks to configuration files..."
                        rm -f ~/.cfortsv/server.conf ~/.cfortsv/qtv.conf ~/.cfortsv/qwfwd.conf
                        ln -s $directory/fortress/config.cfg ~/.cfortsv/server.conf > /dev/null
                        ln -s $directory/qtv/config.cfg ~/.cfortsv/qtv.conf
                        ln -s $directory/qwfwd/config.cfg ~/.cfortsv/qwfwd.conf
                        [ "$silent" != "1" ] || echo "[OK]"
                else
                        [ "$silent" != "1" ] || echo "ERROR: Your installation is missing important configuration files. Please reinstall Classic Fortress."
                        exit
                fi
        else
                [ "$silent" != "1" ] || echo "ERROR: Your installation is broken. Please reinstall Classic Fortress."
                exit
        fi
fi

# check if classic fortress configuration file has been altered
if (grep -Fq "//hostname" ~/.cfortsv/server.conf) \
|| (grep -Fq "//rcon_password" ~/.cfortsv/server.conf) \
|| (grep -Fq "//sv_admininfo" ~/.cfortsv/server.conf)
then
        [ "$silent" != "1" ] || echo "ERROR: You need to configure ~/.cfortsv/server.conf"
        exit
fi
if (grep -Fq "rcon_password \"abc123\"" ~/.cfortsv/server.conf)
then
        [ "$silent" != "1" ] || echo "ERROR: Default rcon password cannot be used in ~/.cfortsv/server.conf"
        exit
fi
if (grep -Fxq "quit" ~/.cfortsv/server.conf)
then
        [ "$silent" != "1" ] || echo "ERROR: You forgot to remove the \"quit\" line in ~/.cfortsv/server.conf"
        exit
fi

# check if qtv configuration file has been altered
if (grep -Fq "//hostname" ~/.cfortsv/qtv.conf) \
|| (grep -Fq "//admin_password" ~/.cfortsv/qtv.conf)
then
        [ "$silent" != "1" ] || echo "ERROR: You need to configure ~/.cfortsv/qtv.conf"
        exit
fi
if (grep -Fq "admin_password \"abc123\"" ~/.cfortsv/qtv.conf)
then
        [ "$silent" != "1" ] || echo "ERROR: Default admin password cannot be used in ~/.cfortsv/qtv.conf"
        exit
fi
if (grep -Fxq "quit" ~/.cfortsv/qtv.conf)
then
        [ "$silent" != "1" ] || echo "ERROR: You forgot to remove the \"quit\" line in ~/.cfortsv/qtv.conf"
        exit
fi

# check if qwfwd configuration file has been altered
if (grep -Fq "//set hostname" ~/.cfortsv/qwfwd.conf)
then
        [ "$silent" != "1" ] || echo "ERROR: You need to configure ~/.cfortsv/qwfwd.conf"
        exit
fi
if (grep -Fxq "quit" ~/.cfortsv/qwfwd.conf)
then
        [ "$silent" != "1" ] || echo "ERROR: You forgot to remove the \"quit\" line in ~/.cfortsv/qwfwd.conf"
        exit
fi

# start mvdsv
cd $(cat ~/.cfortsv/install_dir)
[ "$silent" != "1" ] || echo -n "* Starting server (port 27500)..."
start=1
if [ -f ~/.cfortsv/pid/server ]
then
        pid=$(cat ~/.cfortsv/pid/server)
        if ps -p $pid > /dev/null
        then
                if ps -p $pid | grep mvdsv | grep -v grep > /dev/null
                then
                        [ "$silent" != "1" ] || echo "[ALREADY RUNNING]"
                        start=0
                fi
        fi
fi
if [ $start == 1 ]
then
        ./mvdsv > /dev/null &
        echo $! > ~/.cfortsv/pid/server
        [ "$silent" != "1" ] || echo "[OK]"
fi

# start qtv
cd $(cat ~/.cfortsv/install_dir)/qtv
[ "$silent" != "1" ] || echo -n "* Starting qtv (port 28000)..."
start=1
if [ -f ~/.cfortsv/pid/qtv ]
then
        pid=$(cat ~/.cfortsv/pid/qtv)
        if ps -p $pid > /dev/null
        then
                if ps -p $pid | grep qtv | grep -v grep > /dev/null
                then
                        [ "$silent" != "1" ] || echo "[ALREADY RUNNING]"
                        start=0
                fi
        fi
fi
if [ $start == 1 ]
then
        ./qtv.bin +exec qtv.cfg > /dev/null &
        echo $! > ~/.cfortsv/pid/qtv
        [ "$silent" != "1" ] || echo "[OK]"
fi

# start qwfwd
cd $(cat ~/.cfortsv/install_dir)/qwfwd
[ "$silent" != "1" ] || echo -n "* Starting qwfwd (port 30000)..."
start=1
if [ -f ~/.cfortsv/pid/qwfwd ]
then
        pid=$(cat ~/.cfortsv/pid/qwfwd)
        if ps -p $pid > /dev/null
        then
                if ps -p $pid | grep qwfwd | grep -v grep > /dev/null
                then
                        [ "$silent" != "1" ] || echo "[ALREADY RUNNING]"
                        start=0
                fi
        fi
fi
if [ $start == 1 ]
then
        ./qwfwd.bin > /dev/null &
        echo $! > ~/.cfortsv/pid/qwfwd
        [ "$silent" != "1" ] || echo "[OK]"
fi