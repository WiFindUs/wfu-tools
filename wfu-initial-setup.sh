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

# root check
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: wfu-initial-setup must be run as root!"
   exit 2
fi

#shell globals
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "ERROR: Could not find globals for current user. aborting."
	exit 1
fi

#read number function
read_number ()
{
	VALUE=""
	while [ -z "$VALUE" ]
	do
		echo -n -e "  ${STYLE_PROMPT}Enter $1 ($2-$3):${STYLE_NONE} "
		read VALUE

		if [ -n "$VALUE" ]; then
			while [ $VALUE -lt $2 ] || [ $VALUE -gt $3 ]
			do
				echo -e "    ${STYLE_ERROR}outside range!${STYLE_NONE}"
				VALUE=""
			done
		fi
	done

	return $VALUE
}

#===============================================================
# INTRO
#===============================================================

clear
echo -e "${STYLE_TITLE}        WIFINDUS BRAIN #$WFU_BRAIN_ID_HEX INITIAL SETUP        ${STYLE_NONE}"
echo -e "${STYLE_HEADING}Machine model: ${STYLE_NONE}$MACHINE_MODEL\n"
echo -e "${STYLE_WARNING}NOTE: The unit will be rebooted when this has completed.${STYLE_NONE}\n"
echo -e "${STYLE_HEADING}Just a bit of information from you to start with...${STYLE_NONE}"
read_number "this unit's ID #" 1 254
WFU_BRAIN_NUM=$?
export WFU_BRAIN_NUM


#===============================================================
# WIFINDUS USER ACCOUNT
#===============================================================

HAS_WFU_USER=`cat /etc/passwd | grep $WFU_USER`
if [ -z "HAS_WFU_USER" ]; then
	echo -e "${STYLE_HEADING}User '$WFU_USER' missing! creating...${STYLE_NONE}\n"
	adduser "$WFU_USER"
	echo "$WFU_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	if [ $IS_RASPBERRY_PI -eq 1 ]; then
		HAS_PI_USER=`cat /etc/passwd | grep pi`
		if [ -n "HAS_PI_USER" ]; then
			echo -e "${STYLE_HEADING}Deleting default user 'pi'...${STYLE_NONE}\n"
			deluser -remove-home pi
		fi
	fi
fi

#===============================================================
# WIFINDUS DIRECTORY
#===============================================================

chown "$WFU_USER" "$WFU_HOME"
cd "$WFU_TOOLS"
chmod 777 *.sh

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
apt-get -y purge xserver* x11-common x11-utils x11-xkb-utils  \
	wpasupplicant wpagui scratch xpdf idle midori netsurf-common \
	debian-reference* libpoppler19 x11-xserver-utils dillo \
	xarchiver xauth xkb-data console-setup \
	xinit lightdm lxde* obconf openbox gtk* libgtk* alsa* netsurf-gtk \
	libx{composite,cb,cursor,damage,dmcp,ext,font,ft,i,inerama,kbfile,klavier,mu,pm,randr,render,res,t,xf86}* \
	lx{input,menu-data,panel,polkit,randr,session,session-edit,shortcut,task,terminal} \
	scratch tsconf desktop-file-utils babeld libpng* libmtdev1 libjpeg8 \
	poppler* libvorbis* libv41* libsamplerate* \
	menu-xdg ^lua* libyaml* libwebp2* libtiff* libsndfile* \
	idle-python* fonts-droid esound-common smbclient \
	libsclang* libscsynth* libruby* libwibble* ^vim-* samba-common \
	 gnome-themes-standard-data plymouth netcat-* \
	udhcpd xdg-utils libfreetype* bash-completion ncurses-term wpasupplicant \
	vim-common vim-tiny
if [ $IS_RASPBERRY_PI -eq 1 ]; then
	apt-get -y purge omxplayer pistore wolfram-engine sonic-pi penguinspuzzle \
	^libraspberrypi-* raspberrypi-artwork
fi 

echo -e "${STYLE_HEADING}Removing config-only apt entries...${STYLE_NONE}"
dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs apt-get -y purge

