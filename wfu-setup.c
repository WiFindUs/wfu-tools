//===============================================================
// File: wfu-setup.c
// Author: Mark Gillard
// Target environment: Raspbian
// Description:
//   Sets the PI unit up according to it's ID number (1-254).
//===============================================================
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef NULL
#define NULL 0
#endif

#define VERSION_STR "v1.3.1" 
#define SRC_DIR "/home/pi" 

#define SERVALD_FLAG 1
#define DHCPD_FLAG 2
#define HOSTAPD_FLAG 4
#define GPSD_FLAG 8
#define ALL_FLAGS 15

int quietMode = FALSE;
int noWireless = FALSE;
int adhocMode = FALSE;
int daemon_flags = DHCPD_FLAG | HOSTAPD_FLAG | GPSD_FLAG;
int apChannel = 0;
char sbuf[256], nbuf[256], opString[50];
char hex[3];

int min(int a, int b)
{
	if (a < b)
		return a;
	return b;
}

int dtoh(int decimal, char* hex)
{
	int i = 0, j = 0, remainders[30], length = 0;
	while(decimal > 0)
	{
		remainders[i++] = decimal%16;
		decimal=decimal/16;
		length++;
	}
	
	for(i = length-1; i >= 0; i--)
		hex[j++]= remainders[i] >= 10 ? (char)(((int)'A')+(remainders[i]-10)) : (char)(((int)'0')+remainders[i]);
	hex[length] = '\0';
}

void print_usage(char * argv0)
{
	if (quietMode)
		return;
	
	fprintf(stderr, "Usage: %s [options] [1-254]\n",argv0);
	fprintf(stderr, "Options:\n");
	fprintf(stderr, "  -r or --reboot: auto reboot after completion.\n");
	fprintf(stderr, "  -s or --shutdown: auto halt after completion.\n");
	fprintf(stderr, "  -h or --help: print full description only.\n");
	fprintf(stderr, "  -q or --quiet: quiet mode (no text output).\n");
	fprintf(stderr, "  -a or --adhoc: use ad-hoc mode instead of mesh-point.\n");
	fprintf(stderr, "  -S or --servald: enable serval auto-start.\n");
	fprintf(stderr, "  -D or --nodhcpd: disable dhcpd auto-start.\n");
	fprintf(stderr, "  -H or --nohostapd: disable hostapd auto-start.\n");
	fprintf(stderr, "  -G or --nogpsd: disable gpsd auto-start.\n");
	fprintf(stderr, "  -W or --nowireless: disable auto-configuration of wireless interfaces.\n");
	fprintf(stderr, "  -ch[1-11]: explicitly set hostapd wireless channel\n");
	fprintf(stderr, "Remarks:\n");
	fprintf(stderr, "  If the number is omitted, the value stored in %s/wfu-brain-num\n\
will be used (if it exists; otherwise 1 is used as default).\n",SRC_DIR);
}

void print_detailed_help(char * argv0)
{
	if (quietMode)
		return;

	printf("[WiFindUs Brain Auto-Setup %s]\n\n",VERSION_STR);
	printf(
"This program assigns this brain unit with it's unique ID number\n\
(1-254, provided as a parameter), and generates all the associated\n\
scripts needed to set up the mesh network.\n\n"
	);
	
	print_usage(argv0);
	printf("\n");
	
	printf(
"The following files are automatically generated/overwritten:\n\
    /etc/hosts\n\
    /etc/hostname\n\
    /etc/rc.local\n\
    /etc/hostapd/hostapd.conf\n\
    /etc/dhcp/dhcpd.conf\n\
    /etc/default/isc-dhcp-server\n\
    /etc/network/interfaces\n\
    /usr/local/etc/serval/serval.conf\n\
    %s/wfu-brain-num\n\n",
	SRC_DIR
	);
		
	printf(
"The changes made within won't fully take effect until the Pi is\n\
rebooted; run the program with the -r switch to automatically reboot\n\
it upon completion.\n\n"
	);
}

