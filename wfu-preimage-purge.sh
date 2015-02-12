#! /bin/bash
#===============================================================
# File: wfu-preimage-purge.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Disk operations to make a recorded SD Card image smaller.
#===============================================================
echo -e "${STYLE_HEADING}Performing SD card imaging-prep operations...${STYLE_NONE}"

echo -e "  ${STYLE_HEADING}deleting git artefacts...${STYLE_NONE}"
rm -rf "$SRC_DIR/wfu-tools/.git"
rm -f "$SRC_DIR/wfu-tools/.git*"
rm -f "$PI_HOME/*.log"

echo -e "  ${STYLE_HEADING}removing config-only apt entries...${STYLE_NONE}"
dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs sudo apt-get -y purge
	
echo -e "  ${STYLE_HEADING}cleaning up...${STYLE_NONE}"
sudo apt-get -y autoremove
sudo apt-get -y clean
sudo apt-get -y autoclean

echo -e "  ${STYLE_HEADING}writing zeros to free space...${STYLE_NONE}"
sudo sfill -f -ll -z /

echo -e "  ${STYLE_HEADING}deleting logs...${STYLE_NONE}"
sudo rm `find /var/log -type f`
echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"
