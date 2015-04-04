#! /bin/bash
#===============================================================
# File: wfu-brain-send.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Sends a command to all other nodes via ssh.
#===============================================================

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

if [ -z "$WFU_BRAIN_NUM" ] || [ $WFU_BRAIN_NUM -ne 1 ]; then
	echo "ERROR: Must be node 1 to run wfu-brain-send. aborting." 1>&2
	exit 2
fi

MESH_0=`sudo ifconfig | grep -m 1 "^mesh0"`
if [ -z "$MESH_0" ]; then
	echo "ERROR: Could not find the mesh0 interface. aborting." 1>&2
	exit 3
fi

COMMAND="$1"
if [ -z "$COMMAND" ]; then
	echo "ERROR: A command was not supplied. aborting." 1>&2
	exit 4
fi

#take care of simpler aliases
COMMAND="${COMMAND//fullinfo/brinfo; hbconfig; fakegps}"
COMMAND="${COMMAND//fakegps/wfu-fake-gps}"
COMMAND="${COMMAND//hbconfig/wfu-heartbeat-config}"
COMMAND="${COMMAND//brinfo/wfu-brain-info}"
COMMAND="${COMMAND//meshpeers/wfu-mesh-peers}"
COMMAND="${COMMAND//meshdump/sudo iw dev mesh0 mpath dump 2>&1}"

SLEEP=`echo "$2" | grep -Eo -m 1 "^[0-9]+$"`
if [ -z "$SLEEP" ] || [ $SLEEP -lt 0 ]; then
	SLEEP=0
fi

MESH_PEERS=`wfu-mesh-peers -lr " " 2>/dev/null`
if [ -z "$MESH_PEERS" ]; then
	echo "ERROR: No peers found. aborting." 1>&2
	exit 5
fi

echo -e "${STYLE_HEADING}Sending command to mesh peers...${STYLE_NONE}"
echo -e "  ${STYLE_INFO}Peer list${STYLE_NONE}: ${MESH_PEERS}"
for PEER in $MESH_PEERS; do
	SUBCOMMAND="${COMMAND//_NUM_/$PEER}"
	echo -e "  ${STYLE_INFO}wfu-brain-${PEER}${STYLE_NONE}: '$SUBCOMMAND'"
	( sshpass -p 'omgwtflol87' ssh -o StrictHostKeyChecking=no wifindus@wfu-brain-$PEER "$SUBCOMMAND" & )
	if [ $SLEEP -gt 0 ]; then
		sleep $SLEEP
	fi
done

echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"

exit 0