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
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

# collect data
HOSTAPD=`sudo pgrep -l hostapd`
if [ -n "$HOSTAPD" ]; then
	HOSTAPD="running"
else
	HOSTAPD="not found"
fi
DHCPD=`sudo pgrep -l dhcpd`
if [ -n "$DHCPD" ]; then
	DHCPD="running"
else
	DHCPD="not found"
fi
GPSD=`sudo pgrep -l gpsd`
if [ -n "$GPSD" ]; then
	GPSD="running"
else
	GPSD="not found"
fi
MESH_0=`ifconfig | grep -o -m 1 "^mesh0"`
if [ -n "$MESH_0" ]; then
	LOCAL_PEERS=`wfu-mesh-peers -l ", " 2>/dev/null`
	REMOTE_PEERS=`wfu-mesh-peers -r ", " 2>/dev/null`
else
	MESH_0="not found"
fi
if [ -z "$LOCAL_PEERS" ]; then
	LOCAL_PEERS="none"
fi
if [ -z "$REMOTE_PEERS" ]; then
	REMOTE_PEERS="none"
fi
AP_0=`ifconfig | grep -o -m 1 "^ap0"`
if [ -z "$AP_0" ]; then
	AP_0="not found"
fi
if [ $IS_RASPBERRY_PI -eq 1 ]; then
	IS_RPI="yes"
else
	IS_RPI="no"
fi

if [ $IS_CUBOX -eq 1 ]; then
	IS_CBX="yes"
else
	IS_CBX="no"
fi

if [ $IS_PC -eq 1 ]; then
	ISPC="yes"
else
	ISPC="no"
fi

if [ -n "$LAST_UPDATE_TIME" ]; then
	LAST_UPDATE="$LAST_UPDATE_TIME"
else
	LAST_UPDATE="unknown"
fi

#print info
echo "Brain environment information:"
echo "  Node version  : $WFU_VERSION"
echo "  Node ID       : $WFU_BRAIN_ID_HEX"
echo "  Last updated  : $LAST_UPDATE"
echo "  Station #     : $WFU_BRAIN_NUM"
echo "  Machine model : $MACHINE_MODEL"
echo "  Machine family: $MACHINE_FAMILY"
echo "    - is Pi     : $IS_RPI"
echo "    - is Cubox  : $IS_CBX"
echo "    - is PC     : $ISPC"
echo "  Access point  : $AP_0"
echo "    - channel   : $WFU_AP_CHANNEL"
echo "    - hostapd   : $HOSTAPD"
echo "    - dhcpd     : $DHCPD"
echo "  GPS daemon    : $GPSD"
echo "  Mesh point    : $MESH_0"
echo "    - loc. peers: $LOCAL_PEERS"
echo "    - rem. peers: $REMOTE_PEERS"
exit 0