#!/bin/bash
#===============================================================
# File: wfu-remove-all.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Removes all WFU scripts etc from a system.
#===============================================================
sudo rm -rf /home/pi/src/wfu-tools
sudo rm -f /home/pi/src/wfu-brain-num
sudo rm -f /usr/bin/wfu-*
sudo rm -f /etc/default/udhcpd
sudo rm -f /etc/hostapd/hostapd.conf
sudo rm -f /etc/udhcpd.conf
sudo rm -f /usr/local/etc/serval/serval.conf
sudo rm -f /etc/hostapd/hostapd.conf