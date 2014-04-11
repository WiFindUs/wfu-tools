#!/bin/sh
#===============================================================
# File: wfu-relink.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Recreates wfu symbolic links and init.d scripts.
#===============================================================
cd "$HOME/src/wfu-tools"

sudo rm -f /etc/init.d/vncboot
sudo cp vncboot /etc/init.d/vncboot
sudo chown root:root /etc/init.d/vncboot
sudo chmod 755 /etc/init.d/vncboot
sudo update-rc.d vncboot defaults > /dev/null 2>&1

sudo rm -f /etc/init.d/servalboot
sudo cp servalboot /etc/init.d/servalboot
sudo chown root:root /etc/init.d/servalboot
sudo chmod 755 /etc/init.d/servalboot
sudo update-rc.d servalboot defaults > /dev/null 2>&1

sudo rm -f /etc/init.d/gpsdboot
sudo cp gpsdboot /etc/init.d/gpsdboot
sudo chown root:root /etc/init.d/gpsdboot
sudo chmod 755 /etc/init.d/gpsdboot
sudo update-rc.d gpsdboot defaults > /dev/null 2>&1

sudo chmod 755 wfu-setup
sudo rm -f /usr/bin/wfu-setup
sudo ln -s "$HOME/src/wfu-tools/wfu-setup" /usr/bin/wfu-setup