int write_hosts(int num)
{
	FILE* file = NULL;
	int i;
	
	sprintf(nbuf,"/etc/hosts");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"127.0.0.1 localhost\n");
	fprintf(file,"127.0.1.1 wfu-brain-%d\n",num);
	fprintf(file,"::1 localhost ip6-localhost ip6-loopback\n");
	fprintf(file,"fe00::0 ip6-localnet\n");
	fprintf(file,"ff00::0 ip6-mcastprefix\n");
	fprintf(file,"ff02::1 ip6-allnodes\n");
	fprintf(file,"ff02::2 ip6-allrouters\n\n");
	fprintf(file,"192.168.1.1 wfu-server\n");
	fprintf(file,"192.168.1.1 m-server\n");
	
	for (i = 1; i < 255; i++)
	{
		if (i == num)
			continue;
		fprintf(file,"10.1.0.%d wfu-brain-%d wb%d\n",i,i,i);
	}
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	return TRUE;
}

int write_hostname(int num)
{
	FILE* file = NULL;

	sprintf(nbuf,"/etc/hostname");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"wfu-brain-%d\n",num);
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	return TRUE;
}

int write_rc_local(int num)
{
	FILE* file = NULL;
	int i;
	
	sprintf(nbuf,"/etc/rc.local");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}

	fprintf(file,"#! /bin/sh\n\n");
	fprintf(file,"#############################################################\n");
	fprintf(file,"### Enviroment Logging\n");
	fprintf(file,"#############################################################\n");
	fprintf(file,"sudo rm -f /home/pi/*.log\n");
	fprintf(file,"exec >/home/pi/rc.local.log 2>&1\n\n");
	fprintf(file,"#exec 1>&2\n");
	fprintf(file,"#set -x\n");
	fprintf(file,"DMESG=`dmesg 2>&1`\n");
	fprintf(file,"echo -e \"$DMESG\" > /home/pi/dmesg_boot.log\n");
	fprintf(file,"LSUSB=`lsusb 2>&1`\n");
	fprintf(file,"echo -e \"$LSUSB\" > /home/pi/lsusb_boot.log\n");
	fprintf(file,"LSMOD=`lsmod 2>&1`\n");
	fprintf(file,"echo -e \"$LSMOD\" > /home/pi/lsmod_boot.log\n\n");
	
	if (!noWireless)
	{
		fprintf(file,"#############################################################\n");
		fprintf(file,"### Mesh and AP Logging\n");
		fprintf(file,"#############################################################\n");
		
		//enumerate mesh adapters
		fprintf(file,"echo \"Checking for supported mesh adapter...\"\n");
		//atheros ar9271
		fprintf(file,"MESH_PHY_INFO=`echo -e $DMESG | grep -E -i -o \"phy[0-9]+: Atheros AR9271\"`\n");
		fprintf(file,"if [ -n \"$MESH_PHY_INFO\" ]; then\n");
		fprintf(file,"	MESH_ADAPTER=\"Atheros AR9271\"\n");
		fprintf(file,"fi\n\n");
		//assess enumeration
		fprintf(file,"if [ -n \"$MESH_PHY_INFO\" ]; then\n");
		fprintf(file,"	MESH_PHY=`echo -e \"$MESH_PHY_INFO\" | grep -E -i -o \"phy[0-9]+\"`\n");
		fprintf(file,"	echo \"$MESH_ADAPTER detected ($MESH_PHY).\"\n");
		fprintf(file,"else\n");
		fprintf(file,"	echo \"ERROR: no supported mesh adapters detected.\"\n");
		fprintf(file,"fi\n\n");
		
		//enumerate ap adapters
		fprintf(file,"echo \"Checking for supported AP adapter...\"\n");	
		//ralink rt5370
		fprintf(file,"AP_PHY_INFO=`echo -e $DMESG | grep -E -i -o \"phy[0-9]+: rt2x00_set_rf: Info - RF chipset 5370(, rev [0-9]+)? detected\"`\n");
		fprintf(file,"if [ -n \"$AP_PHY_INFO\" ]; then\n");
		fprintf(file,"	AP_ADAPTER=\"Ralink RT5370\"\n");
		fprintf(file,"fi\n\n");
		//ralink rt5572
		fprintf(file,"if [ -z \"$AP_PHY_INFO\" ]; then\n");
		fprintf(file,"	AP_PHY_INFO=`echo -e $DMESG | grep -E -i -o \"phy[0-9]+: rt2x00_set_rt: Info - RT chipset 5592(, rev [0-9]+)? detected\"`\n");
		fprintf(file,"	if [ -n \"$AP_PHY_INFO\" ]; then\n");
		fprintf(file,"		AP_ADAPTER=\"Ralink RT5572\"\n");
		fprintf(file,"	fi\n");
		fprintf(file,"fi\n\n");
		//assess enumeration
		fprintf(file,"if [ -n \"$AP_PHY_INFO\" ]; then\n");
		fprintf(file,"	AP_PHY=`echo -e \"$AP_PHY_INFO\" | grep -E -i -o \"phy[0-9]+\"`\n");
		fprintf(file,"	echo \"$AP_ADAPTER detected ($AP_PHY).\"\n");
		fprintf(file,"else\n");
		fprintf(file,"	echo \"ERROR: no supported AP adapters detected.\"\n");
		fprintf(file,"	if [ \"$MESH_PHY\" != \"\" ]; then\n");
		fprintf(file,"		echo \"FALLBACK: Will use $MESH_PHY for both interfaces.\"\n");
		fprintf(file,"		AP_PHY=\"$MESH_PHY\"\n");
		fprintf(file,"		AP_ADAPTER=\"$MESH_ADAPTER\"\n");
		fprintf(file,"	fi\n");
		fprintf(file,"fi\n\n");
				
		fprintf(file,"echo \"Checking existing wireless interfaces...\"\n");
		fprintf(file,"WLANS=\"wlan0 wlan1 wlan2 wlan3 ra0 ra1 ra2 ra3\"\n");
		fprintf(file,"for WLAN in $WLANS; do\n");
		fprintf(file,"	WLAN_IFACE=`iwconfig 2>&1 | grep -o -i \"$WLAN\"`\n");
		fprintf(file,"	if [ \"$WLAN_IFACE\" != \"\" ]; then\n");
		fprintf(file,"		echo \"$WLAN_IFACE detected, attempting to remove...\"\n");
		fprintf(file,"		ifconfig \"$WLAN_IFACE\" down\n");
		fprintf(file,"		sleep 3\n");
		fprintf(file,"		iw dev \"$WLAN_IFACE\" del\n");
		fprintf(file,"		WLAN_IFACE=`iwconfig 2>&1 | grep -o -i \"$WLAN\"`\n");
		fprintf(file,"		if [ \"$WLAN_IFACE\" != \"\" ]; then\n");
		fprintf(file,"			echo \"ERROR: $WLAN could not be removed, possibly not nl80211-compatible...\"\n");
		fprintf(file,"		else\n");
		fprintf(file,"			echo \"$WLAN removed OK.\"\n");
		fprintf(file,"		fi\n");
		fprintf(file,"	fi\n");
		fprintf(file,"done\n\n");	
		
		fprintf(file,"echo \"Setting regulatory domain...\"\n");
		fprintf(file,"iw reg set AU\n\n");
		
		fprintf(file,"if [ \"$MESH_PHY\" != \"\" ]; then\n");
		fprintf(file,"	echo \"Creating mesh0 interface on $MESH_PHY...\"\n");
		fprintf(file,"	iw phy $MESH_PHY interface add mesh0 type %s\n",(adhocMode ? "ibss" : "mp mesh_id wifindus_mesh"));
		fprintf(file,"fi\n\n");
		
		fprintf(file,"if [ \"$AP_PHY\" != \"\" ]; then\n");
		fprintf(file,"	echo \"Creating ap0 interface on $AP_PHY...\"\n");
		fprintf(file,"	iw phy $AP_PHY interface add ap0 type managed\n");
		fprintf(file,"	ip link set dev ap0 address 60:60:60:60:60:%s\n",hex);
		fprintf(file,"fi\n\n");
		
		fprintf(file,"if [ \"$MESH_PHY\" != \"\" ]; then\n");
		fprintf(file,"	echo \"Bringing mesh0 up...\"\n");
		fprintf(file,"	ifconfig mesh0 up\n\n");	
		fprintf(file,"	sleep 3\n\n");
		fprintf(file,"	ifconfig mesh0 10.1.0.%d\n",num);	
		fprintf(file,"fi\n\n");
		
		fprintf(file,"if [ \"$AP_PHY\" != \"\" ]; then\n");
		fprintf(file,"	echo \"Bringing ap0 up...\"\n");
		fprintf(file,"	ifconfig ap0 172.16.%d.1 netmask 255.255.255.0 up\n",num);	
		fprintf(file,"fi\n\n");
		
		if (adhocMode)
		{
			fprintf(file,"if [ \"$MESH_PHY\" != \"\" ]; then\n");
			fprintf(file,"	echo \"joining ad-hoc network on mesh0...\"\n");
			fprintf(file,"	sleep 1\n");
			fprintf(file,"	iw dev mesh0 ibss join wifindus_mesh 2412 key 0:PWbDq39QQ8632\n");
			fprintf(file,"fi\n\n");
		}
	}
		
	if (daemon_flags > 0)
	{
		fprintf(file,"#############################################################\n");
		fprintf(file,"### Daemons\n");
		fprintf(file,"#############################################################\n");
		fprintf(file,"sleep 5\n");
		if ((daemon_flags & GPSD_FLAG) == GPSD_FLAG)
		{
			fprintf(file,"echo \"Checking for supported GPS module...\"\n");
			fprintf(file,"GPS_MODULE=`echo -e \"$LSUSB\" | grep -i -o \"0e8d:3329\"`\n");
			fprintf(file,"if [ \"$GPS_MODULE\" != \"\" ]; then\n");
			fprintf(file,"	echo \"MediaTek MT3328 detected ($GPS_MODULE). Looking for serial stream...\"\n");
			fprintf(file,"	GPS_STREAM=`echo -e \"$DMESG\" | grep -E -i -o \"ttyACM[0-9]+\"`\n");
			fprintf(file,"	if [ \"$GPS_STREAM\" != \"\" ]; then\n");
			fprintf(file,"		echo \"GPS serial stream detected ($GPS_STREAM). Launching gpsd...\"\n");
			fprintf(file,"		gpsd -n \"$GPS_STREAM\" -F /var/run/gpsd.sock\n");
			fprintf(file,"	else\n");
			fprintf(file,"		echo \"ERROR: No serial stream detected. Perhaps update firmware or drivers?\"\n");
			fprintf(file,"	fi\n");
			fprintf(file,"else\n");
			fprintf(file,"	echo \"ERROR: no supported GPS receiver detected.\"\n");
			fprintf(file,"fi\n\n");
		}
		
		if (!noWireless && (daemon_flags & (DHCPD_FLAG | HOSTAPD_FLAG | SERVALD_FLAG)) > 0)
		{
			fprintf(file,"AP_0=`ifconfig | grep -o \"ap0\"`\n");
			fprintf(file,"if [ \"$AP_0\" != \"\" ]; then\n");
			if ((daemon_flags & HOSTAPD_FLAG) == HOSTAPD_FLAG)
			{
				fprintf(file,"	echo \"Starting hostapd...\"\n");
				fprintf(file,"	hostapd -B /etc/hostapd/hostapd.conf\n");
			}
			if ((daemon_flags & DHCPD_FLAG) == DHCPD_FLAG)
			{
				fprintf(file,"	sleep 1\n");
				fprintf(file,"	echo \"Starting dhcpd...\"\n");
				fprintf(file,"	dhcpd -4 -q\n");
			}
			if ((daemon_flags & SERVALD_FLAG) == SERVALD_FLAG)
			{
				fprintf(file,"	sleep 1\n");
				fprintf(file,"echo \"Starting servald...\"\n");
				fprintf(file,"  servald start\n");
			}
			fprintf(file,"fi\n\n");
		}
	}
	
	fprintf(file,"#############################################################\n");
	fprintf(file,"### Routing\n");
	fprintf(file,"#############################################################\n");
	fprintf(file,"echo 1 > /proc/sys/net/ipv4/ip_forward\n");
	fprintf(file,"echo \"Flushing ip tables...\"\n");
	fprintf(file,"iptables -F\n");
	fprintf(file,"iptables -X\n");
	fprintf(file,"iptables -t nat -F\n");
	fprintf(file,"iptables -P INPUT ACCEPT\n");
	fprintf(file,"iptables -P FORWARD ACCEPT\n");
	fprintf(file,"iptables -P OUTPUT ACCEPT\n");
	fprintf(file,"iptables -P OUTPUT ACCEPT\n");
	fprintf(file,"sudo ip route del 192.168.1.0/24 dev eth0\n");
	if (num == 1)
	{
		fprintf(file,"echo \"Adding default gateway route...\"\n");
		fprintf(file,"iptables -t nat -A POSTROUTING -d 192.168.1.0/24 -j ACCEPT\n");
		fprintf(file,"iptables -t nat -A POSTROUTING -d 0.0.0.0/0 -j MASQUERADE\n");
		//fprintf(file,"ip route add 0.0.0.0/0 via 192.168.1.254\n");
	}
	
	if (!noWireless)
	{
		fprintf(file,"\nMESH_0=`ifconfig | grep -o \"mesh0\"`\n");
		fprintf(file,"if [ \"$MESH_0\" != \"\" ]; then\n");
		if (num != 1)
		{
			fprintf(file,"	echo \"Adding default gateway route...\"\n");
			fprintf(file,"	ip route add 0.0.0.0/0 via 10.1.0.1\n");
		}

		
		fprintf(file,"	echo \"Adding node routes...\"\n");
		for (i = 1; i < 255; i++)
		{
			if (i == num)
				continue;
			fprintf(file,"	ip route add 172.16.%d.0/24 via 10.1.0.%d dev mesh0\n",i,i);
		}
		fprintf(file,"fi\n\n");
	}

	fprintf(file,"\nexit 0\n");
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_hostapd(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/hostapd/hostapd.conf");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"interface=ap0\n");
	fprintf(file,"country_code=AU\n");
	fprintf(file,"ieee80211d=1\n");
	fprintf(file,"driver=nl80211\n"); //old: rtl871xdrv
	fprintf(file,"ssid=wifindus_public\n");
	fprintf(file,"hw_mode=g\n");
	fprintf(file,"channel=%d\n",apChannel);
	
	//security
	fprintf(file,"macaddr_acl=0\n");
	fprintf(file,"auth_algs=1\n");
	fprintf(file,"wpa=3\n");
	fprintf(file,"wpa_passphrase=a8jFIVcag82H461\n");
	fprintf(file,"wpa_key_mgmt=WPA-PSK\n");
	fprintf(file,"wpa_pairwise=TKIP\n");
	fprintf(file,"rsn_pairwise=CCMP\n");
	fprintf(file,"ignore_broadcast_ssid=0\n");
	
	//wireless-n
	fprintf(file,"ieee80211n=1\n");
	fprintf(file,"preamble=1\n");
	fprintf(file,"ap_max_inactivity=60\n");
	fprintf(file,"disassoc_low_ack=1\n");
	fprintf(file,"wmm_enabled=1\n");
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_network_interfaces(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/network/interfaces");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}

	fprintf(file,"auto lo\n");
	fprintf(file,"iface lo inet loopback\n\n");
	
	fprintf(file,"auto eth0\n");
	fprintf(file,"iface eth0 inet static\n");
	fprintf(file,"        address 192.168.1.%d\n",min(100+num,254));
	fprintf(file,"        netmask 255.255.255.0\n");
	fprintf(file,"        network 192.168.1.0\n");
	fprintf(file,"        broadcast 192.168.1.255\n");
	if (num == 1)
		fprintf(file,"        gateway 192.168.1.254\n");
	fprintf(file,"\n");

	fprintf(file,"iface wlan0 inet manual\n");
	fprintf(file,"        post-up iwconfig wlan0 power off\n");
	fprintf(file,"iface wlan1 inet manual\n");
	fprintf(file,"        post-up iwconfig wlan1 power off\n");

	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_dhcpd(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/dhcp/dhcpd.conf");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
		
	fprintf(file,"ddns-update-style none;\n");
	fprintf(file,"option domain-name \"wfu-brain-%d.local\";\n",num);
	fprintf(file,"default-lease-time 600;\n");
	fprintf(file,"max-lease-time 7200;\n");
	fprintf(file,"authoritative;\n");
	fprintf(file,"log-facility local7;\n");
	fprintf(file,"subnet 172.16.%d.0 netmask 255.255.255.0 {\n",num);
	fprintf(file,"  range 172.16.%d.2 172.16.%d.254;\n",num,num);
	fprintf(file,"  option routers 172.16.%d.1;\n",num);
	fprintf(file,"  option subnet-mask 255.255.255.0;\n");
	fprintf(file,"  option broadcast-address 172.16.%d.255;\n",num);
	fprintf(file,"}\n");


	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_dhcpd_default(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/default/isc-dhcp-server");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"INTERFACES=\"ap0\"\n");

	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_servald(int num)
{
	FILE* file = NULL;

	sprintf(nbuf,"/usr/local/etc/serval/serval.conf");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"interfaces.0.match=mesh*,ap*\n");
	fprintf(file,"interfaces.0.type=wifi\n");
	fprintf(file,"server.respawn_on_crash=true\n");
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_brain_num(int num)
{
	FILE* file = NULL;

	sprintf(nbuf,"%s/wfu-brain-num",SRC_DIR);
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	fprintf(file,"%d\n",num);
	fclose(file);
	
	sprintf(sbuf,"WFU_BRAIN_NUM=`cat \"%s/wfu-brain-num\" | grep -i -E -o \"([1-2][0-9]{2}|[1-9][0-9]|[1-9])\"`; export WFU_BRAIN_NUM", SRC_DIR);
	system(sbuf);
	
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int read_brain_num()
{
	FILE* file = NULL;
	int val = FALSE;
	
	sprintf(nbuf,"%s/wfu-brain-num",SRC_DIR);
	if ((file = fopen(nbuf,"r")) == NULL)
		return FALSE;
	fscanf(file, "%d", &val);
	fclose(file);
	if (val < 1 || val > 254)
		return FALSE;
	return val;	
}

int main(int argc, char **argv)
{
	//vars
	int i = 0;
	int num = FALSE;
	int numDefault = FALSE;
	int numExplicit = FALSE;
	int autoReboot = FALSE;
	int autoHalt = FALSE;
	int detailedHelpMode = FALSE;
	//end vars
	
	for (i = 1; i < argc; i++)
	{
		if (strcmp(argv[i],"-r") == 0 || strcmp(argv[i],"--reboot") == 0)
			autoReboot = TRUE;
		else if (strcmp(argv[i],"-s") == 0 || strcmp(argv[i],"--shutdown") == 0)
			autoHalt = TRUE;
		else if (strcmp(argv[i],"-h") == 0 || strcmp(argv[i],"--help") == 0)
			detailedHelpMode = TRUE;
		else if (strcmp(argv[i],"-q") == 0 || strcmp(argv[i],"--quiet") == 0)
			quietMode = TRUE;
		else if (strcmp(argv[i],"-S") == 0 || strcmp(argv[i],"--servald") == 0)
			daemon_flags |= SERVALD_FLAG;
		else if (strcmp(argv[i],"-D") == 0 || strcmp(argv[i],"--nodhcpd") == 0)
			daemon_flags &= ~DHCPD_FLAG;
		else if (strcmp(argv[i],"-H") == 0 || strcmp(argv[i],"--nohostapd") == 0)
			daemon_flags &= ~HOSTAPD_FLAG;
		else if (strcmp(argv[i],"-G") == 0 || strcmp(argv[i],"--nogpsd") == 0)
			daemon_flags &= ~GPSD_FLAG;
		else if (strcmp(argv[i],"-W") == 0 || strcmp(argv[i],"--nowireless") == 0)
			noWireless = TRUE;
		else if (strcmp(argv[i],"-a") == 0 || strcmp(argv[i],"--adhoc") == 0)
			adhocMode = TRUE;
		else if (strncmp(argv[i],"-ch", 3) == 0 && strlen(argv[i]) > 3)
			apChannel = atoi(argv[i]+3);
		else
		{
			numExplicit = TRUE;
			num = atoi(argv[i]);
			if (num < 1 || num > 254)
				num = FALSE;
		}
	}
	
	strcpy(opString,"Writing");
	
	if (detailedHelpMode)
	{
		print_detailed_help(argv[0]);
		return 0;
	}
	
	if (!num)
		num = read_brain_num();
	if (!num && !numExplicit)
	{
		num = 1;
		numDefault = TRUE;
	}
	if (!num)
	{
		print_usage(argv[0]);
		return 2;
	}
	
	dtoh(num,hex);
	
	if (apChannel < 1 || apChannel > 11)
		apChannel = 6 + (num%2) * 5; //default to 11 for odd numbers, 6 for even
	
	if (!quietMode)
	{
		printf("[WiFindUs Brain Auto-Setup %s]\nUnit: wfu-brain-%d (%s)\n",VERSION_STR,num,hex);
		if (numDefault)
		{
			printf("  -- Notice --\n\
You did not provide a unit number, and\n\
one has not previously been used on this\n\
system. 1 has been used as default.\n",VERSION_STR,num);
		}
		printf("\n");
	}
	
	if (!write_hosts(num))
		return 3;
	if (!write_hostname(num))
		return 4;
	if (!write_rc_local(num))
		return 5;
	if (!write_hostapd(num))
		return 6;
	if (!write_dhcpd(num))
		return 7;
	if (!write_dhcpd_default(num))
		return 8;
	if (!write_network_interfaces(num))
		return 9;
	if (!write_servald(num))
		return 10;
	if (!write_brain_num(num))
		return 11;
	if (autoReboot || autoHalt)
	{
		pid_t proc = fork();
		if (proc == 0)
		{
			sprintf(sbuf,"shutdown -%s now > /dev/null", autoHalt ? "h" : "r");
			return system(sbuf);
		}
		else if (proc < 0)
			return 50;
	}
	
	return 0;
}
