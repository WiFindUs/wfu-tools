#! /bin/bash
#===============================================================
# File: wfu-update-wifi.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Updates the system wifi drivers.
#===============================================================
cd /lib/firmware
sudo rm -f htc_9271.fw htc_7010.fw
sudo route add -net 0.0.0.0 gw 192.168.1.254 eth0

echo -e "${STYLE_HEADING}Downloading Atheros 9271 firmware...${STYLE_NONE}"
sudo wget -q http://www.wifindus.com/downloads/htc_9271.fw
if [ -f htc_9271.fw ]; then
	echo -e "  ${STYLE_SUCCESS}OK!${STYLE_NONE}"
else
	echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
fi

echo -e "${STYLE_HEADING}Downloading Atheros 7010 firmware...${STYLE_NONE}"
sudo wget -q http://www.wifindus.com/downloads/htc_7010.fw
if [ -f htc_7010.fw ]; then
	echo -e "  ${STYLE_SUCCESS}OK!${STYLE_NONE}"
else
	echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
fi
sudo route del -net 0.0.0.0 gw 192.168.1.254 eth0
