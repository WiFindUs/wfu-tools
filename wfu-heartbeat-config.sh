#! /bin/bash
#===============================================================
# File: wfu-heartbeat-config.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Sets or clears the heartbeat packet settings.
#===============================================================

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

if [ -z "$1" ]; then
	echo -e "${STYLE_HEADING}Heartbeat packet configuration:${STYLE_NONE}"
	
	if [ -f "$WFU_HOME/.heartbeat-sleep" ]; then
		SLEEP=`grep -Eo -m 1 "[+]?[0-9]+" "$WFU_HOME/.heartbeat-sleep"`
	fi
	if [ -z "$SLEEP" ]; then
		SLEEP=10
	fi
	echo "  Sleep         : $SLEEP"
	
	if [ -f "$WFU_HOME/.heartbeat-server" ]; then
		SERVER=`cat $WFU_HOME/.heartbeat-server`
	fi
	if [ -z "$SERVER" ]; then
		SERVER="wfu-server"
	fi
	echo "  Server        : $SERVER"

	exit 0
fi

REMOVE=`echo "$1" | grep -E -o -m 1 -i "(rem(ove)?|clear|none|del(ete)?|off|def(ault)?)"`
if [ -n "$REMOVE" ]; then
	rm -f $WFU_HOME/.heartbeat-*
	echo -e "${STYLE_SUCCESS}Reset heartbeat packet configuration to default.${STYLE_NONE}"
	exit 0
fi

echo -e "${STYLE_HEADING}Set heartbeat packet configuration to:${STYLE_NONE}"
SERVER=`echo "$1" | grep -E -o -i -m 1 "[0-9a-z:_./]+"`
if [ -n "$SERVER" ]; then
	echo "$SERVER" > "$WFU_HOME/.heartbeat-server"
else
	rm -f "$WFU_HOME/.heartbeat-server"
	SERVER="wfu-server"
fi
echo -e "  Server        : $SERVER"

SLEEP=`echo "$2" | grep -E -o -m 1 "[+]?[0-9]+"`
if [ -n "$SLEEP" ]; then
	if [ $SLEEP -le 0 ]; then
		SLEEP=1
	fi
	echo "$SLEEP" > "$WFU_HOME/.heartbeat-sleep"
else
	rm -f "$WFU_HOME/.heartbeat-sleep"
	SLEEP=10
fi
echo -e "  Sleep         : $SLEEP sec"

exit 0