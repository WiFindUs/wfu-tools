#! /bin/bash
#===============================================================
# File: wfu-brain-start.sh
# Author: Mark Gillard
# Target environment: Nodes
# Description:
#   (Re)starts the brain node stuff.
#===============================================================

# root check
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: wfu-brain-start must be run as root!"
   exit 2
fi

# environment
if [ -f "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh" ]; then
	source "/usr/local/wifindus/wfu-tools/wfu-shell-globals.sh"
else
	echo "could not find globals for current user. aborting."
	exit 1
fi

#############################################################
### Logging
#############################################################

rm -f $WFU_HOME/*.log
exec > "$WFU_HOME/rc.local.log" 2>&1
#exec 1>&2
#set -x
DMESG=`dmesg 2>&1`
echo -e "$DMESG" > "$WFU_HOME/dmesg_boot.log"
LSUSB=`lsusb 2>&1`
echo -e "$LSUSB" > "$WFU_HOME/lsusb_boot.log"
LSMOD=`lsmod 2>&1`
echo -e "$LSMOD" > "$WFU_HOME/lsmod_boot.log"

#############################################################
### Kill existing daemons
#############################################################

HEARTBEAT=`pgrep wfu-heartbeat`
if [ -n "$HEARTBEAT" ]; then
	echo "Existing wfu-heartbeat running, terminating..."
	kill -9 "$HEARTBEAT"
fi

GPSD=`pgrep gpsd`
if [ -n "$GPSD" ]; then
	echo "Existing gpsd running, terminating..."
	kill -9 "$GPSD"
fi

DHCPD=`pgrep dhcpd`
if [ -n "$DHCPD" ]; then
	echo "Existing dhcpd running, terminating..."
	kill -9 "$DHCPD"
fi

HOSTAPD=`pgrep hostapd`
if [ -n "$HOSTAPD" ]; then
	echo "Existing hostapd running, terminating..."
	kill -9 "$HOSTAPD"
fi

if [ -n "$HEARTBEAT" ] || [ -n "$GPSD" ] || [ -n "$DHCPD" ] || [ -n "$HOSTAPD" ]; then
	sleep 5
fi

#############################################################
### Mesh and AP
#############################################################

echo "Checking existing wireless interfaces..."
WLANS="wlan0 wlan1 wlan2 wlan3 ra0 ra1 ra2 ra3"
for WLAN in $WLANS; do
	WLAN_IFACE=`iwconfig 2>&1 | grep -o -i -m 1 "$WLAN"`
	if [ -n "$WLAN_IFACE" ]; then
		echo "$WLAN_IFACE detected, attempting to remove..."
		ifconfig "$WLAN_IFACE" down
		sleep 1
		iw dev "$WLAN_IFACE" del
		WLAN_IFACE=`iwconfig 2>&1 | grep -o -i -m 1 "$WLAN"`
		if [ -n "$WLAN_IFACE" ]; then
			echo "WARNING: $WLAN could not be removed, possibly not nl80211-compatible..."
		else
			echo "$WLAN removed OK."
		fi
	fi
done

MESH_0=`iwconfig 2>&1 | grep -o -i -m 1 "mesh0"`
if [ -z "$MESH_0" ]; then
	echo "Checking for iw-supported mesh adapter..."
	MESH_PHY_INFO=`echo -e $DMESG | grep -E -i -o -m 1 "phy[0-9]+: Atheros AR9271"`
	if [ -n "$MESH_PHY_INFO" ]; then
		MESH_ADAPTER="Atheros AR9271"
	fi

	if [ -n "$MESH_PHY_INFO" ]; then
		MESH_PHY=`echo -e "$MESH_PHY_INFO" | grep -E -i -o -m 1 "phy[0-9]+"`
		echo "$MESH_ADAPTER detected ($MESH_PHY)."
	else
		echo "ERROR: no supported mesh adapters detected."
	fi
else
	echo "Bringing $MESH_0 down..."
	ifconfig $MESH_0 down
fi

AP_0=`iwconfig 2>&1 | grep -o -i -m 1 "ap0"`
if [ -z "$AP_0" ]; then
	echo "Checking for iw-supported AP adapter..."
	AP_PHY_INFO=`echo -e $DMESG | grep -E -i -o -m 1 "phy[0-9]+: rt2x00_set_rf: Info - RF chipset 5370(, rev [0-9]+)? detected"`
	if [ -n "$AP_PHY_INFO" ]; then
		AP_ADAPTER="Ralink RT5370"
	fi

	if [ -z "$AP_PHY_INFO" ]; then
		AP_PHY_INFO=`echo -e $DMESG | grep -E -i -o -m 1 "phy[0-9]+: rt2x00_set_rt: Info - RT chipset 5592(, rev [0-9]+)? detected"`
		if [ -n "$AP_PHY_INFO" ]; then
			AP_ADAPTER="Ralink RT5572"
		fi
	fi

	if [ -n "$AP_PHY_INFO" ]; then
		AP_PHY=`echo -e "$AP_PHY_INFO" | grep -E -i -o -m 1 "phy[0-9]+"`
		echo "$AP_ADAPTER detected ($AP_PHY)."
	else
		echo "ERROR: no supported AP adapters detected."
		if [ -n "$MESH_PHY" ]; then
			echo "FALLBACK: Will use $MESH_PHY for both interfaces."
			AP_PHY="$MESH_PHY"
			AP_ADAPTER="$MESH_ADAPTER"
		fi
	fi
else
	echo "Bringing $AP_0 down..."
	ifconfig $AP_0 down
fi

if [ -n "$MESH_0" ] || [ -n "$AP_0" ]; then
	sleep 1
fi

echo "Setting regulatory domain..."
iw reg set AU

if [ -z "$MESH_0" ] && [ -n "$MESH_PHY" ]; then
	MESH_0="mesh0"
	echo "Creating $MESH_0 interface on $MESH_PHY..."
	iw phy $MESH_PHY interface add $MESH_0 type mp mesh_id wifindus_mesh
	MESH_0=`iwconfig 2>&1 | grep -o -i -m 1 "$MESH_0"`
	if [ -n "$MESH_0" ]; then
		ip link set dev $MESH_0 address 50:50:50:50:50:$WFU_BRAIN_NUM_HEX
	fi
fi

if [ -z "$AP_0" ] && [ -n "$AP_PHY" ]; then #iw-compat
	AP_0="ap0"
	echo "Creating $AP_0 interface on $AP_PHY..."
	iw phy $AP_PHY interface add $AP_0 type managed
	AP_0=`iwconfig 2>&1 | grep -o -i -m 1 "$AP_0"`
	if [ -n "$AP_0" ]; then
		ip link set dev $AP_0 address 60:60:60:60:60:$WFU_BRAIN_NUM_HEX
	fi
fi

if [ -n "$MESH_0" ]; then
	echo "Bringing $MESH_0 up..."
	ifconfig $MESH_0 up
	ifconfig $MESH_0 10.1.0.$WFU_BRAIN_NUM
fi

if [ -n "$AP_0" ]; then
	echo "Bringing $AP_0 up..."
	ifconfig $AP_0 up
	ifconfig $AP_0 172.16.$WFU_BRAIN_NUM.1
	ifconfig $AP_0 netmask 255.255.255.0
fi

#############################################################
### Daemons
#############################################################

echo "Checking for supported GPS module..."
GPS_MODULE=`echo -e "$LSUSB" | grep -i -o "0e8d:3329"`
if [ -n "$GPS_MODULE" ]; then
	echo "MediaTek MT3329 detected ($GPS_MODULE). Looking for serial stream..."
	GPS_STREAM=`echo -e "$DMESG" | grep -E -i -o "ttyACM[0-9]+"`
	if [ -n "$GPS_STREAM" ]; then
		#launch new gpsd instance
		GPS_STREAM="/dev/$GPS_STREAM"
		echo "GPS serial stream detected ($GPS_STREAM). Starting gpsd..."
		gpsd -n "$GPS_STREAM" -F /var/run/gpsd.sock
		
		#restart ntpd service
		GPSD=`pgrep gpsd`
		if [ -n "$GPSD" ]; then
			echo "Started gpsd OK. Restarting ntpd..."
			/etc/init.d/ntp restart
		else
			echo "ERROR: gpsd did not start properly. Dongle faulty?"
		fi
		
	else
		echo "ERROR: No serial stream detected. Perhaps update firmware or drivers?"
	fi
else
	echo "ERROR: no supported GPS receiver detected."
fi

if [ -n "$AP_0" ]; then
	#update hostapd settings
	sudo sed -i -r "s/^channel=[0-9]+/channel=$WFU_AP_CHANNEL/g" /etc/hostapd/hostapd.conf
	sudo sed -i -r "s/^interface=[a-z0-9]+/interface=$AP_0/g" /etc/hostapd/hostapd.conf
	
	#launch new hostapd instance
	echo "Starting hostapd..."
	hostapd -B /etc/hostapd/hostapd.conf
	
	#launch new dhcpd instance if hostapd is running ok
	HOSTAPD=`pgrep hostapd`
	if [ -n "$HOSTAPD" ]; then
		#handle settings
		sudo rm -f /etc/default/isc-dhcp-server
		echo -e "INTERFACES=\"$AP_0\"\n" > /etc/default/isc-dhcp-server
	
		#launch daemon
		echo "Started hostapd OK. Starting dhcpd..."
		dhcpd -4 -q
	else
		echo "ERROR: hostapd not running! Skipping dhcpd."
	fi
fi

#############################################################
### Routing
#############################################################

echo "Configuring default gateway route..."
if [ $WFU_BRAIN_NUM -eq 1 ] || [ -z "$MESH_0" ]; then
	ip route add 0.0.0.0/0 via 192.168.1.254 dev eth0
else
	ip route del 192.168.1.0/24 dev eth0
	ip route add 0.0.0.0/0 via 10.1.0.1 dev $MESH_0
fi

if [ -n "$MESH_0" ]; then
	echo "Configuring mesh node routes..."
	COUNTER=1
	while true; do
		if [ $COUNTER -ne $WFU_BRAIN_NUM ]; then
			ip route add 172.16.$COUNTER.0/24 via 10.1.0.$COUNTER dev $MESH_0
		fi
		COUNTER=`expr $COUNTER + 1`
		if [ $COUNTER -ge 255 ]; then
			break
		fi
	done
fi

#############################################################
### NAT
#############################################################

echo 1 > /proc/sys/net/ipv4/ip_forward
echo "Clearing ip tables..."
iptables -F
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo "Adding firewall rules..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -j ACCEPT -m state --state ESTABLISHED,RELATED
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --sport 9418 -m state --state NEW -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -p udp --dport 33339:33340 -j ACCEPT
iptables -A INPUT -p udp --dport 123 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#############################################################
### Heartbeat
#############################################################

echo "Launching heartbeat packet process..."
if [ $WFU_BRAIN_NUM -eq 1 ] || [ -n "$MESH_0" ]; then
	wfu-heartbeat -1 &
else
	echo "ERROR: heartbeat sends only when brain number == 1 OR mesh0 is present."
fi

exit 0

