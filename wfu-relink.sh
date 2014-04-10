#!/bin/sh

cd /home/pi/src/wfu-tools

rm -f /etc/init.d/vncboot
cp vncboot /etc/init.d/vncboot
chown root:root /etc/init.d/vncboot
chmod 755 /etc/init.d/vncboot
update-rc.d vncboot defaults

rm -f /etc/init.d/servalboot
cp servalboot /etc/init.d/servalboot
chown root:root /etc/init.d/servalboot
chmod 755 /etc/init.d/servalboot
update-rc.d servalboot defaults

rm -f /etc/init.d/gpsdboot
cp gpsdboot /etc/init.d/gpsdboot
chown root:root /etc/init.d/gpsdboot
chmod 755 /etc/init.d/gpsdboot
update-rc.d gpsdboot defaults

chmod 755 wfu-setup
rm -f /usr/bin/wfu-setup
ln -s /home/pi/src/wfu-tools/wfu-setup /usr/bin/wfu-setup