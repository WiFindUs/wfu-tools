#!/bin/bash
#===============================================================
# File: wfu-remove-all.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Removes all WFU stuff from a system.
#===============================================================
echo -e "${STYLE_TITLE}         WIFINDUS BRAIN UNINSTALLATION          ${STYLE_NONE}"
echo -e "${STYLE_WARNING}This will completely remove WFU and servald from the system!${STYLE_NONE}\n"
echo -e "${STYLE_ERROR}Are you absolutely sure? Press CTRL-C to abort. You have 10 SECONDS.${STYLE_NONE}\n"
sleep 10;
echo -e "${STYLE_WARNING}Alright then, off we go! The unit will be rebooted when this has completed.${STYLE_NONE}\n"
sudo wfu-setup -u
sudo find / -name "wfu*" | xargs sudo rm -rf 
sudo find / -name "*serval*" | xargs sudo rm -rf 
echo -e "${STYLE_SUCCESS}Finished :)\n${STYLE_YELLOW}Thanks! The system will reboot in 5 seconds.${STYLE_NONE}"
sleep 5
sudo shutdown -r now > /dev/null
