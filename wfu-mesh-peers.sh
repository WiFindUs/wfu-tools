#! /bin/bash
#===============================================================
# File: wfu-mesh-peers.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Lists all of a node's mesh peers by their station numbers.
#===============================================================

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

MESH_0=`ifconfig | grep -m 1 "^mesh0"`
if [ -z "$MESH_0" ]; then
	echo "ERROR: Could not find the mesh0 interface. aborting." 1>&2
	exit 3
fi

MESH_PEERS=`sudo iw dev mesh0 mpath dump | grep mesh0`
if [ -z "$MESH_PEERS" ]; then
	echo "No mesh peers found." 1>&2
	exit 0
fi

FLAGS=`echo "$1" | grep -E -o -m 1 -i "-[a-z]+"`
if [ -n "$FLAGS" ]; then
	LOCAL_PEERS=`echo "$FLAGS" | grep -E -o -m 1 -i "l"`
	REMOTE_PEERS=`echo "$FLAGS" | grep -E -o -m 1 -i "r"`
fi
if [ -z $LOCAL_PEERS ]; then
	LOCAL_PEERS=1
fi
if [ -z $REMOTE_PEERS ]; then
	REMOTE_PEERS=0
fi

MS="[0-9A-Za-z]{1,2}"
MAC="$MS[:]$MS[:]$MS[:]$MS[:]$MS[:]$MS"
REGEX="($MAC) +($MAC) +mesh0"
MESH_PEER_LIST=""
while read -r PEER; do
	if [[ $PEER =~ $REGEX ]]; then
		NEW_PEER=""
		if ([ $LOCAL_PEERS -eq 1 ] && [ "${BASH_REMATCH[1]}" == "${BASH_REMATCH[2]}" ]) || ([ $REMOTE_PEERS -eq 1 ] && [ "${BASH_REMATCH[1]}" != "${BASH_REMATCH[2]}" ]); then
			NEW_PEER=`echo "${BASH_REMATCH[1]}"`	
		fi
		if [ -n $NEW_PEER ]; then
			NEW_PEER=`echo "$NEW_PEER" | cut -d':' -f6`
			NEW_PEER=`echo "ibase=16; $NEW_PEER" | bc`
			MESH_PEER_LIST="$MESH_PEER_LIST $NEW_PEER"
		fi
	fi
done <<< "$MESH_PEERS"

echo "Peers found:" 1>&2
echo "$MESH_PEER_LIST"
exit 0