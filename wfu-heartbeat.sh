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
	GPS_DATA=`gpspipe -w -n 6`
	if [ -n "$GPS_DATA" ]; then
		TPV_DATA=`echo "$GPS_DATA" | grep -E -m 1 "\"class\":\"TPV\""`
		if [ -n "$TPV_DATA" ]; then
			LONGITUDE=`echo "$TPV_DATA" | grep -E -o -m 1 "\"lon\":[+-]?[0-9]+[.][0-9]+" | cut -d':' -f2`
			LATITUDE=`echo "$TPV_DATA" | grep -E -o -m 1 "\"lat\":[+-]?[0-9]+[.][0-9]+" | cut -d':' -f2`
			ALTITUDE=`echo "$TPV_DATA" | grep -E -o -m 1 "\"alt\":[+-]?[0-9]+[.][0-9]+" | cut -d':' -f2`
			ACC_X=`echo "$TPV_DATA" | grep -E -o -m 1 "\"epx\":[+-]?[0-9]+[.][0-9]+" | cut -d':' -f2`
			ACC_Y=`echo "$TPV_DATA" | grep -E -o -m 1 "\"epy\":[+-]?[0-9]+[.][0-9]+" | cut -d':' -f2`
			
			if [ -z "$ACC_X" -a -n "$ACC_Y" ]; then
				ACC_X="$ACC_Y"
			elif [ -z "$ACC_Y" -a -n "$ACC_X" ]; then
				ACC_Y="$ACC_X"
			fi
			
			if [ -n "$ACC_Y" -a -n "$ACC_X" ]; then
				ACCURACY=`expr $ACC_X + $ACC_Y`
				ACCURACY=`expr $ACCURACY / 2.0`
			fi
		fi
		
		SKY_DATA=`echo "$GPS_DATA" | grep -E -m 1 "\"class\":\"SKY\""`
		if [ -n "$SKY_DATA" ]; then
			SATCOUNT=`echo "$SKY_DATA" | grep -E -m 1 -o "\"satellites\":\[.*\]" | grep -o -P "{.*?\"used\":true.*?}" | wc -l`
		fi
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

if [ -n "$ACCURACY" ]; then
	PACKET="$PACKET|acc:$ACCURACY"
fi

if [ -n "$SATCOUNT" ]; then
	PACKET="$PACKET|sats:$SATCOUNT"
fi

echo "$PACKET";

exit 0