#!/bin/sh
#===============================================================
# File: wfu-update.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Re-clones, rebuilds and re-links local wfu tools.
#===============================================================
cd "$HOME/src"
sudo rm -f -r wfu-tools
git clone -q git://github.com/WiFindUs/wfu-tools.git

cd wfu-tools
git remote set-url origin git@github.com:WiFindUs/wfu-tools.git > /dev/null 2>&1
sudo rm -f rebuild_rpi_kernel.sh
sudo chmod 755 wfu-update.sh
sudo chmod 755 wfu-relink.sh
sudo chmod 755 initial_setup.sh
sudo rm -f /usr/bin/wfu-relink
sudo rm -f /usr/bin/wfu-update
sudo ln -s "$HOME/src/wfu-tools/wfu-relink.sh" /usr/bin/wfu-relink
sudo ln -s "$HOME/src/wfu-tools/wfu-update.sh" /usr/bin/wfu-update
wfu-relink

make -s -k
