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
	echo "ERROR: Could not find globals for current user. aborting."
	exit 1
fi

REMOVE=`echo "$1" | grep -E -o -m 1 -i "(rem(ove)?|clear|none|del(ete)?|off|def(ault)?)"`
if [ -n $REMOVE ]; then
	rm -f $WFU_HOME/.heartbeat-*
	echo "Reset heartbeat packet configuration to default."
	exit 0
fi

SLEEP=`echo "$1" | grep -E -o -m 1 "[+]?[0-9]+"`
SERVER=`echo "$2" | grep -E -o -i -m 1 "[0-9a-z:_./]"`
PORT=`echo "$3" | grep -E -o -m 1 "[0-9]{1,5}"`

if [ -n $SLEEP ]; then
	if [ $SLEEP -le 0 ]; then
		SLEEP=1
	fi
	echo "$SLEEP" > $WFU_HOME/.heartbeat-sleep
	MESSAGE="Set heartbeat packet configuration to Sleep: $SLEEP sec"
	
	if [ -n $SERVER ]; then
		echo "$SERVER" > $WFU_HOME/.heartbeat-server
		MESSAGE="$MESSAGE, Server: $SERVER"
	else
		rm -f $WFU_HOME/.heartbeat-server
	fi
	
	if [ -n $PORT ] && [ $PORT -gt 0 ] && [ $PORT -lt 65535 ]; then
		echo "$PORT" > $WFU_HOME/.heartbeat-port
		MESSAGE="$MESSAGE, Port: $PORT"
	else
		rm -f $WFU_HOME/.heartbeat-port
	fi
	
	echo $MESSAGE
	exit 0
else
	echo "ERROR: invalid sleep argument."
fi

echo -e "Usage: wfu-heartbeat-config <sleep> [<server>] [<port>]\n   or: wfu-heartbeat-config clear"
exit 2