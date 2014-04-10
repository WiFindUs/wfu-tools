#!/bin/sh
#
#	#### NOTICE ####
#	This script is intended to be the first thing
#	you run on a new build of Raspbian that DOES NOT
#	already have any WFU stuff.
#
#	Do not run it from a git clone; it's only in the
#	wfu-tools repo for convenience. Download it and run it
#	independantly; it will clone wfu-tools itself.
#
clear

TitleStyle="\033[1;36m"
Rst="\033[0m"
IRed="\033[0;91m"
Green="\033[0;32m"
Yellow="\033[0;33m"
Cyan="\033[0;36m"

echo "${TitleStyle}WIFINDUS BRAIN INITIAL SETUP"
echo               "============================${Rst}"
echo "${IRed}You are strongly advised to reboot\nthe unit when this has completed!\n${Rst}"

echo "${Cyan}Purging junk...${Rst}"
sudo apt-get -y purge scratch xpdf idle midori omxplayer dillo netsurf-common netsurf-gtk wolfram-engine sonic-pi > /dev/null

echo "${Cyan}Removing leftovers...${Rst}"
sudo apt-get -y autoremove

echo "${Cyan}Cleaning up...${Rst}"
sudo apt-get -y clean

echo "${Cyan}Updating apt-get list...${Rst}"
sudo apt-get -y update > /dev/null

echo "${Cyan}Upgrading packages...${Rst}"
sudo apt-get -y upgrade > /dev/null

echo "${Cyan}Upgrading distro...${Rst}"
sudo apt-get -y dist-upgrade > /dev/null

cd /home/pi

echo "${Cyan}Installing [most] apps...${Rst}"
sudo apt-get -y install hostapd udhcpd iw git autoconf gpsd gpsd-clients tightvncserver > /dev/null

echo "${Cyan}Creating src dir...${Rst}"
mkdir -p src
cd src

echo "${Cyan}Assembling serval-dna...${Rst}"
if [ -d serval-dna ]; then
	echo "  already present."
	echo "  To rebuild, rm src/serval-dna and re-run this script."
else
	echo "  cloning..."
	git clone -q git://github.com/servalproject/serval-dna.git

	echo "  making..."
	if [ -d serval-dna ]; then
		cd serval-dna
		autoreconf -f -i
		./configure
		make clean
		make

		echo "  creating symlinks..."
		if [ -f servald ]; then
			sudo mkdir -p /usr/local/var/log/serval
			sudo mkdir -p /usr/local/etc/serval
			sudo chmod 755 servald
			sudo rm -f /usr/bin/servald
			sudo ln -s /home/pi/src/serval-dna/servald /usr/bin/servald
		else
			echo "    error! servald may not have built."
		fi
		cd ..
	else
		echo "    error! cloning probably failed."
	fi
fi

echo "${Cyan}Fetching wallpapers...${Rst}"
if [ -d wfu-brain-wallpapers ]; then
	echo "  already present."
	echo "  To re-fetch, rm src/wfu-brain-wallpapers and re-run this script."
else
	mkdir -p wfu-brain-wallpapers
	cd wfu-brain-wallpapers
	echo -n "  ["
	for i in `seq 1 254`; do
		modulus=`expr $i % 10`
		wget -q http://www.wifindus.com/downloads/wfu-brain-wallpapers/wfu-brain-$i.png
		if [ $modulus -eq 0 ]; then
			echo -n "="
		fi
	done
	echo "]"
	cd ..
fi

echo "${Cyan}Assembling wfu-tools...${Rst}"
if [ -d wfu-tools ]; then
	echo "  already present."
	echo "  To rebuilt, rm src/wfu-tools and re-run this script."
else
	echo "  cloning..."
	git clone -q git://github.com/WiFindUs/wfu-tools.git

	echo "  making..."
	if [ -d wfu-tools ]; then
		cd wfu-tools
		sudo chmod 755 wfu-update.sh
		sudo ./wfu-update.sh
		sudo wfu-setup > /dev/null
		cd ..
	else
		echo "    error! cloning probably failed."
	fi
fi

echo "${Cyan}Lauching tightvncserver to set password...${Rst}"
tightvncserver
killall Xtightvnc

echo "${Cyan}Installing babeld...${Rst}"
echo "  It may auto-run and halt this script!"
echo "  You will need to terminate it manually."
sudo apt-get -y install babeld > /dev/null

echo "${Green}Finished :)\n${Yellow}You should reboot now!${Rst}"
