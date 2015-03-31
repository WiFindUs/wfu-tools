#! /bin/bash
#===============================================================
# File: wfu-update-apt.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Applies the correct apt sources and runs apt-get update.
#===============================================================

#===============================================================
# ENVIRONMENT
#===============================================================

if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

#===============================================================
# APT SOURCES.LIST
#===============================================================

if [ $IS_RASPBERRY_PI -eq 1 ]; then
	sudo sh -c 'echo "deb http://mirrordirector.raspbian.org/raspbian/ wheezy main contrib non-free rpi" > /etc/apt/sources.list'
elif [ $IS_CUBOX -eq 1 ]; then
	sudo sh -c 'echo "deb http://ftp.au.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list'
	sudo sh -c 'echo "deb http://ftp.debian.org/debian/ wheezy-updates main contrib non-free" >> /etc/apt/sources.list'
	sudo sh -c 'echo "deb http://security.debian.org/ wheezy/updates main contrib non-free" >> /etc/apt/sources.list'
	sudo sh -c 'echo "deb http://repo.maltegrosse.de/debian/wheezy/bsp_cuboxi/ ./" >> /etc/apt/sources.list'
fi

#===============================================================
# APT PREFERENCES
#===============================================================

sudo rm -f /etc/apt/preferences

#===============================================================
# APT-UPDATE
#===============================================================

sudo apt-get -y update

exit 0