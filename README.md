WFU/Raspbian Tools
==================
A short, sharp and shiny guide on how to get WFU-Raspbian running. The most up-to-date version of this document can always be viewed [here](https://github.com/WiFindUs/wfu-tools).

SD Card Setup - From an image
-----------------------------
1. Get yourself a 4gb SD card. The image is 2gb, though since not all SD cards are the same, you should have a 4GB card in case theres a size difference.  
2. Wipe the card.  
3. Flash [the latest WFU-Raspbian image](http://wifindus.com/downloads/wfu-raspbian.zip) \[[md5](http://wifindus.com/downloads/wfu-raspbian.zip.md5)\].  
    a. optional - Expand the second partition [to fill the rest of the card.](http://www.raspberrypi.org/forums/viewtopic.php?f=51&t=45265)  
4. Ensure the GPS and Wireless dongles are connected to the Pi.  
5. Stick the card in an' turn 'er on.  
6. Connect the Pi's ethernet port to a router or switch with internet connectivity.  
7. Enter the command `wfu-update && sudo wfu-setup <1-254> -r`.  


SD Card Setup - GOING IN DRY
----------------------------
1. Get an SD Card of whatever damn size you like - it just needs to be big enough to cater for Raspbian's many many packages upon installation (~2GB).  
2. Get an up-to date version of [Raspbian](http://downloads.raspberrypi.org/raspbian_latest)  
3. Install it on the SD card as per [the RPi instructions](http://www.raspberrypi.org/documentation/installation/installing-images/README.md)  
    a. optional - Update to the latest kernel by rolling your own from a linux box. Not a simple task, but the included `rebuild-rpi-kernel.sh` should do most of the work for you. If you run into any issues, [these instructions](http://elinux.org/RPi_Kernel_Compilation) should help.  
4. Ensure the GPS and Wireless dongles are connected to the Pi.  
5. Connect the Pi's ethernet port to a router or switch with internet connectivity.  
6. Enter the following commands in the pi's terminal:  
```Shell
	sudo mkdir -p /usr/local/wifindus
	sudo chown $(id -u -n) /usr/local/wifindus
	cd /usr/local/wifindus
	git clone --depth 1 git://github.com/WiFindUs/wfu-tools  
	sudo chmod 755 wfu-tools/*.sh  
	wfu-tools/wfu-initial-setup.sh  
```


Network Addresses and Unit Identity
-----------------------------------
"Brain" node units are assigned a unique ID number between 1 and 254. This is used to determine their logical location on the network according to the following:  
- hostname: `wfu-brain-[num]`  
- mesh0 (mesh backbone interface): `10.1.0.[num]`  
- ap0 (public client interface): `172.16.[num].1`  
- eth0 (wired, for testing only): `192.168.1.[max(100+num,254)]`  
A node's ID number may be changed using the `wfu-setup` command, discussed below.  


CLI commands
------------
There are a few wfu-specific commands available on the command-line:  
- `wfu-update`: updates wfu-tools to the latest from GitHub. Running this usually updates the `wfu-setup` tool so you should re-run it afterwards.
- `wfu-setup`: assigns a node with an ID number and edits system scripts accordingly. Use `-h` for full help. Needs to be run with `sudo`.
- `wfu-initial-setup`: re-runs the initial setup tool.
- `wfu-preimage-purge`: SD-Card cleaning operations to prepare it for imaging - run on the pi prior to the creating a new image.

