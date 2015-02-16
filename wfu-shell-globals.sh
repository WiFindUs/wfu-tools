#! /bin/bash
#===============================================================
# File: wfu-shell-globals.sh
# Author: Mark Gillard
# Target environment: Debian/Raspbian Nodes
# Description:
#   Adds some global stuff to the shell environment
#===============================================================

# user globals
CURRENT_USER=`id -u -n`
CURRENT_HOME=`eval echo ~$CURRENT_USER`

# machine model
MACHINE_MODEL=`dmesg | grep -i -E "Machine model: .+" | cut -d' ' -f8-`
if [ ! -f "$WFU_HOME/.machine-model" ]; then
	echo $MACHINE_MODEL > "$WFU_HOME/.machine-model"
fi

# wfu globals
WFU_HOME="/usr/local/wifindus"
WFU_TOOLS="$WFU_HOME/wfu-tools"
WFU_TOOLS_REPO="git://github.com/WiFindUs/wfu-tools.git"

# brain number
if [ -f "$WFU_HOME/.brain-num" ]; then
	WFU_BRAIN_NUM=`cat $WFU_HOME/.brain-num | grep -E -o -m 1 "([1-2][0-9]{2}|[1-9][0-9]|[1-9])"`
fi
if [ -z "$WFU_BRAIN_NUM" ]; then
	WFU_BRAIN_NUM=0
	echo $WFU_BRAIN_NUM > "$WFU_HOME/.brain-num"
fi

# brain id
if [ -f "$WFU_HOME/.brain-id" ]; then
	WFU_BRAIN_ID=`cat $WFU_HOME/.brain-id | grep -E -o -m 1 "[1-9][0-9]*"`
fi
if [ -z "$WFU_BRAIN_ID" ]; then
	WFU_BRAIN_ID=$RANDOM
	echo $WFU_BRAIN_ID > "$WFU_HOME/.brain-id"
fi
WFU_BRAIN_ID_HEX=`printf "%x\n" $WFU_BRAIN_ID | tr '[:lower:]' '[:upper:]'`

# exports
export CURRENT_USER
export CURRENT_HOME
export MACHINE_MODEL
export WFU_HOME
export WFU_TOOLS
export WFU_TOOLS_REPO
export WFU_BRAIN_NUM
export WFU_BRAIN_NUM_HEX
export WFU_BRAIN_ID
export WFU_BRAIN_ID_HEX


if [ -z "$STYLE_MARKER" ]; then
	source "$WFU_TOOLS/wfu-shell-styles.sh"
fi

read_plaintext ()
{
	VALID=0
	VALUE=""
	while [ $VALID -eq 0 ]
	do
		while [ -z "$VALUE" ]
		do
			echo -n -e "  ${STYLE_PROMPT}Enter $1:${STYLE_NONE} " >&2
			read VALUE
		done
	
		ANSWERED=0
		echo -n -e "  You entered ${STYLE_INFO}$VALUE.${STYLE_NONE}" >&2
		while [ $ANSWERED -eq 0 ]
		do
			echo -n -e "  ${STYLE_PROMPT}Correct? (y/n):${STYLE_NONE} " >&2
			read ANSWER
			case "$ANSWER" in
				y|Y) VALID=1
				ANSWERED=1
				;;

				n|N) VALID=0
				ANSWERED=1
				;;
		
				*) ;;
			esac
		done
	done
	echo $VALUE
}

export -f read_plaintext

read_number ()
{
	VALUE=""
	while [ -z "$VALUE" ]
	do
		echo -n -e "  ${STYLE_PROMPT}Enter $1 ($2-$3):${STYLE_NONE} "
		read VALUE

		if [ -n "$VALUE" ]; then
			while [ $VALUE -lt $2 ] || [ $VALUE -gt $3 ]
			do
				echo -e "    ${STYLE_ERROR}outside range!${STYLE_NONE}"
				VALUE=""
			done
		fi
	done

	return $VALUE
}

export -f read_number

read_password ()
{
	PASS=""
	VALID=0
	while [ $VALID -eq 0 ]
	do
		PASS=""
		SECONDPASS=""

		while [ -z "$PASS" ]
		do
			echo -n -e "  ${STYLE_PROMPT}Enter $1 ($2-$3 chars):${STYLE_NONE} " >&2
			stty -echo
			read PASS
			stty echo
			echo "" >&2
			PASS=`echo "$PASS" | sed 's/^ *//;s/ *$//'`
		done

		while [ -z "$SECONDPASS" ]
		do
			echo -n -e "  ${STYLE_PROMPT}Re-enter password:${STYLE_NONE} " >&2
			stty -echo
			read SECONDPASS
			stty echo
			echo "" >&2
			SECONDPASS=`echo "$SECONDPASS" | sed 's/^ *//;s/ *$//'`
		done
		
		VALID=1
		if [ "$PASS" != "$SECONDPASS" ]; then
			echo -e "    ${STYLE_ERROR}error! did not match.${STYLE_NONE}" >&2
			VALID=0
		fi

		if [ $VALID -eq 1 ]; then
			LENGTH=`expr length "$PASS"`
			if [ $LENGTH -lt $2 ] || [ $LENGTH -gt $3 ]; then
				echo -e "    ${STYLE_ERROR}outside length range!${STYLE_NONE}" >&2
				VALID=0
			fi
		fi
	done
	echo $PASS
}

export -f read_password
