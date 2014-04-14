#!/bin/bash
#===============================================================
# File: wfu-update-system.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Updates a Raspbian system with all the required packages etc.
#===============================================================
echo -e "${STYLE_HEADING}Updating system components...${STYLE_NONE}"
sudo mkdir -p /var/cache/apt/archives/partial
sudo mkdir -p /var/lib/apt/list/partial

echo -e "  ${STYLE_HEADING}updating apt-get list...${STYLE_NONE}"
sudo apt-get -qq update > /dev/null

echo -e "  ${STYLE_HEADING}upgrading existing packages...${STYLE_NONE}"
sudo apt-get -qq upgrade > /dev/null

echo -e "  ${STYLE_HEADING}upgrading distro...${STYLE_NONE}"
sudo apt-get -qq dist-upgrade > /dev/null

echo -e "  ${STYLE_HEADING}installing apps required by WFU...${STYLE_NONE}"
sudo apt-get -qq install haveged hostapd udhcpd iw git autoconf gpsd > /dev/null
sudo update-rc.d -f hostapd remove > /dev/null
sudo update-rc.d -f hostapd stop 80 0 1 2 3 4 5 6 . > /dev/null
sudo update-rc.d -f udhcpd remove > /dev/null
sudo update-rc.d -f udhcpd stop 80 0 1 2 3 4 5 6 . > /dev/null
sudo update-rc.d -f gpsd remove > /dev/null
sudo update-rc.d -f gpsd stop 80 0 1 2 3 4 5 6 . > /dev/null

echo -e "  ${STYLE_HEADING}cleaning up...${STYLE_NONE}"
sudo apt-get -qq autoremove > /dev/null
sudo apt-get -qq clean > /dev/null
sudo apt-get -qq autoclean > /dev/null

echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"
