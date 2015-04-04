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

# intro
echo -e "${STYLE_HEADING}Brain environment information:${STYLE_NONE}"
echo -e "  Node ID       : $WFU_BRAIN_ID_HEX"
echo -e "  Version       : $WFU_VERSION"

# version
LAST_UPDATE="${STYLE_WARNING}unknown${STYLE_NONE}"
if [ -n "$LAST_UPDATE_TIME" ]; then
	LAST_UPDATE="$LAST_UPDATE_TIME"
fi
echo -e "  Last updated  : $LAST_UPDATE"

# brain number
echo -e "  Station #     : $WFU_BRAIN_NUM"

# machine info
echo -e  "  Machine model : $MACHINE_MODEL"
echo -e  "  Machine family: $MACHINE_FAMILY"
echo -ne "    - is Pi     : "
if [ $IS_RASPBERRY_PI -eq 1 ]; then
	echo "${STYLE_SUCCESS}yes${STYLE_NONE}"
else
	echo "no"
fi
echo -ne "    - is Cubox  : "
if [ $IS_CUBOX -eq 1 ]; then
	echo "${STYLE_SUCCESS}yes${STYLE_NONE}"
else
	echo "no"
fi
echo -ne "    - is PC     : "
if [ $IS_PC -eq 1 ]; then
	echo "${STYLE_SUCCESS}yes${STYLE_NONE}"
else
	echo "no"
fi

# access point interface
AP_0=`sudo ifconfig | grep -o -m 1 "^ap0"`
if [ -z "$AP_0" ]; then
	AP_0="${STYLE_ERROR}not found${STYLE_NONE}"
fi
echo -e "  Access point  : $AP_0"
echo -e "    - channel   : $WFU_AP_CHANNEL"

# access point daemon
HOSTAPD=`sudo pgrep -l hostapd`
if [ -n "$HOSTAPD" ]; then
	HOSTAPD="${STYLE_SUCCESS}running${STYLE_NONE}"
else
	HOSTAPD="${STYLE_ERROR}not found${STYLE_NONE}"
fi
echo -e "    - hostapd   : $HOSTAPD"

# dhcp daemon
DHCPD=`sudo pgrep -l dhcpd`
if [ -n "$DHCPD" ]; then
	DHCPD="${STYLE_SUCCESS}running${STYLE_NONE}"
else
	DHCPD="${STYLE_ERROR}not found${STYLE_NONE}"
fi
echo -e "    - dhcpd     : $DHCPD"

# gps daemon
GPSD=`sudo pgrep -l gpsd`
if [ -n "$GPSD" ]; then
	GPSD="${STYLE_SUCCESS}running${STYLE_NONE}"
else
	GPSD="${STYLE_WARNING}not found${STYLE_NONE}"
fi
echo -e "  GPS daemon    : $GPSD"

# mesh point interface
MESH_PEERS="${STYLE_ERROR}none${STYLE_NONE}"
MESH_0=`sudo ifconfig | grep -o -m 1 "^mesh0"`
if [ -n "$MESH_0" ]; then
	MESH_PEERS=`wfu-mesh-peers -lrq ",\n" 2>/dev/null`
else
	MESH_0="${STYLE_ERROR}not found${STYLE_NONE}"
fi
echo -e "  Mesh point    : $MESH_0"
echo -e "    - peers     : $MESH_PEERS"

exit 0