#!/bin/sh

####################################
## CLASSIC FORTRESS GETMAP SCRIPT ##
####################################

##################################################
## script starts here - do not edit lines below ##
##################################################

# functions
error() {
    printf "ERROR: %s\n" "$*"
    [ -d $tmpdir ] && rm -rf $tmpdir
    exit 1
}

quit() {
    printf "%s\n" "$*"
    [ -d $tmpdir ] && rm -rf $tmpdir
    exit 0
}

# initialize variables
eval settingsdir=~/.cfortsv
eval fortressdir=$(cat $settingsdir/install_dir)/fortress
eval tmpdir=$fortressdir/tmp
mapname=${1%.*}
fail=0

# initialize folders
mkdir -p $tmpdir $fortressdir/maps $fortressdir/sound $fortressdir/progs

# check if unzip and curl are installed
[ `which unzip` ] || error "The package 'unzip' is not installed. Please install it and run the installation again."
[ `which curl` ] || error "The package 'curl' is not installed. Please install it and run the installation again."

# check if map is already installed
[ -s "$fortressdir/maps/$mapname.bsp" ] && quit "The map '$mapname.bsp' is already installed."

# check if map exists on quakerepo.net
status=`curl -s -I http://quakerepo.net/fortress/maps/$mapname.zip | grep HTTP/1.1 | awk {'print $2'}`;
[ "$status" = "200" ] || error "The map '$mapname' doesn't exist on remote server."

printf "Installing $mapname.."

# download map
curl --silent --output $tmpdir/$mapname.zip http://quakerepo.net/fortress/maps/$mapname.zip && printf "." || error "Failed to download '$mapname.zip' from remote server."
[ -s "$tmpdir/$mapname.zip" ] || error "Downloaded '$mapname.zip' but file is empty?!"

# install map
(unzip -qqo $tmpdir/$mapname.zip -d $tmpdir >/dev/null && printf ".") || fail=1
(mv $tmpdir/maps/$mapname.bsp $fortressdir/maps/ >/dev/null && printf ".") || fail=1
[ -d $tmpdir/sound/ ] && cp -n -r $tmpdir/sound/* $fortressdir/sound/ >/dev/null && printf "."
[ -d $tmpdir/progs/ ] && cp -n -r $tmpdir/progs/* $fortressdir/progs/ >/dev/null && printf "."
[ $fail -eq 0 ] && echo "done" || echo "fail"

rm -rf $tmpdir

exit 0
