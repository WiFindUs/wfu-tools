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
	HOSTAPD="${STYLE_SUCCESS}running${STYLE_NONE}"
else
	HOSTAPD="${STYLE_ERROR}not found${STYLE_NONE}"
fi

DHCPD=`sudo pgrep -l dhcpd`
if [ -n "$DHCPD" ]; then
	DHCPD="${STYLE_SUCCESS}running${STYLE_NONE}"
else
	DHCPD="${STYLE_ERROR}not found${STYLE_NONE}"
fi

GPSD=`sudo pgrep -l gpsd`
if [ -n "$GPSD" ]; then
	GPSD="${STYLE_SUCCESS}running${STYLE_NONE}"
else
	GPSD="${STYLE_WARNING}not found${STYLE_NONE}"
fi

MESH_PEERS="none"
MESH_0=`sudo ifconfig | grep -o -m 1 "^mesh0"`
if [ -n "$MESH_0" ]; then
	MESH_PEERS=`wfu-mesh-peers -lrq ",\n" 2>/dev/null`
else
	MESH_0="${STYLE_ERROR}not found${STYLE_NONE}"
fi

AP_0=`sudo ifconfig | grep -o -m 1 "^ap0"`
if [ -z "$AP_0" ]; then
	AP_0="${STYLE_ERROR}not found${STYLE_NONE}"
fi

IS_RPI="no"
if [ $IS_RASPBERRY_PI -eq 1 ]; then
	IS_RPI="yes"
fi

IS_CBX="no"
if [ $IS_CUBOX -eq 1 ]; then
	IS_CBX="yes"
fi

ISPC="no"
if [ $IS_PC -eq 1 ]; then
	ISPC="yes"
fi

LAST_UPDATE="${STYLE_WARNING}unknown${STYLE_NONE}"
if [ -n "$LAST_UPDATE_TIME" ]; then
	LAST_UPDATE="$LAST_UPDATE_TIME"
fi

#print info
echo -e "Brain environment information:"
echo -e "  Node ID       : $WFU_BRAIN_ID_HEX"
echo -e "  Version       : $WFU_VERSION"
echo -e "  Last updated  : $LAST_UPDATE"
echo -e "  Station #     : $WFU_BRAIN_NUM"
echo -e "  Machine model : $MACHINE_MODEL"
echo -e "  Machine family: $MACHINE_FAMILY"
echo -e "    - is Pi     : $IS_RPI"
echo -e "    - is Cubox  : $IS_CBX"
echo -e "    - is PC     : $ISPC"
echo -e "  Access point  : $AP_0"
echo -e "    - channel   : $WFU_AP_CHANNEL"
echo -e "    - hostapd   : $HOSTAPD"
echo -e "    - dhcpd     : $DHCPD"
echo -e "  GPS daemon    : $GPSD"
echo -e "  Mesh point    : $MESH_0"
echo -e "    - peers     : $MESH_PEERS"

exit 0