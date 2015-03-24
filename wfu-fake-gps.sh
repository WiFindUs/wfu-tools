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

if [ -z $1 ]; then
	MESSAGE="Fakegps data currently set to:"
	
	if [ -f "$WFU_HOME/.fakegps-latitude" ]; then
		LATITUDE=`cat $WFU_HOME/.fakegps-latitude | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
		if [ -n "$LATITUDE" ]; then
			LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
		fi
	fi
	if [ -z "$LATITUDE" ]; then
		LATITUDE="n/a"
	fi
	MESSAGE="$MESSAGE\n  Latitude: $LATITUDE"
	
	if [ -f "$WFU_HOME/.fakegps-longitude" ]; then
		LONGITUDE=`cat $WFU_HOME/.fakegps-longitude | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
		if [ -n "$LONGITUDE" ]; then
			LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
		fi
	fi
	if [ -z "$LONGITUDE" ]; then
		LONGITUDE="n/a"
	fi
	MESSAGE="$MESSAGE\n  Longitude: $LONGITUDE"
	
	if [ -f "$WFU_HOME/.fakegps-altitude" ]; then
		ALTITUDE=`cat $WFU_HOME/.fakegps-altitude | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
		if [ -n "$ALTITUDE" ]; then
			ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
		fi
	fi
	if [ -z "$ALTITUDE" ]; then
		ALTITUDE="n/a"
	fi
	MESSAGE="$MESSAGE\n  Altitude: $ALTITUDE"
	
	if [ -f "$WFU_HOME/.fakegps-accuracy" ]; then
		ACCURACY=`cat $WFU_HOME/.fakegps-accuracy | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
		if [ -n "$ACCURACY" ]; then
			ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
		fi
	fi
	if [ -z "$ACCURACY" ]; then
		ACCURACY="n/a"
	fi
	MESSAGE="$MESSAGE\n  Accuracy: $ACCURACY"
	
	echo -e $MESSAGE
	exit 0
fi

REMOVE=`echo "$1" | grep -E -o -m 1 -i "(rem(ove)?|clear|none|del(ete)?|off|def(ault)?)"`
if [ -n "$REMOVE" ]; then
	rm -f $WFU_HOME/.fakegps-*
	echo "Cleared all fakegps data."
	exit 0
fi

LATITUDE=`echo "$1" | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
LONGITUDE=`echo "$2" | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
ALTITUDE=`echo "$3" | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
ACCURACY=`echo "$4" | grep -E -o -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
if [ -n "$LATITUDE" ]; then
	if [ -n "$LONGITUDE" ]; then
		LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
		LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
		echo "$LATITUDE" > $WFU_HOME/.fakegps-latitude
		echo "$LONGITUDE" > $WFU_HOME/.fakegps-longitude
		MESSAGE="Set fakegps data to:\n  Latitude: $LATITUDE\n  Longitude: $LONGITUDE"
		
		if [ -n "$ALTITUDE" ]; then
			ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
			echo "$ALTITUDE" > $WFU_HOME/.fakegps-altitude
			MESSAGE="$MESSAGE\n  Altitude: $ALTITUDE"
		else
			rm -f $WFU_HOME/.fakegps-altitude
			MESSAGE="$MESSAGE\n  Altitude: n/a"
		fi
		
		if [ -n "$ACCURACY" ]; then
			ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
			echo "$ACCURACY" > $WFU_HOME/.fakegps-accuracy
			MESSAGE="$MESSAGE\n  Accuracy: $ACCURACY"
		else
			rm -f $WFU_HOME/.fakegps-accuracy
			MESSAGE="$MESSAGE\n  Accuracy: n/a"
		fi
		
		echo -e $MESSAGE
		exit 0
	else
		echo "ERROR: longitude argument missing or invalid."
	fi
else
	echo "ERROR: latitude argument missing or invalid."
fi

echo -e "Usage:\n  wfu-fake-gps\n  wfu-fake-gps <latitude> <longitude> [<altitude>] [<accuracy>]\n  wfu-fake-gps clear"
exit 2