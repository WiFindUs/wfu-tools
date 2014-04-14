#!/bin/bash
#===============================================================
# File: wfu-update-system.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Updates a Raspbian system with all the required packages etc.
#===============================================================

sudo -p mkdir /var/cache/apt/archives/partial
sudo -p mkdir /var/lib/apt/list/partial

echo -e "${STYLE_CYAN}Updating apt-get list...${STYLE_NONE}"
sudo apt-get -qq update > /dev/null

echo -e "${STYLE_CYAN}Upgrading packages...${STYLE_NONE}"
sudo apt-get -qq upgrade > /dev/null

echo -e "${STYLE_CYAN}Upgrading distro...${STYLE_NONE}"
sudo apt-get -qq dist-upgrade > /dev/null

echo -e "${STYLE_CYAN}Installing apps...${STYLE_NONE}"
sudo apt-get -qq install haveged hostapd udhcpd iw git autoconf gpsd > /dev/null
sudo update-rc.d -f hostapd remove > /dev/null
sudo update-rc.d -f hostapd stop 80 0 1 2 3 4 5 6 . > /dev/null
sudo update-rc.d -f udhcpd remove > /dev/null
sudo update-rc.d -f udhcpd stop 80 0 1 2 3 4 5 6 . > /dev/null
sudo update-rc.d -f gpsd remove > /dev/null
sudo update-rc.d -f gpsd stop 80 0 1 2 3 4 5 6 . > /dev/null

echo -e "${STYLE_CYAN}Cleaning up...${STYLE_NONE}"
sudo apt-get -qq clean > /dev/null
sudo apt-get -qq autoclean > /dev/null