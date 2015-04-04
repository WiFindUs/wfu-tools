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
	echo "ERROR: Could not find globals for current user. aborting." 1>&2
	exit 1
fi

if [ -f "/usr/local/wifindus/.update-lock" ]; then
	echo "ERROR: wfu-update already in progress. aborting." 1>&2
	exit 2
fi

echo -e "WARNING: wfu-update has started on wfu-brain-$WFU_BRAIN_NUM.\nDo not reboot the system!" | sudo wall -n

cd "$WFU_HOME"
echo "lock" > "/usr/local/wifindus/.update-lock"

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
		
		for FILE in $WFU_TOOLS/*.sh; do
			FILE_NAME="${FILE##*/}"
			FILE_NAME_SANS_EXT=`echo "$FILE_NAME" | cut -d. -f1`
			sudo rm -f "/usr/bin/$FILE_NAME_SANS_EXT"
			sudo ln -s "$FILE" "/usr/bin/$FILE_NAME_SANS_EXT"
		done
		
		echo -e "  ${STYLE_HEADING}updating scripts and configs...${STYLE_NONE}"
				
		sudo rm -f "$WFU_USER_HOME/.bashrc"
		sudo mv -f configs/.bashrc "$WFU_USER_HOME"
		
		sudo rm -f "$WFU_USER_HOME/.bash_aliases"
		sudo mv -f configs/.bash_aliases "$WFU_USER_HOME"
		
		sudo rm -f "$WFU_USER_HOME/.profile"
		sudo mv -f configs/.profile "$WFU_USER_HOME"
		
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
		
		#remove this eventually
		if [ -f /etc/ssh/sshd_config ]; then
			sudo sed -i 's/PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config
			sudo sed -i 's/PrintMotd yes/PrintMotd no/' /etc/ssh/sshd_config
		fi
		rm -f /etc/motd
		if [ ! -f /etc/profile ]; then
			sudo sh -c 'echo "TZ='Australia/Adelaide'; export TZ" > /etc/profile'
			sudo sh -c 'echo "LC_ALL='C'; export LC_ALL" >> /etc/profile'
		else
			NEEDLE=`grep "export TZ" "/etc/profile"`
			if [ -z "$NEEDLE" ]; then
				sudo sh -c 'echo "TZ='Australia/Adelaide'; export TZ" >> /etc/profile'
			fi
			NEEDLE=`grep "LC_ALL" "/etc/profile"`
			if [ -z "$NEEDLE" ]; then
				sudo sh -c 'echo "LC_ALL='C'; export LC_ALL" >> /etc/profile'
			fi
		fi
			
		
		echo -e -n "  ${STYLE_HEADING}updating version number...${STYLE_NONE} "
		
		sudo rm -f "$WFU_HOME/.version"
		sudo mv -f "configs/.version" "$WFU_HOME/.version"
		if [ -f "$WFU_HOME/.version" ]; then
			WFU_VERSION=`grep -Eo -m 1 "[0-9]+" "$WFU_HOME/.version"`
			if [ -z "$WFU_VERSION" ]; then
				WFU_VERSION=20141231
				echo $WFU_VERSION > "$WFU_HOME/.version"
				sudo chmod 666 "$WFU_HOME/.version"
			fi
		fi
		export WFU_VERSION
		echo $WFU_VERSION
		
		echo -e -n "  ${STYLE_HEADING}recording update timestamp...${STYLE_NONE} "
		
		LAST_UPDATE_TIME=`date +"%Y-%m-%d %H:%M:%S"`
		echo $LAST_UPDATE_TIME > "../.last-update"
		sudo chmod 666 "../.last-update"
		export LAST_UPDATE_TIME
		echo $LAST_UPDATE_TIME
		
		echo -e "  ${STYLE_HEADING}cleaning up wfu-tools...${STYLE_NONE}"
		
		sudo rm -rf configs
		sudo rm -rf ".git"
		sudo rm -f ".git*"
		
		cd ..
		if [ -d wfu-tools-old ]; then
			echo -e "  ${STYLE_HEADING}deleting tools backup...${STYLE_NONE}"
			sudo rm -f -r wfu-tools-old
		fi
		
		echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"
		
		if [[ $1 =~ ^reboot$ ]]; then
			sleep 5
			sudo reboot
		fi
		sudo rm -f "/usr/local/wifindus/.update-lock"
		echo "wfu-update has finished on wfu-brain-$WFU_BRAIN_NUM." | sudo wall -n
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
sudo rm -f "/usr/local/wifindus/.update-lock"
echo "wfu-update has finished on wfu-brain-$WFU_BRAIN_NUM." | sudo wall -n
exit 3