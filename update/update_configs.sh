#!/bin/sh

#############################################
## CLASSIC FORTRESS UPDATE BINARIES SCRIPT ##
#############################################

# parameters:
# --silent      makes the script silent and will
#               automatically restart your servers
#               and proxies.
# --no-restart  will stop the script from auto-
#               matically restarting your servers
#               and proxies.

##################################################
## script starts here - do not edit lines below ##
##################################################

# functions
error() {
    [ $silent -eq 0 ] && {
        echo
        printf "ERROR: %s\n" "$*"
    }

    cd

    # remove temporary directory if it exists
    [ -d $tmpdir ] && rm -rf $tmpdir

    # remove backup directory if it's empty
    [ ! -z "$(ls -1 $backupdir)" ] && rm -rf $backupdir

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

# initialize variables
eval settingsdir=~/.cfortsv
eval serverdir=$(cat $settingsdir/install_dir)
eval backupdir=$serverdir/backup
eval tmpdir=$serverdir/tmp
github=https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/
silent=0
norestart=0
fail=0

# initialize folders
mkdir -p $tmpdir $tmpdir/fortress $tmpdir/qtv $tmpdir/qw $tmpdir/qwfwd $backupdir
cd $tmpdir

# set silent mode if --silent parameter given
[ "$1" = "--silent" ] || [ "$2" = "--silent" ] && silent=1

# set restart mode if --restart parameter given
[ "$1" = "--no-restart" ] || [ "$2" = "--no-restart" ] && norestart=1

# check if unzip and curl are installed
[ `which unzip` ] || error "The package 'unzip' is not installed. Please install it and run the installation again."
[ `which curl` ] || error "The package 'curl' is not installed. Please install it and run the installation again."

# ask to restart servers if --silent and --no-restart were not used
[ $silent -eq 0 ] && {

    [ $norestart -eq 1 ] && restart="n" || read -p "Restart servers and proxies? (y/n) [y]: " restart

}

output "Installing configs..."

# download configs
curl --silent --output $tmpdir/fortress/fortress.cfg $github/config/fortress/fortress.cfg && output "." || fail=1
curl --silent --output $tmpdir/qtv/qtv.cfg $github/config/qtv/qtv.cfg && output "." || fail=1
curl --silent --output $tmpdir/qw/mvdsv.cfg $github/config/qw/mvdsv.cfg && output "." || fail=1
curl --silent --output $tmpdir/qw/server.cfg $github/config/qw/server.cfg && output "." || fail=1
curl --silent --output $tmpdir/qwfwd/qwfwd.cfg $github/config/qwfwd/qwfwd.cfg && output "." || fail=1
curl --silent --output $tmpdir/getmap.sh $github/update/getmap.sh && output "." || fail=1
curl --silent --output $tmpdir/update_binaries.sh $github/update/update_binaries.sh && output "." || fail=1
curl --silent --output $tmpdir/update_configs.sh $github/update/update_configs.sh && output "." || fail=1
curl --silent --output $tmpdir/update_maps.sh $github/update/update_maps.sh && output "." || fail=1
curl --silent --output $tmpdir/start_servers.sh $github/run/start_servers.sh && output "." || fail=1
curl --silent --output $tmpdir/stop_servers.sh $github/run/stop_servers.sh && output "." || fail=1
[ -s $serverdir/fortress/config.cfg ] || curl --silent --output $serverdir/fortress/config.cfg $github/config/fortress/config.cfg && output "." || fail=1
[ -s $serverdir/qtv/config.cfg ] || curl --silent --output $serverdir/qtv/config.cfg $github/config/qtv/config.cfg && output "." || fail=1
[ -s $serverdir/qwfwd/config.cfg ] || curl --silent --output $serverdir/qwfwd/config.cfg $github/config/qwfwd/config.cfg && output "." || fail=1

# check if files contain anything
[ -s $tmpdir/fortress/fortress.cfg ] || fail=1
[ -s $tmpdir/qtv/qtv.cfg ] || fail=1
[ -s $tmpdir/qw/mvdsv.cfg ] || fail=1
[ -s $tmpdir/qw/server.cfg ] || fail=1
[ -s $tmpdir/qwfwd/qwfwd.cfg ] || fail=1
[ -s $tmpdir/getmap.sh ] || fail=1
[ -s $tmpdir/update_binaries.sh ] || fail=1
[ -s $tmpdir/update_configs.sh ] || fail=1
[ -s $tmpdir/update_maps.sh ] || fail=1
[ -s $tmpdir/start_servers.sh ] || fail=1
[ -s $tmpdir/stop_servers.sh ] || fail=1
[ -s $serverdir/fortress/config.cfg ] || fail=1
[ -s $serverdir/qtv/config.cfg ] || fail=1
[ -s $serverdir/qwfwd/config.cfg ] || fail=1

# abort if download failed
[ $fail -eq 0 ] && output "." || {

    outputn "fail"

    error "Could not download configuration files. Try again later."

}

# stop servers and proxies if set to restart
[ "$restart" = "y" ] && {

    ($serverdir/stop_servers.sh --silent && output ".") || {

        outputn "fail"

        error "Could not stop servers and proxies. Exiting."

    }

}

# create a tar.gz of old configs in backup directory
cd $serverdir
backupname="configs-backup-$(date +"%Y%m%d%H%M%S").tar.gz"
tar czf $backupname \
    fortress/fortress.cfg \
    qtv/qtv.cfg \
    qw/mvdsv.cfg \
    qw/server.cfg \
    qwfwd/qwfwd.cfg \
    getmap.sh \
    start_servers.sh \
    stop_servers.sh \
    update_binaries.sh \
    update_configs.sh \
    update_maps.sh \
    2>/dev/null
mv $backupname $backupdir 2>/dev/null || fail=1

# abort if moving of old binaries failed
[ $fail -eq 0 ] && output "." || {

    outputn "fail"

    error "Could not move old configs to backup directory. Something might be wrong with your installation."

}

# move new stuff to working directory
find $tmpdir -name "*.cfg" -exec chmod 644 {} \;
find $tmpdir -name "*.sh" -exec chmod +x {} \;
mv $tmpdir/fortress/fortress.cfg $serverdir/fortress/fortress.cfg 2>/dev/null || fail=1
mv $tmpdir/qtv/qtv.cfg $serverdir/qtv/qtv.cfg 2>/dev/null || fail=1
mv $tmpdir/qw/mvdsv.cfg $serverdir/qw/mvdsv.cfg 2>/dev/null || fail=1
mv $tmpdir/qw/server.cfg $serverdir/qw/server.cfg 2>/dev/null || fail=1
mv $tmpdir/qwfwd/qwfwd.cfg $serverdir/qwfwd/qwfwd.cfg 2>/dev/null || fail=1
mv $tmpdir/getmap.sh $serverdir/getmap.sh 2>/dev/null || fail=1
mv $tmpdir/update_binaries.sh $serverdir/update_binaries.sh 2>/dev/null || fail=1
mv $tmpdir/update_configs.sh $serverdir/update_configs.sh 2>/dev/null || fail=1
mv $tmpdir/update_maps.sh $serverdir/update_maps.sh 2>/dev/null || fail=1
mv $tmpdir/start_servers.sh $serverdir/start_servers.sh 2>/dev/null || fail=1
mv $tmpdir/stop_servers.sh $serverdir/stop_servers.sh 2>/dev/null || fail=1
[ -s $tmpdir/fortress/config.cfg ] && (mv $tmpdir/fortress/config.cfg $serverdir/fortress/config.cfg 2>/dev/null || fail=1)
[ -s $tmpdir/qwfwd/config.cfg ] && (mv $tmpdir/qwfwd/config.cfg $serverdir/qwfwd/config.cfg 2>/dev/null || fail=1)
[ -s $tmpdir/qtv/config.cfg ] && (mv $tmpdir/qtv/config.cfg $serverdir/qtv/config.cfg 2>/dev/null || fail=1)

# abort if moving of binaries failed
[ $fail -eq 0 ] && output "." || {

    outputn "fail"

    error "Could not install configs in server directory. Something might be wrong with your installation."

}

# remove temporary directory
rm -rf $tmpdir
output "."

# start servers and proxies if set to restart
[ "$restart" = "y" ] && {

    ($serverdir/start_servers.sh --silent && output ".") || {

        outputn "fail"

        error "Could not restart servers and proxies. Try restarting them manually."

    }

}

outputn "done"

exit 0
