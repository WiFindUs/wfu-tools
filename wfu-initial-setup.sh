#! /bin/bash
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

#===============================================================
# ENVIRONMENT
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

#===============================================================
# INTRO
#===============================================================
clear
echo -e "${STYLE_TITLE}          WIFINDUS BRAIN INITIAL SETUP          ${STYLE_NONE}"
echo -e "${STYLE_WARNING}NOTE: The unit will be rebooted when this has completed.${STYLE_NONE}\n"
echo -e "${STYLE_HEADING}Just a bit of information from you to start with...${STYLE_NONE}"
read_number "this unit's ID #" 1 254
WFU_BRAIN_NUM=$?
export WFU_BRAIN_NUM
echo "$WFU_BRAIN_NUM" > "$PI_HOME/wfu-brain-num"
PASSWORD=`read_password "a password for the 'pi' user" 6 12`
echo -e "  ${STYLE_INFO}...that's all I need for now. The script will take a few minutes.${STYLE_NONE}\n"

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
poppler* ^python* parted libvorbis* libv41* libsamplerate* \
penguinspuzzle menu-xdg ^lua* libyaml* libwebp2* libtiff* libsndfile* \
idle-python* fonts-droid esound-common smbclient ^libraspberrypi-* \
libsclang* libscsynth* libruby* libwibble* ^vim-* samba-common \
raspberrypi-artwork gnome-themes-standard-data plymouth netcat-* \
udhcpd xdg-utils libfreetype* bash-completion ncurses-term

echo -e "${STYLE_HEADING}Removing config-only apt entries...${STYLE_NONE}"
dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs sudo apt-get -y purge

echo -e "${STYLE_HEADING}Deleting GUI/junk files...${STYLE_NONE}"
cd "$PI_HOME"
sudo rm -f ocr_pi.png
sudo rm -f /lib/modules.bak
sudo rm -rf /var/lib/apt/list
sudo rm -rf /var/cache/apt
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
echo -e "${STYLE_HEADING}Updating apt-get database...${STYLE_NONE}"
sudo apt-get -y update

echo -e "${STYLE_HEADING}Updating remaining packages...${STYLE_NONE}"
sudo apt-get -y upgrade

echo -e "${STYLE_HEADING}Updating distro...${STYLE_NONE}"
sudo apt-get -y dist-upgrade

echo -e "${STYLE_HEADING}Installing packages required by WFU...${STYLE_NONE}"
sudo apt-get -y install build-essential haveged hostapd iw git autoconf gpsd \
libgps-dev secure-delete isc-dhcp-server gpsd-clients crda firmware-realtek firmware-ralink
sudo update-rc.d -f hostapd remove
sudo update-rc.d -f hostapd stop 80 0 1 2 3 4 5 6 .
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

if [ ! -f "/usr/local/sbin/servald" ]; then
	echo -e "${STYLE_HEADING}Downloading serval daemon...${STYLE_NONE}"
	sudo mkdir -p /usr/local/etc/serval
	sudo mkdir -p /usr/local/var/run/serval
	sudo mkdir -p /usr/local/var/log/serval
	sudo wget -O /usr/local/sbin/servald http://www.wifindus.com/downloads/servald
	if [ ! -f /usr/local/sbin/servald ]; then
		echo -e "  ${STYLE_ERROR}error! probably 404.${STYLE_NONE}"
	fi
fi

if [ ! -d "WFU_TOOLS_DIR" ]; then
	echo -e "\n${STYLE_HEADING}Cloning wfu-tools...${STYLE_NONE}"
	cd "$SRC_DIR"
	git clone --depth 1 $WFU_REPOSITORY
	cd "WFU_TOOLS_DIR"
	sudo rm -rf .git
	sudo rm -f .gitattributes
	sudo rm -f .gitignore
	sudo chmod 755 *.sh
	./wfu-update.sh
fi

#===============================================================
# CONFIGURATION
#===============================================================
echo -e "${STYLE_HEADING}Disabling swap..${STYLE_NONE}"
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo update-rc.d dphys-swapfile remove

echo -e "${STYLE_HEADING}Writing /etc/default/ifplugd...${STYLE_NONE}"
sudo sh -c 'echo "INTERFACES=\"eth0\"" > /etc/default/ifplugd'
sudo sh -c 'echo "HOTPLUG_INTERFACES=\"eth0\"" >> /etc/default/ifplugd'
sudo sh -c 'echo "ARGS=\"-q -f -u0 -d10 -w -I\"" >> /etc/default/ifplugd'
sudo sh -c 'echo "SUSPEND_ACTION=\"stop\"" >> /etc/default/ifplugd'

echo -e "${STYLE_HEADING}Writing /boot/cmdline.txt...${STYLE_NONE}"
sudo sh -c 'echo "dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait smsc95xx.turbo_mode=N dwc_otg.microframe_schedule=1" > /boot/cmdline.txt'

echo -e "${STYLE_HEADING}Writing /etc/modules...${STYLE_NONE}"
sudo sh -c 'echo "rt2800usb" > /etc/modules'

echo -e "${STYLE_HEADING}Writing /etc/modprobe.d/raspi-blacklist.conf...${STYLE_NONE}"
sudo sh -c 'echo "blacklist spi-bcm2708" > /etc/modprobe.d/raspi-blacklist.conf'
sudo sh -c 'echo "blacklist i2c-bcm2708" >> /etc/modprobe.d/raspi-blacklist.conf'
sudo sh -c 'echo "blacklist snd_bcm2835" >> /etc/modprobe.d/raspi-blacklist.conf'

echo -e "${STYLE_HEADING}Writing /etc/default/crda...${STYLE_NONE}"
sudo sh -c 'echo "REGDOMAIN=AU" > /etc/default/crda'

echo -e "${STYLE_HEADING}Writing /etc/modprobe.d/8188eu.conf...${STYLE_NONE}"
sudo sh -c 'echo "options 8188eu rtw_power_mgnt=0 rtw_enusbss=0" > /etc/modprobe.d/8188eu.conf'

echo -e "${STYLE_HEADING}Writing /etc/modprobe.d/8192cu.conf...${STYLE_NONE}"
sudo sh -c 'echo "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0" > /etc/modprobe.d/8192cu.conf'

echo -e "${STYLE_HEADING}Writing /etc/resolv.conf...${STYLE_NONE}"
sudo sh -c 'echo "domain wfu.gateway" > /etc/resolv.conf'
sudo sh -c 'echo "search wfu.gateway" >> /etc/resolv.conf'
sudo sh -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
sudo sh -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

echo -e "${STYLE_HEADING}Running wfu-setup...${STYLE_NONE}"
sudo wfu-setup $WFU_BRAIN_NUM

echo -e "\n${STYLE_HEADING}Setting Unix password for 'pi'...${STYLE_NONE}"
echo -e "$PASSWORD\n$PASSWORD\n" | sudo passwd pi

echo -e "${STYLE_SUCCESS}Finished :)\n${STYLE_YELLOW}The system will reboot in 5 seconds.${STYLE_NONE}"
sleep 5
sudo shutdown -r now
