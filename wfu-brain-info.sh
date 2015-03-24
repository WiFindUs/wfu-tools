#! /bin/bash
#===============================================================
# File: wfu-brain-info.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Prints information about the current node environment.
#===============================================================

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting."
	exit 1
fi

#node info
MESSAGE="Brain environment information:"
MESSAGE="$MESSAGE\n  Node ID (int): $WFU_BRAIN_ID"
MESSAGE="$MESSAGE\n  Node ID (hex): $WFU_BRAIN_ID_HEX"
MESSAGE="$MESSAGE\n  Station # (int): $WFU_BRAIN_NUM"
MESSAGE="$MESSAGE\n  Station # (hex): $WFU_BRAIN_NUM_HEX"
MESSAGE="$MESSAGE\n  AP channel: $WFU_AP_CHANNEL"
echo -e $MESSAGE

exit 0