#!/bin/bash
#===============================================================
# File: wfu-shell-globals.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Adds some global stuff to the shell environment
#===============================================================

PI_HOME="/home/pi"
SRC_DIR="$PI_HOME/src"
WFU_TOOLS_DIR="$SRC_DIR/wfu-tools"
WFU_REPOSITORY="git://github.com/WiFindUs/wfu-tools.git"

export PI_HOME
export SRC_DIR
export WFU_TOOLS_DIR
export WFU_REPOSITORY

if [ -z "$STYLE_MARKER" ]; then
	source "$WFU_TOOLS_DIR/wfu-shell-styles.sh"
fi

read_plaintext ()
{
	VALID=0
	VALUE=""
	while [ $VALID -eq 0 ]
	do
		echo -n -e "  ${STYLE_PROMPT}Enter $1:${STYLE_NONE} " >&2
		read VALUE
	
		ANSWERED=0
		echo -n -e "  ${STYLE_INFO}You entered${STYLE_NONE} $VALUE." >&2
		while [ $ANSWERED -eq 0 ]
		do
			echo -n -e "  ${STYLE_PROMPT}Correct? (y/N):${STYLE_NONE} " >&2
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
	echo -n -e "  ${STYLE_PROMPT}Enter $1 ($2-$3):${STYLE_NONE} "
	read VALUE

	while [ $VALUE -lt $2 ] || [ $VALUE -gt $3 ]
	do
		echo -e "    ${STYLE_ERROR}outside range!${STYLE_NONE}"
		echo -n -e "  ${STYLE_PROMPT}Enter $1 ($2-$3):${STYLE_NONE} "
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
			echo -n -e "  ${STYLE_PROMPT}Enter $1 ($2-$3 chars):${STYLE_NONE} " >&2
			stty -echo
			read PASS
			stty echo
			echo "" >&2
			PASS=`echo "$PASS" | sed 's/^ *//;s/ *$//'`
		done

		while [ "$SECONDPASS" = "" ]
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