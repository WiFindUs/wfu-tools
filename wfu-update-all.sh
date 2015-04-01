#! /bin/bash
#===============================================================
# File: wfu-update-all.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Remotely updates and reboots the entire mesh.
#===============================================================

# environment
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

wfu-brain-send "wfu-update; sleep 15; sudo reboot"

wfu-update
sleep 15
sudo reboot

exit 0