#!/bin/bash

# Classic Fortress maps update bash script (for Linux)
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
mkdir -p $tmpdirectory
cd $tmpdirectory

echo
echo "Welcome to the Classic Fortress maps updater"
echo "==================================="
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

# Download maps
echo "=== Downloading ==="
wget --inet4-only -O cfortsv-maps.zip $mirror/cfortsv-maps.zip || error "Failed to download $mirror/cfortsv-maps.zip"
[ -s "cfortsv-maps.zip" ] || error "Downloaded cfortsv-maps.zip but file is empty?!"

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

# Extract maps
echo -n "* Extracting maps..."
(unzip -qqo cfortsv-maps.zip 2>/dev/null && echo done) || echo fail

# Set the correct permissions
echo -n "* Setting permissions..."
chmod 644 fortress/maps/* 2> /dev/null
echo "done"


# Stop servers
if [ "$restart" == "y" ]; then
        printf "* Stopping processes..."
        [ ! -e "../stop_servers.sh" ] || ../stop_servers.sh --silent
        echo "done"
fi

# Move maps into place
printf "* Moving maps into place..."
mv -f fortress/maps/* ../fortress/maps/
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

echo;echo "Update complete."
echo
