#! /bin/bash
#===============================================================
# File: wfu-shell-globals.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Adds some global stuff to the shell environment
#===============================================================

# wfu globals
if [ -z "$WFU_HOME" ]; then
	WFU_HOME="/usr/local/wifindus"
	export WFU_HOME
fi
if [ -z "$WFU_TOOLS" ]; then
	WFU_TOOLS="$WFU_HOME/wfu-tools"
	export WFU_TOOLS
fi
if [ -z "$WFU_TOOLS_REPO" ]; then
	WFU_TOOLS_REPO="git://github.com/WiFindUs/wfu-tools.git"
	export WFU_TOOLS_REPO
fi
if [ -z "$WFU_USER" ]; then
	WFU_USER="wifindus"
	export WFU_USER
fi
if [ -z "$WFU_USER_HOME" ]; then
	WFU_USER_HOME="/home/$WFU_USER"
	export WFU_USER_HOME
fi

#version
if [ -f "$WFU_HOME/.version" ]; then
	WFU_VERSION=`grep -Eo -m 1 "[0-9]+" "$WFU_HOME/.version"`
fi
if [ -z "$WFU_VERSION" ]; then
	WFU_VERSION=20141231
	echo $WFU_VERSION > "$WFU_HOME/.version"
	sudo chmod 666 "$WFU_HOME/.version"
fi
export WFU_VERSION

#last running of wfu-update
if [ -f "$WFU_HOME/.last-update" ]; then
	WFU_LAST_UPDATED=`grep -Eo -m 1 "[0-9]{4}-[0-9]{2}-[0-9]{2} +[0-9]{2}:[0-9]{2}:[0-9]{2}" "$WFU_HOME/.last-update"`
fi
if [ -z "$WFU_LAST_UPDATED" ]; then
	WFU_LAST_UPDATED=`date +"%Y-%m-%d %H:%M:%S"`
	echo $WFU_LAST_UPDATED > "$WFU_HOME/.last-update"
	sudo chmod 666 "$WFU_HOME/.last-update"
fi
export WFU_LAST_UPDATED

# machine model
if [ -z "$MACHINE_MODEL" ]; then
	MACHINE_MODEL=`dmesg | grep -i -E "Machine model: .+" | cut -d' ' -f8-`
	export MACHINE_MODEL
fi

# is raspberry pi boolean
if [ -z "$IS_RASPBERRY_PI" ]; then
	IS_RASPBERRY_PI=`echo "$MACHINE_MODEL" | grep -i -o -m 1 "Raspberry"`
	if [ -z "$IS_RASPBERRY_PI" ]; then
		IS_RASPBERRY_PI=0
	else
		IS_RASPBERRY_PI=1
	fi
	export IS_RASPBERRY_PI
fi

# is cubox boolean
if [ -z "$IS_CUBOX" ]; then
	IS_CUBOX=`echo "$MACHINE_MODEL" | grep -i -o -m 1 "Cubox"`
	if [ -z "$IS_CUBOX" ]; then
		IS_CUBOX=0
	else
		IS_CUBOX=1
	fi
	export IS_CUBOX
fi

# is pc boolean
if [ -z "$IS_PC" ]; then
	IS_PC=`echo "$MACHINE_MODEL" | grep -i -o -m 1 "i dunno, something about x86"`
	if [ -z "$IS_PC" ]; then
		IS_PC=0
	else
		IS_PC=1
	fi
	export IS_PC
fi

# machine family
if [ -z "$MACHINE_FAMILY" ]; then
	if [ $IS_RASPBERRY_PI -eq 1 ]; then
		MACHINE_FAMILY="rpi"
	elif [ $IS_CUBOX -eq 1 ]; then
		MACHINE_FAMILY="cubox"
	elif [ $IS_PC -eq 1 ]; then
		MACHINE_FAMILY="pc"
	else
		MACHINE_FAMILY="unknown"
	fi
	export MACHINE_FAMILY
fi

# brain number
if [ -z "$WFU_BRAIN_NUM" ]; then
	if [ -f "$WFU_HOME/.brain-num" ]; then
		sudo chmod 666 "$WFU_HOME/.brain-num"
		WFU_BRAIN_NUM=`grep -Eo -m 1 "([1-2][0-9]{2}|[1-9][0-9]|[1-9])" "$WFU_HOME/.brain-num"`
	fi
	if [ -z "$WFU_BRAIN_NUM" ]; then
		WFU_BRAIN_NUM=0
		echo $WFU_BRAIN_NUM > "$WFU_HOME/.brain-num"
		sudo chmod 666 "$WFU_HOME/.brain-num"
	fi
	export WFU_BRAIN_NUM
fi
if [ -z "$WFU_BRAIN_NUM_HEX" ]; then
	WFU_BRAIN_NUM_HEX=`printf "%x\n" $WFU_BRAIN_NUM | tr '[:lower:]' '[:upper:]'`
	export WFU_BRAIN_NUM_HEX
fi

# brain id
if [ -z "$WFU_BRAIN_ID_HEX" ]; then
	if [ -f "$WFU_HOME/.brain-id" ]; then
		sudo chmod 666 "$WFU_HOME/.brain-id"
		WFU_BRAIN_ID=`grep -Eo -m 1 "[1-9][0-9]*" "$WFU_HOME/.brain-id"`
	fi
	if [ -z "$WFU_BRAIN_ID" ]; then
		WFU_BRAIN_ID=$RANDOM
		echo $WFU_BRAIN_ID > "$WFU_HOME/.brain-id"
		sudo chmod 666 "$WFU_HOME/.brain-id"
	fi
	
	WFU_BRAIN_ID_HEX=`printf "%x\n" $WFU_BRAIN_ID | tr '[:lower:]' '[:upper:]'`
	export WFU_BRAIN_ID_HEX
fi

# ap channel
WFU_AP_CHANNEL=$(( $WFU_BRAIN_NUM % 2 ))
if [ $WFU_AP_CHANNEL -eq 1 ]; then
	WFU_AP_CHANNEL=11
else
	WFU_AP_CHANNEL=6
fi;
export WFU_AP_CHANNEL

# import shell styles
if [ -z "$STYLE_MARKER" ]; then
	source "$WFU_TOOLS/wfu-shell-styles.sh"
fi
