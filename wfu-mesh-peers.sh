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

MESH_0=`sudo ifconfig | grep -m 1 "^mesh0"`
if [ -z "$MESH_0" ]; then
	echo "ERROR: Could not find the mesh0 interface. aborting." 1>&2
	exit 3
fi

MESH_PEERS=`sudo iw dev mesh0 mpath dump | grep mesh0`
if [ -z "$MESH_PEERS" ]; then
	echo "No mesh peers found." 1>&2
	exit 0
fi

LOCAL_PEERS="1"
REMOTE_PEERS=""
INCLUDE_QUALITY=""
FLAGS=`echo "$1" | grep -Eo -m 1 "^[-][a-zA-Z]+$"`
if [ -n "$FLAGS" ]; then
	LOCAL_PEERS=`echo "$FLAGS" | grep -Eo -m 1 "[lL]"`
	REMOTE_PEERS=`echo "$FLAGS" | grep -Eo  -m 1 "[rR]"`
	INCLUDE_QUALITY=`echo "$FLAGS" | grep -Eo  -m 1 "[qQ]"`
fi

DELIMITER="$2"
if [ -z "$DELIMITER" ]; then
	DELIMITER=" "
fi

MS="[0-9A-Za-z]{1,2}"
MAC="$MS[:]$MS[:]$MS[:]$MS[:]$MS[:]$MS"
REGEX="($MAC) +($MAC) +mesh0"
PEER_LIST=""
REMOTE_PEER_LIST=""
while read -r PEER; do
	if [[ $PEER =~ $REGEX ]]; then
		PEER_MAC="${BASH_REMATCH[1]}"
		IS_LOCAL=0
		if [ "${BASH_REMATCH[1]}" == "${BASH_REMATCH[2]}" ]; then
			IS_LOCAL=1
		fi
		if [ $IS_LOCAL -eq 1 -a -z "$LOCAL_PEERS" ] || [ $IS_LOCAL -eq 0 -a -z "$REMOTE_PEERS" ]; then
			continue
		fi
		if [ -n "$PEER_MAC" ]; then
			PEER_NUM=`echo "$PEER_MAC" | cut -d':' -f6`
			PEER_NUM=`echo "ibase=16; $PEER_NUM" | bc`
			if [ -n "$INCLUDE_QUALITY" ]; then
				STATION_INFO=`sudo iw dev mesh0 station get "$PEER_MAC"`
				SIGNAL_STRENGTH=`echo "$STATION_INFO" | grep -i "signal avg" | grep -Eo "[-+]?[0-9]+"`
				TX_BITRATE=`echo "$STATION_INFO" | grep -i "tx bitrate" | grep -Eo "[-+]?[0-9]+([.][0-9]+)?"`
				PEER_NUM="${PEER_NUM};$SIGNAL_STRENGTH;$TX_BITRATE"
			fi
			if [ $IS_LOCAL -eq 1 ]; then
				if [ -n "$PEER_LIST" ]; then
					PEER_LIST="${PEER_LIST}${DELIMITER}"
				fi
				PEER_LIST="${PEER_LIST}${PEER_NUM}"
			else
				if [ -n "$REMOTE_PEER_LIST" ]; then
					REMOTE_PEER_LIST="${REMOTE_PEER_LIST}${DELIMITER}"
				fi
				REMOTE_PEER_LIST="${REMOTE_PEER_LIST}${PEER_NUM}"
			fi
		fi
	fi
done <<< "$MESH_PEERS"

if [ -n "$REMOTE_PEER_LIST" -a -n "$PEER_LIST" ]; then
	PEER_LIST="${REMOTE_PEER_LIST}${DELIMITER}${PEER_LIST}"
fi

echo "Peers found:" 1>&2
echo "$PEER_LIST"
exit 0