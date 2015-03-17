#! /bin/bash
#===============================================================
# File: wfu-install-hostapd.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   Installs a custom-built hostapd.
#===============================================================

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "could not find globals for current user. aborting."
	exit 1
fi

#terminate existing process
HOSTAPD=`pgrep hostapd`
if [ -n "$HOSTAPD" ]; then
	echo "Existing hostapd running, terminating..."
	sudo kill -9 "$HOSTAPD"
fi

#delete existing binaries
sudo rm -f /usr/bin/hostapd /usr/bin/hostapd_cli
sudo rm -f /usr/local/bin/hostapd /usr/local/bin/hostapd_cli

#return home
cd ~

#clone hostapd
PATCH_HOSTAP=0
if [ ! -d "hostap" ]; then
	echo "Cloning hostapd..."
	git clone -v http://w1.fi/hostap.git
	PATCH_HOSTAP=1
fi

#clone rtl patch
if [ ! -d "hostapd-rtl871xdrv" ]; then
	echo "Cloning hostapd-rtl871xdrv patch..."
	git clone -v --depth 1 https://github.com/pritambaral/hostapd-rtl871xdrv.git
fi

#apply patch
if [ $PATCH_HOSTAP -eq 1 ]; then
	echo "Patching with hostapd-rtl871xdrv..."
	cd hostap
	patch -Np1 -i ../hostapd-rtl871xdrv/rtlxdrv.patch
	cd ..
	cp hostapd-rtl871xdrv/driver_rtl.h hostap/src/drivers/driver_rtl.h
	cp hostapd-rtl871xdrv/driver_rtw.c hostap/src/drivers/driver_rtw.c
	cp hostapd-rtl871xdrv/.config hostap/hostapd/.config
	
	sed -i 's/^#CONFIG_DRIVER_HOSTAP=y/CONFIG_DRIVER_HOSTAP=y/g' hostap/hostapd/.config
	sed -i 's/^#CONFIG_DRIVER_NL80211=y/CONFIG_DRIVER_NL80211=y/g' hostap/hostapd/.config
	sed -i 's/^#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/g' hostap/hostapd/.config
	sed -i 's/^#CONFIG_DRIVER_RTW=y/CONFIG_DRIVER_RTW=y/g' hostap/hostapd/.config
	sed -i 's/^#CONFIG_SUPPORT_RTW_DRIVER=y/CONFIG_SUPPORT_RTW_DRIVER=y/g' hostap/hostapd/.config
	sed -i 's/^#CONFIG_NO_STDOUT_DEBUG=y/CONFIG_NO_STDOUT_DEBUG=y/g' hostap/hostapd/.config
fi

#rebuild hostapd
echo "Building hostapd..."
cd hostap/hostapd
make clean
make

#install hostapd binary
echo "Installing hostapd..."
sudo cp hostapd hostapd_cli /usr/bin/

exit 0