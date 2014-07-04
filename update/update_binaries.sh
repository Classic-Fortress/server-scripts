#!/bin/bash

# Classic Fortress binary update bash script (for Linux)
# by Empezar

# Parameters: --random-mirror --restart --no-restart

error() {
        printf "ERROR: %s\n" "$*"
        [ -n "$created" ] || {
                cd
                echo "The directory $tmpdirectory is about to be removed, press ENTER to confirm or CTRL+C to exit." 
                read dummy
                rm -rf $tmpdirectory
        }
        exit 1
}

# Check if unzip is installed
which unzip >/dev/null || error "The package 'unzip' is not installed. Please install it and run the installation again."

# Check if curl is installed
which curl >/dev/null || error "The package 'curl' is not installed. Please install it and run the installation again."

# Change folder to Classic Fortress
directory=$(cat ~/.cfortsv/install_dir)
tmpdirectory=$directory/tmp
mkdir -p $tmpdirectory $directory/backup/bin
cd $tmpdirectory

echo
echo "Welcome to the Classic Fortress binary updater"
echo "=============================================="
echo

# Download cfort.ini
wget --inet4-only -q -O cfort.ini https://raw.githubusercontent.com/Classic-Fortress/client-installer/master/cfort.ini || error "Failed to download cfort.ini"
[ -s "cfort.ini" ] || error "Downloaded cfort.ini but file is empty?! Exiting."

# List all the available mirrors
echo "From what mirror would you like to download the binaries?"
mirrors=$(grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl | wc -l)
grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl
printf "Enter mirror number [random]: "
read mirror
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
if [ -n "$mirror" && $mirrors > 1 ]; then
        echo;echo -n "* Using mirror: "
        range=$(expr$(grep "[0-9]\{1,2\}=\".*" cfort.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
        while [ -z "$mirror" ]
        do
                number=$RANDOM
                let "number %= $range"
                mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
                mirrorname=$(grep "^$number=\".*" cfort.ini | cut -d "\"" -f2)
        done
        echo "$mirrorname"
else
        mirror=$(grep "^1=[fhtp]\{3,4\}://[^ ]*$" cfort.ini | cut -d "=" -f2)
fi
echo;echo

# Download binaries
echo "=== Downloading ==="
if [ $(getconf LONG_BIT) = 64 ]; then
        wget --inet4-only -O cfortsv-bin-x64.zip $mirror/cfortsv-bin-x64.zip || error "Failed to download $mirror/cfortsv-bin-x64.zip"
        [ -s "cfortsv-bin-x64.zip" ] || error "Downloaded cfortsv-bin-x64.zip but file is empty?!"
else
        wget --inet4-only -O cfortsv-bin-x86.zip $mirror/cfortsv-bin-x86.zip || error "Failed to download $mirror/cfortsv-bin-x86.zip"
        [ -s "cfortsv-bin-x86.zip" ] || error "Downloaded cfortsv-bin-x86.zip but file is empty?!"
fi

# Ask to restart servers
if [ "$1" == "--restart" ] || [ "$2" == "--restart" ] || [ "$3" == "--restart" ] || [ "$4" == "--restart" ]; then
        restart="y"
elif [ "$1" == "--no-restart" ] || [ "$2" == "--no-restart" ] || [ "$3" == "--no-restart" ] || [ "$4" == "--no-restart" ]; then
        restart="n"
else
        read -p "Do you want the script to stop and restart your servers and proxies? (y/n) [n]: " restart
        echo
fi

# Install updates
echo "=== Installing ==="

# Extract binaries
echo -n "* Extracting binaries..."
if [ $(getconf LONG_BIT) = 64 ]; then
    (unzip -qqo cfortsv-bin-x64.zip 2>/dev/null && echo done) || echo fail
else
    (unzip -qqo cfortsv-bin-x86.zip 2>/dev/null && echo done) || echo fail
fi

# Set the correct permissions
printf "* Setting permissions..."
chmod -f +x "$tmpdirectory/mvdsv" 2> /dev/null
chmod -f -x "$directory/mvdsv" 2> /dev/null
chmod 644 "$tmpdirectory/fortress/qwprogs.dat" 2> /dev/null
chmod -f +x "$tmpdirectory/qtv/qtv.bin" 2> /dev/null
chmod -f -x "$directory/qtv/qtv.bin" 2> /dev/null
chmod -f +x "$tmpdirectory/qwfwd/qwfwd.bin" 2> /dev/null
chmod -f -x "$directory/qwfwd/qwfwd.bin" 2> /dev/null
echo "done"

# Stop servers
if [ "$restart" == "y" ]; then
        printf "* Stopping processes..."
        [ ! -e "../stop_servers.sh" ] || ../stop_servers.sh --silent
        echo "done"
fi

# Move binaries into place
printf "* Moving binaries into place..."
[ ! -e "$directory/mvdsv" ] || mv "$directory/mvdsv" "$directory/backup/bin/mvdsv"
mv "$tmpdirectory/mvdsv" "$directory/mvdsv"
[ ! -e "$directory/fortress/qwprogs.dat" ] || mv "$directory/fortress/qwprogs.dat" "$directory/backup/bin/qwprogs.dat"
mv "$tmpdirectory/fortress/qwprogs.dat" "$directory/fortress/qwprogs.dat"
[ ! -e "$directory/qtv/qtv.bin" ] || mv "$directory/qtv/qtv.bin" "$directory/backup/bin/qtv.bin"
mv "$tmpdirectory/qtv/qtv.bin" "$directory/qtv/qtv.bin"
[ ! -e "$directory/qwfwd/qwfwd.bin" ] || mv "$directory/qwfwd/qwfwd.bin" "$directory/backup/bin/qwfwd.bin"
mv "$tmpdirectory/qwfwd/qwfwd.bin" "$directory/qwfwd/qwfwd.bin"
echo "done"

# Remove temporary directory
printf "* Cleaning up..."
cd $directory
rm -rf $tmpdirectory
echo "done"

# Restart servers
if [ "$restart" == "y" ]; then
        printf "* Starting processes..."
        [ ! -e "start_servers.sh" ] || ./start_servers.sh --silent
        echo "done"
fi

echo;echo "Upgrade complete."
echo
