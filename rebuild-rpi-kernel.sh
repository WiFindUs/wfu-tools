#!/bin/bash
#===============================================================
# File: rpi-build-kernel.sh
# Author: Mark Gillard
# Target environment: Debian/Unix
# Description:
#   Helper script for compiling new kernels.
#
# Remarks:
#   This script is designed to be run on a unix system
#   with the intention of compiling a new kernel for the
#   RaspberryPI.
#
#   DO NOT run it on a Pi! It's only in the wfu-tools
#   repo for convenience.
#===============================================================
clear

##### SETTINGS ####
# Edit these according to your system's filesystem.
# Descriptions follow.

#path to root of locally-mounted SD card with Raspbian
RPI="/media/fc254b57-8fff-4f96-9609-ea202d871acf"

#path to boot partition of locally-mounted SD card with Raspbian
RPI_BOOT="/media/boot"

#path to your src directory
SRC="/home/marzer/src"

#path to linux clone
LINUX="${SRC}/linux"

#path to temp modules to create during linux build
# - this folder will be removed upon completion
MODULES="${SRC}/built_linux_modules"

#path to RasberryPi/tools clone
TOOLS="${SRC}/tools"

#if you've cloned tools and linux properly,
#you shouldn't need to edit any of these
CROSS_COMPILE="${TOOLS}/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin/arm-bcm2708hardfp-linux-gnueabi-"
CORES=`nproc`
ARCH="arm"
KERNEL_OUT="${LINUX}/arch/arm/boot/Image"
##### END SETTINGS ####

STYLE_MARKER="\033["
STYLE_NONE="${STYLE_MARKER}0m"
STYLE_BOLD="${STYLE_MARKER}1m"
STYLE_RED="${STYLE_MARKER}0;31m"
STYLE_IRED="${STYLE_MARKER}0;91m"
STYLE_GREEN="${STYLE_MARKER}0;32m"
STYLE_YELLOW="${STYLE_MARKER}0;33m"
STYLE_CYAN="${STYLE_MARKER}0;36m"
STYLE_TITLE="${STYLE_MARKER}1;36m"

echo -e "${STYLE_TITLE}Raspbian Kernel Rebuilder"
echo              "=========================${STYLE_NONE}"

if [ ! -d "$SRC" ]; then
	echo -e "${STYLE_IRED}Source root doesn't exist.${STYLE_NONE}"
	exit 1
elif [ ! -d "$RPI" ]; then
	echo -e "${STYLE_IRED}RPI mount doesn't exist.${STYLE_NONE}"
	exit 1
elif [ ! -d "$RPI_BOOT" ]; then
	echo -e "${STYLE_IRED}RPI_BOOT mount doesn't exist.${STYLE_NONE}"
	exit 1
elif [ ! -d "$LINUX" ]; then
	echo -e "${STYLE_IRED}Linux clone doesn't exist.${STYLE_NONE}"
	exit 1
elif [ ! -d "$TOOLS" ]; then
	echo -e "${STYLE_IRED}Tools clone doesn't exist.${STYLE_NONE}"
	exit 1
elif [ ! -f "${CROSS_COMPILE}gcc" ] || [ ! -f "${CROSS_COMPILE}g++" ]; then
	echo -e "${STYLE_IRED}Tools not complete.${STYLE_NONE}"
	exit 1
fi

cd "$LINUX"

echo -e "${STYLE_YELLOW}This may take a while, go make a coffee! :)\n${STYLE_NONE}"

echo -e "${STYLE_CYAN}Cleaning build artefacts...${STYLE_NONE}"
make mrproper

echo -e "${STYLE_CYAN}Making config...${STYLE_NONE}"
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE bcmrpi_defconfig -s -k -j$CORES

echo -e "${STYLE_CYAN}Making core...${STYLE_NONE}"
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -s -k -j$CORES

if [ ! -f "$KERNEL_OUT" ]; then
	echo -e "${STYLE_IRED}Build complete, but kernel image file not found.\nCheck the script settings.${STYLE_NONE}"
	exit 1
fi

echo -e "${STYLE_CYAN}Making modules...${STYLE_NONE}"
if [ -d "$MODULES" ]; then
	sudo rm -rf "$MODULES"
	mkdir -p "$MODULES"
fi
make modules_install ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH=$MODULES -s -k -j$CORES

echo -e "${STYLE_CYAN}Preparing kernel...${STYLE_NONE}"
cd "$TOOLS/mkimage"
sudo rm -f kernel.img
./imagetool-uncompressed.py "$KERNEL_OUT"

echo -e "${STYLE_CYAN}Moving kernel to SD card...${STYLE_NONE}"
sudo rm -f "$RPI_BOOT/kernel.img"
sudo mv kernel.img "$RPI_BOOT/"

echo -e "${STYLE_CYAN}Removing old modules and firmware...${STYLE_NONE}"
sudo rm -rf "$RPI/lib/modules"
sudo rm -rf "$RPI/lib/firmware"

echo -e "${STYLE_CYAN}Copying new modules and firmware...${STYLE_NONE}"
cd "$MODULES"
sudo cp -a lib/modules/ "$RPI/lib/"
sudo cp -a lib/firmware/ "$RPI/lib/"
sync

echo -e "${STYLE_GREEN}Finished!\nEject the card and stick it in a RPi.${STYLE_NONE}"
