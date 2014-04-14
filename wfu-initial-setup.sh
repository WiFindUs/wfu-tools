#!/bin/bash
#===============================================================
# File: wfu-initial-setup.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Sets up a fresh Rasbian install for use as a wfu-brain unit.
#
# Remarks:
#   This script is intended to be the very next thing
#   you do on a fresh install of Raspbian after cloning
#	wfu-tools to /home/pi/src/wfu-tools.
#===============================================================

if [ -z "$PI_HOME" ]; then
	echo -e "\$PI_HOME not detected. loading scripts and altering .profile..."
	PI_HOME="/home/pi"
	export PI_HOME
	
	cd "$PI_HOME/src/wfu-tools"
	sudo chmod 755 *.sh wfu-setup
	
	IMPORT_SCRIPT="$PI_HOME/src/wfu-tools/wfu-shell-globals.sh"
	if [ -f "$IMPORT_SCRIPT" ]; then
		source "$IMPORT_SCRIPT"
	else
		echo -e "could not find globals for current user. aborting."
		exit 1
	fi
	
	PROFILE_CONFIG="$PI_HOME/.profile"
	HAYSTACK=`cat $PROFILE_CONFIG | grep "#--WFU-INCLUDES"`
	if  [ "$HAYSTACK" == "" ]; then
		echo -e "" >> "$PROFILE_CONFIG"
		echo -e "" >> "$PROFILE_CONFIG"
		echo -e "#--WFU-INCLUDES" >> "$PROFILE_CONFIG"
		echo -e "#do not edit anything below this section; put your additions above it" >> "$PROFILE_CONFIG"
		echo -e "if [ -f \"$IMPORT_SCRIPT\" ]; then" >> "$PROFILE_CONFIG"
		echo -e "	source \"$IMPORT_SCRIPT\"" >> "$PROFILE_CONFIG"
		echo -e "fi" >> "$PROFILE_CONFIG"
		echo -e "" >> "$PROFILE_CONFIG"
	fi
fi

clear
echo -e "${STYLE_TITLE}          WIFINDUS BRAIN INITIAL SETUP          ${STYLE_NONE}"
echo -e "${STYLE_WARNING}NOTE: The unit will be rebooted when this has completed.${STYLE_NONE}\n"
echo -e "${STYLE_HEADING}Just a bit of information from you to start with...${STYLE_NONE}"
NAME=`read_plaintext 'your name'`
EMAIL_ADDRESS=`read_plaintext 'your email address'`
read_number "this unit's ID #" 1 254
ID_NUMBER=$?
PASSWORD=`read_password "a password for the 'pi' user" 6 12`
echo -e "  ${STYLE_INFO}...that's all I need for now. The script will take a few minutes.${STYLE_NONE}\n"

if [ -f "$WFU_TOOLS_DIR/wfu-purge-system.sh"  ]; then
	"$WFU_TOOLS_DIR/wfu-purge-system.sh"
else
	echo -e "${STYLE_ERROR}Could not purge junk; wfu-purge-system.sh missing!...${STYLE_NONE}"
fi

if [ -f "$WFU_TOOLS_DIR/wfu-update-system.sh"  ]; then
	"$WFU_TOOLS_DIR/wfu-update-system.sh"
else
	echo -e "${STYLE_ERROR}Could not update system; wfu-update-system.sh missing!...${STYLE_NONE}"
fi

echo -e "${STYLE_HEADING}Downloading Atheros 9271 firmware...${STYLE_NONE}"
if [ ! -f "/lib/firmware/htc_9271.fw"  ]; then
	cd "/lib/firmware"
	sudo wget -q http://linuxwireless.org/download/htc_fw/1.3/htc_9271.fw
	if [ -f "htc_9271.fw" ]; then
		echo -e "  ${STYLE_SUCCESS}OK!${STYLE_NONE}"
	else
		echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
	fi
else
	echo -e "  ${STYLE_WARNING}already present.${STYLE_NONE}"
fi

echo -e "$\n{STYLE_HEADING}Assembling servald...${STYLE_NONE}"
sudo mkdir -p /usr/local/etc/serval
cd "$SRC_DIR"
if [ -f "/usr/sbin/servald" ]; then
	echo -e "  ${STYLE_WARNING}already present."
	echo -e "  To rebuild, rm /usr/sbin/servald and re-run this script.${STYLE_NONE}"
else
	echo -e "  ${STYLE_HEADING}downloading from wifindus.com...${STYLE_NONE}"
	cd "/usr/sbin"
	sudo wget -q http://www.wifindus.com/downloads/servald
	if [ -f servald ]; then
		sudo chmod 755 servald
		echo -e "    ${STYLE_SUCCESS}downloaded OK!${STYLE_NONE}"
	else
		echo -e "    ${STYLE_ERROR}download failed!${STYLE_NONE}"
		echo -e "  ${STYLE_HEADING}trying to clone from github...${STYLE_NONE}"
		cd "$SRC_DIR"
		git clone --depth 1 -q git://github.com/servalproject/serval-dna.git

		if [ -d serval-dna ]; then
			echo -e "    ${STYLE_HEADING}making... ${STYLE_YELLOW}(may take a while)${STYLE_NONE}"
			cd serval-dna
			autoreconf -f -i  > /dev/null
			./configure  > /dev/null
			make clean -s -k
			make -s -k

			echo -e "    ${STYLE_HEADING}installing...${STYLE_NONE}"
			if [ -f servald ]; then
				sudo mkdir -p /usr/local/var/log/serval
				sudo mkdir -p /usr/local/etc/serval
				killall servald > /dev/null 2>&1
				sudo rm -f /usr/sbin/servald
				make install -s -k
				sudo chmod 755 /usr/sbin/servald
				sudo update-rc.d -f servald remove > /dev/null 2>&1
				sudo update-rc.d -f servald stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1
			else
				echo -e "      ${STYLE_ERROR}error! servald may not have built.${STYLE_NONE}"
			fi
			cd ..
			sudo rm -rf serval-dna
		else
			echo -e "      ${STYLE_ERROR}error! cloning probably failed.${STYLE_NONE}"
		fi
	fi
fi

echo ""
cd "$SRC_DIR"
if [ ! -d wfu-tools ]; then
	echo -e "\n${STYLE_HEADING}Cloning wfu-tools...${STYLE_NONE}"
	git clone --depth 1 -q $WFU_REPOSITORY
fi
if [ -d wfu-tools ]; then
	cd wfu-tools
	sudo rm -rf .git
	sudo rm -f .gitattributes
	sudo rm -f .gitignore
	sudo chmod 755 *.sh
	./wfu-update.sh
	
	echo -e "${STYLE_HEADING}Running wfu-setup...${STYLE_NONE}"
	sudo wfu-setup $ID_NUMBER -q
else
	echo -e "  ${STYLE_ERROR}error! cloning probably failed.${STYLE_NONE}"
fi

echo -e "\n${STYLE_HEADING}Setting Unix password for 'pi'...${STYLE_NONE}"
echo -e "$PASSWORD\n$PASSWORD\n" | sudo passwd pi > /dev/null 2>&1

echo -e "${STYLE_SUCCESS}Finished :)\n${STYLE_YELLOW}The system will reboot in 5 seconds.${STYLE_NONE}"
sleep 5
sudo shutdown -r now > /dev/null
