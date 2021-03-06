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

function trimz ()
{
	VAL=`echo "$1" | sed -r 's/^0+([1-9.])/\1/' | sed -r 's/([1-9.])0+$/\1/' | sed -r 's/[.]$//' | sed -r 's/^[.]/0&/'`
	if [ -z "$VAL" ]; then
		VAL=0
	fi
	echo $VAL	
}

PORT=`shuf -i 33339-33345 -n 1`

# loop
while true; do
	if [ -f "$WFU_HOME/.heartbeat-sleep" ]; then
		SLEEP=`grep -Eo -m 1 "[+]?[0-9]+" "$WFU_HOME/.heartbeat-sleep"`
	fi
	if [ -z "$SLEEP" ]; then
		SLEEP=10
	elif [ $SLEEP -le 0 ]; then
		SLEEP=1
	fi

	SERVER=""
	if [ -f "$WFU_HOME/.heartbeat-server" ]; then
		SERVER=`cat "$WFU_HOME/.heartbeat-server"`
	fi
	if [ -z "$SERVER" ]; then
		SERVER="wfu-server"
	fi

	FLAGS=0
	TIMESTAMP=`date +"%s"`
	TIMESTAMP=`printf "%x\n" $TIMESTAMP  | tr '[:lower:]' '[:upper:]'`
	PACKET="EYE{NODE|$WFU_BRAIN_ID_HEX|$TIMESTAMP{num:$WFU_BRAIN_NUM|ver:$WFU_VERSION"
	
	MESH_0=`sudo ifconfig | grep -m 1 "^mesh0"`
	if [ -n "$MESH_0" ]; then
		FLAGS=$(($FLAGS | 1))
		MESH_PEERS=`wfu-mesh-peers -lq , 2>/dev/null`
		if [ -n "$MESH_PEERS" ]; then
			PACKET="$PACKET|mpl:${MESH_PEERS}"
		else
			PACKET="$PACKET|mpl:0"
		fi
	else
		PACKET="$PACKET|mpl:0"
	fi
	
	HOSTAPD=`pgrep -l hostapd`
	AP_0=`sudo ifconfig | grep -m 1 "^ap0"`
	if [ -n "$HOSTAPD" -a -n "$AP_0" ]; then
		FLAGS=$(($FLAGS | 2))
	fi
	
	DHCPD=`pgrep -l dhcpd`
	if [ -n "$DHCPD" ]; then
		FLAGS=$(($FLAGS | 4))
	fi	

	GPSD=`pgrep -l gpsd`
	if [ -n "$GPSD" ]; then
		FLAGS=$(($FLAGS | 8))
		GPS_DATA=`gpspipe -w -n 7`
		if [ -n "$GPS_DATA" ]; then
			TPV_DATA=`echo "$GPS_DATA" | grep -E -m 1 "\"class\":\"TPV\""`
			if [ -n "$TPV_DATA" ]; then
				LONGITUDE=`echo "$TPV_DATA" | grep -Eo -m 1 "\"lon\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				LATITUDE=`echo "$TPV_DATA" | grep -Eo -m 1 "\"lat\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				ALTITUDE=`echo "$TPV_DATA" | grep -Eo -m 1 "\"alt\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				ACC_X=`echo "$TPV_DATA" | grep -Eo -m 1 "\"epx\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				ACC_Y=`echo "$TPV_DATA" | grep -Eo -m 1 "\"epy\":[+-]?[0-9]+([.][0-9]+)?" | cut -d':' -f2`
				
				if [ -n "$LONGITUDE" ]; then
					LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
					LONGITUDE=`trimz $LONGITUDE`
					PACKET="$PACKET|long:$LONGITUDE"
				fi

				if [ -n "$LATITUDE" ]; then
					LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
					LATITUDE=`trimz $LATITUDE`
					PACKET="$PACKET|lat:$LATITUDE"
				fi

				if [ -n "$ALTITUDE" ]; then
					ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
					ALTITUDE=`trimz $ALTITUDE`
					PACKET="$PACKET|alt:$ALTITUDE"
				fi
				
				if [ -z "$ACC_X" -a -n "$ACC_Y" ]; then
					ACC_X="$ACC_Y"
				elif [ -z "$ACC_Y" -a -n "$ACC_X" ]; then
					ACC_Y="$ACC_X"
				fi
				
				if [ -n "$ACC_Y" -a -n "$ACC_X" ]; then
					ACCURACY=`echo "($ACC_X + $ACC_Y) / 2.0" | bc`
					if [ -n "$ACCURACY" ]; then
						ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
						ACCURACY=`trimz $ACCURACY`
						PACKET="$PACKET|acc:$ACCURACY"
					fi
				fi
			fi
			
			SKY_DATA=`echo "$GPS_DATA" | grep -E -m 1 "\"class\":\"SKY\""`
			if [ -n "$SKY_DATA" ]; then
				SATCOUNT=`echo "$SKY_DATA" | grep -Eo -m 1 "\"satellites\":\[.*\]" | grep -o -P "{.*?\"used\":true.*?}" | wc -l`
				if [ -n "$SATCOUNT" ]; then
					PACKET="$PACKET|sats:$SATCOUNT"
				fi
			fi
		fi
	else
		if [ -f "$WFU_HOME/.fakegps-latitude" -a -f "$WFU_HOME/.fakegps-longitude" ]; then
			LATITUDE=`grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?" "$WFU_HOME/.fakegps-latitude"`
			LONGITUDE=`grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?" "$WFU_HOME/.fakegps-longitude"`
			if [ -n "$LATITUDE" -a -n "LONGITUDE" ]; then
				FLAGS=$(($FLAGS | 16))
				LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
				LATITUDE=`trimz $LATITUDE`
				LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
				LONGITUDE=`trimz $LONGITUDE`
				PACKET="$PACKET|lat:$LATITUDE|long:$LONGITUDE"
				if [ -f "$WFU_HOME/.fakegps-altitude" ]; then
					ALTITUDE=`grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?" "$WFU_HOME/.fakegps-altitude"`
					if [ -n "$ALTITUDE" ]; then
						ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
						ALTITUDE=`trimz $ALTITUDE`
						PACKET="$PACKET|alt:$ALTITUDE"
					fi
				fi
				if [ -f "$WFU_HOME/.fakegps-accuracy" ]; then
					ACCURACY=`grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?" "$WFU_HOME/.fakegps-accuracy"`
					if [ -n "$ACCURACY" ]; then
						ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
						ACCURACY=`trimz $ACCURACY`
						PACKET="$PACKET|acc:$ACCURACY"
					fi
				fi
			fi
		fi
	fi

	echo "$PACKET|flg:$FLAGS}}" > "/dev/udp/$SERVER/$PORT"
	
	if [ $SLEEP -ge 1 ]; then
		sleep $SLEEP
	fi
done
exit 0