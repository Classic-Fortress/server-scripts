#!/bin/bash

# nQWTFsv binary update bash script (for Linux)
# by Empezar

# Parameters: --random-mirror --restart --no-restart

# Check if unzip is installed
unzip=`which unzip`
if [ "$unzip"  = "" ]
then
        echo "Unzip is not installed. Please install it and run the script again."
        exit
fi

# Change folder to nQWTFsv
cd `cat ~/.nqwtfsv/install_dir`

# Check if QTV and QWFWD is installed
if [ -d "qtv" ]; then qtv="1"; fi;
if [ -d "qwfwd" ]; then qwfwd=1; fi;

echo
echo "Welcome to the nQWTFsv binary updater"
echo "====================================="
echo

# Download nqwtf.ini
mkdir tmp
cd tmp
wget --inet4-only -q -O nqwtf.ini http://nqwtf.sourceforge.net/nqwtf.ini
if [ -s "nqwtf.ini" ]
then
        echo foo >> /dev/null
else
        echo "Error: Could not download nqwtf.ini. Better luck next time. Exiting."
        exit
fi

# List all the available mirrors
echo "From what mirror would you like to download the binaries?"
grep "[0-9]\{1,2\}=\".*" nqwtf.ini | cut -d "\"" -f2 | nl
if [ "$1" == "--random-mirror" ] || [ "$2" == "--random-mirror" ] || [ "$3" == "--random-mirror" ] || [ "$4" == "--random-mirror" ]; then
        mirror=""
else
        read -p "Enter mirror number [random]: " mirror
fi
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" nqwtf.ini | cut -d "=" -f2)
if [ "$mirror" = "" ]
then
        echo;echo -n "* Using mirror: "
        RANGE=$(expr$(grep "[0-9]\{1,2\}=\".*" nqwtf.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
        while [ "$mirror" = "" ]
        do
                number=$RANDOM
                let "number %= $RANGE"
                mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" nqwtf.ini | cut -d "=" -f2)
                mirrorname=$(grep "^$number=\".*" nqwtf.ini | cut -d "\"" -f2)
        done
        echo "$mirrorname"
fi
mkdir -p id1
echo

# Download binaries
echo "=== Downloading ==="
wget --inet4-only -O qwtf-sv-bin-x86.zip $mirror/qwtf-sv-bin-x86.zip

# Terminate installation if not all packages were downloaded
if [ -s "qwtf-sv-bin-x86.zip" ]
then
        if [ "$(du qwtf-sv-bin-x86.zip | cut -f1)" == "0" ]
        then
                echo "Error: The binaries failed to download. Better luck next time. Exiting."
                rm -rf qwtf-sv-bin-x86.zip nqwtf.ini
                cd ..
                rm -rf tmp
        fi
else
        echo "Error: The binaries failed to download. Better luck next time. Exiting."
        cd ..
        rm -rf tmp
        exit
fi

# Ask to restart servers
if [ "$1" == "--restart" ] || [ "$2" == "--restart" ] || [ "$3" == "--restart" ] || [ "$4" == "--restart" ]; then
        restart="y"
else
        if [ "$1" == "--no-restart" ] || [ "$2" == "--no-restart" ] || [ "$3" == "--no-restart" ] || [ "$4" == "--no-restart" ]; then
                restart="n"
        else
                read -p "Do you want the script to stop and restart your servers and proxies? (y/n) [n]: " restart
                echo
        fi
fi

# Install updates
echo "=== Installing ==="
# Extract binaries
echo -n "* Extracting binaries..."
unzip -qqo qwtf-sv-bin-x86.zip 2> /dev/null;echo "done"

# Set the correct permissions
echo -n "* Setting permissions..."
chmod -f +x mvdsv 2> /dev/null
chmod -f -x ../mvdsv 2> /dev/null
chmod 644 fortress/qwprogs.dat 2> /dev/null
if [ "$qtv" == "1" ]
then
        chmod -f +x qtv/qtv.bin 2> /dev/null
        chmod -f -x ../qtv/qtv.bin 2> /dev/null
fi
if [ "$qwfwd" == "1" ]
then
        chmod -f +x qwfwd/qwfwd.bin 2> /dev/null
        chmod -f -x ../qwfwd/qwfwd.bin 2> /dev/null
fi
echo "done"

# Stop servers
if [ "$restart" == "y" ]
then
        echo "* Stopping servers and proxies...done"
        ../stop_servers.sh
fi

# Move binaries into place
echo -n "* Moving binaries into place..."
if [ -f ../mvdsv ]; then
	mv ../mvdsv ../mvdsv.old
fi
mv mvdsv ../
if [ -f ../fortress/qwprogs.dat ]; then
	mv ../fortress/qwprogs.dat ../fortress/qwprogs.dat.old
fi
mv fortress/qwprogs.dat ../fortress/
if [ "$qtv" == "1" ]
then
	if [ -f ../qtv/qtv.bin ]; then
		mv ../qtv/qtv.bin ../qtv/qtv.bin.old
	fi
        mv qtv/qtv.bin ../qtv/
fi
if [ "$qwfwd" == "1" ]
then
	if [ -f ../qwfwd/qwfwd.bin ]; then
        	mv ../qwfwd/qwfwd.bin ../qwfwd/qwfwd.bin.old
	fi
        mv qwfwd/qwfwd.bin ../qwfwd/
fi
echo "done"

# Remove temporary directory
echo -n "* Cleaning up..."
cd ..
rm -rf tmp
echo "done"

# Restart servers
if [ "$restart" == "y" ]
then
        echo "* Starting servers and proxies...done"
        ./start_servers.sh > /dev/null 2>&1
fi

echo;echo "Upgrade complete."
echo
