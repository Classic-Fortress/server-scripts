#!/bin/sh

###################################
## CLASSIC FORTRESS START SCRIPT ##
###################################

# use services (0 = disable, 1 = enable)
use_mvdsv=1
use_qtv=1
use_qwfwd=1

# ports to use
mvdsv_port=27500
qtv_port=28000

# use screen (0 = disable, 1 = enable)
use_screen=0

# save logs in ~/.cfortsv/logs/ (0 = disable, 1 = enable)
logging=1

######################
##  INITIALIZATION  ##
######################

# print functions
error() {
    [ $silent -eq 0 ] && printf "%s\n" "$*"

    exit 1
}
output() {
    [ $silent -eq 0 ] && printf "%s" "$*"

    return 0
}
outputn() {
    [ $silent -eq 0 ] && printf "%s\n" "$*"

    return 0
}
ifsuccess() {
    [ $silent -eq 0 ] && ([ $fail -eq 1 ] && echo "[FAIL]" || printf "%s\n" "$*")

    return 1
}

# initialize variables
eval settingsdir=~/.cfortsv
eval serverdir=$(cat $settingsdir/install_dir)
silent=0
error=0
fail=0

# initialize folders and files
mkdir -p $settingsdir/pid
[ $logging -eq 1 ] && {
    mkdir -p $settingsdir/logs
    [ $use_mvdsv -eq 1 ] && touch $settingsdir/logs/server.log
}

# set silent mode if first parameter is --silent
[ "$1" = "--silent" ] && silent=1

# check if screen exists if it's to be used
[ $use_screen -eq 1 ] && [ ! `which screen` ] && \
    error "ERROR: The package 'screen' is not installed. Please install it or disable it."

# check if anything is to be done
[ $use_mvdsv -ne 1 ] && [ $use_qtv -ne 1 ] && [ $use_qwfwd -ne 1 ] && \
    error "ERROR: No services to start. Please edit start_servers.sh."

# check if configuration files exist
[ ! -f $settingsdir/server.conf ] || [ ! -f $settingsdir/qtv.conf ] || [ ! -f $settingsdir/qwfwd.conf ] && {

    outputn "WARNING: Symlinks to configuration files missing."

    [ -f $settingsdir/install_dir ] && {

        [ -f $settingsdir/server.conf ] && [ -f $settingsdir/qtv.conf ] && [ -f $settingsdir/qwfwd.conf ] && {

            output "Creating symlinks to configuration files..."

            [ ! -L $serverdir/fortress/config.cfg ] ln -s $settingsdir/server.conf $serverdir/fortress/config.cfg 2>/dev/null || fail=1
            [ ! -L $serverdir/qtv/config.cfg ] ln -s $settingsdir/qtv.conf $serverdir/qtv/config.cfg 2>/dev/null || fail=1
            [ ! -L $serverdir/qwfwd/config.cfg ] ln -s $settingsdir/qwfwd.conf $serverdir/qwfwd/config.cfg 2>/dev/null || fail=1

            ifsuccess "[OK]"

        } || error "ERROR: Your installation is missing important configuration files. Please reinstall Classic Fortress."

    } || error "ERROR: Your installation is broken. Please reinstall Classic Fortress."

}

######################
##  MVDSV STARTUP   ##
######################

[ $use_mvdsv -eq 1 ] && {

    # check if classic fortress configuration file has been altered
    [ "$(grep -F "//hostname" $settingsdir/server.conf)" ] || [ "$(grep -F "//rcon_password" $settingsdir/server.conf)" ] || [ "$(grep -F "//sv_admininfo" $settingsdir/server.conf)" ] && \
        error "ERROR: You need to configure $settingsdir/server.conf"

    # check if rcon password has been changed from the default value
    [ "$(grep -F "rcon_password \"abc123\"" $settingsdir/server.conf)" ] && \
        error "ERROR: Default rcon password cannot be used in $settingsdir/server.conf"

    # check if the quit line has been removed
    [ "$(grep -Fx "quit" $settingsdir/server.conf)" ] && \
        error "ERROR: You forgot to remove the \"quit\" line in $settingsdir/server.conf"

    # check if mvdsv can be run (32-bit libraries)
    ldd $serverdir/mvdsv >/dev/null || error "ERROR: Could not start mvdsv due to 32-bit glibc missing."

    cd $serverdir

    output "* Starting mvdsv (port $mvdsv_port)..."

    # check if process id has been saved
    [ -f $settingsdir/pid/server ] && pid=$(cat $settingsdir/pid/server) || pid=0

    [ $use_screen -eq 1 ] && {

        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep screen | grep -v grep)" ] && outputn "[ALREADY RUNNING]" || {

            # use screen to resume server window later
            screen -dmS mvdsv ./mvdsv -port $mvdsv_port +set qtv_streamport $mvdsv_port 2>/dev/null || fail=1

            # store process id in settings folder
            screen_info=$(screen -ls | grep mvdsv | sed -r 's/\s//g' | head -1)
            pid=${screen_info%%.*}
            [ $pid -gt 0 ] || fail=1

            # store process id in settings folder
            echo $pid > $settingsdir/pid/server 2>/dev/null || fail=1

            ifsuccess "[OK]"

        }

    } || {

        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep mvdsv | grep -v grep)" ] && outputn "[ALREADY RUNNING]" || {

            [ $logging -eq 1 ] && {

                # log to logs dir if logging is enabled
                ./mvdsv -port $mvdsv_port +set qtv_streamport $mvdsv_port >> $settingsdir/logs/server.log &

            } || {

                # start mvdsv in the background
                ./mvdsv -port $mvdsv_port +set qtv_streamport $mvdsv_port >/dev/null &

            }

            # store process id in settings folder
            echo $! > $settingsdir/pid/server 2>/dev/null || fail=1

            ifsuccess "[OK]"

        }

    }

}

