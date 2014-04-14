#!/bin/bash
#===============================================================
# File: rebuild-rpi-servald
# Author: Mark Gillard
# Target environment: Debian/Unix
# Description:
#   Cross compilation of servald exe.
#
# Remarks:
#   This script is designed to be run on a unix system
#   with the intention of compiling a new servald executable for the
#   RaspberryPI.
#
#   DO NOT run it on a Pi! It's only in the wfu-tools
#   repo for convenience.
#===============================================================
clear

##### SETTINGS ####
# Edit these according to your system's filesystem.
# Descriptions follow.

#path to your src directory (where you clone repositories to)
SRC_DIR="$HOME/src"

##### END SETTINGS ####

SERVALD_DIR="${SRC_DIR}/serval-dna"
WFU_TOOLS_DIR="${SRC_DIR}/wfu-tools"
TOOLS="${SRC_DIR}/tools"
CROSS_COMPILE="${TOOLS}/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin/arm-bcm2708hardfp-linux-gnueabi-"
CORES=`nproc`
ARCH="arm"
SERVALD_OUT="${SERVALD_DIR}/servald"

cd "$SRC_DIR"
if [ -z "$STYLE_MARKER" ]; then
	source "$WFU_TOOLS_DIR/wfu-shell-styles.sh"
fi

echo -e "${STYLE_TITLE}          WFU-RASPBIAN SERVALD BUILDER           ${STYLE_NONE}"
echo -e "${STYLE_WARNING}This may take a while, go make a coffee! :)${STYLE_NONE}\n"

if [ ! -d "$TOOLS" ]; then
	echo -e "${STYLE_HEADING}Cloning rpi/tools...${STYLE_NONE}"
	git clone --depth 1 -q git://github.com/raspberrypi/tools.git
	if [ ! -d "$TOOLS" ] || [ ! -f "${CROSS_COMPILE}gcc" ] || [ ! -f "${CROSS_COMPILE}g++" ]; then
		echo -e "  ${STYLE_ERROR}clone not complete. exiting...${STYLE_NONE}"
		exit 3
	fi
elif [ ! -f "${CROSS_COMPILE}gcc" ] || [ ! -f "${CROSS_COMPILE}g++" ]; then
	echo -e "  ${STYLE_ERROR}clone not complete. exiting...${STYLE_NONE}"
	exit 3
fi

if [ ! -d "$SERVALD_DIR" ]; then
	echo -e "${STYLE_HEADING}Cloning serval-dna...${STYLE_NONE}"
	git clone --depth 1 -q git://github.com/servalproject/serval-dna.git
	if [ ! -d "$SERVALD_DIR" ]; then
		echo -e "  ${STYLE_ERROR}clone not complete. exiting...${STYLE_NONE}"
		exit 4
	fi
fi
	
cd "$SERVALD_DIR"
echo -e "${STYLE_HEADING}Building servald...${STYLE_NONE}"

echo -e "  ${STYLE_HEADING}autoreconf...${STYLE_NONE}"
autoreconf -f -i > /dev/null
	
echo -e "  ${STYLE_HEADING}.configure...${STYLE_NONE}"
./configure > /dev/null

echo -e "  ${STYLE_HEADING}cleaning build artefacts...${STYLE_NONE}"
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean -s -k -j$CORES

echo -e "  ${STYLE_HEADING}making...${STYLE_NONE}"
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -s -k -j$CORES

if [ ! -f "$SERVALD_OUT" ]; then
	echo -e "    ${STYLE_ERROR}build complete, but servald executable not found.\ncheck the script settings.${STYLE_NONE}"
	exit 1
fi

echo -e "  ${STYLE_HEADING}moving to $SRC_DIR...${STYLE_NONE}"
sudo chmod 755 $SERVALD_OUT
sudo mv $SERVALD_OUT "$SRC_DIR/"

echo -e "${STYLE_SUCCESS}Finished!${STYLE_NONE}"