echo -e "${STYLE_HEADING}Deleting GUI/junk files...${STYLE_NONE}"
rm -f /lib/modules.bak
rm -f /home/pi/ocr_pi.png
rm -rf /opt
rm -rf /usr/games/
rm -rf /home/pi/python_games
rm -rf /home/pi/indiecity
rm -rf /etc/X11
rm -rf /var/log/ConsoleKit
rm -rf /etc/polkit-1
rm -rf /usr/lib/xorg
rm -rf /usr/share/icons
rm -rf /usr/share/applications
rm -rf /etc/console-setup
rm -rf /usr/share/man/??
rm -rf /usr/share/man/??_*
rm -rf /usr/share/man/fr.*

#===============================================================
# UPDATE PACKAGES
#===============================================================

echo -e "${STYLE_HEADING}Updating remaining packages...${STYLE_NONE}"
apt-get -f -y install
apt-get -y upgrade
apt-get -y dist-upgrade

if [ $IS_RASPBERRY_PI -eq 1 ]; then
	echo -e "${STYLE_HEADING}Updating Raspbian...${STYLE_NONE}"
	apt-get -y install rpi-update raspi-config
	apt-get -f -y install
	rpi-update
fi

echo -e "${STYLE_HEADING}Installing packages required by WFU...${STYLE_NONE}"
apt-get -y install build-essential haveged iw git autoconf gpsd \
	secure-delete isc-dhcp-server gpsd-clients crda  \
	firmware-ralink firmware-atheros ntp bc nano psmisc hostapd \
	sshpass
update-rc.d -f hostapd remove
update-rc.d -f hostapd stop 80 0 1 2 3 4 5 6 .
update-rc.d -f isc-dhcp-server remove
update-rc.d -f isc-dhcp-server stop 80 0 1 2 3 4 5 6 .
update-rc.d -f gpsd remove
update-rc.d -f gpsd stop 80 0 1 2 3 4 5 6 .

echo -e "${STYLE_HEADING}Cleaning up apt...${STYLE_NONE}"
apt-get -y autoremove
apt-get -y clean
apt-get -y autoclean

#===============================================================
# DOWNLOAD FIRMWARE AND BINARIES
#===============================================================

if [ ! -f /lib/firmware/htc_9271.fw ]; then
	echo -e "${STYLE_HEADING}Downloading Atheros 9271 firmware...${STYLE_NONE}"
	wget -O /lib/firmware/htc_9271.fw http://www.wifindus.com/downloads/htc_9271.fw
	if [ ! -f /lib/firmware/htc_9271.fw ]; then
		echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
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
	dphys-swapfile swapoff
	dphys-swapfile uninstall
	update-rc.d dphys-swapfile remove
	apt-get -y remove dphys-swapfile

	echo -e "${STYLE_HEADING}Writing /boot/cmdline.txt...${STYLE_NONE}"
	echo "dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait smsc95xx.turbo_mode=N dwc_otg.microframe_schedule=1" > /boot/cmdline.txt
fi

HAYSTACK=`cat "/etc/modules" | grep -o -m 1 -E "rt2800usb"`
if [ ! -f "/etc/modules" ] || [ -z "$HAYSTACK" ]; then
	echo -e "${STYLE_HEADING}Writing /etc/modules...${STYLE_NONE}"
	echo "rt2800usb" >> "/etc/modules"
fi

HAYSTACK=`cat /etc/sysctl.conf | grep -o -m 1 -E "net[.]ipv6[.]conf[.]all[.]disable_ipv6 *= *1"`
if [ -z "$HAYSTACK" ]; then
	echo -e "${STYLE_HEADING}Updating /etc/sysctl.conf...${STYLE_NONE}"
	echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
	echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
	echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
	echo "net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf
fi

echo -e "${STYLE_HEADING}Running wfu-setup...${STYLE_NONE}"
wfu-setup $WFU_BRAIN_NUM

#===============================================================
# FINISH
#===============================================================

if [ $IS_RASPBERRY_PI -eq 1 ]; then
	echo -e "${STYLE_HEADING}Launching raspi-config...${STYLE_NONE}"
	raspi-config
fi

echo -e "${STYLE_SUCCESS}Finished :)\n${STYLE_YELLOW}The system will reboot in 5 seconds.${STYLE_NONE}"
sleep 5
reboot

exit 0