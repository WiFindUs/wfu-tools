#!/bin/sh
#===============================================================
# File: wfu-initial-setup.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Sets up a fresh Rasbian install for use as a wfu-brain unit.
#
# Remarks:
#   This script is intended to be the first thing
#   you run on a new build of Raspbian that DOES NOT
#   already have any WFU stuff.
#===============================================================
clear

echo "${STYLE_TITLE}WIFINDUS BRAIN INITIAL SETUP"
echo              "============================${STYLE_NONE}"
echo "${STYLE_IRED}You are strongly advised to reboot\nthe unit when this has completed!\n${STYLE_NONE}"
echo ""
echo "${STYLE_CYAN}Just a bit of information from you to start with...${STYLE_NONE}"
NAME=`read_plaintext 'your name'`
EMAIL_ADDRESS=`read_plaintext 'your email address (for github)'`
read_number "this unit's ID #" 1 254
ID_NUMBER=$?
PASSWORD=`read_password "a password for pi and git" 6 12`
echo "  ${STYLE_YELLOW}...that's all I need for now. The script will take a few minutes.${STYLE_NONE}"

if [ -f "$WFU_TOOLS_DIR/wfu-purge-system.sh"  ]; then
	sudo chmod 755 "$WFU_TOOLS_DIR/wfu-purge-system.sh"
	"$WFU_TOOLS_DIR/wfu-purge-system.sh"
else
	echo "${STYLE_RED}Could not purge junk; wfu-purge-system.sh missing!...${STYLE_NONE}"
fi

if [ -f "$WFU_TOOLS_DIR/wfu-update-system.sh"  ]; then
	sudo chmod 755 "$WFU_TOOLS_DIR/wfu-update-system.sh"
	"$WFU_TOOLS_DIR/wfu-update-system.sh"
else
	echo "${STYLE_RED}Could not update system; wfu-update-system.sh missing!...${STYLE_NONE}"
fi

echo "${STYLE_CYAN}Initializing SSH/Git...${STYLE_NONE}"
git config --global user.name "$NAME" > /dev/null 2>&1
git config --global user.email "$EMAIL_ADDRESS" > /dev/null 2>&1
mkdir -p "$SSH_DIR"
cd "$SSH_DIR"
if [ -f id_rsa ]; then
	sudo rm -f id_rsa
	sudo rm -f id_rsa.pub
fi
echo -e "$SSH_DIR/id_rsa\n$PASSWORD\n$PASSWORD" | ssh-keygen -t rsa -C "$EMAIL_ADDRESS" > /dev/null 2>&1
sudo chmod 600 id_rsa > /dev/null 2>&1
sudo chmod 600 id_rsa.pub > /dev/null 2>&1
eval $(ssh-agent) > /dev/null 2>&1
echo "$PASSWORD" | ssh-add id_rsa > /dev/null 2>&1

echo "${STYLE_CYAN}Downloading Atheros 9271 firmware...${STYLE_NONE}"
if [ ! -f "/lib/firmware/htc_9271.fw"  ]; then
	cd "/lib/firmware"
	sudo wget -q http://linuxwireless.org/download/htc_fw/1.3/htc_9271.fw
	if [ -f "htc_9271.fw" ]; then
		echo "  ${STYLE_GREEN}OK!${STYLE_NONE}"
	else
		echo "  ${STYLE_IRED}error! probably 404.${STYLE_NONE}"
	fi
else
	echo "  ${STYLE_YELLOW}already present.${STYLE_NONE}"
fi

echo "${STYLE_CYAN}Assembling serval-dna...${STYLE_NONE}"
cd "$SRC_DIR"
if [ -d serval-dna ]; then
	echo "  ${STYLE_YELLOW}already present."
	echo "  To rebuild, rm src/serval-dna and re-run this script.${STYLE_NONE}"
else
	echo "  ${STYLE_CYAN}cloning...${STYLE_NONE}"
	git clone -q git://github.com/servalproject/serval-dna.git

	echo "  ${STYLE_CYAN}making... ${STYLE_YELLOW}(may take a while)${STYLE_NONE}"
	if [ -d serval-dna ]; then
		cd serval-dna
		autoreconf -f -i  > /dev/null
		./configure  > /dev/null
		make clean -s -k
		make -s -k

		echo "  ${STYLE_CYAN}creating symlinks...${STYLE_NONE}"
		if [ -f servald ]; then
			sudo mkdir -p /usr/local/var/log/serval
			sudo mkdir -p /usr/local/etc/serval
			sudo chmod 755 servald
			sudo rm -f /usr/bin/servald
			sudo ln -s "$SRC_DIR/serval-dna/servald" /usr/bin/servald
			sudo update-rc.d -f servald remove > /dev/null 2>&1
			sudo update-rc.d -f servald stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1
		else
			echo "    ${STYLE_IRED}error! servald may not have built.${STYLE_NONE}"
		fi
	else
		echo "    ${STYLE_IRED}error! cloning probably failed.${STYLE_NONE}"
	fi
fi

echo "${STYLE_CYAN}Assembling wfu-tools...${STYLE_NONE}"
cd "$SRC_DIR"
if [ ! -d wfu-tools ]; then
	echo "  ${STYLE_CYAN}cloning...${STYLE_NONE}"
	git clone -q git://github.com/WiFindUs/wfu-tools.git
fi
echo "  ${STYLE_CYAN}making...${STYLE_NONE}"
if [ -d wfu-tools ]; then
	cd wfu-tools
	git remote set-url origin git@github.com:WiFindUs/wfu-tools.git > /dev/null 2>&1
	sudo chmod 755 wfu-update.sh
	./wfu-update.sh
	
	echo "${STYLE_CYAN}Running wfu-setup...${STYLE_NONE}"
	sudo wfu-setup $ID_NUMBER -q
else
	echo "    ${STYLE_IRED}error! cloning probably failed.${STYLE_NONE}"
fi

echo "${STYLE_CYAN}Setting Unix passwords for 'pi' and 'root'...${STYLE_NONE}"
echo -e "$PASSWORD\n$PASSWORD" | sudo passwd pi > /dev/null 2>&1
sudo su > /dev/null 2>&1
echo -e "$PASSWORD\n$PASSWORD" | passwd > /dev/null 2>&1
exit

echo "${STYLE_GREEN}Finished :)\n${STYLE_YELLOW}You should reboot now!${STYLE_NONE}"
