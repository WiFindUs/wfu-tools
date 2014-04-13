#!/bin/bash
#===============================================================
# File: wfu-update-system.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Updates a Raspbian system with all the required packages etc.
#===============================================================

echo -e "${STYLE_CYAN}Updating apt-get list...${STYLE_NONE}"
sudo apt-get -qq update > /dev/null 2>&1

echo -e "${STYLE_CYAN}Upgrading packages...${STYLE_NONE}"
sudo apt-get -qq upgrade > /dev/null 2>&1

echo -e "${STYLE_CYAN}Upgrading distro...${STYLE_NONE}"
sudo apt-get -qq dist-upgrade > /dev/null 2>&1

echo -e "${STYLE_CYAN}Installing apps...${STYLE_NONE}"
sudo apt-get -qq install haveged hostapd udhcpd iw git autoconf gpsd gpsd-clients > /dev/null 2>&1
sudo update-rc.d -f hostapd remove > /dev/null 2>&1
sudo update-rc.d -f hostapd stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1
sudo update-rc.d -f udhcpd remove > /dev/null 2>&1
sudo update-rc.d -f udhcpd stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1
sudo update-rc.d -f gpsd remove > /dev/null 2>&1
sudo update-rc.d -f gpsd stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1

echo -e "${STYLE_CYAN}Cleaning up...${STYLE_NONE}"
sudo apt-get -qq clean > /dev/null 2>&1
sudo apt-get -qq autoclean > /dev/null 2>&1