#!/bin/sh

cd /home/pi/src
rm -f -r wfu-tools
git clone -q git://github.com/WiFindUs/wfu-tools.git

cd wfu-tools
rm -f initial_setup.sh
chmod 755 wfu-update.sh
chmod 755 wfu-relink.sh
rm -f /usr/bin/wfu-relink
rm -f /usr/bin/wfu-update
ln -s /home/pi/src/wfu-tools/wfu-relink.sh /usr/bin/wfu-relink
ln -s /home/pi/src/wfu-tools/wfu-update.sh /usr/bin/wfu-update
wfu-relink

make > /dev/null