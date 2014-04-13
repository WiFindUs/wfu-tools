#!/bin/sh
#===============================================================
# File: wfu-refresh-wallpapers.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Fetches new id-specific lxde wallpapers from wifindus.com
#===============================================================
SMK="\033["
Rst="${SMK}0m"
Red="${SMK}0;31m"
Green="${SMK}0;32m"
Yellow="${SMK}0;33m"
Cyan="${SMK}0;36m"

cd "$HOME/src"
echo "${Cyan}Fetching wallpapers...${Rst}"
if [ ! -d wfu-brain-wallpapers ]; then
	mkdir -p wfu-brain-wallpapers
fi
cd wfu-brain-wallpapers
echo -n "  [${Red}"
ONE_THIRD=`expr 254 / 3`
TWO_THIRDS=`expr 2 \* 254 / 3`
for i in `seq 1 254`; do
	if [ ! -f wfu-brain-$i.png ]; then
		wget -q http://www.wifindus.com/downloads/wfu-brain-wallpapers/wfu-brain-$i.png
	fi
	
	if [ $i -eq $ONE_THIRD ]; then
		echo -n "${Yellow}"
	elif [ $i -eq $TWO_THIRDS ]; then
		echo -n "${Green}"
	fi
	
	ticker=`expr $i % 5`
	if [ $ticker -eq 0 ]; then
		echo -n "="
	fi
done
echo "${Rst}]"
cd ..

if [ -f "$HOME/src/wfu-brain-num" ]; then
	BRAIN_NUM=`cat "$HOME/src/wfu-brain-num"`
	WALLPAPER_FILE="$HOME/src/wfu-brain-wallpapers/wfu-brain-$BRAIN_NUM.png"
	if [ -f "$WALLPAPER_FILE" ]; then
		sudo -u pi pcmanfm --set-wallpaper "$WALLPAPER_FILE" > /dev/null 2>&1
	fi
fi
