#! /bin/bash
#===============================================================
# File: wfu-fake-gps.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Sets or clears the 'fake gps' fallback heartbeat data.
#===============================================================

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting."
	exit 1
fi

REMOVE=`echo "$1" | grep -E -o -m 1 -i "(remove|clear)"`
if [ -n "$REMOVE" ]; then
	rm -f $WFU_HOME/.fakegps-*
	echo "Cleared all fakegps data."
	exit 0
fi

LATITUDE=`echo "$1" | grep -E -o -m 1 "[+-]?[0-9]+[.][0-9]+"`
LONGITUDE=`echo "$2" | grep -E -o -m 1 "[+-]?[0-9]+[.][0-9]+"`
ALTITUDE=`echo "$3" | grep -E -o -m 1 "[+-]?[0-9]+[.][0-9]+"`
ACCURACY=`echo "$4" | grep -E -o -m 1 "[+-]?[0-9]+[.][0-9]+"`
if [ -n "$LATITUDE" ] && [ -n "$LONGITUDE" ]; then
	LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
	LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
	echo "$LATITUDE" > $WFU_HOME/.fakegps-latitude
	echo "$LONGITUDE" > $WFU_HOME/.fakegps-longitude
	MESSAGE="Set fakegps data to Latitude: $LATITUDE, Longitude: $LONGITUDE"
	
	if [ -n "$ALTITUDE" ]; then
		ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
		echo "$ALTITUDE" > $WFU_HOME/.fakegps-altitude
		MESSAGE="$MESSAGE, Altitude: $ALTITUDE"
	else
		rm -f $WFU_HOME/.fakegps-altitude
	fi
	
	if [ -n "$ACCURACY" ]; then
		ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
		echo "$ACCURACY" > $WFU_HOME/.fakegps-accuracy
		MESSAGE="$MESSAGE, Accuracy: $ACCURACY"
	else
		rm -f $WFU_HOME/.fakegps-accuracy
	fi
	
	echo $MESSAGE
	exit 0
else
	echo "ERROR: invalid latitude or longitude arguments."
fi

echo -e "Usage: wfu-fake-gps latitude longitude [altitude] [accuracy]\n   or: wfu-fake-gps clear"
exit 2