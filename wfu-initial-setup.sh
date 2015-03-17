#! /bin/bash
#===============================================================
# File: wfu-initial-setup.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Sets up a fresh install for use as a brain unit.
#
# Remarks:
#   This script is intended to be the very next thing
#   you do on a fresh install of linux after cloning
#	wfu-tools to /usr/local/wifindus.
#===============================================================

#===============================================================
# ENVIRONMENT
#===============================================================

if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "could not find globals for current user. aborting."
	exit 1
fi

sudo chown "$CURRENT_USER" "$WFU_HOME"
cd "$WFU_TOOLS"
sudo chmod 777 *.sh

#===============================================================
# INTRO
#===============================================================

clear
echo -e "${STYLE_TITLE}        WIFINDUS BRAIN #$WFU_BRAIN_ID_HEX INITIAL SETUP        ${STYLE_NONE}"
echo -e "${STYLE_HEADING}Current user: ${STYLE_NONE}$CURRENT_USER ($CURRENT_HOME)\n"
echo -e "${STYLE_HEADING}Machine model: ${STYLE_NONE}$MACHINE_MODEL\n"
echo -e "${STYLE_WARNING}NOTE: The unit will be rebooted when this has completed.${STYLE_NONE}\n"
echo -e "${STYLE_HEADING}Just a bit of information from you to start with...${STYLE_NONE}"
read_number "this unit's ID #" 1 254
WFU_BRAIN_NUM=$?
export WFU_BRAIN_NUM
PASSWORD=`read_password "a password for the user '$CURRENT_USER'" 6 12`
echo -e "  ${STYLE_INFO}...that's all I need for now. The script will take a few minutes.${STYLE_NONE}\n"

#===============================================================
# UPDATE APT
#===============================================================

echo -e "${STYLE_HEADING}Updating apt-get database...${STYLE_NONE}"
./wfu-update-apt.sh

#===============================================================
# PURGE PACKAGES
#===============================================================

echo -e "${STYLE_HEADING}Uninstalling unnecessary packages...${STYLE_NONE}"
sudo apt-get -y purge xserver* x11-common x11-utils x11-xkb-utils  \
	wpasupplicant wpagui scratch xpdf idle midori omxplayer netsurf-common \
	pistore debian-reference* libpoppler19 x11-xserver-utils dillo \
	wolfram-engine sonic-pi xarchiver xauth xkb-data console-setup \
	xinit lightdm lxde* obconf openbox gtk* libgtk* alsa* netsurf-gtk \
	libx{composite,cb,cursor,damage,dmcp,ext,font,ft,i,inerama,kbfile,klavier,mu,pm,randr,render,res,t,xf86}* \
	lx{input,menu-data,panel,polkit,randr,session,session-edit,shortcut,task,terminal} \
	scratch tsconf desktop-file-utils babeld libpng* libmtdev1 libjpeg8 \
	poppler* libvorbis* libv41* libsamplerate* \
	penguinspuzzle menu-xdg ^lua* libyaml* libwebp2* libtiff* libsndfile* \
	idle-python* fonts-droid esound-common smbclient ^libraspberrypi-* \
	libsclang* libscsynth* libruby* libwibble* ^vim-* samba-common \
	raspberrypi-artwork gnome-themes-standard-data plymouth netcat-* \
	udhcpd xdg-utils libfreetype* bash-completion ncurses-term wpasupplicant \
	vim-common vim-tiny hostapd

echo -e "${STYLE_HEADING}Removing config-only apt entries...${STYLE_NONE}"
dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs sudo apt-get -y purge

echo -e "${STYLE_HEADING}Deleting GUI/junk files...${STYLE_NONE}"
cd "$CURRENT_HOME"
sudo rm -f ocr_pi.png
sudo rm -f /lib/modules.bak
sudo rm -rf /opt
sudo rm -rf /usr/games/
sudo rm -rf python_games
sudo rm -rf indiecity
sudo rm -rf /etc/X11
sudo rm -rf /var/log/ConsoleKit
sudo rm -rf /etc/polkit-1
sudo rm -rf /usr/lib/xorg
sudo rm -rf /usr/share/icons
sudo rm -rf /usr/share/applications
sudo rm -rf /etc/console-setup
sudo rm -rf /usr/share/man/??
sudo rm -rf /usr/share/man/??_*
sudo rm -rf /usr/share/man/fr.*

#===============================================================
# UPDATE PACKAGES
#===============================================================

echo -e "${STYLE_HEADING}Updating remaining packages...${STYLE_NONE}"
sudo apt-get -f -y install
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

if [ $IS_RASPBERRY_PI -eq 1 ]; then
	echo -e "${STYLE_HEADING}Updating Raspbian...${STYLE_NONE}"
	sudo apt-get -y install rpi-update raspi-config
	sudo apt-get -f -y install
	sudo rpi-update
