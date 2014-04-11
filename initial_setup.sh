#!/bin/sh
#===============================================================
# File: initial_setup.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Sets up a fresh Rasbian install for use as a wfu-brain unit.
#
# Remarks:
#   This script is intended to be the first thing
#   you run on a new build of Raspbian that DOES NOT
#   already have any WFU stuff.
#===============================================================
clear

VNC_PASS="omgwtf42"
SMK="\033["
TitleStyle="${SMK}1;36m"
Rst="${SMK}0m"
IRed="${SMK}0;91m"
Red="${SMK}0;31m"
Green="${SMK}0;32m"
Yellow="${SMK}0;33m"
Cyan="${SMK}0;36m"

echo "${TitleStyle}WIFINDUS BRAIN INITIAL SETUP"
echo              "============================${Rst}"
echo "${IRed}You are strongly advised to reboot\nthe unit when this has completed!\n${Rst}"
cd "$HOME"

echo "${Cyan}Purging junk...${Rst}"
sudo rm -rf /usr/games/
sudo rm -rf python_games
sudo rm -f ocr_pi.png
sudo apt-get -qq purge scratch xpdf idle midori omxplayer dillo netsurf-common netsurf-gtk pistore debian-reference-common debian-reference-en libpoppler19 poppler-utils squeek-plugins-scratch wolfram-engine sonic-pi >& /dev/null

echo "${Cyan}Removing leftovers...${Rst}"
sudo apt-get -qq autoremove >& /dev/null

echo "${Cyan}Updating apt-get list...${Rst}"
sudo apt-get -qq update >& /dev/null

echo "${Cyan}Upgrading packages...${Rst}"
sudo apt-get -qq upgrade >& /dev/null

echo "${Cyan}Upgrading distro...${Rst}"
sudo apt-get -qq dist-upgrade >& /dev/null

echo "${Cyan}Installing [most] apps...${Rst}"
sudo apt-get -qq install hostapd udhcpd iw git autoconf gpsd gpsd-clients tightvncserver >& /dev/null

echo "${Cyan}Cleaning up...${Rst}"
sudo apt-get -qq clean >& /dev/null
sudo apt-get -qq autoclean >& /dev/null

if [ ! -d src ]; then
	echo "${Cyan}Creating src dir...${Rst}"
	mkdir -p src
fi
cd src

echo "${Cyan}Assembling serval-dna...${Rst}"
if [ -d serval-dna ]; then
	echo "  ${Yellow}already present."
	echo "  To rebuild, rm src/serval-dna and re-run this script.${Rst}"
else
	echo "  ${Cyan}cloning...${Rst}"
	git clone -q git://github.com/servalproject/serval-dna.git

	echo "  ${Cyan}making...${Rst}"
	if [ -d serval-dna ]; then
		cd serval-dna
		autoreconf -f -i
		./configure
		make clean -s -k
		make -s -k

		echo "  ${Cyan}creating symlinks...${Rst}"
		if [ -f servald ]; then
			sudo mkdir -p /usr/local/var/log/serval
			sudo mkdir -p /usr/local/etc/serval
			sudo chmod 755 servald
			sudo rm -f /usr/bin/servald
			sudo ln -s /home/pi/src/serval-dna/servald /usr/bin/servald
		else
			echo "    ${IRed}error! servald may not have built.${Rst}"
		fi
		cd ..
	else
		echo "    ${IRed}error! cloning probably failed.${Rst}"
	fi
fi

echo "${Cyan}Fetching wallpapers...${Rst}"
if [ ! -d wfu-brain-wallpapers ]; then
	mkdir -p wfu-brain-wallpapers
fi
cd wfu-brain-wallpapers
echo -n "  [${Red}"
ONE_THIRD=`expr 254 / 3`
TWO_THIRDS=`expr 2 \* 254 / 3`
for i in `seq 1 254`; do
	if [ ! -f wfu-brain-$i.png ]; then
		wget -q http://www.wifindus.com/downloads/wfu-brain-wallpapers/wfu-brain-$i.png
	fi
	
	if [ $i -eq $ONE_THIRD ]; then
		echo -n "${Yellow}"
	elif [ $i -eq $TWO_THIRDS ]; then
		echo -n "${Green}"
	fi
	
	ticker=`expr $i % 10`
	if [ $ticker -eq 0 ]; then
		echo -n "="
	fi
done
echo "${Rst}]"
cd ..

echo "${Cyan}Assembling wfu-tools...${Rst}"
if [ ! -d wfu-tools ]; then
	echo "  ${Cyan}cloning...${Rst}"
	git clone -q git://github.com/WiFindUs/wfu-tools.git
fi

echo "  ${Cyan}making...${Rst}"
if [ -d wfu-tools ]; then
	cd wfu-tools
	sudo chmod 755 wfu-update.sh
	sudo ./wfu-update.sh
	sudo wfu-setup -q
	cd ..
else
	echo "    ${IRed}error! cloning probably failed.${Rst}"
fi
cd ..

echo "${Cyan}Setting VNC password...${Rst}"
mkdir -p ".vnc"
if [ -d ".vnc" ]; then
	cd ".vnc"
	echo -e "$VNC_PASS\n\n" | vncpasswd -f > passwd
	if [ -f passwd ]; then
		echo "    ${Green}OK! password: $VNC_PASS${Rst}"
	else
		echo "    ${IRed}error! could not create passwd file.${Rst}"
	fi
	cd ..
else
	echo "    ${IRed}error! could not create .vnc dir.${Rst}"
fi

echo "${Cyan}Installing babeld...${Rst}"
echo "  ${Yellow}It may auto-run and halt this script!"
echo "  You will need to terminate it manually.${Rst}"
sudo apt-get -qq install babeld >& /dev/null

echo "${Green}Finished :)\n${Yellow}You should reboot now!${Rst}"
