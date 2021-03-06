#! /bin/bash
#===============================================================
# File: record-sdcard-image.sh
# Author: Mark Gillard
# Target environment: Debian PC
# Description:
#   Helper script for recording/zipping new images.
#===============================================================

#===============================================================
# SETTINGS ( you can edit these)
#===============================================================

# input sd card file descriptor
SD_CARD_FD="/dev/sdh"

# path to the parent directory containing the wfu tools repo folder
SRC_DIR="/home/marzer/src"

# how much of the image to record, in megabytes.
#  a good practice is to make this (end_of_last_partition+2MB)
#  e.g. if you shrink your partitions so that the last one
#  ends at 1022MB in, set this to 1024
SIZE_MB=1024

# target family
#  this should match the family types in wfu-shell-globals.sh, e.g.
#  "rpi", "cubox", etc.
DEVICE_FAMILY="rpi"

#===============================================================
# ENVIRONMENT
#===============================================================

IMAGE_NAME="wfu-brain"
IMAGE_VERSION=`date +"%Y%m%d"`
WFU_TOOLS_DIR="${SRC_DIR}/wfu-tools"
OUTPUT_NAME="${IMAGE_NAME}-${IMAGE_VERSION}-${DEVICE_FAMILY}"

if [ -z "$STYLE_MARKER" ] && [ -f "$WFU_TOOLS_DIR/wfu-shell-styles.sh" ]; then
	source "$WFU_TOOLS_DIR/wfu-shell-styles.sh"
fi

#===============================================================
# INTRO
#===============================================================

clear
echo -e "${STYLE_TITLE}          WFU-RASPBIAN IMAGE RECORDER           ${STYLE_NONE}"

echo -e "${STYLE_INFO}Please review your settings:{STYLE_NONE}"
echo -e "${STYLE_HEADING}Input SD card: ${STYLE_NONE}$SD_CARD_FD\n"
echo -e "${STYLE_HEADING}Image size   : ${STYLE_NONE}$SIZE_MB MB\n"
echo -e "${STYLE_HEADING}Device family: ${STYLE_NONE}$DEVICE_FAMILY\n"
echo -e "${STYLE_HEADING}Output name  : ${STYLE_NONE}$OUTPUT_NAME\n"

echo -n -e "  ${STYLE_PROMPT}Are these correct?${STYLE_NONE} "
read -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
   echo -e "  ${STYLE_ERROR}Edit the settings in the script and try again.${STYLE_NONE}"
   exit 1
fi

echo -e "${STYLE_WARNING}This may take a while, go make a coffee! :)${STYLE_NONE}\n"

#===============================================================
# IMAGE RECORDING
#===============================================================

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
echo -e "${STYLE_HEADING}Recording $OUTPUT_NAME.img from $SD_CARD_FD...${STYLE_NONE}"
dd if="$SD_CARD_FD" of="$OUTPUT_NAME.img" bs=1M count=$SIZE_MB

#===============================================================
# ZIP CREATION
#===============================================================

echo -e "${STYLE_HEADING}Creating $OUTPUT_NAME.zip...${STYLE_NONE}"
echo -n "$OUTPUT_NAME.img was generated by $USER at " > image_generated.txt
date +"%c" >> image_generated.txt
rm -f "$OUTPUT_NAME.zip" "$OUTPUT_NAME.zip.md5"
zip -9 -j "$OUTPUT_NAME.zip" "$WFU_TOOLS_DIR/README.md" "$OUTPUT_NAME.img" image_generated.txt
rm -f "$OUTPUT_NAME.img" "image_generated.txt"
md5sum "$OUTPUT_NAME.zip" > "$OUTPUT_NAME.zip.md5"

echo -e "${STYLE_SUCCESS}Finished!${STYLE_NONE}\n"