fi

echo -e "${STYLE_HEADING}Installing packages required by WFU...${STYLE_NONE}"
sudo apt-get -y install build-essential haveged iw git autoconf gpsd \
	secure-delete isc-dhcp-server gpsd-clients crda firmware-realtek \
	firmware-ralink firmware-atheros ntp bc nano psmisc libnl-dev ncurses-dev \
	
#sudo apt-get -y install hostapd
#sudo update-rc.d -f hostapd remove
#sudo update-rc.d -f hostapd stop 80 0 1 2 3 4 5 6 .
sudo update-rc.d -f isc-dhcp-server remove
sudo update-rc.d -f isc-dhcp-server stop 80 0 1 2 3 4 5 6 .
sudo update-rc.d -f gpsd remove
sudo update-rc.d -f gpsd stop 80 0 1 2 3 4 5 6 .

echo -e "${STYLE_HEADING}Cleaning up apt...${STYLE_NONE}"
sudo apt-get -y autoremove
sudo apt-get -y clean
sudo apt-get -y autoclean

#===============================================================
# DOWNLOAD FIRMWARE AND BINARIES
#===============================================================

if [ $IS_RASPBERRY_PI -eq 1 ]; then
	if [ ! -f /lib/firmware/htc_9271.fw ]; then
		echo -e "${STYLE_HEADING}Downloading Atheros 9271 firmware...${STYLE_NONE}"
		sudo wget -O /lib/firmware/htc_9271.fw http://www.wifindus.com/downloads/htc_9271.fw
		if [ ! -f /lib/firmware/htc_9271.fw ]; then
			echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
		fi
	fi

	if [ ! -f /lib/firmware/htc_7010.fw ]; then
		echo -e "${STYLE_HEADING}Downloading Atheros 7010 firmware...${STYLE_NONE}"
		sudo wget -O /lib/firmware/htc_7010.fw http://www.wifindus.com/downloads/htc_7010.fw
		if [ ! -f /lib/firmware/htc_7010.fw ]; then
			echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
		fi
	fi
fi

#===============================================================
# UPDATE TOOLCHAIN
#===============================================================

cd "$WFU_TOOLS"
./wfu-update.sh
cd "$WFU_TOOLS"

#===============================================================
# CONFIGURATION
#===============================================================

if [ $IS_RASPBERRY_PI -eq 1 ]; then
	echo -e "${STYLE_HEADING}Disabling swap..${STYLE_NONE}"
	sudo dphys-swapfile swapoff
	sudo dphys-swapfile uninstall
	sudo update-rc.d dphys-swapfile remove
	sudo apt-get -y remove dphys-swapfile

	echo -e "${STYLE_HEADING}Writing /boot/cmdline.txt...${STYLE_NONE}"
	sudo sh -c 'echo "dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait smsc95xx.turbo_mode=N dwc_otg.microframe_schedule=1" > /boot/cmdline.txt'
fi

HAYSTACK=`cat "/etc/modules" | grep -o -m 1 -E "rt2800usb"`
if [ ! -f "/etc/modules" ] || [ -z "$HAYSTACK" ]; then
	echo -e "${STYLE_HEADING}Writing /etc/modules...${STYLE_NONE}"
	sudo sh -c 'echo "rt2800usb" >> "/etc/modules"'
fi

HAYSTACK=`cat /etc/sysctl.conf | grep -o -m 1 -E "net[.]ipv6[.]conf[.]all[.]disable_ipv6 *= *1"`
if [ -z "$HAYSTACK" ]; then
	echo -e "${STYLE_HEADING}Updating /etc/sysctl.conf...${STYLE_NONE}"
	sudo sh -c 'echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf'
	sudo sh -c 'echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf'
	sudo sh -c 'echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf'
	sudo sh -c 'echo "net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf'
fi

echo -e "${STYLE_HEADING}Running wfu-setup...${STYLE_NONE}"
sudo wfu-setup $WFU_BRAIN_NUM

echo -e "\n${STYLE_HEADING}Setting Unix password for '$CURRENT_USER'...${STYLE_NONE}"
echo -e "$PASSWORD\n$PASSWORD\n" | sudo passwd $CURRENT_USER

#===============================================================
# FINISH
#===============================================================

if [ $IS_RASPBERRY_PI -eq 1 ]; then
	echo -e "${STYLE_HEADING}Launching raspi-config...${STYLE_NONE}"
	sudo raspi-config
fi

echo -e "${STYLE_SUCCESS}Finished :)\n${STYLE_YELLOW}The system will reboot in 5 seconds.${STYLE_NONE}"
sleep 5
sudo shutdown -r now

exit 0