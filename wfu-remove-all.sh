#!/bin/bash
#===============================================================
# File: wfu-remove-all.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Removes all WFU scripts etc from a system.
#===============================================================
echo -e "${STYLE_HEADING}Removing wfu configs created by wfu-setup...${STYLE_NONE}"
echo -e "  ${STYLE_SUCCESS}hosts, hostname and network/interfaces\nare not deleted by this script.!${STYLE_NONE}"
sudo wfu-setup -u
sudo rm -rf /home/pi/src/wfu-tools
sudo rm -f /usr/bin/wfu-*
sudo find / -name "*serval*" | xargs sudo rm -rf 
echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"
