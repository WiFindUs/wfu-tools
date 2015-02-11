#! /bin/bash
#===============================================================
# File: wfu-heartbeat.sh
# Author: Mark Gillard
# Description:
#   Sends a heartbeat packet back to the server.
#===============================================================

if [ `ps aux | grep -m 1 gpsd` = "" ]; then
	echo -e "${STYLE_ERROR}error: gpsd not running.${STYLE_NONE}"
	exit 1
fi

$GPSDATA=`gpspipe -w -n 10 | grep -m 1 lat`
if [ $GPSDATA = "" ]; then
	echo -e "${STYLE_ERROR}error: no gps positioning data was returned.${STYLE_NONE}"
	exit 2
fi

echo $GPSDATA;

exit 0


 #| jsawk 'return this.lat'