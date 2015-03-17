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
	echo "could not find globals for current user. aborting."
	exit 1
fi

#===============================================================
# APT SOURCES.LIST
#===============================================================

if [ $IS_RASPBERRY_PI -eq 1 ]; then
	echo "deb http://mirrordirector.raspbian.org/raspbian/ wheezy main contrib non-free rpi" > /etc/apt/sources.list
	echo "deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib non-free rpi" >> /etc/apt/sources.list
elif [ $IS_CUBOX -eq 1 ]; then
	echo "deb http://ftp.de.debian.org/debian wheezy main contrib non-free" > /etc/apt/sources.list
	echo "deb http://repo.maltegrosse.de/debian/wheezy/bsp_cuboxi/ ./" >> /etc/apt/sources.list
	echo "deb http://ftp.de.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list
fi

#===============================================================
# APT PREFERENCES
#===============================================================

echo "Package: *" > /etc/apt/preferences
echo "Pin: release n=wheezy" >> /etc/apt/preferences
echo "Pin-Priority: 900" >> /etc/apt/preferences
echo "Package: build-essential" >> /etc/apt/preferences
echo "Pin: release n=jessie" >> /etc/apt/preferences
echo "Pin-Priority: 910" >> /etc/apt/preferences
echo "Package: *" >> /etc/apt/preferences
if [ $IS_RASPBERRY_PI -eq 1 ]; then
	echo "Pin: release o=Raspbian" >> /etc/apt/preferences
else
	echo "Pin: release o=Debian" >> /etc/apt/preferences
fi
echo "Pin-Priority: -10" >> /etc/apt/preferences

#===============================================================
# APT-UPDATE
#===============================================================

sudo apt-get -y update

exit 0