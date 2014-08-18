#!/bin/sh

##################################
## CLASSIC FORTRESS STOP SCRIPT ##
##################################

# settings can be changed within start_servers.sh

######################
##  INITIALIZATION  ##
######################

# print functions
output() {
    [ $silent -eq 0 ] && printf "%s" "$*"

    return 0
}
outputn() {
    [ $silent -eq 0 ] && printf "%s\n" "$*"

    return 0
}

# initialize variables
eval settingsdir=~/.cfortsv
eval serverdir=$(cat $settingsdir/install_dir)
silent=0

# get settings from start_servers.sh
[ `grep -F "use_screen=1" $serverdir/start_servers.sh` ] && use_screen=$(grep -F "use_screen=" $serverdir/start_servers.sh | sed -e 's/use_screen=//') || use_screen=0
[ `grep -F "use_mvdsv=1" $serverdir/start_servers.sh` ] && use_mvdsv=1 || use_mvdsv=0
[ `grep -F "use_qtv=1" $serverdir/start_servers.sh` ] && use_qtv=1 || use_qtv=0
[ `grep -F "use_qwfwd=1" $serverdir/start_servers.sh` ] && use_qwfwd=1 || use_qwfwd=0
[ `grep -F "mvdsv_port=" $serverdir/start_servers.sh` ] && mvdsv_port=$(grep -F "mvdsv_port=" $serverdir/start_servers.sh | sed -e 's/mvdsv_port=//') || mvdsv_port=27500
[ `grep -F "qtv_port=" $serverdir/start_servers.sh` ] && qtv_port=$(grep -F "qtv_port=" $serverdir/start_servers.sh | sed -e 's/qtv_port=//') || qtv_port=28000

# set silent mode if first parameter is --silent
[ "$1" = "--silent" ] && silent=1

#######################
## MVDSV TERMINATION ##
#######################

[ $use_mvdsv -eq 1 ] && {

    output "* Stopping mvdsv (port $mvdsv_port)..."

    # check if process id has been saved
    [ -f $settingsdir/pid/server ] && pid=$(cat $settingsdir/pid/server) || pid=0

    [ $use_screen -eq 1 ] && {

        # check if process is running
        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep screen | grep -v grep)" ] && {
        
            # kill process
            kill -9 $pid >/dev/null 2>&1

            outputn "[OK]"

        } || outputn "[NOT RUNNING]"

    } || {

        # check if process is running
        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep mvdsv | grep -v grep)" ] && {

            # kill process
            kill -9 $pid >/dev/null 2>&1

            outputn "[OK]"

        } || outputn "[NOT RUNNING]"

    }

    # remove process id file
    rm -f $settingsdir/pid/server

}

######################
## QTV TERMINATION  ##
######################

[ $use_qtv -eq 1 ] && {

    output "* Stopping qtv (port $qtv_port)....."

    # check if process id has been saved
    [ -f $settingsdir/pid/qtv ] && pid=$(cat $settingsdir/pid/qtv) || pid=0

    [ $use_screen -eq 1 ] && {

        # check if process is running
        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep screen | grep -v grep)" ] && {
        
            # kill process
            kill -9 $pid >/dev/null 2>&1

            outputn "[OK]"

        } || outputn "[NOT RUNNING]"

    } || {

        # check if process is running
        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep qtv | grep -v grep)" ] && {

            # kill process
            kill -9 $pid >/dev/null 2>&1

            outputn "[OK]"

        } || outputn "[NOT RUNNING]"

    }

    # remove process id file
    rm -f $settingsdir/pid/qtv

}

#######################
## QWFWD TERMINATION ##
#######################

[ $use_qwfwd -eq 1 ] && {

    output "* Stopping qwfwd (port 30000)..."

    # check if process id has been saved
    [ -f $settingsdir/pid/qwfwd ] && pid=$(cat $settingsdir/pid/qwfwd) || pid=0

    [ $use_screen -eq 1 ] && {

        # check if process is running
        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep screen | grep -v grep)" ] && {
        
            # kill process
            kill -9 $pid >/dev/null 2>&1

            outputn "[OK]"

        } || outputn "[NOT RUNNING]"

    } || {

        # check if process is running
        [ $pid -gt 0 ] && [ "$(ps -p $pid | grep qwfwd | grep -v grep)" ] && {

            # kill process
            kill -9 $pid >/dev/null 2>&1

            outputn "[OK]"

        } || outputn "[NOT RUNNING]"

    }

    # remove process id file
    rm -f $settingsdir/pid/qwfwd

}

exit 0
