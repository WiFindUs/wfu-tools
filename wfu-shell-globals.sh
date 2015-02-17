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

# user globals
if [ -z "$CURRENT_USER" ]; then
	CURRENT_USER=`id -u -n`
	export CURRENT_USER
fi
if [ -z "$CURRENT_HOME" ]; then
	CURRENT_HOME=`eval echo ~$CURRENT_USER`
	export CURRENT_HOME
fi

# machine model
if [ -z "$MACHINE_MODEL" ]; then
	MACHINE_MODEL=`dmesg | grep -i -E "Machine model: .+" | cut -d' ' -f8-`
	export MACHINE_MODEL
fi
if [ -z "$IS_RASPBERRY_PI" ]; then
	IS_RASPBERRY_PI=`echo "$MACHINE_MODEL" | grep -i -o -m 1 "Raspberry"`
	if [ -z "$IS_RASPBERRY_PI" ]; then
		IS_RASPBERRY_PI=0
	else
		IS_RASPBERRY_PI=1
	fi
	export IS_RASPBERRY_PI
fi
if [ -z "$IS_CUBOX" ]; then
	IS_CUBOX=`echo "$MACHINE_MODEL" | grep -i -o -m 1 "Cubox"`
	if [ -z "$IS_CUBOX" ]; then
		IS_CUBOX=0
	else
		IS_CUBOX=1
	fi
	export IS_CUBOX
fi

# brain number
if [ -z "$WFU_BRAIN_NUM" ]; then
	if [ -f "$WFU_HOME/.brain-num" ]; then
		WFU_BRAIN_NUM=`cat $WFU_HOME/.brain-num | grep -E -o -m 1 "([1-2][0-9]{2}|[1-9][0-9]|[1-9])"`
	fi
	if [ -z "$WFU_BRAIN_NUM" ]; then
		WFU_BRAIN_NUM=0
		echo $WFU_BRAIN_NUM > "$WFU_HOME/.brain-num"
	fi
	export WFU_BRAIN_NUM
fi
if [ -z "$WFU_BRAIN_NUM_HEX" ]; then
	WFU_BRAIN_NUM_HEX=`printf "%x\n" $WFU_BRAIN_NUM | tr '[:lower:]' '[:upper:]'`
	export WFU_BRAIN_NUM_HEX
fi

# brain id
if [ -z "$WFU_BRAIN_ID" ]; then
	if [ -f "$WFU_HOME/.brain-id" ]; then
		WFU_BRAIN_ID=`cat $WFU_HOME/.brain-id | grep -E -o -m 1 "[1-9][0-9]*"`
	fi
	if [ -z "$WFU_BRAIN_ID" ]; then
		WFU_BRAIN_ID=$RANDOM
		echo $WFU_BRAIN_ID > "$WFU_HOME/.brain-id"
	fi
	export WFU_BRAIN_ID
fi
if [ -z "$WFU_BRAIN_ID_HEX" ]; then
	WFU_BRAIN_ID_HEX=`printf "%x\n" $WFU_BRAIN_ID | tr '[:lower:]' '[:upper:]'`
	export WFU_BRAIN_ID_HEX
fi

if [ -z "$STYLE_MARKER" ]; then
	source "$WFU_TOOLS/wfu-shell-styles.sh"
fi

unset -f read_plaintext
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

unset -f read_number
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

unset -f read_password
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
