#!/bin/bash
#===============================================================
# File: wfu-purge-system.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Purges a Raspbian system of many unwanted/unnecessary components
#===============================================================

echo -e "${STYLE_CYAN}Purging junk...${STYLE_NONE}"
sudo apt-get -qq purge xserver* x11-common x11-utils x11-xkb-utils x11-xserver-utils \
	wpasupplicant scratch xpdf idle midori omxplayer dillo netsurf-common netsurf-gtk \
	pistore debian-reference-common debian-reference-en libpoppler19 poppler-utils \
	squeek-plugins-scratch wolfram-engine sonic-pi xarchiver xauth xkb-data console-setup \
	xinit lightdm lxde* obconf openbox gtk* libgtk* alsa* \
	libx{composite,cb,cursor,damage,dmcp,ext,font,ft,i,inerama,kbfile,klavier,mu,pm,randr,render,res,t,xf86}* \
	lx{input,menu-data,panel,polkit,randr,session,session-edit,shortcut,task,terminal} \
	python-pygame python-tk python3-tk scratch tsconf desktop-file-utils
		> /dev/null 2>&1
sudo rm -f ocr_pi.png
sudo rm -rf /usr/games/
sudo rm -rf python_games
sudo rm -rf indiecity
sudo rm -rf /etc/X11
sudo rm -rf /usr/share/icons
sudo rm -rf /var/log/ConsoleKit
sudo rm -rf /etc/polkit-1
sudo rm -rf /usr/lib/xorg/modules/linux
sudo rm -rf /usr/lib/xorg/modules/extensions
sudo rm -rf /usr/lib/xorg/modules
sudo rm -rf /usr/lib/xorg

echo -e "${STYLE_CYAN}Removing leftovers...${STYLE_NONE}"
sudo apt-get -qq autoremove > /dev/null 2>&1


