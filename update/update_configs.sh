#!/bin/sh

# Classic Fortress Configuration Update bash script (for Linux)
# by Empezar

# Parameters: --random-mirror --restart --no-restart --install

# Check if unzip is installed
error() {
        printf "ERROR: %s\n" "$*"
        [ -n "$created" ] || {
                cd
                echo "The directory $tmpdir is about to be removed, press ENTER to confirm or CTRL+C to exit." 
                read dummy
                rm -rf $tmpdir
        }
        exit 1
}

# Check if curl is installed
which curl >/dev/null || error "The package 'curl' is not installed. Please install it and run the installation again."

# Change folder to Classic Fortress
directory=$(cat ~/.cfortsv/install_dir)
tmpdir=$directory/tmp
mkdir -p $tmpdir $tmpdir/fortress $tmpdir/qw $tmpdir/qtv $tmpdir/qwfwd $directory/backup/configs $directory/backup/update $directory/backup/run
cd $tmpdir

echo
echo "Welcome to the Classic Fortress config updater"
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

# Download configuration files
echo "=== Downloading ==="
wget --inet4-only -O fortress/fortress.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/fortress/fortress.cfg || error "Failed to download fortress/fortress.cfg"
wget --inet4-only -O qw/mvdsv.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qw/mvdsv.cfg || error "Failed to download qw/mvdsv.cfg"
wget --inet4-only -O qw/server.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qw/server.cfg || error "Failed to download qw/server.cfg"
wget --inet4-only -O qtv/qtv.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qtv/qtv.cfg || error "Failed to download qtv/qtv.cfg"
wget --inet4-only -O qwfwd/qwfwd.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qwfwd/qwfwd.cfg || error "Failed to download qwfwd/qwfwd.cfg"
wget --inet4-only -O update_binaries.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_binaries.sh || error "Failed to download update_binaries.sh"
wget --inet4-only -O update_configs.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_configs.sh || error "Failed to download update_configs.sh"
wget --inet4-only -O update_maps.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/update/update_maps.sh || error "Failed to download update_maps.sh"
wget --inet4-only -O start_servers.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/run/start_servers.sh || error "Failed to download start_servers.sh"
wget --inet4-only -O stop_servers.sh https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/run/stop_servers.sh || error "Failed to download stop_servers.sh"
[ -s "$directory/fortress/config.cfg" ] || {
        wget --inet4-only -O fortress/config.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/fortress/config.cfg || error "Failed to download fortress/config.cfg"
        [ -s "fortress/config.cfg" ] || error "Downloaded fortress/config.cfg but file is empty?!"
}
[ -s "$directory/qtv/config.cfg" ] || {
        wget --inet4-only -O qtv/config.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qtv/config.cfg || error "Failed to download qtv/config.cfg"
        [ -s "qtv/config.cfg" ] || error "Downloaded qtv/config.cfg but file is empty?!"
}
[ -s "$directory/qwfwd/config.cfg" ] || {
        wget --inet4-only -O qwfwd/config.cfg https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qwfwd/config.cfg || error "Failed to download qwfwd/config.cfg"
        [ -s "qwfwd/config.cfg" ] || error "Downloaded qwfwd/config.cfg but file is empty?!"
}

[ -s "fortress/fortress.cfg" ] || error "Downloaded fortress/fortress.cfg but file is empty?!"
[ -s "qw/mvdsv.cfg" ] || error "Downloaded qw/mvdsv.cfg but file is empty?!"
[ -s "qw/server.cfg" ] || error "Downloaded qw/server.cfg but file is empty?!"
[ -s "qtv/qtv.cfg" ] || error "Downloaded qtv/qtv.cfg but file is empty?!"
[ -s "qwfwd/qwfwd.cfg" ] || error "Downloaded qwfwd/qwfwd.cfg but file is empty?!"
[ -s "update_binaries.sh" ] || error "Downloaded update_binaries.sh but file is empty?!"
[ -s "update_configs.sh" ] || error "Downloaded update_configs.sh but file is empty?!"
[ -s "update_maps.sh" ] || error "Downloaded update_maps.sh but file is empty?!"
[ -s "start_servers.sh" ] || error "Downloaded start_servers.sh but file is empty?!"
[ -s "stop_servers.sh" ] || error "Downloaded stop_servers.sh but file is empty?!"

