#! /bin/bash
#===============================================================
# File: wfu-update.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Re-clones, rebuilds and re-links local wfu tools.
#===============================================================

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "could not find globals for current user. aborting."
	exit 1
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
		sudo chmod 777 *.sh wfu-setup configs/*
		
		sudo rm -f /usr/bin/wfu-brain-start
		sudo ln -s "$WFU_TOOLS/wfu-brain-start.sh" /usr/bin/wfu-brain-start
		
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
		
		sudo rm -f /usr/bin/wfu-update-apt
		sudo ln -s "$WFU_TOOLS/wfu-update-apt.sh" /usr/bin/wfu-update-apt
		
		echo -e "  ${STYLE_HEADING}updating scripts and configs...${STYLE_NONE}"
				
		sudo rm -f "$CURRENT_HOME/.bashrc"
		sudo mv -f configs/.bashrc "$CURRENT_HOME"
		
		sudo rm -f "$CURRENT_HOME/.bash_aliases"
		sudo mv -f configs/.bash_aliases "$CURRENT_HOME"
		
		sudo rm -f "$CURRENT_HOME/.profile"
		sudo mv -f configs/.profile "$CURRENT_HOME"
		
		sudo rm -f /etc/rc.local
		sudo mv -f configs/rc.local /etc
		
		sudo rm -f /etc/ntp.conf
		sudo mv -f configs/ntp.conf /etc
		
		sudo rm -f /etc/modprobe.d/ipv6.conf /etc/modprobe.d/raspi-blacklist.conf \
			/etc/modprobe.d/8192cu.conf /etc/modprobe.d/8188eu.conf \
			/etc/modprobe.d/wfu-module-options.conf
		sudo mv -f configs/wfu-module-options.conf /etc/modprobe.d
		
		sudo rm -f /etc/resolv.conf
		sudo mv -f configs/resolv.conf /etc
	
		sudo rm -f /etc/default/ifplugd
		sudo mv -f configs/ifplugd /etc/default
		
		sudo rm -f /etc/default/hostapd
		sudo mv -f configs/hostapd /etc/default
		
		sudo rm -f /etc/default/crda
		sudo mv -f configs/crda /etc/default
		
		sudo rm -f /etc/hostapd/hostapd.conf
		sudo mv -f configs/hostapd.conf /etc/hostapd/hostapd.conf
		
		sudo rm -rf configs
		
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
		sudo rm -rf wfu-tools
	fi
	
	echo -e "  ${STYLE_HEADING}reverting to backup...${STYLE_NONE}"
	sudo mv wfu-tools-old wfu-tools
fi

echo -e "$  {STYLE_WARNING}finished (with errors).${STYLE_NONE}\n"
exit 1