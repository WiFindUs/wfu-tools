#!/bin/bash
#===============================================================
# File: wfu-update.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Re-clones, rebuilds and re-links local wfu tools.
#===============================================================
cd "$SRC_DIR"

sudo rm -f -r wfu-tools
git clone -q git://github.com/WiFindUs/wfu-tools.git

cd wfu-tools

git remote set-url origin git@github.com:WiFindUs/wfu-tools.git > /dev/null 2>&1

sudo chmod 755 wfu-initial-setup.sh
sudo chmod 755 wfu-purge-system.sh
sudo chmod 755 wfu-update-system.sh
sudo chmod 755 wfu-update.sh
sudo chmod 755 wfu-shell-globals.sh

sudo rm -f /usr/bin/wfu-initial-setup
sudo ln -s "$WFU_TOOLS_DIR/wfu-initial-setup.sh" /usr/bin/wfu-initial-setup

sudo rm -f /usr/bin/wfu-purge-system
sudo ln -s "$WFU_TOOLS_DIR/wfu-purge-system.sh" /usr/bin/wfu-purge-system

sudo rm -f /usr/bin/wfu-update-system
sudo ln -s "$WFU_TOOLS_DIR/wfu-update-system.sh" /usr/bin/wfu-update-system

sudo rm -f /usr/bin/wfu-update
sudo ln -s "$WFU_TOOLS_DIR/wfu-update.sh" /usr/bin/wfu-update

make -s -k
sudo chmod 755 wfu-setup
sudo rm -f /usr/bin/wfu-setup
sudo ln -s "$WFU_TOOLS_DIR/wfu-setup" /usr/bin/wfu-setup
