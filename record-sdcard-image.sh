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
#if it does not exist it will be created
SRC_DIR="/home/marzer/src"

#how much of the image to record, in megabytes
#  a good practice is to make this (end_of_last_partition+2MB)
#  e.g. if you shrink your partitions so that the last one
#  ends at 2048MB in, set this to 2050
SIZE_MB=2050

##### END SETTINGS ####

WFU_TOOLS_DIR="${SRC_DIR}/wfu-tools"

cd "$SRC_DIR"
if [ -z "$STYLE_MARKER" ]; then
	source "$WFU_TOOLS_DIR/wfu-shell-styles.sh"
fi

echo -e "${STYLE_TITLE}          WFU-RASPBIAN IMAGE RECORDER           ${STYLE_NONE}"
echo -e "${STYLE_WARNING}This may take a while, go make a coffee! :)${STYLE_NONE}\n"

cd "$SRC_DIR"
echo -e "${STYLE_HEADING}Recording image...${STYLE_NONE}"
dd if="$SD_CARD_FD" of="$SRC_DIR/wfu-raspbian.img" bs=1M count="$SIZE_MB"

echo -e "${STYLE_HEADING}Creating wfu-raspbian.zip...${STYLE_NONE}"
echo "This WFU-Raspbian image was generated by $USER at " > image_generated.txt
date +"%c" >> image_generated.txt
zip -9 -j wfu-raspbian.zip "$WFU_TOOLS_DIR/README.md" wfu-raspbian.img image_generated.txt
rm -f wfu-raspbian.img
rm -f image_generated.img

echo -e "${STYLE_SUCCESS}Finished!${STYLE_NONE}\n"
