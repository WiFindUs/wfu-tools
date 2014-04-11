#!/bin/sh
#===============================================================
# File: wfu-update.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Re-clones, rebuilds and re-links local wfu tools.
#===============================================================
cd /home/pi/src
sudo rm -f -r wfu-tools
git clone -q git://github.com/WiFindUs/wfu-tools.git

cd wfu-tools
sudo rm -f rebuild_rpi_kernel.sh
sudo chmod 755 wfu-update.sh
sudo chmod 755 wfu-relink.sh
sudo chmod 755 initial_setup.sh
sudo rm -f /usr/bin/wfu-relink
sudo rm -f /usr/bin/wfu-update
sudo ln -s /home/pi/src/wfu-tools/wfu-relink.sh /usr/bin/wfu-relink
sudo ln -s /home/pi/src/wfu-tools/wfu-update.sh /usr/bin/wfu-update
wfu-relink

make -s -k
