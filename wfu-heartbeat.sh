#! /bin/bash
#===============================================================
# File: wfu-heartbeat.sh
# Author: Mark Gillard
# Description:
#   Sends a heartbeat packet back to the server.
#===============================================================

TIMESTAMP=`date +"%s"`
TIMESTAMP=`printf "%x\n" $TIMESTAMP  | tr '[:lower:]' '[:upper:]'`
PACKET="EYE|NODE|$WFU_BRAIN_ID_HEX|$TIMESTAMP|num:$WFU_BRAIN_NUM"

GPSD=`ps aux | grep -m 1 "gpsd"`
if [ -n "$GPSD" ]; then
	GPSDATA=`gpspipe -w -n 10 | grep -m 1 "lat"`
	if [ -n "$GPSDATA" ]; then
		LONGITUDE=`echo "$GPSDATA" | grep -E -o -i -m 1 "\"lon\":[+-]?[0-9]+[.][0-9]+" | cut -d':' -f2`
		LATITUDE=`echo "$GPSDATA" | grep -E -o -i -m 1 "\"lat\":[+-]?[0-9]+[.][0-9]+" | cut -d':' -f2`
		ALTITUDE=`echo "$GPSDATA" | grep -E -o -i -m 1 "\"alt\":[+-]?[0-9]+[.][0-9]+" | cut -d':' -f2`
	fi
fi

if [ -n "$LONGITUDE" ]; then
	PACKET="$PACKET|long:$LONGITUDE"
fi

if [ -n "$LATITUDE" ]; then
	PACKET="$PACKET|lat:$LATITUDE"
fi

if [ -n "$ALTITUDE" ]; then
	PACKET="$PACKET|alt:$ALTITUDE"
fi

echo "$PACKET";

exit 0