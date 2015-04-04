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
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

if [ -z "$1" ]; then
	echo -e "${STYLE_HEADING}Fakegps configuration:${STYLE_NONE}"
	
	if [ -f "$WFU_HOME/.fakegps-latitude" ]; then
		LATITUDE=`grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?" "$WFU_HOME/.fakegps-latitude"`
		if [ -n "$LATITUDE" ]; then
			LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
		fi
	fi
	if [ -z "$LATITUDE" ]; then
		LATITUDE="n/a"
	fi
	echo "  Latitude      : $LATITUDE"
	
	if [ -f "$WFU_HOME/.fakegps-longitude" ]; then
		LONGITUDE=`grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?" "$WFU_HOME/.fakegps-longitude"`
		if [ -n "$LONGITUDE" ]; then
			LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
		fi
	fi
	if [ -z "$LONGITUDE" ]; then
		LONGITUDE="n/a"
	fi
	echo "  Longitude     : $LONGITUDE"
	
	if [ -f "$WFU_HOME/.fakegps-altitude" ]; then
		ALTITUDE=`grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?" "$WFU_HOME/.fakegps-altitude"`
		if [ -n "$ALTITUDE" ]; then
			ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
		fi
	fi
	if [ -z "$ALTITUDE" ]; then
		ALTITUDE="n/a"
	fi
	echo "  Altitude      : $ALTITUDE"
	
	if [ -f "$WFU_HOME/.fakegps-accuracy" ]; then
		ACCURACY=`grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?" "$WFU_HOME/.fakegps-accuracy"`
		if [ -n "$ACCURACY" ]; then
			ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
		fi
	fi
	if [ -z "$ACCURACY" ]; then
		ACCURACY="n/a"
	fi
	echo "  Accuracy      : $ACCURACY"
	
	exit 0
fi

REMOVE=`echo "$1" | grep -Eoi -m 1 "(rem(ove)?|clear|none|del(ete)?|off|def(ault)?)"`
if [ -n "$REMOVE" ]; then
	rm -f "$WFU_HOME/.fakegps-*"
	echo -e "${STYLE_SUCCESS}Cleared all fakegps data.${STYLE_NONE}"
	exit 0
fi

LATITUDE=`echo "$1" | grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
LONGITUDE=`echo "$2" | grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
ALTITUDE=`echo "$3" | grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
ACCURACY=`echo "$4" | grep -Eo -m 1 "[+-]?[0-9]+([.][0-9]+)?"`
if [ -n "$LATITUDE" ]; then
	if [ -n "$LONGITUDE" ]; then
		LATITUDE=`printf '%.*f\n' 6 $LATITUDE`
		LONGITUDE=`printf '%.*f\n' 6 $LONGITUDE`
		echo "$LATITUDE" > "$WFU_HOME/.fakegps-latitude"
		echo "$LONGITUDE" > "$WFU_HOME/.fakegps-longitude"
		echo -e "${STYLE_HEADING}Set fakegps data to:${STYLE_NONE}"
		echo -e "  Latitude      : $LATITUDE"
		echo -e "  Longitude     : $LONGITUDE"
		
		if [ -n "$ALTITUDE" ]; then
			ALTITUDE=`printf '%.*f\n' 6 $ALTITUDE`
			echo "$ALTITUDE" > "$WFU_HOME/.fakegps-altitude"
		else
			rm -f "$WFU_HOME/.fakegps-altitude"
			ALTITUDE="n/a"
		fi
		echo -e "  Altitude      : $ALTITUDE"
		
		if [ -n "$ACCURACY" ]; then
			ACCURACY=`printf '%.*f\n' 1 $ACCURACY`
			echo "$ACCURACY" > "$WFU_HOME/.fakegps-accuracy"
		else
			rm -f "$WFU_HOME/.fakegps-accuracy"
			ACCURACY="n/a"
		fi
		echo -e "  Accuracy      : $ACCURACY"
		sudo chmod 666 "$WFU_HOME/.fakegps-*"
		exit 0
	else
		echo "ERROR: longitude argument missing or invalid."
	fi
else
	echo "ERROR: latitude argument missing or invalid."
fi

echo -e "Usage:\n  wfu-fake-gps\n  wfu-fake-gps <latitude> <longitude> [<altitude>] [<accuracy>]\n  wfu-fake-gps clear"
exit 2