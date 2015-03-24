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

if [ -z $1 ]; then
	MESSAGE="Heartbeat packet configuration currently set to:"
	
	if [ -f "$WFU_HOME/.heartbeat-sleep" ]; then
		SLEEP=`cat $WFU_HOME/.heartbeat-sleep | grep -E -o -m 1 "[+]?[0-9]+"`
	else
		SLEEP=1
	fi
	if [ -z $SLEEP ]; then
		SLEEP=10
	fi
	MESSAGE="$MESSAGE\n  Sleep: $SLEEP"
	
	if [ -f "$WFU_HOME/.heartbeat-server" ]; then
		SERVER=`cat $WFU_HOME/.heartbeat-server`
	fi
	if [ -z $SERVER ]; then
		SERVER="wfu-server"
	fi
	MESSAGE="$MESSAGE\n  Server: $SERVER"
	
	if [ -f "$WFU_HOME/.heartbeat-port" ]; then
		PORT=`cat $WFU_HOME/.heartbeat-port | grep -E -o -m 1 "[0-9]{1,5}"`
	fi
	if [ -z $PORT ] || [ $PORT -le 0 ] || [ $PORT -ge 65535 ]; then
		PORT=33339
	fi
	MESSAGE="$MESSAGE\n  Port: $PORT"
	
	echo -e $MESSAGE
	exit 0
fi

REMOVE=`echo "$1" | grep -E -o -m 1 -i "(rem(ove)?|clear|none|del(ete)?|off|def(ault)?)"`
if [ -n "$REMOVE" ]; then
	rm -f $WFU_HOME/.heartbeat-*
	echo "Reset heartbeat packet configuration to default."
	exit 0
fi

SLEEP=`echo "$1" | grep -E -o -m 1 "[+]?[0-9]+"`
SERVER=`echo "$2" | grep -E -o -i -m 1 "[0-9a-z:_./]+"`
PORT=`echo "$3" | grep -E -o -m 1 "[0-9]{1,5}"`
if [ -n "$SLEEP" ]; then
	if [ $SLEEP -le 0 ]; then
		SLEEP=1
	fi
	echo "$SLEEP" > $WFU_HOME/.heartbeat-sleep
	MESSAGE="Set heartbeat packet configuration to:\n  Sleep: $SLEEP sec"
	
	if [ -n "$SERVER" ]; then
		echo "$SERVER" > $WFU_HOME/.heartbeat-server
		MESSAGE="$MESSAGE\n  Server: $SERVER"
	else
		rm -f $WFU_HOME/.heartbeat-server
		MESSAGE="$MESSAGE\n  Server: wfu-server"
	fi
	
	if [ -n "$PORT" ] && [ $PORT -gt 0 ] && [ $PORT -lt 65535 ]; then
		echo "$PORT" > $WFU_HOME/.heartbeat-port
		MESSAGE="$MESSAGE\n  Port: $PORT"
	else
		rm -f $WFU_HOME/.heartbeat-port
		MESSAGE="$MESSAGE\n  Port: 33339"
	fi
	
	echo -e $MESSAGE
	exit 0
else
	echo "ERROR: sleep argument missing or invalid."
fi

echo -e "Usage:\n  wfu-heartbeat-config\n  wfu-heartbeat-config <sleep> [<server>] [<port>]\n  wfu-heartbeat-config clear"
exit 2