######################
##   QTV STARTUP    ##
######################

[ $use_qtv -eq 1 ] && {

    # check if qtv configuration file has been altered
    [ "$(grep -F "//hostname" $settingsdir/qtv.conf)" ] || [ "$(grep -F "//admin_password" $settingsdir/qtv.conf)" ] && \
        error "ERROR: You need to configure $settingsdir/qtv.conf"

    # check if admin password has been changed from the default value
    [ "$(grep -F "admin_password \"abc123\"" $settingsdir/qtv.conf)" ] && \
        error "ERROR: Default admin password cannot be used in $settingsdir/qtv.conf"

    # check if the quit line has been removed
    [ "$(grep -Fx "quit" $settingsdir/qtv.conf)" ] && \
        error "ERROR: You forgot to remove the \"quit\" line in $settingsdir/qtv.conf"

    cd $serverdir/qtv

    output "* Starting qtv (port $qtv_port)....."

    # check if process id has been saved
    [ -f $settingsdir/pid/qtv ] && pid=$(cat $settingsdir/pid/qtv) || pid=0

    [ $use_screen -eq 1 ] && {

        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep screen | grep -v grep)" ] && outputn "[ALREADY RUNNING]" || {

            # use screen to resume qtv window later
            screen -dmS qtv ./qtv.bin +exec qtv.cfg +mvdport $qtv_port 2>/dev/null || fail=1

            # store process id in settings folder
            screen_info=$(screen -ls | grep qtv | sed -r 's/\s//g' | head -1)
            pid=${screen_info%%.*}
            [ $pid -gt 0 ] || fail=1

            # store process id in settings folder
            echo $pid > $settingsdir/pid/qtv 2>/dev/null || fail=1

            ifsuccess "[OK]"

        }

    } || {

        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep qtv | grep -v grep)" ] && outputn "[ALREADY RUNNING]" || {

            # start qtv in the background
            ./qtv.bin +exec qtv.cfg +mvdport $qtv_port >/dev/null &

            # store process id in settings folder
            echo $! > $settingsdir/pid/qtv 2>/dev/null || fail=1

            ifsuccess "[OK]"

        }

    }

}

######################
##  QWFWD STARTUP   ##
######################

[ $use_qwfwd -eq 1 ] && {

    # check if qwfwd configuration file has been altered
    [ "$(grep -F "//set hostname" $settingsdir/qwfwd.conf)" ] && \
        error "ERROR: You need to configure $settingsdir/qwfwd.conf"

    # check if the quit line has been removed
    [ "$(grep -Fx "quit" $settingsdir/qwfwd.conf)" ] && \
        error "ERROR: You forgot to remove the \"quit\" line in $settingsdir/qwfwd.conf"

    cd $serverdir/qwfwd

    output "* Starting qwfwd (port 30000)..."

    # check if process id has been saved
    [ -f $settingsdir/pid/qwfwd ] && pid=$(cat $settingsdir/pid/qwfwd) || pid=0

    [ $use_screen -eq 1 ] && {

        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep screen | grep -v grep)" ] && outputn "[ALREADY RUNNING]" || {

            # use screen to resume qwfwd window later
            screen -dmS qwfwd ./qwfwd.bin 2>/dev/null || fail=1

            # store process id in settings folder
            screen_info=$(screen -ls | grep qwfwd | sed -r 's/\s//g' | head -1)
            pid=${screen_info%%.*}
            [ $pid -gt 0 ] || fail=1

            # store process id in settings folder
            echo $pid > $settingsdir/pid/qwfwd 2>/dev/null || fail=1

            ifsuccess "[OK]"

        }

    } || {

        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep qwfwd | grep -v grep)" ] && outputn "[ALREADY RUNNING]" || {

            # start qwfwd in the background
            ./qwfwd.bin >/dev/null &

            # store process id in settings folder
            echo $! > $settingsdir/pid/qwfwd 2>/dev/null || fail=1

            ifsuccess "[OK]"

        }

    }

}

######################
##     NOTICES      ##
######################

# display screen help message if used
[ $use_screen -eq 1 ] && [ $silent -eq 0 ] && {

    echo
    printf "Resume screen sessions using 'screen -x "
    [ $use_mvdsv -eq 1 ] && {

        printf "mvdsv"
        [ $use_qtv -eq 1 ] || [ $use_qwfwd -eq 1 ] && printf "|"

    }
    [ $use_qtv -eq 1 ] && {

        printf "qtv"
        [ $use_qwfwd -eq 1 ] && printf "|"

    }
    [ $use_qwfwd -eq 1 ] && {

        printf "qwfwd"

    }
    echo "'"

}

exit 0
