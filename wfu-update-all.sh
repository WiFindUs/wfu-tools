#! /bin/bash
#===============================================================
# File: wfu-update-all.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Remotely updates and reboots the entire mesh.
#===============================================================

#===============================================================
# ENVIRONMENT
#===============================================================

if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

if [ -z "$WFU_BRAIN_NUM" ] || [ $WFU_BRAIN_NUM -ne 1 ]; then
	echo "ERROR: Must be node 1 to run wfu-update-all. aborting." 1>&2
	exit 2
fi

MESH_0=`ifconfig | grep -m 1 "^mesh0"`
if [ -z "$MESH_0" ]; then
	echo "ERROR: Could not find the mesh0 interface. aborting." 1>&2
	exit 3
fi

#===============================================================
# INTRO
#===============================================================

clear
echo -e "${STYLE_TITLE}                WIFINDUS MESH-WIDE UPDATE                  ${STYLE_NONE}"
echo -e "${STYLE_INFO}This utility sends an update and reboot command to every visible${STYLE_NONE}"
echo -e "${STYLE_INFO}node on the mesh, with sleep timers to allow for all updates to finish.${STYLE_NONE}"
echo -e "${STYLE_WARNING}Significant mesh disruption will occur for a few minutes!${STYLE_NONE}\n"

echo -n -e "  ${STYLE_PROMPT}Continue?${STYLE_NONE} "
read -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
   echo ""
   exit 4
fi

#===============================================================
# SEND COMMANDS TO NODES
#===============================================================

wfu-brain-send "wfu-update; sleep 30; sudo reboot"

#===============================================================
# SELF-UPDATE
#===============================================================

sleep 10
wfu-update

#===============================================================
# FINISH
#===============================================================

echo -e "${STYLE_SUCCESS}Finished :)\n${STYLE_YELLOW}The system will reboot in 30 seconds.${STYLE_NONE}"
sleep 10
echo -e "${STYLE_YELLOW}The system will reboot in 20 seconds.${STYLE_NONE}"
sleep 10
echo -e "${STYLE_YELLOW}The system will reboot in 10 seconds.${STYLE_NONE}"
sleep 5
echo -e "${STYLE_YELLOW}The system will reboot in 5 seconds.${STYLE_NONE}"
sleep 5
sudo reboot

exit 0