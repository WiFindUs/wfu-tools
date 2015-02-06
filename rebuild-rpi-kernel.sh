#! /bin/bash
#===============================================================
# File: rebuild-rpi-kernel
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

#path to your src directory (where you clone repositories to)
SRC_DIR="$HOME/src"

#the name of the current kernel branch to clone
KERNEL_VER="rpi-3.18.5+"

##### END SETTINGS ####

WFU_TOOLS_DIR="${SRC_DIR}/wfu-tools"
LINUX="${SRC_DIR}/linux"
TOOLS="${SRC_DIR}/tools"
MODULES="${SRC_DIR}/built_linux_modules"
CROSS_COMPILE="${TOOLS}/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin/arm-bcm2708hardfp-linux-gnueabi-"
CORES=`nproc`
ARCH="arm"
KERNEL_OUT="${LINUX}/arch/arm/boot/Image"

cd "$SRC_DIR"
if [ -z "$STYLE_MARKER" ]; then
	source "$WFU_TOOLS_DIR/wfu-shell-styles.sh"
fi

echo -e "${STYLE_TITLE}          WFU-RASPBIAN KERNEL BUILDER           ${STYLE_NONE}"
if [ ! -d "$RPI" ]; then
	echo -e "${STYLE_ERROR}RPI mount doesn't exist.\nedit RPI in the script and try again.${STYLE_NONE}\n"
	exit 1
elif [ ! -d "$RPI_BOOT" ]; then
	echo -e "${STYLE_ERROR}RPI_BOOT mount doesn't exist.\nedit RPI_BOOT in the script and try again.${STYLE_NONE}\n"
	exit 2
fi
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

if [ ! -d "$LINUX" ]; then
	echo -e "${STYLE_HEADING}Cloning rpi/linux...${STYLE_NONE}"
	git clone --depth 1 --branch $KERNEL_VER -q git://github.com/raspberrypi/linux.git
	if [ ! -d "$LINUX" ]; then
		echo -e "  ${STYLE_ERROR}clone not complete. exiting...${STYLE_NONE}"
		exit 4
	fi
fi
	
cd "$LINUX"
echo -e "${STYLE_HEADING}Building Linux...${STYLE_NONE}"

echo -e "  ${STYLE_HEADING}cleaning build artefacts...${STYLE_NONE}"
make mrproper

echo -e "  ${STYLE_HEADING}making config...${STYLE_NONE}"
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE bcmrpi_defconfig -s -k -j$CORES

echo -e "  ${STYLE_HEADING}Making core...${STYLE_NONE}"
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -s -k -j$CORES

if [ ! -f "$KERNEL_OUT" ]; then
	echo -e "    ${STYLE_ERROR}build complete, but kernel image file not found.\ncheck the script settings.${STYLE_NONE}"
	exit 1
fi

echo -e "  ${STYLE_HEADING}making modules...${STYLE_NONE}"
if [ -d "$MODULES" ]; then
	sudo rm -rf "$MODULES"
	mkdir -p "$MODULES"
fi
make modules_install ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH=$MODULES -s -k -j$CORES

echo -e "${STYLE_HEADING}Installing new kernel${STYLE_NONE}"
echo -e "${STYLE_HEADING}  preparing kernel files...${STYLE_NONE}"
cd "$TOOLS/mkimage"
sudo rm -f kernel.img
./imagetool-uncompressed.py "$KERNEL_OUT"

echo -e "${STYLE_HEADING}  moving to SD card...${STYLE_NONE}"
sudo rm -f "$RPI_BOOT/kernel.img"
sudo mv kernel.img "$RPI_BOOT/"

echo -e "${STYLE_HEADING}  removing old modules and firmware...${STYLE_NONE}"
sudo rm -rf "$RPI/lib/modules"
sudo rm -rf "$RPI/lib/firmware"

echo -e "${STYLE_HEADING}  copying new modules and firmware...${STYLE_NONE}"
cd "$MODULES"
sudo cp -a lib/modules/ "$RPI/lib/"
sudo cp -a lib/firmware/ "$RPI/lib/"
sync

echo -e "${STYLE_HEADING}Cleaning up...${STYLE_NONE}"
cd ..
sudo rm -rf "$MODULES"

echo -e "${STYLE_SUCCESS}Finished!\nEject the card and stick it in a RPi.${STYLE_NONE}"
