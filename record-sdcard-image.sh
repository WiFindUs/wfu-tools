#!/bin/bash
#===============================================================
# File: record-sdcard-image.sh
# Author: Mark Gillard
# Target environment: Debian/Unix
# Description:
#   Helper script for recording/zipping new images.
#===============================================================
clear

##### SETTINGS ####
# Edit these according to your system's filesystem.
# Descriptions follow.

#sd card file descriptor
SD_CARD_FD="/dev/sdh"

#path to your src directory
SRC="/home/marzer/src"

#path to wfu-tools clone
WFU_TOOLS="${SRC}/wfu-tools"

#how much of the image to record, in megabytes
#  a good practice is to make this (end_of_last_partition+2MB)
#  e.g. if you shrink your partitions so that the last one
#  ends at 2048MB in, set this to 2050
SIZE_MB=2050

##### END SETTINGS ####

STYLE_MARKER="\033["
STYLE_NONE="${STYLE_MARKER}0m"
STYLE_GREEN="${STYLE_MARKER}0;32m"
STYLE_YELLOW="${STYLE_MARKER}0;33m"
STYLE_CYAN="${STYLE_MARKER}0;36m"
STYLE_TITLE="${STYLE_MARKER}1;36m"


echo -e "${STYLE_TITLE}Raspbian Image Recorder"
echo               "=======================${STYLE_NONE}"
echo -e "${STYLE_YELLOW}This may take a while, go make a coffee! :)\n${STYLE_NONE}"

cd "$SRC"
echo -e "${STYLE_CYAN}Recording image...${STYLE_NONE}"
dd if="$SD_CARD_FD" of="$SRC/wfu-raspbian.img" bs=1M count="$SIZE_MB"

echo -e "${STYLE_CYAN}Creating wfu-raspbian.zip...${STYLE_NONE}"
zip -9 -j wfu-raspbian.zip "$WFU_TOOLS/README.md" wfu-raspbian.img
rm -f wfu-raspbian.img

echo -e "${STYLE_GREEN}Finished!${STYLE_NONE}"
