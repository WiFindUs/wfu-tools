#! /bin/bash
#===============================================================
# File: wfu-heartbeat.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Sends a heartbeat packet back to the server.
#===============================================================

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

# loop
while true; do
	if [ -f "$WFU_HOME/.heartbeat-sleep" ]; then
		SLEEP=`cat $WFU_HOME/.heartbeat-sleep | grep -E -o -m 1 "[+]?[0-9]+"`
	fi
	if [ -z "$SLEEP" ]; then
		SLEEP=10
	elif [ $SLEEP -le 0 ]; then
		SLEEP=1
	fi

	if [ -f "$WFU_HOME/.heartbeat-server" ]; then
		SERVER=`cat $WFU_HOME/.heartbeat-server`
	else
		SERVER=""
	fi
	if [ -z "$SERVER" ]; then
		SERVER="wfu-server"
	fi

	if [ -f "$WFU_HOME/.heartbeat-port" ]; then
		PORT=`cat $WFU_HOME/.heartbeat-port | grep -E -o -m 1 "[0-9]{1,5}"`
	else
		PORT=0
	fi
	if [ -z "$PORT" ] || [ $PORT -le 0 ] || [ $PORT -ge 65535 ]; then
		PORT=33339
	fi

	TIMESTAMP=`date +"%s"`
	TIMESTAMP=`printf "%x\n" $TIMESTAMP  | tr '[:lower:]' '[:upper:]'`
	PACKET="EYE{NODE|$WFU_BRAIN_ID_HEX|$TIMESTAMP{num:$WFU_BRAIN_NUM|ver:$WFU_VERSION"
	
	MESH_0=`sudo ifconfig | grep -m 1 "^mesh0"`
	if [ -n "$MESH_0" ]; then
		PACKET="$PACKET|mp:1"
		MESH_PEERS=`wfu-mesh-peers -lq , 2>/dev/null`
		if [ -n "$MESH_PEERS" ]; then
			PACKET="$PACKET|mpl:${MESH_PEERS}"
		else
			PACKET="$PACKET|mpl:0"
		fi
	else
		PACKET="$PACKET|mp:0|mpl:0"
	fi
	
	HOSTAPD=`pgrep -l hostapd`
	AP_0=`sudo ifconfig | grep -m 1 "^ap0"`
	if [ -n "$HOSTAPD" ] && [ -n "$AP_0" ]; then
		PACKET="$PACKET|ap:1"
	else
		PACKET="$PACKET|ap:0"
	fi
	
	DHCPD=`pgrep -l dhcpd`
	if [ -n "$DHCPD" ]; then
		PACKET="$PACKET|dhcp:1"
	else
		PACKET="$PACKET|dhcp:0"
	fi	

	GPSD=`pgrep -l gpsd`
	if [ -n "$GPSD" ]; then
		PACKET="$PACKET|gps:1"
		GPS_DATA=`gpspipe -w -n 7`
		if [ -n "$GPS_DATA" ]; then
			TPV_DATA=`echo "$GPS_DATA" | grep -E -m 1 "\"class\":\"TPV\""`
			if [ -n "$TPV_DATA" ]; then
				LONGITUDE=`echo "$TPV_DATA" | grep -E -o -m 1 "\"lon\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				LATITUDE=`echo "$TPV_DATA" | grep -E -o -m 1 "\"lat\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				ALTITUDE=`echo "$TPV_DATA" | grep -E -o -m 1 "\"alt\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				ACC_X=`echo "$TPV_DATA" | grep -E -o -m 1 "\"epx\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				ACC_Y=`echo "$TPV_DATA" | grep -E -o -m 1 "\"epy\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				
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
				
				if [ -z "$ACC_X" ] && [ -n "$ACC_Y" ]; then
					ACC_X="$ACC_Y"
				elif [ -z "$ACC_Y" ] && [ -n "$ACC_X" ]; then
					ACC_Y="$ACC_X"
				fi
				
				if [ -n "$ACC_Y" ] && [ -n "$ACC_X" ]; then
					ACCURACY=`echo "($ACC_X + $ACC_Y) / 2.0" | bc`
					if [ -n "$ACCURACY" ]; then
						ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
						PACKET="$PACKET|acc:$ACCURACY"
					fi
				fi
			fi
			
			SKY_DATA=`echo "$GPS_DATA" | grep -E -m 1 "\"class\":\"SKY\""`
			if [ -n "$SKY_DATA" ]; then
				SATCOUNT=`echo "$SKY_DATA" | grep -E -m 1 -o "\"satellites\":\[.*\]" | grep -o -P "{.*?\"used\":true.*?}" | wc -l`
				if [ -n "$SATCOUNT" ]; then
					PACKET="$PACKET|sats:$SATCOUNT"
				fi
			fi
		fi
	else
		if [ -f "$WFU_HOME/.fakegps-latitude" ] && [ -f "$WFU_HOME/.fakegps-longitude" ]; then
			LATITUDE=`cat $WFU_HOME/.fakegps-latitude | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
			LONGITUDE=`cat $WFU_HOME/.fakegps-longitude | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
			if [ -n "$LATITUDE" ] && [ -n "LONGITUDE" ]; then
				LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
				LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
				PACKET="$PACKET|gps:2|lat:$LATITUDE|long:$LONGITUDE"
				if [ -f "$WFU_HOME/.fakegps-altitude" ]; then
					ALTITUDE=`cat $WFU_HOME/.fakegps-altitude | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
					if [ -n "$ALTITUDE" ]; then
						ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
						PACKET="$PACKET|alt:$ALTITUDE"
					fi
				fi
				if [ -f "$WFU_HOME/.fakegps-accuracy" ]; then
					ACCURACY=`cat $WFU_HOME/.fakegps-accuracy | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
					if [ -n "$ACCURACY" ]; then
						ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
						PACKET="$PACKET|acc:$ACCURACY"
					fi
				fi
			else
				PACKET="$PACKET|gps:0"
			fi
		else
			PACKET="$PACKET|gps:0"
		fi
	fi

	echo "$PACKET}}" > "/dev/udp/$SERVER/$PORT"
	
	if [ $SLEEP -ge 1 ]; then
		sleep $SLEEP
	fi
done
exit 0