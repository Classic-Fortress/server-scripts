#!/bin/sh

#############################################
## CLASSIC FORTRESS UPDATE BINARIES SCRIPT ##
#############################################

# parameters:
# --silent      makes the script silent and will
#               automatically select a mirror and
#               restart your servers and proxies.
# --no-restart  will stop the script from auto-
#               matically restarting your servers
#               and proxies.

######################
##  INITIALIZATION  ##
######################

# functions
error() {
    [ $silent -eq 0 ] && {
        echo
        printf "%s\n" "$*"
    }

    # remove temporary directory if it exists
    [ -d $tmpdir ] && rm -rf $tmpdir

    # remove backup directory if it's empty
    [ ! -z "$(ls -1 $backupdir)" ] && -rf $backupdir

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
iffailed() {
    [ $silent -eq 0 ] && [ $fail -eq 1 ] && {
        echo "fail"
        printf "%s\n" "$*"
        exit 1
    }

    return 1
}

# initialize variables
eval settingsdir="~/.cfortsv"
eval serverdir="$(cat $settingsdir/install_dir)"
eval backupdir=$serverdir/backup
eval tmpdir=$settingsdir/tmp
silent=0
norestart=0
fail=0

# initialize folders
mkdir -p $tmpdir $backupdir

# set silent mode if --silent parameter given
[ "$1" = "--silent" ] || [ "$2" = "--silent" ] && silent=1

# set restart mode if --restart parameter given
[ "$1" = "--no-restart" ] || [ "$2" = "--no-restart" ] && norestart=1

# check if unzip and curl are installed
[ `which unzip` ] || error "ERROR: The package 'unzip' is not installed. Please install it and run the installation again."
[ `which curl` ] || error "ERROR: The package 'curl' is not installed. Please install it and run the installation again."

# download cfort.ini
curl --silent --output $tmpdir/cfort.ini https://raw.githubusercontent.com/Classic-Fortress/client-installer/master/cfort.ini || \
    error "ERROR: Failed to download 'cfort.ini' (mirror information) from remote server."

# check if cfort.ini actually contains anything
[ -s "$tmpdir/cfort.ini" ] || error "ERROR: Downloaded 'cfort.ini' but file is empty. Exiting."

######################
## MIRROR SELECTION ##
######################

# skip mirror selection if --silent was specified
[ $silent -eq 0 ] && {

    outputn "Select a download mirror:"

    # print mirrors and number them
    grep "[0-9]\{1,2\}=\".*" $tmpdir/cfort.ini | cut -d "\"" -f2 | nl

    output "Enter mirror number [random]: "

    # read user's input
    read mirror

    # get mirror address from cfort.ini
    mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" $tmpdir/cfort.ini | cut -d "=" -f2)

}

# count mirrors
mirrors=$(grep "[0-9]=\"" $tmpdir/cfort.ini | wc -l)

[ -z $mirror ] && [ $mirrors -gt 1 ] && {

    # calculate range (amount of mirrors + 1)
    range=$(expr$(grep "[0-9]=\"" $tmpdir/cfort.ini | nl | tail -n1 | cut -f1) + 1)

    while [ -z $mirror ]; do

        # generate a random number
        number=$RANDOM

        # divide the random number with the calculated range and put the remainder in $number
        let "number %= $range"

        # get the nth mirror using the random number
        mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" $tmpdir/cfort.ini | cut -d "=" -f2)

    done

} || mirror=$(grep "^1=[fhtp]\{3,4\}://[^ ]*$" $tmpdir/cfort.ini | cut -d "=" -f2)

# ask to restart servers if --silent and --no-restart were not used
[ $silent -eq 1 ] || [ $norestart -eq 1 ] && restart="n" || { outputn; read -p "Restart servers and proxies? (y/n) [y]: " restart; }

######################
##     DOWNLOAD     ##
######################

outputn
output "Installing binaries..."

# detect system architecture
[ $(getconf LONG_BIT) = 64 ] && arch=x64 || arch=x86

# download binaries
curl --silent --output $tmpdir/cfortsv-bin.zip $mirror/cfortsv-bin-$arch.zip || fail=1
[ -s $tmpdir/cfortsv-bin.zip ] || fail=1

iffailed "ERROR: Could not download binaries. Try again later." || output "."

######################
##    UNPACKING     ##
######################

# unpack binaries
unzip -qqo $tmpdir/cfortsv-bin.zip -d $tmpdir 2>/dev/null || fail=1

iffailed "ERROR: Could not unpack binaries. Try running the script again." || output "."

######################
##   STOP SERVERS   ##
######################

# stop servers and proxies if set to restart
[ "$restart" != "n" ] && ($serverdir/stop_servers.sh --silent || fail=1)

iffailed "ERROR: Could not stop servers and proxies. Exiting." || output "."

######################
##      BACKUP      ##
######################

# create a tar/gzip of old binaries in backup directory
backupname="binaries-backup-$(date +"%Y%m%d%H%M%S").tar.gz"
(cd $serverdir && tar czf $backupname fortress/qwprogs.dat qtv/qtv.bin qwfwd/qwfwd.bin mvdsv 2>/dev/null) || fail=1
mv $backupname $backupdir 2>/dev/null || fail=1

iffailed "ERROR: Could not move old binaries to backup directory. Something might be wrong with your installation." || output "."

######################
##   INSTALLATION   ##
######################

# set permissions
chmod -f 644 "$tmpdir/fortress/qwprogs.dat" 2>/dev/null || fail=1
chmod -f 755 "$tmpdir/qtv/qtv.bin" 2>/dev/null || fail=1
chmod -f 755 "$tmpdir/qwfwd/qwfwd.bin" 2>/dev/null || fail=1
chmod -f 755 "$tmpdir/mvdsv" 2>/dev/null || fail=1

iffailed "ERROR: Could not set proper permissions for installed binaries. Perhaps you have some permission problems." || output "."

# move stuff to server folder
mv "$tmpdir/mvdsv" "$serverdir/mvdsv" 2>/dev/null || fail=1
mv "$tmpdir/fortress/qwprogs.dat" "$serverdir/fortress/qwprogs.dat" 2>/dev/null || fail=1
mv "$tmpdir/qtv/qtv.bin" "$serverdir/qtv/qtv.bin" 2>/dev/null || fail=1
mv "$tmpdir/qwfwd/qwfwd.bin" "$serverdir/qwfwd/qwfwd.bin" 2>/dev/null || fail=1

iffailed "ERROR: Could not install binaries in server directory. Perhaps you have some permission problems." || output "."

######################
##  START SERVERS   ##
######################

# start servers and proxies if set to restart
[ "$restart" != "n" ] && ($serverdir/start_servers.sh --silent || fail=1)

iffailed "ERROR: Could not restart servers and proxies. Try restarting them manually." || output "."

######################
##     CLEANUP      ##
######################

# remove temporary directory
rm -rf $tmpdir || fail=1

iffailed "ERROR: Could not remove temporary directory '$tmpdir'. Perhaps you have some permission problems." || outputn "done"

exit 0
