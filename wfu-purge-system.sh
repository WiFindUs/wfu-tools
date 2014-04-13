#!/bin/bash
#===============================================================
# File: wfu-purge-system.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Purges a Raspbian system of many unwanted/unnecessary components
#===============================================================
cd "$PI_HOME"

echo -e "${STYLE_CYAN}Purging junk...${STYLE_NONE}"
sudo apt-get -qq purge xserver* x11-common x11-utils x11-xkb-utils x11-xserver-utils \
	wpasupplicant wpagui scratch xpdf idle midori omxplayer dillo netsurf-common netsurf-gtk \
	pistore debian-reference* libpoppler19 \
	wolfram-engine sonic-pi xarchiver xauth xkb-data console-setup \
	xinit lightdm lxde* obconf openbox gtk* libgtk* alsa* \
	libx{composite,cb,cursor,damage,dmcp,ext,font,ft,i,inerama,kbfile,klavier,mu,pm,randr,render,res,t,xf86}* \
	lx{input,menu-data,panel,polkit,randr,session,session-edit,shortcut,task,terminal} \
	scratch tsconf desktop-file-utils babeld \
	rpi-update poppler* ^python* parted libvorbis* libv41* libsamplerate* libpng* libmtdev1 libjpeg8 \
	penguinspuzzle menu-xdg ^lua* libyaml* libwebp2* libtiff* libsndfile* libsclang* libscsynth* libruby* \
	idle-python* fonts-droid esound-common > /dev/null 2>&1
	
echo -e "${STYLE_CYAN}Removing leftovers...${STYLE_NONE}"
sudo apt-get -qq autoremove > /dev/null 2>&1
sudo apt-get -qq clean > /dev/null 2>&1
sudo apt-get -qq autoclean > /dev/null 2>&1
dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs sudo apt-get -qq purge > /dev/null 2>&1

sudo rm -f ocr_pi.png
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