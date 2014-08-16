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

##################################################
## script starts here - do not edit lines below ##
##################################################

# functions
error() {
    [ $silent -eq 0 ] && {
        echo
        printf "ERROR: %s\n" "$*"
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

# initialize variables
eval settingsdir="~/.cfortsv"
eval serverdir="$(cat $settingsdir/install_dir)"
eval backupdir=$serverdir/backup
eval tmpdir=$serverdir/tmp
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
[ `which unzip` ] || error "The package 'unzip' is not installed. Please install it and run the installation again."
[ `which curl` ] || error "The package 'curl' is not installed. Please install it and run the installation again."

# download cfort.ini
curl --silent --output $tmpdir/cfort.ini https://raw.githubusercontent.com/Classic-Fortress/client-installer/master/cfort.ini || \
    error "Failed to download 'cfort.ini' (mirror information) from remote server."

# check if cfort.ini actually contains anything
[ -s "$tmpdir/cfort.ini" ] || error "Downloaded 'cfort.ini' but file is empty. Exiting."

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

    while [ -z "$mirror" ]; do

        # generate a random number
        number=$RANDOM

        # divide the random number with the calculated range and put the remainder in $number
        let "number %= $range"

        # get the nth mirror using the random number
        mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" $tmpdir/cfort.ini | cut -d "=" -f2)

    done

} || mirror=$(grep "^1=[fhtp]\{3,4\}://[^ ]*$" $tmpdir/cfort.ini | cut -d "=" -f2)

# ask to restart servers if --silent and --no-restart were not used
[ $silent -eq 0 ] && {

    [ $norestart -eq 1 ] && restart="n" || read -p "Restart servers and proxies? (y/n) [y]: " restart

}

output "Installing binaries..."

# detect system architecture
[ $(getconf LONG_BIT) = 64 ] && {

    # download 64-bit binaries
    curl --silent --output $tmpdir/cfortsv-bin-x64.zip $mirror/cfortsv-bin-x64.zip || fail=1

    # check if downloaded zip actually contains something
    [ -s "$tmpdir/cfortsv-bin-x64.zip" ] || fail=1

} || {

    # download 32-bit binaries
    curl --silent --output $tmpdir/cfortsv-bin-x86.zip $mirror/cfortsv-bin-x86.zip || fail=1

    # check if downloaded zip actually contains something
    [ -s "$tmpdir/cfortsv-bin-x86.zip" ] || fail=1

}

# abort if download failed
[ $fail -eq 0 ] && output "." || {

    outputn "fail"

    error "Could not download binaries. Try again later."

}

# unpack binaries
[ $(getconf LONG_BIT) = 64 ] && {

    unzip -qqo $tmpdir/cfortsv-bin-x64.zip -d $tmpdir 2>/dev/null || fail=1

} || {

    unzip -qqo $tmpdir/cfortsv-bin-x86.zip -d $tmpdir 2>/dev/null || fail=1

}

# abort if installation failed
[ $fail -eq 0 ] && output "." || {

    outputn "fail"

    error "Could not unpack binaries. Try running the script again."

}

# stop servers and proxies if set to restart
[ "$restart" = "y" ] && {

    ($serverdir/stop_servers.sh --silent && output ".") || {

        outputn "fail"

        error "Could not stop servers and proxies. Exiting."

    }

}

# create a tar.gz of old binaries in backup directory
cd $serverdir
backupname="binaries-backup-$(date +"%Y%m%d%H%M%S").tar.gz"
tar czf $backupname fortress/qwprogs.dat qtv/qtv.bin qwfwd/qwfwd.bin mvdsv 2>/dev/null || fail=1
mv $backupname $backupdir 2>/dev/null || fail=1

# abort if moving of old binaries failed
[ $fail -eq 0 ] && output "." || {

    outputn "fail"

    error "Could not move old binaries to backup directory. Something might be wrong with your installation."

}

# move new stuff to working directory
chmod -f 644 "$tmpdir/fortress/qwprogs.dat" 2>/dev/null
chmod -f 755 "$tmpdir/qtv/qtv.bin" 2>/dev/null
chmod -f 755 "$tmpdir/qwfwd/qwfwd.bin" 2>/dev/null
chmod -f 755 "$tmpdir/mvdsv" 2>/dev/null
mv "$tmpdir/mvdsv" "$serverdir/mvdsv" 2>/dev/null || fail=1
mv "$tmpdir/fortress/qwprogs.dat" "$serverdir/fortress/qwprogs.dat" 2>/dev/null || fail=1
mv "$tmpdir/qtv/qtv.bin" "$serverdir/qtv/qtv.bin" 2>/dev/null || fail=1
mv "$tmpdir/qwfwd/qwfwd.bin" "$serverdir/qwfwd/qwfwd.bin" 2>/dev/null || fail=1

# abort if moving of binaries failed
[ $fail -eq 0 ] && output "." || {

    outputn "fail"

    error "Could not install binaries in server directory. Something might be wrong with your installation."

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
