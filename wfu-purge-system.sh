#!/bin/sh
#===============================================================
# File: wfu-purge-system.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Purges a Raspbian system of many unwanted/unnecessary components
#===============================================================

echo "${STYLE_CYAN}Purging junk...${STYLE_NONE}"
sudo rm -rf /usr/games/
sudo rm -rf python_games
sudo rm -rf indiecity
sudo rm -f ocr_pi.png
sudo apt-get -qq purge wpasupplicant scratch xpdf idle midori omxplayer dillo netsurf-common netsurf-gtk pistore debian-reference-common debian-reference-en libpoppler19 poppler-utils squeek-plugins-scratch wolfram-engine sonic-pi > /dev/null 2>&1

echo "${STYLE_CYAN}Removing leftovers...${STYLE_NONE}"
sudo apt-get -qq autoremove > /dev/null 2>&1