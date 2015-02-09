#! /bin/bash
#===============================================================
# File: wfu-update.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Re-clones, rebuilds and re-links local wfu tools.
#===============================================================
cd "$SRC_DIR"

echo -e "${STYLE_HEADING}Updating WFU-tools...${STYLE_NONE}"
if [ -d wfu-tools-old ]; then
	echo -e "  ${STYLE_HEADING}deleting old tools backup...${STYLE_NONE}"
	sudo rm -f -r wfu-tools-old
fi

if [ -d wfu-tools ]; then
	echo -e "  ${STYLE_HEADING}moving existing tools to temporary backup...${STYLE_NONE}"
	sudo mv wfu-tools wfu-tools-old
fi

echo -e "  ${STYLE_HEADING}cloning...${STYLE_NONE}"
git clone --depth 1 -q $WFU_REPOSITORY
if [ -d wfu-tools ]; then
	cd wfu-tools
	sudo rm -f rebuild-rpi-servald.sh
	sudo rm -f rebuild-rpi-kernel.sh
	sudo rm -f record-sdcard-image.sh
	sudo rm -f README.md

	echo -e "  ${STYLE_HEADING}deleting git artefacts...${STYLE_NONE}"
	sudo rm -rf .git
	sudo rm -f .gitattributes
	sudo rm -f .gitignore

	echo -e "  ${STYLE_HEADING}making wfu-setup...${STYLE_NONE}"
	make
	if [ -f wfu-setup ]; then
		echo -e "  ${STYLE_HEADING}recreating symlinks...${STYLE_NONE}"
		sudo chmod 755 *.sh
		sudo chmod 755 wfu-setup
		
		sudo rm -f /usr/bin/wfu-update-wifi
		sudo ln -s "$WFU_TOOLS_DIR/wfu-update-wifi.sh" /usr/bin/wfu-update-wifi
		
		sudo rm -f /usr/bin/wfu-initial-setup
		sudo ln -s "$WFU_TOOLS_DIR/wfu-initial-setup.sh" /usr/bin/wfu-initial-setup

		sudo rm -f /usr/bin/wfu-purge-system
		sudo ln -s "$WFU_TOOLS_DIR/wfu-purge-system.sh" /usr/bin/wfu-purge-system

		sudo rm -f /usr/bin/wfu-update-system
		sudo ln -s "$WFU_TOOLS_DIR/wfu-update-system.sh" /usr/bin/wfu-update-system

		sudo rm -f /usr/bin/wfu-update
		sudo ln -s "$WFU_TOOLS_DIR/wfu-update.sh" /usr/bin/wfu-update

		sudo rm -f /usr/bin/wfu-remove-all
		sudo ln -s "$WFU_TOOLS_DIR/wfu-remove-all.sh" /usr/bin/wfu-remove-all

		sudo rm -f /usr/bin/wfu-preimage-purge
		sudo ln -s "$WFU_TOOLS_DIR/wfu-preimage-purge.sh" /usr/bin/wfu-preimage-purge

		sudo rm -f /usr/bin/wfu-setup
		sudo ln -s "$WFU_TOOLS_DIR/wfu-setup" /usr/bin/wfu-setup
		
		cd ..
		if [ -d wfu-tools-old ]; then
			echo -e "  ${STYLE_HEADING}deleting tools backup...${STYLE_NONE}"
			sudo rm -f -r wfu-tools-old
		fi
		
		echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"
		exit 0
	else
		echo -e "      ${STYLE_ERROR}error! wfu-tools was not built.${STYLE_NONE}"
	fi
else
	echo -e "      ${STYLE_ERROR}error! cloning probably failed.${STYLE_NONE}"
fi

if [ -d wfu-tools-old ]; then

	if [ -d wfu-tools ]; then
		echo -e "  ${STYLE_HEADING}deleting partial version of tools...${STYLE_NONE}"
		sudo rm -f -r wfu-tools
	fi
	
	echo -e "  ${STYLE_HEADING}reverting to backup...${STYLE_NONE}"
	sudo mv wfu-tools-old wfu-tools
fi

echo -e "$  {STYLE_WARNING}finished (with errors).${STYLE_NONE}\n"
