#!/bin/sh
#===============================================================
# File: initial_setup.sh
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

SSH_DIR="$HOME/.ssh"
VNC_DIR="$HOME/.vnc"
SMK="\033["
TitleStyle="${SMK}1;36m"
Rst="${SMK}0m"
IRed="${SMK}0;91m"
Red="${SMK}0;31m"
Green="${SMK}0;32m"
Yellow="${SMK}0;33m"
Cyan="${SMK}0;36m"

read_plaintext ()
{
	VALID=0
	VALUE=""
	while [ $VALID -eq 0 ]
	do
		echo -n "  ${Yellow}Enter $1: ${Rst}" >&2
		read VALUE
	
		ANSWERED=0
		echo -n "  You entered ${Yellow}$VALUE${Rst}." >&2
		while [ $ANSWERED -eq 0 ]
		do
			echo -n "  Correct? (y/N):" >&2
			read ANSWER
			case "$ANSWER" in
				y|Y) VALID=1
				ANSWERED=1
				;;

				n|N) VALID=0
				ANSWERED=1
				;;
		
				*) ;;
			esac
		done
	done
	echo $VALUE
}

read_number ()
{
	echo -n "  ${Yellow}Enter $1 ($2-$3): ${Rst}"
	read VALUE

	while [ $VALUE -lt $2 ] || [ $VALUE -gt $3 ]
	do
		echo "    ${Red}outside range!${Rst}"
		echo -n "  ${Yellow}Enter $1 ($2-$3): ${Rst}"
		read VALUE
	done

	return $VALUE
}

read_password ()
{
	PASS=""
	VALID=0
	while [ $VALID -eq 0 ]
	do
		PASS=""
		SECONDPASS=""

		while [ "$PASS" = "" ]
		do
			echo -n "  ${Yellow}Enter $1 ($2-$3 chars): ${Rst}" >&2
			stty -echo
			read PASS
			stty echo
			echo "" >&2
			PASS=`echo "$PASS" | sed 's/^ *//;s/ *$//'`
		done

		while [ "$SECONDPASS" = "" ]
		do
			echo -n "  ${Yellow}Re-enter password: ${Rst}" >&2
			stty -echo
			read SECONDPASS
			stty echo
			echo "" >&2
			SECONDPASS=`echo "$SECONDPASS" | sed 's/^ *//;s/ *$//'`
		done
		
		VALID=1
		if [ "$PASS" != "$SECONDPASS" ]; then
			echo "    ${IRed}error! did not match.${Rst}" >&2
			VALID=0
		fi

		if [ $VALID -eq 1 ]; then
			LENGTH=`expr length "$PASS"`
			if [ $LENGTH -lt $2 ] || [ $LENGTH -gt $3 ]; then
				echo "    ${IRed}outside length range!${Rst}" >&2
				VALID=0
			fi
		fi
	done
	echo $PASS
}

cd "$HOME"

echo "${TitleStyle}WIFINDUS BRAIN INITIAL SETUP"
echo              "============================${Rst}"
echo "${IRed}You are strongly advised to reboot\nthe unit when this has completed!\n${Rst}"
echo ""
echo "${Cyan}Just a bit of information from you to start with...${Rst}"
NAME=`read_plaintext 'your name'`
EMAIL_ADDRESS=`read_plaintext 'your email address (for github)'`
read_number "this unit's ID #" 1 254
ID_NUMBER=$?
PASSWORD=`read_password "a password for pi, vnc and git" 6 12`
echo "  ${Yellow}...that's all I need for now. The script will take a few minutes.${Rst}"

echo "${Cyan}Purging junk...${Rst}"
sudo rm -rf /usr/games/
sudo rm -rf python_games
sudo rm -rf indiecity
sudo rm -f ocr_pi.png
sudo apt-get -qq purge wpasupplicant scratch xpdf idle midori omxplayer dillo netsurf-common netsurf-gtk pistore debian-reference-common debian-reference-en libpoppler19 poppler-utils squeek-plugins-scratch wolfram-engine sonic-pi > /dev/null 2>&1

echo "${Cyan}Removing leftovers...${Rst}"
sudo apt-get -qq autoremove > /dev/null 2>&1

echo "${Cyan}Updating apt-get list...${Rst}"
sudo apt-get -qq update > /dev/null 2>&1

echo "${Cyan}Upgrading packages...${Rst}"
sudo apt-get -qq upgrade > /dev/null 2>&1

echo "${Cyan}Upgrading distro...${Rst}"
sudo apt-get -qq dist-upgrade > /dev/null 2>&1

echo "${Cyan}Installing apps...${Rst}"
sudo apt-get -qq install haveged hostapd udhcpd iw git autoconf gpsd gpsd-clients tightvncserver > /dev/null 2>&1
sudo update-rc.d -f hostapd remove > /dev/null 2>&1
sudo update-rc.d -f hostapd stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1
sudo update-rc.d -f udhcpd remove > /dev/null 2>&1
sudo update-rc.d -f udhcpd stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1
sudo update-rc.d -f gpsd remove > /dev/null 2>&1
sudo update-rc.d -f gpsd stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1

echo "${Cyan}Cleaning up...${Rst}"
sudo apt-get -qq clean > /dev/null 2>&1
sudo apt-get -qq autoclean > /dev/null 2>&1

echo "${Cyan}Initializing SSH/Git...${Rst}"
git config --global user.name "$NAME" > /dev/null 2>&1
git config --global user.email "$EMAIL_ADDRESS" > /dev/null 2>&1
mkdir -p "$SSH_DIR"
if [ -f "$SSH_DIR/id_rsa" ]; then
	sudo rm -f "$SSH_DIR/id_rsa"
	sudo rm -f "$SSH_DIR/id_rsa.pub"
