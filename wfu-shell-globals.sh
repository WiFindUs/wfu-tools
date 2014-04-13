#!/bin/bash
#===============================================================
# File: wfu-shell-globals.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Adds some global stuff to the shell environment
#===============================================================

# text formatting markers
STYLE_MARKER="\033["
STYLE_NONE="${STYLE_MARKER}0m"
STYLE_BOLD="${STYLE_MARKER}1m"
STYLE_RED="${STYLE_MARKER}0;31m"
STYLE_IRED="${STYLE_MARKER}0;91m"
STYLE_GREEN="${STYLE_MARKER}0;32m"
STYLE_YELLOW="${STYLE_MARKER}0;33m"
STYLE_CYAN="${STYLE_MARKER}0;36m"
STYLE_TITLE="${STYLE_BOLD}${STYLE_CYAN}"

export STYLE_MARKER
export STYLE_NONE
export STYLE_BOLD
export STYLE_RED
export STYLE_IRED
export STYLE_GREEN
export STYLE_CYAN
export STYLE_YELLOW
export STYLE_TITLE

#needs to go in ~/.profile:
	#PI_HOME="$HOME"
#needs to go in ~root/.profile:
	#PI_HOME="/home/pi"
SSH_DIR="$PI_HOME/.ssh"
SRC_DIR="$PI_HOME/src"
WFU_TOOLS_DIR="$SRC_DIR/wfu-tools"

export SSH_DIR
export SRC_DIR
export WFU_TOOLS_DIR

read_plaintext ()
{
	VALID=0
	VALUE=""
	while [ $VALID -eq 0 ]
	do
		echo -n "  ${STYLE_YELLOW}Enter $1: ${STYLE_NONE}" >&2
		read VALUE
	
		ANSWERED=0
		echo -n "  You entered ${STYLE_YELLOW}$VALUE${STYLE_NONE}." >&2
		while [ $ANSWERED -eq 0 ]
		do
			echo -n "  Correct? (y/N):" >&2
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
	echo -n "  ${STYLE_YELLOW}Enter $1 ($2-$3): ${STYLE_NONE}"
	read VALUE

	while [ $VALUE -lt $2 ] || [ $VALUE -gt $3 ]
	do
		echo "    ${STYLE_RED}outside range!${STYLE_NONE}"
		echo -n "  ${STYLE_YELLOW}Enter $1 ($2-$3): ${STYLE_NONE}"
		read VALUE
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

		while [ "$PASS" = "" ]
		do
			echo -n "  ${STYLE_YELLOW}Enter $1 ($2-$3 chars): ${STYLE_NONE}" >&2
			stty -echo
			read PASS
			stty echo
			echo "" >&2
			PASS=`echo "$PASS" | sed 's/^ *//;s/ *$//'`
		done

		while [ "$SECONDPASS" = "" ]
		do
			echo -n "  ${STYLE_YELLOW}Re-enter password: ${STYLE_NONE}" >&2
			stty -echo
			read SECONDPASS
			stty echo
			echo "" >&2
			SECONDPASS=`echo "$SECONDPASS" | sed 's/^ *//;s/ *$//'`
		done
		
		VALID=1
		if [ "$PASS" != "$SECONDPASS" ]; then
			echo "    ${STYLE_IRED}error! did not match.${STYLE_NONE}" >&2
			VALID=0
		fi

		if [ $VALID -eq 1 ]; then
			LENGTH=`expr length "$PASS"`
			if [ $LENGTH -lt $2 ] || [ $LENGTH -gt $3 ]; then
				echo "    ${STYLE_IRED}outside length range!${STYLE_NONE}" >&2
				VALID=0
			fi
		fi
	done
	echo $PASS
}

export -f read_password