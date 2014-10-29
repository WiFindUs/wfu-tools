#! /bin/bash
#===============================================================
# File: wfu-update-wifi.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Updates the system wifi drivers.
#===============================================================
cd /lib/firmware

echo -e "${STYLE_HEADING}Downloading Atheros 9271 firmware...${STYLE_NONE}"
sudo wget -q -O htc_9271.fw.new http://www.wifindus.com/downloads/htc_9271.fw
if [ -f htc_9271.fw.new ]; then
	sudo rm -f htc_9271.fw
	sudo mv htc_9271.fw.new htc_9271.fw
	echo -e "  ${STYLE_SUCCESS}OK!${STYLE_NONE}"
else
	echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
fi

echo -e "${STYLE_HEADING}Downloading Atheros 7010 firmware...${STYLE_NONE}"
sudo wget -q -O htc_7010.fw.new http://www.wifindus.com/downloads/htc_7010.fw
if [ -f htc_7010.fw.new ]; then
	sudo rm -f htc_7010.fw
	sudo mv htc_7010.fw.new htc_7010.fw
	echo -e "  ${STYLE_SUCCESS}OK!${STYLE_NONE}"
else
	echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
fi