fi
echo -e "$SSH_DIR/id_rsa\n$PASSWORD\n$PASSWORD" | ssh-keygen -t rsa -C "$EMAIL_ADDRESS" > /dev/null 2>&1
sudo chmod 600 "$SSH_DIR/id_rsa" > /dev/null 2>&1
sudo chmod 600 "$SSH_DIR/id_rsa.pub" > /dev/null 2>&1
eval $(ssh-agent) > /dev/null 2>&1
echo "$PASSWORD" | ssh-add "$SSH_DIR/id_rsa" > /dev/null 2>&1

echo "${Cyan}Creating src dir...${Rst}"
if [ ! -d src ]; then
	mkdir -p src
else
	echo "  ${Yellow}already present.${Rst}"
fi
cd src

echo "${Cyan}Assembling serval-dna...${Rst}"
if [ -d serval-dna ]; then
	echo "  ${Yellow}already present."
	echo "  To rebuild, rm src/serval-dna and re-run this script.${Rst}"
else
	echo "  ${Cyan}cloning...${Rst}"
	git clone -q git://github.com/servalproject/serval-dna.git

	echo "  ${Cyan}making... {Yellow}(may take a while)${Rst}" $
	if [ -d serval-dna ]; then
		cd serval-dna
		autoreconf -f -i  > /dev/null
		./configure  > /dev/null
		make clean -s -k
		make -s -k

		echo "  ${Cyan}creating symlinks...${Rst}"
		if [ -f servald ]; then
			sudo mkdir -p /usr/local/var/log/serval
			sudo mkdir -p /usr/local/etc/serval
			sudo chmod 755 servald
			sudo rm -f /usr/bin/servald
			sudo ln -s "$HOME/src/serval-dna/servald" /usr/bin/servald
			sudo update-rc.d -f servald remove > /dev/null 2>&1
			sudo update-rc.d -f servald stop 80 0 1 2 3 4 5 6 . > /dev/null 2>&1
		else
			echo "    ${IRed}error! servald may not have built.${Rst}"
		fi
		cd ..
	else
		echo "    ${IRed}error! cloning probably failed.${Rst}"
	fi
fi

echo "${Cyan}Fetching Atheros 9271 firmware...${Rst}"
if [ ! -f "/lib/firmware/htc_9271.fw"  ]; then
	cd "/lib/firmware"
	sudo wget -q http://linuxwireless.org/download/htc_fw/1.3/htc_9271.fw
	if [ -f "htc_9271.fw" ]; then
		echo "  ${Green}OK!${Rst}"
	else
		echo "  ${IRed}error! probably 404.${Rst}"
	fi
	cd "$HOME/src"
else
	echo "  ${Yellow}already present.${Rst}"
fi

echo "${Cyan}Fetching wallpapers...${Rst}"
if [ ! -d wfu-brain-wallpapers ]; then
	mkdir -p wfu-brain-wallpapers
fi
cd wfu-brain-wallpapers
echo -n "  [${Red}"
ONE_THIRD=`expr 254 / 3`
TWO_THIRDS=`expr 2 \* 254 / 3`
for i in `seq 1 254`; do
	if [ ! -f wfu-brain-$i.png ]; then
		wget -q http://www.wifindus.com/downloads/wfu-brain-wallpapers/wfu-brain-$i.png
	fi
	
	if [ $i -eq $ONE_THIRD ]; then
		echo -n "${Yellow}"
	elif [ $i -eq $TWO_THIRDS ]; then
		echo -n "${Green}"
	fi
	
	ticker=`expr $i % 5`
	if [ $ticker -eq 0 ]; then
		echo -n "="
	fi
done
echo "${Rst}]"
cd ..

echo "${Cyan}Assembling wfu-tools...${Rst}"
if [ ! -d wfu-tools ]; then
	echo "  ${Cyan}cloning...${Rst}"
	git clone -q git://github.com/WiFindUs/wfu-tools.git
fi

echo "  ${Cyan}making...${Rst}"
if [ -d wfu-tools ]; then
	cd wfu-tools
	git remote set-url origin git@github.com:WiFindUs/wfu-tools.git > /dev/null 2>&1
	sudo chmod 755 wfu-update.sh
	./wfu-update.sh
	sudo wfu-setup $ID_NUMBER -q
	cd ..
else
	echo "    ${IRed}error! cloning probably failed.${Rst}"
fi
cd ..

echo "${Cyan}Setting VNC password...${Rst}"
mkdir -p "$VNC_DIR"
if [ -d "$VNC_DIR" ]; then
	echo "$PASSWORD" | vncpasswd -f > "$VNC_DIR/passwd"
	if [ -f passwd ]; then
		echo "  ${Green}OK!${Rst}"
		killall Xtightvnc > /dev/null 2>&1
		vncserver :1 -geometry 1024x576 > /dev/null 2>&1
	else
		echo "  ${IRed}error! could not create $VNC_DIR/passwd.${Rst}"
	fi
else
	echo "  ${IRed}error! could not create $VNC_DIR.${Rst}"
fi

echo "${Cyan}Setting Unix password (for user 'pi')...${Rst}"
echo -e "$PASSWORD\n$PASSWORD" | sudo passwd pi > /dev/null 2>&1

echo "${Green}Finished :)\n${Yellow}You should reboot now!${Rst}"
