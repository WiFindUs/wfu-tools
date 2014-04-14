#!/bin/bash
#===============================================================
# File: wfu-preimage-purge.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Disk operations to make a recorded SD Card image smaller.
#===============================================================

if [ -d "$SRC_DIR/serval-dna" ]; then
	cd "$SRC_DIR/serval-dna"
	ls -A | grep -v -E "servald|directory_service|libmonitorclient\\.(a|so)" | xargs sudo rm -rf
fi

sudo apt-get -qq autoremove
sudo apt-get -qq clean
sudo apt-get -qq autoclean

dpkg -l | grep -o -E "^rc  [a-zA-Z0-9\\.-]+" | grep -o -E "[a-zA-Z0-9\\.-]+$" | tr -s "\n" " " | xargs sudo apt-get -qq purge

sudo rm -rf /var/lib/apt/list
sudo rm -rf /var/cache/apt

sudo sfill -f -ll -z /
sudo swapoff -a
sudo dd if=/dev/zero of=/var/swap bs=1M count=100
sudo swapon -a
sudo rm `find /var/log -type f`