#!/bin/sh
#===============================================================
# File: rpi_build_kernel.sh
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

TitleStyle="\033[1;36m"
Rst="\033[0m"
IRed="\033[0;91m"
Green="\033[0;32m"
Yellow="\033[0;33m"
Cyan="\033[0;36m"

echo "${TitleStyle}Raspbian Kernel Rebuilder"
echo              "=========================${Rst}"

if [ ! -d "$SRC" ]; then
	echo "${IRed}Source root doesn't exist.${Rst}"
	exit 1
elif [ ! -d "$RPI" ]; then
	echo "${IRed}RPI mount doesn't exist.${Rst}"
	exit 1
elif [ ! -d "$RPI_BOOT" ]; then
	echo "${IRed}RPI_BOOT mount doesn't exist.${Rst}"
	exit 1
elif [ ! -d "$LINUX" ]; then
	echo "${IRed}Linux clone doesn't exist.${Rst}"
	exit 1
elif [ ! -d "$TOOLS" ]; then
	echo "${IRed}Tools clone doesn't exist.${Rst}"
	exit 1
elif [ ! -f "${CROSS_COMPILE}gcc" ] || [ ! -f "${CROSS_COMPILE}g++" ]; then
	echo "${IRed}Tools not complete.${Rst}"
	exit 1
fi

cd "$LINUX"

echo "${Yellow}This may take a while, go make a coffee! :)\n${Rst}"

echo "${Cyan}Cleaning build artefacts...${Rst}"
make mrproper

echo "${Cyan}Making config...${Rst}"
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE bcmrpi_defconfig -s -k -j$CORES

echo "${Cyan}Making core...${Rst}"
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -s -k -j$CORES

if [ ! -f "$KERNEL_OUT" ]; then
	echo "${IRed}Build complete, but kernel image file not found.\nCheck the script settings.${Rst}"
	exit 1
fi

echo "${Cyan}Making modules...${Rst}"
if [ -d "$MODULES" ]; then
	sudo rm -rf "$MODULES"
	mkdir -p "$MODULES"
fi
make modules_install ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH=$MODULES -s -k -j$CORES

echo "${Cyan}Preparing kernel...${Rst}"
cd "$TOOLS/mkimage"
sudo rm -f kernel.img
./imagetool-uncompressed.py "$KERNEL_OUT"

echo "${Cyan}Moving kernel to SD card...${Rst}"
sudo rm -f "$RPI_BOOT/kernel.img"
sudo mv kernel.img "$RPI_BOOT/"

echo "${Cyan}Removing old modules and firmware...${Rst}"
sudo rm -rf "$RPI/lib/modules"
sudo rm -rf "$RPI/lib/firmware"

echo "${Cyan}Copying new modules and firmware...${Rst}"
cd "$MODULES"
sudo cp -a lib/modules/ "$RPI/lib/"
sudo cp -a lib/firmware/ "$RPI/lib/"
sync

echo "${Green}Finished!\nEject the card and stick it in a RPi.${Rst}"
