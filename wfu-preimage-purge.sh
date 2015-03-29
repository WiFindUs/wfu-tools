#! /bin/bash
#===============================================================
# File: wfu-preimage-purge.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Disk operations to make a recorded SD Card image smaller.
#===============================================================
# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting."
	exit 1
fi

echo -e "${STYLE_HEADING}Terminating processes...${STYLE_NONE}"

HEARTBEAT=`sudo pgrep wfu-heartbeat`
if [ -n "$HEARTBEAT" ]; then
	echo "wfu-heartbeat running, terminating..."
	sudo kill -9 "$HEARTBEAT"
fi

GPSD=`sudo pgrep gpsd`
if [ -n "$GPSD" ]; then
	echo "gpsd running, terminating..."
	sudo kill -9 "$GPSD"
fi

DHCPD=`sudo pgrep dhcpd`
if [ -n "$DHCPD" ]; then
	echo "dhcpd running, terminating..."
	sudo kill -9 "$DHCPD"
fi

HOSTAPD=`sudo pgrep hostapd`
if [ -n "$HOSTAPD" ]; then
	echo "hostapd running, terminating..."
	sudo kill -9 "$HOSTAPD"
fi

echo -e "${STYLE_HEADING}Performing SD card imaging-prep operations...${STYLE_NONE}"

echo -e "  ${STYLE_HEADING}deleting git artefacts...${STYLE_NONE}"
rm -rf "$WFU_TOOLS/.git"
rm -f "$WFU_TOOLS/.git*"
rm -f "~/*.log"

echo -e "  ${STYLE_HEADING}removing config-only apt entries...${STYLE_NONE}"
dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs sudo apt-get -y purge
	
echo -e "  ${STYLE_HEADING}cleaning up...${STYLE_NONE}"
sudo apt-get -y autoremove
sudo apt-get -y clean
sudo apt-get -y autoclean

echo -e "  ${STYLE_HEADING}writing zeros to free space...${STYLE_NONE}"
sudo sfill -f -ll -z /

echo -e "  ${STYLE_HEADING}deleting logs...${STYLE_NONE}"
sudo rm `find /var/log -type f`
echo -e "  ${STYLE_SUCCESS}done! The system will halt in 5 seconds. ${STYLE_NONE}\n"

sleep 5

sudo shutdown -h now

exit 0
