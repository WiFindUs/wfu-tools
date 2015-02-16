#! /bin/bash
#===============================================================
# File: wfu-update.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Re-clones, rebuilds and re-links local wfu tools.
#===============================================================
# environment
if [ -z "$WFU_HOME" ]; then
	WFU_HOME="/usr/local/wifindus"
	WFU_TOOLS="$WFU_HOME/wfu-tools"
	export WFU_HOME
	export WFU_TOOLS
	
	IMPORT_SCRIPT="$WFU_TOOLS/wfu-shell-globals.sh"
	if [ -f "$IMPORT_SCRIPT" ]; then
		source "$IMPORT_SCRIPT"
	else
		exit 1
	fi
fi
cd "$WFU_HOME"

echo -e "${STYLE_HEADING}Updating WFU-tools...${STYLE_NONE}"
if [ -d wfu-tools-old ]; then
	echo -e "  ${STYLE_HEADING}deleting old tools backup...${STYLE_NONE}"
	sudo rm -rf wfu-tools-old
fi

if [ -d wfu-tools ]; then
	echo -e "  ${STYLE_HEADING}moving existing tools to temporary backup...${STYLE_NONE}"
	sudo mv wfu-tools wfu-tools-old
fi

echo -e "  ${STYLE_HEADING}cloning...${STYLE_NONE}"
git clone --depth 1 -q $WFU_TOOLS_REPO
if [ -d wfu-tools ]; then
	cd wfu-tools
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
		sudo chmod 755 *.sh wfu-setup .bashrc .bash_aliases .profile
		
		sudo rm -f /usr/bin/wfu-initial-setup
		sudo ln -s "$WFU_TOOLS/wfu-initial-setup.sh" /usr/bin/wfu-initial-setup

		sudo rm -f /usr/bin/wfu-update
		sudo ln -s "$WFU_TOOLS/wfu-update.sh" /usr/bin/wfu-update

		sudo rm -f /usr/bin/wfu-preimage-purge
		sudo ln -s "$WFU_TOOLS/wfu-preimage-purge.sh" /usr/bin/wfu-preimage-purge

		sudo rm -f /usr/bin/wfu-setup
		sudo ln -s "$WFU_TOOLS/wfu-setup" /usr/bin/wfu-setup
		
		sudo rm -f /usr/bin/wfu-heartbeat
		sudo ln -s "$WFU_TOOLS/wfu-heartbeat.sh" /usr/bin/wfu-heartbeat
		
		echo -e "  ${STYLE_HEADING}updating .bash scripts...${STYLE_NONE}"
				
		sudo rm -f "$CURRENT_HOME/.bashrc"
		sudo mv -f .bashrc "$CURRENT_HOME"
		
		sudo rm -f "$CURRENT_HOME/.bash_aliases"
		sudo mv -f .bash_aliases "$CURRENT_HOME"
		
		sudo rm -f "$CURRENT_HOME/.profile"
		sudo mv -f .profile "$CURRENT_HOME"
		
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
