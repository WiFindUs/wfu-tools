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
rm -rf "$SRC_DIR/serval-dna"
rm -rf "$SRC_DIR/wfu-tools/.git"
rm -f "$SRC_DIR/wfu-tools/.git*"

echo -e "  ${STYLE_HEADING}removing config-only apt entries...${STYLE_NONE}"
dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs sudo apt-get -qq purge > /dev/null
	
echo -e "  ${STYLE_HEADING}cleaning up...${STYLE_NONE}"
sudo apt-get -qq autoremove > /dev/null
sudo apt-get -qq clean > /dev/null
sudo apt-get -qq autoclean > /dev/null


echo -e "  ${STYLE_HEADING}cleaning apt-cache...${STYLE_NONE}"
sudo rm -rf /var/lib/apt/list
sudo rm -rf /var/cache/apt

echo -e "  ${STYLE_HEADING}writing zeros to free space...${STYLE_NONE}"
sudo sfill -f -ll -z /

echo -e "  ${STYLE_HEADING}writing zeros to swap...${STYLE_NONE}"
sudo swapoff -a
sudo dd if=/dev/zero of=/var/swap bs=1M count=100
sudo swapon -a

echo -e "  ${STYLE_HEADING}deleting logs...${STYLE_NONE}"
sudo rm `find /var/log -type f`
if [ -d "/usr/local/var/log/serval" ]; then
	sudo rm -f "/usr/local/var/log/serval/*.log"
fi
echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"