echo


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

# Convert DOS files to UNIX
printf "* Converting DOS files to UNIX..."
for file in $(find $tmpdir -type f -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README")
do
    [ ! -f "$file" ] || cat $file|tr -d '\015' > tmpfile
    rm $file
    mv tmpfile $file
done
echo "done"

# Set the correct permissions
echo -n "* Setting permissions..."
find . -type f -exec chmod -f 644 {} \;
chmod -f +x *.sh 2> /dev/null
echo "done"

# Stop servers
if [ "$restart" == "y" ]; then
        printf "* Stopping processes..."
        [ ! -e "../stop_servers.sh" ] || ../stop_servers.sh --silent
        echo "done"
fi

# Move configs into place
echo -n "* Moving configs into place..."
chmod -f -x "$directory/start_servers.sh" 2> /dev/null
chmod -f -x "$directory/stop_servers.sh" 2> /dev/null
chmod -f -x "$directory/update_binaries.sh" 2> /dev/null
chmod -f -x "$directory/update_configs.sh" 2> /dev/null
chmod -f -x "$directory/update_maps.sh" 2> /dev/null
[ ! -e "$directory/fortress/fortress.cfg" ] || mv "$directory/fortress/fortress.cfg" "$directory/backup/configs/fortress.cfg"
[ ! -e "$directory/qw/mvdsv.cfg" ] || mv "$directory/qw/mvdsv.cfg" "$directory/backup/configs/mvdsv.cfg"
[ ! -e "$directory/qw/server.cfg" ] || mv "$directory/qw/server.cfg" "$directory/backup/configs/server.cfg"
[ ! -e "$directory/qtv/qtv.cfg" ] || mv "$directory/qtv/qtv.cfg" "$directory/backup/configs/qtv.cfg"
[ ! -e "$directory/qwfwd/qwfwd.cfg" ] || mv "$directory/qwfwd/qwfwd.cfg" "$directory/backup/configs/qwfwd.cfg"
[ ! -e "$directory/update_binaries.sh" ] || mv "$directory/update_binaries.sh" "$directory/backup/update/update_binaries.sh"
[ ! -e "$directory/update_configs.sh" ] || mv "$directory/update_configs.sh" "$directory/backup/update/update_configs.sh"
[ ! -e "$directory/update_maps.sh" ] || mv "$directory/update_maps.sh" "$directory/backup/update/update_maps.sh"
[ ! -e "$directory/start_servers.sh" ] || mv "$directory/start_servers.sh" "$directory/backup/run/start_servers.sh"
[ ! -e "$directory/stop_servers.sh" ] || mv "$directory/stop_servers.sh" "$directory/backup/run/stop_servers.sh"

mv "$tmpdir/fortress/fortress.cfg" "$directory/fortress/fortress.cfg"
mv "$tmpdir/qw/mvdsv.cfg" "$directory/qw/mvdsv.cfg"
mv "$tmpdir/qw/server.cfg" "$directory/qw/server.cfg"
mv "$tmpdir/qtv/qtv.cfg" "$directory/qtv/qtv.cfg"
mv "$tmpdir/qwfwd/qwfwd.cfg" "$directory/qwfwd/qwfwd.cfg"
mv "$tmpdir/update_binaries.sh" "$directory/update_binaries.sh"
mv "$tmpdir/update_configs.sh" "$directory/update_configs.sh"
mv "$tmpdir/update_maps.sh" "$directory/update_maps.sh"
mv "$tmpdir/start_servers.sh" "$directory/start_servers.sh"
mv "$tmpdir/stop_servers.sh" "$directory/stop_servers.sh"
echo "done"

# Remove temporary directory
echo -n "* Cleaning up..."
cd $directory
rm -rf $tmpdir
echo "done"

# Restart servers
if [ "$restart" == "y" ]; then
        printf "* Starting processes..."
        [ ! -e "start_servers.sh" ] || ./start_servers.sh --silent
        echo "done"
fi

echo;echo "Update complete."
echo
