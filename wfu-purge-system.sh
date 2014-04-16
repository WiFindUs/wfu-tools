#!/bin/bash
#===============================================================
# File: wfu-purge-system.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Purges a Raspbian system of many unwanted/unnecessary components
#===============================================================
cd "$PI_HOME"

echo -e "${STYLE_HEADING}Purging system of non-WFU content...${STYLE_NONE}"

if [ ! -d "/var/cache/apt/archives/partial"]; then
	echo -e "  ${STYLE_HEADING}updating apt-get list...${STYLE_NONE}"
	sudo mkdir -p /var/cache/apt/archives/partial
	sudo mkdir -p /var/lib/apt/list/partial
	sudo apt-get -qq update > /dev/null
fi

echo -e "  ${STYLE_HEADING}uninstalling unnecessary Raspbian packages...${STYLE_NONE}"
sudo apt-get -qq purge xserver* x11-common x11-utils x11-xkb-utils  \
wpasupplicant wpagui scratch xpdf idle midori omxplayer netsurf-common \
pistore debian-reference* libpoppler19 x11-xserver-utils dillo \
wolfram-engine sonic-pi xarchiver xauth xkb-data console-setup \
xinit lightdm lxde* obconf openbox gtk* libgtk* alsa* netsurf-gtk \
libx{composite,cb,cursor,damage,dmcp,ext,font,ft,i,inerama,kbfile,klavier,mu,pm,randr,render,res,t,xf86}* \
lx{input,menu-data,panel,polkit,randr,session,session-edit,shortcut,task,terminal} \
scratch tsconf desktop-file-utils babeld libpng* libmtdev1 libjpeg8 \
rpi-update poppler* ^python* parted libvorbis* libv41* libsamplerate* \
penguinspuzzle menu-xdg ^lua* libyaml* libwebp2* libtiff* libsndfile* \
idle-python* fonts-droid esound-common smbclient ^libraspberrypi-* \
libsclang* libscsynth* libruby* libwibble* ^vim-* samba-common \
raspberrypi-artwork gnome-themes-standard-data plymouth \
udhcpd xdg-utils libfreetype* bash-completion ncurses-term \
netcat-* > /dev/null

echo -e "  ${STYLE_HEADING}removing config-only apt entries...${STYLE_NONE}"
dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs sudo apt-get -qq purge > /dev/null
	
echo -e "  ${STYLE_HEADING}cleaning up...${STYLE_NONE}"
sudo apt-get -qq autoremove > /dev/null
sudo apt-get -qq clean > /dev/null
sudo apt-get -qq autoclean > /dev/null

echo -e "  ${STYLE_HEADING}deleting GUI-related files and folders...${STYLE_NONE}"
sudo rm -f ocr_pi.png
sudo rm -f /boot.bak
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

echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"
