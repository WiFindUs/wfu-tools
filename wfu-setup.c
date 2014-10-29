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
#ifndef VERSION_STR
#define VERSION_STR "v1.2" 
#endif
#ifndef SRC_DIR
#define SRC_DIR "/home/pi/src" 
#endif

#define SERVALD_FLAG 1
#define DHCPD_FLAG 2
#define HOSTAPD_FLAG 4
#define GPSD_FLAG 8
#define ALL_FLAGS 15

int quietMode = FALSE;
int uninstallMode = FALSE;
int noWireless = FALSE;
int adhocMode = FALSE;
int daemon_flags = ALL_FLAGS;
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
	fprintf(stderr, "  -S or --noservald: disable serval auto-start.\n");
	fprintf(stderr, "  -D or --nodhcpd: disable dhcpd auto-start.\n");
	fprintf(stderr, "  -H or --nohostapd: disable hostapd auto-start.\n");
	fprintf(stderr, "  -G or --nogpsd: disable gpsd auto-start.\n");
	fprintf(stderr, "  -W or --nowireless: disable auto-configuration of wireless interfaces.\n");
	fprintf(stderr, "  -u or --uninstall: reverts scripts to pre-wfu defaults,\n\
instead of writing them out to disk.\n");
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
	
	if (!uninstallMode)
	{	
		for (i = 1; i < 255; i++)
		{
			if (i == num)
				continue;
			fprintf(file,"172.16.0.%d wfu-brain-%d\n",i,i);
		}
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
	
	sprintf(nbuf,"/etc/rc.local");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"#! /bin/sh -e\n");

	if (!uninstallMode)
	{
		fprintf(file,"echo \"[WFU Mesh Setup] - creating node...\"\n");
		
		fprintf(file,"sudo ifconfig wlan0 down\n");
		fprintf(file,"sleep 3\n");
		fprintf(file,"sudo iw dev wlan0 del\n");
		fprintf(file,"sudo iw reg set AU\n");
		if (!noWireless)
		{
			fprintf(file,"sudo iw phy phy0 interface add mesh0 type %s\n",(adhocMode ? "ibss" : "mp mesh_id wifindus_mesh"));
			fprintf(file,"sudo iw phy phy0 interface add ap0 type managed\n");
			fprintf(file,"sudo ip link set dev ap0 address 60:60:60:60:60:%s\n",hex);
			fprintf(file,"sudo ifconfig mesh0 up\n");	
			fprintf(file,"sleep 3\n");
			fprintf(file,"sudo ifconfig mesh0 10.1.0.%d\n",num);	
			fprintf(file,"sudo ifconfig ap0 10.0.%d.1 up\n",num);	
			if (adhocMode)
			{
				fprintf(file,"sleep 1\n");
				fprintf(file,"sudo iw dev mesh0 ibss join wifindus_mesh 2412 key 0:PWbDq39QQ8632\n");
			}
		}
			
		if (daemon_flags > 0)
		{
			fprintf(file,"echo \"[WFU Mesh Setup] - launching daemons...\"\n");
			if ((daemon_flags & GPSD_FLAG) == GPSD_FLAG)
			{
				fprintf(file,"sleep 5\n");
				fprintf(file,"GPS_MODULE=`lsusb | grep -i -E \"0e8d:3329\"`\n");
				fprintf(file,"if [ \"$GPS_MODULE\" != \"\" ]; then \n");
				fprintf(file,"	sudo gpsd /dev/ttyACM0 -F /var/run/gpsd.sock\n");
				fprintf(file,"fi\n");
			}
			
			if (!noWireless && (daemon_flags & (DHCPD_FLAG | HOSTAPD_FLAG | SERVALD_FLAG)) > 0)
			{
				fprintf(file,"AP_MODULE=`ifconfig | grep -i -E \"ap0\"`\n");
				fprintf(file,"if [ \"$AP_MODULE\" != \"\" ]; then \n");
				if ((daemon_flags & HOSTAPD_FLAG) == HOSTAPD_FLAG)
				{
					fprintf(file,"	sleep 5\n");
					fprintf(file,"	sudo hostapd -B /etc/hostapd/hostapd.conf\n");
					
				}
				if ((daemon_flags & DHCPD_FLAG) == DHCPD_FLAG)
				{
					fprintf(file,"	sleep 5\n");
					fprintf(file,"	sudo dhcpd\n");
					
				}
				if ((daemon_flags & SERVALD_FLAG) == SERVALD_FLAG)
				{
					fprintf(file,"	sleep 5\n");
					fprintf(file,"  sudo servald start\n");
					
				}
				fprintf(file,"fi\n");
			}
			fprintf(file,"sleep 5\n");
		}
		
		//routing like a baws
		fprintf(file,"sudo su\n");
		fprintf(file,"echo 1 > /proc/sys/net/ipv4/ip_forward\n");
		fprintf(file,"iptables -F\n");
		fprintf(file,"iptables -X\n");
		fprintf(file,"iptables -t nat -F\n");
		fprintf(file,"iptables -P INPUT ACCEPT\n");
		fprintf(file,"iptables -P FORWARD ACCEPT\n");
		fprintf(file,"iptables -P OUTPUT ACCEPT\n");
		fprintf(file,"iptables -P OUTPUT ACCEPT\n");
		if (num > 1)
			fprintf(file,"ip route add 192.168.1.0/24 via 10.1.0.1 dev mesh0\n");
		fprintf(file,"exit\n");
	}

	fprintf(file,"exit 0\n");
	
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
	if ((uninstallMode && remove(nbuf) != 0) || (!uninstallMode && (file = fopen(nbuf,"w")) == NULL))
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	if (uninstallMode)
		return TRUE;
	
	fprintf(file,"interface=ap0\n");
	fprintf(file,"country_code=AU\n");
	fprintf(file,"driver=nl80211\n"); //old: rtl871xdrv
	fprintf(file,"ssid=wifindus_public\n");
	fprintf(file,"hw_mode=g\n");
	fprintf(file,"ieee80211n=0\n"); //was 1
	fprintf(file,"channel=1\n");
	fprintf(file,"macaddr_acl=0\n");
	fprintf(file,"ignore_broadcast_ssid=0\n");
	fprintf(file,"auth_algs=1\n");
	fprintf(file,"wpa=2\n");
	fprintf(file,"wpa_passphrase=a8jFIVcag82H461\n");
	fprintf(file,"wpa_key_mgmt=WPA-PSK\n");
	fprintf(file,"wpa_pairwise=TKIP\n");
	fprintf(file,"rsn_pairwise=CCMP\n");
	
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
	
	fprintf(file,"iface eth0 inet static\n");
	fprintf(file,"        address 192.168.1.%d\n",min(100+num,254));
	fprintf(file,"        netmask 255.255.255.0\n");
	fprintf(file,"\n");

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
	if ((uninstallMode && remove(nbuf) != 0) || (!uninstallMode && (file = fopen(nbuf,"w")) == NULL))
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	if (uninstallMode)
		return TRUE;
		
	fprintf(file,"ddns-update-style none;\n");
	fprintf(file,"option domain-name \"wfu-brain-%d.local\";\n",num);
	fprintf(file,"default-lease-time 86400;\n");
	fprintf(file,"max-lease-time 604800;\n");
	fprintf(file,"authoritative;\n");
	fprintf(file,"log-facility local7;\n");
	fprintf(file,"subnet 10.0.%d.0 netmask 255.255.255.0 {\n",num);
	fprintf(file,"  range 10.0.%d.2 10.0.%d.254;\n",num,num);
	fprintf(file,"  option subnet-mask 255.255.255.0;\n");
	fprintf(file,"  option broadcast-address 10.0.%d.255;\n",num);
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
	if ((uninstallMode && remove(nbuf) != 0) || (!uninstallMode && (file = fopen(nbuf,"w")) == NULL))
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	if (uninstallMode)
		return TRUE;
	
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
	
	if ((uninstallMode && remove(nbuf) != 0) || (!uninstallMode && (file = fopen(nbuf,"w")) == NULL))
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	if (uninstallMode)
		return TRUE;
	
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
		else if (strcmp(argv[i],"-u") == 0 || strcmp(argv[i],"--uninstall") == 0)
			uninstallMode = TRUE;
		else if (strcmp(argv[i],"-S") == 0 || strcmp(argv[i],"--noservald") == 0)
			daemon_flags &= ~SERVALD_FLAG;
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
		else
		{
			numExplicit = TRUE;
			num = atoi(argv[i]);
			if (num < 1 || num > 254)
				num = FALSE;
		}
	}
	
	strcpy(opString,uninstallMode ? "Reverting" : "Writing");
	
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
	
	if (!quietMode)
	{
		printf("[WiFindUs Brain Auto-Setup %s]\nUnit: wfu-brain-%d (%s)\n",VERSION_STR,num,hex);
		if (uninstallMode)
			printf("## UNINSTALL MODE ##\n");
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
