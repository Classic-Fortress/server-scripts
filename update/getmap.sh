#!/bin/sh

####################################
## CLASSIC FORTRESS GETMAP SCRIPT ##
####################################

######################
##  INITIALIZATION  ##
######################

# functions
error() {
    printf "%s\n" "$*"

    # remove temporary directory if it exists
    [ -d $tmpdir ] && rm -rf $tmpdir

    exit 1
}
quit() {
    printf "%s\n" "$*"

    # remove temporary directory if it exists
    [ -d $tmpdir ] && rm -rf $tmpdir

    exit 0
}
iffailed() {
    [ $fail -eq 1 ] && {
        echo "fail"
        printf "%s\n" "$*"
        exit 1
    }

    return 1
}

# initialize variables
eval settingsdir=~/.cfortsv
eval serverdir=$(cat $settingsdir/install_dir)
eval fortressdir=$serverdir/fortress
eval tmpdir=$settingsdir/tmp
mapname=${1%.*}
fail=0

# check if parameters were given
[ -z $1 ] && quit "You need to specify a map to download."

# initialize folders
mkdir -p $tmpdir $fortressdir/maps $fortressdir/sound $fortressdir/progs

# check if unzip and curl are installed
[ `which unzip` ] || error "The package 'unzip' is not installed. Please install it and run the installation again."
[ `which curl` ] || error "The package 'curl' is not installed. Please install it and run the installation again."

# check if map is already installed
[ -s $fortressdir/maps/$mapname.bsp ] && quit "The map '$mapname.bsp' is already installed."

######################
##     DOWNLOAD     ##
######################

# check if map exists on quakerepo.net
status=`curl -s -I http://quakerepo.net/fortress/maps/$mapname.zip | grep HTTP/1.1 | awk {'print $2'}`;
[ "$status" = "200" ] || error "ERROR: The map '$mapname' doesn't exist on remote server."

printf "Installing $mapname.."

# download map
curl --silent --output $tmpdir/$mapname.zip http://quakerepo.net/fortress/maps/$mapname.zip || fail=1
[ -s $tmpdir/$mapname.zip ] || fail=1

iffailed "Failed to download '$mapname.zip' from remote server." || printf "."

######################
##    UNPACKING     ##
######################

# unpack map
unzip -qqo $tmpdir/$mapname.zip -d $tmpdir 2>/dev/null || fail=1

iffailed "Failed to unpack '$mapname.zip'. Try running the script again." || printf "."

######################
##   INSTALLATION   ##
######################

mv $tmpdir/maps/$mapname.bsp $fortressdir/maps/ >/dev/null && printf "." || fail=1
[ -d $tmpdir/sound/ ] && (cp -n -r $tmpdir/sound/* $fortressdir/sound/ >/dev/null && printf "." || fail=1)
[ -d $tmpdir/progs/ ] && (cp -n -r $tmpdir/progs/* $fortressdir/progs/ >/dev/null && printf "." || fail=1)

iffailed "ERROR: Could not install map in server directory. Perhaps you have some permission problems." || printf "."

######################
##     CLEANUP      ##
######################

# remove temporary directory
rm -rf $tmpdir || fail=1

iffailed "ERROR: Could not remove temporary directory '$tmpdir'. Perhaps you have some permission problems." || echo "done"

exit 0
