#! /bin/bash
#===============================================================
# File: wfu-heartbeat.sh
# Author: Mark Gillard
# Description:
#   Sends a heartbeat packet back to the server.
#===============================================================

COUNT=$1
if [ -z $COUNT -o $COUNT -le 0 ]; then
	COUNT=1
fi

SLEEP=$2
if [ -z $SLEEP -o $SLEEP -lt 0 ]; then
	SLEEP=0
fi

SERVER=$3
if [ -z "$SERVER" ]; then
	SERVER="wfu-server"
fi

PORT=$4
if [ -z "$PORT" ]; then
	PORT="33339"
fi

	for i in {1..$COUNT}; do
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
					ACCURACY=`echo "($ACC_X + $ACC_Y) / 2.0" | bc`
				fi
			fi
			
			SKY_DATA=`echo "$GPS_DATA" | grep -E -m 1 "\"class\":\"SKY\""`
			if [ -n "$SKY_DATA" ]; then
				SATCOUNT=`echo "$SKY_DATA" | grep -E -m 1 -o "\"satellites\":\[.*\]" | grep -o -P "{.*?\"used\":true.*?}" | wc -l`
			fi
		fi
	fi

	if [ -n "$LONGITUDE" ]; then
		LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
		PACKET="$PACKET|long:$LONGITUDE"
	fi

	if [ -n "$LATITUDE" ]; then
		LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
		PACKET="$PACKET|lat:$LATITUDE"
	fi

	if [ -n "$ALTITUDE" ]; then
		ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
		PACKET="$PACKET|alt:$ALTITUDE"
	fi

	if [ -n "$ACCURACY" ]; then
		PACKET="$PACKET|acc:$ACCURACY"
	fi

	if [ -n "$SATCOUNT" ]; then
		PACKET="$PACKET|sats:$SATCOUNT"
	fi

	echo "$PACKET";
	echo "$PACKET" > "/dev/udp/$SERVER/$PORT"
	sleep $SLEEP
done
exit 0