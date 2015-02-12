#! /bin/bash
#===============================================================
# File: wfu-heartbeat.sh
# Author: Mark Gillard
# Description:
#   Sends a heartbeat packet back to the server.
#===============================================================

COUNT=$1
if [ -z $COUNT ]; then
	COUNT=5
elif [ $COUNT -eq 0 ]; then
	exit 0
fi

SLEEP=$2
if [ -z $SLEEP ] || [ $SLEEP -lt 0 ]; then
	SLEEP=1
fi

SERVER=$3
if [ -z "$SERVER" ]; then
	SERVER="wfu-server"
fi

PORT=$4
if [ -z "$PORT" ]; then
	PORT="33339"
fi

if [ -f "/home/pi/.wfu-brain-id" ]; then
	BRAIN_ID=`cat /home/pi/.wfu-brain-id | grep -E -o -m 1 "[1-9][0-9]*"`
	BRAIN_ID=`printf "%x\n" $BRAIN_ID | tr '[:lower:]' '[:upper:]'`
fi
if [ -f "/home/pi/.wfu-brain-num" ]; then
	BRAIN_NUM=`cat /home/pi/.wfu-brain-num | grep -E -o -m 1 "([1-2][0-9]{2}|[1-9][0-9]|[1-9])"`
fi
if [ -z $BRAIN_ID ] || [ -z $BRAIN_NUM ]; then
	exit 1
fi

COUNTER=0
while true; do
	TIMESTAMP=`date +"%s"`
	TIMESTAMP=`printf "%x\n" $TIMESTAMP  | tr '[:lower:]' '[:upper:]'`
	PACKET="EYE|NODE|$BRAIN_ID|$TIMESTAMP|num:$BRAIN_NUM"
	
	MESH_0=`ifconfig | grep -m 1 "^mesh0"`
	if [ -n "$MESH_0" ]; then
		PACKET="$PACKET|mp:1"
	else
		PACKET="$PACKET|mp:0"
	fi
	
	MESH_PEERS=`sudo iw dev mesh0 mpath dump | grep mesh0`
	if [ -n "$MESH_0" ]; then
		MESH_PEER_LIST="peers:"
		while read -r PEER; do
			echo $PEER
		done <<< "$MESH_PEERS"
	fi
	
	HOSTAPD=`pstree | grep -m 1 -o "hostapd"`
	AP_0=`ifconfig | grep -m 1 "^ap0"`
	MON_AP_0=`ifconfig | grep -m 1 "^mon.ap0"`
	if [ -n "$HOSTAPD" ] && [ -n "$AP_0" ] && [ -n "$MON_AP_0" ]; then
		PACKET="$PACKET|ap:1"
	else
		PACKET="$PACKET|ap:0"
	fi
	
	DHCPD=`pstree | grep -m 1 -o "dhcpd"`
	if [ -n "$DHCPD" ]; then
		PACKET="$PACKET|dhcp:1"
	else
		PACKET="$PACKET|dhcp:0"
	fi	

	GPSD=`pstree | grep -m 1 -o "gpsd"`
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
				
				if [ -z "$ACC_X" ] || [ -n "$ACC_Y" ]; then
					ACC_X="$ACC_Y"
				elif [ -z "$ACC_Y" ] || [ -n "$ACC_X" ]; then
					ACC_Y="$ACC_X"
				fi
				
				if [ -n "$ACC_Y" ] || [ -n "$ACC_X" ]; then
					ACCURACY=`echo "($ACC_X + $ACC_Y) / 2.0" | bc`
				fi
			fi
			
			SKY_DATA=`echo "$GPS_DATA" | grep -E -m 1 "\"class\":\"SKY\""`
			if [ -n "$SKY_DATA" ]; then
				SATCOUNT=`echo "$SKY_DATA" | grep -E -m 1 -o "\"satellites\":\[.*\]" | grep -o -P "{.*?\"used\":true.*?}" | wc -l`
			fi
		fi
		PACKET="$PACKET|gpsd:1"
	else
		PACKET="$PACKET|gpsd:0"
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

	echo "$PACKET"
	echo "$PACKET" > "/dev/udp/$SERVER/$PORT"
	
	COUNTER=`expr $COUNTER + 1`
	if [ $COUNT -gt 0 ] && [ $COUNTER -ge $COUNT ]; then
		break
	fi
	
	sleep $SLEEP
done
exit 0